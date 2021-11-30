-- Loader broni z pliku konfiguracyjnego (plik wspólny dla klienta i serwera)

g_weapon = {} -- g_weapon[csSlot][csID][parametr], np. g_weapon[1][2]["objectID"]

local weapons = 0

local file = xmlLoadFile("files/weapons.xml")
if file then
	for k, v in pairs(xmlNodeGetChildren(file)) do -- grupa broni w danym slocie
		local slot = xmlNodeGetAttribute(v, "id")
		if not string.find(slot, "S") then -- slot specjalny (string)
			slot = tonumber(slot) -- zwykły slot (liczba)
		end
		
		g_weapon[slot] = {} -- slot
		for weapon, v2 in pairs(xmlNodeGetChildren(v)) do
			g_weapon[slot][weapon] = {} -- broń o danym id (to nie jest parametr weaponID, który zawiera ID GTA!)
			weapons = weapons + 1

			for name, value in pairs(xmlNodeGetAttributes(v2)) do
				--if not localPlayer and (name == "shotSound" or name == "image") then break end -- nie zapisywanie tych atrybutów po stronie serwera
				if name == "flags" then
					--output("Weapon " .. slot .. "-" .. weapon .. " flags: " .. value)
					g_weapon[slot][weapon][name] = split(string.lower(value), ",") -- trzymanie flag w tabeli
				else
					g_weapon[slot][weapon][name] = value
				end
			end
		end
	end
	xmlUnloadFile(file)
else
	output("CRITICAL ERROR: I can't load weapon config!")
end

if #g_weapon < 1 then
	output("CRITICAL ERROR: Can't find any weapon. Please reinstall gamemode.")
end

if not localPlayer then
	--outputServerLog("Standard lot count: " .. tostring(#g_weapon)) -- nie są wliczane specjalne sloty (np. S1)
	--outputServerLog(tostring(g_weapon[1][1]["name"]))
	--outputServerLog("Weapon count: " .. weapons)
	g_weapon_slotCount = #g_weapon
end

--[[function getWeaponAttribute(slot, weapon, attribute)
	return g_weapon[tonumber(slot)][tonumber(weapon)][tostring(attribute)]
end]]--

function getWeaponsWithFlag(wantedFlag)
	local results = {}
	for k, v in ipairs(g_weapon) do
		for k2, v2 in ipairs(v) do
			if v2["flags"] then
				for _, flag in pairs( v2["flags"] ) do -- szukanie danej flagi we flagach broni
					if flag == string.lower(wantedFlag) then
						table.insert(results, {k, k2}) -- slot, id
					end
				end
			end
		end
	end

	if #results == 0 then
		return nil
	end
	return results
end

function hasWeaponFlag(slot, weapon, wantedFlag)
	for k, v in pairs( g_weapon[slot][weapon]["flags"] ) do
		if v == string.lower(wantedFlag) then
			return true
		end
	end
	return false
end
