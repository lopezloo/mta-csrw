if true then
	-- Disable debug stuff
	return
end

local debug = {
	enabled,
}

function enableDebug(cmd, level)
	if debug.enabled then
		if not level then
			level = 1
		end

		level = tonumber(level)
		if level > 0 and level <= 5 then
			debug[level] = not debug[level]
			outputChatBox("debug[" .. level .. "] = " .. tostring(debug[level]))
			if debug[level] then
				addEventHandler("onClientRender", root, loadstring("return drawDebug_" .. level .. "()"))
			else
				removeEventHandler("onClientRender", root, loadstring("return drawDebug_" .. level .. "()"))
			end
		end
	end
end
addCommandHandler("debug", enableDebug)

function drawDebug_1()
	local text = ""
	for i = 1, #g_weapon do
		if not g_playerWeaponData[i] then
			text = text .. i .. " | nope!\n#FFFFFF"
		else
			if i == getElementData(localPlayer, "currentSlot") then
				text = text .. "#D12828"
			end
			text = text .. i .. " | weapon " .. tostring(g_playerWeaponData[i].weapon) .. " | clip " .. tostring(g_playerWeaponData[i].clip) .. " | total " .. tostring(g_playerWeaponData[i].ammo) .. " | wSlot " .. tostring(getElementData(localPlayer, "wSlot" .. i)) .. "\n#FFFFFF"
		end
	end

	text = text .. "\n\ncurrentWeapon: " .. tostring(g_playerWeaponData.current) .. " | currentSlot: " .. tostring(getElementData(localPlayer, "currentSlot"))
	text = text .. "\ngetPedTotalAmmo: " .. tostring(getPedTotalAmmo(localPlayer)) .. "\ngetPedAmmoInClip: " .. getPedAmmoInClip(localPlayer)

	local a = {}
	a[1], a[2] = getPedAnimation(localPlayer)
	text = text .. "\nwalkAnim: " .. tostring(getElementData(localPlayer, "anim")) .. " | getPedAnimation: " .. tostring(a[1]) .. ":" .. tostring(a[2])

	--[[local b = {}
	b[1], b[2] = getPedAnimationData(localPlayer)
	text = text .. "\ngetPedAnimationData: " .. tostring(a[1]) .. ":" .. tostring(a[2])]]--

	text = text .. "\nducked: " .. tostring(isPedDucked(localPlayer)) .. " | flashed: " .. tostring(g_player.flashed) .. " | canChangeSlot: " .. tostring(g_player.canChangeSlot) .. " | reloading: " .. tostring(g_player.reloading)
	text = text .. "\ntask: " .. tostring(getPedSimplestTask(localPlayer))
	text = text .. "\nsmokeUpdate: " .. tostring(g_misc.smokeUpdate)
	text = text .. "\nprojectiles: " .. #getElementsByType("projectile") .. " | colshapes: " .. #getElementsByType("colshape")
	text = text .. "\nlocalization: " .. getLocalization().name .. " (" .. getLocalization().code .. ")"
	text = text .. "\naim: " .. tostring(getControlState("aim_weapon")) .. " | shoot: " .. tostring(getControlState("fire"))
	text = text .. "\nskin: " .. localPlayer.model
	text = text .. "\nhelmet: " .. tostring(g_player.items.helmet) .. " | defuser: " .. tostring(g_player.items.defuser)
	text = text .. "\ncamRot: " .. tostring( getPedCameraRotation(localPlayer) )
	text = text .. "\nmoveState: " .. tostring( getPedMoveState(localPlayer) )

	local target = getCameraTarget()
	if target and target ~= localPlayer then
		text = text .. "\nSPEC DEBUG (spectating: " .. getPlayerName(target) .. ")\n"

		for i = 1, #g_weapon do
			local weapon = getElementData(target, "wSlot" .. i)
			if weapon then
				if i == getElementData(target, "currentSlot") then
					text = text .. "#D12828"
				end
				text = text .. i .. " | weapon " .. weapon .. "\n#FFFFFF"
			else
				text = text .. i .. " | nope!\n#FFFFFF"
			end
		end

		text = text .. "#FFFFFF\nducked: " .. tostring(isPedDucked(target)) .. " | aliveData: " .. tostring(getElementData(target, "alive"))
		text = text .. "\ntask: " .. tostring( getPedSimplestTask(target) )
		text = text .. "\ncamRot: " .. tostring( getPedCameraRotation(target) )
		text = text .. "\nmoveState: " .. tostring( getPedMoveState(target) )
	end

	dxDrawText(text, 26, 300, 483, 745, tocolor(255, 255, 255, 255), 1, "default-bold", "left", "top", false, false, false, true, false)
end

-- draw other info about player debug
function drawDebug_2()
	for _, v in pairs(getElementsByType("player")) do
		if v ~= localPlayer and isElementOnScreen(v) then
			local x, y, z = getPedBonePosition(v, 8)
			local x, y = getScreenFromWorldPosition(x, y, z)
			local text = getPlayerName(v) .. "\nwalkAnim: " .. tostring(getElementData(v, "anim"))

			local a = {}
			a[1], a[2] = getPedAnimation(v)
			text = text .. "\nanim: " .. tostring(a[1]) .. ":" .. tostring(a[2]) .. "\nducked: " .. tostring(isPedDucked(v))

			local slot = tostring(getElementData(v, "currentSlot"))
			local weapon = tostring(getElementData(v, "wSlot" .. slot))
			text = text .. "\nslot: " .. slot .. " weapon: " .. weapon
			text = text .. "\nammo: " .. tostring(getElementData(v, "wSlot" .. slot .. "Clip")) .. "|" .. tostring(getElementData(v, "wSlot" .. slot .. "Ammo"))
			text = text .. "\nammoGTA: " .. getPedAmmoInClip(v) .. "|" .. getPedTotalAmmo(v)
			text = text .. "\nHP: " .. tostring(getElementData(v, "health")) .. " Armor: " .. tostring(getElementData(v, "armor"))
			text = text .. "\nHPGTA: " .. getElementHealth(v) .. " ArmorGTA: " .. getPedArmor(v)

			dxDrawText(text, x, y)
		end
	end
end

-- weapons lying on the ground debug
function drawDebug_3()
	for _, v in pairs(getElementsByType("colshape")) do
		--if isElementOnScreen(v) then -- nie dziala na colshape o.o
		local data = getElementData(v, "groundWeapon")
		if data ~= false then
			local x, y, z = getElementPosition(v)
			local x, y = getScreenFromWorldPosition(x, y, z)

			local w = split(data, ":") -- id markera, slot broni, broń
			w[1], w[2], w[3] = tonumber(w[1]), tonumber(w[2]), tonumber(w[3])

			dxDrawText("ID " .. w[1] .. " Weapon " .. w[3] .. " Slot " .. w[3], x, y)
		end
	end
end

-- local player bones debug
function drawDebug_4()
	for i = 1, 60 do
		local x, y, z = getPedBonePosition(localPlayer, i)
		if x and y and z then
			local x, y = getScreenFromWorldPosition(x, y, z)
			if x and y then
				dxDrawText(i, x, y)
			end
		end
	end
end

-- show distance to other players
function drawDebug_5()
	for _, v in pairs(getElementsByType("player")) do
		if v ~= localPlayer and isElementStreamedIn(v) and getElementData(v, "alive") and isElementOnScreen(v) then
			local x, y, z = getElementPosition(v)
			local distance = getDistanceBetweenPoints3D(x, y, z, getElementPosition(localPlayer))
			dxDrawLine3D(x, y, z, getElementPosition(localPlayer))
			x, y = getScreenFromWorldPosition(x, y, z)
			if x and y then
				dxDrawText("distance: " .. tostring(distance), x, y)
			end
		end
	end
end

-- shots debug
local miscDebug = {
	impacts = false
}

addCommandHandler("csrw_showimpacts",
	function()
		miscDebug.impacts = not miscDebug.impacts
		if miscDebug.impacts then
			addEventHandler("onClientPlayerWeaponFire", root, drawImpacts)
		else
			removeEventHandler("onClientPlayerWeaponFire", root, drawImpacts)
		end
		outputChatBox("csrw_showimpacts = " .. tostring(miscDebug.impacts))
	end
)

function drawImpacts(weapon, ammo, clip, hitX, hitY, hitZ, hitElement, startX, startY, startZ)
	if hitX and hitY and hitZ then
		local function drawThisImpact()
			local x, y = getScreenFromWorldPosition(hitX, hitY, hitZ)
			if x and y then
				dxDrawRectangle(x - 2, y - 2, 4, 4, tocolor(0, 255, 0))
			end
		end
		
		addEventHandler("onClientRender", root, drawThisImpact)
		setTimer(
			function()
				removeEventHandler("onClientRender", root, drawThisImpact)
			end, 2000, 1
		)
	end
end

if false then
function spawnDebug()
	for _, v in pairs(getElementsByType("spawntt")) do
		local x, y, z = getElementData(v, "posX"), getElementData(v, "posY"), getElementData(v, "posZ")
		x, y = getScreenFromWorldPosition(x, y, z)
		if x and y then
			dxDrawText("Spawn TT (int " .. (getElementData(v, "interior") or 0) .. ")", x, y, x, y, tocolor(getTeamColor(g_team[1])))
		end
	end

	for _, v in pairs(getElementsByType("spawnct")) do
		local x, y, z = getElementData(v, "posX"), getElementData(v, "posY"), getElementData(v, "posZ")
		x, y = getScreenFromWorldPosition(x, y, z)
		if x and y then
			dxDrawText("Spawn CT (int " .. (getElementData(v, "interior") or 0) .. ")", x, y, x, y, tocolor(getTeamColor(g_team[2])))
		end
	end
	dxDrawText("TT spawns: " .. #getElementsByType("spawntt") .. "\nCT spawns: " .. #getElementsByType("spawnct"), 300, 300)
end
addEventHandler("onClientRender", root, spawnDebug)
end
