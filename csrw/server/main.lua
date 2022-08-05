g_resources = {
	toStop = {
		"defaultstats",
		"helpmanager",
		"mapcycler",
		"scoreboard",
		"spawnmanager",
		"freeroam",
		"reload"
	},

	toStart = {
		"csrw-media",
		"csrw-models",
		"csrw-sounds",
		"bone_attach",
		"topbarchat",
		"object_light_fix",
		"mapmanager",
		"votemanager"
	}
}

g_player = {}
local DEFINE_VERSION = "1.1.0"

addEventHandler("onResourceStart", root,
	function()
		if source == resourceRoot then
			setGameType("CSRW: no_map")
			setRuleValue("csrw_author", "lopezloo")
			setRuleValue("csrw_version", DEFINE_VERSION)
			setRuleValue("csrw_mode", "normal")

			if getResourceInfo(getThisResource(), "version") ~= DEFINE_VERSION then
				outputServerLog("WARNING: Gamemode meta data do not present valid version (" .. getResourceInfo(getThisResource(), "version") .. " instead of " .. DEFINE_VERSION .. ").")
			end

			-- hardcoded weapon skills
			-- Należy ustawiać skille od najmniejszego do największego, w innej kolejności poprzednie wartości zresetują się
			setWeaponProperty("rifle", "poor", "anim_loop_stop", 0.48)
			setWeaponProperty("rifle", "poor", "anim2_loop_stop", 0.48)

			setWeaponProperty("rifle", "std", "anim_loop_stop", 0.48) -- szybko strzelne country rifle
			setWeaponProperty("rifle", "std", "anim2_loop_stop", 0.48)

			setWeaponProperty("shotgun", "std", "accuracy", 1) -- większy rorzrzut shotguna
			setWeaponProperty("combat shotgun", "std", "accuracy", 0.9)

			-- zwiększony rozrzut broni (poor - bieganie z bronią)
			for k, v in pairs( { "ak47", "m4" } ) do
				for k2, v2 in pairs( { "poor", "std", "pro" } ) do
					setWeaponProperty(v, v2, "accuracy", getOriginalWeaponProperty(v, v2, "accuracy") - 0.1)
					--if v2 ~= "poor" then
						setWeaponProperty(v, v2, "weapon_range", getOriginalWeaponProperty(v, v2, "weapon_range") - 20)
					--end
				end
			end

			--[[setWeaponProperty("ak47", "std", "accuracy", getOriginalWeaponProperty("ak47", "std", "accuracy") - 0.1)
			setWeaponProperty("ak47", "std", "weapon_range", getOriginalWeaponProperty("ak47", "std", "weapon_range") - 7)

			setWeaponProperty("m4", "std", "accuracy", getOriginalWeaponProperty("m4", "std", "accuracy") - 0.1)
			setWeaponProperty("m4", "std", "weapon_range", getOriginalWeaponProperty("m4", "std", "weapon_range") - 7)]]--
			--

			-- bieganie z bronią
			--[[local sprintAimableWeapons = {
				"ak-47", "m4",
				"shotgun", "combat shotgun", -- combat = spaz
				"mp5",
			}

			for k, v in pairs(sprintAimableWeapons) do
				setWeaponProperty(v, "poor", "flag_aim_arm", true)
			end]]--

			-- zwiększony rozrzut podczas biegania z brońmi
			--[[setWeaponProperty("shotgun", "poor", "accuracy", 0.7)
			setWeaponProperty("combat shotgun", "poor", "accuracy", 0.6)
			setWeaponProperty("ak47", "poor", "weapon_range", 40) -- domyślnie 70 na wszystkich parametrach
			setWeaponProperty("m4", "poor", "weapon_range", 60) -- domyślnie 90 na wszystkich parametrach
			setWeaponProperty("combat shotgun", "std", "weapon_range", 30) -- domyślnie 40 na wszystkich parametrach (to samo zwykły shotgun)

			setWeaponProperty("mp5", "pro", "weapon_range", 35) -- p90
			setWeaponProperty("mp5", "pro", "accuracy", 1)]]--
			-- todo: maszynowe
			--

			for _, v in pairs(getElementsByType("player")) do
				onPlayerJoinFunc(v)
			end

			local problems = {
				errors = 0,
				criticals = 0
			}
			
			local neededPermissions = {
				{"function.stopResource", "stopping useless resources"},
				{"function.startResource", "starting required resources"},
				--{"function.restartResource", "restarting in auto update"},
				--{"function.fetchRemote", "global news, master server list"},
				{"function.callRemote", "new version notification"},
			}

			for k, v in pairs(neededPermissions) do
				if not hasObjectPermissionTo(getThisResource(), v[1]) then
					if k == 1 then
						outputServerLog("WARNING: Gamemode need these permissions:")
						problems.errors = problems.errors + 1
					end

					outputServerLog(" * " .. v[1] .. " for " .. v[2])
					if k == #neededPermissions then
						outputServerLog("Please use \"aclrequest allow " .. getResourceName(getThisResource()) .. " all\" command.\n")
					end
				end
			end

			local resourceTemp = {
				toStart = "",
				toStop = "",
				stopped = ""
			}

			for k, v in pairs(g_resources.toStop) do
				local resource = getResourceFromName(v)
				if resource then
					if getResourceState(resource) == "running" or getResourceState(resource) == "starting" then
						if not hasObjectPermissionTo(getThisResource(), "function.stopResource") then
							resourceTemp.toStop = resourceTemp.toStop .. v
							if k ~= #g_resources.toStop - 1 then resourceTemp.toStop = resourceTemp.toStop .. ", " end
							problems.errors = problems.errors + 1
						else
							if resourceTemp.stopped ~= "" then
								resourceTemp.stopped = resourceTemp.stopped .. ", "
							end 
							resourceTemp.stopped = resourceTemp.stopped .. v
							stopResource(resource)
						end
					end
				end
			end

			for k, v in pairs(g_resources.toStart) do
				local resource = getResourceFromName(v)
				if resource then
					if getResourceState(resource) ~= "running" and getResourceState(resource) ~= "starting" then
						if hasObjectPermissionTo(getThisResource(), "function.startResource") then
							resourceTemp.toStart = resourceTemp.toStart .. v
							if k ~= #g_resources.toStart - 1 then resourceTemp.toStart = resourceTemp.toStart .. ", " end
						else
							startResource(resource)
						end
					end
				else
					resourceTemp.toStart = resourceTemp.toStart .. v
				end
			end

			if resourceTemp.toStop ~= "" then
				outputServerLog("WARNING: Gamemode can't stop useless resources. Please stop these manually: " .. resourceTemp.toStop)
			elseif resourceTemp.stopped ~= "" then
				outputServerLog("Gamemode stopped useless resources (" .. resourceTemp.stopped .. ").")
			end

			if resourceTemp.toStart ~= "" then
				outputServerLog("ERROR: Gamemode can't start some required resources: " .. resourceTemp.toStart)
				problems.errors = problems.errors + 1
			end

			if problems.criticals > 0 or problems.errors > 0 then
				outputServerLog("WARNING: Gamemode was started but got some problems. Please FIX IT.")
			else
				outputServerLog("CSRW started properly!")
			end
		
		else
			-- other resources
			for _, v in pairs(g_resources.toStop) do
				local resource = getResourceFromName(v)
				if source == resource then
					if not hasObjectPermissionTo(getThisResource(), "function.stopResource") then
						outputServerLog("ERROR: Gamemode can't stop useless resource (" .. v .. ").")
					else
						outputServerLog("Stopping useless resource (" .. v .. ").")
						stopResource(resource)
					end
					break -- @todo: is this right?
				end
			end
		end
	end
)

function checkScriptUpdates()
	if hasObjectPermissionTo(getThisResource(), "function.callRemote") then
		callRemote("http://community.mtasa.com/mta/resources.php", onScriptUpdatesChecked, "version", "csrw")
	end	
end

function onScriptUpdatesChecked(name, version, id)
	if version ~= DEFINE_VERSION then
		outputServerLog("\n======== VERSION CHECK ========\nNew version (" .. version .. ") available!\nDownload it from https://community.mtasa.com/index.php?p=resources&s=details&id=" .. id .. "\n===============================")
	end
end

addEventHandler("onResourceStop", resourceRoot,
	function()
		-- Reset weapon properties
		local allWeapons = {
			"ak-47",
			"m4",
			"shotgun",
			"combat shotgun",
			"mp5",
			"rifle"
		}

		local parameters = {
			"weapon_range",
			"target_range",
			"accuracy",
			"flag_aim_arm",
			"anim_loop_stop",
			"anim2_loop_stop"
		}

		for _, v in pairs(allWeapons) do
			for _, v2 in pairs(parameters) do
				for _, v3 in pairs({"poor", "std", "pro"}) do
					setWeaponProperty(v, v3, v2, getOriginalWeaponProperty(v, v3, v2))
				end
			end
		end
	end
)

g_team = {
	[1] = createTeam("tt", 255, 0, 0),
	[2] = createTeam("ct", 0, 0, 255),
	[3] = createTeam("spec", 255, 255, 255)
}
setTeamScore(g_team[1], 0)
setTeamScore(g_team[2], 0)

addEventHandler("onPlayerJoin", root,
	function()
		onPlayerJoinFunc(source)
	end
)

addEventHandler("onPlayerQuit", root,
	function()
		csResetWeapons(source, true)
		deletePlayerNomination(source)
		checkPlayers()

		if g_player[source].rtv then
			g_match.wantsRTV = g_match.wantsRTV - 1
		end

		detachCarriedHostage(source)
		g_player[source] = nil
	end
)

function onPlayerJoinFunc(player)
	g_player[player] = {
		localization = false,
		skin = 0,
		surviveLastRound = false,
		sneaking = false,
		rtv = false,
		carryingHost = nil
	}

	setPlayerMoneyEx(player, g_config["startmoney"])
	setElementData(player, "alive", false)
	setElementData(player, "armor", 0)
	setElementData(player, "score", 0)
	setElementData(player, "deaths", 0)
	setPlayerAnnounceValue(player, "score", 0)

	bindKey(player, "walk", "down", setPlayerSneaking)
	bindKey(player, "walk", "up", setPlayerSneaking)
	g_playerWeaponData[player] = {}

	sendMatchSettingsToPlayer(player)
end

function setPlayerSneaking(player, key, keyState)
	if g_player[player].carryingHost then
		-- Player can't sneak while carrying hostage
		return
	end

	if keyState == "down" then
		player.walkingStyle = MOVE_SNEAK
		g_player[player].sneaking = true
		
		if not getElementData(player, "anim") then
			playAnimationWithWalking("ped", "facanger", player)
		end
		
		if player.weaponSlot == WEAPON_SLOT_MELEE then
			toggleControl(player, "sprint", false)
		end
		
	else
		g_player[player].sneaking = false
		player.walkingStyle = MOVE_PLAYER_M
		if g_player[player].carryingHost ~= nil then
			player.walkingStyle = MOVE_PLAYER_F
		end

		if getElementData(player, "anim") == "ped:facanger" then
			stopAnimationWithWalking(player)
		end

		toggleControl(player, "sprint", isWeaponSlotSprintable(player.weaponSlot) and g_player[player].carryingHost == nil)
	end
end

addEventHandler("onVehicleStartEnter", root,
	function(player, seat, jacked, door)
		if getElementData(source, "decorative") == "true" then
			cancelEvent()
		end
	end
)

addEvent("sendMeLocalization", true)
addEventHandler("sendMeLocalization", root,
	function(loc)
		if client and source == client then
			if g_lang[loc] then
				g_player[client].localization = loc
			else
				g_player[client].localization = g_config["default_locale"]
			end
		end
	end
)

function outputText(txt, r, g, b, to)
	if to == root or to == nil or getElementType(to) == "team" then
		if to == root or to == nil then
			to = getElementsByType("player")
		elseif getElementType(to) == "team" then
			to = getPlayersFromTeam(to)
		end

		for k, v in pairs(to) do
			outputChatBox(getText(txt, v), v, r, g, b)
		end
	
	elseif getElementType(to) == "player" then
		outputChatBox(getText(txt, to), to, r, g, b)
	end
end

addEventHandler("onPickupHit", root,
	function(player)
		cancelEvent()
	end
)
