-- jak jest to zrobione jako komenda to nie ma argumentu key i keyState

local progressTimer
local progress = 0
local progressX = 0
local gl_lastPlantTryTime
local gl_lastDefuseTryTime

-- podkładanie C4
function plantBomb(key, keyState)
	if not g_misc.roundStarted or not getElementData(localPlayer, "alive") then return end

	if keyState == "down" and getCurrentProgressBar() == "" then
		if not g_player.canChangeSlot then return end
		if isPedInVehicle(localPlayer) then return end
		if isCursorShowing() then return end
		if g_player.reloading then return end
		if getControlState("fire") or getControlState("aim_weapon") then return end
		if localPlayer.team ~= g_team[1] then return end

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

				if gl_lastPlantTryTime and getTickCount() - gl_lastPlantTryTime < 2000 then
					-- Rate limit bomb planting
					return
				end
				gl_lastPlantTryTime = getTickCount()

				setProgressBar("planting", 0.02)
				addEventHandler("onProgressBarEnd", resourceRoot, onBombPlanted)

				localPlayer.frozen = true
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

		localPlayer.frozen = false
		playAnimationWithWalking("CARRY", "crry_prtial")
		g_player.canChangeSlot = true
		removeEventHandler("onProgressBarEnd", resourceRoot, onBombPlanted)
	end	
end

function onBombPlanted(progressName)
	if progressName == "planting" then
		localPlayer.frozen = false
		stopAnimationWithWalking()
		updatePlayerControls()
		g_player.canChangeSlot = true

		triggerServerEvent("plantBomb", localPlayer)
		switchWeaponSlot("up")
		removeEventHandler("onProgressBarEnd", resourceRoot, onBombPlanted)
	end
end
--

-- rozbrajanie C4
function defuseBomb(key, keyState)
	if not getElementData(localPlayer, "alive") or g_player.reloading or localPlayer.team ~= g_team[2] then return end

	if keyState == "down" and getElementData(resourceRoot, "defusingBomb") == false then
		if not g_player.canChangeSlot then return end
		if isPedInVehicle(localPlayer) then return end
		if isCursorShowing() then return end
		if g_player.reloading then return end
		if getControlState("fire") or getControlState("aim_weapon") then return end

		local x, y, z = getElementPosition(localPlayer)
		for k, v in pairs(getElementsByType("object")) do
			if getElementData(v, "bomb") then
				local x2, y2, z2 = getElementPosition(v)
				if getDistanceBetweenPoints3D(x, y, z, x2, y2, z2) <= 1.4 then
					if gl_lastDefuseTryTime and getTickCount() - gl_lastDefuseTryTime < 2000 then
						-- Rate limit bomb defusing
						return
					end
					gl_lastDefuseTryTime = getTickCount()

					if g_player.items.defuser then
						-- defusing is faster with defuse kit
						setProgressBar("defusing", 0.012, true)
					else
						setProgressBar("defusing", 0.0055, true)
					end
					addEventHandler("onProgressBarEnd", resourceRoot, onBombDefused)

					localPlayer.frozen = true
					updatePlayerControls()
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
		localPlayer.frozen = false
		updatePlayerControls()

		setElementData(resourceRoot, "defusingBomb", false)
		stopAnimationWithWalking()
		g_player.canChangeSlot = true
		removeEventHandler("onProgressBarEnd", resourceRoot, onBombPlanted)
	end	
end

function onBombDefused(progressName)
	if progressName == "defusing" then
		localPlayer.frozen = false
		updatePlayerControls()
		stopAnimationWithWalking()
		g_player.canChangeSlot = true

		triggerServerEvent("defuseBomb", localPlayer)
		removeEventHandler("onProgressBarEnd", resourceRoot, onBombDefused)
	end
end
--

addEventHandler("onClientPlayerWasted", localPlayer,
	function()
		if getCurrentProgressBar() ~= "" then
			if localPlayer.team == g_team[1] then
				cancelPlant()
			elseif localPlayer.team == g_team[2] then
				cancelDefuse()
			end
		end
	end
)

addEventHandler("onClientPlayerQuit", localPlayer,
	function()
		if getCurrentProgressBar() == "defusing" and localPlayer.team == g_team[2] then
			setElementData(resourceRoot, "defusingBomb", false)
		end
	end
)
