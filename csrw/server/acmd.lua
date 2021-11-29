-- Admin commands

-- /endround
-- Ends round
addCommandHandler("endround",
	function(player)
		if not hasObjectPermissionTo(player, "function.kickPlayer") then
			return
		end

		outputChatBox(" ** Round was ended by admin " .. getPlayerName(player))
		onRoundEnd(3, 7)
	end
)

-- /givemoney [player] [amount]
-- Gives money to specified player
addCommandHandler("givemoney",
	function(playerSource, _, playerNameTo, amount)
		if not hasObjectPermissionTo(playerSource, "function.banPlayer") then
			return
		end

		if not playerNameTo then
			outputChatBox("USAGE: /givemoney [player] [amount]")
			return
		end

		local playerTo = getPlayerFromName(playerNameTo)
		if not playerTo then
			outputChatBox("ERROR: Player which such name not found.")
			return
		end

		if not amount then
			outputChatBox("USAGE: /givemoney [player] [amount]")
			return
		end

		local amount = tonumber(amount)
		if not amount or amount < 0 then
			outputChatBox("ERROR: Invalid amount.")
			return
		end

		outputChatBox(" ** Admin " .. getPlayerName(playerSource) .. " gave $" .. amount .. " to player " .. getPlayerName(playerTo))
		givePlayerMoneyEx(playerTo, amount)
	end
)
