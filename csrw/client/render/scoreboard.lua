-- liczenie pozycji na wszystkie rozdziałki:
--  pozycja / rozdziałka w której było zapisywane
--  ex. 321 / 1680 (pozycja X)
--  ex. 321 / 1050 (pozycja Y)

local tableShowing = false
local tableCanBeSwitched = true -- czy tabela moze byc aktualnie odpalona/ukryta przez TAB

--[[if getElementData(resourceRoot, "currentMode") ~= "cs" then
	langText["terrorists"] = getText("zombies")
end]]--

local players = {}

local score = {}
local me = {}

function showTable(show)
	--outputChatBox("showTable " .. tostring(show))
	if tableShowing ~= show then -- zapobiega pieprzeniu sie handlerow
		if show then
			addEventHandler("onClientRender", root, onScoreTableRender)
		else
			removeEventHandler("onClientRender", root, onScoreTableRender)
		end
		if getElementData(localPlayer, "alive") then
			showRadar(not show)
		end
		tableShowing = show
	end
end

function showHideTable(key, keyState)
	if not tableCanBeSwitched then return end
	if keyState == "down" then
		showTable(true)
	else
		showTable(false)
	end
end
--addCommandHandler("Scoreboard", showHideTable)
bindKey("tab", "both", showHideTable)

function setTableCanBeSwitched(show)
	tableCanBeSwitched = show
end

function updateTeams()
	--playersTT = csGetPlayersFromTeam(g_team[1]) -- ta func pobierala takze boty
	players = {
		getPlayersInTeam(g_team[1]), getPlayersInTeam(g_team[2]), getPlayersInTeam(g_team[3])
	}

	score[1] = getElementData(g_team[1], "score") or 0
	score[2] = getElementData(g_team[2], "score") or 0
end
updateTeams()
setTimer(updateTeams, 500, 0)

local tempPlayers -- trzymanie infa o graczach przy zmianie mapy
function saveTeamsToTemp() -- pokazywanie tablicy przy zmianie mapy
	tempPlayers = { {}, {} }
	for k, v in pairs(getPlayersInTeam(g_team[1])) do
		tempPlayers[1][k] = { getPlayerName(v), getElementData(v, "score") or 0, getElementData(v, "deaths") or 0, " " } -- nick, score, zabojstwa
	end
	for k, v in pairs(getPlayersInTeam(g_team[2])) do
		tempPlayers[2][k] = { getPlayerName(v), getElementData(v, "score") or 0, getElementData(v, "deaths") or 0, " " } -- nick, score, zabojstwa
	end
	tableCanBeSwitched = false
	setBoxVisible(false)
	showTable(true)
end

function clearTempPlayers()
	tempPlayers = nil
	tableCanBeSwitched = true
	showTable(false)
end

local render = { -- 1680x1050
	["bg"] = {0.101190476*sX, 0.188571429*sY, 0.795238095*sX, 0.683809524*sY},
	["line"] = {0.498214286*sX, 0.205714286*sY, 0.498214286*sX, 0.843809524*sY}, -- linia środkowa
	["ttBg"] = {0.501190476*sX, 0.200952381*sY, 0.385714286*sX, 0.08*sY}, -- tło napisu TT
	["ctBg"] = {0.110119048*sX, 0.200952381*sY, 0.385714286*sX, 0.08*sY}, -- tło napisu CT

	["mainSize"] = 0.00119047619*sX, -- rozmiar nazw teamów i score
	["mainY"] = 0.20952381*sY, -- pozycja Y nazw teamów i score
	["ttText"] = {0.773809524*sX, 0.87797619*sX, 0.24*sY},
	["ctText"] = {0.118452381*sX, 0.222619048*sX, 0.24*sY},

	["line2"] = {0.500595238*sX, 0.298095238*sY, 0.886309524*sX},
	["line3"] = {0.110714286*sX, 0.495833333*sX}, -- 3 parametr z line2[3]

	-- nagłówki
	["headerSize"] = 0.000357142857*sX,
	["headerY"] = 0.280952381*sY,
	["label"] = {0.75*sX, 0.88452381*sX, 0.297142857*sY},
	["player"] = {0.505357143*sX, 0.744047619*sX, 0.296190476*sY},

	["label2"] = {0.360714286*sX, 0.495238095*sX, 0.293333333*sY},
	["player2"] = {0.114880952*sX, 0.353571429*sX, 0.293333333*sY},

	["score1"] = {0.505952381*sX, 0.536309524*sX, 0.273333333*sY},
	["score2"] = {0.460714286*sX, 0.491071429*sX, 0.273333333*sY},

	["specText"] = {0.10416666666*sX, 0.84761904761*sY, 0.89285714285*sX, 0.86857142857*sY},

	["playerSize"] = 0.000892857143*sX,
	["playerYPos"] = {0.299047619*sY - 0.0219047619*sY, 0.0219047619*sY},
	
	["playerName"] = { {0.505952381*sX, 0.666666667*sX}, {0.11547619*sX, 0.30297619*sX} },
	["playerScore"] = { {0.747619048*sX, 0.783333333*sX}, {0.35952381*sX, 0.395238095*sX} },
	["playerDeaths"] = { {0.785714286*sX, 0.821428571*sX}, {0.396428571*sX, 0.432142857*sX} },
	["playerPing"] = { {0.826190476*sX, 0.885119048*sX}, {0.436309524*sX, 0.494047619*sX} }

	--[[["playerNameCT"] = {0.11547619*sX, 0.30297619*sX},
	["playerScoreCT"] = {0.35952381*sX, 0.395238095*sX},
	["playerDeathsCT"] = {0.396428571*sX, 0.432142857*sX},
	["playerPingCT"] = {0.436309524*sX, 0.494047619*sX}]]--
}

function onScoreTableRender()
	if not tempPlayers then
		dxDrawRectangle(render["bg"][1], render["bg"][2], render["bg"][3], render["bg"][4], tocolor(0, 0, 0, 170), false) -- tło główne
		dxDrawLine(render["line"][1], render["line"][2], render["line"][3], render["line"][4], tocolor(255, 255, 255, 255), 0.00119047619*sX, false) -- linia środkowa
	else
		dxDrawRectangle(0, 0, sX, sY, tocolor(0, 0, 0), false) -- czarny prostokąt na ekran zamiast fadeCamera()
	end
	
	dxDrawRectangle(render["ttBg"][1], render["ttBg"][2], render["ttBg"][3], render["ttBg"][4], tocolor(135, 26, 31, 180), alse) -- tło napisu TT
	dxDrawRectangle(render["ctBg"][1], render["ctBg"][2], render["ctBg"][3], render["ctBg"][4], tocolor(24, 115, 177, 180), false) -- tło napisu CT
	
    dxDrawLine(render["line2"][1], render["line2"][2], render["line2"][3], render["line2"][2], tocolor(255, 255, 255, 255), 1, false)
    dxDrawLine(render["line3"][1], render["line2"][2], render["line3"][2], render["line2"][2], tocolor(255, 255, 255), 1, false)
	
    dxDrawText(getText("terrorists"), render["ttText"][1], render["mainY"], render["ttText"][2], render["ttText"][3], tocolor(255, 255, 255, 255), render["mainSize"], "sans", "right", "top", false, false, false)
    dxDrawText(getText("counterTerrorists"), render["ctText"][1], render["mainY"], render["ctText"][2], render["ctText"][3], tocolor(255, 255, 255, 255), render["mainSize"], "sans", "left", "top", false, false, false)
	
	dxDrawText(score[1], render["score1"][1], render["mainY"], render["score1"][2], render["score1"][3], tocolor(255, 255, 255, 255), render["mainSize"], "bankgothic", "left", "top", false, false, false) -- punkty tt
    dxDrawText(score[2], render["score2"][1], render["mainY"], render["score2"][2], render["score2"][3], tocolor(255, 255, 255, 255), render["mainSize"], "bankgothic", "right", "top", false, false, false) -- punkty ct

	dxDrawText(getText("scoreboard_infoLabel"), render["label"][1], render["headerY"], render["label"][2], render["label"][3], tocolor(153, 0, 0, 255), render["headerSize"], "bankgothic", "left", "top", false, false, false)
    dxDrawText(getText("scoreboard_player"), render["player"][1], render["headerY"], render["player"][2], render["player"][3], tocolor(153, 0, 0, 255), render["headerSize"], "bankgothic", "left", "top", false, false, false)

    dxDrawText(getText("scoreboard_infoLabel"), render["label2"][1], render["headerY"], render["label2"][2], render["label2"][3], tocolor(0, 51, 204, 255), render["headerSize"], "bankgothic", "left", "top", false, false, false)
    dxDrawText(getText("scoreboard_player"), render["player2"][1], render["headerY"], render["player2"][2], render["player2"][3], tocolor(0, 51, 204, 255), render["headerSize"], "bankgothic", "left", "top", false, false, false)		
	
	if not tempPlayers then
		for k, v in pairs(players[1]) do -- TT
			drawPlayer(v, k)
		end

		for k, v in pairs(players[2]) do -- CT
			drawPlayer(v, k)
		end
	else
		for k, v in pairs(tempPlayers[1]) do
			drawPlayer(v[1], k, 1, v[2], v[3], v[4], true)
		end

		for k, v in pairs(tempPlayers[2]) do
			drawPlayer(v[1], k, 2, v[2], v[3], v[4], true)
		end
	end
	
	if #players[3] >= 1 then -- obserwatorzy
		local text = getText("spectators") .. ": "
		for id, player in pairs(players[3]) do
			text = text .. getPlayerName(player)
			if id ~= #players[3] then
				text = text .. ", "
			end
		end
		dxDrawText(text, render["specText"][1], render["specText"][2], render["specText"][3], render["specText"][4], tocolor(146, 146, 146, 255), 0.8, "bankgothic", "left", "top", false, false, true, false, false)
	end
end

function drawPlayer(player, i, team, score, deaths, ping, alive)
	if isElement(player) then -- jeśli player to nie nick
		if getElementType(player) == "player" then
			name = getPlayerName(player)
			ping = getPlayerPing(player)
		else
			name = getElementData(player, "BotName") or "Bot Unnamed"
			ping = "BOT"
		end
		score = getElementData(player, "score") or 0
		deaths = getElementData(player, "deaths") or 0
		alive = getElementData(player, "alive")
		team = getTeamID(getPlayerTeam(player))
	else
		--if not team or not score or not deaths or not ping or not alive then return end
		name = player
	end

	if not alive then
		color = tocolor(128, 128, 128, 255)
	else
		if team == 1 then
			color = tocolor(100, 0, 0, 255)
		else
			color = tocolor(0, 80, 204, 255)
		end
	end

	local yPos = render["playerYPos"][1] + render["playerYPos"][2] * i

	dxDrawText(name, render["playerName"][team][1], yPos, render["playerName"][team][2], 0, color, render["playerSize"], "default", "left", "top", false, false, false) -- 1680x1050		
	dxDrawText(score, render["playerScore"][team][1], yPos, render["playerScore"][team][2], 0, color, render["playerSize"], "default", "center", "top", false, false, false)	
	dxDrawText(deaths, render["playerDeaths"][team][1], yPos, render["playerDeaths"][team][2], 0, color, render["playerSize"], "default", "center", "top", false, false, false)	
	dxDrawText(ping, render["playerPing"][team][1], yPos, render["playerPing"][team][2], 0, color, render["playerSize"], "default", "center", "top", false, false, false)
end