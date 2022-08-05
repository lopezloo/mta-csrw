-- Weapon drop - server

local weaponCount = 0
local weapons = {} -- xyzString, slot, weapon, totalAmmo, clipAmmo

-- @todo: set dimensions?

addEvent("dropPhysicWeapon", true)
addEventHandler("dropPhysicWeapon", root,
	function(slot, weapon, totalAmmo, clipAmmo, groundZ)
		if not client or client ~= source then
			return
		end

		if not g_match.settings.weaponDrop and not (slot == DEF_BOMB[1] and weapon == DEF_BOMB[2]) then
			return
		end

		if client.health == 0 then
			-- Player is dead
			return
		end

		if client.team ~= g_team[1] and client.team ~= g_team[2] then
			-- Player is not in any game team
			return
		end

		-- Check if valid weapon
		if not g_weapon[slot] or not g_weapon[slot][weapon] then
			return
		end

		-- Check if this weapon can be dropped
		if g_weapon[slot][weapon]["droppable"] == "false" or g_weapon[slot][weapon]["objectID"] == nil or tonumber(g_weapon[slot][weapon]["objectID"]) <= 0 then
			return
		end

		-- Check if player actually have this weapon
		if g_playerWeaponData[client] and g_playerWeaponData[client][slot].weapon ~= weapon then
			return
		end

		-- Validate ammo
		if totalAmmo ~= nil then
			if totalAmmo > g_playerWeaponData[client][slot].ammo then
				-- Player can report less but it shouldn't be higher
				return
			end

			if totalAmmo < 0 then return end
		end

		if clipAmmo ~= nil then
			if clipAmmo > g_playerWeaponData[client][slot].clip then
				-- Player can report less but it shouldn't be higher
				return
			end

			if clipAmmo < 0 then return end
		end

		if math.abs(client.position.z - groundZ) > 10 then
			-- Ground Z position doesn't look correct, just make it player Z position to be safe
			groundZ = client.position.z
		end

		-- weaponCount aka uniqueID
		weaponCount = weaponCount + 1

		-- Take dropped weapon from player
		csTakeWeapon(client, slot, weapon, false)

		-- Init ground weapon data on server
		-- position will be later corrected by call from the same client
		weapons[weaponCount] = {
			xyzString = client.position.x .. ";" .. client.position.y .. ";" .. groundZ,
			dropState = 0, -- waiting for call from the same client
			owner = client,
			slot = slot,
			weapon = weapon,
			totalAmmo = totalAmmo,
			clipAmmo = clipAmmo,
			rotz = 0,
			int = client.interior
		}

		-- Announce weapon drop to players (including this client)
		triggerClientEvent("dropClientPhysicWeapon", root, client, slot, weapon, weaponCount)
	end
)

function createGroundWeapon(slot, weapon, x, y, z, rz, int)
	if not g_weapon[slot] or not g_weapon[slot][weapon] then
		return
	end

	local totalAmmo = tonumber(g_weapon[slot][weapon].ammo)
	local totalClip = tonumber(g_weapon[slot][weapon].clip)

	-- weaponCount aka uniqueID
	weaponCount = weaponCount + 1
	weapons[weaponCount] = {
		xyzString = x .. ";" .. y .. ";" .. z,
		dropState = 1,
		owner = nil,
		slot = slot,
		weapon = weapon,
		totalAmmo = totalAmmo,
		clipAmmo = totalClip,
		rotz = rz,
		int = int
	}
end

function onPhysicWeaponTaken(uniqueID)
	if not client or client ~= source then
		return
	end

	if client.health == 0 then
		-- Player is dead
		return
	end

	if client.team ~= g_team[1] and client.team ~= g_team[2] then
		-- Player is not in any game team
		return
	end

	outputChatBox("onPhysicWeaponTaken " .. uniqueID, client)

	uniqueID = tonumber(uniqueID)
	if not uniqueID then
		outputChatBox("onPhysicWeaponTaken nope 1", client)
		return
	end

	local weapon = weapons[uniqueID]
	if not weapon then
		outputChatBox("onPhysicWeaponTaken nope 2", client)
		return
	end

	if weapon.int ~= client.interior then
		-- Interiors doesn't match
		outputChatBox("onPhysicWeaponTaken nope int", client)
		return
	end

	if not g_weapon[weapon.slot] or not g_weapon[weapon.slot][weapon.weapon] then
		outputChatBox("onPhysicWeaponTaken nope 3", client)
		-- Invalid weapon
		return
	end
	
	if (weapon.slot == DEF_BOMB[1] and weapon.weapon == DEF_BOMB[2]) and client.team ~= g_team[1] then
		-- Only TT player can take bomb
		outputChatBox("onPhysicWeaponTaken nope 4 Only TT player can take bomb", client)
		return
	end

	local pos = split(weapon.xyzString, ";")
	outputChatBox("onPhysicWeaponTaken dropstate " .. weapon.dropState, client)

	local dist = getDistanceBetweenPoints3D(client.position, pos[1], pos[2], pos[3])
	if weapon.dropState == 0 and dist >= 50 then
		-- Positions doesn't match, weapon seems to be far away from player
		outputChatBox("onPhysicWeaponTaken nope pos", client)
		return
	end

	if weapon.dropState == 1 and dist >= 5 then
		-- Positions doesn't match, weapon seems to be far away from player
		outputChatBox("onPhysicWeaponTaken nope pos 2", client)
		return
	end

	outputChatBox("onPhysicWeaponTaken suc", client)
	
	triggerClientEvent("removeGroundWeapon", resourceRoot, uniqueID)

	-- Give player taken weapon
	csGiveWeapon(client, weapon.slot, weapon.weapon, weapon.totalAmmo, weapon.clipAmmo, false)
	weapons[uniqueID] = nil
end
addEvent("onPhysicWeaponTaken", true)
addEventHandler("onPhysicWeaponTaken", root, onPhysicWeaponTaken)

addEvent("syncThrowedWeapon", true)
addEventHandler("syncThrowedWeapon", root,
	function(uniqueID, xyzString, rotz)
		if not client or client ~= source then
			return
		end

		if not weapons[uniqueID] then
			-- Invalid weapon
			return
		end

		local weapon = weapons[uniqueID]
		if weapon.dropState ~= 0 then
			-- Weapon is already synced
			return
		end

		if weapon.owner ~= client then
			-- Player can't sync this weapon position
			-- because he isn't owner
			return
		end

		if not g_match.settings.weaponDrop and not (weapon.slot == DEF_BOMB[1] and weapon.weapon == DEF_BOMB[2]) then
			-- Weapon drop is disabled in config
			-- (but drop bomb even if weapon drop is disabled)
			return
		end

		local pos = split(xyzString, ";")
		if type(pos) ~= "table" or #pos ~= 3 then
			-- Invalid position (should be "X;Y;Z" string)
			return
		end

		local oldPos = split(weapon.xyzString, ";")
		local dist = getDistanceBetweenPoints3D(oldPos[1], oldPos[2], oldPos[3], pos[1], pos[2], pos[3])
		outputChatBox("syncThrowedWeapon " .. dist)
		if dist >= 50 then
			return
		end

		-- Commented out for now, in theory player could be dead far away or something
		-- if getDistanceBetweenPoints3D(client.position, pos[1], pos[2], pos[3]) >= 50 then
			-- return
		-- end

		weapons[uniqueID].xyzString = xyzString
		weapons[uniqueID].rotz = rotz
		weapons[uniqueID].dropState = 1

		outputChatBox("syncThrowedWeapon suc")
		triggerClientEvent("syncThrowedWeaponStepTwo", resourceRoot, uniqueID, xyzString, rotz)
	end
)

function syncGroundWeapons(player, reset)
	triggerClientEvent("syncGroundWeapons", player, weapons, reset)
end

function destroyGroundWeapons()
	weapons = {}
	weaponCount = 0
end

function loadGroundWeaponsFromMap()
	for _, v in pairs(getElementsByType("weapon")) do
		local x, y, z = tonumber(v:getData("posX")), tonumber(v:getData("posY")), tonumber(v:getData("posZ"))
		--local rx, ry, rz = tonumber(v:getData("rotX")), tonumber(v:getData("rotY")), tonumber(v:getData("rotZ"))
		local rz = tonumber(v:getData("rotZ"))

		--if not rx then rx = 90 end
		--if not ry then ry = 0 end
		if not rz then rz = 0 end

		local int = tonumber(v:getData("interior")) or 0
		-- local dimension = tonumber(v:getData("dimension")) or 0

		local weaponSlot = tonumber(v:getData("weaponSlot"))
		local weaponID = tonumber(v:getData("weaponID"))

		if weaponSlot and weaponID and x and y and z then
			createGroundWeapon(weaponSlot, weaponID, x, y, z, rz, int)
		end
	end
end
