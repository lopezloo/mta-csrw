local classButton = {}
local btnPos = 0.3
local btnSpace = 0.065

local classData = {}

local classes = {
	-- @todo: localize this
	[1] = {
		{"Phoenix Conexxion", "Having established a reputation for killing anyone that gets in their way, the Phoenix Connexion is one of the most feared terrorist groups in Eastern Europe. Formed shortly after the breakup of the USSR."},
		{"Elite Crew", "Middle Eastern fundamentalist group bent on world domination."},
		{"Arctic Avengers", "Swedish terrorist faction founded in 1977. Famous for their bombing of the Canadian embassy in 1990."},
		{"Guerilla Warfare", "A terrorist faction founded in the Middle East, this group has a reputation for ruthlessness. Their disgust for the American lifestyle was demonstrated in their 1982 bombing of a school bus full of Rock and Roll musicians."}
	},
	[2] = {
		{"Seal Team 6", "ST-6 (to be known later as DEVGRU) was founded in 1980. Under the command of Lieutenant-Commander Richard Marcincko. ST-6 was placed on permanent alert to respond Terrorist attacks against American targets worldwide."},
		{"GSG-9", "The GSG-9 was born out of the tragic events that led to the death of several Israeli athletes during the 1972 Olympics in Munich."},
		{"SAS", "The world-renowned British SAS was founded in the Second World War by a man named David Stirling. Their role during World War II (WW2) involved gathering intelligence behind enemy lines and executing sabotage strikes and assassinations against key targets."},
		{"GIGN", "France's elite Counter-Terrorist unit, the GIGN, was designed to be a fast response force that could decisively react to any large-scale terrorist incident. Consisting of no more than 100 men, the GIGN has earned its reputation through a history of successful ops."}
	}
}

function loadClassSelection()
	for i = 1, 10 do
		if i == 1 then
			classButton[i] = guiCreateButton(0.279166667, btnPos, 0.145238095, 0.0466666667, i .. " ", true)
		else
			classButton[i] = guiCreateButton(0.279166667, btnPos + btnSpace * (i - 1), 0.145238095, 0.0466666667, i .. " ", true)
		end

		guiSetAlpha(classButton[i], 0.9)
		guiSetFont(classButton[i], "default-bold-small")
		guiSetProperty(classButton[i], "NormalTextColour", "FFFF6900")
		guiSetProperty(classButton[i], "HoverTextColour", "FFFF6900")
		guiSetProperty(classButton[i], "PushedTextColour", "FFFF6900")	
		guiSetVisible(classButton[i], false)

		addEventHandler("onClientGUIClick", classButton[i], onClassClick)
		addEventHandler("onClientMouseEnter", classButton[i], onClassHover)
	end
end

function showClassSelection()
	classData["step"] = 1 -- wybór drużyny
	classData["class"] = false
	setBoxVisible(true, getText("class_chose1"), "class", "renderMapDescription", classButton)
	guiSetText(classButton[1], "1 " .. string.upper(getText("terrorists")))
	guiSetText(classButton[2], "2 " .. string.upper(getText("counterTerrorists")))

	guiSetText(classButton[5], "5 " .. getText("class_auto1"))
	guiSetText(classButton[6], "6 " .. getText("class_watch"))
	--guiSetText(classButton[7], "7 CHANGE LANGUAGE")

	for i=1, 9 do
		bindKey(tostring(i), "down", onClassKey)
	end

	guiSetVisible(classButton[1], true)
	guiSetVisible(classButton[2], true)
	guiSetVisible(classButton[5], true)
	guiSetVisible(classButton[6], true)
	--guiSetVisible(classButton[7], true)
	showCursor(true)
end

function onClassClosed(window)
	if window == "class" then
		for i=1, 9 do
			unbindKey(tostring(i), "down", onClassKey)
		end
		showCursor(false)
	end
end

function onClassClick()
	if classData["step"] == 1 then -- klik w wyborze drużyny
		for i=1, 10 do
			if source == classButton[i] then chooseTeam(i) end
		end

	elseif classData["step"] == 2 then -- klik w wyborze klasy
		for i=1, 7 do
			if source == classButton[i] then
				chooseClass(i)
				break
			end
		end
	end
end

function onClassHover() -- najechanie na button klasy
	if classData["step"] == 2 then
		for i=1, 4 do
			if source == classButton[i] then
				classData["class"] = i -- aktualna klasa postaci przeglądana przez gracza
 				break
			end
		end
	end
end

function onClassKey(key, state) -- wybór klasy bindem
	key = tonumber(key)
	if classData["step"] == 1 and key <= 7 and key ~= 4 and key ~= 3 then
		chooseTeam(key)
	elseif classData["step"] == 2 and key <= 7 and key ~= 5 then
		chooseClass(key)
	end
end

function chooseTeam(teamID)
	-- tt, ct, [5] = random, [6] = spec

	if teamID == 5 then 
		teamID = math.random(1, 2)
	elseif teamID == 6 then -- spec
		classData["step"] = 0
		setBoxVisible(false)
		spectator.join()
		return
	end

	classData["step"] = 2
	classData["team"] = teamID
	setBoxVisible(true, getText("class_chose2"), "class", "renderClassInfo", classButton)
	showCursor(true)
	for i=1, 4 do
		guiSetText(classButton[i], i .. " " .. string.upper(classes[teamID][i][1]))
		guiSetVisible(classButton[i], true)
	end
	guiSetVisible(classButton[6], true)
	guiSetText(classButton[6], "6 " .. string.upper(getText("cancel")))
	guiSetVisible(classButton[7], true)
	guiSetText(classButton[7], "7 " .. getText("class_auto2"))	

	for i=1, 9 do
		bindKey(tostring(i), "down", onClassKey)
	end	
end

function chooseClass(classID)
	classData["step"] = 0
	if classID == 7 then classID = math.random(1, 2) end

	if classData["team"] == 1 then
		classData["skin"] = classID
	elseif classData["team"] == 2 then
		classData["skin"] = classID
	end
	setBoxVisible(false)

	if classID == 6 then -- powrót
		showClassSelection()
	else
		--if lobbyPed then destroyElement(lobbyPed) end
		classUpdatePlayer()
	end
end

function classUpdatePlayer(skin, team)
	if not skin then skin = classData["skin"] end
	if not team then team = classData["team"] end
	if team ~= 3 then spectator.exit() end
	triggerServerEvent("updateClassInfos", resourceRoot, skin, team)
end

-- bind
addCommandHandler("Class Selection", 
	function()
		if getElementData(localPlayer, "alive") or g_player.spectating then
			if getActiveBoxWindow() == "class" then
				setBoxVisible(false)
			else
				showClassSelection()
			end
		end
	end
)
bindKey("M", "down", "Class Selection")

-- 1440 x 900
local classRender = { -- 1440 x 900
	["img"] = {0.469*sX, 0.256*sY, 0.252*sX, 0.416*sY}, -- 676, 231, 364, 375
	["txt"] = {0.441*sX, 0.684*sY, 0.777*sX, 0.866*sY}, -- 636, 616, 1120, 780
	["desc"] = {0.441*sX, 0.3*sY, 0.777*sX, 0.866*sY}
}
function renderClassInfo()
	if classData["class"] then
		dxDrawImage(classRender["img"][1], classRender["img"][2], classRender["img"][3], classRender["img"][4], ":csrw-media/images/skins/" .. classData["team"] .. "-" .. classData["class"] .. ".png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
		dxDrawText(classes[classData["team"]][classData["class"]][2], classRender["txt"][1], classRender["txt"][2], classRender["txt"][3], classRender["txt"][4], tocolor(240, 89, 14, 255), 1.00, "default-bold", "left", "top", false, true, false, false, false)
	end
end

function renderMapDescription()
	dxDrawText(getElementData(resourceRoot, "mapDesc") or "", classRender["desc"][1], classRender["desc"][2], classRender["desc"][3], classRender["desc"][4], tocolor(240, 89, 14, 255), 1.00, "default-bold", "left", "top", false, true, false, false, false)
end
