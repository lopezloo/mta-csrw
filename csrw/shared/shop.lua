-- Weapon shop - shared part

function loadShopWeapons()
	-- wczytywanie kategori broni teamów i broni przypisanych do nich
	local shopFile = xmlLoadFile("files/shop.xml")
	if not shopFile then
		output("CRTICAL ERROR: Unable to load shop configuration file!")
		return
	end

	local shop = { {}, {} } -- for two teams

	-- loop team nodes
	for k, v in pairs(xmlNodeGetChildren(shopFile)) do -- wykona się 2 razy (2 teamy) (nod <teamX>)
		-- loop shop category nodes
		for k2, v2 in pairs(xmlNodeGetChildren(v)) do
			shop[k][k2] = {}

			-- category name
			shop[k][k2]["name"] = xmlNodeGetAttribute(v2, "name")
			--shop[k][k2]["slot"] = xmlNodeGetAttribute(v2, "slot") -- slot[team][kategoria][info kategorii/bron][parametr]

			-- loop category item nodes (weapons)
			for k3, v3 in pairs(xmlNodeGetChildren(v2)) do
				shop[k][k2][k3] = {}

				-- loop item parameters
				for _, itemNode in pairs(xmlNodeGetChildren(v3)) do
					local name = itemNode.name

					if name == "csWeaponID" or name == "cost" then
						local value = tonumber(itemNode.value)
						shop[k][k2][k3][name] = value

					elseif name == "slot" then
						local value = itemNode.value
						if not string.find(value, "S") then
							value = tonumber(value)
						end
						shop[k][k2][k3][name] = value
					
					elseif name == "information" then
						shop[k][k2][k3]["information"] = {}
						for _, infoNode in pairs(xmlNodeGetChildren(itemNode)) do
							shop[k][k2][k3]["information"][infoNode.name] = infoNode.value
						end
					
					else
						shop[k][k2][k3][name] = itemNode.value
					end
				end
				
				if not shop[k][k2][k3]["csWeaponID"] or not shop[k][k2][k3]["slot"] then
					--output("shop[" .. k .. "][" .. k2 .. "][" .. k3 .. "][name] = " .. tostring(shop[k][k2][k3]["name"]) .. " ?")
					output("CRITICAL ERROR: Weapon " .. tostring(k3) .. " (category " .. tostring(k2) .. ", team " .. tostring(k) .. ") has not setted csWeaponID or slot.")
				end
			end
		end
	end

	xmlUnloadFile(shopFile)
	return shop
end
