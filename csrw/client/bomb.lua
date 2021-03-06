-- jak jest to zrobione jako komenda to nie ma argumentu key i keyState

local progressTimer
local progress = 0
local progressX = 0

-- podkładanie C4
function plantBomb(key, keyState)
	if not getElementData(localPlayer, "alive") then return end

	if keyState == "down" and not isCursorShowing() and getCurrentProgressBar() == "" then
		local inBombsite = false
		for k, v in pairs(getElementsByType("marker")) do
			if isElementWithinMarker(localPlayer, v) then
				local id = getElementID(v)
				if id == "A" or id == "B" or id == "C" then
					inBombsite = true
					break
				end
			end
		end
		
		if inBombsite then
			local currentSlot = getElementData(localPlayer, "currentSlot")
			if not currentSlot or not g_playerWeaponData.current then return end
			if g_weapon[currentSlot][g_playerWeaponData.current]["weaponID"] == "-6" then
				setProgressBar("planting", 0.02)
				addEventHandler("onProgressBarEnd", resourceRoot, onBombPlanted)

				setElementFrozen(localPlayer, true)
				playAnimationWithWalking("BOMBER", "BOM_Plant_Loop")
				g_player.canChangeSlot = false
			end
		end
	elseif getCurrentProgressBar() == "planting" then
		cancelPlant()
	end
end
bindKey("mouse1", "both", plantBomb)

function cancelPlant()
	if getCurrentProgressBar() == "planting" then
		stopProgressBar()

		setElementFrozen(localPlayer, false)
		playAnimationWithWalking("CARRY", "crry_prtial")
		g_player.canChangeSlot = true
		removeEventHandler("onProgressBarEnd", resourceRoot, onBombPlanted)
	end	
end

function onBombPlanted(progressName)
	if progressName == "planting" then
		setElementFrozen(localPlayer, false)
		toggleControl("fire", true)
		toggleControl("aim_weapon", true)
		stopAnimationWithWalking()
		g_player.canChangeSlot = true

		triggerServerEvent("plantBomb", resourceRoot, localPlayer)
		switchWeaponSlot("up")
		removeEventHandler("onProgressBarEnd", resourceRoot, onBombPlanted)
	end
end
--

-- rozbrajanie C4
function defuseBomb(key, keyState)
	if not getElementData(localPlayer, "alive") or g_player.reloading or getPlayerTeam(localPlayer) ~= g_team[2] then return end

	if keyState == "down" and getElementData(resourceRoot, "defusingBomb") == false then
		local x, y, z = getElementPosition(localPlayer)
		for k, v in pairs(getElementsByType("object")) do
			if getElementData(v, "bomb") then
				local x2, y2, z2 = getElementPosition(v)
				if getDistanceBetweenPoints3D(x, y, z, x2, y2, z2) <= 1.4 then
					if g_player.items.defuser then
						setProgressBar("defusing", 0.012, true)
					else
						setProgressBar("defusing", 0.0055, true) -- bez zestawu do rozbrajania
					end
					addEventHandler("onProgressBarEnd", resourceRoot, onBombDefused)

					setElementFrozen(localPlayer, false)
					toggleControl("fire", false)
					toggleControl("aim_weapon", false)
					playAnimationWithWalking("BOMBER", "BOM_Plant_Loop")
					g_player.canChangeSlot = false
					setElementData(resourceRoot, "defusingBomb", true)
					break
				end
			end
		end
	else
		cancelDefuse()	
	end
end
bindKey("E", "both", defuseBomb)

function cancelDefuse()
	if getCurrentProgressBar() == "defusing" then
		stopProgressBar()
		
		setElementFrozen(localPlayer, false)
		toggleControl("fire", true)
		toggleControl("aim_weapon", true)
		setElementData(resourceRoot, "defusingBomb", false)
		stopAnimationWithWalking()
		g_player.canChangeSlot = true
		removeEventHandler("onProgressBarEnd", resourceRoot, onBombPlanted)
	end	
end

function onBombDefused(progressName)
	if progressName == "defusing" then
		setElementFrozen(localPlayer, false)
		toggleControl("fire", true)
		toggleControl("aim_weapon", true)
		stopAnimationWithWalking()
		g_player.canChangeSlot = true

		triggerServerEvent("defuseBomb", resourceRoot, localPlayer)
		removeEventHandler("onProgressBarEnd", resourceRoot, onBombDefused)
	end
end
--

addEventHandler("onClientPlayerWasted", localPlayer,
	function()
		if getCurrentProgressBar() ~= "" then
			if getPlayerTeam(localPlayer) == g_team[1] then cancelPlant()
			elseif getPlayerTeam(localPlayer) == g_team[2] then cancelDefuse() end
		end
	end
)

addEventHandler("onClientPlayerQuit", localPlayer,
	function()
		if getCurrentProgressBar() == "defusing" and getPlayerTeam(localPlayer) == g_team[2] then
			setElementData(resourceRoot, "defusingBomb", false)
		end
	end
)