-- Weapon drop

-- Same physical property group is used for projectiles and weapon objects
local DROPPED_OBJECT_PHYSICAL_PROPERTY_GROUP = 122

-- Disable camera collisions for dropped weapon objects
engineRestoreObjectGroupPhysicalProperties(DROPPED_OBJECT_PHYSICAL_PROPERTY_GROUP)
engineSetObjectGroupPhysicalProperty(DROPPED_OBJECT_PHYSICAL_PROPERTY_GROUP, "avoid_camera", false)

-- Weapon objects doesn't have collisions if there wasn't created projectile before
-- So create one
--local ped = Ped(17, BLACKHOLE)
Projectile(localPlayer, WEAPON_TEARGAS, BLACKHOLE):destroy()
--ped:destroy()

local weapons = {}

-- Render
local render = { -- 1680x1050
	["img"] = {0.822*sX, 0.743*sY, 0.130*sX, 0.076*sY}, -- 1381, 781, 220, 80
	["txt"] = {0.824*sY, 0.953*sX, 0.845*sY} -- 1381, 866, 1602, 888
}

local text = getText("drop_text")
local function drawWeapon()
	dxDrawImage(render["img"][1], render["img"][2], render["img"][3], render["img"][4], ":csrw-media/images/shop/" .. g_weapon[drop_currentWeapon[1]][drop_currentWeapon[2]]["image"], 0, 0, 0, tocolor(0, 0, 0, 145), true)
	dxDrawText(text, render["img"][1], render["txt"][1], render["txt"][2], render["txt"][3], tocolor(251, 121, 5, 211), 1, "default-bold", "center", "center", false, false, true, false, false)
end

local function startDrawingWeapon(slot, weapon)
	if not drop_currentWeapon then
		drop_currentWeapon = {slot, weapon}
		addEventHandler("onClientRender", root, drawWeapon)
	else
		drop_currentWeapon = {slot, weapon}
	end
end

local function stopDrawingWeapon()
	if drop_currentWeapon then
		drop_currentWeapon = false
		removeEventHandler("onClientRender", root, drawWeapon)
	end
end
-- Render end

function dropWeapon(forced, slot)
	if not g_matchSettings.weaponDrop and not (forced and slot == DEF_BOMB[1] and g_playerWeaponData[slot] and g_playerWeaponData[slot].weapon == DEF_BOMB[2]) then
		-- Weapon drop is disabled in config
		-- (drop bomb even if weaponDrop is disabled though)
		return
	end

	if forced or (g_player.canChangeSlot and not isPedInVehicle(localPlayer) and not isCursorShowing() and not g_player.reloading and getCurrentProgressBar() == "" and getElementData(localPlayer, "alive") == true and not getControlState("fire") and not getControlState("aim_weapon") and (getPedSimplestTask(localPlayer) == "TASK_SIMPLE_PLAYER_ON_FOOT" or getPedSimplestTask(localPlayer) == "TASK_SIMPLE_SWIM")) then
		-- disable drop while in air and ex. while jumping because player would instantly catch dropped weapon (50 ms timer)
		if not slot then
			slot = getElementData(localPlayer, "currentSlot")
		end

		if not slot then
			return
		end

		if not g_playerWeaponData[slot] then
			return
		end

		local weapon = g_playerWeaponData[slot].weapon
		if not weapon then
			return
		end

		if g_weapon[slot][weapon]["droppable"] == "false" or g_weapon[slot][weapon]["objectID"] == nil or tonumber(g_weapon[slot][weapon]["objectID"]) <= 0 then
			return
		end

		local x, y, z = getElementPosition(localPlayer)
		local x2, y2, z2 = getPositionFromElementOffset(localPlayer, 0, 1.5, 0)
		if not isLineOfSightClear(x, y, z + 0.05, x2, y2, z2 + 0.05, true, false, false) then
			advert.error(getText("drop_wall_close"), localPlayer, true)
			return
		end

		local groundZ = getGroundPosition(x, y, z) + 0.1

		-- Call server about dropping weapon
		triggerServerEvent("dropPhysicWeapon", localPlayer, slot, weapon, g_playerWeaponData[slot].ammo, g_playerWeaponData[slot].clip, groundZ)
		
		if slot == getElementData(localPlayer, "currentSlot") then
			switchWeaponSlot("up", nil, nil, nil, true, true)
		else
			g_playerWeaponData[slot] = nil
			-- nie trzeba robić triggeru do serwera o skasowanie broni z pleców albo z serwerowych zmiennych, ponieważ wszystko się
			-- nadpisze w raz z nową bronią (wykorzystywane w sklepie przy kupnie broni na tym samym slocie - forced = true)
		end
	end
end

local function getWeaponFromGround(player, colshape)
	if player.health == 0 then
		return
	end

	if player.team ~= g_team[1] and player.team ~= g_team[2] then
		return
	end

	local weapon = getElementData(colshape, "weapon")
	if not getElementData(player, "wSlot" .. weapon.slot) and (not (weapon.slot == DEF_BOMB[1] and weapon.weapon == DEF_BOMB[2]) or player.team == g_team[1]) then -- jeśli gracz nie ma nic na tym slocie
	-- if not g_playerWeaponData[player][weapon.slot] then
		
		local related = getElementData(colshape, "related")
		local uniqueID = getElementData(related, "uniqueID")
		destroyElement(related)
		destroyElement(colshape)

		if player == localPlayer then
			if g_player.aiming then
				return
			end

			local task = localPlayer:getTask("secondary", TASK_SECONDARY_ATTACK)
			if task == "TASK_SIMPLE_USE_GUN" then
				return
			end

			stopDrawingWeapon()
			playSound(":csrw-sounds/sounds/items/itempickup.wav")
			
			-- opóźnienie ze względu na innych graczy, którzy 'mogą myśleć', że gracz nadal trzyma starą broń na slocie
			setTimer(triggerServerEvent, 200, 1, "onPhysicWeaponTaken", localPlayer, uniqueID)
		end
	
	else
		-- Gracz nie może podnieść broni bo ma już coś na tym slocie
		-- @todo: reset animacji?
		if player == localPlayer and getElementData(localPlayer, "currentSlot") == weapon.slot then
			startDrawingWeapon(weapon.slot, weapon.weapon)
		end
	end
end

-- projectile lub object
local function onWeaponHitted(element, matchingDimension)
	-- Projectile / obiekt musi być dopiero usuwany gdy gracz KTÓRY W NIEGO WEJDZIE go podniesie (bo przecież może nie mieć miejsca na slocie)

	if element.type == "player" and matchingDimension then
		getWeaponFromGround(element, source)
	end
end

local function onWeaponLeave(element, matchingDimension)
	if element == localPlayer then
		if source:getData("weapon") ~= false then
			stopDrawingWeapon()
		end
	end
end

function createGroundWeapon(uniqueID, slot, weapon, x, y, z, rx, ry, rz, int, dimension)
	outputChatBox("C createGroundWeapon uniqueID " .. uniqueID)
	if not g_weapon[slot] or not g_weapon[slot][weapon] then
		-- Invalid weapon
		outputChatBox("C createGroundWeapon inv wep")
		return
	end

	-- x = tonumber(x)
	-- y = tonumber(y)
	-- z = tonumber(z)
	-- rx = tonumber(rx)
	-- ry = tonumber(ry)
	-- rz = tonumber(rz)
	-- int = tonumber(int)
	-- dimension = tonumber(dimension)

	if weapons[uniqueID] then
		outputChatBox("C createGroundWeapon already ext")
		-- Such weapon already exist, so just update data/position
		if isElement(weapons[uniqueID].object) then
			weapons[uniqueID].object.position = Vector3(x, y, z)
			weapons[uniqueID].object.rotation = Vector3(rx, ry, rz)
			weapons[uniqueID].object.interior = int
			weapons[uniqueID].object.dimension = dimension
			weapons[uniqueID].object.model = g_weapon[slot][weapon]["objectID"]
		end

		if isElement(weapons[uniqueID].colshape) then
			weapons[uniqueID].colshape.position = Vector3(x, y, z)
			weapons[uniqueID].colshape.interior = int
			weapons[uniqueID].colshape.dimension = dimension
		end

		weapons[uniqueID].slot = slot
		weapons[uniqueID].weapon = weapon
		return
	end

	weapons[uniqueID] = {
		slot = slot,
		weapon = weapon,
		object = nil,
		colshape = nil
	}

	outputChatBox("C createGroundWeapon before create: slot " .. slot .. " weapon " .. weapon)
	local model = tonumber(g_weapon[slot][weapon]["objectID"])
	if not model or model <= 0 then
		return
	end

	engineSetModelPhysicalPropertiesGroup(model, DROPPED_OBJECT_PHYSICAL_PROPERTY_GROUP)

	local wepObj = createObject(model, x, y, z, rx, ry, rz)
	weapons[uniqueID].object = wepObj

	for _, v in pairs(getElementsByType("player")) do
		setElementCollidableWith(wepObj, v, false)
	end
	
	for _, v in pairs(getElementsByType("ped")) do
		setElementCollidableWith(wepObj, v, false)
	end
	
	for _, v in pairs(getElementsByType("colshape")) do
		local relatedWeaponObj = getElementData(v, "related")
		if relatedWeaponObj then
			setElementCollidableWith(wepObj, relatedWeaponObj, false)
		end
	end	

	wepObj.interior = int
	wepObj.dimension = dimension
	wepObj.breakable = false

	-- Freeze weapon object
	wepObj.frozen = true
	wepObj.collisions = false

	-- Set object physical properties
	wepObj:setProperty("mass", 1500)
	wepObj:setProperty("turn_mass", 99999)
	wepObj:setProperty("air_resistance", 0.99)
	wepObj:setProperty("elasticity", 0.01)
	wepObj:setProperty("center_of_mass", Vector3(0, 0, 0))
	wepObj:setProperty("buoyancy", 0.99)

	local col = createColSphere(x, y, z, 1)
	col.dimension = dimension
	attachElements(col, wepObj)
	weapons[uniqueID].colshape = col

	setElementData(col, "weapon", {
		slot = slot,
		weapon = weapon
	}, false)

	setElementData(col, "related", wepObj, false) -- colshape należy do projectile
	setElementData(wepObj, "uniqueID", uniqueID, false)

	addEventHandler("onClientColShapeHit", col, onWeaponHitted) -- gdy jakiś gracz podniesie broń (lub wleci w niego)
	addEventHandler("onClientColShapeLeave", col, onWeaponLeave)
	-- ^ to działa także na niezestreamowane obiekty :O

	-- enable wallshader on this weapon object for spectators
	if localPlayer.team == g_team[3] then
		CWallShader:enable(wepObj, 255, 119, 0, 100)
	end

	outputChatBox(tostring(wepObj.position))
	--localPlayer.position = wepObj.position

	outputChatBox("C createGroundWeapon AFTER | " .. x .. ", " .. y .. ", " .. z .. " | " .. int .. " dim " .. dimension)
end

local function onWeaponDropped(player, slot, weapon, uniqueID)
	local x, y, z = getElementPosition(player)
	local rotx, roty, rotz = getElementRotation(player)
	local int = player.interior
	local dimension = player.dimension

	local x2, y2, z2 = getPositionFromElementOffset(player, 0, 1.5, 0)
	local velocity

	weapons[uniqueID] = {
		slot = slot,
		weapon = weapon,
		object = nil,
		colshape = nil
	}
	
	if not isLineOfSightClear(x, y, z + 0.05, x2, y2, z2 + 0.05, true, false, false) then
		velocity = {0, 0, 0.05}
	
	else
		local matrix = getElementMatrix(player) -- mam nadzieję, że to zwróci dobre wartości na niezestreamowanym graczu
		local offX = 0 * matrix[1][1] + 1 * matrix[2][1] + 0 * matrix[3][1] + 1 * matrix[4][1]
		local offY = 0 * matrix[1][2] + 1 * matrix[2][2] + 0 * matrix[3][2] + 1 * matrix[4][2]
		local offZ = 0 * matrix[1][3] + 1 * matrix[2][3] + 0 * matrix[3][3] + 1 * matrix[4][3]
		local vx = offX - x
		local vy = offY - y
		local vz = offZ - z
		velocity = {vx/4, vy/4, vz/4}
		x, y, z = getPositionFromElementOffset(player, 0, 1.5, 0)
	end

	local model = tonumber(g_weapon[slot][weapon]["objectID"])
	if not model or model <= 0 then
		return
	end

	engineSetModelPhysicalPropertiesGroup(model, DROPPED_OBJECT_PHYSICAL_PROPERTY_GROUP)

	local wepObj = createObject(model, x, y, z, 90, 0, rotz)
	weapons[uniqueID].object = wepObj

	for _, v in pairs(getElementsByType("player")) do
		setElementCollidableWith(wepObj, v, false)
	end
	
	for _, v in pairs(getElementsByType("ped")) do
		setElementCollidableWith(wepObj, v, false)
	end
	
	for _, v in pairs(getElementsByType("colshape")) do
		local relatedWeaponObj = getElementData(v, "related")
		if relatedWeaponObj then
			setElementCollidableWith(wepObj, relatedWeaponObj, false)
		end
	end	

	wepObj.interior = int
	wepObj.dimension = dimension
	wepObj.breakable = false

	-- Set object physical properties
	wepObj:setProperty("mass", 1500)
	wepObj:setProperty("turn_mass", 99999)
	wepObj:setProperty("air_resistance", 0.99)
	wepObj:setProperty("elasticity", 0.01)
	wepObj:setProperty("center_of_mass", Vector3(0, 0, 0))
	wepObj:setProperty("buoyancy", 0.99)

	setTimer(
		function()
			if not wepObj or not isElement(wepObj) then return end

			if isElementStreamedIn(wepObj) then
				setElementVelocity(wepObj, velocity[1], velocity[2], velocity[3])
			else
				setTimer(setElementVelocity, 200, 1, wepObj, velocity[1], velocity[2], velocity[3])
			end
		end, 50, 1
	)

	if wepObj then
		local col = createColSphere(x, y, z, 1)
		col.dimension = dimension
		attachElements(col, wepObj)
		weapons[uniqueID].colshape = col

		setElementData(col, "weapon", {
			slot = slot,
			weapon = weapon
		}, false)

		setElementData(col, "related", wepObj, false) -- colshape należy do projectile
		setElementData(wepObj, "uniqueID", uniqueID, false)

		addEventHandler("onClientColShapeHit", col, onWeaponHitted) -- gdy jakiś gracz podniesie broń (lub wleci w niego)
		addEventHandler("onClientColShapeLeave", col, onWeaponLeave)
		-- ^ to działa także na niezestreamowane obiekty :O

		-- After some time, weapon should drop on the ground
		setTimer(
			function()
				if not wepObj or not isElement(wepObj) then
					return
				end

				-- Freeze weapon object
				wepObj.frozen = true
				wepObj.collisions = false

				if isElementStreamedIn(wepObj) then
					-- Make it laying on the ground
					local x, y, z = getElementPosition(wepObj)
					local groundZ = getGroundPosition(x, y, z) + 0.1
					moveObject(wepObj, 100*(z - groundZ), x, y, groundZ)

					if player == localPlayer then
						-- Send position of this weapon to the server
						-- so we can update it for other players
						triggerServerEvent("syncThrowedWeapon", localPlayer, uniqueID, x .. ";" .. y .. ";" .. groundZ, rotz)
					end
				end
			end, 7000, 1
		)

		-- enable wallshader on this weapon object for spectators
		if localPlayer.team == g_team[3] then
			CWallShader:enable(wepObj, 255, 119, 0, 100)
		end
	end

	-- dodanie nowej broni wyrzucającemu graczowi jeśli stoi na jakiejś
	for _, v in pairs(getElementsByType("colshape")) do
		if isElementWithinColShape(player, v) then
			if getElementData(v, "weapon") ~= false then
				setTimer(getWeaponFromGround, 100, 1, player, v) -- timer ze względu na aktualizacje zmiennych po obu stronach (ważne przy auto dropie broni w sklepie)
			end
		end
	end
end
addEvent("dropClientPhysicWeapon", true)
addEventHandler("dropClientPhysicWeapon", root, onWeaponDropped)

addEvent("syncThrowedWeaponStepTwo", true)
addEventHandler("syncThrowedWeaponStepTwo", root,
	function(uniqueID, xyzString, rotz)
		for _, v in pairs(getElementsByType("object")) do
			if not isElementStreamedIn(v) and getElementData(v, "uniqueID") == uniqueID then
				--outputChatBox("C_DEBUG: Phydrop: Dodatkowy sync niezestreamowanej broni o UID " .. uniqueID)
				local pos = split(xyzString, ";")
				setElementPosition(v, pos[1], pos[2], pos[3])

				-- @todo: set rotz
				break
			end
		end
	end
)

addEvent("syncGroundWeapons", true)
addEventHandler("syncGroundWeapons", root,
	function(weapons, reset)
		if reset then
			destroyGroundWeapons()
		end

		outputChatBox("syncGroundWeapons client")
		for uniqueID, v in pairs(weapons) do
			local pos = split(v.xyzString, ";")

			local x, y, z = pos[1], pos[2], pos[3]
			local rx, ry, rz = 90, 0, v.rotz
			local dimension = 0

			createGroundWeapon(uniqueID, v.slot, v.weapon, x, y, z, rx, ry, rz, v.int, dimension)
		end
	end
)

addEvent("removeGroundWeapon", true)
addEventHandler("removeGroundWeapon", root,
	function(uniqueID)
		if not weapons[uniqueID] then
			return
		end

		if isElement(weapons[uniqueID].object) then
			weapons[uniqueID].object:destroy()
		end

		if isElement(weapons[uniqueID].colshape) then
			weapons[uniqueID].colshape:destroy()
		end

		weapons[uniqueID] = nil
		outputChatBox("removeGroundWeapon suc " .. uniqueID)
	end
)

function destroyGroundWeapons()
	for _, v in pairs(weapons) do
		if isElement(v.object) then
			v.object:destroy()
		end

		if isElement(v.colshape) then
			v.colshape:destroy()
		end
	end
	weapons = {}
end

function destroyGroundWeapon(uniqueID)
	local wep = weapons[uniqueID]
	if isElement(wep.object) then
		wep.object:destroy()
	end

	if isElement(wep.colshape) then
		wep.colshape:destroy()
	end
	weapons[uniqueID] = nil
end

addCommandHandler("Drop weapon", function() dropWeapon() end)
bindKey("g", "down", "Drop weapon")
