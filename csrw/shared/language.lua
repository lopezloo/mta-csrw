--[[
	System języków bazujący na lokalizacji gracza (z 1.4).
]]
g_lang = {} -- serwer: g_lang[lang][text] = var | klient: g_lang[text] = var

local standardLang = "en"

local function getAvailableLanguages()
	local langFile = xmlLoadFile("files/lang.xml")
	local availableLangs = xmlNodeGetAttribute(langFile, "available")
	xmlUnloadFile(langFile)

	return split(availableLangs, ",")
end

local function isLanguageAvailable(lang)
	local availableLangs = getAvailableLanguages()
	for k, v in pairs(availableLangs) do
		if lang == v then
			return true
		end
	end
	return false
end

local lang
if localPlayer then
	function getLocalLanguage()
		local lang = getLocalization().code
		if string.find(lang, "en_") or not isLanguageAvailable(lang) then
			lang = standardLang
		end
		return lang
	end
	lang = getLocalLanguage()
end

local function loadLanguage()
	local langFile = xmlLoadFile("files/lang.xml")
	if not langFile then
		if not localPlayer then
			outputServerLog("CRITICAL ERROR: Can't find language file, please reinstall gamemode.")
		else
			outputChatBox("CRITICAL ERROR: Can't find language file.")
		end
	else
		for k, v in pairs(xmlNodeGetChildren(langFile)) do
			local txtName = xmlNodeGetName(v)

			for k2, v2 in pairs(xmlNodeGetChildren(v)) do

				if localPlayer then

					if xmlNodeGetName(v2) == lang then
						-- trzymanie tylko jednego języka po stronie klienta
						g_lang[txtName] = xmlNodeGetValue(v2)
						break
					end

				else

					local lang = xmlNodeGetName(v2)
					if not g_lang[lang] then
						g_lang[lang] = {}
					end
					g_lang[lang][txtName] = xmlNodeGetValue(v2)
					--outputServerLog("g_lang[" .. lang .. "][" .. txtName .. "] = " .. tostring(g_lang[lang][txtName]))

				end

			end
		end
		xmlUnloadFile(langFile)
	end
end
loadLanguage()

function getText(txt, player)
	if player and not localPlayer then
		--outputServerLog("getText " .. txt .. ", " .. tostring(player) .. " loc " .. tostring(g_player[player].localization))
		if g_lang[ g_player[player].localization ] then
			return g_lang[ g_player[player].localization ][txt] or g_lang[standardLang][txt] or "err"
		else
			return "err"
		end
	elseif localPlayer then
		if g_lang then
			return g_lang[txt] or "err"
		else
			return "err"
		end
	end
end

function outputText(txt, r, g, b, to)
	if to == root or to == nil or getElementType(to) == "team" then
		if to == root or to == nil then
			to = getElementsByType("player")
		elseif getElementType(to) == "team" then
			to = getPlayersFromTeam(to)
		end

		for k, v in pairs(to) do
			outputChatBox(getText(txt, v), v, r, g, b)
		end
	elseif getElementType(to) == "player" then
		outputChatBox(getText(txt, to), to, r, g, b)
	end
end