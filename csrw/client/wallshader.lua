-- originally made by Ren

local specularPower=2;
local effectMaxDistance=70
local wallShader = {}
local updateTimer

CWallShader = {}

--function enableWallEffect(element, r, g, b, a)
function CWallShader:enable(element, r, g, b, a)
	if not wallShader[element] then
		wallShader[element] = {}
		wallShader[element].color = {r, g, b, a or 1}
		updateElementShader(element)

		if not updateTimer then
			updateTimer = setTimer(updateElements, 100, 0)
		end
	end
end

--function disableWallEfect(element)
function CWallShader:disable(element)
	if wallShader[element] then
		destroyWallEffect(element)
		wallShader[element] = {}

		if #wallShader == 0 and updateTimer then
			killTimer(updateTimer)
		end
	end
end

function CWallShader:setColor(element, r, g, b, a)
	if wallShader[element] then
		wallShader[element].color = {r, g, b, a or 1}
		dxSetShaderValue( wallShader[element].shader, "sColorizePed", wallShader[element].color)
	end
end

function CWallShader:resetAll()
	if #wallShader > 0 and updateTimer then
		killTimer(updateTimer)
	end

	for k, v in pairs(wallShader) do
		CWallShader:disable(k)
	end
	wallShader = {}
end

function createWallEffect(element)
	if not wallShader[element].shader then
		wallShader[element].shader = dxCreateShader ( ":csrw-media/shaders/ped_wall.fx", 1, 0, true, "all" )
		if not wallShader[element].shader then
			outputDebugString("Can't create wall shader.", 2)
			return
		end

		dxSetShaderValue( wallShader[element].shader, "sColorizePed", wallShader[element].color)
		dxSetShaderValue( wallShader[element].shader, "sSpecularPower", specularPower)
		engineApplyShaderToWorldTexture ( wallShader[element].shader, "*", element )
		engineRemoveShaderFromWorldTexture( wallShader[element].shader,"muzzle_texture*", element )
		setElementAlpha(element, 254)
	end
end

function destroyWallEffect(element)
	if wallShader[element].shader then
		engineRemoveShaderFromWorldTexture(wallShader[element].shader, "*", element)
		destroyElement(wallShader[element].shader)
		setElementAlpha(element, 255)
		wallShader[element].shader = nil
	end
end

function updateElementShader(element)
	if isElementStreamedIn(element) then
		local hx, hy, hz = getElementPosition(element)            
		local cx, cy, cz = getCameraMatrix()
		local dist = getDistanceBetweenPoints3D(cx, cy, cz, hx, hy, hz)

		if dist > effectMaxDistance then
			destroyWallEffect(element)
		else
			local isItClear = isLineOfSightClear(cx, cy, cz, hx, hy, hz, true, false, false, true, false, true, false, element)
			if isItClear then
				destroyWallEffect(element)
			else
				createWallEffect(element)
			end
		end
	end
end

function updateElements()
	for k, v in pairs(wallShader) do
		updateElementShader(k)
	end
end

--addEventHandler("onClientElementStreamOut", root, function() CWallShader:disable(source) end) -- todo: to powinno blokować tylko na chwile, a nie permamentalnie
addEventHandler("onClientPlayerWasted", root, function() CWallShader:disable(source) end)
addEventHandler("onClientPedWasted", root, function() CWallShader:disable(source) end)
addEventHandler("onClientPlayerQuit", root, function() CWallShader:disable(source) end)
addEventHandler("onClientElementDestroy", root, function() CWallShader:disable(source) end)