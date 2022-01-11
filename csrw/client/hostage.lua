local hostage = {
	tryingToPick = nil,
	picked = nil,
	renderedHostages = {},

	lastPickTryTime = nil
}

function pickHostage(key, keyState)
	if not g_misc.roundStarted or not localPlayer:getData("alive") or localPlayer.team ~= g_team[2] then return end

	if keyState == "down" and not isCursorShowing() and getCurrentProgressBar() == "" and not hostage.tryingToPick and not hostage.picked then
		if not g_player.canChangeSlot then return end
		if isPedInVehicle(localPlayer) then return end
		if isCursorShowing() then return end
		if g_player.reloading then return end
		if getControlState("fire") or getControlState("aim_weapon") then return end
		if g_player.team ~= g_team[2] then return end

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
			setElementFrozen(localPlayer, true)
			playAnimationWithWalking("BOMBER", "BOM_Plant_Loop")
			setElementData(nearHost, "picking", true)
		end
	
	elseif getCurrentProgressBar() == "host" then
		stopAnimationWithWalking()
		setElementFrozen(localPlayer, false)
		setElementData(hostage.tryingToPick, "picking", false)
		hostage.tryingToPick = nil
		stopProgressBar()
		removeEventHandler("onProgressBarEnd", resourceRoot, onHostagePicked)
	end
end
bindKey("E", "both", pickHostage)

function onHostagePicked(progressName)
	if progressName == "host" then
		stopAnimationWithWalking()
		setElementFrozen(localPlayer, false)
		setElementData(hostage.tryingToPick, "carryBy", localPlayer)
		hostage.picked = hostage.tryingToPick
		hostage.tryingToPick = nil
		removeEventHandler("onProgressBarEnd", resourceRoot, onHostagePicked)
		-- nie ma sensu resetowania daty "picking" tutaj (reset dopiero po stronie serwera przy upadku hosta)		
	end
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
	for k, v in pairs(hostage.renderedHostages) do
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

addEventHandler("onClientElementStreamIn", root,
	function()
		if source.type == "ped" and source:getData("isHostage") then
			fixPedLighting(source)
		end
	end
)
