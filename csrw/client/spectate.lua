local specData = {
	currentID = 1,
	currentPlayer = nil,
	list = {},
	mode = nil,
}

local updateColorTimer
local updateWallEffectTimer

spectator = {}

function spectator.join(temporary)
	outputDebugString("joining spectators")
	g_player.spectating = true
	
	if not temporary then
		classUpdatePlayer(nil, 3)
	end
	
	if getElementData(localPlayer, "alive") then
		csSetPedHealth(localPlayer, 0)
		setElementHealth(localPlayer, 0)
	end

	--roundEndClientFunctions()
	showRadar(true)
	
	spectator.updateList()
	if #specData.list < 1 then
		advert.error("msg_specAlone")
		spectator.freecam()
	else
		spectator.spectatePlayer()
		showHUD(true)
		addEventHandler("onClientRender", root, renderSpectatorHUD)
		addEventHandler("onClientPlayerQuit", root, updateSpectator)
		addEventHandler("onClientPlayerWasted", root, updateSpectator)
	end

	bindKey("arrow_l", "down", spectator.previous)
	bindKey("arrow_r", "down", spectator.next)
	bindKey("space", "down", spectator.switchMode)

	local team = localPlayer.team
	if team == g_team[1] or team == g_team[2] then
		-- wallhack people from own team
		local r, g, b = getTeamColor(team)
		for k, v in pairs(getPlayersInTeam(team)) do
			if v.health > 0 then
				CWallShader:enable(v, r, g, b)
			end
		end
	else
		-- wallhack everyone
		for k, v in pairs(getElementsByType("player")) do
			if v.health > 0 then
				local vteam = getPlayerTeam(v)
				if vteam then
					local r, g, b = getTeamColor(vteam)
					CWallShader:enable(v, r, g, b)
				end
			end
		end
	end
	addEventHandler("onClientPlayerSpawn", root, onNewPlayerSpawned)
end

-- spawn nowego gracza (jeśli się jest w teamie spectatorów)
function onNewPlayerSpawned(team)
	if not team then
		outputDebugString("Spectator: onNewPlayerSpawned: player spawned without team", 2)
		return
	end

	if not table.find(specData.list, source) then
		-- dodanie gracza do listy specowanych
		table.insert(specData.list, source)
	end

	if localPlayer.team == g_team[3] or localPlayer.team == team then
		local r, g, b = getTeamColor(team)
		CWallShader:enable(source, r, g, b)
	end
end

function spectator.exit()
	if not g_player.spectating then
		return
	end

	outputDebugString("leaving spectators")
	if specData.mode == 1 then
		setFreecamDisabled()
	end
	g_player.spectating = false
	
	unbindKey("arrow_l", "down", spectator.previous)
	unbindKey("arrow_r", "down", spectator.next)
	unbindKey("space", "down", spectator.switchMode)

	removeEventHandler("onClientPlayerSpawn", root, onNewPlayerSpawned)

	CWallShader:resetAll()
	showRadar(false)
	showHUD(false)
	removeEventHandler("onClientRender", root, renderSpectatorHUD)
	removeEventHandler("onClientPlayerQuit", root, updateSpectator)
	removeEventHandler("onClientPlayerWasted", root, updateSpectator)
end

function spectator.updateList()
	specData.list = {}
	for k, v in pairs(getElementsByType("player")) do
		if getElementData(v, "alive") and v ~= localPlayer then
			--outputChatBox("spectator.updateList(): dodawanie gracza do listy: " .. getPlayerName(v))
			table.insert(specData.list, v) -- usuwanie nieżywych graczy i localPlayera
		end
	end
	return #specData.list
end

function spectator.spectatePlayer(id)
	if not id then id = 1 end
	
	if id > #specData.list then
		id = 1 -- jeśli ID jest większe od ostatniego ID z listy to przeskok na 1 gracza
	elseif id <= 0 then
		id = #specData.list
	end

	if specData.currentPlayer ~= specData.list[id] or specData.mode ~= 0 then
		specData.mode = 0
		specData.currentID = id
		specData.currentPlayer = specData.list[id]
		
		setCameraTarget( specData.currentPlayer )
		setElementInterior(localPlayer, getElementInterior( specData.currentPlayer ))
	end
end

function spectator.next()
	if specData.mode ~= 0 then return false end
	spectator.spectatePlayer(specData.currentID + 1)
end

function spectator.previous()
	if specData.mode ~= 0 then return false end
	spectator.spectatePlayer(specData.currentID - 1)
end

function spectator.freecam(customPosition)
	if customPosition then
		local x, y, z, rx, ry, rz, _, _ = getCameraMatrix()
		setCameraMatrix(x, y, z, rx, ry, rz)
		setFreecamEnabled()
	else
		local int, x, y, z = getRandomCameraPos(true)
		setElementInterior(localPlayer, int)
		setFreecamEnabled(x, y, z)
	end
	specData.mode = 1
end

function joinSpectatorsTemporary()
	if source and source == localPlayer then
		outputDebugString("temporary joining spectators")
		spectator.join(true)
	end
end
addEvent("joinSpectatorsTemporary", true)
addEventHandler("joinSpectatorsTemporary", root, joinSpectatorsTemporary)

function spectator.switchMode()
	if specData.mode == 0 then
		-- switch to free cam
		spectator.freecam(true)
		playSound(":csrw-sounds/sounds/gui/whooshes/short_whoosh1.wav")
		removeEventHandler("onClientRender", root, renderSpectatorHUD)
		removeEventHandler("onClientPlayerQuit", root, updateSpectator)
		removeEventHandler("onClientPlayerWasted", root, updateSpectator)
	
	else
		-- switch to player spectator
		if spectator.updateList() > 0 then
			-- if there are alive players
			setFreecamDisabled()
			
			spectator.spectatePlayer(specData.currentID)
			playSound(":csrw-sounds/sounds/gui/whooshes/short_whoosh1.wav")
			showHUD(true)
			addEventHandler("onClientRender", root, renderSpectatorHUD)
			addEventHandler("onClientPlayerQuit", root, updateSpectator)
			addEventHandler("onClientPlayerWasted", root, updateSpectator)			
		else
			advert.error("msg_specAlone")
		end
	end
end

function updateSpectator()
	if not g_player.spectating or source == localPlayer then
		return
	end

	for k, v in pairs(specData.list) do
		if v == source then
			-- remove dead/non-existing player from spectator list
			table.remove(specData.list, k)
		end
	end

	-- @todo: shouldn't we disable wallshader for dead/non-existing player here?

	-- switch to next alive player or freecam
	if specData.currentPlayer == source then
		if #specData.list == 0 then
			advert.error("msg_specAlone")
			specData.mode = 0
			spectator.freecam(true)
			removeEventHandler("onClientRender", root, renderSpectatorHUD)
			removeEventHandler("onClientPlayerQuit", root, updateSpectator)
			removeEventHandler("onClientPlayerWasted", root, updateSpectator)					
			showHUD(false)
		else
			spectator.next()
		end
	end
end

-- interfejs
local render = { -- 1440x900
	rectangle = { 0.3027*sX, 0.8022*sY, 0.3965*sX, 0.1277*sY }, -- 436, 722, 571, 115
	name = { 0.3104*sX, 0.8144*sY, 0.5652*sX, 0.85*sY }, -- 447, 733, 814, 765 (cień: 446, 732, 813, 764)
	stats = { 0.3131*sX, 0.8588*sY, 0.5645*sX, 0.9188*sY }, -- 451, 773, 813, 827
	weaponImg1 = { 0.5715*sX, 0.8033*sY, 0.1152*sX, 0.0755*sY }, -- 823, 732, 166, 68 (szeroka) 
	weaponImg2 = { 0.5715*sX, 0.8088*sY, 0.1152*sX, 0.0966*sY }, -- 823, 728, 166, 87
	weaponName = { 0.5715*sX, 0.8944*sY, 0.6868*sX, 0.9211*sY }, -- 823, 805, 989, 829
	specNamesColors = {
		[getTeamFromName("tt")] = tocolor(207, 0, 24, 234),
		[getTeamFromName("ct")] = tocolor(1, 116, 189, 234),
	}
}

function renderSpectatorHUD()
	if not specData.currentPlayer then
		return
	end

	dxDrawRectangle(render.rectangle[1], render.rectangle[2], render.rectangle[3], render.rectangle[4], tocolor(0, 0, 0, 117), false)
	dxDrawText(getPlayerName( specData.currentPlayer ), render.name[1], render.name[2], render.name[3], render.name[4], tocolor(0, 0, 0, 255), 1.00, "bankgothic", "left", "top", false, false, false, false, false)
	dxDrawText(getPlayerName( specData.currentPlayer ), render.name[1]-1, render.name[2]-1, render.name[3]-1, render.name[4]-1, render.specNamesColors[getPlayerTeam( specData.currentPlayer )], 1.00, "bankgothic", "left", "top", false, false, false, false, false)
	--dxDrawRectangle(437, 509, 0, 0, tocolor(255, 255, 255, 255), true) -- ?

	-- @todo: localize
	dxDrawText("Kills: " .. (getElementData(specData.currentPlayer, "score") or 0) .. "\nDeaths: " .. (getElementData(specData.currentPlayer, "deaths") or 0), render.stats[1], render.stats[2], render.stats[3], render.stats[4], tocolor(255, 255, 255, 255), 1.00, "clear", "left", "top", false, false, false, false, false)

	local slot = getElementData(specData.currentPlayer, "currentSlot")
	if slot then
		local wep = getElementData(specData.currentPlayer, "wSlot" .. slot)
		if wep then
			local img = g_weapon[slot][wep]["image"]
			if img then
				dxDrawImage(render.weaponImg1[1], render.weaponImg1[2], render.weaponImg1[3], render.weaponImg1[4], ":csrw-media/images/shop/" .. img, 0, 0, 0, tocolor(255, 255, 255, 255), false)
				--dxDrawImage(render.weaponImg2[2], render.weaponImg2[3], render.weaponImg2[3], render.weaponImg2[4], 728, 166, 87, ":csrw-media/images/shop/pistols/40dual_elites.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
			end
			dxDrawText( g_weapon[slot][wep]["name"], render.weaponName[1], render.weaponName[2], render.weaponName[3], render.weaponName[4], tocolor(255, 255, 255, 255), 1.00, "clear", "center", "center", false, false, true, false, false)
		end
	end

	-- pozycjonowanie kamery
	--[[if isPedDoingTask(specData.currentPlayer, "TASK_SIMPLE_USE_GUN") then
		local tx, ty, tz = getPedTargetCollision(specData.currentPlayer)
		setCameraTarget(tx, ty, tz)

		local x, y, z = getElementPosition(specData.currentPlayer)
		dxDrawLine(x, y, z, tx, ty, tz)
	else]]--
	--setPedCameraRotation(localPlayer, - getPedCameraRotation(specData.currentPlayer))
end

-- KAMERA
local speed = 0
local strafespeed = 0
local rotX, rotY = 0,0
local velocityX, velocityY, velocityZ
local freecamState

-- configurable parameters
local options = {
	invertMouseLook = false,
	normalMaxSpeed = 2,
	slowMaxSpeed = 0.2,
	fastMaxSpeed = 12,
	smoothMovement = true,
	acceleration = 0.3,
	decceleration = 0.15,
	mouseSensitivity = 0.3,
	maxYAngle = 188,
	key_fastMove = "lshift",
	key_slowMove = "lalt",
	key_forward = "w",
	key_backward = "s",
	key_left = "a",
	key_right = "d"
}

local mouseFrameDelay = 0

local function freecamFrame ()
	if isMTAWindowActive() then return end
    -- work out an angle in radians based on the number of pixels the cursor has moved (ever)
    local cameraAngleX = rotX
    local cameraAngleY = rotY

    local freeModeAngleZ = math.sin(cameraAngleY)
    local freeModeAngleY = math.cos(cameraAngleY) * math.cos(cameraAngleX)
    local freeModeAngleX = math.cos(cameraAngleY) * math.sin(cameraAngleX)
    local camPosX, camPosY, camPosZ = getCameraMatrix()

    -- calculate a target based on the current position and an offset based on the angle
    local camTargetX = camPosX + freeModeAngleX * 100
    local camTargetY = camPosY + freeModeAngleY * 100
    local camTargetZ = camPosZ + freeModeAngleZ * 100

	-- Calculate what the maximum speed that the camera should be able to move at.
    local mspeed = options.normalMaxSpeed
    if getKeyState ( options.key_fastMove ) then
        mspeed = options.fastMaxSpeed
	elseif getKeyState ( options.key_slowMove ) then
		mspeed = options.slowMaxSpeed
    end
	
	if options.smoothMovement then
		local acceleration = options.acceleration
		local decceleration = options.decceleration
	
	    -- Check to see if the forwards/backwards keys are pressed
	    local speedKeyPressed = false
	    if getKeyState ( options.key_forward ) and not getKeyState("arrow_u") then
			speed = speed + acceleration 
	        speedKeyPressed = true
	    end
		if getKeyState ( options.key_backward ) and not getKeyState("arrow_d") then
			speed = speed - acceleration 
	        speedKeyPressed = true
	    end

	    -- Check to see if the strafe keys are pressed
	    local strafeSpeedKeyPressed = false
		if getKeyState ( options.key_right ) and not getKeyState("arrow_r") then
	        if strafespeed > 0 then -- for instance response
	            strafespeed = 0
	        end
	        strafespeed = strafespeed - acceleration / 2
	        strafeSpeedKeyPressed = true
	    end
		if getKeyState ( options.key_left ) and not getKeyState("arrow_l") then
	        if strafespeed < 0 then -- for instance response
	            strafespeed = 0
	        end
	        strafespeed = strafespeed + acceleration / 2
	        strafeSpeedKeyPressed = true
	    end

	    -- If no forwards/backwards keys were pressed, then gradually slow down the movement towards 0
	    if speedKeyPressed ~= true then
			if speed > 0 then
				speed = speed - decceleration
			elseif speed < 0 then
				speed = speed + decceleration
			end
	    end

	    -- If no strafe keys were pressed, then gradually slow down the movement towards 0
	    if strafeSpeedKeyPressed ~= true then
			if strafespeed > 0 then
				strafespeed = strafespeed - decceleration
			elseif strafespeed < 0 then
				strafespeed = strafespeed + decceleration
			end
	    end

	    -- Check the ranges of values - set the speed to 0 if its very close to 0 (stops jittering), and limit to the maximum speed
	    if speed > -decceleration and speed < decceleration then
	        speed = 0
	    elseif speed > mspeed then
	        speed = mspeed
	    elseif speed < -mspeed then
	        speed = -mspeed
	    end
	 
	    if strafespeed > -(acceleration / 2) and strafespeed < (acceleration / 2) then
	        strafespeed = 0
	    elseif strafespeed > mspeed then
	        strafespeed = mspeed
	    elseif strafespeed < -mspeed then
	        strafespeed = -mspeed
	    end
	else
		speed = 0
		strafespeed = 0
		if getKeyState ( options.key_forward ) then speed = mspeed end
		if getKeyState ( options.key_backward ) then speed = -mspeed end
		if getKeyState ( options.key_left ) then strafespeed = mspeed end
		if getKeyState ( options.key_right ) then strafespeed = -mspeed end
	end

    -- Work out the distance between the target and the camera (should be 100 units)
    local camAngleX = camPosX - camTargetX
    local camAngleY = camPosY - camTargetY
    local camAngleZ = 0 -- we ignore this otherwise our vertical angle affects how fast you can strafe

    -- Calulcate the length of the vector
    local angleLength = math.sqrt(camAngleX*camAngleX+camAngleY*camAngleY+camAngleZ*camAngleZ)

    -- Normalize the vector, ignoring the Z axis, as the camera is stuck to the XY plane (it can't roll)
    local camNormalizedAngleX = camAngleX / angleLength
    local camNormalizedAngleY = camAngleY / angleLength
    local camNormalizedAngleZ = 0

    -- We use this as our rotation vector
    local normalAngleX = 0
    local normalAngleY = 0
    local normalAngleZ = 1

    -- Perform a cross product with the rotation vector and the normalzied angle
    local normalX = (camNormalizedAngleY * normalAngleZ - camNormalizedAngleZ * normalAngleY)
    local normalY = (camNormalizedAngleZ * normalAngleX - camNormalizedAngleX * normalAngleZ)
    local normalZ = (camNormalizedAngleX * normalAngleY - camNormalizedAngleY * normalAngleX)

    -- Update the camera position based on the forwards/backwards speed
    camPosX = camPosX + freeModeAngleX * speed
    camPosY = camPosY + freeModeAngleY * speed
    camPosZ = camPosZ + freeModeAngleZ * speed

    -- Update the camera position based on the strafe speed
    camPosX = camPosX + normalX * strafespeed
    camPosY = camPosY + normalY * strafespeed
    camPosZ = camPosZ + normalZ * strafespeed
	
	--Store the velocity
	velocityX = (freeModeAngleX * speed) + (normalX * strafespeed)
	velocityY = (freeModeAngleY * speed) + (normalY * strafespeed)
	velocityZ = (freeModeAngleZ * speed) + (normalZ * strafespeed)

    -- Update the target based on the new camera position (again, otherwise the camera kind of sways as the target is out by a frame)
    camTargetX = camPosX + freeModeAngleX * 100
    camTargetY = camPosY + freeModeAngleY * 100
    camTargetZ = camPosZ + freeModeAngleZ * 100

    -- Set the new camera position and target
    setCameraMatrix ( camPosX, camPosY, camPosZ, camTargetX, camTargetY, camTargetZ )
end

local function freecamMouse (cX,cY,aX,aY)
	--ignore mouse movement if the cursor or MTA window is on
	--and do not resume it until at least 5 frames after it is toggled off
	--(prevents cursor mousemove data from reaching this handler)
	if isCursorShowing() or isMTAWindowActive() then
		mouseFrameDelay = 5
		return
	elseif mouseFrameDelay > 0 then
		mouseFrameDelay = mouseFrameDelay - 1
		return
	end
	
	-- how far have we moved the mouse from the screen center?
    local width, height = guiGetScreenSize()
    aX = aX - width / 2 
    aY = aY - height / 2
	
	--invert the mouse look if specified
	if options.invertMouseLook then
		aY = -aY
	end
	
    rotX = rotX + aX * options.mouseSensitivity * 0.01745
    rotY = rotY - aY * options.mouseSensitivity * 0.01745
	
	local PI = math.pi
	if rotX > PI then
		rotX = rotX - 2 * PI
	elseif rotX < -PI then
		rotX = rotX + 2 * PI
	end
	
	if rotY > PI then
		rotY = rotY - 2 * PI
	elseif rotY < -PI then
		rotY = rotY + 2 * PI
	end
    -- limit the camera to stop it going too far up or down - PI/2 is the limit, but we can't let it quite reach that or it will lock up
	-- and strafeing will break entirely as the camera loses any concept of what is 'up'
    if rotY < -PI / 2.05 then
       rotY = -PI / 2.05
    elseif rotY > PI / 2.05 then
        rotY = PI / 2.05
    end
end

function setFreecamEnabled (x, y, z)
	if freecamState then
		return false
	end
	
	if (x and y and z) then
	    setCameraMatrix ( x, y, z )
	end
	addEventHandler("onClientRender", root, freecamFrame)
	addEventHandler("onClientCursorMove", root, freecamMouse)
	freecamState = true
	return true
end

function setFreecamDisabled()
	if not freecamState then
		return false
	end
	
	velocityX,velocityY,velocityZ = 0,0,0
	speed = 0
	strafespeed = 0
	removeEventHandler("onClientRender", root, freecamFrame)
	removeEventHandler("onClientCursorMove", root, freecamMouse)
	freecamState = false
	return true
end
