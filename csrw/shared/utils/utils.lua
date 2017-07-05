function isElementInRangeOfPoint(ele, x, y, z, range)
	if ele and x and y and z and range then
		local x0, y0, z0 = getElementPosition(ele)
		return getDistanceBetweenPoints3D(x0, y0, z0, x,y,z) <= range
	end
	return false
end

function rgbToHex(r, g, b)
	return string.format("#%02X%02X%02X", r, g, b)
end

function math.round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function round(num)
	return math.round(num)
end

function changeViewToRandomCamera(player)
	if not localPlayer and not player then return end

	local int, x, y, z, tX, tY, tZ, roll, fov = getRandomCameraPos()
	setElementInterior(player or localPlayer, int)
	if localPlayer then
		setCameraMatrix(x, y, z, tX, tY, tZ, roll, fov)
		fadeCamera(true)
		outputDebugString("Camera changed to " .. x .. ", " .. y .. ", " .. z)
	else
		setCameraMatrix(player, x, y, z, tX, tY, tZ, roll, fov)
		fadeCamera(player, true)
		outputConsole("Camera changed to " .. x .. ", " .. y .. ", " .. z, player)
	end


	--[[if not lobbyPed then
		lobbyPed = createPed(104, 313.85488891602, 1832.0942382813, 6.9)
		setElementFrozen(lobbyPed, false)
		--setElementCollisionsEnabled(lobbyPed, false)
		setElementRotation(lobbyPed, 90)
		setPedAnimation(lobbyPed, "crack", "crckidle4", -1, true, false, false, false)
	end]]--
end

function getRandomCameraPos(ifNoReturnSpawn)
	local cameras = getElementsByType("camera")
	if #cameras > 0 then
		local cam = cameras[math.random(1, #cameras)]
		local x = getElementData(cam, "posX")
		local y = getElementData(cam, "posY")
		local z = getElementData(cam, "posZ")

		local tX = getElementData(cam, "targetX")
		local tY = getElementData(cam, "targetY")
		local tZ = getElementData(cam, "targetZ")

		local roll = getElementData(cam, "roll") or 0
		local fov = getElementData(cam, "fov") or 70

		local int = getElementData(cam, "interior") or 0
		return int, x, y, z, tX, tY, tZ, roll, fov
	else
		if ifNoReturnSpawn then
			local spawnsTT = getElementsByType("spawntt")
			local spawnSlot = 1 -- slot spawnu

			local int = getElementData(spawnsTT[spawnSlot], "interior") or 0
			local x2 = getElementData(spawnsTT[spawnSlot], "posX")
			local y2 = getElementData(spawnsTT[spawnSlot], "posY")
			local z2 = getElementData(spawnsTT[spawnSlot], "posZ")
			return int, x2, y2, z2 + 5, 0, 0, 0, 0, 70
		else
			return 0, 300.59533691406, 1836.1302490234, 6.973030090332, 393.78421020508, 1803.8177490234, 23.457494735718
		end
	end
end

function getWeaponSkillID(gtaWeaponID)
	if not gtaWeaponID then return false end
	gtaWeaponID = tonumber(gtaWeaponID)

	-- gtaSLOT 2 (handguns) csSlot 2
	if gtaWeaponID == 22 then return 69 -- "WEAPONTYPE_PISTOL_SKILL"
	elseif gtaWeaponID == 23 then return 70 -- "WEAPONTYPE_PISTOL_SILENCED_SKILL"
	elseif gtaWeaponID == 24 then return 71 -- "WEAPONTYPE_DESERT_EAGLE_SKILL"

	-- gtaSlot 3 (shotguns) csSlot 1
	elseif gtaWeaponID == 25 then return 72 -- "WEAPONTYPE_SHOTGUN_SKILL"
	elseif gtaWeaponID == 26 then return 73 -- "WEAPONTYPE_SAWNOFF_SHOTGUN_SKILL"
	elseif gtaWeaponID == 27 then return 74 -- "WEAPONTYPE_SPAS12_SHOTGUN_SKILL"

	-- gtaSlot 4 (sub-machine guns) csSlot 1
	elseif gtaWeaponID == 28 then return 75 -- "WEAPONTYPE_MICRO_UZI_SKILL"
	elseif gtaWeaponID == 29 then return 76 -- "WEAPONTYPE_MP5_SKILL"

	-- gtaSlot 5 (assault) csSlot 1
	elseif gtaWeaponID == 30 then return 77 -- "WEAPONTYPE_AK47_SKILL"
	elseif gtaWeaponID == 31 then return 78 -- "WEAPONTYPE_M4_SKILL"
	elseif gtaWeaponID == 34 then return 79 -- "WEAPONTYPE_SNIPERRIFLE_SKILL"
	else return false end
end

function getWeaponSkillAmount(skillName)
	if skillName == "medium" then return 600 -- wartość pośrednia
	elseif skillName == "pro" then return 999
	elseif skillName == "ultra" then return 1000 -- podwójne bronie
	else return 0 end
end

function playAnimationWithWalking(block, anim, player)
	if localPlayer then player = localPlayer end
	if not player then return end
	setElementData(player, "anim", block .. ":" .. anim)
end

function stopAnimationWithWalking(player)
	if localPlayer then player = localPlayer end
	if player and getElementData(player, "anim") ~= false then
		setElementData(player, "anim", false)
	end
end
-- sync w c walkanim.lua

function getOppositeTeam(team)
	if team == g_team[1] then return g_team[2]
	elseif team == g_team[2] then return g_team[1]
	elseif team == g_team[3] then return g_team[3] end
	return false
end

function getTeamID(team)
	for k, v in pairs(g_team) do
		if team == v then
			return k
		end
	end
end

function setPlayerMoneyEx(player, money)
	if money > g_config["maxmoney"] then
		money = g_config["maxmoney"]
	elseif money < 0 then
		money = 0
	end
	setElementData(player, "money", money)
end

function takePlayerMoneyEx(player, money)
	setPlayerMoneyEx(player, getElementData(player, "money") - money)
end

function givePlayerMoneyEx(player, money)
	setPlayerMoneyEx(player, getElementData(player, "money") + money)
end

function getPlayerMoneyEx(player)
	return getElementData(player, "money")
end

function getPositionFromElementOffset(element,offX,offY,offZ)
	local m = getElementMatrix ( element )  -- Get the matrix
	local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]  -- Apply transform
	local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
	local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
	return x, y, z                               -- Return the transformed point
end

function getPointFromDistanceRotation(x, y, dist, angle)
  local a = math.rad(90 - angle)
  local dx = math.cos(a) * dist
  local dy = math.sin(a) * dist
  return x + dx, y + dy
end

function output(text)
	if localPlayer then
		outputChatBox(text)
	else
		outputServerLog(text)
	end
end

function table.find(table, toFind)
	for k, v in pairs(table) do
		if v == toFind then
			return k
		end
	end
	return false
end
