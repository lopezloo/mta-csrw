-- Wyrzucanie broni z wykorzystaniem fizyki GTA
local weaponCount = 0
local weapons = {} -- xyzString, slot, weapon, totalAmmo, clipAmmo

addEvent("dropPhysicWeapon", true)
addEventHandler("dropPhysicWeapon", root,
	function(slot, weapon, totalAmmo, clipAmmo)
		if client and client == source then
			weaponCount = weaponCount + 1
			csTakeWeapon(client, slot, weapon, dontChangeSlot)
			triggerClientEvent("dropClientPhysicWeapon", root, client, slot, weapon, totalAmmo, clipAmmo, weaponCount)
		end
	end
)

function onPhysicWeaponTaken(slot, weapon, totalAmmo, clipAmmo)
	if client and client == source then
		--outputChatBox("siema tu serwer lap bron " .. weapon .. " ze slotu " .. slot .. " z totalAmmo = " .. tostring(totalAmmo) .. "; clipAmmo = " .. tostring(clipAmmo), client)
		csGiveWeapon(client, tonumber(slot), tonumber(weapon), tonumber(totalAmmo), tonumber(clipAmmo), false)
	end
end
addEvent("onPhysicWeaponTaken", true)
addEventHandler("onPhysicWeaponTaken", root, onPhysicWeaponTaken)

addEvent("syncThrowedWeapon", true)
addEventHandler("syncThrowedWeapon", root,
	function(uniqueID, xyzString, slot, weapon, totalAmmo, clipAmmo, rotz, int)
		if client and client == source then
			triggerClientEvent("syncThrowedWeaponStepTwo", resourceRoot, uniqueID, xyzString)
			weapons[uniqueID] = {xyzString = xyzString, slot = slot, weapon = weapon, totalAmmo = totalAmmo, clipAmmo = clipAmmo, rotz = rotz, int = int}
		end
	end
)

function syncGroundWeapons(player)
	triggerClientEvent("syncGroundWeapons", player, weapons)
end

function destroyGroundWeapons()
	weapons = {}
	weaponCount = 0
end
