-- roles.lua
local roles = {}

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
