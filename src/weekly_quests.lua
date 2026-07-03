-- src/weekly_quests.lua
-- Witch-Style Bulk "Sellable" Quest Supply Terminal for Techblox

local S = core.get_translator("folks")
local storage = core.get_mod_storage()

-- Define the exact table returned to roles.lua
local weekly_sys = {} 

-- 1. CONFIGURATION
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

-- 2. PERSISTENCE LAYER LOGIC
local function get_player_progress(player_name)
  if not player_name or player_name == "" then return { barley = 0, stone = 0, earth = 0, lightning = 0 } end
  
  local raw = storage:get_string("sellable_prog:" .. player_name)[cite: 6]
  if raw and raw ~= "" then
    local success, data = pcall(core.deserialize, raw)
    if success and type(data) == "table" then
      return {
        barley = tonumber(data.barley) or 0,
        stone = tonumber(data.stone) or 0,
        earth = tonumber(data.earth) or 0,
        lightning = tonumber(data.lightning) or 0
      }
    end
  end
  return { barley = 0, stone = 0, earth = 0, lightning = 0 }
end

local function save_player_progress(player_name, data)
  if player_name and player_name ~= "" and type(data) == "table" then
    storage:set_string("sellable_prog:" .. player_name, core.serialize(data))[cite: 6]
  end
end

-- 3. INTERACTIVE TRANSACTION PROCESSOR
local function handle_bulk_deposit(player, key)
  if not player or not player:is_player() then return end
  
  local player_name = player:get_player_name()
  if not player_name or player_name == "" then return end
  
  local inv = player:get_inventory()
  local cfg = QUESTS[key]
  if not inv or not cfg then return end

  local progress_data = get_player_progress(player_name)
  local current_amount = progress_data[key] or 0
  local amount_needed = cfg.goal - current_amount

  if amount_needed <= 0 then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: This requirement loop is completely filled already! Drop items elsewhere."))[cite: 6]
    return
  end

  local item_to_remove = nil
  local amount_to_remove = 0

  if core.registered_items[cfg.item] then
    for amt = math.min(99, amount_needed), 1, -1 do
      local check_stack = ItemStack(cfg.item .. " " .. amt)[cite: 6]
      if inv:contains_item("main", check_stack) then[cite: 6]
        item_to_remove = cfg.item
        amount_to_remove = amt
        break
      end
    end
  end

  if not item_to_remove and cfg.alt_items then
    for _, alt_item in ipairs(cfg.alt_items) do
      if core.registered_items[alt_item] then
        for amt = math.min(99, amount_needed), 1, -1 do
          local check_stack = ItemStack(alt_item .. " " .. amt)[cite: 6]
          if inv:contains_item("main", check_stack) then[cite: 6]
            item_to_remove = alt_item
            amount_to_remove = amt
            break
          end
        end
      end
      if item_to_remove then break end
    end
  end

  if not item_to_remove or amount_to_remove <= 0 then
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Witch]: Verification failed. You have no valid supplies for this drop."))[cite: 6]
    return
  end

  local remove_stack = ItemStack(item_to_remove .. " " .. amount_to_remove)[cite: 6]
  inv:remove_item("main", remove_stack)[cite: 6]

  local new_amount = current_amount + amount_to_remove
  progress_data[key] = new_amount
  save_player_progress(player_name, progress_data)

  core.chat_send_player(player_name, core.colorize("#e066ff", "[Witch]: Deposited " .. amount_to_remove .. "x items into the terminal cluster."))[cite: 6]

  if new_amount >= cfg.goal then
    local pay_stack = ItemStack("currency:minegeld 50")[cite: 6]
    
    if inv:room_for_item("main", pay_stack) then[cite: 6]
      inv:add_item("main", pay_stack)[cite: 6]
    else
      local pos = player:get_pos()[cite: 6]
      if pos then
        core.add_item(pos, pay_stack)[cite: 6]
      end
    end

    core.chat_send_player(player_name, core.colorize("#00ff00", "[Witch]: Directive complete! Milestone secured. +50 Minegeld notes dispatched!"))[cite: 6]
    core.sound_play("default_cool_lava", {to_player = player_name, gain = 1.0}, true)[cite: 6]
  end

  -- Re-draw via the standard interface right-click hook
  weekly_sys.on_interact(player, nil)
end

-- 4. RIGHT CLICK HOOK ENTRY (Triggers straight from roles.lua)
function weekly_sys.on_interact(player, npc_self)
  if not player or not player:is_player() then return end
  local player_name = player:get_player_name()
  if not player_name or player_name == "" then return end
  
  local progress_data = get_player_progress(player_name)
  
  local formspec = 
    "size[9.5,9.0]" ..
    "real_coordinates[true]" ..
    "background[0,0;9.5,9.0;#161224;true]" ..[cite: 6]
    "box[0,0;9.5,0.1;#a832a4]" ..[cite: 6]
    "label[0.6,0.6;" .. core.colorize("#e066ff", "WITCH'S BULK SUPPLY TERMINAL") .. "]" ..[cite: 6]
    "box[0.6,1.0;8.3,0.02;#ffffff15]"[cite: 6]

  local order = {"barley", "stone", "earth", "lightning"}[cite: 6]
  local start_y = 1.3[cite: 6]

  for _, key in ipairs(order) do[cite: 6]
    local cfg = QUESTS[key][cite: 6]
    if cfg then
      local current = progress_data[key] or 0
      local status_text
      
      if current >= cfg.goal then[cite: 6]
        status_text = core.colorize("#00ff00", "COMPLETED (50$ Milestone Secured)")[cite: 6]
      else
        status_text = core.colorize("#a6b2c0", "Progress: " .. current .. " / " .. cfg.goal)[cite: 6]
      end

      formspec = formspec .. 
        "box[0.6," .. start_y .. ";8.3,1.3;#ffffff03]" ..[cite: 6]
        "item_image[0.9," .. (start_y + 0.15) .. ";1.0,1.0;" .. (cfg.item or "") .. "]" ..[cite: 6]
        "label[2.1," .. (start_y + 0.4) .. ";" .. core.colorize("#ffffff", cfg.title or "") .. "]" ..[cite: 6]
        "label[2.1," .. (start_y + 0.85) .. ";" .. status_text .. "]" ..[cite: 6]
        "button[6.5," .. (start_y + 0.3) .. ";2.1,0.7;deposit_" .. key .. ";Deposit]"[cite: 6]
        
      start_y = start_y + 1.5[cite: 6]
    end
  end

  formspec = formspec .. "button_exit[3.7,7.7;2.1,0.6;quit;Leave Terminal]"[cite: 6]
  core.show_formspec(player_name, "folks:weeklyquests", formspec)[cite: 6]
end

-- 5. GUI SELECTION PROCESSOR
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:weeklyquests" then return false end[cite: 6]
  if not player or not player:is_player() then return true end[cite: 6]

  if fields.deposit_barley then[cite: 6]
    handle_bulk_deposit(player, "barley")
    return true
  elseif fields.deposit_stone then[cite: 6]
    handle_bulk_deposit(player, "stone")
    return true
  elseif fields.deposit_earth then[cite: 6]
    handle_bulk_deposit(player, "earth")
    return true
  elseif fields.deposit_lightning then[cite: 6]
    handle_bulk_deposit(player, "lightning")
    return true
  end
end)

-- CRITICAL FIX: Explicitly return the table to loadfile()
return weekly_sys
