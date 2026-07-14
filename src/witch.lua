-- src/witch.lua
-- Witch NPC Altar Exchange Module for Techblox

local S = core.get_translator("folks")
local witch = {}

-- 1. CONFIGURATION: Define trade definitions clearly
local trades = {
  earth = {
    req_item = "magic_materials:earth_gemstone_block",
    req_count = 10,
    give_item = "techblox:earth_orb",
    give_count = 1,
    title = "Extract Earth Orb"
  },
  lightning = {
    req_item = "magic_materials:lightning_gemstone_block",
    req_count = 10,
    give_item = "techblox:lightning_orb",
    give_count = 1,
    title = "Extract Lightning Orb"
  }
}

-- 2. FORMSPEC GUI LOBBY (Using the custom purple layout)
function witch.show_interface(player_name)
  local formspec = 
    "size[9.5,7.0]" ..
    "real_coordinates[true]" ..
    "background[0,0;9.5,7.0;techblox_terminal_bg.png;true]" .. -- Replaced solid color with requested PNG background
    "box[0,0;9.5,0.1;#a832a4]" ..
    "label[0.6,0.6;" .. core.colorize("#e066ff", "WITCH'S GEMSTONE ALTAR") .. "]" ..
    "box[0.6,1.0;8.3,0.02;#ffffff15]" ..
    
    -- Trade 1: Earth Altar Slot
    "box[0.6,1.5;8.3,1.4;#ffffff03]" ..
    "item_image[0.9,1.7;1.0,1.0;magic_materials:earth_gemstone_block]" ..
    "label[2.2,2.0;" .. core.colorize("#ffffff", "Exchange 10 Earth Gemstone Blocks") .. "]" ..
    "label[2.2,2.4;" .. core.colorize("#00ff00", "Receive: 1 Earth Orb") .. "]" ..
    "button[6.2,1.9;2.3,0.7;trade_earth;Transmute]" ..
    
    -- Trade 2: Lightning Altar Slot
    "box[0.6,3.2;8.3,1.4;#ffffff03]" ..
    "item_image[0.9,3.4;1.0,1.0;magic_materials:lightning_gemstone_block]" ..
    "label[2.2,3.7;" .. core.colorize("#ffffff", "Exchange 10 Lightning Gemstone Blocks") .. "]" ..
    "label[2.2,4.1;" .. core.colorize("#00f0ff", "Receive: 1 Lightning Orb") .. "]" ..
    "button[6.2,3.6;2.3,0.7;trade_lightning;Transmute]" ..
    
    "button_exit[3.7,5.5;2.1,0.6;quit;Leave Altar]"

  core.show_formspec(player_name, "folks:witch_altar", formspec)
end

-- 3. HOOK ENTRY (Matching ghoti.lua pattern perfectly)
function witch.on_interact(player, npc_self)
  local player_name = player:get_player_name()
  witch.show_interface(player_name)
end

-- 4. INTERACTIVE TRANSACTION PROCESSOR
local function process_trade(player, trade_cfg)
  local player_name = player:get_player_name()
  local inv = player:get_inventory()
  if not inv then return end

  -- Safety verification: Ensure items exist in game register to prevent ghost loss
  if not core.registered_items[trade_cfg.req_item] or not core.registered_items[trade_cfg.give_item] then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: Matrix Error - Missing item definitions on server."))
    return
  end

  -- Check if player actually has enough resources
  local req_stack = ItemStack(trade_cfg.req_item .. " " .. trade_cfg.req_count)
  if not inv:contains_item("main", req_stack) then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: You do not have enough materials for this transmuting sequence."))
    return
  end

  -- Check if player inventory has room to hold the reward item
  local give_stack = ItemStack(trade_cfg.give_item .. " " .. trade_cfg.give_count)
  if not inv:room_for_item("main", give_stack) then
    core.chat_send_player(player_name, core.colorize("#ffaa00", "[Witch]: Your inventory is full! Make space before altering items."))
    return
  end

  -- Deduct and deliver cleanly
  inv:remove_item("main", req_stack)
  inv:add_item("main", give_stack)
  
  core.chat_send_player(player_name, core.colorize("#e066ff", "[Witch]: Transmutation successful! " .. trade_cfg.title .. " finalized."))
end

-- 5. GUI SELECTION PROCESSOR
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:witch_altar" then return false end
  if not player or not player:is_player() then return true end

  if fields.trade_earth then
    process_trade(player, trades.earth)
    return true
  elseif fields.trade_lightning then
    process_trade(player, trades.lightning)
    return true
  end
end)

return witch
