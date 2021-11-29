local hudShowing

local csFont = dxCreateFont(":csrw-media/fonts/ccwstrike.ttf", 40)
if not csFont then
	outputChatBox("WARNING: I can't load HUD font! Using default.")
	csFont = "default-bold"
end

local csFontSize = 0.00041666666*sX -- 0.6

local render = { -- 1440x900
	height =  { 0.94888888888*sY, 0.98888888888*sY }, -- 854, 890
	hpIcon = 0.01845238095*sX, -- 31, 854, 61, 890

	hp = { 0.04236111111*sX, 0.12361111111*sX }, -- 61, 854[height], 178, 890

	armorIcon = 0.21805555555*sX, -- 314, 854, 344, 890
	armor = { 0.23888888888*sX, 0.32013888888*sX }, -- 344, 854, 461, 890

	timeIcon = 0.44652777777*sX, -- 643, 854, 673, 890
	time = { 0.46736111111*sX, 0.56111111111*sX, 0.56111111111*sX }, -- 673, 854, 808, 890

	ammoClip = { 0.80833333333*sX, 0.87083333333*sX }, -- 1164, 854, 1254, 890
	ammoLine = { 0.82152777777*sX, 0.94166666666*sX }, -- 1183, 854, 1356, 890
	ammoTotal = { 0.89236111111*sX, 0.96805555555*sX }, -- 1285, 854, 1394, 890

	money = { 0.85902777777*sX, 0.89*sY, 0.975*sX, 0.93*sY } -- 1237, 801, 1404, 837 -- ikona i kasa
}

local color = tocolor(255, 130, 0, 240)

function setHUDColor(r, g, b, a) -- todo: komenda do zmiany koloru hudu
	if r and g and b and a then
		local c = tocolor(r, g, b, a)
		if c then
			color = c
		end
	end
end

function showHUD(show)
	if show ~= hudShowing then
		hudShowing = show
		if hudShowing then
			addEventHandler("onClientRender", root, renderHUD)
		else
			removeEventHandler("onClientRender", root, renderHUD)
		end
	end
end

function renderHUD()
	local target = getCameraTarget()
	if not target then -- szybki fix ze względu na fps (wtedy target = nil)
		if getElementHealth(localPlayer) > 0 then
			target = localPlayer
		end
	end

	if target then
		if getElementType(target) == "vehicle" and getPedOccupiedVehicle(localPlayer) == target then
			target = localPlayer
		end
		
		local hp = getElementData(target, "health")
		if not hp or hp == "headshot" or hp < 0 then hp = 0 end

		dxDrawText("b", render.hpIcon, render.height[1], 0, 0, color, csFontSize, csFont, "left", "top", false, false, false, false, false)
		dxDrawText(math.floor(hp), render.hp[1], render.height[1], render.hp[2], render.height[2], color, csFontSize, csFont, "right", "top", false, false, false, false, false)

		dxDrawText("a", render.armorIcon, render.height[1], 0, 0, color, csFontSize, csFont, "left", "top", false, false, false, false, false)
		dxDrawText(math.floor(getElementData(target, "armor") or 0), render.armor[1], render.height[1], render.armor[2], render.height[2], color, csFontSize, csFont, "right", "top", false, false, false, false, false)

		dxDrawText("e", render.timeIcon, render.height[1], 0, 0, color, csFontSize, csFont, "left", "top", false, false, false, false, false)
		local seconds = getElementData(resourceRoot, "roundTimeSeconds")
		if seconds then
			if seconds < 10 then
				seconds = "0" .. tostring(seconds)
			end
			dxDrawText(getElementData(resourceRoot, "roundTimeMinutes") .. ":" .. seconds, render.time[1], render.height[1], render.time[3], render.height[2], color, csFontSize, csFont, "right", "top", false, false, false, false, false)
		end

		if target == localPlayer then
			if getPedWeaponSlot(target) >= 2 and getPedWeaponSlot(target) <= 7 then
				local slot = getElementData(target, "currentSlot")
				if g_playerWeaponData[slot] then
					dxDrawText(g_playerWeaponData[ slot ].clip, render.ammoClip[1], render.height[1], render.ammoClip[2], render.height[2], color, csFontSize, csFont, "right", "top", false, false, false, false, false)
					dxDrawText("|", render.ammoLine[1], render.height[1], render.ammoLine[2], render.height[2], color, csFontSize, csFont, "center", "top", false, false, false, false, false)
					dxDrawText(g_playerWeaponData[ slot ].ammo, render.ammoTotal[1], render.height[1], render.ammoTotal[2], render.height[2], color, csFontSize, csFont, "left", "top", false, false, false, false, false)
				end
			
			elseif getPedWeaponSlot(target) == 1 then
				dxDrawText("J", render.ammoLine[1], render.height[1], render.ammoLine[2], render.height[2], color, csFontSize, csFont, "center", "top", false, false, false, false, false)
			
			elseif getPedWeaponSlot(target) == 8 then
				local slot = getElementData(target, "currentSlot")
				if g_playerWeaponData[slot] then
					local icon = "G" -- smoke

					if getPedWeapon(target) == 16 then -- grenade
						icon = "H"
					elseif getPedWeapon(target) == 18 then -- molotov
						icon = "M"
					elseif g_weapon[slot][ g_playerWeaponData.current ]["objectID"] == "-2" then -- flashbang
						icon = "P"
					end
					
					dxDrawText(g_playerWeaponData[ slot ].clip .. icon, render.ammoLine[1], render.height[1], render.ammoLine[2], render.height[2], color, csFontSize, csFont, "center", "top", false, false, false, false, false)
				end

			elseif getPedWeaponSlot(target) == 0 and g_playerWeaponData.current then
				if g_weapon [getElementData(target, "currentSlot") ][ g_playerWeaponData.current ]["flag"] == "BOMB" then
					dxDrawText("j", render.ammoLine[1], render.height[1], render.ammoLine[2], render.height[2], color, csFontSize, csFont, "center", "top", false, false, false, false, false)
				end
			end
		end

		dxDrawText("$", render.money[1], render.money[2], render.money[3], render.money[4], color, csFontSize, csFont, "left", "top", false, false, false, false, false)
		dxDrawText(math.floor(getElementData(target, "money") or 0), render.money[1], render.money[2], render.money[3], render.money[4], color, csFontSize, csFont, "right", "top", false, false, false, false, false)	
	end
end
