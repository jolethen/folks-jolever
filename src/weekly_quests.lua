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
  },
  desert_stone = {
    item = "default:desert_stone",
    goal = 1500,
    give_item = "currency:minegeld",
    give_count = 50,
    title = "Desert Stone Collection"
  },
  copper = {
    item = "default:copper_lump",
    goal = 500,
    give_item = "currency:minegeld",
    give_count = 75,
    title = "Heavy Copper Reserve"
  }
}

-- Helper Functions to handle progress tracking
local function get_progress(player_name, key)
  local raw = storage:get_string("weekly_prog:" .. player_name)
  if raw and raw ~= "" then
    local success, data = pcall(core.deserialize, raw)
    if success and type(data) == "table" then
      return tonumber(data[key]) or 0
    end
  end
  return 0
end

local function save_progress(player_name, key, amount)
  local raw = storage:get_string("weekly_prog:" .. player_name)
  local data = {}
  if raw and raw ~= "" then
    local success, res = pcall(core.deserialize, raw)
    if success and type(res) == "table" then data = res end
  end
  data[key] = amount
  storage:set_string("weekly_prog:" .. player_name, core.serialize(data))
end

-- 2. FORMSPEC GUI LOBBY (Using the custom purple layout expanded for 4 items)
function weekly_sys.show_interface(player_name)
  local barley_current = get_progress(player_name, "barley")
  local stone_current = get_progress(player_name, "stone")
  local desert_current = get_progress(player_name, "desert_stone")
  local copper_current = get_progress(player_name, "copper")

  local barley_status = barley_current >= QUESTS.barley.goal and 
    core.colorize("#00ff00", "COMPLETED!") or 
    core.colorize("#a6b2c0", "Deposited: " .. barley_current .. " / " .. QUESTS.barley.goal)

  local stone_status = stone_current >= QUESTS.stone.goal and 
    core.colorize("#00ff00", "COMPLETED!") or 
    core.colorize("#a6b2c0", "Deposited: " .. stone_current .. " / " .. QUESTS.stone.goal)

  local desert_status = desert_current >= QUESTS.desert_stone.goal and 
    core.colorize("#00ff00", "COMPLETED!") or 
    core.colorize("#a6b2c0", "Deposited: " .. desert_current .. " / " .. QUESTS.desert_stone.goal)

  local copper_status = copper_current >= QUESTS.copper.goal and 
    core.colorize("#00ff00", "COMPLETED!") or 
    core.colorize("#a6b2c0", "Deposited: " .. copper_current .. " / " .. QUESTS.copper.goal)

  -- Size adjusted to 10.2 height to accommodate all 4 quest rows clean and spacing out nicely
  local formspec = 
    "size[9.5,10.2]" ..
    "real_coordinates[true]" ..
    "background[0,0;9.5,10.2;#161224;true]" .. 
    "box[0,0;9.5,0.1;#a832a4]" ..
    "label[0.6,0.6;" .. core.colorize("#e066ff", "WITCH'S BULK SUPPLY TERMINAL") .. "]" ..
    "box[0.6,1.0;8.3,0.02;#ffffff15]" ..
    
    -- Quest 1: Barley Slot
    "box[0.6,1.4;8.3,1.4;#ffffff03]" ..
    "item_image[0.9,1.6;1.0,1.0;" .. QUESTS.barley.item .. "]" ..
    "label[2.2,1.7;" .. core.colorize("#ffffff", "Supply " .. QUESTS.barley.goal .. " Bulk Barley") .. "]" ..
    "label[2.2,2.1;" .. barley_status .. "]" ..
    "label[2.2,2.5;" .. core.colorize("#00ff00", "Reward: " .. QUESTS.barley.give_count .. " Minegeld") .. "]" ..
    "button[6.2,1.8;2.3,0.7;trade_barley;Deposit]" ..
    
    -- Quest 2: Stone Slot
    "box[0.6,3.0;8.3,1.4;#ffffff03]" ..
    "item_image[0.9,3.2;1.0,1.0;" .. QUESTS.stone.item .. "]" ..
    "label[2.2,3.3;" .. core.colorize("#ffffff", "Supply " .. QUESTS.stone.goal .. " Subterranean Stone") .. "]" ..
    "label[2.2,3.7;" .. stone_status .. "]" ..
    "label[2.2,4.1;" .. core.colorize("#00f0ff", "Reward: " .. QUESTS.stone.give_count .. " Minegeld") .. "]" ..
    "button[6.2,3.4;2.3,0.7;trade_stone;Deposit]" ..

    -- Quest 3: Desert Stone Slot
    "box[0.6,4.6;8.3,1.4;#ffffff03]" ..
    "item_image[0.9,4.8;1.0,1.0;" .. QUESTS.desert_stone.item .. "]" ..
    "label[2.2,4.9;" .. core.colorize("#ffffff", "Supply " .. QUESTS.desert_stone.goal .. " Desert Stone") .. "]" ..
    "label[2.2,5.3;" .. desert_status .. "]" ..
    "label[2.2,5.7;" .. core.colorize("#ffaa00", "Reward: " .. QUESTS.desert_stone.give_count .. " Minegeld") .. "]" ..
    "button[6.2,5.0;2.3,0.7;trade_desert_stone;Deposit]" ..

    -- Quest 4: Copper Lump Slot
    "box[0.6,6.2;8.3,1.4;#ffffff03]" ..
    "item_image[0.9,6.4;1.0,1.0;" .. QUESTS.copper.item .. "]" ..
    "label[2.2,6.5;" .. core.colorize("#ffffff", "Supply " .. QUESTS.copper.goal .. " Copper Lumps") .. "]" ..
    "label[2.2,6.9;" .. copper_status .. "]" ..
    "label[2.2,7.3;" .. core.colorize("#e066ff", "Reward: " .. QUESTS.copper.give_count .. " Minegeld") .. "]" ..
    "button[6.2,6.6;2.3,0.7;trade_copper;Deposit]" ..
    
    "button_exit[3.7,8.5;2.1,0.6;quit;Leave Altar]"

  core.show_formspec(player_name, "folks:weekly_terminal", formspec)
end

-- 3. HOOK ENTRY (Matching witch.lua pattern perfectly)
function weekly_sys.on_interact(player, npc_self)
  local player_name = player:get_player_name()
  weekly_sys.show_interface(player_name)
end

-- 4. INTERACTIVE TRANSACTION PROCESSOR (With Incremental Storing)
local function process_deposit(player, key)
  local player_name = player:get_player_name()
  local inv = player:get_inventory()
  local cfg = QUESTS[key]
  if not inv or not cfg then return end

  -- Safety verification
  if not core.registered_items[cfg.item] or not core.registered_items[cfg.give_item] then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: Matrix Error - Missing item definitions on server."))
    return
  end

  local current_amount = get_progress(player_name, key)
  local amount_needed = cfg.goal - current_amount

  if amount_needed <= 0 then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: This requirement loop is completely filled already!"))
    return
  end

  -- Scan inventory for items to take (up to a stack of 99 or what is needed)
  local amount_to_take = 0
  for amt = math.min(99, amount_needed), 1, -1 do
    local check_stack = ItemStack(cfg.item .. " " .. amt)
    if inv:contains_item("main", check_stack) then
      amount_to_take = amt
      break
    end
  end

  if amount_to_take == 0 then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: You don't have any of the required materials in your inventory to deposit."))
    return
  end

  -- Remove items safely
  local take_stack = ItemStack(cfg.item .. " " .. amount_to_take)
  inv:remove_item("main", take_stack)

  -- Save new progress values
  local new_amount = current_amount + amount_to_take
  save_progress(player_name, key, new_amount)

  core.chat_send_player(player_name, core.colorize("#e066ff", "[Witch]: Stored " .. amount_to_take .. "x items into the terminal cluster."))

  -- If goal is reached, give payout
  if new_amount >= cfg.goal then
    local give_stack = ItemStack(cfg.give_item .. " " .. cfg.give_count)
    if inv:room_for_item("main", give_stack) then
      inv:add_item("main", give_stack)
    else
      local pos = player:get_pos()
      if pos then core.add_item(pos, give_stack) end
    end
    core.chat_send_player(player_name, core.colorize("#00ff00", "[Witch]: Directive complete! " .. cfg.title .. " finalized. Reward dispatched!"))
  end

  -- Refresh formspec view to update progress bar lines instantly
  weekly_sys.show_interface(player_name)
end

-- 5. GUI SELECTION PROCESSOR (Checks all 4 interaction hooks flawlessly)
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:weekly_terminal" then return false end
  if not player or not player:is_player() then return true end

  if fields.trade_barley then
    process_deposit(player, "barley")
    return true
  -- Explicit safely coded hooks matching configuration tables
  elseif fields.trade_stone then
    process_deposit(player, "stone")
    return true
  elseif fields.trade_desert_stone then
    process_deposit(player, "desert_stone")
    return true
  elseif fields.trade_copper then
    process_deposit(player, "copper")
    return true
  end
end)

return weekly_sys
