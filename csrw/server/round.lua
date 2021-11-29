g_roundData = {
	-- round state, can be: ended, starting, started
	state = "ended",
	aliveTT = 0,
	aliveCT = 0,

	-- if bomb is planted
	bomb = false
}

function updateClassInfos(skin, teamid) -- update teamu, skinu (z c class.lua)
	--outputChatBox("SERWER: updateClassInfos: client: " .. getPlayerName(client))
	-- zmienia team będąc żywym
	if getElementData(client, "alive") then
		local oldTeam = getPlayerTeam(client)
		if oldTeam == g_team[1] then g_roundData.aliveTT = g_roundData.aliveTT - 1
		elseif oldTeam == g_team[2] then aliveCT = g_roundData.aliveCT - 1 end
		setElementData(client, "alive", false)
	end
	
	changePlayerTeam(client, g_team[teamid], skin)
	g_player[client].surviveLastRound = false
	csResetWeapons(client)
	
	-- jeśli gracz dołącza do speca to dalszy kod się nie wykonuje (czyli runda nie zostaje przez to zakończona)
	if teamid ~= 3 then
		if not isRoundStarted() then
			startRound()
		else	
			--if checkPlayers() then -- jeśli checkPlayers() sprawdzi graczy i nie zakończy rundy
			if countPlayersInTeam(g_team[teamid]) - 1 == 0 or countPlayersInTeam( getOppositeTeam( g_team[teamid] ) ) == 0 then -- jeśli dołącza do pustej drużyny / przeciwna drużyna jest pusta to nastąpuje coś ala "Game Connecting" z CS 1.6
				onRoundEnd(3, 10)
			else
				-- jeśli runda nie trwa ponad 30 sekund
				if (getElementData(resourceRoot, "roundTimeMinutes") == 5 and getElementData(resourceRoot, "roundTimeSeconds") == 0) or (getElementData(resourceRoot, "roundTimeMinutes") == 4 and getElementData(resourceRoot, "roundTimeSeconds") >= 30) then
					spawn(client)
					syncGroundWeapons(client) -- sync broni położonych na ziemi (do danego gracza)
				else -- jeśli trwa
					outputChatBox("#FC6666" .. getText("msg_roundArleadyStarted", client), client, 255, 255, 255, true)
					joinSpectatorsTemporary(client)
				end
			end
		end
	end
end
addEvent("updateClassInfos", true)
addEventHandler("updateClassInfos", root, updateClassInfos, skin, theTeam)

function spawn(player) -- spawn
	local theTeam = getPlayerTeam(player)
	if theTeam == g_team[1] or theTeam == g_team[2] then
		local spawns
		if theTeam == g_team[1] then
			g_roundData.aliveTT = g_roundData.aliveTT + 1
			spawns = getElementsByType("spawntt")
		elseif theTeam == g_team[2] then
			g_roundData.aliveCT = g_roundData.aliveCT + 1
			spawns = getElementsByType("spawnct")
		end

		local spawnSlot = math.random(1, #spawns)
		local int = getElementData(spawns[spawnSlot], "interior") or 0
		local posX = getElementData(spawns[spawnSlot], "posX")
		local posY = getElementData(spawns[spawnSlot], "posY")
		local posZ = getElementData(spawns[spawnSlot], "posZ")
		local rotZ = getElementData(spawns[spawnSlot], "rotZ") or 0
		--outputChatBox("SERWER: spawn: " .. getPlayerName(player) .. "; skin: " .. tostring(skin) .. "; team: " .. getTeamName(team))
		
		if not posX or not posY or not posZ then
			outputChatBox("Spawn ID #FF6600" .. spawnSlot .. "#FFFFFF (team #FF6600" .. getTeamName(getPlayerTeam(player)) .. "#FFFFFF) is broken! Spawning again...", player, 255, 255, 255, true)
			if theTeam == g_team[1] then
				g_roundData.aliveTT = g_roundData.aliveTT - 1
			elseif theTeam == g_team[2] then
				g_roundData.aliveCT = g_roundData.aliveCT - 1
			end
			spawn(player)
		end

		spawnPlayer(player, posX, posY, posZ, rotZ, getTeamSkinValue(theTeam) + g_player[player].skin, int, 0, theTeam)
		setCameraTarget(player)
		setPlayerChannelByTeam(player)
		
		if not g_player[player].surviveLastRound then
			--if g_match.mode == "cs" then csGiveWeapon(player, 34, 1) end

			--csGiveWeapon(player, 3, 1, 1, 1, true) -- nóż
			csGiveWeapon(player, DEF_KNIFE[1], DEF_KNIFE[2], 1, 1, true)
			csGiveWeapon(player, 2, 1, tonumber(g_weapon[2][1]["ammo"]), tonumber(g_weapon[2][1]["clip"])) -- pistol
			--elseif g_match.mode == "cs" then
		else
			csGiveWeapon(player, 3, 1, 1, 1, false) -- dajemy mu nóż bo przecież inne bronie i tak ma w dacie i po zmianie slota je dostanie
		end

		if g_config["freekevlar"] then -- darmowy kevlar
			setElementData(player, "armor", 100)
		end
	end
end

function joinSpectatorsTemporary(player)
	triggerClientEvent("joinSpectatorsTemporary", player, player)
end

function randomizeBomberMan()
	if not isRoundStarted() then
		return false
	end

	local terrorists = getPlayersInTeam(g_team[1])
	for k, v in pairs(terrorists) do
		-- usuwanie nieżywych tt
		if getElementData(v, "alive") == false then
			table.remove( terrorists, table.find( terrorists, v ) )
		end
	end
	
	if #terrorists < 1 then
		return false
	end
	
	local randomTerro = terrorists[math.random(1, #terrorists)]
	csGiveWeapon(randomTerro, 8, 1, false, false, true)
	advert.ok("msg_bomberman", randomTerro)
	outputServerLog(getPlayerName(randomTerro) .. " got bomb.")
	return true
end

function onPlayerSpawn(x, y, z, rot, theTeam, skin, int, dimension)
	setElementCollisionsEnabled(source, true)
	setElementData(source, "alive", true)
	setElementData(source, "health", 100)
	
	-- "najmniejsza" animacja alt. bicia (CTRL + F; enter_exit)
	setPedFightingStyle(source, 16)
	
	-- MOVE_PLAYER_M
	setPedWalkingStyle(source, 56)

	setPedHeadless(source, false)

	-- refill weapon clips
	for i=1, #g_weapon do
		if g_playerWeaponData[source][i] then
			local wep = g_playerWeaponData[source][i].weapon
			if wep then
				g_playerWeaponData[source][i].clip = tonumber(g_weapon[i][wep]["clip"])
				g_playerWeaponData[source][i].ammo = tonumber(g_weapon[i][wep]["ammo"])
			end
		end
	end
end
addEventHandler("onPlayerSpawn", root, onPlayerSpawn)

function onPlayerWasted(ammo, killer, weapon, bodypart)
	if isRoundStarted() and getElementData(source, "alive") then
		local team = getPlayerTeam(source)
		if team == g_team[1] then g_roundData.aliveTT = g_roundData.aliveTT - 1
		elseif team == g_team[2] then g_roundData.aliveCT = g_roundData.aliveCT - 1 end
		
		if g_roundData.aliveTT < 0 or g_roundData.aliveCT < 0 then
			outputChatBox("SERVER: ERROR: A fatal error has occurred, the number of TT or CT players is negative.", root, 204, 0, 0)
			outputServerLog("ERROR: A fatal error has occurred, the number of TT or CT players is negative.")
		end
		
		setElementData(source, "alive", false)
		
		if killer and source ~= killer then
			if getPlayerTeam(source) == getPlayerTeam(killer) then -- teamkill
				takePlayerMoneyEx(killer, 1000) -- kara pieniężna za zabicie gracza ze swojej drużyny (możliwe tylko jeśli friendly fire jest włączone)
				setElementData(killer, "score", (getElementData(killer, "score") or 0) - 1)
				setPlayerAnnounceValue(killer, "score", (getElementData(killer, "score") or 0) - 1)
				advert.Error("Team kill! -$1000", killer, true)
			else
				givePlayerMoneyEx(killer, 300) -- bonus pieniężny za zabicie gracza
				setElementData(killer, "score", (getElementData(killer, "score") or 0) + 1)
				setPlayerAnnounceValue(killer, "score", (getElementData(killer, "score") or 0) + 1)
			end
		end
		setElementData(source, "deaths", (getElementData(source, "deaths") or 0) + 1)
		g_player[source].surviveLastRound = false
		setPlayerChannelByTeam(source)
		
		stopAnimationWithWalking(source)
		csResetWeapons(source)
		setElementData(source, "armor", 0)
		-- @todo: weapon drop after death
		
		-- bonus (zapomoga po śmierci) za podłożenie bomby (niezależnie czy wygrano tą runde czy nie)
		if getElementData(source, "hePlantedBomb") then
			-- @todo: zamienić na zmienną ^
			setElementData(source, "hePlantedBomb", false)
			givePlayerMoneyEx(source, 800)
			advert.ok(getText("msg_moneyAward", source) .. 800, source, true)
		end

		-- brak kolizji ciał; @todo: powinno być poza warunkiem isRoundStart() ?
		setElementCollisionsEnabled(source, false)

		-- sprawdza ile jest żywych graczy, w razie potrzeby kończy rundę
		if checkPlayers() then
			joinSpectatorsTemporary(source)
		end
		-- @todo: czy gracz może (i powinien) ginąć gdy nie jest w żadnym teamie?
	end
end
addEventHandler("onPlayerWasted", root, onPlayerWasted)

-- RUNDY
local roundEndReasons = {
	[0] = "unkown",
	"all players from team died",
	"bomb exploded",
	"bomb was defused",
	"bomb wasn't planted in time",
	"hostages are rescued",
	"hostages aren't rescued in time",
	"manually by admin",
	"manually by admin (freeze)",
	"all players left the match",
	"game connecting",
	"all humans was infected",
	"time expired"
}
function onRoundEnd(winTeam, reason)
	if not isRoundStarted() then
		return
	end

	--outputChatBox("SERWER: onRoundEnd(): winTeam = " .. winTeam .. "; reason = " .. reason)

	-- reason:
	-- 0 = unkown
	-- 1 = zginęli wszyscy członkowie drużyny
	-- 2 = bomba wybuchła
	-- 3 = bomba została rozbrojona
	-- 4 = bomba nie została podłożona (czas się skończył)
	-- 5 = zakładnicy zostali uwolnieni
	-- 6 = zakładnicy nie zostali uwolnieni (czas się skończył)
	-- 7 = manualnie przez admina
	-- 8 = manualnie przez admina (bez rozpoczynania nowej)
	-- 9 = wszyscy gracze opuścili gre
	-- 10 = game connecting (ktoś dołączył do pustej drużyny)
	
	-- zombie:
	-- 11 = wszyscy ct zostali zarażeni (wygrywa zombie)
	-- 12 = czas się skończył (wygrywają ct)

	if winTeam == 1 or winTeam == 2 then
		setElementData(g_team[ winTeam ], "score", getElementData(g_team[ winTeam ], "score") + 1)
	end
	outputServerLog("Round ended. Team " .. getTeamName( g_team[ winTeam ] ) .. " win (reason: " .. reason .. " - " .. roundEndReasons[reason] .. ").")
	g_roundData.state = "ended"
	
	-- kasa za wygranie rundy poprzez zabicie wszystkich członków pozostałej drużyny (jednakowa dla obu drużyn)
	if reason == 1 then
		for i, player in pairs( getPlayersInTeam(g_team[winTeam]) ) do
			givePlayerMoneyEx(player, 3250)
			advert.ok(getText("msg_moneyAward", player) .. 3250, player, true)
		end

	-- kasa dla TT za wybuch bomby
	elseif reason == 2 then
		for i, player in pairs( getPlayersInTeam(g_team[1]) ) do
			local money = 3500
			-- dodatkowy bonus pieniężny gdy jest conajmniej 1 CT żywy
			if g_roundData.aliveCT >= 1 then
				money = money + 200
			end
			givePlayerMoneyEx(player, money)
			advert.ok(getText("msg_moneyAward", player) .. money, player, true)
		end

	-- kasa dla CT za rozbrojenie bomby lub dla TT za skończenie się czasu na rozbrojenie bomby
	elseif reason == 3 or reason == 4 then
		for i, player in pairs( getPlayersInTeam(g_team[winTeam]) ) do
			givePlayerMoneyEx(player, 3250)
			advert.ok(getText("msg_moneyAward", player) .. 3250, player, true)
		end
	-- CT nie dostaje kasy za uwolnienie zakładników bo nie wiem ile to ma być
	-- to samo z TT - nie dostaje kasy za nie uwolnienie ich

	-- uwolnienie zakładników
	elseif reason == 5 then
		for k, v in pairs( getPlayersInTeam( g_team[winTeam] ) ) do
			givePlayerMoneyEx(v, 1000)
			advert.ok(getText("msg_moneyAward", v) .. 1000, v, true)
		end

	elseif reason == 8 then
		triggerClientEvent("changeViewToRandomCamera", root)
	elseif reason == 9 then
		outputText("msg_roundEndNoPlayers", 255, 255, 255, root)
	elseif reason == 10 then
		restartMatch()
	end

	if winTeam ~= 3 then
		local lostTeam = getOppositeTeam(winTeam)
		if lostTeam then
			-- zapomoga pieniężna dla przegrańców
			for k, v in pairs(getPlayersInTeam( g_team[ lostTeam ] )) do
				givePlayerMoneyEx(v, 1500)
			end
		end
	else
		for k, v in pairs(getElementsByType("player")) do
			if getPlayerTeam(v) == g_team[1] or getPlayerTeam(v) == g_team[2] then
				-- zapomoga dla obu drużyn podczas remisu
				givePlayerMoneyEx(v, 1500)
			end
		end
	end

	local players = getElementsByType("player")
	for i, player in pairs(players) do
		if getElementData(player, "alive") then
			g_player[player].surviveLastRound = true
			setPlayerChannelByTeam(player)
		end
	end

	g_roundData.aliveTT = 0
	g_roundData.aliveCT = 0
	if g_match.nextMap then
		setTimer(changeMap, 5000, 1, g_match.nextMap)
	else
		g_roundData.state = "starting"
		setTimer(startRound, 5000, 1)
	end
	
	for k, v in pairs( getPlayersInTeam(g_team[1]) ) do
		if getElementData(v, "wSlot" .. DEF_BOMB[1]) == DEF_BOMB[2] then
			csTakeWeapon(v, DEF_BOMB[1])
		end
	end
	
	balanceTeams()
	destroyBomb()
	destroyGroundWeapons()
	triggerClientEvent("onClientRoundEnd", root, winTeam, reason)
	setElementData(resourceRoot, "defusingBomb", false)
end
addEvent("onRoundEnd", false)
addEventHandler("onRoundEnd", root, onRoundEnd, winTeam, reason)

function startRound()
	if isRoundStarted() then
		return
	end

	local spawnedTT = 0
	local spawnedCT = 0
	g_roundData.aliveTT = 0
	g_roundData.aliveCT = 0
	
	for k, v in pairs(getPlayersInTeam(g_team[1])) do
		spawn(v)
		spawnedTT = spawnedTT + 1
	end

	for k, v in pairs(getPlayersInTeam(g_team[2])) do
		spawn(v)
		spawnedCT = spawnedCT + 1
	end

	for k, v in pairs( getPlayersInTeam(g_team[3]) ) do
		-- ukrywanie martwych ciał spectatorów z mapy
		setElementPosition(v, 0, 0, 4)
	end
	
	for k, vehicle in pairs(getElementsByType("vehicle")) do
		if getElementData(vehicle, "wreck") ~= "true" then
			respawnVehicle(vehicle)
		else
			if not isVehicleBlown(vehicle) then
				blowVehicle(vehicle, false)
			end
		end
	end
	respawnHostages()

	if spawnedTT == 0 and spawnedCT == 0 then
		outputText("msg_roundCantStartEmptyTeams", 255, 102, 102, root)
		g_roundData.state = "ended"
	else
		outputText("msg_roundStarting2", 255, 255, 255, root)
		
		outputServerLog("Round started!")
		g_roundData.state = "started"

		setElementData(resourceRoot, "bombPlanted", false)

		countdownRoundTime(5, 0)
		if g_match.bombsites then
			randomizeBomberMan()
		end

		g_match.rounds = g_match.rounds + 1
		if g_match.rounds == g_config["matchrounds"] - 1 then
			voteMaps()
		end			
	end
end

function countdownRoundTime(minutes, seconds)
	if seconds == -1 then
		minutes = minutes - 1
		seconds = 59
	end
	
	if isRoundStarted() and not g_roundData.bomb then
		setElementData(resourceRoot, "roundTimeMinutes", minutes)
		setElementData(resourceRoot, "roundTimeSeconds", seconds)
		
		if minutes == 0 and seconds == 0 then
			-- ^ jeśli jest 00:00 i jest przynajmniej jeden gracz w TT i CT
			if not g_roundData.bomb then
				if g_roundData.aliveCT >= 1 and g_match.bombsites then
					-- to czas na podłożenie bomby się skończył i CT wygrywa (na mapie muszą być BSy)
					triggerEvent("onRoundEnd", root, 2, 4)
				else
					-- remis bo nie ma nikogo żywego w CT lub/i nie ma BSów
					triggerEvent("onRoundEnd", root, 3, 4)
				end
			end
		else		
			if minutes >= 0 then
				setTimer(countdownRoundTime, 1000, 1, minutes, seconds - 1)
			end
		end
	end
end

-- mniejsze funkcje
function checkPlayers()
	if not isRoundStarted() then
		return false
	end

	if g_roundData.aliveTT >= 1 and g_roundData.aliveCT <= 0 then -- wygrywa TT
		if countPlayersInTeam(g_team[2]) <= 0 then
			-- gdy w przeciwnym teamie nie będzie graczy to po prostu runda się nie kończy (w cs 1.6 tak jest)
			-- słabo to w cs 1.6 rozwiązali, zrobimy po swojemu.. :>
			triggerEvent("onRoundEnd", root, 3, 10) -- po prostu remis
		else
			-- tutaj kurwa trzeba zrobić jakoś jakiś warunek jeśli gracz dołączy do pustego teamu żeby dawało remis a nie wygrywał przeciwnik!
			triggerEvent("onRoundEnd", root, 1, 1)
		end
	elseif g_roundData.aliveTT <= 0 and g_roundData.aliveCT >= 1 and not g_roundData.bomb then -- wygrywa CT (tylko jeśli bomba nie jest podłożona, w przeciwnym razie musi ją rozbroić aby wygrać)
		if countPlayersInTeam(g_team[1]) <= 0 then
			-- gdy w przeciwnym teamie nie będzie graczy to po prostu runda się nie kończy (w cs 1.6 tak jest)
			-- słabo to w cs 1.6 rozwiązali, zrobimy po swojemu.. :>
			-- po prostu remis
			triggerEvent("onRoundEnd", root, 3, 10)
		else
			triggerEvent("onRoundEnd", root, 2, 1)
		end
	elseif g_roundData.aliveTT <= 0 and g_roundData.aliveCT <= 0 then
		-- remis
		triggerEvent("onRoundEnd", root, 3, 1)
	end
end

function changePlayerTeam(player, team, theSkin)
	--if not skin then skin = math.random(1, 4)
	--if teamid ~= 0 then setPlayerTeam(player, g_team[teamid])
	setPlayerTeam(player, team)
	if theSkin then
		g_player[player].skin = theSkin
	elseif not g_player[player].skin then
		-- jeśli nie ma theSkin i gracz nie ma ustalonego skina (z wcześniejszego teamu) to losowanie
		g_player[player].skin = math.random(1, 4)
	end
	-- (skin jest fizycznie zmieniony przy spawnie)
end

function balanceTeams()
	if g_config["autobalance"] and #getElementsByType("player") >= 4 then -- auto balans drużyn od 4 graczy
		local t1 = balanceTeam(g_team[1]) or 0
		local t2 = balanceTeam(g_team[2]) or 0
		outputServerLog("Teams was ballanced (to CT: " .. t1 .. ", to TT: " .. t2 .. ").")
	end
end

function balanceTeam(team)
	local count = countPlayersInTeam(team)
	local oppositeCount = countPlayersInTeam(getOppositeTeam(team))
	
	local difference = count - oppositeCount
	if difference >= 2 then
		-- przerzucanie difference / 2 graczy do przeciwnej drużyny
		local players = getPlayersInTeam(team)
		
		for i = 1, difference / 2 do
			local pla = math.random(1, #players)
			changePlayerTeam(players[pla], getOppositeTeam(team))
			table.remove(players, pla)
		end
		return true
	else return false end
end

function getOppositeTeam(theTeam)
	if theTeam == 1 then return 2
	elseif theTeam == 2 then return 1
	elseif theTeam == g_team[1] then return g_team[2]
	elseif theTeam == g_team[2] then return g_team[1]
	else return nil end
end

function countAlivePlayers() return table.getn(getAlivePlayers()) end
function isRoundStarted() return g_roundData.state == "started" end

function getPlayerByID(id)
	local players = getElementsByType("player")
	return players[id]
end

function getTeamSkinValue(team)
	if team == g_team[1] then
		return 100
	elseif team == g_team[2] then
		return 104
	else
		return 0
	end
end
