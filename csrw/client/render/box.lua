-- Rendering dynamicznych boxów

local box = {}
box["label"] = ""
--box["latestWindow"] = nil
box["window"] = nil -- na wzór starego activeWindow_nazwa
box["renderHandlers"] = {}
box["elements"] = {} -- przyciski etc.

function renderBox()
	dxDrawRectangle(0.222619048*sX, 0.0485714286*sY, 0.567261905*sX, 0.161904762*sY, tocolor(0, 0, 0, 200), false) -- górne tło
	dxDrawRectangle(0.222619048*sX, 0.216190476*sY, 0.567261905*sX, 0.686666667*sY, tocolor(0, 0, 0, 150), false) -- dolne tło (to większe)


	--[[
		pasek co ma ta sama wysokosc co ten box \/
		dxDrawRectangle(374, 925, 953, 21, tocolor(255, 255, 255, 255), true)
	--]]
	
	dxDrawText(box["label"], 0.338095238*sX, 0.102857143*sY, 0.699404762*sX, 0.215238095*sY, tocolor(255, 130, 0, 255), 0.00119047619*sX, "bankgothic", "left", "top", false, false, false) 
	dxDrawImage(0.236904762*sX, 0.0647619048*sY, 0.0964285714*sX, 0.132380952*sY, ":csrw-media/images/cstrike.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
end

function enableLatestBox() -- TODO
	--[[if box["latestWindow"] then
		-- class
		setBoxVisible(true, box["label"], box["latestWindow"], box["renderHandlers"], box["elements"])
	end]]--
end

addEvent("onBoxClosed", false)
function setBoxVisible(draw, name, window, renderHandlers, elements)
	if draw then
		if not window then return false end
		
		if isBoxVisible() then -- jeśli inne okno jest otwarte
			--outputChatBox("Inne okno jest już otwarte, zamykam je.")
			setBoxVisible(false)
		end
	
		--clearBoxElements()
		--clearBoxRenderHandlers()
	
		box["label"] = name or ""
		box["window"] = window	
		
		addEventHandler("onClientRender", root, renderBox) -- box na dole
		if renderHandlers ~= nil then -- "render1,render2" itd
			local renders = split(renderHandlers, ",")
			for k, v in pairs(renders) do
				v = loadstring("return " .. v .. "()")
				if v then
					table.insert(box["renderHandlers"], v)
					addEventHandler("onClientRender", root, v)
				end
			end
		end
		
		if elements ~= nil then
			for k, v in pairs(elements) do
				if isElement(v) then 
					--outputChatBox("box: dodaje element " .. getElementType(v))
					table.insert(box["elements"], v)
					-- guiSetVisible(v, false) -- elementy gui nie są automatycznie pokazywane, trzeba to robić ręcznie!
				end
			end
		end
	else
		triggerEvent("onBoxClosed", resourceRoot, box["window"], box["label"], box["renderHandlers"], box["elements"])
		clearBoxElements()
		clearBoxRenderHandlers()
		box["latestWindow"] = box["window"]
		box["window"] = nil
	end
end	

function clearBoxRenderHandlers()
	if #box["renderHandlers"] >= 1 then
		for k, v in pairs(box["renderHandlers"]) do
			if v then removeEventHandler("onClientRender", root, v) end
		end
		box["renderHandlers"] = {}
	end
	removeEventHandler("onClientRender", root, renderBox)
end

function clearBoxElements()
	if #box["elements"] >= 1 then
		--outputChatBox("clearBoxElements " .. #box["elements"])
		for k, v in ipairs(box["elements"]) do
			if isElement(v) then
				if string.find(getElementType(v), "gui-") then
					guiSetVisible(v, false)
					--outputChatBox(getElementType(v))
				end
			end
		end
		box["elements"] = {}
	end
end

function isBoxVisible()
	if box["window"] ~= nil then
		return true
	else return false end
end

function getActiveBoxWindow() return box["window"] end
function getLatestBoxWindow() return box["latestWindow"] end
function setBoxLabel(name) box["label"] = name end
function getBoxLabel() return box["label"] end

function addRenderHandlersToCurrentBox(renderHandlers)
	if isBoxVisible() then
		local renders = split(renderHandlers, ",")
		for k, v in pairs(renders) do
			v = loadstring("return " .. v .. "()")
			if v then
				table.insert(box["renderHandlers"], v)
				addEventHandler("onClientRender", root, v)
			end
		end
		return true
	else return false end
end

function removeRenderHandlersFromCurrentBox(renderHandlers)
	if isBoxVisible() then
		local renders = split(renderHandlers, ",")
		for k, v in pairs(renders) do
			v = loadstring("return " .. v .. "()")
			if v then
				local pos = table.find(box["renderHandlers"], v)
				if pos then
					table.remove(box["renderHandlers"], pos)
					removeEvent("onClientRender", root, v)
				end
			end
		end
		return true
	else return false end
end

function addElementsToCurrentBox(elements)
	if isBoxVisible() then
		for k, v in pairs(elements) do
			if isElement(v) then
				table.insert(box["elements"], v)
			end
		end
		return true
	else return false end
end

function removeElementsFromCurrentBox(elements)
	if isBoxVisible() then
		for k, v in pairs(elements) do
			if isElement(v) then
				local pos = table.find(box["elements"], v)
				if pos then
					table.remove(box["elements"], pos)
				end
			end
		end
		return true
	else return false end
end

-- DEBUG CODE
--[[addCommandHandler("box", 
	function(cmd, label)
		if label == "0" then setBoxVisible(false) return end
		if label then
			label = string.gsub(label, "-", " ")
		end
		setBoxVisible(true, label, "boxdebug")
	end
)]]--