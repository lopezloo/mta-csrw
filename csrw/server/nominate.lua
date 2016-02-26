local playerNominations = { }
local nominations = {}

local nominateLimit = 5
local currentVoteOptions = {} -- mapy w obecnym głosowaniu

-- TODO: języki

function nominateMap(mapName) -- nazwa mapy
	if #currentVoteOptions > 0 then -- jeśli właśnie jest głosowanie to return
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

	for k, v in pairs(nominations) do
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

		for k, v in pairs(getElementsByType("player")) do
			outputChatBox(" * " .. getPlayerName(client) .. getText("msgPart_nominated", v) .. string.gsub(mapName, "csrw_", "") .. ".", v)
		end
	else -- nominował wcześniej mape
		if playerNominations[client] == mapName then
			outputText("msg_mapNominatedByYou", 255, 102, 102, client)
			return
		end

		table.remove(nominations, table.find(nominations, playerNominations[client]))

		for k, v in pairs(getElementsByType("player")) do
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
		local maps = getCounterStrikeMaps()
		local mapsData = {}
		
		for id, map in pairs(maps) do
			table.insert(mapsData, { getResourceName(map), getResourceInfo(map, "author") or "-" })
		end
		triggerClientEvent("updateMapList", client, mapsData)
	end
)

function deletePlayerNomination(player)
	if playerNominations[player] then
		table.remove(nominations, table.find(nominations, playerNominations[player])) -- todo if nie ma aktualnie głosowania
		playerNominations[player] = nil
	end
end

function clearNominations()
	playerNominations = {}
	nominations = {}
end

-- głosowanie
function voteMaps()
	if getResourceState(getResourceFromName("votemanager")) ~= "running" then
		if hasObjectPermissionTo(getThisResource(), "function.startResource") then
			outputServerLog("Turning votemanger on due to maps vote.")
			startResource(getResourceFromName("votemanager"))
		else
			outputServerLog("ERROR: Vote can't be started because votemanager is turned off.")
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

	for k, v in pairs(nominations) do
		table.insert(pollTable, {v})
		table.insert(currentVoteOptions, v)
	end

	if #nominations < nominateLimit then -- są jeszcze miejsca na mapy
		local maps = exports["mapmanager"]:getMapsCompatibleWithGamemode(getThisResource())
		for k, v in pairs(maps) do
			if getCurrentMap() == v or getResourceName(v) == "editor_test" or getResourceName(v) == "editor_dump" then
				table.remove(maps, k)
				break
			end

			for k2, v2 in pairs(nominations) do
				if getResourceName(v) == v2 then
					--outputChatBox("Usuwanie mapy " .. v2 .. " ze wzgledu na powtarzanie sie.")
					table.remove(maps, k2)
					break
				end
			end
		end

		for i=1, nominateLimit - #nominations do
			local r = math.random(1, #maps)
			table.insert(pollTable, { getResourceName(maps[r]) })
			table.insert(currentVoteOptions, getResourceName(maps[r]))
			table.remove(maps, r)
		end
	end
	table.insert(pollTable, {"Extend"})
	exports["votemanager"]:startPoll(pollTable)
end

addEventHandler("onPollEnd", root,
	function(result)
		if result and #currentVoteOptions > 0 then

			if result > #currentVoteOptions then
				outputText("msg_mapExtended", 255, 255, 255, root)
				currentVoteOptions = {}
				return
			end

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

--[[addCommandHandler("votedebug",
	function(player)
		if hasObjectPermissionTo(player, "function.kickPlayer") then
			outputChatBox("votedebug")
			voteMaps()
		end
	end
)]]--