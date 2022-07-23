local HOSTAGE_PAIN_SOUND_TIMEOUT = 2000

function onSomeoneDamaged(attacker, weapon, bodypart, loss)
	cancelEvent()

	if weapon == WEAPON_TEARGAS then
		-- Disable tear gas damage
		return
	end

	if source.type == "ped" and source:getData("isHostage") then
		if weapon == DAMAGE_BURNT then
			-- Do not let hostages catch fire
			setPedOnFire(source, false)
			return
		end

		-- Play hostage pain sounds
		-- Rate limit it to max once per 2s
		local ts = getElementData(source, "lastPainSoundTime")
		if ts and getTickCount() - ts < HOSTAGE_PAIN_SOUND_TIMEOUT then
			return
		end

		playSound3D(":csrw-sounds/sounds/hostage/hpain/hpain" .. math.random(1, 6) .. ".wav", getElementPosition(source))
		setElementData(source, "lastPainSoundTime", getTickCount(), false)
		return
	end

	-- Jeśli atakujący w momencie zadania obrażenia będzie miał inną broń (np. wyrzuci granat i zmieni slot) to calcDamage() pobierze zabierze złą ilość HP

	if attacker and source ~= attacker and attacker.type == "player" and not g_config["friendlyfire"] and attacker.team == source.team then
		return
	end

	if weapon ~= DAMAGE_EXPLOSION and weapon ~= DAMAGE_FALL and weapon ~= DAMAGE_TANK_GRENADE and weapon ~= WEAPON_GRENADE and weapon ~= WEAPON_MOLOTOV and weapon ~= DAMAGE_ROCKET and weapon ~= 20 and weapon ~= WEAPON_SATCHEL and weapon ~= DAMAGE_BURNT then
		if source == localPlayer or (getElementType(source) == "ped" and attacker == localPlayer) then
			calcDamage(source, attacker, bodypart, loss, weapon)
		end
	else
		if weapon == DAMAGE_FALL then
			-- Workaround fix for "Climbing over certain objects kills you, when you have high FPS"
			-- https://github.com/multitheftauto/mtasa-blue/issues/602
			if not attacker and bodypart == 3 then
				local task = {}
				task[1], task[2], task[3] = getPedTask(localPlayer, "primary", 3)
				if task[1] == "TASK_COMPLEX_JUMP" and task[2] == "TASK_SIMPLE_CLIMB" then
					return
				end

				if task[1] == "TASK_COMPLEX_JUMP" and task[2] == "TASK_COMPLEX_IN_AIR_AND_LAND" and task[3] == "TASK_SIMPLE_CLIMB" then
					return
				end
			end

			playSound3D(":csrw-sounds/sounds/player/damage" .. math.random(1, 3) .. ".wav", getElementPosition(source))

			-- double Falling Down damage
			loss = loss * 2
		end
		
		if source == localPlayer then
			csSetPedHealth(source, csGetPedHealth(source) - loss)
			if attacker and getElementType(attacker) == "player" then
				outputConsole("[DAMAGE TAKEN] From: " .. getPlayerName(attacker) .. " | Amount: " .. loss)
			else
				outputConsole("[DAMAGE TAKEN] Amount: " .. loss)
			end
		end
	end
end

function calcDamage(victim, attacker, bodypart, gtaLoss, gtaWeapon)
	if not attacker then return end
	local slot = getElementData(attacker, "currentSlot")
	if not slot then return end
	local weapon = getElementData(attacker, "wSlot" .. slot)
	if not weapon then return end

	local x, y, z = getElementPosition(victim)
	local x2, y2, z2 = getElementPosition(attacker)
	local distance = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)

	local damage = {
		healthInstant = tonumber(g_weapon[slot][weapon]["instantDamage"]),
		health = 0,
		armor = 0
	}

	local new = {
		health,
		armor
	}

	if not damage.healthInstant then
		if distance <= 1 then
			-- za blisko (gracz mógł zostać uderzony bronią lub alternatywnym atakiem CTRL+F)
			return
		end

		local hasArmor
		local tempDamage

		if csGetPedArmor(victim) > 0 then
			tempDamage = tonumber(g_weapon[slot][weapon][csGetBodyPartName(bodypart) .. "DamageArmor"])
			hasArmor = true

			if bodypart == 9 and g_player.items.helmet then
				tempDamage = tempDamage / 2 -- obrażenia o połowe mniejsze gdy ofiara posiada hełm
				g_player.items.helmet = false
				playSound(":csrw-sounds/sounds/player/bhit_helmet-1.wav")
			end
		else
			tempDamage = tonumber(g_weapon[slot][weapon][csGetBodyPartName(bodypart) .. "Damage"])
		end

		if not tempDamage or tempDamage == -1 then return
		elseif tempDamage == -2 then -- flaga: oryginalne obrażenia GTA
			tempDamage = math.ceil(gtaLoss)
		else
			--tempDamage = math.ceil(tempDamage / (distance / 4))
			tempDamage = math.ceil(tempDamage - distance / 2.5)
		end

		if hasArmor then
			damage.armor = tempDamage
			new.armor = csGetPedArmor(victim) - damage.armor
			if new.armor < 0 then
				damage.health = -new.armor
				new.armor = 0
			end
		else
			damage.health = tempDamage
		end
	else
		damage.health = damage.healthInstant
	end

	if victim == localPlayer then
		outputConsole("[DAMAGE TAKEN] From: " .. getPlayerName(attacker) .. " | Amount: " .. damage.health + damage.armor)
	end

	if damage.health > 0 then
		if getElementType(victim) == "ped" then
			damage.health = math.floor(damage.health / 2)
		end
		new.health = csGetPedHealth(victim) - damage.health

		if new.health < 0 then
			triggerServerEvent("csKillPed", resourceRoot, victim, attacker, gtaWeapon, bodypart)
			if bodypart == 9 then
				playSound(":csrw-sounds/sounds/player/headshot" .. math.random(1, 2) .. ".wav")
			end

			-- koniec i pomijanie zmiany daty pancerza po triggerze
			return
		else
			csSetPedHealth(victim, new.health)
		end
	end

	if new.armor then
		csSetPedArmor(victim, new.armor)
	end
end
addEventHandler("onClientPlayerDamage", localPlayer, onSomeoneDamaged)
addEventHandler("onClientPedDamage", root, onSomeoneDamaged) -- obliczane przez ofiare (ofiara sama sobie ustawia date) (lub atakującego jeśli atakuje się peda - np. zakładnika)

function csGetBodyPartName(partid)
	if partid >= 3 and partid <= 6 then
		return "torso"
	elseif partid == 7 or partid == 8 then
		return "legs"
	elseif partid == 9 then
		return "head"
	end
end

function csSetPedHealth(ped, health)
	setElementData(ped, "health", health)
end

function csGetPedHealth(ped)
	return getElementData(ped, "health") or 0
end

function csSetPedArmor(ped, armor)
	setElementData(ped, "armor", armor)
end

function csGetPedArmor(ped)
	return getElementData(ped, "armor") or 0
end
