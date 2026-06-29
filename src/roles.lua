-- roles.lua
roles = {} -- Fixed: Exposed globally so the folks engine can read this registry

-- Safely locate and load the external specialized scripts
local modpath = core.get_modpath("folks")

-- Load Ghoti (Fisherman Shop)
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
  ["banker"] = {
    -- This function runs when the player right-clicks a banker
    action = function(player, npc_self)
      local player_name = player:get_player_name()
      
      -- Define a unique name for this formspec session
      local formspec_name = "folks:bank_interface"
      
      -- Designing a clean, standard 6x4 container UI
      local formspec = 
        "size[6,4]" ..
        "real_coordinates[true]" ..
        -- Centered Header Text
        "label[2.5,0.5;Bank]" .. 
        -- A decorative separator line or box style indicator
        "box[0.5,1.0;5,0.05;#ffffff]" ..
        -- Placeholder content text inside the bank window
        "label[0.5,1.8;Welcome to the banking terminal!]" ..
        "label[0.5,2.3;Account services will appear here.]" ..
        -- An exit button to cleanly dismiss the screen
        "button_exit[2.0,3.2;2.0,0.6;close;Exit]"
        
      -- Render the UI safely to the player's screen
      core.show_formspec(player_name, formspec_name, formspec)
    end
  },
  
  ["ghoti"] = {
    -- Handled via separate clean mod script chunk
    action = function(player, npc_self)
      if ghoti then
        -- Fixed: Added npc_self parameter to support independent shop inventories
        ghoti.on_interact(player, npc_self)
      else
        core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Fisherman module failed to load."))
      end
    end
  },
  
  ["quester"] = {
    -- Central Operational Taskmaster role
    action = function(player, npc_self)
      if quest_sys then
        -- Passes the clean name string "Quester" to match the database logic
        quest_sys.handle_npc_interaction(player, "Quester")
      else
        core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Quest subsystem failed to load."))
      end
    end
  },
  
  ["doctor"] = {
    -- Example of an extra role you can easily add later!
    action = function(player, npc_self)
      -- Heal the player completely
      player:set_hp(player:get_properties().hp_max)
      core.chat_send_player(player:get_player_name(), "The Doctor has healed you!")
    end
  },
}

return roles
