-- globalne definicje broni o danych flagach
DEF_BOMB = getWeaponsWithFlag("BOMB")
if #DEF_BOMB > 0 then
	DEF_BOMB = { DEF_BOMB[1][1], DEF_BOMB[1][2] }
else
	DEF_BOMB = { -1, -1 }
	outputServerLog("Warning: Can find weapon flagged as BOMB.")
end

DEF_KNIFE = getWeaponsWithFlag("KNIFE")
if #DEF_KNIFE > 0 then
	DEF_KNIFE = { DEF_KNIFE[1][1], DEF_KNIFE[1][2] } -- slot, csweaponid
else
	DEF_KNIFE = { -1, -1 }
	outputServerLog("Warning: Can find weapon with KNIFE flag.")
end
--outputServerLog( "DEF_BOMB: " .. getWeaponsWithFlag("BOMB")[1][1] .. ", " .. getWeaponsWithFlag("BOMB")[1][2] )
--

playerAttachments = {}
for i=1, #g_weapon do
	playerAttachments[i] = {}
end
playerAttachments["goggle"] = {}

g_playerWeaponData = {} -- informacja o broniach gracza na danym slocie
-- g_playerWeaponData[player][slot] = {weapon, ammo, clip}

function server_changeWeaponToSlot(oldSlot, slot, oldAmmo, oldClip, deleteWeapon)
	if client and source == client then
		--[[if not oldAmmo and not oldClip then
			csTakeWeapon(client, oldSlot, nil, true)
		--]]
		--outputChatBox("server_changeWeaponToSlot(oldSlot = " .. tostring(oldSlot) .. ", slot = " .. tostring(slot) .. ", ...)")
		changePlayerSlot(client, oldSlot, slot, oldAmmo, oldClip)
	end
end
addEvent("server_changeWeaponToSlot", true)
addEventHandler("server_changeWeaponToSlot", root, server_changeWeaponToSlot)

addEvent("csTakeCurrentWeaponTrigger", true)
addEventHandler("csTakeCurrentWeaponTrigger", root,
	function()
		if client and source == client then
			local slot = getElementData(client, "currentSlot")
			csTakeWeapon(client, slot, g_playerWeaponData[client][slot].weapon, true)
			-- csTakeWeapon(player, slot, weapon, dontSendDataToClient)
		end
	end
)

addEventHandler("onElementDataChange", root,
	function(data, oldValue)
		if data == "currentSlot" then
			-- odczepianie / podczepianie broni w zmianie slotu clientside
			local newSlot = getElementData(source, data)
			if not newSlot then return end
			
			detachWeaponFromBody(source, newSlot) -- odczepianie nowej broni z ciała

			local newWeapon = tonumber(g_weapon[newSlot][ g_playerWeaponData[source][newSlot].weapon ]["weaponID"])
			if g_player[source].sneaking and newWeapon > 0 and getSlotFromWeapon(newWeapon) == 1 then
				-- broń biała
				toggleControl(source, "sprint", false)
			end

			if newSlot == DEF_BOMB[1] and newWeapon == DEF_BOMB[2] then
				-- nowa broń to C4
				playAnimationWithWalking("CARRY", "crry_prtial", source)
				-- podczepianie bomby do rąk
				attachWeaponToBody(source, DEF_BOMB[2], newSlot, "hands")
			
			elseif oldValue then
				-- doczepianie starej broni do ciała -- wywala błąd przy zmianie slotu przy skradaniu się
				attachWeaponToBody(source, g_playerWeaponData[source][oldValue].weapon, oldValue, "body")
				if oldValue == DEF_BOMB[1] and g_playerWeaponData[source][oldValue].weapon == DEF_BOMB[2] then
					-- stara broń to bomba
					stopAnimationWithWalking(source)				
				end
			end

		elseif data == "health" and getElementData(source, "alive") and getElementData(source, data) <= 0 then
			setElementHealth(source, 0)
		end
	end
)
--

function changePlayerSlot(player, oldSlot, newSlot, oldAmmo, oldClip)
	if oldAmmo and oldClip then
		g_playerWeaponData[player][oldSlot].ammo = oldAmmo
		g_playerWeaponData[player][oldSlot].clip = oldClip
	--else
		--outputConsole("ERROR: Problem with saving weapon ammo on slot " .. tostring(oldSlot) .. " (ammo: " .. tostring(oldAmmo) .. ", clip: " .. tostring(oldClip) .. ")", player)
	end

	if g_playerWeaponData[player][newSlot] then
		csGiveWeapon(player, newSlot, g_playerWeaponData[player][newSlot].weapon)
	else
		outputChatBox("ERROR: Problem with getting weapon data from slot " .. tostring(newSlot), player)
	end
end

function attachWeaponToBody(player, weapon, slot, bombType)
	--outputChatBox("attachWeaponToBody(" .. getPlayerName(player) .. ", weapon = " .. tostring(weapon) .. ", slot = " .. tostring(slot) .. ", bombType = " .. tostring(bombType) .. ")", player)
	if not slot then
		slot = getElementData(player, "currentSlot")
		if not slot then return end
	end

	if slot ~= "goggle" and not weapon then
		weapon = g_playerWeaponData[player][slot].weapon
		if not weapon then return end
	end
	
	if slot ~= 1 and slot ~= 8 and slot ~= "goggle" then return end
	--[[if g_playerWeaponData[player][slot].ammo == 0 and g_playerWeaponData[player][slot].ammo ~= nil then
		outputConsole("DEBUG: KONIEC AMMO W attachWeaponToBody - nie doczepianie broni do ciala", player)
		return
	end]]-- -- broń się kończy (0 ammo) więc nie doczepiamy jej do ciała

	detachWeaponFromBody(player, slot)
	
	local objectID
	if slot == "goggle" then
		-- @todo
		--local wep = getElementData(player, "wSlotE1") -- 24, 25 (weapons.xml) ; wSlotE1 - extra slot (gogle termowizyjne / nocnowizyjne)
		--playerAttachments[slot][player] = createObject(368, 0, 0, 0)
		objectID = 368
	else
		objectID = g_weapon[slot][weapon]["objectID"]
		if not objectID then
			-- jeśli coś jest nie tak z objectID używanie modelu AK-47
			objectID = 355
			outputChatBox("ERROR: There is a problem with attaching weapon (slot " .. slot .. ", weapon " .. weapon .. ") to body - objectID parameter is invalid, using AK-47 model.", player)
		end
	end

	if objectID then
		playerAttachments[slot][player] = createObject(objectID, 0, 0, 0)
		setObjectScale(playerAttachments[slot][player], 0.9)
		
		local bone, x, y, z, rx, ry, rz
		if slot == "goggle" then
			bone, x, y, z, rx, ry, z = 1, 0, 0.12, 0.165, 0, 90, 0
		elseif slot == 1 then
			bone, x, y, z, rx, ry, z = 3, 0, -0.14, 0.4, 0, 90, 0
		elseif slot == DEF_BOMB[1] and weapon == DEF_BOMB[2] then -- flaga c4
			if bombType == "hands" then -- ręce
				bone, x, y, z, rx, ry, z = 11, -0.1, 0.08, 0.15, 200, 70, 0
			else -- plecy
				bone, x, y, z, rx, ry, z = 3, -0.1, -0.13, 0.16, 0, 0, 0
			end
		end
		exports["bone_attach"]:attachElementToBone(playerAttachments[slot][player], player, bone, x, y, z, rx, ry, rz)
		setElementData(playerAttachments[slot][player], "attachedPlayer", player) -- do pobierania obiektow do ukrycia przy celowaniu snajperką
		setElementInterior(playerAttachments[slot][player], getElementInterior(player))
		return true
	end
	return false
	
	-- c4 na lewej nodze: crun exports["bone_attach"]:attachElementToBone(obj, localPlayer, 13, -0.13, -0.08, 0.2, 180, 0, 90)
	-- c4 na plecach: crun exports["bone_attach"]:attachElementToBone(obj, localPlayer, 3, -0.1, -0.13, 0.16, 0, 0, 0)
end
addEvent("attachWeaponToBody", true)
addEventHandler("attachWeaponToBody", root, attachWeaponToBody, player, slot, bombType)

function detachWeaponFromBody(player, slot)
	if isElement(playerAttachments[slot][player]) then
		destroyElement(playerAttachments[slot][player])
	end
end
addEvent("detachWeaponFromBody", true)
addEventHandler("detachWeaponFromBody", root, detachWeaponFromBody)

function unloadBombFromHands(player)
	if getElementData(player, "currentSlot") == DEF_BOMB[1] then
		if isElement(playerAttachments[ DEF_BOMB[1] ][player]) then
			destroyElement(playerAttachments[DEF_BOMB[1]][player])
		end
		stopAnimationWithWalking(player)
		toggleControl(player, "jump", true)
		toggleControl(player, "crouch", true)

		if getElementData( player, "wSlot" .. DEF_BOMB[1] ) ~= false then
			attachWeaponToBody(player, DEF_BOMB[2], DEF_BOMB[1], "body") -- podczepianie C4 do pleców
		end		
	end
end

function csGiveWeapon(player, csSlot, csWeaponID, ammo, ammoInClip, hideHer)
	if not player or not csSlot or not csWeaponID then return false end
	
	local csWeaponID = tonumber(csWeaponID)
	--outputChatBox("DEBUG: csGiveWeapon( " .. getPlayerName(player) .. ", csSlot=" .. tostring(csSlot) .. ", csWeaponID=" .. tostring(csWeaponID) .. ", ... )")
	local gtaWeaponID = tonumber(g_weapon[csSlot][csWeaponID]["weaponID"])

	if not g_playerWeaponData[player][csSlot] then
		g_playerWeaponData[player][csSlot] = {}
	end
	g_playerWeaponData[player][csSlot].weapon = csWeaponID

	if csSlot == DEF_BOMB[1] and csWeaponID == DEF_BOMB[2] then -- nowa broń to c4
		if not hideHer then
			setElementData(player, "currentSlot", csSlot)
			--setElementData(player, "currentWeapon", csWeaponID)
			playAnimationWithWalking("CARRY", "crry_prtial", player)	
			attachWeaponToBody(player, csWeaponID, csSlot, "hands")

			toggleControl(player, "fire", false)
			toggleControl(player, "jump", false)
			toggleControl(player, "crouch", false)
			setPedWeaponSlot(player, 0)
		else
			stopAnimationWithWalking(player)
			attachWeaponToBody(player, csWeaponID, csSlot, "body")
		end
	
	else
		attachWeaponToBody(player)
		--outputChatBox("[S DEBUG SLOTCHANGE] currentSlot: " .. tostring(getElementData(player, "currentSlot")) .. " new: " .. csSlot)
		--unloadBomb(player) -- usuwa starą broń z "kieszeni" postaci (tylko c4)
		unloadBombFromHands(player)

		if gtaWeaponID == 16 or gtaWeaponID == 17 or gtaWeaponID == 18 then -- granaty (grenade, smoke (+ flash, decoy), molotov)
			--if not ammo then ammo = 1 end
			if not ammoInClip then
				ammoInClip = ammo or 1 -- gracz wszystkie granaty trzyma w 'magazynku'
			end

			if ammo then ammo = 0 end
			if not hideHer then
				setElementData(player, "currentSlot", csSlot) -- ustawienie info o obecnym slocie
				--setElementData(player, "currentWeapon", csWeaponID)
				giveWeapon(player, gtaWeaponID, 1, true)
				setWeaponAmmo(player, gtaWeaponID, 51711, 51711)
				toggleControl(player, "fire", true)
				-- ^ gta ma tak zjebany system, że jak nie ma się obecnie tej broni to nie dodaje amunicji tylko podmienia
			end
		else
			detachWeaponFromBody(player, csSlot) -- ściąganie nowej broni z pleców

			-- \/ dodawanie nowej broni
			-- zmiana skilla broni
			local skillName = getWeaponSkillID(gtaWeaponID)
			if skillName then
				local skill = g_weapon[csSlot][csWeaponID]["skill"]
				if skill then
					setPedStat(player, skillName, getWeaponSkillAmount(skill))
				end
			end
			-- 
			
			if not ammo then
				ammo = g_playerWeaponData[player][csSlot].ammo or tonumber(g_weapon[csSlot][csWeaponID]["ammo"])
			end
			
			if not ammoInClip then
				ammoInClip = g_playerWeaponData[player][csSlot].clip or tonumber(g_weapon[csSlot][csWeaponID]["clip"])
			end
			--if ammoInClip > ammo then ammoInClip = ammo end

			if not hideHer then -- jeśli nowa broń nie ma być odrazu chowana do ekwipunku
				setElementData(player, "currentSlot", csSlot)
				--setElementData(player, "currentWeapon", csWeaponID)
				giveWeapon(player, gtaWeaponID, 1, true)
				--setWeaponAmmo(player, gtaWeaponID, ammo, ammoInClip) -- zmiana ilości amunicji (w giveWeapon nie można podać ilości ammo w magazynku)
				setWeaponAmmo(player, gtaWeaponID, 51711, 51711)
				--outputChatBox("Physicall weapon ammo change (new weapon GTAID " .. gtaWeaponID .. ", ammo " .. ammo .. ", clip " .. ammoInClip .. ")", player)
			
				if getSlotFromWeapon(gtaWeaponID) == 1 then
					if not g_player.sneaking then
						toggleControl(player, "sprint", true) -- bieganie z bronią białą
					end
					toggleControl(player, "fire", true)
				else
					toggleControl(player, "sprint", false)
					if getControlState(player, "aim_weapon") == false and getSlotFromWeapon(gtaWeaponID) ~= 8 then -- jeśli nie celuje i nie ma granata
						toggleControl(player, "fire", false)
					end
				end
			end
		end
	end
	g_playerWeaponData[player][csSlot].ammo = ammo
	g_playerWeaponData[player][csSlot].clip = ammoInClip
	setElementData(player, "wSlot" .. csSlot, csWeaponID) -- potrzebne do synchronizowania: obrażeń, spectatora, wyrzucania broni, rzucania customowymi granatami (flash, smoke, decoy etc.) etc.
	triggerClientEvent(player, "updateWeaponData", resourceRoot, csSlot, csWeaponID, ammo, ammoInClip, hideHer)
end
addEvent("csGiveWeapon", true)
addEventHandler("csGiveWeapon", root, csGiveWeapon, player, csweaponID, ammo, ammoInClip)

function unloadSlotWeapon(player, slot) -- uwaga! funkcja nie przerzuca na niższy slot, dlatego po niej należy dać funkcję zmiany slota bądź nadać nową broń!
	-- nie stosować przed nadaniem nowej broni (gta)
	if not player then
		return
	end

	if not slot then
		slot = getElementData(player, "currentSlot")
	end

	if not slot then
		return
	end
	
	local weapon = g_playerWeaponData[player][slot].weapon
	if not weapon then
		return
	end

	attachWeaponToBody(player, weapon, slot)
	local gtaWeaponID = tonumber(g_weapon[slot][weapon]["weaponID"])
	if gtaWeaponID then
		return
	end

	if gtaWeaponID > 0 then
		takeWeapon(player, gtaWeaponID)
	elseif slot == DEF_BOMB[1] and weapon == DEF_BOMB[2] then -- chowanie c4
		stopAnimationWithWalking(player)
		toggleControl(player, "jump", true)
		toggleControl(player, "crouch", true)
	end
	
	--[[
		@TODO - temp broni
		Zamiast kasowania broni można by wtedy zmienić slot na pięść.
	]]
end

function setPedArmorEx(ped, armor)
	return setElementData(ped, "armor", armor)
end

function getPedArmorEx(ped)
	local armor = tonumber(getElementData(ped, "armor"))
	if armor == nil then armor = 0 end
	return armor
end

-- Called from client/shop.lua
function buyWeapon(weaponCost, csSlot, csWeaponID)
	if getPlayerMoneyEx(client) < weaponCost and not g_config["everything_is_free"] then
		advert.error("msg_noMoney", client)
		triggerClientEvent("cPlaySound", client, "files/sounds/buttons/weapon_cant_buy.wav")
		return
	end

	local gtaWeaponID = tonumber(g_weapon[csSlot][csWeaponID]["weaponID"])
	if gtaWeaponID == WEAPON_GRENADE or gtaWeaponID == WEAPON_TEARGAS or gtaWeaponID == WEAPON_MOLOTOV then
		local maxGrenades = 1
		if csSlot == 4 then
			maxGrenades = 2
		end

		local clip = 0
		if g_playerWeaponData[client][csSlot] then
			clip = g_playerWeaponData[client][csSlot].clip or 0
		end

		takePlayerMoneyEx(client, weaponCost)
		csGiveWeapon(client, csSlot, csWeaponID, clip + 1)
		--outputChatBox("SERWER: Granat kupiony za $" .. weaponCost .. ". csWeaponID = " .. csWeaponID, client)
	else
		--local ammo = tonumber(g_weapon[csSlot][csWeaponID]["ammo"]) + tonumber(g_weapon[csSlot][csWeaponID]["clip"])
		local ammo = tonumber(g_weapon[csSlot][csWeaponID]["ammo"])
		
		--detachWeaponFromBody(client, csSlot)
		takePlayerMoneyEx(client, weaponCost)
		--outputChatBox("buyWeapon " .. csSlot .. " " .. csWeaponID .. " " .. tostring(ammo))
		csGiveWeapon(client, csSlot, csWeaponID, ammo)
		--outputChatBox("SERWER: Broń " .. weaponName .. "(" .. csWeaponID .. ") z " .. ammo .. " nabojami kupiona za $" .. weaponCost, client)
	end
end
addEvent("buyWeapon", true)
addEventHandler("buyWeapon", root, buyWeapon, weaponCost, csSlot, csWeaponID)

function csKillPed(ped, attacker, weapon, bodypart)
	-- bodypart = gta body part ; weapon = gta weapon (w przyszłości zamienić na cs weapon - własna lista zabójstw)
	
	killPed(ped, attacker, weapon, bodypart)
	setElementData(ped, "alive", false)
	setElementData(ped, "health", 0)

	setElementCollisionsEnabled(ped, false)
	if bodypart == 9 and g_config["gore"] then
		setPedHeadless(ped, true)
	end
end
addEvent("csKillPed", true)
addEventHandler("csKillPed", root, csKillPed)

function csResetWeapons(player, quit)
	for i=1, #g_weapon do
		if not quit then
			setElementData(player, "wSlot" .. i, false)
		end
		detachWeaponFromBody(player, i)
	end
	g_playerWeaponData[player] = {}
	detachWeaponFromBody(player, "goggle")

	if not quit then
		setElementData(player, "currentSlot", false)
		triggerClientEvent(player, "updateWeaponData", resourceRoot, "clearAll")
	end
end

addEventHandler("onPlayerStealthKill", root, function() cancelEvent(true) end)

function csTakeWeapon(player, slot, weapon, dontSendDataToClient)
	--outputChatBox("csTakeWeapon slot " .. tostring(slot))
	if not slot then
		slot = getElementData(player, "currentSlot")
	end

	if not g_playerWeaponData[player][slot] then
		return
	end

	if not weapon then
		weapon = g_playerWeaponData[player].weapon
	end

	detachWeaponFromBody(player, slot)
	if slot == DEF_BOMB[1] and weapon == DEF_BOMB[2] then stopAnimationWithWalking(player) end
	if not dontSendDataToClient then
		triggerClientEvent(player, "updateWeaponData", resourceRoot, slot)
	end
	g_playerWeaponData[player][slot] = {}
	setElementData(player, "wSlot" .. slot, false)
end

--[[
addEvent("switchWeaponAimMovingSkill", true)
addEventHandler("switchWeaponAimMovingSkill", root,
	function(switch)
		local skillName = getWeaponSkillID(getPedWeapon(client))
		if not skillName then return end

		if switch then
			setPedStat(client, skillName, 1)
		else
			local slot = getElementData(client, "currentSlot")
			if not slot then return end

			local weapon = g_playerWeaponData[client][slot].weapon
			local validSkill = g_weapon[slot][weapon]["skill"]
			if not validSkill then return end

			setPedStat(client, skillName, getWeaponSkillAmount( validSkill ))
		end
	end
)
]]--
