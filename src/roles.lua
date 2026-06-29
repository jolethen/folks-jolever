-- roles.lua
roles = {} -- Exposed globally so the folks engine can read this registry

-- Safely locate and load the external specialized scripts[cite: 2]
local modpath = core.get_modpath("folks")[cite: 2]

-- Load Ghoti (Fisherman Shop Engine)[cite: 2]
local ghoti_file = loadfile(modpath .. "/src/ghoti.lua")[cite: 2]
local ghoti = ghoti_file and ghoti_file()[cite: 2]

-- Load the Quest System Core Logic[cite: 2]
local quest_file = loadfile(modpath .. "/src/quests.lua")[cite: 2]
local quest_sys = quest_file and quest_file()[cite: 2]

-- Load the Quest Graphical User Interface Panel / Commands[cite: 2]
local quest_gui_file = loadfile(modpath .. "/src/quests_gui.lua")[cite: 2]
if quest_gui_file then[cite: 2]
  quest_gui_file()[cite: 2]
end[cite: 2]

-- Define your roles here[cite: 2]
roles.registry = {
  -- INDEPENDENT REGISTRATIONS: Each name is its own distinct role entry
  ["ghoti"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self)[cite: 2]
      else core.chat_send_player(player:get_player_name(), "[System Error]: Ghoti module failed.") end
    end
  },
  ["allison"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Allison module failed.") end
    end
  },
  ["phillips"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Phillips module failed.") end
    end
  },
  ["jack"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Jack module failed.") end
    end
  },
  ["david"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: David module failed.") end
    end
  },
  ["felix"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Felix module failed.") end
    end
  },
  ["james"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: James module failed.") end
    end
  },
  ["walker"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Walker module failed.") end
    end
  },

  ["banker"] = {[cite: 2]
    action = function(player, npc_self)[cite: 2]
      local player_name = player:get_player_name()[cite: 2]
      local formspec_name = "folks:bank_interface"[cite: 2]
      local formspec = [cite: 2]
        "size[6,4]" ..[cite: 2]
        "real_coordinates[true]" ..[cite: 2]
        "label[2.5,0.5;Bank]" .. [cite: 2]
        "box[0.5,1.0;5,0.05;#ffffff]" ..[cite: 2]
        "label[0.5,1.8;Welcome to the banking terminal!]" ..[cite: 2]
        "label[0.5,2.3;Account services will appear here.]" ..[cite: 2]
        "button_exit[2.0,3.2;2.0,0.6;close;Exit]"[cite: 2]
      core.show_formspec(player_name, formspec_name, formspec)[cite: 2]
    end[cite: 2]
  },[cite: 2]
  
  ["quester"] = {[cite: 2]
    action = function(player, npc_self)[cite: 2]
      if quest_sys then[cite: 2]
        quest_sys.handle_npc_interaction(player, "Quester")[cite: 2]
      else[cite: 2]
        core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Quest subsystem failed to load."))[cite: 2]
      end[cite: 2]
    end[cite: 2]
  },[cite: 2]
  
  ["doctor"] = {[cite: 2]
    action = function(player, npc_self)[cite: 2]
      player:set_hp(player:get_properties().hp_max)[cite: 2]
      core.chat_send_player(player:get_player_name(), "The Doctor has healed you!")[cite: 2]
    end[cite: 2]
  },[cite: 2]
}

return roles[cite: 2]
