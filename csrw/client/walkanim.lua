addEventHandler("onClientElementStreamIn", root,
	function()
		if getElementType(source) == "player" or getElementType(source) == "ped" then
			syncPedAnimation(source)
		end
	end
)

addEventHandler("onClientElementDataChange", root,
	function(name)
		if name == "anim" and (getElementType(source) == "player" or getElementType(source) == "ped") then
			if getElementData(source, "anim") == false then
				setPedAnimation(source, "ped", "facanger")
				setTimer(setPedAnimation, 50, 1, source)
			else
				syncPedAnimation(source)
			end
		end
	end
)

function syncPedAnimation(ped)
	local a = getElementData(ped, "anim")
	if a ~= false and (ped.type == "ped" or ped:getData("alive")) then
		anim = {}
		anim = split(a, ":")
		--outputChatBox("c syncPedAnimation: " .. tostring(anim[1]))
		
		local interruptable = true
		
		-- 200ms - zamrożenie na ten czas (podnosi peda z kucaka na animacji bomby (wtf, tylko na niej))
		local time = 200
		if ped.type == "ped" and ped:getData("isHostage") and anim[1] == "CRACK" and anim[2] == "crckidle3" then
			time = -1
			interruptable = false
		end

		setPedAnimation(ped, anim[1], anim[2], time, true, false, interruptable, true)
	
		if ped.type == "ped" and ped:getData("isHostage") and anim[1] == "CRACK" and anim[2] == "crckidle3" then
			setTimer(
				function()
					setPedAnimationSpeed(ped, "crckidle3", 0)
					setPedAnimationProgress(ped, "crckidle3", 1)
				end, 50, 1
			)
		end

		if a == "BOMBER:BOM_Plant_Loop" then
			-- zsynchronizowany dźwięk podkładania / rozbrajania C4 / brania hostów
			local distance = 60
			if getPlayerTeam(ped) == g_team[1] then
				sound = "weapons/c4/c4_plant"
			
			elseif getPlayerTeam(ped) == g_team[2] then
				if #getElementsByType("hostage") > 0 then
					local hostSounds = {
						"letsdoit", "letshurry", "okletsgo"
					}

					sound = "hostage/huse/" .. hostSounds[math.random(1, 3)]
					distance = 10
				else
					sound = "weapons/c4/c4_disarm"
					distance = 50
				end
			end

			local x, y, z = getElementPosition(ped)
			setSoundMaxDistance( playSound3D(":csrw-sounds/sounds/" .. sound .. ".wav", x, y, z), distance)
		end
	end
end
