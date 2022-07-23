local gl_timer_updateProjectileLines
local gl_timer_flyingSmokeGrenadesUpdate

local gl_flashedSound

local gl_grenades = {
	-- Table of all smoke grenade projectiles
	smokes = {},

	-- Table of smoke grenade projectiles in air
	smokesFlying = {},

	-- Table of smoke grenade smoke particles
	smokeParticles = {},

	smokeSounds = {},

	-- Table of smoke grenades recreated as objects
	smokeObjects = {},

	decoys = {}
}

-- Time until smoke grenade disappears
local SMOKE_GRENADE_LIFETIME = 20000

-- Time until smoke grenade explodes
local SMOKE_GRENADE_EXPLOSION_TIMEOUT = 3000

-- Time until decoy grenade explodes
local DECOY_GRENADE_EXPLOSION_TIMEOUT = 2000

-- Time until flashbang grenade explodes
local FLASHBANG_GRENADE_EXPLOSION_TIMEOUT = 2000

local DECOY_GRENADE_GROUND_OBJECT_ID = 343
local SMOKE_GRENADE_GROUND_OBJECT_ID = 343

local SMOKE_GRENADE_PARTICLE_EFFECT_NAME = "carwashspray"

local PROJECTILE_COUNTER_MAX = 999999

addEventHandler("onClientProjectileCreation", root,
	function(creator)
		if getProjectileType(source) == WEAPON_GRENADE then
			-- HE grenade
			addEventHandler("onClientElementDestroy", source, onHEGrenadeExploded)

		elseif getProjectileType(source) == WEAPON_TEARGAS then
			local slot = getElementData(creator, "currentSlot")
			if slot then
				local weapon = getElementData(creator, "wSlot" .. slot)
				if weapon then
					if g_weapon[slot][weapon]["objectID"] == "-2" then
						-- Flashbang grenade
						-- Set projectile counter to max to avoid grenade explosion
						source:setCounter(PROJECTILE_COUNTER_MAX)
						setTimer(onFlashBangExploded, FLASHBANG_GRENADE_EXPLOSION_TIMEOUT, 1, source)				
					
					elseif g_weapon[slot][weapon]["objectID"] == "-3" then
						-- Decoy grenade
						source:setCounter(PROJECTILE_COUNTER_MAX)

						-- Get best player weapon to use it as decoy
						local weapon = {1, getElementData(creator, "wSlot1")}
						if not weapon[2] then
							weapon = {2, getElementData(creator, "wSlot2")}
						end
						setTimer(onDecoyExploded, DECOY_GRENADE_EXPLOSION_TIMEOUT, 1, source, weapon[1], weapon[2])
					
					else
						-- Smoke grenade
						setTimer(onSmokeGrenadeExploded, SMOKE_GRENADE_EXPLOSION_TIMEOUT, 1, source)
					end
				end
			end
		end
	end
)

function onFlashBangExploded(grenade)
	if not isElement(grenade) then return end
	local x, y, z = getElementPosition(grenade)
	local x2, y2, z2 = getElementPosition(localPlayer)

	-- Create FX
	Effect("camflash", x, y, z)

	-- Create light
	local startRadius = 6
	local endRadius = 22
	local light = Light(0, x, y, z, startRadius, 255, 255, 255, 0, 0, 0, true)
	setTimer(
		function()
			light.radius = light.radius + 2
			if light.radius >= endRadius then
				light:destroy()
			end
		end, 50, (endRadius-startRadius) * 1/2
	)

	if g_player.flashed or (localPlayer.team ~= g_team[1] and localPlayer.team ~= g_team[2]) then
		-- Already flashed by another flashbang
		-- Or in spectator
		destroyProjectile(grenade)
		return
	end
	
	if not isLineOfSightClear(x, y, z, x2, y2, z2, true, true, false, true, true, false, false, grenade) then
		-- If flashbang projectile is behind some object
		Sound3D(":csrw-sounds/sounds/weapons/flashbang/flashbang_explode2.wav", x, y, z).maxDistance = 50
		destroyProjectile(grenade)
		return
	end

	local distance = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
	local exploded = false
	
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
					if not g_player.flashed then return end

					fadeCamera(true, 1)
					showRadar(true)
					g_player.flashed = false
				end, 30000 / distance, 1
			)
		end

	elseif distance <= 12 then
		-- If player is not looking at flashbang projectile but is close
		exploded = true
		fadeCamera(false, 0.1, 255, 255, 255)
		g_player.flashed = true
		
		setTimer(
			function()
				if not g_player.flashed then return end

				fadeCamera(true, 1) 
				showRadar(true)
				g_player.flashed = false
			end, 5000 / distance, 1
		)
	end

	-- Destroy projectile
	destroyProjectile(grenade)

	if exploded then
		gl_flashedSound = playSound(":csrw-sounds/sounds/weapons/flashbang/flash.ogg")
	else
		setSoundMaxDistance(playSound3D(":csrw-sounds/sounds/weapons/flashbang/flashbang_explode2.wav", x, y, z), 50)
	end
end

function resetFlashedState()
	g_player.flashed = false
	fadeCamera(true, 0)

	-- Stop flashed sound
	if gl_flashedSound and isElement(gl_flashedSound) then
		gl_flashedSound:destroy()
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

	destroyProjectile(grenade)

	if not weapon then
		-- Get default weapon for decoy if none specified
		local defweapons = getWeaponsWithFlag("DECOY_DEFAULT")
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
	local obj = Object(DECOY_GRENADE_GROUND_OBJECT_ID, x, y, z, -rx, -ry, -rz)
	obj.collisions = false
	obj.frozen = true
	obj.interior = int

	table.insert(gl_grenades.decoys, obj)
	
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
					createExplosion(x, y, z, EXPLOSION_TINY, false)

					-- Play explosion sound
					local sound = playSound3D(":csrw-sounds/sounds/weapons/hegrenade/explode3.wav", x, y, z)
					setSoundMaxDistance(sound, 150)

					table.remove(gl_grenades.decoys, table.find(gl_grenades.decoys, obj))

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
						end, timeBetweenShots, 1
					)
				end
			end, (2000 + timeBetweenShots)*i, 1
		)
	end
end

function onSmokeGrenadeExploded(projectile)
	if not isElement(projectile) then return end

	table.insert(gl_grenades.smokes, projectile)

	local x, y, z = getElementPosition(projectile)
	local groundZ = getGroundPosition(x, y, z)
	if getDistanceBetweenPoints3D(x, y, z, x, y, groundZ) <= 1 then
		createSmokeGrenadeParticleEffect(projectile)
		
	else
		table.insert(gl_grenades.smokesFlying, projectile)

		-- Smoke projectile is still in the air, we will wait
		if not g_misc.smokeUpdate and #gl_grenades.smokes > 0 then
			g_misc.smokeUpdate = true
			gl_timer_flyingSmokeGrenadesUpdate = setTimer(updateFlyingSmokeGrenades, 50, 0)
		end

		addEventHandler("onClientElementDestroy", projectile, onSmokeGrenadeDestroy)
	end
end

function updateFlyingSmokeGrenades()
	if not g_misc.smokeUpdate then
		return
	end

	local smokesFlyingCopy = {}
	for k, v in pairs(gl_grenades.smokesFlying) do
		local x, y, z = getElementPosition(v)
		local groundZ = getGroundPosition(x, y, z)
		if getDistanceBetweenPoints3D(x, y, z, x, y, groundZ) <= 1 then
			createSmokeGrenadeParticleEffect(v)
		
		else
			table.insert(smokesFlyingCopy, v)
		end
	end
	gl_grenades.smokesFlying = smokesFlyingCopy
end

function createSmokeGrenadeParticleEffect(projectile)
	local x, y, z = getElementPosition(projectile)
	local rx, ry, rz = getElementRotation(projectile)
	local interior = projectile.interior

	local particle = Effect(SMOKE_GRENADE_PARTICLE_EFFECT_NAME, x, y, z-2, -90, 0, 0)
	particle.speed = 1
	particle.density = 2

	setTimer(
		function()
			if particle and isElement(particle) then
				particle.speed = 0.25
			end
		end, 2000, 1
	)

	particle.collisions = false
	table.insert(gl_grenades.smokeParticles, particle)

	local sound = Sound3D(":csrw-sounds/sounds/weapons/smokegrenade/sg_explode.wav", x, y, z)
	sound.maxDistance = 50
	table.insert(gl_grenades.smokeSounds, sound)

	-- Smoke is already lying on the ground, we can delete it to easy projectile limits
	table.remove(gl_grenades.smokes, table.find(gl_grenades.smokes, projectile))
	destroyProjectile(projectile)

	-- Recreate projectile as object
	local groundZ = getGroundPosition(x, y, z)
	local obj = Object(SMOKE_GRENADE_GROUND_OBJECT_ID, x, y, z, -rx, -ry, -rz)
	obj.collisions = false
	obj.frozen = true
	obj.interior = interior
	table.insert(gl_grenades.smokeObjects, obj)
	
	if z > groundZ then
		moveObject(obj, 100*(z - groundZ), x, y, groundZ)
	end
	
	setTimer(
		function()
			if obj and isElement(obj) then
				obj:destroy()
			end

			local tPos = table.find(gl_grenades.smokeObjects, obj)
			if tPos then
				table.remove(gl_grenades.smokeObjects, tPos)
			end

			if sound and isElement(sound) then
				sound:destroy()
			end

			if not particle or not isElement(particle) then
				return
			end

			local tPos = table.find(gl_grenades.smokeParticles, particle)
			if tPos then
				table.remove(gl_grenades.smokeParticles, tPos)
			end

			-- Let particle smoothly fade away
			particle.speed = 0.5
			particle.density = 0

			-- Delete particle
			setTimer(
				function()
					if particle and isElement(particle) then
						particle:destroy()
					end
				end, 10000, 1
			)
		end, SMOKE_GRENADE_LIFETIME, 1
	)
end

function onSmokeGrenadeDestroy()
	if source and isElement(source) then
		local particle = source:getData("particle")
		if particle and isElement(particle) then
			destroyElement(particle)
		end
	end

	local tPos = table.find(gl_grenades.smokesFlying, source)
	if tPos then
		table.remove(gl_grenades.smokesFlying, source)
	end

	if g_misc.smokeUpdate and #gl_grenades.smokesFlying == 0 then
		g_misc.smokeUpdate = false
		killTimer(gl_timer_flyingSmokeGrenadesUpdate)
	end
	table.remove(gl_grenades.smokes, table.find(gl_grenades.smokes, source))
end

function onHEGrenadeExploded()
	Sound3D(":csrw-sounds/sounds/weapons/hegrenade/explode3.wav", source.position).maxDistance = 100
end

-- Remove all grenades
function destroyGrenades()
	if g_misc.smokeUpdate then
		g_misc.smokeUpdate = false
		killTimer(gl_timer_flyingSmokeGrenadesUpdate)
	end

	for k, v in pairs(gl_grenades.smokeObjects) do destroyElement(v) end
	for k, v in pairs(gl_grenades.smokeParticles) do destroyElement(v) end
	for k, v in pairs(gl_grenades.smokes) do destroyElement(v) end
	for k, v in pairs(gl_grenades.decoys) do destroyElement(v) end

	for k, v in pairs(gl_grenades.smokeSounds) do
		if isElement(v) then
			v:destroy()
		end
	end

	gl_grenades.smokeObjects = {}
	gl_grenades.smokeParticles = {}
	gl_grenades.smokeSounds = {}
	gl_grenades.decoys = {}
	gl_grenades.smokes = {}

	for k, v in pairs(getElementsByType("projectile")) do
		destroyProjectile(v)
	end
end

function createSparks(position)
	local fx = Effect("prt_spark", position, -90, 0, 0, 100, false)
	fx.density = 0.2

	setTimer(
		function()
			fx.density = 0
			
			setTimer(
				function()
					fx:destroy()
				end, 400, 1
			)
		end, 150, 1
	)
end

function destroyProjectile(projectile)
	-- Grenades explode while being destroyed
	-- so update projectile counter and teleport them away before that
	projectile:setCounter(PROJECTILE_COUNTER_MAX)
	projectile.position = BLACKHOLE
	projectile:destroy()
end
