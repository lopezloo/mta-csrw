advert = {}
local notopbarchat

local event = "onResourceStart"
if localPlayer then event = "onClientResourceStart" end

addEventHandler(event, resourceRoot,
	function()
		if getResourceDynamicElementRoot(getResourceFromName("topbarchat")) == false then
			notopbarchat = true
		end
	end
)

function advert.ok(text, player, skipLang)
	advert.text(text, 120, 255, 0, player, skipLang)
end

function advert.error(text, player, skipLang)
	advert.text(text, 180, 0, 0, player, skipLang)
end

function advert.text(text, r, g, b, player, skipLang)
	if not r or not g or not b then return end
	if localPlayer then player = localPlayer end

	if not skipLang then
		text = getText(text, player)
	end

	if notopbarchat then
		if localPlayer then
			outputChatBox(text, r, g, b)
		else
			outputChatBox(text, player, r, g, b)
		end
		return
	end

	if localPlayer then
		exports["topbarchat"]:sendClientMessage(text, r, g, b, true, 8)
	else
		exports["topbarchat"]:sendClientMessage(text, player, r, g, b, true, 8)
	end
end
