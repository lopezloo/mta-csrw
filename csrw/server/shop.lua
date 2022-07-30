-- Weapon shop - server part

local shop = loadShopWeapons()
local DEBUG_SKIP_GRENADE_LIMIT = DEBUG_MODE and true

-- Called from client/shop.lua
function buyWeapon(weaponCategory, weaponPos)
	if not client or client ~= source then
		return
	end

	if not g_match.settings.weaponShop then
		outputChatBox("shop disabledddd")
		return
	end

	if client.health == 0 then
		-- Player is dead
		return
	end

	local tid = getTeamID(client.team)
	if tid == nil then
		return
	end

	if not shop[tid] or not shop[tid][weaponCategory] or not shop[tid][weaponPos] then
		-- Invalid shop item
		return
	end

	local shopWeapon = shop[tid][weaponCategory][weaponPos]
	if shopWeapon["cost"] == nil or shopWeapon["slot"] == nil or shopWeapon["csWeaponID"] == nil then
		-- This shop item doesn't have required info set
		return
	end

	local weaponCost = shopWeapon["cost"]
	local csSlot = shopWeapon["slot"]
	local csWeaponID = shopWeapon["csWeaponID"]

	if not g_weapon[csSlot] or not g_weapon[csSlot][csWeaponID] then
		-- Invalid weapon
		return
	end

	if getPlayerMoneyEx(client) < weaponCost and not g_match.settings.everythingIsFree then
		advert.error("msg_noMoney", client)
		triggerClientEvent("cPlaySound", client, "files/sounds/buttons/weapon_cant_buy.wav")
		return
	end

	local gtaWeaponID = tonumber(g_weapon[csSlot][csWeaponID]["weaponID"])
	if isWeaponProjectile(gtaWeaponID) then
		local maxGrenades = 1
		if csSlot == 4 then
			maxGrenades = 2
		end

		local clip = 0
		if g_playerWeaponData[client][csSlot] then
			clip = g_playerWeaponData[client][csSlot].clip or 0
		end

		if clip >= maxGrenades and not DEBUG_SKIP_GRENADE_LIMIT then
			return
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
addEventHandler("buyWeapon", root, buyWeapon)
