function createHostages()
	local hostageSites = getElementsByType("hostagesite")

	if #hostageSites > 0 then
		outputServerLog("Hostagesites: " .. #hostageSites)

		local hostages = getElementsByType("hostage")
		for k, hostage in pairs(getElementsByType("hostage")) do
			local ped = createPed(50, getElementData(hostage, "posX"), getElementData(hostage, "posY"), getElementData(hostage, "posZ"), (getElementData(hostage, "rotZ") or 0) - 90)
			setElementData(hostage, "ped", ped)
			setElementData(ped, "health", 100)

			playAnimationWithWalking("CRACK", "crckidle3", ped)
			setElementFrozen(ped, true)
			setElementInterior(ped, getElementData(hostage, "interior") or 0)
		end

		if #hostages > 0 then
			for k, v in pairs(hostageSites) do
				local marker = createMarker(getElementData(v, "posX"), getElementData(v, "posY"), getElementData(v, "posZ"), "cylinder", getElementData(v, "size"), 255, 255, 255, 0, nil)
				setElementInterior(marker, getElementData(v, "interior") or 0)
				addEventHandler("onMarkerHit", marker, onHostageDelivered)
			end
			g_match.hostages = true
		end
	end
end

function removeHostages()
	for k, hostage in pairs(getElementsByType("hostage")) do
		local ped = getElementData(hostage, "ped")
		if isElement(ped) then
			destroyElement(ped)
		end
	end
end

function respawnHostages()
	removeHostages()

	local hostages = getElementsByType("hostage")
	for k, hostage in pairs(getElementsByType("hostage")) do
		local ped = createPed(50, getElementData(hostage, "posX"), getElementData(hostage, "posY"), getElementData(hostage, "posZ"), (getElementData(hostage, "rotZ") or 0) - 90)
		setElementData(hostage, "ped", ped)
		setElementData(ped, "health", 100)

		playAnimationWithWalking("CRACK", "crckidle3", ped)
		setElementFrozen(ped, true)
		setElementInterior(ped, getElementData(hostage, "interior") or 0)
	end
end

addEventHandler("onElementDataChange", root,
	function(data, oldValue)
		if data == "carryBy" and getElementType(source) == "ped" then
			local player = getElementData(source, "carryBy")
			if player then
				-- safety check
				if ((client and player ~= client) or getPlayerTeam(player) ~= g_team[2] or
					not isElementInRangeOfPoint(player, source.position.x, source.position.y, source.position.z, 5)) then
					setElementData(source, data, oldValue)
					return
				end

				g_player[player].carryingHost = source
				playAnimationWithWalking("GYMNASIUM", "gym_bike_fast", source)
				--setElementPosition(source, getElementPosition(player)) -- fix oświetlenia elementu
				setTimer(
					function(ped)
						exports.bone_attach:attachElementToBone(ped, getElementData(ped, "carryBy"), 3, -0.52, -0.5, -0.2, 0, 0, 0)
					end, 250, 1, source)
			end
		end
	end
)

function detachCarriedHostage(player) -- upadanie zakładnika na ziemie przy śmierci noszącego; dołączone do onPlayerQuit w main.lua
	if g_player[player].carryingHost then
		exports.bone_attach:detachElementFromBone(g_player[player].carryingHost)
		setElementPosition(g_player[player].carryingHost, getElementPosition(player))
		setElementRotation(g_player[player].carryingHost, getElementRotation(player))
		playAnimationWithWalking("CRACK", "crckidle3", g_player[player].carryingHost)

		setElementData(g_player[player].carryingHost, "carryBy", false)
		setElementData(g_player[player].carryingHost, "picking", false)

		g_player[player].carryingHost = nil
	end
end
addEventHandler("onPlayerWasted", root, function() detachCarriedHostage(source) end)

function onHostageDelivered(element, matchingDimensions)
	if getElementType(element) == "player" and matchingDimensions and g_player[element].carryingHost then
		givePlayerMoneyEx(element, 300) -- nagroda pieniężna za doniesienie zakładnika
		advert.ok(getText("msg_moneyAward", element) .. 300, v, true)

		destroyElement(g_player[element].carryingHost)
		g_player[element].carryingHost = nil
		onRoundEnd(2, 5)
	end
end