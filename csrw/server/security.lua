local protectedDatas = {
	ped = {"money", "health", "armor", "anim", "defusingBomb", "wSlot", "currentSlot", "score", "deaths"}
}

--[[
	* jeśli inny zasób zmieni chronioną date elementu (player/ped) to przywraca starą wartość + wyrzuca komunikat + próbuje wyłączyć owy zasób
	* jeśli inny zasób zmieni jakąkolwiek date csrw --||--
	* jeśli jakiś gracz zmieni chronioną datę innego elementu (z wyjątkiem peda - ustalanie hp przy obrażeniach) to przywraca starą wartość + wyrzuca komunikat
	* jeśli gracz zmieni sobie datę broni (wSlot) na broń, której nie ma zapisanej w zmiennych po stronie serwera to --||--
	* jeśli gracz zmieni sobie currentSlot na slot w którym nie ma broni to --||--
--]]

addEventHandler("onElementDataChange", root,
	function(dataName, oldValue)

		--[[local resName = "nil"
		if sourceResource then
			resName = getResourceName(sourceResource)
		end
		outputServerLog("[DEBUG] onElementDataChange(data='" .. tostring(dataName) .. "', oldVal='" .. tostring(oldValue) .. "') client='" .. tostring(client) .. "' src='" .. tostring(source) .. "' resource='" .. resName .. "'")]]--

		if sourceResource and sourceResource ~= getThisResource() then
			if source == getThisResource() then
				outputServerLog("WARNING: Resource " .. getResourceName(sourceResource) .. " tried to change CSRW data.")
				if hasObjectPermissionTo(getThisResource(), "function.stopResource") then
					outputServerLog("Turning off resource " .. getResourceName(sourceResource) .. " due to trying hack.")
					stopResource(sourceResource)
				end
				setElementData(source, dataName, oldValue)

			elseif getElementType(source) == "player" or getElementType(source) == "ped" then -- jeśli inny zasób zmienia date gracza/peda
				for k, v in pairs(protectedDatas.ped) do
					if dataName == v then
						setElementData(source, dataName, oldValue) -- przywracanie starej daty

						local trusted
						for k, v in pairs(g_resources.toStart) do
							local resource = getResourceFromName(v)
							if resource == sourceResource then
								trusted = true
								break
							end
						end
						outputServerLog("WARNING: Resource " .. getResourceName(sourceResource) .. " (trusted: " .. tostring(trusted) .. ") tried to change CSRW protected element data (" .. dataName .. ") on " .. getElementType(source) .. ".")

						if not trusted and hasObjectPermissionTo(getThisResource(), "function.stopResource") then
							outputServerLog("Turning off resource " .. getResourceName(sourceResource) .. " due trying to hack.")
							stopResource(sourceResource)
						end
						break
					end
				end
			end

		elseif client then -- jeśli data została zmieniona przez jakiegoś klienta
			if source == getThisResource() then -- jeśli klient zmienia date skryptowi
				outputServerLog("DEBUG WARNING: Player " .. getPlayerName(client) .. " tried to change CSRW data (" .. dataName .. ").")
				setElementData(source, dataName, oldValue)

			elseif client ~= source and getElementType(source) == "player" then -- jeśli zmienia date innemu graczowi
				for k, v in pairs(protectedDatas.ped) do
					if v == dataName then
						outputServerLog("WARNING: Player " .. getPlayerName(client) .. " tried to change CSRW other element protected data (data " .. dataName .. ") on " .. getElementType(source) .. ".")
						setElementData(source, dataName, oldValue)
						break
					end
				end

			elseif client == source then -- jeśli zmienia date sobie
				if (dataName == "health" or dataName == "money") and oldValue and tonumber(oldValue) < tonumber(getElementData(source, dataName)) then
					-- jeśli zmienia HP, pancerz lub kase i wartość ta jest większa od starej
					outputServerLog("WARNING: Player " .. getPlayerName(source) .. " tried to change his " .. dataName .. " data.")
					setElementData(source, dataName, oldValue)

				if (dataName == "score" or dataName == "deaths") and oldValue and tonumber(getElementData(source, dataName)) < tonumber(oldValue) then
					-- jeśli zmienia ilość zabójstw / zgonów i ta wartosć jest mniejsza od starej
					outputServerLog("WARNING: Player " .. getPlayerName(source) .. " tried to change his " .. dataName .. " data.")
					setElementData(source, dataName, oldValue)
				end

				elseif string.find(dataName, "wSlot") then
					local slot = tonumber(string.sub(dataName, 5))
					if g_playerWeaponData[source][slot].weapon ~= getElementData(source, dataName) then
						-- wartość w dacie nie zgadza się ze zmienną po stronie serwera
						outputServerLog("WARNING: Player " .. getPlayerName(source) .. " tried to change his weapon slot data.")
						setElementData(source, dataName, oldValue)
					end

				elseif dataName == "currentSlot" then
					local slot = getElementData(source, dataName)
					local correct = false
					for k, v in pairs(g_playerWeaponData[source]) do
						--outputServerLog("DEBUG cSlot test: slot: " .. k .. " weapon: " .. tostring(v.weapon))
						if slot == k then
							correct = true
							break
						end
					end
					if not correct then
						outputServerLog("WARNING: Player " .. getPlayerName(source) .. " tried to change his weapon cSlot data.")
						setElementData(source, dataName, oldValue)
					end
				end
			end
		end
	end
)
