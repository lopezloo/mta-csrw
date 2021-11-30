local bomb
local bombBeepTimer

function onBombPlanted(player)
	csTakeWeapon(player)

	local x, y, z = getElementPosition(player)
	bomb = createObject(g_weapon[DEF_BOMB[1]][DEF_BOMB[2]]["objectID"] or 1654, x, y, z - 0.7, -90, 90, 0)
	setElementInterior(bomb, getElementInterior(player))
	setElementCollisionsEnabled(bomb, false)
	setElementData(bomb, "bomb", true)

	bombBeepTimer = setTimer(bombBeep, 2000, 1, 2000)
	triggerClientEvent("cPlaySound", root, "radio/bombpl.wav")
	g_roundData.bomb = true
end
addEvent("plantBomb", true)
addEventHandler("plantBomb", root, onBombPlanted)

function bombBeep(interval)
	local x, y, z = getElementPosition(bomb)
	local light = createMarker(x, y, z, "corona", 0.5, 255, 0, 0)
	setElementInterior(light, getElementInterior(bomb))
	setTimer(destroyElement, 50, 1, light)
	triggerClientEvent("cPlaySound", root, "weapons/c4/c4_beep1.wav", x, y, z, 50)

	interval = interval-50 -- ~40 s
	if interval <= 0 then
		onBombExploded()
	else
		bombBeepTimer = setTimer(bombBeep, interval, 1, interval)
	end
end

function onBombExploded()
	local x, y, z = getElementPosition(bomb)
	createExplosion(x, y, z, 6)
	triggerClientEvent("cPlaySound", root, "weapons/c4/c4_explode1.wav", x, y, z, 100)

	if countPlayersInTeam(g_team[2]) > 0 then
		onRoundEnd(1, 2) -- jeśli jest conajmniej 1 CT to wygrywa TT
	else
		onRoundEnd(3, 2) -- remis
	end
end

function destroyBomb()
	if bomb and isElement(bomb) then
		destroyElement(bomb)
		if isTimer(bombBeepTimer) then
			killTimer(bombBeepTimer)
		end
	end
	g_roundData.bomb = false
end

function onBombDefused(player)
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
