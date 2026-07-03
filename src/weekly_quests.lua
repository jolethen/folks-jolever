-- src/weekly_quests.lua
-- Cloned from witch.lua structure with incremental storage added for Techblox

local S = core.get_translator("folks")
local storage = core.get_mod_storage()
local weekly_sys = {}

-- 1. CONFIGURATION: Define trade targets and limits clearly
local QUESTS = {
  barley = {
    item = "techblox_ores:mmo_barley_8",
    goal = 1500,
    give_item = "currency:minegeld",
    give_count = 50,
    title = "Bulk Barley Shipment"
  },
  stone = {
    item = "default:stone",
    goal = 1500,
    give_item = "currency:minegeld",
    give_count = 50,
    title = "Subterranean Stone Supply"
  }
}

-- Helper Functions to handle progress tracking
local function get_progress(player_name, key)
  local raw = storage:get_string("weekly_prog:" .. player_name)[cite: 6]
  if raw and raw ~= "" then
    local success, data = pcall(core.deserialize, raw)
    if success and type(data) == "table" then
      return tonumber(data[key]) or 0
    end
  end
  return 0
end

local function save_progress(player_name, key, amount)
  local raw = storage:get_string("weekly_prog:" .. player_name)[cite: 6]
  local data = {}
  if raw and raw ~= "" then
    local success, res = pcall(core.deserialize, raw)
    if success and type(res) == "table" then data = res end
  end
  data[key] = amount
  storage:set_string("weekly_prog:" .. player_name, core.serialize(data))[cite: 6]
end

-- 2. FORMSPEC GUI LOBBY (Using the custom purple layout)
function weekly_sys.show_interface(player_name)
  local barley_current = get_progress(player_name, "barley")
  local stone_current = get_progress(player_name, "stone")

  local barley_status = barley_current >= QUESTS.barley.goal and 
    core.colorize("#00ff00", "COMPLETED!") or 
    core.colorize("#a6b2c0", "Deposited: " .. barley_current .. " / " .. QUESTS.barley.goal)

  local stone_status = stone_current >= QUESTS.stone.goal and 
    core.colorize("#00ff00", "COMPLETED!") or 
    core.colorize("#a6b2c0", "Deposited: " .. stone_current .. " / " .. QUESTS.stone.goal)

  local formspec = 
    "size[9.5,7.0]" ..
    "real_coordinates[true]" ..
    "background[0,0;9.5,7.0;#161224;true]" .. -- Dark purple atmosphere[cite: 9]
    "box[0,0;9.5,0.1;#a832a4]" ..[cite: 9]
    "label[0.6,0.6;" .. core.colorize("#e066ff", "WITCH'S BULK SUPPLY TERMINAL") .. "]" ..[cite: 9]
    "box[0.6,1.0;8.3,0.02;#ffffff15]" ..[cite: 9]
    
    -- Quest 1: Barley Slot
    "box[0.6,1.5;8.3,1.4;#ffffff03]" ..[cite: 9]
    "item_image[0.9,1.7;1.0,1.0;techblox_ores:mmo_barley_8]" ..[cite: 9]
    "label[2.2,1.8;" .. core.colorize("#ffffff", "Supply 1500 Bulk Barley") .. "]" ..
    "label[2.2,2.2;" .. barley_status .. "]" ..
    "label[2.2,2.6;" .. core.colorize("#00ff00", "Reward: 50 Minegeld") .. "]" ..
    "button[6.2,1.9;2.3,0.7;trade_barley;Deposit]" ..
    
    -- Quest 2: Stone Slot
    "box[0.6,3.2;8.3,1.4;#ffffff03]" ..[cite: 9]
    "item_image[0.9,3.4;1.0,1.0;default:stone]" ..[cite: 9]
    "label[2.2,3.5;" .. core.colorize("#ffffff", "Supply 1500 Subterranean Stone") .. "]" ..
    "label[2.2,3.9;" .. stone_status .. "]" ..
    "label[2.2,4.3;" .. core.colorize("#00f0ff", "Reward: 50 Minegeld") .. "]" ..
    "button[6.2,3.6;2.3,0.7;trade_stone;Deposit]" ..
    
    "button_exit[3.7,5.5;2.1,0.6;quit;Leave Altar]"[cite: 9]

  core.show_formspec(player_name, "folks:weekly_terminal", formspec)[cite: 9]
end

-- 3. HOOK ENTRY (Matching witch.lua pattern perfectly)
function weekly_sys.on_interact(player, npc_self)
  local player_name = player:get_player_name()[cite: 9]
  weekly_sys.show_interface(player_name)[cite: 9]
end

-- 4. INTERACTIVE TRANSACTION PROCESSOR (With Incremental Storing)
local function process_deposit(player, key)
  local player_name = player:get_player_name()[cite: 9]
  local inv = player:get_inventory()[cite: 9]
  local cfg = QUESTS[key]
  if not inv or not cfg then return end

  -- Safety verification
  if not core.registered_items[cfg.item] or not core.registered_items[cfg.give_item] then[cite: 9]
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: Matrix Error - Missing item definitions on server."))[cite: 9]
    return
  end

  local current_amount = get_progress(player_name, key)
  local amount_needed = cfg.goal - current_amount

  if amount_needed <= 0 then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: This requirement loop is completely filled already!"))[cite: 6]
    return
  end

  -- Scan inventory for items to take (up to a stack of 99 or what is needed)
  local amount_to_take = 0
  for amt = math.min(99, amount_needed), 1, -1 do[cite: 6]
    local check_stack = ItemStack(cfg.item .. " " .. amt)[cite: 6]
    if inv:contains_item("main", check_stack) then[cite: 6]
      amount_to_take = amt
      break
    end
  end

  if amount_to_take == 0 then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: You don't have any of the required materials in your inventory to deposit."))
    return
  end

  -- Remove items safely[cite: 6]
  local take_stack = ItemStack(cfg.item .. " " .. amount_to_take)
  inv:remove_item("main", take_stack)[cite: 6]

  -- Save new progress values
  local new_amount = current_amount + amount_to_take
  save_progress(player_name, key, new_amount)

  core.chat_send_player(player_name, core.colorize("#e066ff", "[Witch]: Stored " .. amount_to_take .. "x items into the terminal cluster."))[cite: 6]

  -- If goal is reached, give payout
  if new_amount >= cfg.goal then
    local give_stack = ItemStack(cfg.give_item .. " " .. cfg.give_count)
    if inv:room_for_item("main", give_stack) then[cite: 6]
      inv:add_item("main", give_stack)[cite: 6]
    else
      local pos = player:get_pos()[cite: 6]
      if pos then core.add_item(pos, give_stack) end[cite: 6]
    end
    core.chat_send_player(player_name, core.colorize("#00ff00", "[Witch]: Directive complete! " .. cfg.title .. " finalized. Reward dispatched!"))
  end

  -- Refresh formspec view to update progress bar lines instantly
  weekly_sys.show_interface(player_name)
end

-- 5. GUI SELECTION PROCESSOR
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname != "folks:weekly_terminal" then return false end[cite: 9]
  if not player or not player:is_player() then return true end[cite: 9]

  if fields.trade_barley then
    process_deposit(player, "barley")
    return true
  elseif fields.trade_stone then
    process_deposit(player, "stone")
    return true
  end
end)

return weekly_sys
