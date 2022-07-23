local shopButton = {}
local currentWeapon = {}

local shop = { {}, {} } -- dwa teamy
local currentCategory

local shopInformation = {}

local DEBUG_SKIP_GRENADE_LIMIT = true

addCommandHandler("Shop",
	function()
		if getActiveBoxWindow() == "shop" then
			setBoxVisible(false)
		
		else
			showShop()
		end
	end
)
bindKey("B", "down", "Shop")

function showShop()
	if not getElementData(localPlayer, "alive") then
		return
	end

	-- jeśli runda nie trwa ponad 15 sekund
	--if getElementData(resourceRoot, "currentMode") == "cs" or getPlayerTeam(localPlayer) == ct then -- w trybie zombie tylko dla CT
	local mapTime = 5
	if getElementData(resourceRoot, "currentMode") == "zombie" then
		mapTime = 10
	end

	--if (getElementData(resourceRoot, "roundTimeMinutes") == 5 and getElementData(resourceRoot, "roundTimeSeconds") == 0) or (getElementData(resourceRoot, "roundTimeMinutes") == 10 and getElementData(resourceRoot, "roundTimeSeconds") == 0) or (getElementData(resourceRoot, "roundTimeMinutes") == mapTime - 1 and getElementData(resourceRoot, "roundTimeSeconds") >= 15) then
	if 1 == 1 then
		local plus = 0
		if getPlayerTeam(localPlayer) == g_team[1] then
			spawnsTT = getElementsByType("spawntt")
			for i, spawn in pairs(spawnsTT) do
				local x = getElementData(spawn, "posX")
				local y = getElementData(spawn, "posY")
				local z = getElementData(spawn, "posZ")
				if isElementInRangeOfPoint(localPlayer, x, y, z, 5.0) then
					plus = plus + 1
				end
			end
		
		elseif getPlayerTeam(localPlayer) == g_team[2] then
			spawnsCT = getElementsByType("spawnct")
			for i, spawn in pairs(spawnsCT) do
				local x = getElementData(spawn, "posX")
				local y = getElementData(spawn, "posY")
				local z = getElementData(spawn, "posZ")
				if isElementInRangeOfPoint(localPlayer, x, y, z, 5.0) then
					plus = plus + 1
				end
			end	
		end
		
		if plus >= 1 then
			activateWindow_shop()
		else
			advert.error("msg_buyNeedSpawn")
		end					
	else -- jeśli trwa
		playSound(":csrw-sounds/sounds/resource/warning.wav")
		--advert.Error("msg_buyTime")
	end
end

addEventHandler("onClientResourceStart", resourceRoot,
	function()
		addEventHandler("onBoxClosed", root, onShopClosed)
		
		for i = 1, 10 do
			shopInformation[i] = getText("shop_info" .. i)
		end

		--local shopButtonPos = 0.279047619 -- stara pozycja
		local shopButtonPos = 0.25
		--local shopButtonSpace = 0.071428571 -- stara pozycja
		local shopButtonSpace = 0.065

		for i = 1, 10 do
			if i == 1 then
				shopButton[i] = guiCreateButton(0.279166667, shopButtonPos, 0.145238095, 0.0466666667, i .. " ", true)
			else
				shopButton[i] = guiCreateButton(0.279166667, shopButtonPos + shopButtonSpace * (i - 1), 0.145238095, 0.0466666667, i .. " ", true)
			end

			guiSetAlpha(shopButton[i], 0.9)
			guiSetFont(shopButton[i], "default-bold-small")
			guiSetProperty(shopButton[i], "NormalTextColour", "FFFF6900")
			guiSetProperty(shopButton[i], "HoverTextColour", "FFFF6900")
			guiSetProperty(shopButton[i], "PushedTextColour", "FFFF6900")	
			guiSetVisible(shopButton[i], false)
		end
		outputDebugString("shop GUI loaded")
		-- koniec wczytywania gui		
		loadShopWeapons()
	end
)

function loadShopWeapons()
	-- wczytywanie kategori broni teamów i broni przypisanych do nich
	local shopFile = xmlLoadFile("files/shop.xml")
	if not shopFile then
		outputDebugString("CRTICAL ERROR: shop configuration file don't exists or is damaged", 1)
		outputChatBox("CRTICAL ERROR: shop configuration file don't exists or is damaged")
		outputChatBox("BŁĄD KRYTYCZNY! Nie znaleziono pliku z konfiguracją sklepu z bronią lub jest on uszkodzony.")
		return
	end

	for k, v in pairs(xmlNodeGetChildren(shopFile)) do -- wykona się 2 razy (2 teamy) (nod <teamX>)
		for k2, v2 in pairs(xmlNodeGetChildren(v)) do -- pętla na kategorie
			shop[k][k2] = {}

			shop[k][k2]["name"] = xmlNodeGetAttribute(v2, "name")
			--shop[k][k2]["slot"] = xmlNodeGetAttribute(v2, "slot") -- slot[team][kategoria][info kategorii/bron][parametr]

			for k3, v3 in pairs(xmlNodeGetChildren(v2)) do -- pętla na wszystkie bronie z kategorii
				shop[k][k2][k3] = {}
				for attribute, value in pairs(xmlNodeGetAttributes(v3)) do -- uzyskiwanie atrybutów broni
					if attribute == "csWeaponID" or attribute == "cost" then
						value = tonumber(value)
					end
					if attribute == "slot" then
						if not string.find(value, "S") then
							value = tonumber(value)
						end
					end
					shop[k][k2][k3][attribute] = value

					--[[if value ~= "-1" then -- debug
						--outputChatBox(tostring(attribute) .. " = " .. value)
						--outputChatBox("shop[" .. k .. "][" .. k2 .. "][" .. k3 .. "][" .. attribute .. "]")
						--outputChatBox("shop[" .. k .. "][" .. k2 .. "][" .. k3 .. "][" .. attribute .. "] = " .. value)
					end]]--
				end
				if not shop[k][k2][k3]["csWeaponID"] or not shop[k][k2][k3]["slot"] then
					--outputChatBox("shop[" .. k .. "][" .. k2 .. "][" .. k3 .. "][name] = " .. tostring(shop[k][k2][k3]["name"]) .. " ?")
					outputChatBox("CRITICAL ERROR: Weapon " .. tostring(k3) .. " (category " .. tostring(k2) .. ", team " .. tostring(k) .. ") has not setted csWeaponID or slot.")
				end
			end
		end
	end

	xmlUnloadFile(shopFile)
	outputDebugString("shop weapons configuration loaded")
end

function shop_loadCategories()
	-- kategoria z broniami, powrot, powrot - nie kasuje buttonow
	currentCategory = false
	shop_hideAllButtons()
	unbindKey("backspace", "down", shop_loadCategories)
	bindKey("backspace", "down", activateWindow_shop)
	
	currentWeapon = {}
	setBoxLabel(getText("shop"))
	
	local team = getTeamID(getPlayerTeam(localPlayer))
	
	local buttons = {}
	for i, v in pairs(shop[team]) do
		guiSetProperty(shopButton[i], "Text", i .. " " .. string.upper(getText("shop_cat_" .. v["name"])))
		guiSetVisible(shopButton[i], true)
		
		addEventHandler("onClientGUIClick", shopButton[i], shop_buttonChooseCategory)
		addEventHandler("onClientMouseEnter", shopButton[i], shop_buttonHover)
		table.insert(buttons, shopButton[i])
	end
	guiSetProperty(shopButton[8], "Text", "0 " .. string.upper(getText("cancel")))
	guiSetVisible(shopButton[8], true)
	table.insert(buttons, shopButton[8])
	addEventHandler("onClientGUIClick", shopButton[8], shop_buttonChooseCategory)
	addEventHandler("onClientMouseEnter", shopButton[8], shop_buttonHover)
	addElementsToCurrentBox(buttons)
end

function shop_buttonChooseCategory(button, state)
	if source == shopButton[8] then -- "anuluj"
		setBoxVisible(false) -- wyjście ze sklepu
		return false
	end
	
	if button == "left" and state == "up" then
		local team = getTeamID(getPlayerTeam(localPlayer))
		for i = 1, table.getn(shop[team]) do
			if source == shopButton[i] then
				shop_loadWeaponsFromCategory(i)
				break
			end
		end
		
		bindKey("backspace", "down", shop_loadCategories)
		unbindKey("backspace", "down", activateWindow_shop)
	end
end

function shop_buttonHover(button, state) -- najazd na przyciski wyboru kategori (oraz ANULUJ); działa też to na przycisk w wyborze broni - ''ANULUJ''
	--clickSound()
end

function shop_hideAllButtons() -- chowanie wszystkich 10 przycisków
	for i = 1, 10 do
		guiSetVisible(shopButton[i], false)
		removeEventHandler("onClientGUIClick", shopButton[i], shop_buttonChooseCategory)
		removeEventHandler("onClientMouseEnter", shopButton[i], shop_buttonHover)
		removeEventHandler("onClientGUIClick", shopButton[i], shop_buyWeapon)
		
		removeEventHandler("onClientMouseEnter", shopButton[i], shop_weaponButtonHover)
		removeEventHandler("onClientMouseLeave", shopButton[i], shop_weaponButtonLeave)
	end
	clearBoxElements()
end

function shop_weaponButtonHover() -- najazd na przycisk wyboru broni
	local name = string.sub(guiGetText(source), 3)
	local team = getTeamID(getPlayerTeam(localPlayer))

	currentWeapon = {}
	for k, v in pairs(shop[team][currentCategory]) do
		if name == v["name"] then
			currentWeapon.id = k

			--outputChatBox("Weapon: " .. v["csWeaponID"] .. " Slot: " .. v["slot"] .. " img: " .. g_weapon[v["slot"]][v["csWeaponID"]]["image"])
			currentWeapon.image = g_weapon[v["slot"]][v["csWeaponID"]]["image"]
			currentWeapon.cost = v["cost"]
			local text = ""
			local text2 = ""
			for i=1, 10 do
				local info = v["info" .. i]
				if info and info ~= "-1" then
					text = text .. shopInformation[i] .. "\n" -- lewa belka
					text2 = text2 .. info .. "\n" -- prawa belka
				end
			end
			currentWeapon.text = text
			currentWeapon.text2 = text2
			break			
		end
	end
	--clickSound()
end

-- odjazd z przycisku wyboru broni
function shop_weaponButtonLeave()
	--shop_currentWeapon = false -- odkomentować jak chce się aby informacja o danej broni wyświetlała się tylko w przy trzymaniu kursora na przycisku
end

function onShopClosed(window)
	if window == "shop" then
		currentWeapon = {}
		
		for i = 0, 9 do
			unbindKey(tostring(i), "down", shop_bindBuyWeapon, i)
		end
		unbindKey("backspace", "down", shop_loadCategories)
		unbindKey("backspace", "down", activateWindow_shop)
		showCursor(false)
	end
end

function activateWindow_shop() -- otworzenie / zamknięcie sklepu z bronią
	--if getElementData(localPlayer, "choosingLanguage") then return false end
	--outputChatBox("activateWindow_shop")
	setBoxVisible(true, "", "shop", "renderShop")
	shop_loadCategories()
	
	for i = 0, 9 do
		bindKey(tostring(i), "down", shop_bindBuyWeapon, i)
	end
	showCursor(true)
end

--

function shop_bindBuyWeapon(number) -- kupienie broni przez bind numerowy
	--outputChatBox(number)
	number = tonumber(number)
	if number == 0 then
		if getBoxLabel() ~= getText("shop") then -- jeśli gracz jest w wyborze broni
			number = 10 -- jeśli naciśniemy 0 to zadziałamy na przycisk o numerze 10
		else -- jeśli gracz jest w wyborze kategori
			number = 8
		end
	end
	
	if guiGetVisible(shopButton[number]) then -- jeśli widzimy ten button
		triggerEvent("onClientGUIClick", shopButton[number], "left", "up")
	end
end

function shop_buyWeapon(button, state) -- onClientGUIClick; wybranie broni i próba jej kupna
	if source == shopButton[10] then -- "anuluj"
		shop_loadCategories() -- powrót do listy kategori
		return false
	end
	
	if g_player.reloading then return end

	local name = string.sub(guiGetText(source), 3)
	local team = getTeamID(getPlayerTeam(localPlayer))
		
	setBoxVisible(false) -- chowanie okienka sklepu
	for k, v in pairs(shop[team][currentCategory]) do
		--outputChatBox("c shop_buyWeapon: " .. name .. " " .. v["name"] .. " ?")
		if name == v["name"] then
			buyWeapon(v["cost"], v["slot"], v["csWeaponID"])
			break
		end
	end
end

function buyWeapon(cost, slot, weapon)
	local gtaWepID
	if slot == "S1" then
		gtaWepID = tonumber(g_weapon["S1"][weapon]["weaponID"])
	else
		gtaWepID = tonumber(g_weapon[slot][weapon]["weaponID"])
	end

	if getPlayerMoneyEx(localPlayer) < cost and not g_config["everything_is_free"] then
		advert.error("msg_noMoney")
		playSound(":csrw-sounds/sounds/buttons/weapon_cant_buy.wav")
		return
	end

	if g_playerWeaponData[slot] then
		dropWeapon(true, slot)
	end

	local noserver = true
	if gtaWepID == -1 then -- kamizelka
		csSetPedArmor(localPlayer, 100)

	elseif gtaWepID == -2 then -- kamizelka + hełm
		csSetPedArmor(localPlayer, 100)
		g_player.items.helmet = true

	elseif gtaWepID == -3 or gtaWepID == -4 then -- termowizor lub noktowizor
		local g = 1
		if gtaWepID == -4 then g = 2 end
		g_player.items.goggles = g
		turnGogglesOff()

	elseif gtaWepID == -5 then
		-- defusing kit
		g_player.items.defuser = true

	else
		if gtaWepID == WEAPON_GRENADE or gtaWepID == WEAPON_TEARGAS or gtaWepID == WEAPON_MOLOTOV then
			local maxGrenades = 1
			if slot == 4 then
				maxGrenades = 2
			end

			local clip = 0
			if g_playerWeaponData[slot] then
				clip = g_playerWeaponData[slot].clip
			end

			if clip >= maxGrenades and not DEBUG_SKIP_GRENADE_LIMIT then
				advert.error("msg_tooMuchGrenades")
				playSound(":csrw-sounds/sounds/buttons/weapon_cant_buy.wav")
				return
			end
		end

		noserver = false
		triggerServerEvent("buyWeapon", localPlayer, cost, slot, weapon)
		
		if CFirstPerson.enabled then
			setControlState("aim_weapon", true)
		end
	end
	playSound(":csrw-sounds/sounds/buttons/weapon_confirm.wav")

	--outputChatBox("noserver " .. tostring(noserver))
	if noserver and not g_config["everything_is_free"] then
		takePlayerMoneyEx(localPlayer, cost)
	end
end

function shop_loadWeaponsFromCategory(category) -- ładowanie broni z danej kategori do 10 przycisków
	local team = getTeamID(getPlayerTeam(localPlayer))
	shop_hideAllButtons()
		
	setBoxLabel(getText("shop_cat_" .. shop[team][category]["name"]))

	local buttons = {}
	for k, v in pairs(shop[team][category]) do
		if v["name"] then
			guiSetProperty(shopButton[k], "Text", k .. " " .. v["name"])
			guiSetVisible(shopButton[k], true)
			setTimer(function()
					addEventHandler("onClientGUIClick", shopButton[k], shop_buyWeapon)
					addEventHandler("onClientMouseEnter", shopButton[k], shop_weaponButtonHover, false)
					addEventHandler("onClientMouseLeave", shopButton[k], shop_weaponButtonLeave, false)
				end, 50, 1)
			table.insert(buttons, shopButton[k])
		end
	end
	
	guiSetProperty(shopButton[10], "Text", "0 " .. string.upper(getText("cancel")))
	guiSetVisible(shopButton[10], true)
	table.insert(buttons, shopButton[10])
	addEventHandler("onClientGUIClick", shopButton[10], shop_buyWeapon)
	addEventHandler("onClientMouseEnter", shopButton[10], shop_buttonHover, false)
	addElementsToCurrentBox(buttons)
	currentCategory = category
end

local render = { -- 1680x1050 ?
	["img"] = {0.47976190476*sX, 0.27809523809*sY, 0.26011904761*sX, 0.12476190476*sY},
	["cost"] = {0.45297619047*sX, 0.4019047619*sY, 0.76547619047*sX, 0.4419047619*sY},
	["line"] = {0.44523809523*sX, 0.44952380952*sY, 0.77083333333*sX, 0.44952380952*sY},
	["txt"] = {0.45238095238*sX, 0.45809523809*sY, 0.60738095238*sX, 0.73904761904*sY},
	["txt2"] = {0.57559523809*sX, 0.45809523809*sY, 0.76547619047*sX, 0.73904761904*sY}
}

local free_str = getText("free")
function renderShop()
	if currentWeapon.id then
		dxDrawImage(render["img"][1], render["img"][2], render["img"][3], render["img"][4], ":csrw-media/images/shop/" .. currentWeapon.image, 0, 0, 0, tocolor(255, 255, 255, 255), false)
	
		local cost = "$" .. currentWeapon.cost
		if g_config["everything_is_free"] then
			cost = free_str
		end

		dxDrawText(cost, render["cost"][1], render["cost"][2], render["cost"][3], render["cost"][4], tocolor(252, 85, 2, 255), 1, "bankgothic", "center", "top", false, false, false, false, false)
	
		dxDrawLine(render["line"][1], render["line"][2], render["line"][3], render["line"][4], tocolor(255, 255, 255, 255), 1, false)
		
		dxDrawText(currentWeapon.text, render["txt"][1], render["txt"][2], render["txt"][3], render["txt"][4], tocolor(252, 85, 2, 255), 0.6, "bankgothic", "left", "top", false, true, false, false, false)
		dxDrawText(currentWeapon.text2, render["txt2"][1], render["txt2"][2], render["txt2"][3], render["txt2"][4], tocolor(252, 85, 2, 255), 0.6, "bankgothic", "right", "top", false, true, false, false, false)
	end
end
