local smokeGrenades = {}

local timer_updateProjectileLines
local lineProjectiles = {} -- lista projecttile z linami
local projectileLines = {} -- liny projectile
local grenades = {
	smokes = {},
	decoys = {}
}

addEventHandler("onClientProjectileCreation", root,
	function(creator)
		if getProjectileType(source) == 16 then -- grenade
			addEventHandler("onClientElementDestroy", source, onHEGrenadeExploded)
		end

		if getProjectileType(source) == 17 then -- 17 = teargas
			local slot = getElementData(creator, "currentSlot")
			if slot then
				local weapon = getElementData(creator, "wSlot" .. slot)
				if weapon then
					if g_weapon[slot][weapon]["objectID"] == "-2" then -- flashbang
						setProjectileCounter(source, 99999) -- żeby przypadkiem ten granat nie jebnął przed timerem
						setTimer(onFlashBangExploded, 2000, 1, source) -- 2000 to czas wybuchu flasha od jego wyrzucenia z ręki					
					elseif g_weapon[slot][weapon]["objectID"] == "-3" then -- decoy
						setProjectileCounter(source, 99999)
						-- Pobieranie najlepszej broni gracza
						local weapon = {1, getElementData(creator, "wSlot1")}
						if not weapon[2] then
							weapon = {2, getElementData(creator, "wSlot2")}
						end
						setTimer(onDecoyExploded, 2000, 1, source, weapon[1], weapon[2])
					else
						setTimer(onSmokeGrenadeExploded, 3000, 1, source) -- prawdziwy smoke
					end
				end
			end
		end

		--outputChatBox("onClientProjectileCreation; creator: " .. tostring(creator) .. " (element " .. getElementType(creator) .. ")")
		if g_player.spectating and creator and getElementType(creator) == "player" then -- + getElementData(source, "spectator")
			projectileLines[source] = {}
			table.insert(lineProjectiles, source)
			if not isTimer(timer_updateProjectileLines) then
				setTimer(updateProjectileLines, 50, 0)
			end
			
			local x, y, z = getElementPosition(source)
			local r, g, b = getTeamColor(getPlayerTeam(creator))
			setElementData(source, "oldPos", {x, y, z}, false)
			setElementData(source, "color", {r, g, b}, false)
			addEventHandler("onClientElementDestroy", source, onProjectileWithLineDestroy)
		end
	end
)

function updateProjectileLines()
	for k, v in pairs(lineProjectiles) do
		local o = getElementData(v, "oldPos")
		local x, y, z = getElementPosition(v)
		local color = getElementData(v, "color")

		function drawProjectileLine()
			local x0, y0 = getScreenFromWorldPosition(o[1], o[2], o[3])
			local x, y = getScreenFromWorldPosition(x, y, z)
			if x0 and x then
				dxDrawLine(x0, y0, x, y, tocolor(color[1], color[2], color[3], 230), 2, false)
			end
			--dxDrawLine3D(o[1], o[2], o[3], x, y, z, tocolor(color[1], color[2], color[3]), 2, true)
		end
		addEventHandler("onClientRender", root, drawProjectileLine)
		table.insert(projectileLines[v], drawProjectileLine)
		setElementData(v, "oldPos", {x, y, z}, false)
	end
end

function onProjectileWithLineDestroy()
	local x, y, z = getElementPosition(source)
	local color = getElementData(source, "color")
	local point = createMarker(x, y, z, "corona", 0.25, color[1], color[2], color[3])
	setElementInterior(point, getElementInterior(source))
	table.remove(lineProjectiles, table.find(lineProjectiles, source))
	if #lineProjectiles == 0 and isTimer(timer_updateProjectileLines) then
		killTimer(timer_updateProjectileLines)
	end

	setTimer(
			function(proj)
				destroyElement(point)
				for k, v in pairs(projectileLines[proj]) do
					removeEventHandler("onClientRender", root, v)
				end
				projectileLines[proj] = nil
			end, 3000, 1, source)
end

function onFlashBangExploded(grenade)
	if not isElement(grenade) then return end
	local x, y, z = getElementPosition(grenade)
	local x2, y2, z2 = getElementPosition(localPlayer)
	
	if not isLineOfSightClear(x, y, z, x2, y2, z2, true, true, false, true, true, false, false, grenade) then -- jeśli flashbang jest za jakimś obiektem
		setSoundMaxDistance(playSound3D(":csrw-sounds/sounds/weapons/flashbang/flashbang_explode2.wav", x, y, z), 50)
		destroyElement(grenade)
		return
	end

	local distance = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
	local exploded
	if isElementOnScreen(grenade) then -- jeśli patrzy na tego flasha
		if distance <= 50 then -- jeśli gracz jest w zasięgu flasha
			exploded = true
			showRadar(false)
			fadeCamera(false, 0.1, 255, 255, 255)
			g_player.flashed = true
			setTimer(
				function()
					fadeCamera(true, 1)
					showRadar(true)
					g_player.flashed = false
				end, 30000 / distance, 1)		
		end
	elseif distance <= 12 then -- jeśli nie patrzy (np. obrócił sie) i jest w odległości 7 metrów od flasha
		exploded = true
		fadeCamera(false, 0.1, 255, 255, 255)
		setTimer(
			function()
				fadeCamera(true, 1) 
				showRadar(true)
				g_player.flashed = false
			end, 5000 / distance, 1)
	end
	destroyElement(grenade) -- usuwanie prawdziwego granata
	createEffect("camflash", x, y, z)

	if exploded then
		playSound(":csrw-sounds/sounds/weapons/flashbang/flash.ogg")
	else
		setSoundMaxDistance(playSound3D(":csrw-sounds/sounds/weapons/flashbang/flashbang_explode2.wav", x, y, z), 50)
	end
end

function onDecoyExploded(grenade, slot, weapon)
	if not isElement(grenade) then return end

	local x, y, z = getElementPosition(grenade)
	local rx, ry, rz = getElementRotation(grenade)
	local int = getElementInterior(grenade)

	local groundZ = getGroundPosition(x, y, z)
	groundZ = groundZ + 0.2

	destroyElement(grenade)
	local obj = createObject(343, x, y, z, rx, ry, rz)
	table.insert(grenades.decoys, obj)
	setElementInterior(obj, int)
	moveObject(obj, 100*(z - groundZ), x, y, groundZ)

	local sound = ":csrw-sounds/sounds/weapons/ak47/ak47-1.wav"
	if weapon then
		sound = ":csrw-sounds/sounds/weapons/" .. g_weapon[slot][weapon]["shotSound"]
	end

	for i=1, 20 do
		setTimer(
			function()
				if not obj then return end
				local x, y, z = getElementPosition(obj)

				if i == 20 then
					createExplosion(x, y, z, 12) -- mała eksplozja
					local sound = playSound3D(":csrw-sounds/sounds/weapons/hegrenade/explode3.wav", x, y, z)
					setSoundMaxDistance(sound, 75)
					table.remove(grenades.decoys, table.find(grenades.decoys, obj))
					destroyElement(obj)
				else
					fxAddDebris(x, y, z, 255, 119, 0, 255, 0.1, 3)
					local s = playSound3D(sound, x, y, z)
					setSoundMaxDistance(s, 50)
					setTimer(
						function()
							local s = playSound3D(sound, x, y, z)
							setSoundMaxDistance(s, 50)
						end, 250, 1)
				end
			end, 2000*i, 1)
	end
end

function onSmokeGrenadeExploded(grenade)
	if not isElement(grenade) then return end
	local x, y, z = getElementPosition(grenade)
	local particle = createObject(915, x, y, z-2)
	setElementCollisionsEnabled(particle, false)
	setElementInterior(particle, getElementInterior(grenade))
	setObjectScale(particle, 0.8)
	table.insert(grenades.smokes, particle)

	local sound = playSound3D(":csrw-sounds/sounds/weapons/smokegrenade/sg_explode.wav", x, y, z)
	setSoundMaxDistance(sound, 60)

	setElementData(grenade, "particle", particle, false)
	table.insert(smokeGrenades, grenade)

	local groundZ = getGroundPosition(x, y, z)
	if getDistanceBetweenPoints3D(x, y, z, x, y, groundZ) <= 1 then -- leży już na ziemi, można go usuwać aby zwolnić limit
		-- smoke już leży na ziemi nieruchomo, więc nie trzeba aktualizować pozycji dymu
		table.remove(smokeGrenades, table.find(smokeGrenades, grenade))
		destroyElement(grenade)	
		setTimer(
			function()
				if particle then
					table.remove(grenades.smokes, table.find(grenades.smokes, particle))
					destroyElement(particle)
				end
			end, 20000, 1)
	else
		if not g_misc.smokeUpdate and #smokeGrenades == 1 then
			g_misc.smokeUpdate = true
			addEventHandler("onClientPreRender", root, updateSmokeGrenadeParticles) -- włączanie tego eventu tylko na czas gdy są stworzone smokesy
		end
		addEventHandler("onClientElementDestroy", grenade, onSmokeGrenadeDestroy)
	end
end

function updateSmokeGrenadeParticles()
	for k, v in pairs(smokeGrenades) do
		local x, y, z = getElementPosition(v)
		setElementPosition(getElementData(v, "particle"), x, y, z-2)
	end
	--dxDrawText("Smoke particle update. <---------------------------", 10, 600) -- było do 22.08.15 wtf
end

function onSmokeGrenadeDestroy()
	if source then
		destroyElement(getElementData(source, "particle"))
	end
	if g_misc.smokeUpdate and #smokeGrenades == 1 then
		g_misc.smokeUpdate = false
		removeEventHandler("onClientPreRender", root, updateSmokeGrenadeParticles)
	end
	table.remove(smokeGrenades, table.find(smokeGrenades, source))
end

function onHEGrenadeExploded()
	local x, y, z = getElementPosition(source)
	local sound = playSound3D(":csrw-sounds/sounds/weapons/hegrenade/explode3.wav", x, y, z)
	setSoundMaxDistance(sound, 100)
end

function destroyGrenades()
	for k, v in pairs(grenades.smokes) do destroyElement(v) end
	for k, v in pairs(grenades.decoys) do destroyElement(v) end

	grenades.smokes = {}
	grenades.decoys = {}

	for k, v in pairs(getElementsByType("projectile")) do
		if getProjectileType(v) ~= 16 then
			destroyElement(v) -- usuwanie wszystkich projectile oprocz normalnych granatów odłamkowych
		end
	end
end