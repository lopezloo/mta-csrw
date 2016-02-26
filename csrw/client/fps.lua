CFirstPerson = {
	enabled,
}

--[[local CFirstPersonLocal = {} -- cała klasa niedostępna z zewnątrz

-- tylko do testu
setFPSLimit(70)
addEventHandler("onClientResourceStop", root, function() setCursorAlpha(255) end)
--

function CFirstPersonLocal:enable()
	if not CFirstPerson.enabled then
		-- kontrolki
		--toggleControl("aim_weapon", false)
		setControlState("aim_weapon", true)

		-- kamera
		 -- ak47
		--attachElements(getCamera(), localPlayer, -0.03, -0.8, 0.7) -- c4

		addEventHandler("onClientPreRender", root, CFirstPersonLocal.updateRotation)
		addEventHandler("onClientKey", root, CFirstPersonLocal.activateControls)
		CFirstPerson.enabled = true
	end
end
addEventHandler("onClientPlayerSpawn", localPlayer, CFirstPersonLocal.enable)

function CFirstPersonLocal:disable()
	if CFirstPerson.enabled then
		--toggleControl("aim_weapon", true)
		--setControlState("aim_weapon", false)
		detachElements(getCamera(), localPlayer)
		removeEventHandler("onClientPreRender", root, CFirstPersonLocal.updateFPSRotation)
		removeEventHandler("onClientKey", root, CFirstPersonLocal.activateControls)
		CFirstPerson.enabled = false
	end
end
addEventHandler("onClientPlayerWasted", localPlayer, CFirstPersonLocal.disable)

addCommandHandler("fps",
	function()
		if not CFirstPerson.enabled then
			initFPS()
		else
			setCameraTarget(localPlayer)
			disableFPS()
		end
		outputChatBox("FPS mode: " .. tostring(CFirstPerson.enabled))
	end
)

	Koncept #1:
		Osobny ped do celowania na osi gora - dol. Synchronizowanie

function CFirstPersonLocal:updateRotation()
	if not isMTAWindowActive() then

		-- tylko do testu
		setCursorAlpha(0)
		showCursor(true)
		attachElements(getCamera(), localPlayer, -0.03, -0.1, 0.65)
		--

		local x, y = getCursorPosition()
		if y < 0.5 then y = 0.5 end
		localPlayer.rotation = Vector3(360*y+90, 0, -360*x)
		--dxDrawText("Rotation: " .. localPlayer.rotation.x .. ", " .. localPlayer.rotation.y .. ", " .. localPlayer.rotation.z, 300, 300)

		-- przeskakiwanie kursora miedzy krawedziami na osi X
		if x == 1 then
			setCursorPosition(0, y*sY)
		elseif x == 0 then
			setCursorPosition(sX-1, y*sY)
		end
	end
end

-- konrola postaci
local controls = {
	w = "forwards",
	d = "right",
	a = "left",
	mouse1 = "fire",
	c = "crouch",
}

function CFirstPersonLocal:activateControls(state)
	if not isMTAWindowActive() then
		if controls[self] then
			setControlState(controls[self], state)
		end
	end
end]]--