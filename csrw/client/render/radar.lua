local radar = {
	showing = false,
	-- kolor tła i obramowania
	background = {51, 162, 37, 160},
	disc = {0, 0, 0, 240},

	-- pozycja, rozmiary
	x = sY * 0.028,
	y = sY * 0.75,
	height = sY * 0.200,

	centerleft = radar.x + radar.height / 2,
	centerTop = radar.y + radar.height / 2,
	blipSize = radar.height / 16,
	lpsize = radar.height / 8,
	range = 100
}

function showRadar(show)
	if not show then show = not radar.showing end
	if radar.showing and show == false then
		removeEventHandler("onClientRender", root, onRadarRender)
	elseif not radar.showing and show == true then
		addEventHandler("onClientRender", root, onRadarRender)
	end
	radar.showing = show
end

function onRadarRender()
	local target = getCameraTarget()
	if not radar.showing or (not target and not g_player.spectator) then return end
	if target and getElementType(target) == "vehicle" and getPedOccupiedVehicle(localPlayer) == target then
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

	for k, v in ipairs(getElementsByType("player")) do
		if (g_player.spectator or (getElementData(v, "alive") and getPlayerTeam(v) == getPlayerTeam(localPlayer))) and target ~= v then
			local _, _, rot = getElementRotation(v)
			local ex, ey, ez = getElementPosition(v)
			local dist = getDistanceBetweenPoints2D(px, py, ex, ey)
			if dist > radar.range then
				dist = tonumber(radar.range)
			end
			local rot = 180-north + findRotation(px,py,ex,ey)
			local cblipx, cblipy = getPointFromDistanceRotation(0, 0, radar.height * (dist/radar.range)/2, rot)
			local blipx = radar.centerleft + cblipx - radar.blipSize/2
			local blipy = radar.centerTop + cblipy - radar.blipSize/2

			if getPlayerTeam(v) == g_team[1] then
				dxDrawImage(blipx, blipy, radar.blipSize, radar.blipSize, ":csrw-media/images/radar/tt.png", north-rot+45)
			else
				dxDrawImage(blipx, blipy, radar.blipSize, radar.blipSize, ":csrw-media/images/radar/ct.png", north-rot+45)
			end
		end
	end

	for k, v in ipairs(getElementsByType("bombsite")) do
		local letter = getElementID(v)
		if letter == "bombsite (1)" then letter = "A"
		elseif letter == "bombsite (2)" then letter = "B"
		elseif letter == "bombsite (3)" then letter = "C" end
		if letter == "A" or letter == "B" or letter == "C" then
			local ex, ey, ez = getElementPosition(v)
			local dist = getDistanceBetweenPoints2D(px, py, ex, ey)
			if dist > radar.range then
				dist = tonumber(radar.range)
			end
			local rot = 180 - north + findRotation(px, py, ex, ey)
			local cblipx, cblipy = getPointFromDistanceRotation(0, 0, radar.height * (dist/radar.range)/2, rot)
			local blipx = radar.centerleft + cblipx - radar.lpsize/2
			local blipy = radar.centerTop + cblipy - radar.lpsize/2

			dxDrawImage(blipx, blipy, radar.lpsize, radar.lpsize, ":csrw-media/images/radar/" .. letter .. ".png")
		end
	end

	for k, v in ipairs(getElementsByType("hostageSite")) do
		local ex, ey, ez = getElementPosition(v)
		local dist = getDistanceBetweenPoints2D(px, py, ex, ey)
		if dist > radar.range then
			dist = tonumber(radar.range)
		end
		local rot = 180 - north + findRotation(px, py, ex, ey)
		local cblipx, cblipy = getPointFromDistanceRotation(0, 0, radar.height * (dist/radar.range)/2, rot)
		local blipx = radar.centerleft + cblipx - radar.lpsize/2
		local blipy = radar.centerTop + cblipy - radar.lpsize/2

		dxDrawImage(blipx, blipy, radar.lpsize, radar.lpsize, ":csrw-media/images/radar/H.png")
	end

	if g_player.spectator and not target then
		dxDrawImage(radar.centerleft - radar.lpsize/2, radar.centerTop - radar.lpsize/2, radar.lpsize, radar.lpsize, ":csrw-media/images/radar/camera.png", north - pr)
	else
		dxDrawImage(radar.centerleft - radar.lpsize/2, radar.centerTop - radar.lpsize/2, radar.lpsize, radar.lpsize, ":csrw-media/images/radar/centre.png", north - pr)
	end
end

function findRotation(x1,y1,x2,y2)
	local t = -math.deg(math.atan2(x2-x1,y2-y1))
	if t < 0 then t = t + 360 end;
	return t;
end
