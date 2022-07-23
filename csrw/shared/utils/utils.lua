local DEFAULT_CAMERA_POSITION = {0, 300.59533691406, 1836.1302490234, 6.973030090332, 393.78421020508, 1803.8177490234, 23.457494735718}

function isElementInRangeOfPoint(ele, x, y, z, range)
	if ele and x and y and z and range then
		local x0, y0, z0 = getElementPosition(ele)
		return getDistanceBetweenPoints3D(x0, y0, z0, x, y, z) <= range
	end
	
	return false
end

function rgbToHex(r, g, b)
	return string.format("#%02X%02X%02X", r, g, b)
end

function math.round(num)
	local under = math.floor(num)
	local upper = math.floor(num) + 1
	local underV = -(under - num)
	local upperV = upper - num
	if upperV > underV then
		return under
	end

	return upper
end

function changeViewToRandomCamera(player)
	if not localPlayer and not player then return end

	local int, x, y, z, tX, tY, tZ, roll, fov = getRandomCameraPos()
	setElementInterior(player or localPlayer, int)
	
	if localPlayer then
		setCameraMatrix(x, y, z, tX, tY, tZ, roll, fov)
		fadeCamera(true)
	
	else
		setCameraMatrix(player, x, y, z, tX, tY, tZ, roll, fov)
		fadeCamera(player, true)
	end
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
	end

	if ifNoReturnSpawn then
		local spawnsTT = getElementsByType("spawntt")
		local spawnSlot = 1 -- slot spawnu

		local int = getElementData(spawnsTT[spawnSlot], "interior") or 0
		local x2 = getElementData(spawnsTT[spawnSlot], "posX")
		local y2 = getElementData(spawnsTT[spawnSlot], "posY")
		local z2 = getElementData(spawnsTT[spawnSlot], "posZ")
		return int, x2, y2, z2 + 5, 0, 0, 0, 0, 70
	end

	return unpack(DEFAULT_CAMERA_POSITION)
end

-- Returns weapon skill ID from weapon ID
function getWeaponSkillID(gtaWeaponID)
	if not gtaWeaponID then return false end
	gtaWeaponID = tonumber(gtaWeaponID)

	-- gtaSLOT 2 (handguns) csSlot 2
	if gtaWeaponID == WEAPON_COLT45 then return STAT_PISTOL_SKILL
	elseif gtaWeaponID == WEAPON_SILENCED then return STAT_PISTOL_SILENCED_SKILL
	elseif gtaWeaponID == WEAPON_DEAGLE then return STAT_DEAGLE_SKILL

	-- gtaSlot 3 (shotguns) csSlot 1
	elseif gtaWeaponID == WEAPON_SHOTGUN then return STAT_SHOTGUN_SKILL
	elseif gtaWeaponID == WEAPON_SAWEDOFF then return STAT_SAWNOFF_SHOTGUN_SKILL
	elseif gtaWeaponID == WEAPON_COMBAT_SHOTGUN then return STAT_COMBAT_SHOTGUN_SKILL

	-- gtaSlot 4 (sub-machine guns) csSlot 1
	elseif gtaWeaponID == WEAPON_UZI then return STAT_MICRO_UZI_SKILL
	elseif gtaWeaponID == WEAPON_MP5 then return STAT_MP5_SKILL

	-- gtaSlot 5 (assault) csSlot 1
	elseif gtaWeaponID == WEAPON_AK47 then return STAT_AK47_SKILL
	elseif gtaWeaponID == WEAPON_M4 then return STAT_M4_SKILL
	elseif gtaWeaponID == WEAPON_SNIPER then return STAT_SNIPER_SKILL end
	
	return false
end

function getWeaponSkillAmount(skillName)
	if skillName == "poor" then
		return 0

	elseif skillName == "medium" then
		return 600
	
	elseif skillName == "pro" then
		return 999
	
	elseif skillName == "ultra" then
		-- dual wield
		return 1000
	
	else
		return 0
	end
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
-- sync in c walkanim.lua

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

	player:setData("money", money)
end

function takePlayerMoneyEx(player, money)
	setPlayerMoneyEx(player, getElementData(player, "money") - money)
end

function givePlayerMoneyEx(player, money)
	setPlayerMoneyEx(player, getElementData(player, "money") + money)
end

function getPlayerMoneyEx(player)
	return player:getData("money")
end

function getPositionFromElementOffset(element, offX, offY, offZ)
	-- Get the matrix
	local m = getElementMatrix(element)

	-- Apply transform
	local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
	local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
	local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]

	return x, y, z
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

function table.find(table, find)
	if not table or not find then return false end
	
	for k, v in pairs(table) do
		if v == find then
			return k
		end
	end
	
	return false
end

function strip()
	return string.gsub(strval, "^%s*(.-)%s*$", "%1")
end

function getTeamSkinValue(team)
	if team == g_team[1] then
		return 100
	
	elseif team == g_team[2] then
		return 104
	end
	
	return 0
end

function findRotation(x1, y1, x2, y2)
	local t = -math.deg(math.atan2(x2 - x1, y2 - y1))
	if t < 0 then t = t + 360 end
	return t
end
