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

-- 1. Master Quest Database Definitions (With strict chronological chain progression)
folks.quests.database = {
  ["fish_novice"] = {
    title = S("The Beginner's Catch"),
    giver = "quester",
    requires = nil, -- No prerequisite; available immediately
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
    requires = "fish_novice", -- Must complete fish_novice first!
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

---
-- Helper function to safely count total items of a specific type in player inventory
local function get_total_item_count(inv, item_name)
  if not inv then return 0 end
  local inv_list = inv:get_list("main")
  if not inv_list then return 0 end

  local total = 0
  for _, stack in ipairs(inv_list) do
    if stack and not stack:is_empty() and stack:get_name() == item_name then
      total = total + stack:get_count()
    end
  end
  return total
end
---

-- 2. Persistent Database Storage Engine (Luanti Serialization)
function folks.quests.load_player_db(player_name)
  if folks.quests.player_data[player_name] then
    return folks.quests.player_data[player_name]
  end

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
    for _, hud_id in ipairs(tracking.quest_slots) do
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
        local count = get_total_item_count(inv, cfg.target_item)
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

  if not inv then return false end

  local target_quest_id = nil
  local quest_cfg = nil
  
  -- Step A: First priority evaluation - check if the player already has an ongoing active quest with this NPC
  for q_id, cfg in pairs(folks.quests.database) do
    if cfg.giver == npc_id_clean and pdata.active[q_id] then
      target_quest_id = q_id
      quest_cfg = cfg
      break
    end
  end

  -- Step B: If no active assignment is running, look for the next eligible unlocked link in the timeline chain
  if not target_quest_id then
    for q_id, cfg in pairs(folks.quests.database) do
      if cfg.giver == npc_id_clean and not pdata.completed[q_id] then
        -- Strict prerequisite checklist verification gating loop
        local tracking_passed = true
        if cfg.requires and not pdata.completed[cfg.requires] then
          tracking_passed = false
        end
        
        if tracking_passed then
          target_quest_id = q_id
          quest_cfg = cfg
          break
        end
      end
    end
  end

  -- No available content remaining for this specific npc unit
  if not target_quest_id or not quest_cfg then 
    core.chat_send_player(player_name, core.colorize("#a6b2c0", npc_name_raw .. ": Clear sailing today, friend! I don't have any open cargo requests left for you."))
    return false 
  end

  -- Progression Check Loop Execution
  if pdata.active[target_quest_id] then
    local current_count = 0
    if quest_cfg.type == "gather" then
      current_count = get_total_item_count(inv, quest_cfg.target_item)
    end

    if current_count >= quest_cfg.target_count then
      -- Safe, clean programmatic removal using clean explicit stack constructor strings
      inv:remove_item("main", quest_cfg.target_item .. " " .. quest_cfg.target_count)
      
      local reward = ItemStack(quest_cfg.reward_item .. " " .. quest_cfg.reward_count)
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
  
  -- Base canvas setups
  local formspec = 
    "size[13.0,9.5]" ..
    "real_coordinates[true]" ..
    
    -- Global custom UI styling elements
    "style_type[label;font=bold;font_size=18]" ..
    "style_type[box;border=false]" ..
    "style_type[button;border=true;font=bold;font_size=15;backcolor=#1f252d;textcolor=#ffffff]" ..
    "style_type[button:hover;backcolor=#00f0ff15;textcolor=#00f0ff;bordercolor=#00f0ff]" ..
    
    -- Main deep tactical background frame
    "background[0,0;13.0,9.5;#11161b;true]" ..
    
    -- Glowing top border accent line
    "box[0,0;13.0,0.12;#00f0ff]" ..
    
    -- Top Header Navigation & Titles
    "label[0.8,0.7;#00f0ff;TECHBLOX LOGBOOK]" ..
    "label[0.8,1.15;#8899a6;Manage ongoing tactical operations and terminal assignments]" ..
    "box[0.8,1.55;11.4,0.03;#ffffff12]" -- Subtle divider line

  local row_y = 1.9
  local has_active = false
  
  for q_id, _ in pairs(pdata.active) do
    has_active = true
    local cfg = folks.quests.database[q_id]
    
    if cfg then
      -- Panel container backing card
      formspec = formspec .. 
        "box[0.8," .. row_y .. ";11.4,2.0;#ffffff04]" .. -- Translucent dark panel
        "box[0.8," .. row_y .. ";0.06,2.0;#00f0ff]"    -- Left border cyan operation accent
        
      local clean_giver = cfg.giver:gsub("^%l", string.upper)
      
      -- Quest Context Data Lines
      formspec = formspec .. 
        "label[1.2," .. (row_y + 0.4) .. ";#ffffff;" .. cfg.title .. "]" ..
        "label[1.2, " .. (row_y + 0.8) .. ";#5c6e7e;OPERATIVE: " .. clean_giver .. "]" ..
        "hypertext[1.2," .. (row_y + 1.15) .. ";6.8,0.7;desc_" .. q_id .. ";<global font=normal size=14 color=#b2c0cc>" .. cfg.description .. "]"
        
      -- Dynamic Reward Segment Card Frame
      formspec = formspec ..
        "box[8.3," .. (row_y + 0.25) .. ";3.5,1.5;#070a0d90]" .. -- Inner dark container
        "label[8.6," .. (row_y + 0.6) .. ";#ffaa00;SECURED PAYLOAD]" ..
        "item_image[8.6," .. (row_y + 0.85) .. ";0.8,0.8;" .. cfg.reward_item .. "]" ..
        "label[9.6," .. (row_y + 1.35) .. ";#ffffff;x" .. cfg.reward_count .. " Gold]"
      
      row_y = row_y + 2.3 -- Offset space padding layout for next item row
    end
  end

  -- Fallback screen render layout frame when active assignment logs evaluate to empty
  if not has_active then
    formspec = formspec .. 
      "box[3.5,3.8;6.0,2.5;#ffffff02]" ..
      "label[4.6,4.6;#8899a6;No active assignments found.]" ..
      "label[4.1,5.1;#00f0ff;Speak to folks at the docks to find work.]"
  end

  -- Persistent footer controls layout position
  formspec = formspec .. "button[10.2,8.5;2.0,0.65;quit;Close Terminal]"

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

-- Live HUD Inventory Refresh Mechanics
core.register_on_placenode(function(pos, newnode, placer)
  if placer and placer:is_player() then folks.quests.update_hud(placer) end
end)

core.register_on_dignode(function(pos, oldnode, digger)
  if digger and digger:is_player() then folks.quests.update_hud(digger) end
end)

-- Global step handler backup loop to handle loose custom node drop collection events seamlessly
local update_timer = 0
core.register_globalstep(function(dtime)
  update_timer = update_timer + dtime
  if update_timer < 2.0 then return end
  update_timer = 0

  for _, player in ipairs(core.get_connected_players()) do
    folks.quests.update_hud(player)
  end
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
