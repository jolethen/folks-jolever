-- ghoti.lua
local S = core.get_translator("folks")

local ghoti = {}

-- 1. Total Pool of 20 Fishes with their base purchase reward values
local fish_pool = {
  {item = "default:clownfish",      price = 10,  label = "Clownfish"},
  {item = "default:blue_tang",      price = 12,  label = "Blue Tang"},
  {item = "default:salmon",         price = 15,  label = "Raw Salmon"},
  {item = "default:cod",            price = 8,   label = "Raw Cod"},
  {item = "default:pufferfish",     price = 25,  label = "Pufferfish"},
  {item = "default:trout",          price = 14,  label = "River Trout"},
  {item = "default:tuna",           price = 18,  label = "Bluefin Tuna"},
  {item = "default:mackerel",       price = 11,  label = "Mackerel"},
  {item = "default:carp",           price = 9,   label = "Common Carp"},
  {item = "default:bass",           price = 16,  label = "Largemouth Bass"},
  {item = "default:catfish",        price = 20,  label = "Channel Catfish"},
  {item = "default:goldfish",       price = 5,   label = "Goldfish"},
  {item = "default:anglerfish",     price = 50,  label = "Deep-Sea Angler"},
  {item = "default:swordfish",      price = 45,  label = "Swordfish"},
  {item = "default:shark_fin",      price = 100, label = "Small Shark"},
  {item = "default:eel",            price = 22,  label = "Electric Eel"},
  {item = "default:octopus",        price = 35,  label = "Squid Tentacle"},
  {item = "default:shrimp",         price = 6,   label = "Tiger Shrimp"},
  {item = "default:lobster",        price = 40,  label = "Rock Lobster"},
  {item = "default:crab",           price = 15,  label = "Mud Crab"}
}

-- Market state management tracking
ghoti.market = {
  active_deals = {},
  last_roll_time = 0
}

-- Pick 5 unique fishes out of the pool
local function refresh_ghoti_deals()
  local indices = {}
  while #indices < 5 do
    local rand_idx = math.random(1, #fish_pool)
    local exists = false
    for _, v in ipairs(indices) do
      if v == rand_idx then exists = true break end
    end
    if not exists then
      table.insert(indices, rand_idx)
    end
  end

  ghoti.market.active_deals = {}
  for _, idx in ipairs(indices) do
    table.insert(ghoti.market.active_deals, fish_pool[idx])
  end
  ghoti.market.last_roll_time = core.get_us_time()
end

-- Generate the graphical user interface
function ghoti.show_formspec(player_name)
  local current_time = core.get_us_time()
  local elapsed_seconds = (current_time - ghoti.market.last_roll_time) / 1000000
  local time_left_mins = math.max(0, math.floor(60 - (elapsed_seconds / 60)))

  local formspec = 
    "size[10,8.5]" ..
    "real_coordinates[true]" ..
    "title[0.5,0.4;Ghoti's Fish Market]" ..
    "label[0.5,0.9;Offers refresh in: " .. time_left_mins .. " minutes]" ..
    "box[0.5,1.2;9,0.02;#ffffff]"

  local row_y = 1.5
  for i, deal in ipairs(ghoti.market.active_deals) do
    formspec = formspec ..
      "item_image[0.6," .. row_y .. ";0.8,0.8;" .. deal.item .. "]" ..
      "label[1.6," .. (row_y + 0.25) .. ";" .. deal.label .. "]" ..
      "label[5.0," .. (row_y + 0.25) .. ";Value: " .. deal.price .. " Gold]" ..
      "button[7.5," .. row_y .. ";1.8,0.7;ghoti_sell_" .. i .. ";Sell 1x]"
    row_y = row_y + 0.9
  end

  formspec = formspec .. 
    "box[0.5,6.0;9,0.02;#ffffff]" ..
    "list[current_player;main;0.5,6.3;8,2;]" ..
    "listring[current_player;main]"

  core.show_formspec(player_name, "folks:ghoti_market", formspec)
end

-- This executes when Ghoti is right-clicked via the roles engine
function ghoti.on_interact(player)
  local current_time = core.get_us_time()
  local elapsed = (current_time - ghoti.market.last_roll_time) / 1000000
  
  if #ghoti.market.active_deals == 0 or elapsed >= 3600 then
    refresh_ghoti_deals()
  end

  ghoti.show_formspec(player:get_player_name())
end

-- Formspec Event Handler
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:ghoti_market" then return false end
  local player_name = player:get_player_name()

  for i = 1, 5 do
    if fields["ghoti_sell_" .. i] then
      local deal = ghoti.market.active_deals[i]
      if deal then
        local inv = player:get_inventory()
        
        if inv:contains_item("main", ItemStack(deal.item)) then
          inv:remove_item("main", ItemStack(deal.item .. " 1"))
          
          -- Payout Notification (Add your server economy balance changes here!)
          core.chat_send_player(player_name, core.colorize("#00ff00", "Ghoti: Thanks! Here is your " .. deal.price .. " Gold for the " .. deal.label .. "."))
          
          ghoti.show_formspec(player_name)
        else
          core.chat_send_player(player_name, core.colorize("#ff3333", "Ghoti: You don't have any " .. deal.label .. " in your bag!"))
        end
      end
      return true
    end
  end
end)

return ghoti
