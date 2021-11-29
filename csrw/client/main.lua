g_team = {
	[1] = getTeamFromName("tt"),
	[2] = getTeamFromName("ct"),
	[3] = getTeamFromName("spec")
}

g_player = {
	flashed = false,
	goggleState = false,
	canChangeSlot = true, -- czy może zmienić slot / wyrzucić broń
	reloading = false,
	skin = false, -- skin w formie 1 - 4
	surviveLastRound = false, -- czy przeżył ostatnią runde
	spectating = false,

	items = {
		helmet = false,
		goggles = 0,
		defuser = false
	}
}

g_misc = {
	smokeUpdate = false
}

sX, sY = guiGetScreenSize()

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

function preInit() -- wykonuje sie na starcie skryptu oraz przy zmianie mapy
	showPlayerHudComponent("all", false)
	showPlayerHudComponent("crosshair", true)
	toggleControl("next_weapon", false)
	toggleControl("previous_weapon", false)	
	--toggleControl("enter_exit", false) -- alternatywny styl walki (ctrl + f) / wchodzenie do pojazdu

	setCloudsEnabled(false)
	setBirdsEnabled(false)
	setInteriorSoundsEnabled(false)
	setPedTargetingMarkerEnabled(false)
	setAmbientSoundEnabled("general", false)
	setAmbientSoundEnabled("gunfire", false)
	setTime(12, 0)
	clearWorld()

	local enableSounds = {55, 51, 55, 66, 69, 70, 71, 72, 84, 85, 31, 32, 88}
	for i=1, 100 do -- wyłączanie dźwięków broni
		if not table.find(enableSounds, i) then
			setWorldSoundEnabled(5, i, false)
		end
	end

	-- strange CJ breathing sound
	setWorldSoundEnabled(25, false)
	setWorldSoundEnabled(0, false)

	-- explosions
	setWorldSoundEnabled(4, false)

	--[[
		Dźwięki przeładowania broni:
			deagle: 55, 51
			pistol/silenced: 55, 66
			sawn-off: 69, 70
			shotgun: 72
			spaz: 71, 72
			mp5/tec/uzi: 84, 85
			m4/ak: 31, 32
			snajperka: 32

		88 - dźwięk noża
		odgłosy krztuszenia od gazu łzawiącego: grupa 21 - 24?
	]]

	setWorldSoundEnabled(21, false)
	setWorldSoundEnabled(22, false)
	setWorldSoundEnabled(23, false)
	setWorldSoundEnabled(24, false)		
end

-- wykonuje sie przy starcie skryptu oraz po zmianie mapy
function init()
	loadClassSelection()
	changeViewToRandomCamera()
	--showClassSelection()
	showMOTD()
end

function clearWorld()
	destroyGroundWeapons()
	destroyGrenades()
	extinguishFire(0, 0, 0, 999999)
end

addEventHandler("onClientPlayerSpawn", localPlayer,
	function()
		-- Round started
		spectator.exit()
		showRadar(true)
		showHUD(true)
		setWindowFlashing(true, 3)
		clearWorld()

		local i = math.random(1, 3)
		if i == 1 then s = "letsgo"
		elseif i == 2 then s = "locknload"
		else s = "moveout" end
		playSound(":csrw-sounds/sounds/radio/" .. s .. ".wav")

		-- Give CT free defusing kit if enabled
		if g_config["free_defusing_kit"] and getPlayerTeam(localPlayer) == g_team[2] then
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

		g_player.goggleState = false
		g_player.reloading = false
		--g_player.flashed = false
		--g_player.canChangeSlot = true
		g_player.items.helmet = false
		g_player.items.goggles = 0
		g_player.items.defuser = false

		-- wypadanie C4
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
local goggleDelay
function enableGoggles()
	if goggleDelay or not getElementData(localPlayer, "alive") then return end
	if g_player.goggles then
		setCameraGoggleEffect("normal")
		g_player.goggles = false
		playSound(":csrw-sounds/sounds/items/nvg_off.wav")
		triggerServerEvent("detachWeaponFromBody", localPlayer, localPlayer, "goggle")
	else
		local goggle = getElementData(localPlayer, "item_goggles")
		if goggle then
			if goggle == 1 then
				setCameraGoggleEffect("nightvision")
			else
				setCameraGoggleEffect("thermalvision")
			end
			g_player.goggles = true
			playSound(":csrw-sounds/sounds/items/nvg_on.wav")
			triggerServerEvent("attachWeaponToBody", localPlayer, localPlayer, nil, "goggle")
		end
	end
	goggleDelay = true
	setTimer(function() goggleDelay = false end, 1000, 1)
end
addCommandHandler("goggles", enableGoggles)
bindKey("N", "down", "goggles")

bindKey(getKeyBoundToCommand("screenshot"), "down", 
	function()
		playSound(":csrw-sounds/sounds/snapshot.wav")
	end
)

