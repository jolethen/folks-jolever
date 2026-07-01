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
    target_items = { ["techblox_ores:mmo_barley_8"] = true, ["x_farming:barley_8"] = true },
    progress_label = "Barley harvested: "
  },
  [2] = {
    id = "weekly_stone",
    title = "Weekly Operation: Subterranean Clearing",
    description = "Examine and break down structural stones to secure core infrastructure lines.",
    target_count = 1500,
    target_items = { ["default:stone"] = true },
    progress_label = "Stone mined: "
  },
  [3] = {
    id = "weekly_earth",
    title = "Weekly Operation: Earth Core Extraction",
    description = "Mine down deep into core matrix lines to secure Earth Gemstone Ores.",
    target_count = 25,
    target_items = { ["magic_materials:earth_gemstone"] = true },
    progress_label = "Earth Gemstones mined: "
  },
  [4] = {
    id = "weekly_lightning",
    title = "Weekly Operation: High-Voltage Synthesis",
    description = "Recover rare Lightning Gemstone Ores to supercharge the main sector grids.",
    target_count = 25,
    target_items = { ["magic_materials:light_gemstone"] = true },
    progress_label = "Lightning Gemstones mined: "
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
    "size[9.0,6.5]" ..
    "real_coordinates[true]" ..
    "background[0,0;9.0,6.5;#11161b;true]" ..
    "box[0,0;9.0,0.1;#00f0ff]" ..
    "label[0.6,0.6;" .. core.colorize("#00f0ff", "WEEKLY TERMINAL INTERFACE") .. "]" ..
    "box[0.6,1.0;7.8,0.02;#ffffff15]"

  if data.completed_all or current_step > 4 then
    formspec = formspec .. 
      "label[2.0,3.0;" .. core.colorize("#00ff00", "All operations completed for this weekly sequence!") .. "]" ..
      "label[2.8,3.5;" .. core.colorize("#8899a6", "Check back next week for fresh terminal links.") .. "]"
  else
    formspec = formspec ..
      "label[0.6,1.5;" .. core.colorize("#ffffff", cfg.title) .. "]" ..
      "textarea[0.6,2.0;7.8,1.2;weekly_desc;;" .. cfg.description .. "]" ..
      "box[0.6,3.4;7.8,1.4;#ffffff03]" ..
      "label[0.9,3.8;" .. core.colorize("#ffffff", "PROGRESSION STATUS:") .. "]" ..
      "label[0.9,4.3;" .. core.colorize("#ffaa00", cfg.progress_label .. data.progress .. " / " .. cfg.target_count) .. "]" ..
      "label[5.3,3.8;" .. core.colorize("#a6b2c0", "ASSIGNMENT PAYLOAD:") .. "]" ..
      "label[5.3,4.3;" .. core.colorize("#00ff00", "50 Gold & 1 Minegeld") .. "]"
  end

  formspec = formspec .. "button_exit[3.5,5.4;2.0,0.6;quit;Disconnect]"
  core.show_formspec(player_name, "folks:weekly_log", formspec)
end

-- 3. Mining Interception Hook (Tracks actual mining actions)
core.register_on_dignode(function(pos, oldnode, oldmetadata, digger)
  if not digger or not digger:is_player() then return end
  local player_name = digger:get_player_name()
  
  local data = load_weekly_data(player_name)
  if data.completed_all or data.current_step > 4 then return end

  local cfg = folks.weekly.chain[data.current_step]
  
  -- Match broken block against the table of valid nodes for this task step
  if cfg.target_items[oldnode.name] then
    data.progress = data.progress + 1
    
    -- When the goal target count is matched, grant rewards and flip step indexes
    if data.progress >= cfg.target_count then
      local inv = digger:get_inventory()
      if inv then
        local reward_gold = ItemStack("default:gold 50")
        local reward_minegeld = ItemStack("currency:minegeld 1")
        
        -- Give Gold safely
        if inv:room_for_item("main", reward_gold) then
          inv:add_item("main", reward_gold)
        else
          core.add_item(digger:get_pos(), reward_gold)
        end
        
        -- Give Minegeld safely
        if inv:room_for_item("main", reward_minegeld) then
          inv:add_item("main", reward_minegeld)
        else
          core.add_item(digger:get_pos(), reward_minegeld)
        end
      end

      core.chat_send_player(player_name, core.colorize("#00ff00", "[Weekly Terminal]: Step objective complete! " .. cfg.title))
      
      -- Shift timeline pointer directly to next sequential task step
      data.current_step = data.current_step + 1
      data.progress = 0
      
      if data.current_step > 4 then
        data.completed_all = true
        core.chat_send_player(player_name, core.colorize("#00f0ff", "[Weekly Terminal]: Outstanding execution! All 4 weekly directives are fully secure."))
      else
        local next_cfg = folks.weekly.chain[data.current_step]
        core.chat_send_player(player_name, core.colorize("#00aaff", "[Weekly Terminal]: Next sequential protocol online: " .. next_cfg.title))
      end
    end
    
    save_weekly_data(player_name, data)
  end
end)

return folks.weekly
