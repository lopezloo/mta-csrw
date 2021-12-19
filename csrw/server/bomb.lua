-- Bomb object
local gl_bombObj

-- Bomb update timer
local gl_bombBeepTimer

function onBombPlanted(player)
	if g_roundData.bomb then
		-- Bomb is already planted
		return
	end

	if DEF_BOMB[1] == -1 or DEF_BOMB[2] == -1 then
		return
	end

	g_roundData.bomb = true
	csTakeWeapon(player, DEF_BOMB[1], DEF_BOMB[2])

	local x, y, z = getElementPosition(player)
	gl_bombObj = createObject(g_weapon[DEF_BOMB[1]][DEF_BOMB[2]]["objectID"], x, y, z - 0.7, -90, 90, 0)
	gl_bombObj.interior = player.interior
	gl_bombObj.dimension = player.dimension
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
	local light = createMarker(x, y, z, "corona", 0.5, 255, 0, 0)
	setElementInterior(light, getElementInterior(gl_bombObj))
	setTimer(destroyElement, 50, 1, light)
	triggerClientEvent("cPlaySound", root, "weapons/c4/c4_beep1.wav", x, y, z, 50)

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
	createExplosion(x, y, z, 6)
	triggerClientEvent("cPlaySound", root, "weapons/c4/c4_explode1.wav", x, y, z, 100)

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

function onBombDefused(player)
	if not g_roundData.bomb then
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
