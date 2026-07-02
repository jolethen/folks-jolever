-- src/sellable_quests.lua
-- Witch-Style Bulk "Sellable" Quest Supply Terminal for Techblox

local S = core.get_translator("folks")
local storage = core.get_mod_storage()
local weekly_sys = {} -- Renamed to match roles.lua expected global identifier

-- 1. CONFIGURATION: Define tracking structures and targets cleanly
local QUESTS = {
  barley = {
    item = "techblox_ores:mmo_barley_8",
    alt_items = { "x_farming:barley_8", "x_farming:barley" },
    goal = 1500,
    title = "Bulk Barley Shipment"
  },
  stone = {
    item = "default:stone",
    goal = 1500,
    title = "Subterranean Stone Supply"
  },
  earth = {
    item = "magic_materials:earth_gemstone",
    goal = 25,
    title = "Earth Core Extraction"
  },
  lightning = {
    item = "magic_materials:light_gemstone",
    goal = 25,
    title = "High-Voltage Light Gems"
  }
}

-- 2. PERSISTENCE LAYER LOGIC (Using memory-efficient lookup tables)
local function get_player_progress(player_name)
  local raw = storage:get_string("sellable_prog:" .. player_name)
  if raw and raw ~= "" then
    local success, data = pcall(core.deserialize, raw)
    if success and type(data) == "table" then
      return data
    end
  end
  return { barley = 0, stone = 0, earth = 0, lightning = 0 }
end

local function save_player_progress(player_name, data)
  storage:set_string("sellable_prog:" .. player_name, core.serialize(data))
end

-- 3. FORMSPEC GUI LOBBY (Sleek and Modern Redesign Layout)
function weekly_sys.show_interface(player_name)
  local progress_data = get_player_progress(player_name)
  
  local formspec = 
    "size[9.5,9.0]" ..
    "real_coordinates[true]" ..
    "background[0,0;9.5,9.0;#161224;true]" .. -- Dark purple/witchy tint atmosphere
    "box[0,0;9.5,0.1;#a832a4]" ..
    "label[0.6,0.6;" .. core.colorize("#e066ff", "WITCH'S BULK SUPPLY TERMINAL") .. "]" ..
    "box[0.6,1.0;8.3,0.02;#ffffff15]"

  -- Ordered keys array to loop-render rows predictably
  local order = {"barley", "stone", "earth", "lightning"}
  local start_y = 1.3

  for _, key in ipairs(order) do
    local cfg = QUESTS[key]
    local current = progress_data[key] or 0
    
    local status_text
    if current >= cfg.goal then
      status_text = core.colorize("#00ff00", "COMPLETED (50$ Milestone Secured)")
    else
      status_text = core.colorize("#a6b2c0", "Progress: " .. current .. " / " .. cfg.goal)
    end

    formspec = formspec .. 
      "box[0.6," .. start_y .. ";8.3,1.3;#ffffff03]" ..
      "item_image[0.9," .. (start_y + 0.15) .. ";1.0,1.0;" .. cfg.item .. "]" ..
      "label[2.1," .. (start_y + 0.4) .. ";" .. core.colorize("#ffffff", cfg.title) .. "]" ..
      "label[2.1," .. (start_y + 0.85) .. ";" .. status_text .. "]" ..
      "button[6.5," .. (start_y + 0.3) .. ";2.1,0.7;deposit_" .. key .. ";Deposit]"
      
    start_y = start_y + 1.5
  end

  formspec = formspec .. "button_exit[3.7,7.7;2.1,0.6;quit;Leave Terminal]"

  core.show_formspec(player_name, "folks:weeklyquests", formspec)
end

-- 4. HOOK ENTRY (Matching roles.lua standard configuration execution)
function weekly_sys.on_interact(player, npc_self)
  local player_name = player:get_player_name()
  weekly_sys.show_interface(player_name)
end

-- 5. INTERACTIVE TRANSACTION PROCESSOR
local function handle_bulk_deposit(player, key)
  local player_name = player:get_player_name()
  local inv = player:get_inventory()
  if not inv then return end

  local cfg = QUESTS[key]
  local progress_data = get_player_progress(player_name)
  local current_amount = progress_data[key] or 0

  -- Check if they are already done with this task
  if current_amount >= cfg.goal then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: This requirement loop is completely filled already! Drop items elsewhere."))
    return
  end

  -- Scan for primary item total in inventory first
  local count = inv:get_stack_count(cfg.item)
  local item_to_use = cfg.item

  -- Dynamic loop check over alternative names if primary is not found
  if count == 0 and cfg.alt_items then
    for _, alt_name in ipairs(cfg.alt_items) do
      local alt_count = inv:get_stack_count(alt_name)
      if alt_count > 0 then
        count = alt_count
        item_to_use = alt_name
        break
      end
    end
  end

  if count <= 0 then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: Verification failed. You have no valid supplies for this drop."))
    return
  end

  -- Calculation: figure out how much we actually need vs what player has in pockets
  local amount_needed = cfg.goal - current_amount
  local transfer_amount = math.min(count, amount_needed)

  -- Deduct cleanly from inventory
  local remove_stack = ItemStack(item_to_use .. " " .. transfer_amount)
  inv:remove_item("main", remove_stack)

  -- Save new state math calculations
  local new_amount = current_amount + transfer_amount
  progress_data[key] = new_amount
  save_player_progress(player_name, progress_data)

  core.chat_send_player(player_name, core.colorize("#e066ff", "[Witch]: Deposited " .. transfer_amount .. "x items into the terminal cluster."))

  -- MILESTONE TRIGGER CHECK: Checks if transition values crossed the max target exactly this transaction
  if new_amount >= cfg.goal then
    local pay_stack = ItemStack("currency:minegeld 50")
    
    if inv:room_for_item("main", pay_stack) then
      inv:add_item("main", pay_stack)
    else
      core.add_item(player:get_pos(), pay_stack)
    end

    core.chat_send_player(player_name, core.colorize("#00ff00", "[Witch]: Directive complete! Milestone secured. +50 Minegeld notes dispatched!"))
    core.sound_play("default_cool_lava", {to_player = player_name, gain = 1.0}, true)
  end

  -- Dynamic live screen redraw matching refresh specs
  weekly_sys.show_interface(player_name)
end

-- 6. GUI SELECTION PROCESSOR
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:weeklyquests" then return false end
  if not player or not player:is_player() then return true end

  if fields.deposit_barley then
    handle_bulk_deposit(player, "barley")
    return true
  elseif fields.deposit_stone then
    handle_bulk_deposit(player, "stone")
    return true
  elseif fields.deposit_earth then
    handle_bulk_deposit(player, "earth")
    return true
  elseif fields.deposit_lightning then
    handle_bulk_deposit(player, "lightning")
    return true
  end
end)

return weekly_sys
