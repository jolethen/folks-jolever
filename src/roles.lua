-- roles.lua
roles = {} -- Exposed globally so the folks engine can read this registry

-- Safely locate and load the external specialized scripts
local modpath = core.get_modpath("folks")

-- Load Ghoti (Fisherman Shop Engine)
local ghoti_file = loadfile(modpath .. "/src/ghoti.lua")
local ghoti = ghoti_file and ghoti_file()

-- Load the Quest System Core Logic
local quest_file = loadfile(modpath .. "/src/quests.lua")
local quest_sys = quest_file and quest_file()

-- Load the Quest Graphical User Interface Panel / Commands
local quest_gui_file = loadfile(modpath .. "/src/quests_gui.lua")
if quest_gui_file then
  quest_gui_file()
end

-- Define your roles here
roles.registry = {
  -- INDEPENDENT REGISTRATIONS: Each name is its own distinct role entry
  ["ghoti"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self)
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

  ["banker"] = {
    action = function(player, npc_self)
      local player_name = player:get_player_name()
      local formspec_name = "folks:bank_interface"
      local formspec = 
        "size[6,4]" ..
        "real_coordinates[true]" ..
        "label[2.5,0.5;Bank]" .. 
        "box[0.5,1.0;5,0.05;#ffffff]" ..
        "label[0.5,1.8;Welcome to the banking terminal!]" ..
        "label[0.5,2.3;Account services will appear here.]" ..
        "button_exit[2.0,3.2;2.0,0.6;close;Exit]"
      core.show_formspec(player_name, formspec_name, formspec)
    end
  },
  
  ["quester"] = {
    action = function(player, npc_self)
      if quest_sys then
        quest_sys.handle_npc_interaction(player, "Quester")
      else
        core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Quest subsystem failed to load."))
      end
    end
  },
  
  ["doctor"] = {
    action = function(player, npc_self)
      player:set_hp(player:get_properties().hp_max)
      core.chat_send_player(player:get_player_name(), "The Doctor has healed you!")
    end
  },
}

return roles
