local S = core.get_translator("folks")

local DENJI_BUYS = {
	crown = {
		item = "forgotten_monsters:spider_eye_poisonous",
		payout = 15
	},
	sword = {
		item = "forgotten_monsters:undead_heart",
		payout = 25
	},
	payout_item = "currency:minegeld"
}

local function show_denji_gui(player_name)
	local formspec = 
		"size[8.5,6]" ..
		"background[0,0;8.5,6;techblox_terminal_bg.png;true]" .. 
		"box[0,0;8.5,0.1;#a832a4]" ..
		"label[0.5,0.5;" .. core.colorize("#e066ff", "DENJI - THE RESOURCE TRADER") .. "]" ..
		"box[0.5,0.9;7.5,0.02;#ffffff15]" ..
		
		-- Row 1: Poisonous Spider Eye
		"box[0.5,1.3;7.5,1.3;#ffffff03]" ..
		"item_image[0.8,1.4;1,1;" .. DENJI_BUYS.crown.item .. "]" ..
		"label[2.0,1.5;" .. core.colorize("#ffffff", "Sell Poisonous Eye") .. "]" ..
		"label[2.0,2.0;" .. core.colorize("#00ff00", "Payout: " .. DENJI_BUYS.crown.payout .. " Minegeld") .. "]" ..
		"button[5.6,1.5;2,0.6;sell_crown;Sell Stack]" ..

		-- Row 2: Undead Heart
		"box[0.5,2.8;7.5,1.3;#ffffff03]" ..
		"item_image[0.8,2.9;1,1;" .. DENJI_BUYS.sword.item .. "]" ..
		"label[2.0,3.0;" .. core.colorize("#ffffff", "Sell Undead Heart") .. "]" ..
		"label[2.0,3.5;" .. core.colorize("#00ff00", "Payout: " .. DENJI_BUYS.sword.payout .. " Minegeld") .. "]" ..
		"button[5.6,3.0;2,0.6;sell_sword;Sell Stack]" ..
		
		"button_exit[3.2,5.0;2,0.6;quit;Close]"

	core.show_formspec(player_name, "folks:merchant_denji", formspec)
end

local function handle_denji_sale(player, player_name, inv, target_config)
	local check_stack = ItemStack(target_config.item)
	if check_stack:is_empty() or not inv:contains_item("main", check_stack) then
		core.chat_send_player(player_name, core.colorize("#ff3333", "[Denji]: You don't have that item on you!"))
		return
	end

	local total_sold = 0
	for amt = 99, 1, -1 do
		local test_stack = ItemStack(target_config.item .. " " .. amt)
		if inv:contains_item("main", test_stack) then
			total_sold = amt
			break
		end
	end

	if total_sold > 0 then
		inv:remove_item("main", ItemStack(target_config.item .. " " .. total_sold))
		local total_payout = total_sold * target_config.payout
		local payout_stack = ItemStack(DENJI_BUYS.payout_item .. " " .. total_payout)

		if inv:room_for_item("main", payout_stack) then
			inv:add_item("main", payout_stack)
		else
			local pos = player:get_pos()
			if pos then core.add_item(pos, payout_stack) end
		end

		core.chat_send_player(player_name, core.colorize("#00ff00", "[Denji]: Sweet! Here is your " .. total_payout .. " Minegeld."))
		show_denji_gui(player_name)
	end
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "folks:merchant_denji" then return false end
	if not player or not player:is_player() then return true end
	local player_name = player:get_player_name()
	local inv = player:get_inventory()
	if not inv then return true end

	if fields.sell_crown then
		handle_denji_sale(player, player_name, inv, DENJI_BUYS.crown)
		return true
	elseif fields.sell_sword then
		handle_denji_sale(player, player_name, inv, DENJI_BUYS.sword)
		return true
	end
end)

return {
	on_interact = function(player, npc_self)
		show_denji_gui(player:get_player_name())
	end
}
