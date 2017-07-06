local motdFile = fileOpen("motd.txt")
local motd = "Message Of The Day cannot be loadded."
if motdFile then
    motd = fileRead(motdFile, fileGetSize(motdFile))
    fileClose(motdFile)
end

function onMOTDClosed(window)
    if window == "motd" then
        unbindKey("space", "down", showClassSelection)
        unbindKey("enter", "down", showClassSelection)
    end
end

local skipButton = guiCreateButton(0.482, 0.85, 0.05, 0.04, "SKIP", true)
guiSetVisible(skipButton, false)
guiSetProperty(skipButton, "NormalTextColour", "FFAAAAAA")
addEventHandler("onClientGUIClick", skipButton, showClassSelection)

local render = { -- 1680x1050
    motd = {0.2279*sX, 0.2266*sY, 0.5*sX, 0.8885*sY}, -- 383, 238, 840, 933
    line = {0.5059*sX, 0.2580*sY, 0.8485*sY}, -- 850, 271, 891
    globalHeader = {0.5214*sX, 0.2238*sY, 0.7863*sX, 0.2542*sY}, -- 876, 235, 1321, 267

    newsHeaderScale = 1.20, -- 1.20 (text scale)

    news = {0.517857*sX, 0.7827*sX, 0.8885*sY} -- 870 (x), 1315 (x), 933 (y2)
}

-- GLOBALNE NEWSY
local news = {}
function renderMOTD()
    dxDrawText(motd, render["motd"][1], render["motd"][2], render["motd"][3], render["motd"][4], tocolor(255, 255, 255, 255), 1.00, "default", "left", "top", true, true, false, false, false) -- motd
    dxDrawLine(render["line"][1], render["line"][2], render["line"][1], render["line"][3], tocolor(255, 255, 255, 255), 1, false) -- linia środkowa

    --dxDrawText(newsString, render["newsX"], 296, 1315, 933, tocolor(255, 255, 255, 255), 1.00, "default", "left", "top", true, true, false, false, false)
    dxDrawText("Global News:", render["globalHeader"][1], render["globalHeader"][2], render["globalHeader"][3], render["globalHeader"][4], tocolor(255, 255, 255, 255), 1.00, "bankgothic", "center", "top", false, false, false, false, false)
    --[[dxDrawText(news[1].title, 870, 271, 1321, 291, tocolor(255, 255, 255, 255), 1.20, "clear", "left", "top", true, false, false, false, false) -- nagłówek 1 newsa
    dxDrawLine(870, 291, 1320, 291, tocolor(255, 255, 255, 255), 1, false) -- linia pod nagłówkiem 1 newsa
    dxDrawText(news[1].text, 870, 296, 1315, 933, tocolor(255, 255, 255, 255), 1.00, "default", "left", "top", true, true, false, false, false) -- treść 1 newsa]]--

    for k, v in pairs(news) do
        dxDrawText(news[k].title, render["news"][1], news[k].h1, render["globalHeader"][3], news[k].h2, tocolor(255, 255, 255, 255), render["newsHeaderScale"], "clear", "left", "top", true, false, false, false, false) -- nagłówek
        dxDrawLine(render["news"][1], news[k].h2, render["globalHeader"][3]-1, news[k].h2, tocolor(255, 255, 255, 255), 1, false) -- linia pod nagłówkiem newsa
        dxDrawText(news[k].text, render["news"][1], news[k].h2, render["news"][2], render["news"][3], tocolor(255, 255, 255, 255), 1.00, "default", "left", "top", true, true, false, false, false) -- treść newsa
    end
end

function showMOTD()
    setBoxVisible(true, "Server MOTD", "motd", "renderMOTD", { skipButton })
    guiSetVisible(skipButton, true)
    bindKey("space", "down", showClassSelection)
    bindKey("enter", "down", showClassSelection)
    showCursor(true)
end

local newsMainNode = xmlLoadFile("news")
if not newsMainNode or #xmlNodeGetChildren(newsMainNode) == 0 then
    outputConsole("Warning: I can't load latest news.")
    return
end

for k, v in pairs( xmlNodeGetChildren(newsMainNode) ) do
    news[k] = {}
    news[k].title = xmlNodeGetAttribute(v, "title")
    news[k].size = tonumber(xmlNodeGetAttribute(v, "size")) * sY
    news[k].text = xmlNodeGetValue( v )

    if k == 1 then
        news[k].h1 = render["line"][2] -- pozycja Y (271)
    else
        news[k].h1 = news[k-1].h1 + news[k-1].size
    end
    news[k].h2 = news[k].h1 + 0.025*sY -- dodane 42px (1680x1050)   
end
xmlUnloadFile(newsMainNode)