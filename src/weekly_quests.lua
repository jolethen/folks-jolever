-- src/weekly_quests.lua
-- Weekly Quest Chain Handling Engine for Techblox

local S = core.get_translator("folks")
local storage = core.get_mod_storage()

if not folks then folks = {} end
folks.weekly = {}

-- Master Definition of the 4 Weekly Chain Quests
folks.weekly.chain = {
  [1] = {
    id = "weekly_barley",
    title = "Weekly Operation: Agricultural Reclaiming",
    description = "Harvest and clear out standard agricultural fields to secure basic supplies.",
    target_count = 1500,
    -- Accepting both node names and potential inventory item names for Barley
    target_items = { 
      ["techblox_ores:mmo_barley_8"] = true, 
      ["x_farming:barley_8"] = true,
      ["techblox_ores:barley"] = true,
      ["x_farming:barley"] = true
    },
    progress_label = "Barley harvested: ",
    short_name = "1. Barley"
  },
  [2] = {
    id = "weekly_stone",
    title = "Weekly Operation: Subterranean Clearing",
    description = "Examine and break down structural stones to secure core infrastructure lines.",
    target_count = 1500,
    target_items = { ["default:stone"] = true },
    progress_label = "Stone mined: ",
    short_name = "2. Stone"
  },
  [3] = {
    id = "weekly_earth",
    title = "Weekly Operation: Earth Core Extraction",
    description = "Mine down deep into core matrix lines to secure Earth Gemstone Ores.",
    target_count = 25,
    target_items = { ["magic_materials:earth_gemstone"] = true },
    progress_label = "Earth Gemstones mined: ",
    short_name = "3. Earth"
  },
  [4] = {
    id = "weekly_lightning",
    title = "Weekly Operation: High-Voltage Synthesis",
    description = "Recover rare Lightning Gemstone Ores to supercharge the main sector grids.",
    target_count = 25,
    target_items = { ["magic_materials:light_gemstone"] = true },
    progress_label = "Lightning Gemstones mined: ",
    short_name = "4. Lightning"
  }
}

-- 1. DB Loader & Saver for Weekly Progression Context
local function load_weekly_data(player_name)
  local raw = storage:get_string("weekly_save:" .. player_name)
  if raw and raw ~= "" then
    local data = core.deserialize(raw)
    if type(data) == "table" then
      data.current_step = data.current_step or 1
      data.progress = data.progress or 0
      data.completed_all = data.completed_all or false
      return data
    end
  end
  return { current_step = 1, progress = 0, completed_all = false }
end

local function save_weekly_data(player_name, data)
  storage:set_string("weekly_save:" .. player_name, core.serialize(data))
end

-- 2. Formspec GUI Frame Layout
function folks.weekly.show_interface(player_name)
  local data = load_weekly_data(player_name)
  local current_step = data.current_step
  local cfg = folks.weekly.chain[current_step]

  local formspec = 
    "size[9.5,8.5]" ..
    "real_coordinates[true]" ..
    "background[0,0;9.5,8.5;#11161b;true]" ..
    "box[0,0;9.5,0.1;#00f0ff]" ..
    "label[0.6,0.6;" .. core.colorize("#00f0ff", "WEEKLY TERMINAL INTERFACE") .. "]" ..
    "box[0.6,1.0;8.3,0.02;#ffffff15]"

  if data.completed_all or current_step > 4 then
    formspec = formspec .. 
      "label[2.2,2.8;" .. core.colorize("#00ff00", "All operations completed for this weekly sequence!") .. "]" ..
      "label[3.0,3.4;" .. core.colorize("#8899a6", "Check back next week for fresh terminal links.") .. "]"
  else
    formspec = formspec ..
      "label[0.6,1.4;" .. core.colorize("#ffffff", cfg.title) .. "]" ..
      "textarea[0.6,1.9;8.3,1.0;weekly_desc;;" .. cfg.description .. "]" ..
      
      "box[0.6,3.2;8.3,1.4;#ffffff03]" ..
      "label[0.9,3.5;" .. core.colorize("#a6b2c0", "CURRENT OBJECTIVE PROGRESS:") .. "]" ..
      "label[0.9,4.1;" .. core.colorize("#ffaa00", cfg.progress_label .. data.progress .. " / " .. cfg.target_count) .. "]" ..
      
      "label[5.5,3.5;" .. core.colorize("#a6b2c0", "ASSIGNMENT PAYLOAD:") .. "]" ..
      "label[5.5,4.1;" .. core.colorize("#00ff00", "50 Gold & 1 Minegeld") .. "]"
  end

  formspec = formspec .. "box[0.6,5.1;8.3,0.02;#ffffff15]" ..
                         "label[0.6,5.5;" .. core.colorize("#a6b2c0", "CHAIN INDEX TRACKER:") .. "]"
  
  local slot_x = 0.6
  for idx = 1, 4 do
    local chain_cfg = folks.weekly.chain[idx]
    local status_str = ""
    
    if data.completed_all or idx < current_step then
      status_str = core.colorize("#00ff00", "COMPLETED")
    elseif idx == current_step and not data.completed_all then
      status_str = core.colorize("#ffaa00", data.progress .. "/" .. chain_cfg.target_count)
    else
      status_str = core.colorize("#556677", "LOCKED")
    end
    
    formspec = formspec .. 
      "box[" .. slot_x .. ",5.9;1.9,1.1;#ffffff02]" ..
      "label[" .. (slot_x + 0.15) .. ",6.1;" .. core.colorize("#ffffff", chain_cfg.short_name) .. "]" ..
      "label[" .. (slot_x + 0.15) .. ",6.6;" .. status_str .. "]"
      
    slot_x = slot_x + 2.1
  end

  formspec = formspec .. "button_exit[3.7,7.4;2.1,0.6;quit;Disconnect]"
  core.show_formspec(player_name, "folks:weekly_log", formspec)
end

-- Progress Processor Function
local function add_weekly_progress(player, item_name, count)
  local player_name = player:get_player_name()
  local data = load_weekly_data(player_name)
  if data.completed_all or data.current_step > 4 then return end

  local cfg = folks.weekly.chain[data.current_step]
  
  if cfg.target_items[item_name] then
    data.progress = data.progress + (count or 1)
    
    if data.progress >= cfg.target_count then
      local inv = player:get_inventory()
      if inv then
        local reward_gold = ItemStack("default:gold 50")
        local reward_minegeld = ItemStack("currency:minegeld 1")
        
        if inv:room_for_item("main", reward_gold) then inv:add_item("main", reward_gold)
        else core.add_item(player:get_pos(), reward_gold) end
        
        if inv:room_for_item("main", reward_minegeld) then inv:add_item("main", reward_minegeld)
        else core.add_item(player:get_pos(), reward_minegeld) end
      end

      core.chat_send_player(player_name, core.colorize("#00ff00", "[Weekly Terminal]: Step objective complete! " .. cfg.title))
      data.current_step = data.current_step + 1
      data.progress = 0
      
      if data.current_step > 4 then
        data.completed_all = true
        core.chat_send_player(player_name, core.colorize("#00f0ff", "[Weekly Terminal]: Outstanding execution! All 4 weekly directives are secure."))
      else
        local next_cfg = folks.weekly.chain[data.current_step]
        core.chat_send_player(player_name, core.colorize("#00aaff", "[Weekly Terminal]: Next sequential protocol online: " .. next_cfg.title))
      end
    end
    save_weekly_data(player_name, data)
  end
end

-- 3. INTERCEPTION METHOD A: Mining traditional blocks
core.register_on_dignode(function(pos, oldnode, oldmetadata, digger)
  if not digger or not digger:is_player() then return end
  add_weekly_progress(digger, oldnode.name, 1)
end)

-- 4. INTERCEPTION METHOD B: Picking up items from the ground (Fixes custom farming harvests!)
if core.register_on_item_pickup then
  core.register_on_item_pickup(function(itemstack, picker, pointed_thing)
    if picker and picker:is_player() then
      -- Prints name to chat if it's barley so you can identify item strings
      if itemstack:get_name():find("barley") then
        core.chat_send_player(picker:get_player_name(), "[Debug Pickup]: Caught item name: " .. itemstack:get_name())
      end
      add_weekly_progress(picker, itemstack:get_name(), itemstack:get_count())
    end
  end)
end

return folks.weekly
