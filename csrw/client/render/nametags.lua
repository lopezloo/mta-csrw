local font = "default-bold"
local sX, sY = guiGetScreenSize()
local teamColors = {
	[getTeamFromName("tt")] = tocolor(207, 0, 24, 200),
	[getTeamFromName("ct")] = tocolor(0, 83, 156, 200),
}

local minus = 0.022*sY -- 20 (900px)
addEventHandler("onClientRender", root,
	function()
		local target = getPedTarget(localPlayer)
		if target and (getElementType(target) == "player" or getElementType(target) == "ped") and target ~= localPlayer and getElementData(target, "health") > 0 then
			local x, y, z = getPedBonePosition(target, 1)
			local lx, ly, lz = getElementPosition(localPlayer)
			if getDistanceBetweenPoints3D(x, y, z, lx, ly, lz) <= 30 then
				local x, y = getScreenFromWorldPosition(x, y, z)
				if x and y then
					local color = tocolor(255, 255, 255, 200)
					local px, py, pz = getElementPosition(target)

					-- podnapis
					if getElementType(target) == "player" then
						color = teamColors[ getPlayerTeam(target) ]
						local txt
						if getPlayerTeam(target) == getPlayerTeam(localPlayer) then
							txt = getText("nametags_friend") .. ", " .. getElementData(target, "health")
						else
							txt = getText("nametags_enemy")
						end

						local width = dxGetTextWidth(txt, 1, "default-bold")
						local xwidth = x-width
						local xwidth2 = x+width

						dxDrawText(txt, xwidth+1, y+1, xwidth2+1, y+1, tocolor(0, 0, 0, 150), 1, font, "center", "top", false, false, false, false, true)
						dxDrawText(txt, xwidth+1, y-1, xwidth2+1, y-1, tocolor(0, 0, 0, 150), 1, font, "center", "top", false, false, false, false, true)
						dxDrawText(txt, xwidth-1, y+1, xwidth2-1, y+1, tocolor(0, 0, 0, 150), 1, font, "center", "top", false, false, false, false, true)
						dxDrawText(txt, xwidth-1, y-1, xwidth2-1, y-1, tocolor(0, 0, 0, 150), 1, font, "center", "top", false, false, false, false, true)
						dxDrawText(txt, xwidth, y, xwidth2, y, color, 1, "default-bold", "center", "top", false, false, false, false, true)
					end

					-- nagłówek
					y = y - minus
					--local txt = getPlayerName(target)
					local txt = getText("nametags_hostage")
					if getElementType(target) == "player" then
						txt = getPlayerName(target)
					end

					local scale = 1.5
					local width = dxGetTextWidth(txt, scale, font)
					local xwidth = x-width
					local xwidth2 = x+width

					dxDrawText(txt, xwidth+1, y+1, xwidth2+1, y+1, tocolor(0, 0, 0, 150), scale, font, "center", "top", false, false, false, false, true)
					dxDrawText(txt, xwidth+1, y-1, xwidth2+1, y-1, tocolor(0, 0, 0, 150), scale, font, "center", "top", false, false, false, false, true)
					dxDrawText(txt, xwidth-1, y+1, xwidth2-1, y+1, tocolor(0, 0, 0, 150), scale, font, "center", "top", false, false, false, false, true)
					dxDrawText(txt, xwidth-1, y-1, xwidth2-1, y-1, tocolor(0, 0, 0, 150), scale, font, "center", "top", false, false, false, false, true)
					dxDrawText(txt, xwidth, y, xwidth2, y, color, scale, font, "center", "top", false, false, false, false, true)
				end
			end
		end
	end
)

addEventHandler("onClientElementStreamIn", root,
	function()
		if getElementType(source) == "player" then
			setPlayerNametagShowing(source, false)
		end
	end
)
