local crosshair = {
	type = "default",
	dot = true,

	dotSize = 2,
	dotColor = tocolor(0, 255, 0, 255),
	lineWidth = 5,
}

local render = {
	center = {sX/2 + sX*0.030245, sY/2 - sY*0.100245}
}

function setCrosshairType(type)
	if type == "default" then
		-- Default GTA crosshair with replaced texture (with recoil)

		removeEventHandler("onClientRender", root, renderStaticCrosshair)
		setPlayerHudComponentVisible("crosshair", true)

	elseif type == "static" then
		-- Static crosshair
		setPlayerHudComponentVisible("crosshair", false)
		addEventHandler("onClientRender", root, renderStaticCrosshair)
	end
end

function setCrosshairParam(param, value)
	if param == "dot" then
		crosshair.dot = value
	end
end

function renderStaticCrosshair()
	local target = getCameraTarget()
	if not target then
		if localPlayer.health > 0 then
			target = localPlayer
		end
	end

	if not target or (target.type ~= "player" and target.type ~= "ped") then
		return
	end

	if getPedTask(target, "secondary", TASK_SECONDARY_ATTACK) ~= "TASK_SIMPLE_USE_GUN" then
		return
	end

	if crosshair.dot then
		-- dxDrawRectangle(render.center[1] - crosshair.dotSize/2, render.center[2] - crosshair.dotSize/2, crosshair.dotSize, crosshair.dotSize, crosshair.dotColor, false, true)
	
		dxDrawCircle(render.center[1], render.center[2], crosshair.dotSize, 0, 360, crosshair.dotColor, crosshair.dotColor)
	end
end

setCrosshairType("static")
setCrosshairParam("dot", true)
