--[[

	AUTO UPDATE

	TODO:
		* aktualizacja specyficznych plików XML gdy mają wartość modified="false"

	Notes:
		* pliki pobierane są tylko za pierwszym razem (bo mogą być modyfikowane przez adm. serwera)
		* kod pobiera się zawsze
		* generowanie całkiem nowej mety przy aktualizacji
		* backup poprzedniego kodu/mety + nfo o ścieżkach w gałęzi meta.xml
		* pobieranie 'jednorazowych' plików komendą
		* pobieranie tylko tych plików z aktualizacji co potrzeba (wielkość)

--]]

if true then
	-- disable for now
	return
end

local meta = {
	file = nil,
	fileBackupNode = nil,
	oldFile = nil,
	text = nil
}

meta.oldFile = xmlLoadFile("meta.xml")
if not hasObjectPermissionTo(getThisResource(), "function.fetchRemote") then
	outputServerLog("WARNING: Auto update turned off due to permissions.")

	if not xmlFindChild(meta.oldFile, "script", 1) then -- szukanie drugiego skryptu
		outputServerLog("CRITICAL ERROR: Gamemode is not installed, you NEED to enable auto update (give gamemode permission to fetchRemote in ACL).")
		xmlUnloadFile(meta.oldFile)
	end
	meta = nil
	setRuleValue("autoupdate", "off")
	return
end
setRuleValue("autoupdate", "on")

local falseUpdate = true -- do debugu

local fileTypes = {"files", "shared", "server", "client"}
local files = {}

if meta.oldFile then
	meta.oldFile = xmlCopyFile(meta.oldFile, "backup/meta.xml") -- backup mety
	xmlSaveFile(meta.oldFile)
	xmlUnloadFile(meta.oldFile)
end

function onUpdateDataRecieved(data, errno) -- pobranie info o update (lista plików etc.)
	if errno == 0 then
		local updateFile = fileCreate("update.red")
		fileWrite(updateFile, data)
		fileClose(updateFile)

		local updateFile = xmlLoadFile("update.red")
		if not updateFile then
			outputServerLog("ERROR: I can't parse update data.")
			xmlUnloadFile(updateFile)
			fileDelete("update.red")
			return
		end

		-- rozdzielanie i zapisywanie listy plików do zmiennych
		for k, v in pairs(fileTypes) do
			local node = xmlFindChild(updateFile, v, 0) -- szukanie '<server' etc
			files[v] = {}
			for k2, v2 in pairs( xmlNodeGetChildren(node) ) do
				table.insert(files[v], { xmlNodeGetAttribute(v2, "src"), xmlNodeGetAttribute(v2, "checksum") }) -- nazwa, wielkość
			end
		end

		local oldMeta = xmlLoadFile("meta.xml")
		local oldMetaVer = 0
		if oldMeta then
			oldMetaVer = xmlNodeGetAttribute( xmlFindChild(oldMeta, "info", 0), "version" )
		end

		if xmlNodeGetAttribute( xmlFindChild(updateFile, "info", 0) , "ver") > oldMetaVer then -- aktualizacja
			outputServerLog("AUTO-UPDATE: New version available! Downloading...")

			-- zapisywanie info o skrypcie do mety
			if not falseUpdate then
				meta.file = xmlCreateFile("meta.xml", "meta") -- tworzenie mety (nawet jeśli juz istnieje)
				meta.fileBackupNode = xmlCreateChild(meta.file, "backup")
				xmlNodeSetAttribute(meta.fileBackupNode, "src", "")

				local metaInfo = xmlCreateChild(meta.file, "info")
				xmlNodeSetAttribute(metaInfo, "type", "gamemode")
				xmlNodeSetAttribute(metaInfo, "name", "csrw")
				xmlNodeSetAttribute(metaInfo, "author", "lopezloo")
				xmlNodeSetAttribute(metaInfo, "version", xmlNodeGetAttribute( xmlFindChild(updateFile, "info", 0) , "ver") or "0.0" )
				xmlNodeSetAttribute(metaInfo, "description", "Counter Strike RenderWare (last update: " .. (xmlNodeGetAttribute( xmlFindChild(updateFile, "info", 0) , "date") or "never") .. ")")
				xmlNodeSetAttribute(metaInfo, "edf:definition", "edf/csrw.xml")
				--

				local metaNode = xmlFindChild(updateFile, "meta", 0)
				meta.text = xmlNodeGetAttribute(metaNode, "text")
			end

			downloadScriptPart(fileTypes[1], 1) -- start pobierania kodu
		else
			outputServerLog("AUTO-UPDATE: Gamemode don't need update.")
		end
		if oldMeta then xmlUnloadFile(oldMeta) end -- zamykanie starej mety
		xmlUnloadFile(updateFile) -- unload pliku z info o update
		fileDelete("update.red")
	else
		outputServerLog("ERROR: Gamemode can't recieve update data (error " .. errno .. ").")
	end
end

fetchRemote("http://redknife.tk/csrw/update/update.xml", onUpdateDataRecieved)

-- POBIERANIE & ZAPISYWANIE
function onScriptPartDownloaded(responseData, errno, stype, id, onlyOneFile)
	local fileUrl = stype .. "/" .. files[stype][id][1]

	if errno ~= 0 then -- problem z pobraniem pliku, stop aktualizacji i przywracanie kodu z backupu
		outputServerLog("AUTO-UPDATE: I can't download " .. fileUrl .. " (error " .. errno .. "). Update canceled.")

		-- kopiowanie kodu z backupu
		local backupData = xmlNodeGetAttribute(meta.fileBackupNode, "src")
		for k, v in pairs(split(backupData, ",")) do
			local copied = fileCopy("backup/" .. v, v, true)
			if not copied then
				outputServerLog("ERROR: Problem with backup file.")
			end
		end

		if meta.file then xmlUnloadFile(meta.file) end -- zamykanie otwartej nowej mety

		-- kopiowanie mety z backupu
		meta.file = xmlLoadFile("backup/meta.xml")
		if meta.file then
			local metaCopied = xmlCopyFile(meta.file, "meta.xml")
			xmlSaveFile(metaCopied)
			xmlUnloadFile(metaCopied)
			xmlUnloadFile(meta.file)
		else
			outputServerLog("ERROR: I can't load meta.xml backup")
		end
		return
	end

	--[[if stype ~= "files" then
		fileUrl = fileUrl .. ".red" -- dodawanie rozszerzenia do pliku z kodem
	end]]--

	outputServerLog("Downloaded " .. stype .. " script part (id " .. id .. ") " .. fileUrl)

	if fileExists(fileUrl) then
		fileCopy(fileUrl, "backup/" .. fileUrl, true) -- backup starego kodu
	end

	if not falseUpdate then
		if stype ~= "files" or not fileExists(fileUrl) then -- nie aktualizowanie plików (konfingów etc.)
			local codeFile = fileCreate(fileUrl) -- jak już taki istnieje to sie nadpisze :>
			fileWrite(codeFile, responseData)
			fileFlush(codeFile)
			fileClose(codeFile)
		end

		local scriptNode
		if stype == "files" then
			scriptNode = xmlCreateChild(meta.file, "file")
		else
			scriptNode = xmlCreateChild(meta.file, "script")
			xmlNodeSetAttribute(scriptNode, "type", stype)
		end
		xmlNodeSetAttribute(scriptNode, "src", fileUrl)

		-- zapisywanie info o backupie do gałęzi w nowym meta.xml
		-- nie ma potrzeby zapisywania typu pliku ponieważ ta gałąź jest potrzebna jedynie do skopiowania plików (bo meta.xml z innymi danymi jest także skopiowana)
		local backupData = xmlNodeGetAttribute(meta.fileBackupNode, "src")
		if id > 1 or stype ~= fileTypes[1] then
			backupData = backupData .. ","
		end
		xmlNodeSetAttribute(meta.fileBackupNode, "src", backupData .. fileUrl)
		--
	end

	if not onlyOneFile then -- skrypt pobierał tylko jeden plik
		if id < #files[stype] then
			downloadScriptPart(stype, id + 1)
		else
			local i = table.find(fileTypes, stype)
			if i == #fileTypes then -- wszystkie pliki kodu zostały pobrane
				updateSuccesfull()
			else
				downloadScriptPart(fileTypes[i + 1], 1)
			end
		end
	else
		outputServerLog("Updating " .. files[stype][id][1] .. " finished. Please restart gamemode.")
	end
end

function downloadScriptPart(stype, id)
	local filepath = stype .. "/" .. files[stype][id][1]
	--[[if stype ~= "files" then
		filepath = filepath .. ".lua" -- dodawanie rozszerzenia do kodu
	end]]--
	-- (pobieranie plikow kodu bez rozszerzenia)

	if stype == "files" then
		filepath = filepath .. ".xml"
	end

	if fileExists(filepath) then
		local oldCode = fileOpen(filepath)

		local oldChecksum = md5( fileRead( oldCode, fileGetSize(oldCode) ) )
		local newChecksum = files[stype][id][2]

		outputServerLog("Verify checksum: " .. oldChecksum .. " vs " .. newChecksum)
		if oldChecksum ~= newChecksum then -- plik z aktualizacji ma inną sume kontrolną
			fetchRemote("http://redknife.tk/csrw/update/" .. filepath, onScriptPartDownloaded, "", true, stype, id)
		else
			-- dodawanie nie pobranego pliku pliku do mety (bo jest już pobrany)
			if not falseUpdate then
				local scriptNode
				if stype == "files" then
					scriptNode = xmlCreateChild(meta.file, "file")
				else
					scriptNode = xmlCreateChild(meta.file, "script")
					xmlNodeSetAttribute(scriptNode, "type", stype)
				end
				xmlNodeSetAttribute(scriptNode, "src", filepath)
			end

			-- próba pobrania kolejnych plików
			if id < #files[stype] then
				setTimer(downloadScriptPart, 250, 1, stype, id + 1)
			else
				local i = table.find(fileTypes, stype)
				if i < #fileTypes then
					setTimer(downloadScriptPart, 250, 1, fileTypes[i + 1], 1)
				else
					updateSuccesfull()
				end
			end
		end
		fileClose(oldCode)
	else
		-- pobieranie całkiem nowego kodu
		fetchRemote("http://redknife.tk/csrw/update/" .. filepath, onScriptPartDownloaded, "", true, stype, id)
	end
end

local function updateFile(path)
	for k, v in pairs(files["files"]) do
		if v == path then
			fetchRemote("http://redknife.tk/csrw/update/files/" .. files[stype][id][1], onScriptPartDownloaded, "", true, "files", k, true)
			outputServerLog("UPDATE: Trying to manually update file '" .. path .. "'.")
			return
		end
	end
	outputServerLog("UPDATE: Old file " .. path .. " doesn't exist.")
end

addCommandHandler("updatefile",
	function(player, cmd, filepath)
		if hasObjectPermissionTo(player, "function.ModifyOtherObjects") then
			if filepath then
				updateFile(filepath)
				outputChatBox("UPDATE: Request was sent. Please see result in server log.", player)
			else
				outputChatBox("UPDATE: You need specify filepath.", player)
			end
		else
			outputChatBox("UPDATE: Access denied.", player)
		end
	end
)

function updateSuccesfull()
	if not falseUpdate then
		-- zapisywanie meta.xml
		xmlSaveFile(meta.file)
		xmlUnloadFile(meta.file)

		meta.file = fileOpen("meta.xml")
		fileSetPos(meta.file, fileGetSize(meta.file) - 9) -- zaczynanie pisania od prawie końca (nadpisywanie końcowego '</meta>')
		fileWrite(meta.file, meta.text .. "\n</meta>")
		fileFlush(meta.file)
		fileClose(meta.file)
	end

	if hasObjectPermissionTo(getThisResource(), "function.restartResource") and not falseUpdate then
		restartResource(getThisResource())
		outputServerLog("Update fininsed, restarting gamemode...")
	else
		outputServerLog("Update fininsed, please restart gamemode.")
	end
end

-- mini utils
function table.find(table, find)
	if not table or not find then return false end
	for k, v in pairs(table) do
		if v == find then
			return k
		end
	end
	return false
end
