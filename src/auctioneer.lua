-- src/auctioneer.lua
-- Auction House NPC Module for Techblox

local auctioneer = {}

function auctioneer.on_interact(player, npc_self)
  if not player or not player:is_player() then return end
  local player_name = player:get_player_name()

  -- Call the formspec from eco_trade/auction.lua
  if eco_trade and eco_trade.show_ah then
    eco_trade.show_ah(player_name, 1)
  else
    core.chat_send_player(player_name, core.colorize("#ff3333", "[Auctioneer]: The Auction House is currently offline."))
  end
end

return auctioneer
