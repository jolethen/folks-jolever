-- src/banker.lua
local S = core.get_translator("folks")
local banker = {}

-- 1. HOOK ENTRYPOINT (Right-click handler)
function banker.on_interact(player, npc_self)
  if not player or not player:is_player() then return end
  local player_name = player:get_player_name()

  -- Call your bank module GUI or display the Folks Bank Interface
  if eco_trade and eco_trade.show_bank_gui then
    eco_trade.show_bank_gui(player_name)
  else
    banker.show_fallback_interface(player_name)
  end
end

-- 2. FALLBACK GUI (If eco_trade isn't loaded)
function banker.show_fallback_interface(player_name)
  local formspec = 
    "size[6,4]" ..
    "real_coordinates[true]" ..
    "background[0,0;6,4;techblox_terminal_bg.png;true]" ..
    "label[2.1,0.5;" .. core.colorize("#e066ff", "CENTRAL BANK") .. "]" .. 
    "box[0.5,1.0;5,0.02;#ffffff15]" ..
    "label[0.5,1.8;Welcome to the Central Bank terminal!]" ..
    "label[0.5,2.3;Vault services are currently initializing.]" ..
    "button_exit[2.0,3.1;2.0,0.6;close;Exit]"

  core.show_formspec(player_name, "folks:bank_interface", formspec)
end

return banker
