-- quests.lua
-- Techblox Quest, Objective, Persistent DB, and Live HUD Subsystem
local S = core.get_translator("folks")

folks.quests = {}

-- Local reference to Luanti's engine per-mod storage system
local storage = core.get_mod_storage()

-- Memory cache for live player data tracking
folks.quests.player_data = {}

-- Memory cache tracking live player HUD IDs so we don't leak or duplicate elements
folks.quests.hud_ids = {}

-- 1. Master Quest Database Definitions (Assigned strictly to Quester)
folks.quests.database = {
  ["fish_novice"] = {
    title = S("The Beginner's Catch"),
    giver = "quester",
    description = S("Quester wants you to prove your angling skills. Bring him 3 Raw Cod."),
    type = "gather",
    target_item = "fishing:fish_cod",
    target_count = 3,
    reward_item = "default:gold",
    reward_count = 15,
    dialogue = {
      intro = S("Hey there adventurer! Welcome to Techblox. I need someone to help supply the local docks. Could you hook me 3 Raw Cod?"),
      progress = S("Still searching the rivers? Come back when you have all 3 Raw Cod in your cargo bag!"),
      complete = S("Ah, beautiful specimens! Here is some gold for your trouble. I'll have more work for you soon!")
    }
  },
  ["deep_sea_danger"] = {
    title = S("Depths of Danger"),
    giver = "quester",
    description = S("Quester is looking for an elusive prize. Bring him 1 rare Anglerfish."),
    type = "gather",
    target_item = "fishing:fish_angler",
    target_count = 1,
    reward_item = "default:gold",
    reward_count = 50,
    dialogue = {
      intro = S("Brr... only the bravest fish the deep trenches. Bring me an Anglerfish if you want to prove your worth."),
      progress = S("No luck in the dark depths yet? Watch your step down there, it gets dangerous."),
      complete = S("Unbelievable! You actually brought me one intact! Here, you earned every single piece of this gold.")
    }
  }
}

-- 2. Persistent Database Storage Engine (JSON Serialization)
function folks.quests.load_player_db(player_name)
  local raw_string = storage:get_string("quest_save:" .. player_name)
  if raw_string and raw_string ~= "" then
    local data = core.deserialize(raw_string)
    if type(data) == "table" then
      data.active = data.active or {}
      data.completed = data.completed or {}
      folks.quests.player_data[player_name] = data
      return data
    end
  end
  
  folks.quests.player_data[player_name] = { active = {}, completed = {} }
  return folks.quests.player_data[player_name]
end

function folks.quests.save_player_db(player_name)
  local pdata = folks.quests.player_data[player_name]
  if pdata then
    storage:set_string("quest_save:" .. player_name, core.serialize(pdata))
  end
end

-- 3. Dynamic Screen-Aligned HUD Engine
function folks.quests.update_hud(player)
  if not player or not player:is_player() then return end
  local player_name = player:get_player_name()
  local pdata = folks.quests.player_data[player_name] or folks.quests.load_player_db(player_name)
  
  if not folks.quests.hud_ids[player_name] then
    folks.quests.hud_ids[player_name] = { title_id = nil, quest_slots = {} }
  end
  local tracking = folks.quests.hud_ids[player_name]
  
  local has_active = false
  for _, _ in pairs(pdata.active) do has_active = true break end
  
  if not has_active then
    if tracking.title_id then 
      player:hud_remove(tracking.title_id) 
      tracking.title_id = nil 
    end
    for i, hud_id in ipairs(tracking.quest_slots) do
      player:hud_remove(hud_id)
    end
    tracking.quest_slots = {}
    return
  end
  
  if not tracking.title_id then
    tracking.title_id = player:hud_add({
      hud_elem_type = "text",
      position      = {x = 1.0, y = 0.4},
      offset        = {x = -25, y = 0},
      alignment     = {x = -1, y = 0},
      scale         = {x = 100, y = 20},
      text          = "=== QUESTS ===",
      number        = 0x00f0ff,
    })
  end
  
  local offset_y = 25
  local slot_idx = 1
  local inv = player:get_inventory()
  
  for q_id, _ in pairs(pdata.active) do
    local cfg = folks.quests.database[q_id]
    if cfg then
      local progress_str = ""
      if cfg.type == "gather" and inv then
        local count = 0
        local stack = inv:get_stack("main", cfg.target_item)
        if stack and not stack:is_empty() then
          count = stack:get_count()
        end
        progress_str = " (" .. math.min(count, cfg.target_count) .. "/" .. cfg.target_count .. ")"
      end
      
      local line_text = "• " .. cfg.title .. progress_str
      
      if tracking.quest_slots[slot_idx] then
        player:hud_change(tracking.quest_slots[slot_idx], "text", line_text)
      else
        tracking.quest_slots[slot_idx] = player:hud_add({
          hud_elem_type = "text",
          position      = {x = 1.0, y = 0.4},
          offset        = {x = -25, y = offset_y},
          alignment     = {x = -1, y = 0},
          scale         = {x = 100, y = 20},
          text          = line_text,
          number        = 0xffffff,
        })
      end
      
      offset_y = offset_y + 22
      slot_idx = slot_idx + 1
    end
  end
  
  while #tracking.quest_slots >= slot_idx do
    local target_idx = #tracking.quest_slots
    player:hud_remove(tracking.quest_slots[target_idx])
    table.remove(tracking.quest_slots, target_idx)
  end
end

-- 4. Interactive Core Mechanics (Accept / Verify Loops)
function folks.quests.handle_npc_interaction(player, npc_name_raw)
  if not player or not player:is_player() then return false end
  
  local player_name = player:get_player_name()
  local npc_id_clean = string.lower(npc_name_raw)
  local pdata = folks.quests.player_data[player_name] or folks.quests.load_player_db(player_name)
  local inv = player:get_inventory()

  -- Hard safety fallback if inventory doesn't exist
  if not inv then return false end

  local target_quest_id = nil
  local quest_cfg = nil
  
  for q_id, cfg in pairs(folks.quests.database) do
    if cfg.giver == npc_id_clean then
      if pdata.active[q_id] then
        target_quest_id = q_id
        quest_cfg = cfg
        break
      elseif not pdata.completed[q_id] and not target_quest_id then
        target_quest_id = q_id
        quest_cfg = cfg
      end
    end
  end

  if not target_quest_id or not quest_cfg then return false end

  -- Progression Check Loop Execution
  if pdata.active[target_quest_id] then
    local current_count = 0
    if quest_cfg.type == "gather" then
      local stack = inv:get_stack("main", quest_cfg.target_item)
      if stack and not stack:is_empty() then
        current_count = stack:get_count()
      end
    end

    if current_count >= quest_cfg.target_count then
      -- Safe alternative ItemStack constructor using explicit table dictionaries
      inv:remove_item("main", ItemStack({name = quest_cfg.target_item, count = quest_cfg.target_count}))
      
      local reward = ItemStack({name = quest_cfg.reward_item, count = quest_cfg.reward_count})
      if inv:room_for_item("main", reward) then
        inv:add_item("main", reward)
      else
        core.add_item(player:get_pos(), reward)
      end

      pdata.completed[target_quest_id] = true
      pdata.active[target_quest_id] = nil
      
      folks.quests.save_player_db(player_name)
      folks.quests.update_hud(player)

      core.chat_send_player(player_name, core.colorize("#00ff00", npc_name_raw .. ": " .. quest_cfg.dialogue.complete))
      return true
    else
      core.chat_send_player(player_name, core.colorize("#ffaa00", npc_name_raw .. ": " .. quest_cfg.dialogue.progress))
      return true
    end

  -- Assignment Loop Execution
  else
    pdata.active[target_quest_id] = { progress = 0 }
    
    folks.quests.save_player_db(player_name)
    folks.quests.update_hud(player)

    core.chat_send_player(player_name, core.colorize("#00aaff", npc_name_raw .. ": " .. quest_cfg.dialogue.intro))
    core.chat_send_player(player_name, core.colorize("#00f0ff", ">> Assignment Initiated: " .. quest_cfg.title))
    return true
  end
end

-- 5. Graphical Interface Display Frame
function folks.quests.show_quest_log(player_name)
  local pdata = folks.quests.player_data[player_name] or folks.quests.load_player_db(player_name)
  
  local formspec = 
    "size[12.0,9.0]" ..
    "real_coordinates[true]" ..
    "style_type[label;font=bold;font_size=16]" ..
    "style_type[box;border=false]" ..
    "style_type[button;border=true;font=bold;font_size=14;backcolor=#ffffff10;textcolor=#ffffff]" ..
    "style_type[button:hover;backcolor=#00f0ff20;textcolor=#00f0ff]" ..
    "background[0,0;12.0,9.0;#11161b;true]" ..
    "box[0,0;12.0,0.15;#00f0ff]" ..
    "label[0.6,0.6;#00f0ff;TECHBLOX LOGBOOK]" ..
    "label[0.6,1.0;#8899a6;Track active tactical operations and open assignments]" ..
    "box[0.6,1.4;10.8,0.02;#ffffff15]"

  local row_y = 1.7
  local has_active = false
  
  for q_id, _ in pairs(pdata.active) do
    has_active = true
    local cfg = folks.quests.database[q_id]
    
    formspec = formspec .. 
      "box[0.6," .. row_y .. ";10.8,1.8;#ffffff06]" ..
      "box[0.6," .. row_y .. ";0.05,1.8;#00f0ff]"
      
    local clean_giver = cfg.giver:gsub("^%l", string.upper)
    formspec = formspec .. 
      "label[0.9," .. (row_y + 0.3) .. ";#ffffff" .. cfg.title .. "]" ..
      "label[0.9," .. (row_y + 0.65) .. ";#8899a6;Assigned by: " .. clean_giver .. "]" ..
      "hypertext[0.9," .. (row_y + 1.0) .. ";6.0,0.6;desc_" .. q_id .. ";<global font=normal size=14 color=#b2c0cc>" .. cfg.description .. "]" ..
      "box[7.5," .. (row_y + 0.25) .. ";3.5,1.3;#00000030]" ..
      "label[7.8," .. (row_y + 0.5) .. ";#ffaa00;REWARD:]" ..
      "item_image[7.8," .. (row_y + 0.75) .. ";0.6,0.6;" .. cfg.reward_item .. "]" ..
      "label[8.6," .. (row_y + 0.95) .. ";#ffffffx" .. cfg.reward_count .. " Gold]"
    
    row_y = row_y + 2.0
  end

  if not has_active then
    formspec = formspec .. 
      "box[3.5,3.5;5.0,2.0;#ffffff03]" ..
      "label[4.2,4.3;#8899a6;No active assignments found.]" ..
      "label[3.8,4.7;#00f0ff;Speak to local folks to find work.]"
  end

  formspec = formspec .. "button[9.4,8.0;2.0,0.6;quit;Close Log]"

  core.show_formspec(player_name, "folks:quest_log", formspec)
end

-- 6. Engine Server Hooks & Global Event Registrations
core.register_on_joinplayer(function(player)
  if not player then return end
  local name = player:get_player_name()
  folks.quests.load_player_db(name)
  
  core.after(1.0, function()
    local p = core.get_player_by_name(name)
    if p then folks.quests.update_hud(p) end
  end)
end)

core.register_on_leaveplayer(function(player)
  if not player then return end
  local name = player:get_player_name()
  folks.quests.save_player_db(name)
  
  folks.quests.player_data[name] = nil
  folks.quests.hud_ids[name] = nil
end)

core.register_on_placenode(function(pos, newnode, placer)
  if placer and placer:is_player() then folks.quests.update_hud(placer) end
end)

core.register_on_dignode(function(pos, oldnode, digger)
  if digger and digger:is_player() then folks.quests.update_hud(digger) end
end)

core.register_on_player_receive_fields(function(player, formname, fields)
  if player and player:is_player() then 
    folks.quests.update_hud(player) 
  end
  return false
end)

-- 7. Chat Commands (/quests and /cancelqu)
core.register_chatcommand("quests", {
  description = "Open your active quest log menu",
  func = function(name)
    folks.quests.show_quest_log(name)
    return true
  end
})

core.register_chatcommand("cancelqu", {
  description = "Abandon all active quests entirely",
  func = function(name)
    local player = core.get_player_by_name(name)
    if not player then return false end
    
    local pdata = folks.quests.player_data[name]
    if pdata then
      local count = 0
      for q_id, _ in pairs(pdata.active) do
        pdata.active[q_id] = nil
        count = count + 1
      end
      
      if count > 0 then
        folks.quests.save_player_db(name)
        folks.quests.update_hud(player)
        return true, "Successfully terminated " .. count .. " running operations."
      else
        return false, "You have no running operations to terminate."
      end
    end
    return false, "Data tracking context missing."
  end
})

return folks.quests
