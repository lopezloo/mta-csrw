local playerNominations = { }
local nominations = {}

local nominateLimit = 5

-- lista map w obecnym głosowaniu
local currentVoteOptions = {}

function nominateMap(mapName)
	if not client or client ~= source then
		return
	end

	if #currentVoteOptions > 0 then
		outputText("msg_ArleadyVoting", 255, 102, 102, client)
		return
	end

	if not getResourceFromName(mapName) then
		mapName = "csrw_" .. mapName
	end

	if getResourceFromName(mapName) == getCurrentMap() then
		outputText("msg_nomIsCurrently", 255, 102, 102, client)
		return
	end

	for _, v in pairs(nominations) do
		if v == mapName then
			outputText("msg_mapAlreadyNominated", 255, 102, 120, client)
			return
		end
	end

	if not playerNominations[client] then -- nie nominował wcześniej żadnej mapy
		if #nominations == nominateLimit then
			outputText("msg_nominateLimitReached", 255, 102, 102, client)
			return
		end

		playerNominations[client] = mapName
		table.insert(nominations, mapName)

		for _, v in pairs(getElementsByType("player")) do
			outputChatBox(" * " .. getPlayerName(client) .. getText("msgPart_nominated", v) .. string.gsub(mapName, "csrw_", "") .. ".", v)
		end
	else -- nominował wcześniej mape
		if playerNominations[client] == mapName then
			outputText("msg_mapNominatedByYou", 255, 102, 102, client)
			return
		end

		table.removeElement(nominations, playerNominations[client])

		for _, v in pairs(getElementsByType("player")) do
			outputChatBox(" * " .. getPlayerName(client) .. getText("nomChanged", v) .. playerNominations[client] .. " " .. getText("to", v) .. " " .. string.gsub(mapName, "csrw_", "") .. ".", v)
		end
		playerNominations[client] = mapName
		table.insert(nominations, mapName)
	end
end
addEvent("nominateMap", true)
addEventHandler("nominateMap", root, nominateMap, mapName)

addEvent("pleaseSendMeMapList", true)
addEventHandler("pleaseSendMeMapList", root,
	function()
		if not client or client ~= source then
			return
		end

		local maps = getCSMaps()
		local mapsData = {}
		
		for _, map in pairs(maps) do
			table.insert(mapsData, { getResourceName(map), getResourceInfo(map, "author") or "-" })
		end
		triggerClientEvent("updateMapList", client, mapsData)
	end
)

function deletePlayerNomination(player)
	if playerNominations[player] then
		table.removeElement(nominations, playerNominations[player]) -- todo if nie ma aktualnie głosowania
		playerNominations[player] = nil
	end
end

function clearNominations()
	playerNominations = {}
	nominations = {}

	for k, v in pairs(g_player) do
		g_player[k].rtv = false
	end
end

function voteMaps()
	if #currentVoteOptions > 0 or g_match.nextMap then
		-- map vote already started or map was selected and gonna change soon
		return
	end

	if getResourceState(getResourceFromName("votemanager")) ~= "running" then
		if hasObjectPermissionTo(getThisResource(), "function.startResource") then
			outputServerLog("Turning votemanger on due to map vote.")
			startResource(getResourceFromName("votemanager"))
		else
			outputServerLog("ERROR: Map vote can't be started because votemanager is turned off.")
			return
		end
	end

	local pollTable = {
		--start settings (dictionary part)
		title  = "Choose new map:",
		percentage = 75,
		timeout = 15,
		allowchange = true,
		maxnominations = nominateLimit + 1,
		visibleTo = root,
		--start options (array part)
	}

	for _, v in pairs(nominations) do
		table.insert(pollTable, {v})
		table.insert(currentVoteOptions, v)
	end

	-- if there is still place for maps
	if #nominations < nominateLimit then
		local maps = {}
		for _, v in pairs(exports["mapmanager"]:getMapsCompatibleWithGamemode(getThisResource())) do
			local name = getResourceName(v)
			if getCurrentMap() ~= v and name ~= "editor_test" and name ~= "editor_dump" then
				local nominated = false
				for _, v2 in pairs(nominations) do
					if name == v2 then
						nominated = true
						break
					end
				end
				if not nominated then
					table.insert(maps, v)
				end
			end
		end

		for i=1, nominateLimit - #nominations do
			if #maps == 0 then
				break
			end
			
			local r = math.random(1, #maps)
			table.insert(pollTable, { getResourceName(maps[r]) })
			table.insert(currentVoteOptions, getResourceName(maps[r]))
			table.remove(maps, r)
		end
	end
	-- Add current map as rematch option
	table.insert(pollTable, {"Rematch"})
	table.insert(currentVoteOptions, getResourceName(exports["mapmanager"]:getRunningGamemodeMap()))

	exports["votemanager"]:startPoll(pollTable)
end

addEventHandler("onPollEnd", root,
	function(result)
		if result and #currentVoteOptions > 0 then
			local resource = getResourceFromName( currentVoteOptions[result] )
			if resource then
				if g_roundData.state == "ended" then
					outputChatBox("Vote was ended. New map: " .. currentVoteOptions[result] .. ".")
					changeMap(resource) -- zmiana natychmiastowa bo runda jest skończona
				else
					outputChatBox("Vote was ended. New map (" .. currentVoteOptions[result] .. ") starts after this round.")
					g_match.nextMap = resource -- zmiana po zakończeniu rundy
				end
				currentVoteOptions = {}
			end
		end
	end
)
