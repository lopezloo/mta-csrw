local configFile = xmlLoadFile("files/config.xml")
g_config = {}

local default
if not localPlayer then
	-- tylko po stronie serwera
	default = {
		{"matchrounds", 30},
		{"startmoney", 800},
		{"maxmoney", 10000},
		{"everything_is_free", false},
		{"friendlyfire", false},
		{"friendlycollisions", true}, -- nie dziala
		{"freedefusingkit", false}, -- nie dziala
		{"freekevlar", false},
		{"nobomb", false},
		{"nohostage", false},
		{"weapon_drop", true},
		{"autobalance", false},
		{"gore", false},
		{"locales", "en,pl"},
		{"default_locale", "en"},
	}
end

if not configFile then -- nie ma configu, tworzenie nowego z domyślnymi ustawieniami
	if default then
		-- strona serwera
		configFile = xmlCreateFile("files/config.xml", "config")

		if not configFile then
			outputServerLog("ERROR: I can't create config.xml")
			return
		end

		for k, v in pairs(default) do
			local n = xmlCreateChild(configFile, v[1])
			xmlNodeSetValue(n, tostring(v[2]))
			g_config[v[1]] = v[2]
		end
		xmlSaveFile(configFile)
	else
		-- strona klienta
		outputChatBox("CRITICAL ERROR: There is problem with config file.")
	end
else
	for k, v in pairs(xmlNodeGetChildren(configFile)) do
		local value = xmlNodeGetValue(v)
		if value == "true" then value = true
		elseif value == "false" then value = false
		elseif type(tonumber(value)) == "number" then
			value = tonumber(value)
			if xmlNodeGetName(v) == "matchrounds" and value < 5 then
				value = 5
				outputServerLog("WARNING: matchrounds config option was too low and was automatically changed to " .. value)
			elseif xmlNodeGetName(v) == "maxmoney" and value < 5000 then
				value = 5000
				outputServerLog("WARNING: maxmoney config option was too low and was automatically changed to " .. value)
			end
		end

		g_config[xmlNodeGetName(v)] = value
	end
end