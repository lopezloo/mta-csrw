local nominateWindow = guiCreateWindow(0.01, 0.31, 0.17, 0.53, getText("nominateMap"), true)
guiWindowSetMovable(nominateWindow, false)
guiWindowSetSizable(nominateWindow, false)

local nominateGrid = guiCreateGridList(0.05, 0.06, 0.91, 0.92, true, nominateWindow)
guiGridListAddColumn(nominateGrid, getText("Map"), 0.5)
guiGridListAddColumn(nominateGrid, getText("Author"), 0.5)

guiSetVisible(nominateWindow, false)

addEvent("updateMapList", true)
addEventHandler("updateMapList", root,
	function(data)
		guiGridListClear(nominateGrid)
		for k, v in pairs(data) do
			local row = guiGridListAddRow(nominateGrid)
			guiGridListSetItemText(nominateGrid, row, 1, string.gsub(v[1], "csrw_", ""), false, false) -- nazwa mapy
			guiGridListSetItemText(nominateGrid, row, 2, v[2], false, false) -- autor mapy
		end
		outputDebugString("Map list updated.")
	end
)
triggerServerEvent("pleaseSendMeMapList", resourceRoot)

addEventHandler("onClientGUIDoubleClick", nominateGrid,
	function(button, state)
		if button == "left" and state == "up" then
			local row = guiGridListGetSelectedItem(nominateGrid)
			if row ~= -1 then
				local mapName = guiGridListGetItemText(nominateGrid, row, 1)
				outputDebugString("Nominating " .. tostring(mapName))
				triggerServerEvent("nominateMap", resourceRoot, mapName)
				guiSetVisible(nominateWindow, false)
				showCursor(false)
			end
		end
	end
)

addCommandHandler("nominate",
	function()
		local show = not guiGetVisible(nominateWindow)
		guiSetVisible(nominateWindow, show)
		showCursor(show)
	end
)