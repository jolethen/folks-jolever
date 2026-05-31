-- roles.lua
local roles = {}

-- Define your roles here
roles.registry = {
  ["banker"] = {
    -- This function runs when the player right-clicks a banker
    action = function(player, npc_self)
      -- Check if your banking mod exists before calling it
      if your_banking_mod and your_banking_mod.open_bank_gui then
        your_banking_mod.open_bank_gui(player)
      else
        local name = player:get_player_name()
        core.chat_send_player(name, core.colorize("#ff3333", "[System Error]: Banking interface unavailable."))
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
