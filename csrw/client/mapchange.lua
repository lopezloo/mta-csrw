local loadingMap -- nazwa aktualnie ładowanej mapy
local loadingTimer
local loadingMusic

addEvent("onMapStart", true)
addEventHandler("onMapStart", root,
	function(mapname)
		saveTeamsToTemp()
		spectator.exit()
		preInit()

		local team = getPlayerTeam(localPlayer)

		if loadingMusic and isElement(loadingMusic) then stopSound(loadingMusic) end
		if team then
			local oppositeTeam = getOppositeTeam(team)
			if (getElementData(team, "score") or 0) > (getElementData(oppositeTeam, "score") or 0) then
				loadingMusic = playSound(":csrw-sounds/sounds/music/winmusic.mp3")
			elseif (getElementData(team, "score") or 0) < (getElementData(oppositeTeam, "score") or 0) then
				loadingMusic = playSound(":csrw-sounds/sounds/music/lossmusic.mp3")
			else
				loadingMusic = playSound(":csrw-sounds/sounds/music/drawmusic.mp3")
			end
		else loadingMusic = playSound(":csrw-sounds/sounds/music/drawmusic.mp3") end

		outputDebugString("New map started (" .. mapname .. ").")
		loadingMap = mapname
		
		loadingTimer = setTimer(
			function()
				if loadingMap ~= false then
					clearTempPlayers()
					loadingMap = false
					stopSound(loadingMusic)
					init()
				end
			end, 5000, 1)
	end
)

addEventHandler("onClientResourceStart", root,
	function(resource)
		if getResourceName(resource) == loadingMap then
			outputDebugString("Downloaded map (" .. loadingMap .. ").")
			if loadingMap ~= false and (not loadingTimer or not isTimer(loadingTimer)) then
				clearTempPlayers()
				loadingMap = false
				stopSound(loadingMusic)
			end
		end
	end
)
