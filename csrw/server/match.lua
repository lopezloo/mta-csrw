g_match = {
	mode = "cs",
	rounds = 0, -- liczba wystartowanych rund na obecnej mapie
	nextMap = nil,

	-- zmienne ze starego g_currentMap
	bombsites = false,
	hostages = false,
	wantsRTV = 0
}

function restartMatch()
	outputServerLog("Match was restarted.")
	setTeamScore(g_team[1], 0)
	setTeamScore(g_team[2], 0)
	g_match.rounds = 0
	g_match.nextMap = nil
	g_match.wantsRTV = 0
	clearNominations()

	for k, v in pairs(getElementsByType("player")) do
		setPlayerMoneyEx(v, g_config["startmoney"])
		setElementData(v, "score", 0)
		setElementData(v, "deaths", 0)
		setPlayerAnnounceValue(v, "score", 0)
		csResetWeapons(v)
	end
end

function setTeamScore(team, score)
	setElementData(team, "score", score)
	if team == g_team[1] then
		setRuleValue("score_tt", score)
	elseif team == g_team[2] then
		setRuleValue("score_ct", score)
	end
end