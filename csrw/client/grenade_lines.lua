-- table of projectiles with lines to be rendered
local gl_lineProjectiles = {}

-- table of projectile lines
local gl_projectileLines = {}

local gl_projectileLines_lastIndex = 0

local PROJECTILE_LINES_RENDER_HANDLER = "onClientPreRender"
local DEBUG_ALWAYS_RENDER_PROJECTILE_LINES = DEBUG_MODE and true
local GRENADE_LINE_TIMEOUT = 7000
local MARKER_SCALE = 0.25

addEventHandler("onClientProjectileCreation", root,
	function(creator)
		--outputChatBox("onClientProjectileCreation; creator: " .. tostring(creator) .. " (element " .. creator.type .. ")")
		if (g_player.spectating and creator and creator.type == "player") or DEBUG_ALWAYS_RENDER_PROJECTILE_LINES then
			-- Draw projectile lines in spectator
			local linesIndex = gl_projectileLines_lastIndex
			gl_projectileLines_lastIndex = gl_projectileLines_lastIndex + 1
			gl_projectileLines[linesIndex] = {
				lines = {},
				marker = nil
			}
			source:setData("linesIndex", linesIndex, false)

			table.insert(gl_lineProjectiles, source)
			if not isTimer(gl_timer_updateProjectileLines) then
				setTimer(updateProjectileLines, 50, 0)
			end
			
			local x, y, z = getElementPosition(source)
			local r, g, b = creator.team:getColor()
			setElementData(source, "oldPos", {x, y, z}, false)
			setElementData(source, "color", {r, g, b}, false)

			addEventHandler("onClientElementDestroy", source, onProjectileWithLineDestroy)
		end
	end
)

function updateProjectileLines()
	for k, v in pairs(gl_lineProjectiles) do
		local o = getElementData(v, "oldPos")
		local x, y, z = getElementPosition(v)
		local color = getElementData(v, "color")
		local linesIndex = v:getData("linesIndex")

		function drawProjectileLine()
			local x0, y0 = getScreenFromWorldPosition(o[1], o[2], o[3])
			local x, y = getScreenFromWorldPosition(x, y, z)
			if x0 and x then
				dxDrawLine(x0, y0, x, y, tocolor(color[1], color[2], color[3], 230), 2, false)
			end
			--dxDrawLine3D(o[1], o[2], o[3], x, y, z, tocolor(color[1], color[2], color[3]), 2, true)
		end
		addEventHandler(PROJECTILE_LINES_RENDER_HANDLER, root, drawProjectileLine)
		table.insert(gl_projectileLines[linesIndex].lines, drawProjectileLine)
		setElementData(v, "oldPos", {x, y, z}, false)
	end
end

function onProjectileWithLineDestroy()
	local tPos = table.find(gl_lineProjectiles, source)
	if not tPos then
		return
	end

	local x, y, z = getElementPosition(source)
	local color = source:getData("color")

	table.remove(gl_lineProjectiles, tPos)
	if #gl_lineProjectiles == 0 and isTimer(gl_timer_updateProjectileLines) then
		killTimer(gl_timer_updateProjectileLines)
	end

	local linesIndex = source:getData("linesIndex")

	local marker = createMarker(x, y, z, "corona", MARKER_SCALE, color[1], color[2], color[3])
	marker.interior = source.interior
	marker.dimension = source.dimension
	gl_projectileLines[linesIndex].marker = marker

	setTimer(
		function()
			if not gl_projectileLines[linesIndex] then return end

			if marker and isElement(marker) then
				marker:destroy()
			end
			gl_projectileLines[linesIndex].marker = nil

			for k, v in pairs(gl_projectileLines[linesIndex].lines) do
				removeEventHandler(PROJECTILE_LINES_RENDER_HANDLER, root, v)
			end
			gl_projectileLines[linesIndex] = nil
		end,
	GRENADE_LINE_TIMEOUT, 1)
end

-- Remove all projectile lines
function destroyProjectileLines()
	if gl_timer_updateProjectileLines and isTimer(gl_timer_updateProjectileLines) then
		killTimer(gl_timer_updateProjectileLines)
	end
	gl_timer_updateProjectileLines = nil

	for k, v in pairs(gl_projectileLines) do
		if v.marker and isElement(v.marker) then
			v.marker:destroy()
			v.marker = nil
		end

		for k, v2 in pairs(v.lines) do
			removeEventHandler(PROJECTILE_LINES_RENDER_HANDLER, root, v2)
		end
		v.lines = {}
	end

	gl_lineProjectiles = {}
end

--[[function cmd_destroyProjectileLines(cmdName)
	destroyProjectileLines()
end    
addCommandHandler("delprojlines", cmd_destroyProjectileLines)]]--
