-- Bomb object
local gl_bombObj

-- Bomb update timer
local gl_bombBeepTimer

local BOMB_BEEP_SOUND_DISTANCE = 70
local BOMB_EXPLOSION_SOUND_DISTANCE = 120

-- Player is sending request to plant bomb
function onBombPlanted()
	if not client or client ~= source then
		return
	end

	if g_roundData.bomb then
		-- Bomb is already planted
		return
	end

	if not isRoundStarted() then
		return
	end

	if DEF_BOMB[1] == -1 or DEF_BOMB[2] == -1 then
		-- Bomb weapon isn't defined
		return
	end

	if not g_match.bombsites then
		-- Bomb defusals are disabled
		return
	end

	if client.health == 0 or client.team ~= g_team[1] then
		return
	end

	local currentSlot = client:getData("currentSlot")
	if not currentSlot or currentSlot ~= DEF_BOMB[1] then
		-- Player current weapon isn't bomb
		return
	end

	if g_playerWeaponData[client][ DEF_BOMB[1] ].weapon ~= DEF_BOMB[2] then
		-- Player doesn't have bomb
		return
	end

	local inBombsite = false
	for _, v in pairs(getElementsByType("marker")) do
		if v:getData("isBombsite") and client:isWithinMarker(v) and client.interior == v.interior and client.dimension == v.dimension then
			inBombsite = true
			break
		end
	end

	if not inBombsite then
		-- Player is not at bomb site
		return
	end

	g_roundData.bomb = true
	csTakeWeapon(client, DEF_BOMB[1], DEF_BOMB[2])

	local x, y, z = getElementPosition(client)
	gl_bombObj = createObject(g_weapon[DEF_BOMB[1]][DEF_BOMB[2]]["objectID"], x, y, z - 0.75, -90, 90, 0)
	gl_bombObj.interior = client.interior
	gl_bombObj.dimension = client.dimension
	gl_bombObj.collisions = false
	gl_bombObj:setData("bomb", true)

	gl_bombBeepTimer = setTimer(bombBeep, 2000, 1, 2000)
	triggerClientEvent("cPlaySound", root, "radio/bombpl.wav")
end
addEvent("plantBomb", true)
addEventHandler("plantBomb", root, onBombPlanted)

function bombBeep(interval)
	if not g_roundData.bomb then
		return
	end

	local x, y, z = getElementPosition(gl_bombObj)
	local light = createMarker(x, y, z + 0.075, "corona", 0.1, 255, 0, 0)
	light.interior = gl_bombObj.interior
	light.dimension = gl_bombObj.dimension
	setTimer(destroyElement, 50, 1, light)
	triggerClientEvent("cPlaySound", root, "weapons/c4/c4_beep1.wav", x, y, z, BOMB_BEEP_SOUND_DISTANCE)

	interval = interval-50 -- ~40 s
	if interval <= 0 then
		onBombExploded()
	else
		gl_bombBeepTimer = setTimer(bombBeep, interval, 1, interval)
	end
end

function onBombExploded()
	if not g_roundData.bomb then
		return
	end

	local x, y, z = getElementPosition(gl_bombObj)
	createExplosion(x, y, z, EXPLOSION_BOAT)
	triggerClientEvent("cPlaySound", root, "weapons/c4/c4_explode1.wav", x, y, z, BOMB_EXPLOSION_SOUND_DISTANCE)

	if countPlayersInTeam(g_team[2]) > 0 then
		onRoundEnd(1, 2) -- jeśli jest conajmniej 1 CT to wygrywa TT
	else
		onRoundEnd(3, 2) -- remis
	end
end

function destroyBomb()
	if not g_roundData.bomb then
		return
	end

	if gl_bombBeepTimer and isTimer(gl_bombBeepTimer) then
		killTimer(gl_bombBeepTimer)
	end

	if gl_bombObj and isElement(gl_bombObj) then
		gl_bombObj:destroy()
	end
	g_roundData.bomb = false
end

-- Player is sending request to defuse bomb
function onBombDefused()
	if not client or client ~= source then
		return
	end

	if not g_roundData.bomb then
		-- Bomb isn't planted
		return
	end

	if not isRoundStarted() then
		return
	end

	if client.health == 0 or client.team ~= g_team[2] then
		return
	end

	if client.interior ~= gl_bombObj.interior or client.dimension ~= gl_bombObj.dimension then
		return
	end

	local dist = getDistanceBetweenPoints3D(client.position, gl_bombObj.position)
	if dist >= 5 then
		-- Player is too far away from bomb
		return
	end

	triggerClientEvent("cPlaySound", root, "radio/bombdef.wav")
	destroyBomb()
	
	setTimer(
		function()
			if countPlayersInTeam(g_team[1]) > 0 then
				-- jeśli jest conajmniej 1 TT to wygrywa CT
				onRoundEnd(2, 3)
			else
				-- remis
				onRoundEnd(3, 3)
			end
		end, 1500, 1)
end
addEvent("defuseBomb", true)
addEventHandler("defuseBomb", root, onBombDefused)
