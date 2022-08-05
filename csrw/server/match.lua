g_match = {
	mode = "cs",

	-- count of started rounds in this match
	rounds = 0,

	nextMap = nil,

	bombsites = false,
	hostages = false,
	wantsRTV = 0,

	settings = deepcopy(DEFAULT_MATCH_SETTINGS)
}

function restartMatch(currentMap)
	outputServerLog("Match was restarted.")
	setTeamScore(g_team[1], 0)
	setTeamScore(g_team[2], 0)
	g_match.rounds = 0
	g_match.nextMap = nil
	g_match.wantsRTV = 0
	clearNominations()

	for _, v in pairs(getElementsByType("player")) do
		setPlayerMoneyEx(v, g_config["startmoney"])
		setElementData(v, "score", 0)
		setElementData(v, "deaths", 0)
		setPlayerAnnounceValue(v, "score", 0)
		csResetWeapons(v)
	end

	resetMatchSettings()

	if not currentMap then
		currentMap = getCurrentMap()
	end

	if currentMap then
		local mapName = currentMap.name
		if get(mapName .. ".no_weapon_shop") then
			g_match.settings.weaponShop = false
		end
		
		if get(mapName .. ".no_weapon_drop") then
			g_match.settings.weaponDrop = false
		end

		if get(mapName .. ".everything_is_free") then 
			g_match.settings.everythingIsFree = true
		end
	end
	sendMatchSettingsToPlayer(root)
end

function resetMatchSettings()
	g_match.settings = deepcopy(DEFAULT_MATCH_SETTINGS)
	g_match.settings.weaponDrop = g_config["weapon_drop"]
	g_match.settings.everythingIsFree = g_config['everything_is_free']
end

function sendMatchSettingsToPlayer(player)
	triggerClientEvent("updateMatchSettings", player, g_match.settings)
end

function setTeamScore(team, score)
	setElementData(team, "score", score)
	if team == g_team[1] then
		setRuleValue("score_tt", score)
	elseif team == g_team[2] then
		setRuleValue("score_ct", score)
	end
end
