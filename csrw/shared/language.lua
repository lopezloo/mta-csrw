-- Locale system

-- serwer: g_lang[lang][text] = var | klient: g_lang[text] = var
g_lang = {}

local defaultLocale = g_config["default_locale"]

local function getAvailableLanguages()
	local langFile = xmlLoadFile("files/lang.xml")
	local availableLangs = xmlNodeGetAttribute(langFile, "available")
	xmlUnloadFile(langFile)
	return split(availableLangs, ",")
end

local function getLocales()
	return split(g_config["locales"], ",")
end

local function isLocaleAvailable(locale)
	local locales = getLocales()
	for _, v in pairs(locales) do
		if locale == v then
			return true
		end
	end
	return false
end

local function loadLocales()
	local locales = getLocales()

	for _, locale in pairs(locales) do
		local file = xmlLoadFile("files/locales/" .. locale .. ".xml")
		if file then
			g_lang[locale] = {}
			for _, node in pairs(xmlNodeGetChildren(file)) do
				strname = xmlNodeGetName(node)
				strval = xmlNodeGetValue(node)
				strval = strip(strval)
				g_lang[locale][strname] = strval
			end
		else
			output("ERROR: Cant load " .. locale .. " locale.")
		end
	end
end
loadLocales()

if localPlayer then

function getLocalLanguage()
	local code = getLocalization().code
	if isLocaleAvailable(code) then
		return code
	end
	return defaultLocale
end

function getText(txt)
	local locale = getLocalLanguage()
	return getLanguageText(locale, txt)
end

else

function getText(txt, player)
	if not player then
		outputChatBox("getText player is nil")
	end

	local locale = g_player[player].localization
	return getLanguageText(locale, txt)
end

end

function getLanguageText(locale, txt)
	if not g_lang[locale] or not g_lang[locale][txt] then
		if locale ~= defaultLocale then
			return getLanguageText(defaultLocale, txt)
		end
		return ""
	end

	return g_lang[locale][txt]
end

function getDefaultLocaleText(txt)
	return getLanguageText(defaultLocale, txt)
end
