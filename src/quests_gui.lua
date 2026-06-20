-- quests_gui.lua
-- Techblox Graphical Interface Frame Layouts

function folks.quests.show_quest_log(player_name)
  local pdata = folks.quests.player_data[player_name] or folks.quests.load_player_db(player_name)
  
  local formspec = 
    "size[13.0,9.5]" ..
    "real_coordinates[true]" ..
    "style_type[label;font=bold;font_size=18]" ..
    "style_type[box;border=false]" ..
    "style_type[button;border=true;font=bold;font_size=15;backcolor=#1f252d;textcolor=#ffffff]" ..
    "style_type[button:hover;backcolor=#00f0ff15;textcolor=#00f0ff;bordercolor=#00f0ff]" ..
    "background[0,0;13.0,9.5;#11161b;true]" ..
    "box[0,0;13.0,0.12;#00f0ff]" ..
    "label[0.8,0.7;#00f0ff;TECHBLOX LOGBOOK]" ..
    "label[0.8,1.15;#8899a6;Manage ongoing tactical operations and terminal assignments]" ..
    "box[0.8,1.55;11.4,0.03;#ffffff12]"

  local row_y = 1.9
  local has_active = false
  
  for q_id, _ in pairs(pdata.active) do
    has_active = true
    local cfg = folks.quests.database[q_id]
    
    if cfg then
      formspec = formspec .. 
        "box[0.8," .. row_y .. ";11.4,2.0;#ffffff04]" .. 
        "box[0.8," .. row_y .. ";0.06,2.0;#00f0ff]"    
        
      local clean_giver = cfg.giver:gsub("^%l", string.upper)
      
      formspec = formspec .. 
        "label[1.2," .. (row_y + 0.4) .. ";#ffffff;" .. cfg.title .. "]" ..
        "label[1.2, " .. (row_y + 0.8) .. ";#5c6e7e;OPERATIVE: " .. clean_giver .. "]" ..
        "hypertext[1.2," .. (row_y + 1.15) .. ";6.8,0.7;desc_" .. q_id .. ";<global font=normal size=14 color=#b2c0cc>" .. cfg.description .. "]"
        
      formspec = formspec ..
        "box[8.3," .. (row_y + 0.25) .. ";3.5,1.5;#070a0d90]" .. 
        "label[8.6," .. (row_y + 0.6) .. ";#ffaa00;SECURED PAYLOAD]" ..
        "item_image[8.6," .. (row_y + 0.85) .. ";0.8,0.8;" .. cfg.reward_item .. "]" ..
        "label[9.6," .. (row_y + 1.35) .. ";#ffffff;x" .. cfg.reward_count .. " Gold]"
      
      row_y = row_y + 2.3 
    end
  end

  if not has_active then
    formspec = formspec .. 
      "box[3.5,3.8;6.0,2.5;#ffffff02]" ..
      "label[4.6,4.6;#8899a6;No active assignments found.]" ..
      "label[4.1,5.1;#00f0ff;Speak to folks at the docks to find work.]"
  end

  formspec = formspec .. "button[10.2,8.5;2.0,0.65;quit;Close Terminal]"

  core.show_formspec(player_name, "folks:quest_log", formspec)
end

-- Hook the command to load the graphical frame
core.register_chatcommand("quests", {
  description = "Open your active quest log menu",
  func = function(name)
    folks.quests.show_quest_log(name)
    return true
  end
})
