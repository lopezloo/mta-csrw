local radar = {
	showing = false,
	-- background and border colors
	background = {51, 162, 37, 160},
	disc = {0, 0, 0, 240},

	-- position and size
	x = sY * 0.028,
	y = sY * 0.75,
	height = sY * 0.200,

	range = 100,

	blips = {}
}

radar.centerleft = radar.x + radar.height / 2
radar.centerTop = radar.y + radar.height / 2
radar.blipSize = radar.height / 16
radar.lpsize = radar.height / 8

function csCreateBlip(pos, img, size)
	table.insert(radar.blips, {
		pos = pos,
		attachedTo = nil,
		img = img,
		size = size
	})
end

function csCreateBlipAttachedTo(attachedTo, img, size)
	table.insert(radar.blips, {
		pos = nil,
		attachedTo = attachedTo,
		img = img,
		size = size
	})
end

function csClearBlips()
	radar.blips = {}
end

local function renderRadar()
	local target = getCameraTarget()
	if not radar.showing or (not target and not g_player.spectator) then return end

	if target and target.type == "vehicle" and localPlayer.vehicle == target then
		target = localPlayer
	end

	if not g_player.spectator and target then
		px, py, pz = getElementPosition(target)
		pr = getPedRotation(target)
	else
		px, py, pz = getCameraMatrix()
		pr = 0
	end

	local cx, cy, _, tx, ty = getCameraMatrix()
	local north = findRotation(cx, cy, tx, ty)
	dxDrawImage(radar.x, radar.y, radar.height, radar.height, ":csrw-media/images/radar/background.png", 0, 0, 0, tocolor(radar.background[1], radar.background[2], radar.background[3], radar.background[4]), false)
	dxDrawImage(radar.x, radar.y, radar.height, radar.height, ":csrw-media/images/radar/disc.png", 0, 0, 0, tocolor(radar.disc[1], radar.disc[2], radar.disc[3], radar.disc[4]), false)

	for _, v in ipairs(getElementsByType("player")) do
		if (g_player.spectator or (getElementData(v, "alive") and v.team == localPlayer.team)) and target ~= v then
			local _, _, rot = getElementRotation(v)
			local ex, ey, ez = getElementPosition(v)
			local dist = getDistanceBetweenPoints2D(px, py, ex, ey)
			if dist > radar.range then
				dist = tonumber(radar.range)
			end
			local rot = 180-north + findRotation(px, py, ex, ey)
			local cblipx, cblipy = getPointFromDistanceRotation(0, 0, radar.height * (dist/radar.range)/2, rot)
			local blipx = radar.centerleft + cblipx - radar.blipSize/2
			local blipy = radar.centerTop + cblipy - radar.blipSize/2

			if v.team == g_team[1] then
				dxDrawImage(blipx, blipy, radar.blipSize, radar.blipSize, ":csrw-media/images/radar/tt.png", north-rot+45)
			else
				dxDrawImage(blipx, blipy, radar.blipSize, radar.blipSize, ":csrw-media/images/radar/ct.png", north-rot+45)
			end
		end
	end

	for _, v in ipairs(radar.blips) do
		local ex, ey, ez
		if v.pos then
			ex, ey, ez = v.pos.x, v.pos.y, v.pos.z
		elseif isElement(v.attachedTo) then
			ex, ey, ez = v.attachedTo.position.x, v.attachedTo.position.y, v.attachedTo.position.z
		end

		if ex and ey and ez then
			local dist = getDistanceBetweenPoints2D(px, py, ex, ey)
			if dist > radar.range then
				dist = tonumber(radar.range)
			end

			local size = radar.height / v.size

			local rot = 180 - north + findRotation(px, py, ex, ey)
			local cblipx, cblipy = getPointFromDistanceRotation(0, 0, radar.height * (dist/radar.range)/2, rot)
			local blipx = radar.centerleft + cblipx - size/2
			local blipy = radar.centerTop + cblipy - size/2

			dxDrawImage(blipx, blipy, size, size, ":csrw-media/images/radar/" .. v.img .. ".png")
		end
	end

	if g_player.spectator and not target then
		dxDrawImage(radar.centerleft - radar.lpsize/2, radar.centerTop - radar.lpsize/2, radar.lpsize, radar.lpsize, ":csrw-media/images/radar/camera.png", north - pr)
	else
		dxDrawImage(radar.centerleft - radar.lpsize/2, radar.centerTop - radar.lpsize/2, radar.lpsize, radar.lpsize, ":csrw-media/images/radar/centre.png", north - pr)
	end
end

function showRadar(show)
	if not show then
		show = not radar.showing
	end

	if radar.showing and show == false then
		removeEventHandler("onClientRender", root, renderRadar)
	
	elseif not radar.showing and show == true then
		addEventHandler("onClientRender", root, renderRadar)
	end
	radar.showing = show
end
