g_team = {
	[1] = getTeamFromName("tt"),
	[2] = getTeamFromName("ct"),
	[3] = getTeamFromName("spec")
}

g_player = {
	-- if is currently flashed by flashbang
	flashed = false,

	goggleState = false,

	-- if can change slot or drop weapon
	canChangeSlot = true,
	reloading = false,
	aiming = false,

	-- current player skin in format 1 - 4
	skin = false,

	-- if survived last round
	surviveLastRound = false,
	spectating = false,

	items = {
		helmet = false,
		goggles = 0,
		defuser = false
	}
}

g_misc = {
	smokeUpdate = false,
	roundStarted = false
}

sX, sY = guiGetScreenSize()

local gl_goggleDelay

addEventHandler("onClientResourceStart", resourceRoot,
	function()
		preInit()
		init()
		toggleControl("fire", false)
		bindKey("aim_weapon", "both", onClientAim)
		addEventHandler("onBoxClosed", root, onClassClosed) -- class.lua
		addEventHandler("onBoxClosed", root, onMOTDClosed) -- motd.lua

		triggerServerEvent("sendMeLocalization", resourceRoot, getLocalLanguage())
	end
)

-- Called at resource start and on map change
function preInit()
	showPlayerHudComponent("all", false)
	showPlayerHudComponent("crosshair", true)
	toggleControl("next_weapon", false)
	toggleControl("previous_weapon", false)	
	--toggleControl("enter_exit", false) -- alternatywny styl walki (ctrl + f) / wchodzenie do pojazdu

	setCloudsEnabled(false)
	setBirdsEnabled(false)
	setPedTargetingMarkerEnabled(false)
	setInteriorSoundsEnabled(false)
	setAmbientSoundEnabled("general", false)
	setAmbientSoundEnabled("gunfire", false)
	setPedsLODDistance(100)
	setTime(12, 0)
	clearWorld()
	csClearBlips()
	setCameraClip(true, true)
	dealWithGTASounds()
end

function dealWithGTASounds()
	resetWorldSounds()

	local enableSounds = {
		55, 51, 55, 66, 69, 70, 71, 72, 84, 85, 31, 32, 88
	}

	for i=1, 100 do
		-- Disable weapon sounds
		if not table.find(enableSounds, i) then
			setWorldSoundEnabled(5, i, false, true)
		end
	end

	--[[
		Weapon reloading sounds:
			deagle: 55, 51
			pistol/silenced: 55, 66
			sawn-off: 69, 70
			shotgun: 72
			spaz: 71, 72
			mp5/tec/uzi: 84, 85
			m4/ak: 31, 32
			sniper: 32

		88 - knife sound
		teargas choking sounds: group 21 - 24?
	]]

	setWorldSoundEnabled(21, -1, false, true)
	setWorldSoundEnabled(22, -1, false, true)
	setWorldSoundEnabled(23, -1, false, true)
	setWorldSoundEnabled(24, -1, false, true)

	-- Disable strange CJ breathing sound
	setWorldSoundEnabled(25, -1, false, true)

	-- Disable explosion sounds
	-- (disable everything in group except index 0 which is fire)
	for i=1, 999 do
		setWorldSoundEnabled(4, i, false, true)
	end

	-- Disable wind sounds
	setWorldSoundEnabled(0, 29, false, true)
	setWorldSoundEnabled(0, 30, false, true)

	-- Enable jetpack sounds
	setWorldSoundEnabled(5, 10, true, true)
	setWorldSoundEnabled(19, 26, true, true)
end

-- wykonuje sie przy starcie skryptu oraz po zmianie mapy
function init()
	loadClassSelection()
	changeViewToRandomCamera()
	showMOTD()

	-- new class stuff
	--setClassSelectionVisible(true)
end

function clearWorld()
	destroyGroundWeapons()
	destroyGrenades()
	destroyProjectileLines()
	extinguishFire(0, 0, 0, 999999)
end

addEventHandler("onClientPlayerSpawn", localPlayer,
	function()
		-- Round started
		g_misc.roundStarted = true

		spectator.exit()
		showRadar(true)
		showHUD(true)
		setWindowFlashing(true, 3)
		clearWorld()
		localPlayer:setVoice("PED_TYPE_DISABLED")

		setGogglesOff()
		resetFlashedState()

		local i = math.random(1, 3)
		if i == 1 then s = "letsgo"
		elseif i == 2 then s = "locknload"
		else s = "moveout" end
		playSound(":csrw-sounds/sounds/radio/" .. s .. ".wav")

		-- Give CT free defusing kit if enabled
		if g_config["free_defusing_kit"] and localPlayer.team == g_team[2] then
			g_player.items.defuser = true
		end
	end
)

addEventHandler("onClientPlayerWasted", localPlayer,
	function()
		showRadar(false)
		showHUD(false)

		if getElementData(localPlayer, "alive") then
			setBoxVisible(false)
		end

		setCameraGoggleEffect("normal")

		g_player.reloading = false
		--g_player.canChangeSlot = true
		g_player.items.helmet = false
		g_player.items.goggles = 0
		g_player.items.defuser = false

		-- drop bomb
		if getElementData(source, "wSlot" .. DEF_BOMB[1]) == DEF_BOMB[2] then
			local aliveTT = 0
			for k, v in pairs(getPlayersInTeam(g_team[1])) do
				if getElementData(v, "alive") and v ~= localPlayer then
					aliveTT = aliveTT + 1
				end
			end

			if aliveTT > 0 then
				dropWeapon(true, DEF_BOMB[1])
			end
		end		
	end
)

addEvent("onClientRoundEnd", true)
addEventHandler("onClientRoundEnd", root,
	function(winTeam, reason)
		g_misc.roundStarted = false

		if winTeam == 1 then
			playSound(":csrw-sounds/sounds/radio/terwin.wav")
		
		elseif winTeam == 2 then
			if reason == 5 then
				playSound(":csrw-sounds/sounds/radio/rescued.wav")
				setTimer(playSound, 2200, 1, ":csrw-sounds/sounds/radio/ctwin.wav")
			elseif reason == 6 then
				playSound(":csrw-sounds/sounds/radio/hostagecompromised.wav")
				setTimer(playSound, 2800, 1, ":csrw-sounds/sounds/radio/ctwin.wav")
			else
				playSound(":csrw-sounds/sounds/radio/ctwin.wav")
			end
		
		elseif winTeam == 3 then
			playSound(":csrw-sounds/sounds/radio/rounddraw.wav")
		end

		if getActiveBoxWindow() == "shop" then
			setBoxVisible(false)
		end

		cancelDefuse()
		cancelPlant()
		csClearBlips()
	end
)

addEvent("onClientRoundStart", true)
addEventHandler("onClientRoundStart", root,
	function()
		-- Create radar blips
		for _, v in ipairs(getElementsByType("bombsite")) do
			local letter = getElementID(v)
			if letter == "bombsite (1)" then letter = "A"
			elseif letter == "bombsite (2)" then letter = "B"
			elseif letter == "bombsite (3)" then letter = "C" end
			
			if letter == "A" or letter == "B" or letter == "C" then
				csCreateBlipAttachedTo(v, letter, 8)
			end
		end

		for _, v in ipairs(getElementsByType("hostagesite")) do
			csCreateBlipAttachedTo(v, "H", 8)
		end

		for _, v in ipairs(getElementsByType("hostage")) do
			csCreateBlipAttachedTo(v, "hostage", 16)
		end
	end
)

addEvent("cPlaySound", true)
addEventHandler("cPlaySound", root,
	function(sound, x, y, z, distance, volume)
		if x and y and z then
			local s = playSound3D(":csrw-sounds/sounds/" .. sound, x, y, z)
			if distance then setSoundMaxDistance(s, distance) end
			if volume then setSoundVolume(s, volume) end
		else
			playSound(":csrw-sounds/sounds/" .. sound)
		end
	end
)

-- GOGGLE
function enableGoggles()
	if gl_goggleDelay or not getElementData(localPlayer, "alive") then return end
	
	if g_player.goggleState then
		turnGogglesOff()
	
	else
		if g_player.items.goggles > 0 then
			if g_player.items.goggles == 1 then
				setCameraGoggleEffect("nightvision")
			else
				setCameraGoggleEffect("thermalvision")
			end
			g_player.goggleState = true
			playSound(":csrw-sounds/sounds/items/nvg_on.wav")
			triggerServerEvent("attachWeaponToBody", localPlayer, localPlayer, nil, "goggle")
		end
	end
	gl_goggleDelay = true
	setTimer(function() gl_goggleDelay = false end, 1000, 1)
end
addCommandHandler("goggles", enableGoggles)
bindKey("N", "down", "goggles")

function turnGogglesOff()
	if not g_player.goggleState then return end

	playSound(":csrw-sounds/sounds/items/nvg_off.wav")
	setGogglesOff()
end

function setGogglesOff()
	if not g_player.goggleState then return end

	g_player.goggleState = false
	setCameraGoggleEffect("normal")
	triggerServerEvent("detachWeaponFromBody", localPlayer, localPlayer, "goggle")
end

bindKey(getKeyBoundToCommand("screenshot"), "down", 
	function()
		playSound(":csrw-sounds/sounds/snapshot.wav")
	end
)

addEventHandler("onClientElementStreamIn", root,
	function()
		if source.type == "player" or source.type == "ped" then
			source:setVoice("PED_TYPE_DISABLED")
		end

		-- Make wrecked cars on the map look more wrecked
		if source.type == "vehicle" and source:getData("wreck") == "true" then
			-- Hide windows
			for i = 1, 6 do
				setVehicleWindowOpen(source, i, true)
			end

			-- Hide some components
			source:setComponentVisible("bump_front_dummy", false)
			source:setComponentVisible("bump_rear_dummy", false)

			source:setComponentVisible("exhaust", false)
			source:setComponentVisible("exhaust_ok", false)
			source:setComponentVisible("exhaust_dam", false)

			source:setComponentVisible("plate_front", false)
			source:setComponentVisible("plate_rear", false)
		end
	end
)

function fixPedLighting(ped)
	-- Hacky way to fix ped lighting (rendering as dark)
	local obj = Object(1224, ped.position)
	obj.dimension = ped.dimension
	obj.interior = 77
	obj.frozen = true
	obj.breakable = false

	for k, v in pairs(getElementsByType("player")) do
		obj:setCollidableWith(v, false)
	end

	setTimer(
		function()
			obj:destroy()
		end, 50, 1
	)
end

-- Weapon slots which doesn't require aiming for shooting (attacking)
local NO_AIM_FIRE_WEAPON_SLOTS = {
	WEAPON_SLOT_HAND,
	WEAPON_SLOT_MELEE,
	WEAPON_SLOT_PROJECTILES,
	WEAPON_SLOT_SPECIAL1,
	WEAPON_SLOT_GIFTS,
	WEAPON_SLOT_SPECIAL2,
	WEAPON_SLOT_DETONATOR
}

function updatePlayerControls()
	-- Can shoot?
	local fire = false

	local hasBombInHands = false
	local slot = localPlayer:getData("currentSlot")
	if slot then
		if g_playerWeaponData[slot].clip ~= nil and g_playerWeaponData[slot].clip > 0 then
			fire = true
		end

		if g_weapon[slot][g_playerWeaponData[slot].weapon]["weaponID"] == "-6" then -- bomb
			hasBombInHands = true
		end
	end

	if not g_player.aiming then
		fire = false

		if not hasBombInHands then
			if table.find(NO_AIM_FIRE_WEAPON_SLOTS, localPlayer.weaponSlot) ~= false then
				fire = true
			end
		end
	end

	if g_player.reloading then
		fire = false
	end

	toggleControl("fire", fire)

	-- @TODO: implement more controls here
end
