local hostage = {
	tryingToPick = nil,
	picked = nil,
	renderedHostages = {},

	lastPickTryTime = nil,

	tryingToDrop = nil,
	lastDropTryTime = nil
}

local function pickHostage(key, keyState)
	if not g_misc.roundStarted or not localPlayer:getData("alive") or localPlayer.team ~= g_team[2] then return end

	if keyState == "down" and getCurrentProgressBar() == "" and not hostage.tryingToPick and not hostage.picked then
		if not g_player.canChangeSlot then return end
		if isPedInVehicle(localPlayer) then return end
		if isCursorShowing() then return end
		if g_player.reloading then return end
		if getControlState("fire") or getControlState("aim_weapon") then return end

		local nearHost
		for k, v in pairs(getElementsByType("hostage")) do
			local ped = getElementData(v, "ped")
			if isElement(ped) and not ped:getData("carryBy") and not ped:getData("picking") and not ped:getData("rescued") then
				local x, y, z = getElementPosition(ped)
				local x2, y2, z2 = getElementPosition(localPlayer)
				if getDistanceBetweenPoints3D(x, y, z, x2, y2, z2) <= 1 then
					nearHost = ped
					break
				end
			end
		end

		if nearHost then
			if hostage.lastPickTryTime and getTickCount() - hostage.lastPickTryTime < 2000 then
				-- Rate limit hostage picking
				return
			end

			hostage.lastPickTryTime = getTickCount()
			hostage.tryingToPick = nearHost
			setProgressBar("host", 0.015)
			addEventHandler("onProgressBarEnd", resourceRoot, onHostagePicked)
			localPlayer.frozen = true
			playAnimationWithWalking("BOMBER", "BOM_Plant_Loop")
			nearHost:setData("picking", true)
			updatePlayerControls()
		end
	
	elseif getCurrentProgressBar() == "host" then
		stopAnimationWithWalking()
		localPlayer.frozen = false
		hostage.tryingToPick:setData("picking", false)
		hostage.tryingToPick = nil
		stopProgressBar()
		updatePlayerControls()
		removeEventHandler("onProgressBarEnd", resourceRoot, onHostagePicked)
	end
end
bindKey("E", "both", pickHostage)

local function dropHostage(key, keyState)
	if not g_misc.roundStarted or not localPlayer:getData("alive") or localPlayer.team ~= g_team[2] then return end
	if not hostage.picked then return end
	if hostage.tryingToPick then return end

	if keyState == "down" and getCurrentProgressBar() == "" and not hostage.tryingToDrop then
		if not g_player.canChangeSlot then return end
		if isPedInVehicle(localPlayer) then return end
		if isCursorShowing() then return end
		if g_player.reloading then return end
		if getControlState("fire") or getControlState("aim_weapon") then return end

		if hostage.lastDropTryTime and getTickCount() - hostage.lastDropTryTime < 2000 then
			-- Rate limit hostage picking
			return
		end

		hostage.lastDropTryTime = getTickCount()
		hostage.tryingToDrop = true

		setProgressBar("host-drop", 0.015)
		addEventHandler("onProgressBarEnd", resourceRoot, onHostageDropped)
		localPlayer.frozen = true
		playAnimationWithWalking("BOMBER", "BOM_Plant_Loop")
		updatePlayerControls()
	
	elseif getCurrentProgressBar() == "host-drop" then
		stopAnimationWithWalking()
		localPlayer.frozen = false
		hostage.tryingToDrop = false
		stopProgressBar()
		updatePlayerControls()
		removeEventHandler("onProgressBarEnd", resourceRoot, onHostageDropped)
	end
end
bindKey("H", "both", dropHostage)

function onHostagePicked(progressName)
	if progressName ~= "host" then return end

	stopAnimationWithWalking()
	localPlayer.frozen = false
	setElementData(hostage.tryingToPick, "carryBy", localPlayer)
	hostage.picked = hostage.tryingToPick
	hostage.tryingToPick = nil
	removeEventHandler("onProgressBarEnd", resourceRoot, onHostagePicked)
	-- nie ma sensu resetowania daty "picking" tutaj (reset dopiero po stronie serwera przy upadku hosta)

	toggleControl("sprint", false)
	toggleControl("jump", false)
	toggleControl("crouch", false)
	toggleControl("walk", false)
end

function onHostageDropped(progressName)
	if progressName ~= "host-drop" then return end

	stopAnimationWithWalking()
	localPlayer.frozen = false

	hostage.picked = nil
	hostage.tryingToDrop = false

	triggerServerEvent("dropHostage", localPlayer)
	removeEventHandler("onProgressBarEnd", resourceRoot, onHostageDropped)
end

addEventHandler("onClientElementDataChange", root,
	function(data, oldValue)
		if source.type ~= "ped" then
			return
		end

		if data == "carryBy" and isElementStreamedIn(source) then
			if source:getData(data) then
				--setElementPosition(source, getElementPosition(getElementData(source, "carryBy")))
				table.insert(hostage.renderedHostages, source)
				if #hostage.renderedHostages == 1 then
					addEventHandler("onClientPreRender", root, renderCarriedHostages)
				end
			
			else
				for k, v in pairs(hostage.renderedHostages) do
					if v == source then
						table.remove(hostage.renderedHostages, k)
						if #hostage.renderedHostages == 0 then
							removeEventHandler("onClientPreRender", root, renderCarriedHostages)
						end
						break
					end
				end
			end
		end
	end
)

addEventHandler("onClientElementDestroy", root,
	function()
		if source.type == "ped" then
			local k = table.find(hostage.renderedHostages, source)
			if k then
				table.remove(hostage.renderedHostages, k)
				if #hostage.renderedHostages == 0 then
					removeEventHandler("onClientPreRender", root, renderCarriedHostages)
				end
			end
		end
	end
)

function renderCarriedHostages()
	for _, v in pairs(hostage.renderedHostages) do
		-- @TODO: It can be done via setPedAnimationSpeed instead
		setPedAnimationProgress(v, "gym_bike_fast", 0.7)
	end
end

addEventHandler("onClientRoundEnd", root,
	function()
		hostage.picked = nil
		hostage.tryingToPick = nil
	end
)

addEventHandler("onClientPedHitByWaterCannon", root,
	function()
		if source.type == "ped" and source:getData("isHostage") then
			cancelEvent()
		end
	end
)

addEventHandler("onClientPedHeliKilled", root,
	function()
		if source.type == "ped" and source:getData("isHostage") then
			cancelEvent()
		end
	end
)

function getPickedHostage()
	return hostage.picked
end

function isPlayerCarryingHostage()
	return hostage.picked ~= nil
end

function isPlayerPickingUpHostage()
	return hostage.tryingToPick ~= nil
end

addEventHandler("onClientElementStreamIn", root,
	function()
		if source.type == "ped" and source:getData("isHostage") then
			fixPedLighting(source)
		end
	end
)
