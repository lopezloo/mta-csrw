function onPlayerChat(message, messageType)
	if messageType == 1 then cancelEvent() end -- blokowanie /me

	if messageType == 0 or messageType == 2 then
		cancelEvent()

		-- RTV
		if message == "rtv" or message == "rockthevote" or message == "rock the vote" then
			if g_match.nextMap then
				outputChatBox("New map was already choosen.", source)
			elseif g_player[source].rtv then
				outputChatBox("You have already voted to change map.", source)
			else
				local pCount = #getElementsByType("player")
				if pCount == 1 then pCount = 2 end -- jeden gracz nie może wywołać rtv

				g_match.wantsRTV = g_match.wantsRTV + 1
				g_player[source].rtv = true

				local neededVotes = math.round(pCount*0.75) -- 3/4 wszystkich graczy wymagana do rtv
				--outputChatBox("neededVotes: " .. neededVotes .. " g_match.wantsRTV: " .. g_match.wantsRTV)
				
				if g_match.wantsRTV >= neededVotes then -- jeśli liczba chcących rtv jest większa lub równa liczbyGraczy * 0.75
					outputChatBox("#FFFFFF* #FF6600" .. getPlayerName(source) .. " #FFFFFFwants map change. Vote starts...", root, 255, 255, 255, true)	
					voteMaps()
				else
					local stillNeeded = neededVotes - g_match.wantsRTV
					outputChatBox("#FFFFFF* #FF6600" .. getPlayerName(source) .. " #FFFFFFwants map change! If you want change map type #FF6600RTV#FFFFFF. Votes needed: " .. stillNeeded, root, 255, 255, 255, true)
				end
			end

		-- CHAT
		else
			local playerTeam = getPlayerTeam(source)
			if not playerTeam then playerTeam = g_team[3] end
			local color = {}
			color[1], color[2], color[3] = getTeamColor(playerTeam)
			local colorHex = rgbToHex(color[1], color[2], color[3])
			
			if messageType == 0 then -- rozmowa ze wszystkimi
				if getElementData(source, "alive") then -- jeśli żywy
					outputChatBox(getPlayerName(source) .. "#E7D9B0: " .. message, root, color[1], color[2], color[3], true)
					outputServerLog(getPlayerName(source) .. ": " .. message)
				else
					for i, deadPlayer in pairs( getElementsByType("player") ) do
						if not getElementData(deadPlayer, "alive") then
							outputChatBox(getText("dead", deadPlayer) .. colorHex .. getPlayerName(source) .. "#E7D9B0: " .. message, deadPlayer, 231, 217, 176, true)
						end
					end
					outputServerLog("*DEAD* " .. getPlayerName(source) .. ": " .. message)
				end
			else -- rozmowa z teamem
				if getElementData(source, "alive") then -- jeśli żywy
					for i, teamPlayer in pairs(getPlayersInTeam(playerTeam)) do
						outputChatBox("(TEAM) " .. colorHex .. getPlayerName(source) .. "#E7D9B0: " .. message, teamPlayer, 231, 217, 176, true)
					end
					outputServerLog("*TEAM* " .. getPlayerName(source) .. ": " .. message)
				else
					for i, deadTeamPlayer in pairs( getPlayersInTeam( g_team[3] ) ) do
						if not getElementData(deadTeamPlayer, "alive") then
							outputChatBox(getText("dead", deadTeamPlayer) .. "(TEAM) " .. colorHex .. getPlayerName(source) .. "#E7D9B0: " .. message, deadTeamPlayer, 231, 217, 176, true)
						end
					end
					outputServerLog("*DEAD|TEAM* " .. getPlayerName(source) .. ": " .. message)
				end

				if getPlayerTeam(source) ~= playerTeam then
					if getElementData(source, "alive") then
						outputChatBox("(TEAM) " .. colorHex .. getPlayerName(source) .. "#E7D9B0: " .. message, source, 231, 217, 176, true)
					else
						outputChatBox(getText("dead", source) .. "(TEAM) " .. colorHex .. getPlayerName(source) .. "#E7D9B0: " .. message, source, 231, 217, 176, true)
					end
				end
			end
		end
	end
end
addEventHandler("onPlayerChat", root, onPlayerChat)

function onMapStop(stoppedMap)
	destroyBomb()
	destroyGroundWeapons() -- chyba nie działa, bronie na ziemi po zmianie mapy zostają
	removeHostages()
	g_roundData.state = "ended"
	g_match.bombsites = false
	g_match.hostages = false
	
	for k, v in pairs(getElementsByType("player")) do
		--if getElementData(v, "alive") and isTimer(zombieIdleTimers[v]) then killTimer(zombieIdleTimers[v]) end
		setElementData(v, "anim", false)
		setElementData(v, "alive", false)
	end

	for k, v in pairs(getElementsByType("marker")) do
		destroyElement(v)
	end

	g_roundData.aliveTT = 0
	g_roundData.aliveCT = 0
	
	outputText("rtv_mapChanging", 255, 102, 0, resourceRoot)
end
addEventHandler("onGamemodeMapStop", root, onMapStop)

function onMapStart(startedMap)
	if #getElementsByType("spawntt") == 0 or #getElementsByType("spawnct") == 0 then
		outputChatBox("ERROR: Map " .. getResourceName(startedMap) .. " doesn't have TT or CT spawnpoints. Starting random map in 5 seconds..")
		outputServerLog("ERROR: Map " .. getResourceName(startedMap) .. " doesn't have TT or CT spawnpoints. Starting random map in 5 seconds..")
		setTimer(changeToRandomMap, 5000, 1)
		return
	end

	if getResourceName(startedMap) == "editor_test" or getResourceName(startedMap) == "editor_dump" then
		outputChatBox("ERROR: Invalid map. Starting random map in 5 seconds..")
		outputServerLog("ERROR: Invalid map, if you still think it's must work.. change they name. Starting random map in 5 seconds..")
		setTimer(changeToRandomMap, 5000, 1)
		return
	end

	-- wczytywanie opisu
	local description = getResourceInfo(startedMap, "description") or ""
	local author = getResourceInfo(startedMap, "author")
	if author then
		description = description .. "\nMap author: " .. author
	end
	if description == "" then description = false end
	setElementData(resourceRoot, "mapDesc", description)
	setGameType("CSRW: " .. string.gsub(getResourceName(startedMap), "csrw_", ""))
	--setMapName(string.gsub(getResourceName(startedMap), "csrw_", ""))
	setRuleValue("map", string.gsub(getResourceName(startedMap), "csrw_", ""))
	
	--[[if string.find(getResourceName(startedMap), "zm_") then
		setElementData(resourceRoot, "currentMode", "zombie")
	else
		setElementData(resourceRoot, "currentMode", "cs") -- cs lub zombie
	end]]--

	-- wczytywanie pojazdów
	for i, vehicle in pairs(getElementsByType("vehicle")) do
		if tostring(getElementData(vehicle, "decorative")) == "true" then
			setElementFrozen(vehicle, true)
			setVehicleDamageProof(vehicle, true)
		end
	end
	
	-- wczytywanie bombsite
	local bombsiteLetters = {"A", "B", "C"}
	if not g_config["nobomb"] then
		local bombsites = getElementsByType("bombsite")
		for k, v in pairs(bombsites) do
			local marker = createMarker(getElementData(v, "posX"), getElementData(v, "posY"), getElementData(v, "posZ"), "cylinder", getElementData(v, "size"), 255, 255, 255, 0, nil)
			setElementInterior(marker, getElementData(v, "interior") or 0)
			setElementID(marker, bombsiteLetters[k])
		end
		if #bombsites > 0 then
			g_match.bombsites = true
		end
	end

	createHostages()
	for k, v in pairs(getElementsByType("player")) do
		changeViewToRandomCamera(v)
	end
	triggerClientEvent("onMapStart", resourceRoot, getResourceName(startedMap))

	restartMatch()
	for i, player in pairs(getElementsByType("player")) do
		setElementData(player, "alive", false)
		setPlayerTeam(player, nil)
	end

	-- sprawdzanie wersji
	checkScriptUpdates()
	if hasObjectPermissionTo(getThisResource(), "function.callRemote") then
		callRemote("http://community.mtasa.com/mta/resources.php", onStartedMapUpdatesChecked, "version", getResourceName(startedMap))
	end
end
addEventHandler("onGamemodeMapStart", root, onMapStart)

function onStartedMapUpdatesChecked(name, version, id)
	if id then
		local currentVer = getResourceInfo(getResourceFromName(name), "version")
		if currentVer ~= version then
			outputServerLog("\n======== VERSION CHECK ========\nMap " .. name .. " is outdated! New version (" .. version .. ") available at https://community.mtasa.com/index.php?p=resources&s=details&id=" .. id .. "\n===============================")
		end
	end
end

-- funkcje pomocnicze
function isValidMap(map)
	return exports["mapmanager"]:isMapCompatibleWithGamemode(map, getThisResource())
end

function changeMap(newmap)
	return exports["mapmanager"]:changeGamemodeMap(newmap) -- newmap to nie nazwa resource tylko resource !!!
end

function getCounterStrikeMaps()
	local maps = exports["mapmanager"]:getMapsCompatibleWithGamemode(getThisResource())
	if not maps then
		outputServerLog("CRITICAL ERROR: Stupid 'mapmanager' can't believe this resource is gamemode. Please restart server.")
	end
	for k, v in pairs(maps) do
		if getResourceName(v) == "editor_dump" or getResourceName(v) == "editor_test" then
			table.remove(maps, k)
		end
	end
	return maps
end

function getCurrentMap()
	return exports["mapmanager"]:getRunningGamemodeMap()
end

function changeToRandomMap()
	local map = getRandomMaps(1)
	--outputServerLog(tostring(getResourceName(map[1])))
	changeMap(map[1])
end

function getRandomMaps(count) -- zwraca losowe mapy w formie nazw resource (nie powtarzają się)
	-- wczesniej ta funkcja zwracala nazwy map, a nie element resource
	local allMaps = getCounterStrikeMaps()
	if #allMaps == 1 then return {getCurrentMap()} end -- zwraca aktualną mape jeśli nie ma innych map
	local deleteMap = table.find(allMaps, getCurrentMap())
	table.remove(allMaps, deleteMap)
	
	local selectedMaps = {}
	for i=1, count do
		randomMap = math.random(1, #allMaps)
		table.insert(selectedMaps, allMaps[randomMap])
		table.remove(allMaps, randomMap)
		--outputChatBox("getRandomMaps(): " .. i .. ". " .. allMaps[randomMap])
	end
	return selectedMaps
end