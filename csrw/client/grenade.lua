local smokeGrenades = {}

local timer_updateProjectileLines

-- table of projectiles with lines to be rendered
local lineProjectiles = {}

-- table of projectile lines
local projectileLines = {}

local grenades = {
	smokes = {},
	decoys = {}
}

addEventHandler("onClientProjectileCreation", root,
	function(creator)
		if getProjectileType(source) == 16 then -- 16 = grenade
			-- HE grenade
			addEventHandler("onClientElementDestroy", source, onHEGrenadeExploded)
		end

		if getProjectileType(source) == 17 then -- 17 = teargas
			local slot = getElementData(creator, "currentSlot")
			if slot then
				local weapon = getElementData(creator, "wSlot" .. slot)
				if weapon then
					if g_weapon[slot][weapon]["objectID"] == "-2" then
						-- Flashbang grenade
						-- Set projectile counter high to avoid grenade explosion
						setProjectileCounter(source, 99999)
						setTimer(onFlashBangExploded, 2000, 1, source) -- 2000 to czas wybuchu flasha od jego wyrzucenia z ręki					
					
					elseif g_weapon[slot][weapon]["objectID"] == "-3" then
						-- Decoy grenade
						setProjectileCounter(source, 99999)

						-- Get best player weapon to use it as decoy
						local weapon = {1, getElementData(creator, "wSlot1")}
						if not weapon[2] then
							weapon = {2, getElementData(creator, "wSlot2")}
						end
						setTimer(onDecoyExploded, 2000, 1, source, weapon[1], weapon[2])
					
					else
						-- Smoke grenade
						setTimer(onSmokeGrenadeExploded, 3000, 1, source)
					end
				end
			end
		end

		--outputChatBox("onClientProjectileCreation; creator: " .. tostring(creator) .. " (element " .. getElementType(creator) .. ")")
		if g_player.spectating and creator and getElementType(creator) == "player" then -- + getElementData(source, "spectator")
			-- Draw projectile lines in spectator
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
	
	if not isLineOfSightClear(x, y, z, x2, y2, z2, true, true, false, true, true, false, false, grenade) then
		-- If flashbang projectile is behind some object
		setSoundMaxDistance(playSound3D(":csrw-sounds/sounds/weapons/flashbang/flashbang_explode2.wav", x, y, z), 50)
		destroyElement(grenade)
		return
	end

	local distance = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
	local exploded
	if isElementOnScreen(grenade) then
		-- If player is looking at flashbang projectile
		if distance <= 50 then
			-- If player is close to it
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

	elseif distance <= 12 then
		-- If player is not looking at flashbang projectile but is close
		exploded = true
		fadeCamera(false, 0.1, 255, 255, 255)
		setTimer(
			function()
				fadeCamera(true, 1) 
				showRadar(true)
				g_player.flashed = false
			end, 5000 / distance, 1)
	end

	-- Destroy projectile
	destroyElement(grenade)

	-- Create FX
	local fx = Effect("camflash", x, y, z)
	setTimer(destroyElement, 1000, 1, fx)

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
	groundZ = groundZ + 0.1
	if groundZ > z then
		groundZ = z
	end

	-- Destroy projectile
	destroyElement(grenade)

	if not weapon then
		-- Get default weapon for decoy if none specified
		local defweapons = getWeaponsWithFlag("DECOY_DEFAULT")
		if #defweapons == 0 then
			defweapons = getWeaponsWithFlag("STARTPISTOL")
		end
		
		if #defweapons == 0 then
			return
		end

		slot, weapon = defweapons[1][1], defweapons[1][2]
	end

	local shotSound = g_weapon[slot][weapon]["shotSound"]
	if not shotSound then
		return
	end

	sound = ":csrw-sounds/sounds/weapons/" .. shotSound

	-- Recreate projectile as object
	local obj = Object(343, x, y, z, rx, ry, rz)
	obj.collisions = false
	obj.frozen = true
	obj.interior = int

	table.insert(grenades.decoys, obj)
	
	if z > groundZ then
		moveObject(obj, 100*(z - groundZ), x, y, groundZ)
	end

	-- Calculate time between decoy shots
	local timeBetweenShots = 250
	if weapon then
		local gtaWeaponID = g_weapon[slot][weapon]["weaponID"]
		local gtaSkillName
		local csSkillName = g_weapon[slot][weapon]["skill"]
		if csSkillName == "low" then
			gtaSkillName = "poor"
		elseif csSkillName == "medium" then
			gtaSkillName = "std"
		elseif csSkillName == "pro" then
			gtaSkillName = "pro"
		end
		
		if gtaWeaponID and gtaSkillName then
			local anim_loop_stop = getWeaponProperty(gtaWeaponID, gtaSkillName, "anim_loop_stop")
			local anim_loop_start = getWeaponProperty(gtaWeaponID, gtaSkillName, "anim_loop_start")
			local anim_loop_time = anim_loop_stop - anim_loop_start
			timeBetweenShots = 50 + 1000 * anim_loop_time
		end

		-- Add extra reload time if weapon has only one bullet in the clip
		local clip = tonumber(g_weapon[slot][weapon]["clip"])
		if clip == 1 then
			timeBetweenShots = timeBetweenShots + 1700
		end
	end

	for i=1, 20 do
		setTimer(
			function()
				if not obj or not isElement(obj) then return end
				local x, y, z = getElementPosition(obj)

				if i == 20 then
					-- Create small explosion
					createExplosion(x, y, z, 12)

					-- Play explosion sound
					local sound = playSound3D(":csrw-sounds/sounds/weapons/hegrenade/explode3.wav", x, y, z)
					setSoundMaxDistance(sound, 150)

					table.remove(grenades.decoys, table.find(grenades.decoys, obj))

					-- Destroy grenade object
					destroyElement(obj)
				else
					-- Create FX effect
					createSparks(Vector3(x, y, z))

					-- Play two weapon shoot sounds
					local s = playSound3D(sound, x, y, z)
					setSoundMaxDistance(s, 100)

					setTimer(
						function()
							local s = playSound3D(sound, x, y, z)
							setSoundMaxDistance(s, 100)
							createSparks(Vector3(x, y, z))
						end, timeBetweenShots, 1)
				end
			end, (2000 + timeBetweenShots)*i, 1)
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
	if getDistanceBetweenPoints3D(x, y, z, x, y, groundZ) <= 1 then
		-- Smoke is already lying on the ground, we can delete it to easy projectile limits
		-- we don't need to update smoke FX position per frame anymore too
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
			-- Enabling this event only when there are smoke grenades created
			addEventHandler("onClientPreRender", root, updateSmokeGrenadeParticles)
		end

		addEventHandler("onClientElementDestroy", grenade, onSmokeGrenadeDestroy)
	end
end

function updateSmokeGrenadeParticles()
	for k, v in pairs(smokeGrenades) do
		local x, y, z = getElementPosition(v)
		setElementPosition(getElementData(v, "particle"), x, y, z-2)
	end
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

	-- Deleting all projectiles except HE grenades
	for k, v in pairs(getElementsByType("projectile")) do
		if getProjectileType(v) ~= 16 then
			destroyElement(v)
		end
	end
end

function createSparks(position)
	local fx = Effect("prt_spark", position, -90, 0, 0, 100, false)
	fx.density = 0.2

	setTimer(function()
		fx.density = 0
		
		setTimer(function()
			fx:destroy()
		end, 400, 1)

	end, 150, 1)
end
