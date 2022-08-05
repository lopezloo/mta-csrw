local HOSTAGE_DEFAULT_SKIN_ID = 50
local HOSTAGE_DEFAULT_INTERIOR_ID = 0

function createHostages()
	local hostageSites = getElementsByType("hostagesite")
	if #hostageSites == 0 then
		return
	end

	outputServerLog("Hostage sites count: " .. #hostageSites)
	respawnHostages()

	local hostages = getElementsByType("hostage")
	if #hostages > 0 then
		for k, v in pairs(hostageSites) do
			local marker = createMarker(getElementData(v, "posX"), getElementData(v, "posY"), getElementData(v, "posZ"), "cylinder", getElementData(v, "size"), 255, 255, 255, 0, nil)
			setElementInterior(marker, getElementData(v, "interior") or 0)
			addEventHandler("onMarkerHit", marker, onHostageDelivered)
		end
		g_match.hostages = true
	end
end

function removeHostages()
	for _, hostage in pairs(getElementsByType("hostage")) do
		local ped = getElementData(hostage, "ped")
		if isElement(ped) then
			destroyElement(ped)
		end
	end
end

function respawnHostages()
	removeHostages()

	local hostages = getElementsByType("hostage")
	for _, hostage in pairs(getElementsByType("hostage")) do
		local skin = hostage:getData("skin")
		if skin == false then
			skin = HOSTAGE_DEFAULT_SKIN_ID
		end
		
		local ped = createPed(skin, getElementData(hostage, "posX"), getElementData(hostage, "posY"), getElementData(hostage, "posZ"), (getElementData(hostage, "rotZ") or 0) - 90)
		
		hostage:setData("ped", ped)
		ped:setData("health", 100)
		ped:setData("isHostage", true)

		playAnimationWithWalking("CRACK", "crckidle3", ped)
		ped.frozen = true

		local int = hostage:getData("interior")
		if int == false then
			int = HOSTAGE_DEFAULT_INTERIOR_ID
		end

		ped.interior = int
	end
end

-- @todo: refactor this into event
addEventHandler("onElementDataChange", root,
	function(data, oldValue)
		if data == "carryBy" and source.type == "ped" then
			local player = source:getData("carryBy")
			if player then
				if not isRoundStarted() then
					source:setData(data, oldValue)
					return
				end

				if player.health == 0 or player.team ~= g_team[2] then
					source:setData(data, oldValue)
					return
				end

				if ((client and player ~= client) or
					not isElementInRangeOfPoint(player, source.position.x, source.position.y, source.position.z, 5)) then
					source:setData(data, oldValue)
					return
				end

				g_player[player].carryingHost = source
				playAnimationWithWalking("GYMNASIUM", "gym_bike_fast", source)
				--setElementPosition(source, getElementPosition(player)) -- fix ped lighting
				
				setTimer(
					function(ped)
						exports.bone_attach:attachElementToBone(ped, getElementData(ped, "carryBy"), 3, -0.52, -0.5, -0.2, 0, 0, 0)
					end, 250, 1, source
				)

				player.walkingStyle = MOVE_PLAYER_F
			end
		end
	end
)

-- Drop carried hostage on the ground
function detachCarriedHostage(player)
	if not g_player[player].carryingHost then
		return
	end

	if isElement(g_player[player].carryingHost) then
		exports.bone_attach:detachElementFromBone(g_player[player].carryingHost)
		setElementPosition(g_player[player].carryingHost, getElementPosition(player))
		setElementRotation(g_player[player].carryingHost, getElementRotation(player))
		playAnimationWithWalking("CRACK", "crckidle3", g_player[player].carryingHost)

		setElementData(g_player[player].carryingHost, "carryBy", false)
		setElementData(g_player[player].carryingHost, "picking", false)
	end

	g_player[player].carryingHost = nil
	player.walkingStyle = MOVE_PLAYER_M
end

addEventHandler("onPlayerWasted", root,
	function()
		detachCarriedHostage(source)
	end
)

function onHostageDelivered(element, matchingDimensions)
	if not isRoundStarted() then
		return
	end

	if element.type == "player" and matchingDimensions and g_player[element].carryingHost then
		-- nagroda pieniężna za doniesienie zakładnika
		givePlayerMoneyEx(element, 300)
		advert.ok(getText("msg_moneyAward", element) .. 300, v, true)

		g_player[element].carryingHost:setData("rescued", true)
		detachCarriedHostage(element)
		toggleControl(element, "sprint", isWeaponSlotSprintable(element.weaponSlot))

		-- @todo?
		toggleControl(element, "jump", true)
		toggleControl(element, "crouch", true)
		toggleControl(element, "walk", true)

		element.frozen = false

		onRoundEnd(2, 5)
	end
end

addEvent("dropHostage", true)
addEventHandler("dropHostage", root,
	function()
		if not client or client ~= source then return end

		if not isRoundStarted() then
			return
		end

		if not g_player[client].carryingHost then
			return
		end

		detachCarriedHostage(client)
	end
)
