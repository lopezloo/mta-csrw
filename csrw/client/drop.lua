-- Wyrzucanie broni z wykorzystaniem fizyki GTA

local physicFixer = createProjectile(localPlayer, 16, 0, 0, -4) -- obiekty broni zapadają się pod ziemie jeśli nie ma wcześniej stworzonego projectile
destroyElement(physicFixer)

function dropWeapon(forced, slot)
	if not g_config["weapon_drop"] then
		return
	end

	if forced or (g_player.canChangeSlot and not isPedInVehicle(localPlayer) and not isCursorShowing() and not g_player.reloading and getElementData(localPlayer, "alive") == true and not getControlState("fire") and not getControlState("aim_weapon") and (getPedSimplestTask(localPlayer) == "TASK_SIMPLE_PLAYER_ON_FOOT" or getPedSimplestTask(localPlayer) == "TASK_SIMPLE_SWIM")) then
		-- zablokowane wyrzucanie podczas bycia w powietrzu i np. skoku bo wtedy gracz odrazu złapie tą broń co wyrzucił (timer 50ms)
		if not slot then
			slot = getElementData(localPlayer, "currentSlot")
		end
		if slot then
			local weapon = g_playerWeaponData[slot].weapon
			if weapon and g_weapon[slot][weapon]["droppable"] ~= "false" and g_weapon[slot][weapon]["objectID"] ~= nil and tonumber(g_weapon[slot][weapon]["objectID"]) > 0 then
				
				local x, y, z = getElementPosition(localPlayer)
				local x2, y2, z2 = getPositionFromElementOffset(localPlayer, 0, 1.5, 0)
				if not isLineOfSightClear(x, y, z + 0.05, x2, y2, z2 + 0.05, true, false, false) then
					advert.error(getText("drop_wall_close"), localPlayer, true)
					return
				end

				triggerServerEvent("dropPhysicWeapon", localPlayer, slot, weapon, g_playerWeaponData[slot].ammo, g_playerWeaponData[slot].clip)
				if slot == getElementData(localPlayer, "currentSlot") then
					switchWeaponSlot("up", nil, nil, nil, true, true)
				else
					g_playerWeaponData[slot] = nil
					-- nie trzeba robić triggeru do serwera o skasowanie broni z pleców albo z serwerowych zmiennych, ponieważ wszystko się
					-- nadpisze w raz z nową bronią (wykorzystywane w sklepie przy kupnie broni na tym samym slocie - forced = true)
				end
			end
		end
	end
end

function onWeaponDropped(player, slot, weapon, totalAmmo, clipAmmo, uniqueID)
	local x, y, z = getElementPosition(player)
	local rotx, roty, rotz = getElementRotation(player)
	local int = getElementInterior(player)

	local x2, y2, z2 = getPositionFromElementOffset(player, 0, 1.5, 0)
	local velocity
	
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

	local model = g_weapon[slot][weapon]["objectID"]
	-- obiekt o modelu broni zapada się pod ziemie jeśli nie ma wcześniej stworzonego projectile
	local wepObj = createObject(model, x, y, z, 90, 0, rotz)
	
	for k, v in pairs(getElementsByType("player")) do
		setElementCollidableWith(wepObj, v, false)
	end
	
	for k, v in pairs(getElementsByType("colshape")) do
		local relatedWeaponObj = getElementData(v, "related")
		if relatedWeaponObj then
			setElementCollidableWith(wepObj, relatedWeaponObj, false)
		end
	end	

	setElementInterior(wepObj, int)
	setTimer(
		function()
			if isElementStreamedIn(wepObj) then
				setElementVelocity(wepObj, velocity[1], velocity[2], velocity[3])
			else
				setTimer(setElementVelocity, 200, 1, wepObj, velocity[1], velocity[2], velocity[3])
			end
		end, 50, 1)

	-- jako creatora projectile można dać normalnego gracza co wyrzuca broń, ale u niego też to trzeba zsynchronizować i wtedy player == localPlayer
	-- więc projectile się zdublują.. pojazd to jak narazie jedyne normalne wyjście

	if wepObj then
		local col = createColSphere(x, y, z, 1)
		attachElements(col, wepObj)

		setElementData(col, "weapon", {slot = slot, weapon = weapon, totalAmmo = totalAmmo, clipAmmo = clipAmmo}, false)
		setElementData(col, "related", wepObj) -- colshape należy do projectile
		setElementData(wepObj, "uniqueID", uniqueID)

		addEventHandler("onClientColShapeHit", col, onWeaponHitted) -- gdy jakiś gracz podniesie broń (lub wleci w niego)
		addEventHandler("onClientColShapeLeave", col, onWeaponLeave)
		-- ^ to działa także na niezestreamowane obiekty :O

		setTimer(
			function()
				if wepObj and isElement(wepObj) then
					setElementFrozen(wepObj, true)
					setElementCollisionsEnabled(wepObj, false)

					if isElementStreamedIn(wepObj) then
						local x, y, z = getElementPosition(wepObj)
						local groundZ = getGroundPosition(x, y, z) + 0.1
						moveObject(wepObj, 100*(z - groundZ), x, y, groundZ)

						if player == localPlayer then
							triggerServerEvent("syncThrowedWeapon", localPlayer, uniqueID, x .. ";" .. y .. ";" .. groundZ, slot, weapon, totalAmmo, clipAmmo, rotz, int)
						end
					end
				end
			end, 7000, 1)

		if getPlayerTeam(localPlayer) == g_team[3] then -- wall shader na wyrzuconej broni tylko gdy jest się w pełnym specu
			CWallShader:enable(wepObj, 255, 119, 0, 100)
		end
	end

	-- dodanie nowej broni wyrzucającemu graczowi jeśli stoi na jakiejś
	for k, v in pairs(getElementsByType("colshape")) do
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
	function(uniqueID, xyzString)
		for k, v in pairs(getElementsByType("object")) do
			if not isElementStreamedIn(v) and getElementData(v, "uniqueID") == uniqueID then
				--outputChatBox("C_DEBUG: Phydrop: Dodatkowy sync niezestreamowanej broni o UID " .. uniqueID)
				local pos = split(xyzString, ";")
				setElementPosition(v, pos[1], pos[2], pos[3])
			end
		end
	end
)

addEvent("syncGroundWeapons", true)
addEventHandler("syncGroundWeapons", root,
	function(weapons)
		for k, v in pairs(weapons) do
			local pos = split(v.xyzString, ",")
			local wepObj = createObject(g_weapon[v.slot][v.weapon]["objectID"], pos[1], pos[2], pos[3], 90, 0, v.rotz)
			setElementInterior(wepObj, v.int)
			setElementFrozen(wepObj, true)
			setElementCollisionsEnabled(wepObj, false)
		end
	end
)

-- projectile lub object
function onWeaponHitted(element, matchingDimension)
	-- Projectile / obiekt musi być dopiero usuwany gdy gracz KTÓRY W NIEGO WEJDZIE go podniesie (bo przecież może nie mieć miejsca na slocie)

	if getElementType(element) == "player" and matchingDimension then
		getWeaponFromGround(element, source)
	end
end

function onWeaponLeave(element, matchingDimension)
	if element == localPlayer then
		if getElementData(source, "weapon") ~= false then
			stopDrawingWeapon()
		end
	end
end

function getWeaponFromGround(player, colshape)
	local weapon = getElementData(colshape, "weapon")

	if not getElementData(player, "wSlot" .. weapon.slot) and (not (weapon.slot == DEF_BOMB[1] and weapon.weapon == DEF_BOMB[2]) or getPlayerTeam(player) == g_team[1]) then -- jeśli gracz nie ma nic na tym slocie
	-- if not g_playerWeaponData[player][weapon.slot] then
		local related = getElementData(colshape, "related")
		destroyElement(related)
		destroyElement(colshape)

		if player == localPlayer then
			stopDrawingWeapon()
			-- opóźnienie ze względu na innych graczy, którzy 'mogą myśleć', że gracz nadal trzyma starą broń na slocie
			setTimer(triggerServerEvent, 200, 1, "onPhysicWeaponTaken", localPlayer, weapon.slot, weapon.weapon, weapon.totalAmmo, weapon.clipAmmo)
			playSound(":csrw-sounds/sounds/items/itempickup.wav")
		end
	else
		-- Gracz nie może podnieść broni bo ma już coś na tym slocie
		-- @todo: reset animacji?
		if player == localPlayer and getElementData(localPlayer, "currentSlot") == weapon.slot then
			startDrawingWeapon(weapon.slot, weapon.weapon)
		end
	end
end

--[[addEventHandler("onClientElementStreamIn", root,
    function()
    	if getElementType(source) == "object" and getElementData(source, "neededVelocity") ~= false then
    		local vel = getElementData(source, "neededVelocity")
    		setElementVelocity(source, vel[1], vel[2], vel[3])
    		setElementData(source, "neededVelocity", false)
    		outputChatBox("C_DEBUG: Phydrop: Broni o modelu " .. getElementModel(source) .. " została nadana prędkość.")
    	end
    end
)]]--

local render = { -- 1680x1050
	["img"] = {0.822*sX, 0.743*sY, 0.130*sX, 0.076*sY}, -- 1381, 781, 220, 80
	["txt"] = {0.824*sY, 0.953*sX, 0.845*sY} -- 1381, 866, 1602, 888
}
local text = getText("drop_text")
function drawWeapon()
	dxDrawImage(render["img"][1], render["img"][2], render["img"][3], render["img"][4], ":csrw-media/images/shop/" .. g_weapon[drop_currentWeapon[1]][drop_currentWeapon[2]]["image"], 0, 0, 0, tocolor(0, 0, 0, 145), true)
	dxDrawText(text, render["img"][1], render["txt"][1], render["txt"][2], render["txt"][3], tocolor(251, 121, 5, 211), 1, "default-bold", "center", "center", false, false, true, false, false)
end

function startDrawingWeapon(slot, weapon)
	if not drop_currentWeapon then
		drop_currentWeapon = {slot, weapon}
		addEventHandler("onClientRender", root, drawWeapon)
	else
		drop_currentWeapon = {slot, weapon}
	end
end

function stopDrawingWeapon()
	if drop_currentWeapon then
		drop_currentWeapon = false
		removeEventHandler("onClientRender", root, drawWeapon)
	end
end

function destroyGroundWeapons()
	for k, v in pairs(getElementsByType("colshape")) do
		local related = getElementData(v, "related")
		if related then -- jeśli colshape ma powiązaną broń
			destroyElement(v)
			destroyElement(related)
		end
	end
end

addCommandHandler("Drop weapon", function() dropWeapon() end)
bindKey("g", "down", "Drop weapon")
