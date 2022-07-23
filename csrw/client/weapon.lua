local bombs = getWeaponsWithFlag("BOMB")
DEF_BOMB = {-1, -1}
if #bombs > 0 then
	DEF_BOMB = {bombs[1][1], bombs[1][2]}
else
	outputDebugString("WARNING: Can't find weapon with the BOMB flag.")
end

local delay
g_playerWeaponData = {} -- informacje o broniach lokalnego gracza
-- g_playerWeaponData[slot] = {weapon, ammo, clip}

function onTrySlotChange(key, keyState)
	--getElementData(localPlayer, "reloading") >= 1
	--if not g_player.canChangeSlot or isPedInVehicle(localPlayer) or isCursorShowing() or g_player.reloading or not getElementData(localPlayer, "alive") or getControlState("fire") or getControlState("aim_weapon") or (getPedSimplestTask(localPlayer) ~= "TASK_SIMPLE_PLAYER_ON_FOOT" and getPedSimplestTask(localPlayer) ~= "TASK_SIMPLE_SWIM") then
	if not g_player.canChangeSlot or isPedInVehicle(localPlayer) or g_player.reloading or not getElementData(localPlayer, "alive") or getControlState("fire") or (isCursorShowing() and not CFirstPerson.enabled) or (getControlState("aim_weapon") and not CFirstPerson.enabled) or (getPedSimplestTask(localPlayer) ~= "TASK_SIMPLE_PLAYER_ON_FOOT" and getPedSimplestTask(localPlayer) ~= "TASK_SIMPLE_SWIM") then
		-- nie można przeładowywać jak już się przeładowuje, jest się nie żywym lub się celuje (bez FPS), jest się we wodzie lub powietrzu
		return false
	else
		local state = "up"
		if key == "mouse_wheel_down" then 
			state = "down"
		end
		switchWeaponSlot(state)
	end
end

bindKey("mouse_wheel_up", "down", onTrySlotChange)
bindKey("mouse_wheel_down", "down", onTrySlotChange)

function onBindTrySlotChange(key, keyState)
	if g_player.canChangeSlot and not isPedInVehicle(localPlayer) and not g_player.reloading and getElementData(localPlayer, "alive") and (not isCursorShowing() or CFirstPerson.enabled) and getElementData(localPlayer, "currentSlot") ~= tonumber(key) and getElementData(localPlayer, "wSlot" .. key) ~= false and not delay and not getControlState("fire") and not getControlState("aim_weapon") and (getPedSimplestTask(localPlayer) == "TASK_SIMPLE_PLAYER_ON_FOOT" or getPedSimplestTask(localPlayer) == "TASK_SIMPLE_SWIM") then
		if g_playerWeaponData[tonumber(key)] then
			changeWeaponSlot(tonumber(key))
			playSound(":csrw-sounds/sounds/weapons/change/slot" .. key .. ".wav")
			delay = true
			setTimer(function() delay = false end, 100, 1)
		end
	end
end

for i=1, 9 do
	bindKey(tostring(i), "down", onBindTrySlotChange)
end

function switchWeaponSlot(state, baseSlot, slot, ignoreDelay, noSound, deleteHerToo) -- baseSlot - slot od ktorego zaczyna sie rekurencja
	if delay and not ignoreDelay then
		return
	end

	--outputChatBox("switchWeaponSlot(" .. tostring(state) .. ", " .. tostring(baseSlot) .. ", " .. tostring(slot))
	if not baseSlot and slot then
		-- error
		return
	end

	if not baseSlot then
		baseSlot = getElementData(localPlayer, "currentSlot")
	end

	if not baseSlot then
		return
	end

	if not slot then
		slot = baseSlot
	end

	local newSlot
	if state == "up" then
		newSlot = slot + 1
		if newSlot > #g_weapon then
			newSlot = 1
		end

	elseif state == "down" then
		newSlot = slot - 1
		if newSlot <= 0 then
			newSlot = #g_weapon
		end
	end
	
	if newSlot == baseSlot then -- algorytm zapętla się (gracz ma tylko 1 broń)
		--outputChatBox("c: switchWeaponSlot: Algorym sie zapetla")
		return
	end

	-- if getElementData(localPlayer, "wSlot" .. newSlot) ~= false then
	if g_playerWeaponData[newSlot] then
		changeWeaponSlot(newSlot, baseSlot, deleteHerToo)
		if not noSound then
			playSound(":csrw-sounds/sounds/weapons/change/slot" .. newSlot .. ".wav")
		end
		delay = true
		setTimer(function() delay = false end, 100, 1)
	
	else
		switchWeaponSlot(state, baseSlot, newSlot, nil, noSound, deleteHerToo)
	end
end

function changeWeaponSlot(slot, oldSlot, deleteWeapon)
	if not g_playerWeaponData[slot] then
		return
	end

	if not oldSlot then
		oldSlot = getElementData(localPlayer, "currentSlot")
	end

	for k, v in pairs(getElementsByType("colshape")) do
		if isElementWithinColShape(localPlayer, v) then
			w = getElementData(v, "groundWeapon")
			if w then
				w = split(w, ":")
				w[2], w[3] = tonumber(w[2]), tonumber(w[3])
				if w[2] == slot then
					setElementData(localPlayer, "currentColshape", v)
					startDrawingWeapon(w[2], w[3]) -- ta broń, którą wyrzuca a nie którą podnosi (w[3])!
					break
				
				else
					stopDrawingWeapon()
					break
				end
			end
		end
	end

	local newWeapon = g_playerWeaponData[slot].weapon
	local gtaWeapon = g_weapon[slot][newWeapon]["weaponID"]
	local gtaSlot, skilName, skill
	if gtaWeapon and tonumber(gtaWeapon) > 0 then
		gtaWeapon = tonumber(gtaWeapon)
		gtaSlot = getSlotFromWeapon( gtaWeapon )
		skillName = getWeaponSkillID( gtaWeapon )
		skill = g_weapon[slot][newWeapon]["skill"]
		if skill then
			skill = getWeaponSkillAmount(skill)
		end
	end

	local clientside
	if gtaSlot and getPedWeapon(localPlayer, gtaSlot) == tonumber(g_weapon[slot][newWeapon]["weaponID"]) and (not skillName or not skill or getPedStat(localPlayer, skillName) == skill) then
		clientside = true
		if deleteWeapon then
			triggerServerEvent("csTakeCurrentWeaponTrigger", localPlayer)
		end

		-- gracz ma odpowiednie staty dla nowej broni
		setPedWeaponSlot(localPlayer, gtaSlot)
		outputDebugString("Changed slot CLIENTSIDE (new gta slot: " .. gtaSlot .. ", weapon: " .. newWeapon .. ", slot: " .. slot .. ")")
		setElementData(localPlayer, "currentSlot", slot) -- 1 trigger (serwer dowiaduje się o zmianie slota i podczepia starą broń)

		if oldSlot == DEF_BOMB[1] and g_playerWeaponData[oldSlot].weapon == DEF_BOMB[2] then -- jeśli stara broń to bomba
			toggleControl("fire", true)
			toggleControl("jump", true)
			toggleControl("crouch", true)
		end

		if gtaWeapon > 0 and getSlotFromWeapon(gtaWeapon) == 1 then
			-- Enable sprinting with melee weapons
			toggleControl("sprint", true)
			toggleControl("fire", true)
		else
			toggleControl("sprint", false)
			--if gtaWeapon > 0 and not getControlState("aim_weapon") and getSlotFromWeapon(gtaWeapon) ~= 8 then -- jeśli nie celuje i nie ma granata
			if gtaWeapon > 0 and getSlotFromWeapon(gtaWeapon) ~= 8 then -- usunięcie warunku o nie celowaniu ze względu na tryb FPS
				toggleControl("fire", false)
			end
		end
	end

	local oldAmmo, oldClip -- jeśli oldAmmo & oldClip jest nil to serwer usunie obecną broń przy triggerze na server_changeWeaponToSlot
	if not deleteWeapon then
		oldAmmo = g_playerWeaponData[oldSlot].ammo
		oldClip = g_playerWeaponData[oldSlot].clip
	else
		--outputDebugString("Deleting weapon.")
		g_playerWeaponData[oldSlot] = nil
	end
	g_playerWeaponData.current = newWeapon

	if not clientside then
		--outputDebugString("Triggering slot change to server (old slot: " .. oldSlot .. ", old ammo: " .. tostring(oldAmmo) .. ", old clip: " .. tostring(oldClip) .. ")")
		triggerServerEvent("server_changeWeaponToSlot", localPlayer, oldSlot, slot, oldAmmo, oldClip) -- tymczasowy trigger
	end
end

local sprintAimableWeapons = {
	"ak-47", "m4",
	"shotgun", "combat shotgun", -- combat = spaz
	"mp5",
}
local timer_updateWeaponAimMovingSkill
function onClientAim(key, keyState)
	if not getElementData(localPlayer, "alive") then
		return
	end

	local gtaWep = getPedWeapon(localPlayer)
	if getSlotFromWeapon(gtaWep) == 1 or getSlotFromWeapon(gtaWep) == 8 or (g_player.reloading and key ~= "induced") then
		-- blokowanie celowania tylko z bronią palną i przy przeładowywyaniu
		return
	end

	if keyState == "down" and getElementData(localPlayer, "alive") then
		local slot = getElementData(localPlayer, "currentSlot")
		if not slot then
			return
		end

		if g_weapon[slot][g_playerWeaponData[slot].weapon]["weaponID"] ~= "-6" then -- inne niż c4
			toggleControl("fire", true)

			--[[if not isPedDucked(localPlayer) then
				for k, v in pairs(sprintAimableWeapons) do
					if getWeaponIDFromName(v) == getPedWeapon(localPlayer) then
						timer_updateWeaponAimMovingSkill = setTimer(updateWeaponAimMovingSkill, 5000, 0)
						break
					end
				end
			end]]--

			if getPedWeapon(localPlayer) == 34 and getPedSimplestTask(localPlayer) == "TASK_SIMPLE_PLAYER_ON_FOOT" then
				-- Player is zooming sniper
				-- Play sniper zoom sound
				playSound(":csrw-sounds/sounds/weapons/zoom.wav")

				-- Hide objects attached to player
				for k, v in pairs(getElementsByType("object")) do
					if getElementData(v, "attachedPlayer") == localPlayer then
						setElementAlpha(v, 0)
					end
				end

				local hostage = getPickedHostage()
				if hostage then
					hostage.alpha = 0
				end
				-- ^ będą niewidoczne dopóki gracz nie puści przycisku, nawet jeśli przestanie celować
			end
		end
	else
		--[[if isTimer(timer_updateWeaponAimMovingSkill) then killTimer(timer_updateWeaponAimMovingSkill) end

		local skillName = getWeaponSkillID( getPedWeapon(localPlayer) )
		if skillName and getPedStat(localPlayer, skillName) == 1 then
			triggerServerEvent("switchWeaponAimMovingSkill", resourceRoot, false) -- przywracanie właściwego skilla
		end]]--

		toggleControl("fire", false)

		if gtaWep == 34 then -- sniper gta id
			for k, v in pairs(getElementsByType("object")) do
				if getElementData(v, "attachedPlayer") == localPlayer then
					setElementAlpha(v, 255)
				end
			end

			local hostage = getPickedHostage()
			if hostage then
				hostage.alpha = 255
			end
		end		
	end
end

--[[function updateWeaponAimMovingSkill()
	if getControlState("aim_weapon") then
		if not isPedDucked(localPlayer) and getPedStat(localPlayer, getWeaponSkillID(getPedWeapon(localPlayer))) > 1 and (getControlState("forwards") or getControlState("backwards") or getControlState("left") or getControlState("right")) then
			triggerServerEvent("switchWeaponAimMovingSkill", resourceRoot, true)
		elseif getPedStat(localPlayer, getWeaponSkillID(getPedWeapon(localPlayer))) == 1 and not (getControlState("forwards") or getControlState("backwards") or getControlState("left") or getControlState("right")) then
			triggerServerEvent("switchWeaponAimMovingSkill", resourceRoot, false)
		end
	end
end]]--

function onSomeoneShot()
	local slot = getElementData(source, "currentSlot")
	if not slot then
		return
	end

	local weapon = getElementData(source, "wSlot" .. slot)
	if not weapon then
		return
	end

	if not g_player.flashed then
		local sound = g_weapon[slot][weapon]["shotSound"]
		if sound then
			playSound3D(":csrw-sounds/sounds/weapons/" .. g_weapon[slot][weapon]["shotSound"], getElementPosition(source))
		end
	end

	if source == localPlayer then
		g_playerWeaponData[slot].clip = g_playerWeaponData[slot].clip - 1

		if g_playerWeaponData[slot].clip == 0 then
			local gtaWeaponID = getPedWeapon(localPlayer)

			if g_playerWeaponData[slot].ammo == 0 then -- broń się skończyła
				outputDebugString("No ammo in weapon, deleting.")
				setTimer(
					function()
						if getPedTotalAmmo(localPlayer) > 0 then
							switchWeaponSlot("up", nil, nil, nil, nil, true) -- zmiana slota + usuwanie broni
						else
							switchWeaponSlot("up") -- tylko zmiana slota (broń się sama usunęła)
						end
					end, 50, 1)
			else
				-- weapon require reloading
				if gtaWeaponID == WEAPON_GRENADE or gtaWeaponID == WEAPON_TEARGAS or gtaWeaponID == WEAPON_MOLOTOV or gtaWeaponID == WEAPON_SATCHEL then
					-- do not reload grenades
					--setElementData(localPlayer, "wSlot" .. slot .. "Ammo", getPedAmmoInClip(localPlayer) - 1)
					-- jaki jest sens aktualizacji liczby granatów do zmiennej ?
				else
					--onClientPlayerReloading(false) -- przeładowanie wywołane w połowie naturalnie (bo GTA też wtedy zmienia ammo)
					-- bez timera ostatni strzał u gracza nielokalnego jest ucinany przez wystartowanie animacji
					onClientPlayerReloading(slot)
				end
			end

			if gtaWeaponID == WEAPON_SNIPER then -- sniper
				onClientAim("induced", "up") -- ponowne pokazywanie obiektów przyczepionych do gracza (bo po strzale niekoniecznie musi skończyć celowanie)
			end
		end
	end
end
addEventHandler("onClientPlayerWeaponFire", root, onSomeoneShot)
--addEventHandler("onClientPedWeaponFire", root, onSomeoneShot)

addEvent("updateWeaponData", true)
addEventHandler("updateWeaponData", root,
	function(slot, weapon, ammo, clip, hideHer)
		if not slot then
			return
		end

		if slot == "clearAll" then
			g_playerWeaponData = {}
			return
		end

		if not weapon then
			-- usuwanie danych o slocie
			g_playerWeaponData[slot] = nil
			return
		end

		if not g_playerWeaponData[slot]
			then g_playerWeaponData[slot] = {}
		end

		g_playerWeaponData[slot].weapon = weapon

		if ammo and clip then
			g_playerWeaponData[slot].ammo = ammo
			g_playerWeaponData[slot].clip = clip
		end
		
		if not hideHer then
			-- broń nie została schowana do ekwipunku
			g_playerWeaponData.current = weapon
		end
	end
)
