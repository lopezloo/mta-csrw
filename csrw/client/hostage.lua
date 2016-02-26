local hostage = {
	tryingToPick = nil,
	picked = nil,
	renderedHostages = {}
}

--[[
	TODO:
		* zrobić aby tylko 1 gracz mógł brać tego samego hosta w jednym czasie [100%]
		* optymalizacja
]]

function pickHostage(key, keyState)
	if not getElementData(localPlayer, "alive") or getPlayerTeam(localPlayer) == g_team[1] then return end

	if keyState == "down" and not isCursorShowing() and getCurrentProgressBar() == "" and not hostage.tryingToPick and not hostage.picked then
		local nearHost
		for k, v in pairs(getElementsByType("hostage")) do
			local ped = getElementData(v, "ped")
			if isElement(ped) and not getElementData(ped, "carryBy") and not getElementData(ped, "picking") then
				local x, y, z = getElementPosition(ped)
				local x2, y2, z2 = getElementPosition(localPlayer)
				if getDistanceBetweenPoints3D(x, y, z, x2, y2, z2) <= 1 then
					nearHost = ped
					break
				end
			end
		end

		if nearHost then
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
		if getElementType(source) == "ped" then
			if data == "carryBy" and isElementStreamedIn(source) then
				if getElementData(source, data) then
					--setElementPosition(source, getElementPosition(getElementData(source, "carryBy")))
					table.insert(hostage.renderedHostages, source)
					if #hostage.renderedHostages == 1 then
						addEventHandler("onClientPreRender", root, renderHostages)
					end
				else
					table.remove(hostage.renderedHostages, source)
					if #hostage.renderedHostages == 0 then
						removeEventHandler("onClientPreRender", root, renderHostages)
					end
				end
			elseif data == "health" and getElementData(source, data) ~= 100 then
				playSound3D(":csrw-sounds/sounds/hostage/hpain/hpain" .. math.random(1, 6) .. ".wav", getElementPosition(source))
			end
		end
	end
)

addEventHandler("onClientElementDestroy", root,
	function()
		if getElementType(source) == "ped" then
			local k = table.find(hostage.renderedHostages, source)
			if k then
				table.remove(hostage.renderedHostages, k)
				if #hostage.renderedHostages == 0 then
					removeEventHandler("onClientPreRender", root, renderHostages)
				end
			end
		end
	end
)

function renderHostages()
	for k, v in pairs( hostage.renderedHostages ) do
		setPedAnimationProgress(v, "gym_bike_fast", 0.7)
	end
end

addEventHandler("onClientRoundEnd", root,
	function()
		hostage.picked = nil
		hostage.tryingToPick = nil
	end
)