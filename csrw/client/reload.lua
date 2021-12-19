local reloadAnimation = {
	-- zbiór, animacja normalna, animacja podczas kucania
	[2] = {"COLT45", "colt45_reload", "colt45_crouchreload"}, -- pistolety
	[3] = {"BUDDY", "buddy_reload", "buddy_crouchreload"}, -- shotguny
	[4] = {"UZI", "UZI_reload", "UZI_crouchreload"}, -- maszynowe
	[5] = {"PYTHON", "python_reload", "python_crouchreload"}, -- karabiny
	[6] = {"BUDDY", "buddy_reload", "buddy_crouchreload"} -- rifle
}
local duckState

addCommandHandler("Reload weapon",
	function()
		--if getElementData(localPlayer, "reloading") >= 1 or not getElementData(localPlayer, "alive") or getControlState("fire") or getControlState("aim_weapon") or isElementInWater(localPlayer) or not isPedOnGround(localPlayer) then
		if g_player.reloading or not getElementData(localPlayer, "alive") or getControlState("fire") or (getControlState("aim_weapon") and not CFirstPerson.enabled)or isPedDoingTask(localPlayer, "TASK_SIMPLE_USE_GUN") or getPedSimplestTask(localPlayer) ~= "TASK_SIMPLE_PLAYER_ON_FOOT" then
			-- nie można przeładowywać jak już się przeładowuje, jest się nie żywym lub się celuje, jest się we wodzie lub powietrzu
			-- proptip: TASK_SIMPLE_USE_GUN wyłącza się dopiero gdy ped skończy całkowicie celować (animacja celowania skończy się w 100%)
			return false
		end
		--local task = getPedSimplestTask(localPlayer)
		--if ((task == "TASK_SIMPLE_JUMP" or task == "TASK_SIMPLE_IN_AIR") and not task == "TASK_SIMPLE_USE_GUN" and not doesPedHaveJetPack(localPlayer)) then return end
		
		local csSlot = getElementData(localPlayer, "currentSlot")
		local csWeapon = g_playerWeaponData[csSlot].weapon
		--if getPedAmmoInClip(localPlayer) ~= tonumber(getWeaponAttribute(csSlot, csWeapon, "clip")) and getPedAmmoInClip(localPlayer) ~= getPedTotalAmmo(localPlayer) then
		if g_playerWeaponData[csSlot].ammo > 0 and g_playerWeaponData[csSlot].clip ~= tonumber(g_weapon[csSlot][csWeapon]["clip"]) then
			-- nie można przeładowywać jak jest pełny magazynek lub jak nie ma zapasowej amunicji
			--outputChatBox("if " .. getPedAmmoInClip(localPlayer) .. " ~= " .. tonumber(getWeaponAttribute(csSlot, csWeapon, "clip")))
			onClientPlayerReloading(csSlot)
		end		
	end
)
bindKey("r", "down", "Reload weapon")

function onClientPlayerReloading(slot)
	local gtaSlot = getPedWeaponSlot(localPlayer)
	duckState = isPedDucked(localPlayer) 
	
	if not duckState then
		setTimer(playAnimationWithWalking, 50, 1, reloadAnimation[gtaSlot][1], reloadAnimation[gtaSlot][2])
	else
		setTimer(playAnimationWithWalking, 50, 1, reloadAnimation[gtaSlot][1], reloadAnimation[gtaSlot][3])
	end

	-- Animacja nadana podczas ładowania gta (induced = false) zadziała tylko gdy gracz się porusza lub kuca (wtedy go podniesie i zadziała lol)
	outputDebugString("Weapon reloading.")
	
	toggleControl("aim_weapon", false)
	toggleControl("fire", false)
	toggleControl("crouch", false)
	toggleControl("jump", false)
	-- induced = true = przeładowywanie wywołane przez skrypt reload (przycisk R); false = naturalnie po skończeniu się amunicji w magazynku;

	g_player.reloading = true
	
	-- @todo: play reload sound

	-- czas dodania nowej amunicji może być różny na różnych fpsach
	-- 1100 ms to za mało.. wtedy jeszcze gta nie daje nowej amunicji; 1800 jest ok bo minimalnie wyprzedza ten czas
	local tim = 1700
	if gtaSlot == 2 then tim = 1000
	elseif gtaSlot == 4 then tim = 1300 end
	
	setTimer(triggerEvent, tim, 1, "onClientPlayerReloadingEnd", localPlayer, slot)
end

function onClientPlayerReloadingEnd(slot)
	if not getElementData(source, "alive") then
		-- nie wykonuje się jak gracz jest nieżywy
		return false
	end

	stopAnimationWithWalking()
	if not g_playerWeaponData[slot] then
		outputDebugString("ERROR: Problem with reloading weapon (slot " .. tostring(slot) .. ")")
		return
	end

	local clipCapacity = tonumber(g_weapon[slot][ g_playerWeaponData[slot].weapon ]["clip"])
	if clipCapacity > g_playerWeaponData[slot].ammo then
		-- wrzucanie resztek (całego ammo) do magazynka
		clipCapacity = g_playerWeaponData[slot].ammo
		g_playerWeaponData[slot].ammo = 0
	else
		g_playerWeaponData[slot].ammo = g_playerWeaponData[slot].ammo - clipCapacity + g_playerWeaponData[slot].clip
	end
	g_playerWeaponData[slot].clip = clipCapacity

	setTimer(
		function(source)
			--setElementData(source, "reloading", 0)
			toggleControl("aim_weapon", true)
			toggleControl("crouch", true)
			toggleControl("jump", true)

			setTimer(
				function()
					if getControlState("aim_weapon") then
						-- jeśli celuje
						toggleControl("fire", true)
						onClientAim("induced", "down")
					end
				end, 100, 1)

			if duckState then
				setDucked(true)
			end

			if CFirstPerson.enabled then
				setControlState("aim_weapon", true)
			end
		end, 50, 1, source)

	g_player.reloading = false
	return true
end
addEvent("onClientPlayerReloadingEnd")
addEventHandler("onClientPlayerReloadingEnd", localPlayer, onClientPlayerReloadingEnd)

function setDucked(state)
	if state ~= isPedDucked(localPlayer) then
		setControlState("crouch", true)
		setTimer(setControlState, 100, 0, "crouch", false)
		return true
	end
	return false
end
