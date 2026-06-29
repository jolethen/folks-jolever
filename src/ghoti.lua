-- ghoti.lua
local S = core.get_translator("folks")

local ghoti = {}

-- 1. Complete fish pool table (Original working variables and item prices)
local fish_pool = {
  {item = "fishing:fish_bluefin",        price = 20,  label = "Bluefin Tuna"},
  {item = "fishing:fish_blueram",        price = 15,  label = "Blue Ram Cichlid"},
  {item = "fishing:fish_catfish",        price = 18,  label = "Catfish"},
  {item = "fishing:fish_plaice",         price = 11,  label = "Plaice"},
  {item = "fishing:fish_salmon",         price = 15,  label = "Salmon"},
  {item = "fishing:fish_clownfish",      price = 14,  label = "Clownfish"},
  {item = "fishing:fish_pike",           price = 24,  label = "Pike"},
  {item = "fishing:fish_flathead",       price = 16,  label = "Flathead Fish"},
  {item = "fishing:fish_pufferfish",     price = 28,  label = "Pufferfish"},
  {item = "fishing:fish_cichlid",        price = 12,  label = "Cichlid"},
  {item = "fishing:fish_coy",            price = 25,  label = "Coy Fish"},
  {item = "fishing:fish_tilapia",        price = 13,  label = "Tilapia"},
  {item = "fishing:fish_trevally",       price = 17,  label = "Trevally"},
  {item = "fishing:fish_angler",         price = 45,  label = "Anglerfish"},
  {item = "fishing:fish_jellyfish",      price = 30,  label = "Jellyfish"},
  {item = "fishing:fish_seahorse",       price = 20,  label = "Seahorse"},
  {item = "fishing:fish_seahorse_green", price = 22,  label = "Green Seahorse"},
  {item = "fishing:fish_seahorse_pink",  price = 22,  label = "Pink Seahorse"},
  {item = "fishing:fish_seahorse_blue",  price = 25,  label = "Blue Seahorse"},
  {item = "fishing:fish_seahorse_yellow",price = 22,  label = "Yellow Seahorse"},
  {item = "fishing:fish_parrot",         price = 22,  label = "Parrotfish"},
  {item = "fishing:fish_piranha",        price = 35,  label = "Piranha"},
  {item = "fishing:fish_tuna",           price = 18,  label = "Tuna"},
  {item = "fishing:fish_trout",          price = 14,  label = "Trout"},
  {item = "fishing:fish_cod",            price = 8,   label = "Raw Cod"},
  {item = "fishing:fish_flounder",       price = 14,  label = "Flounder"},
  {item = "fishing:fish_redsnapper",     price = 20,  label = "Red Snapper"},
  {item = "fishing:fish_squid",          price = 32,  label = "Squid"},
  {item = "fishing:fish_shrimp",         price = 6,   label = "Shrimp"},
  {item = "fishing:fish_carp",           price = 10,  label = "Carp"},
  {item = "fishing:fish_tetra",          price = 7,   label = "Neon Tetra"},
  {item = "fishing:fish_mackerel",       price = 9,   label = "Mackerel"}
}

-- Global market state table
ghoti.market = {
  active_deals = {},
  last_roll_time = 0
}

-- Safe pool picker routine matching your original code logic
local function refresh_market_deals()
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
    local base_fish = fish_pool[idx]
    local random_stock = math.random(1, 10)
    
    table.insert(ghoti.market.active_deals, {
      item = base_fish.item,
      price = base_fish.price,
      label = base_fish.label,
      stock = random_stock,
      max_stock = random_stock,
      out_of_stock_time = nil
    })
  end
  ghoti.market.last_roll_time = core.get_us_time()
end

-- Checks background stock restock timers
local function check_and_restock_items()
  local current_time = core.get_us_time()
  
  for _, deal in ipairs(ghoti.market.active_deals) do
    if deal.stock == 0 and deal.out_of_stock_time then
      local seconds_elapsed = (current_time - deal.out_of_stock_time) / 1000000
      
      if seconds_elapsed >= 600 then -- 10 Minutes
        deal.stock = math.random(1, 10)
        deal.max_stock = deal.stock
        deal.out_of_stock_time = nil
      end
    end
  end
end

-- Fixed layout using standard real_coordinates and labels (No custom title tags to break loading)
function ghoti.show_formspec(player_name)
  check_and_restock_items()
  
  local current_time = core.get_us_time()
  local elapsed_seconds = (current_time - ghoti.market.last_roll_time) / 1000000
  local time_left_mins = math.max(0, math.floor(60 - (elapsed_seconds / 60)))

  local formspec = 
    "size[11.5,8.5]" ..
    "real_coordinates[true]" ..
    "label[0.5,0.5;Ghoti's Fish Market]" ..
    "label[0.5,0.9;Offers refresh in: " .. time_left_mins .. " minutes]" ..
    "box[0.5,1.2;10.5,0.02;#ffffff]"

  local row_y = 1.5
  for i, deal in ipairs(ghoti.market.active_deals) do
    local stock_info = "Stock: " .. deal.stock .. "/" .. deal.max_stock
    local display_button = "button[9.0," .. row_y .. ";2.0,0.7;ghoti_sell_" .. i .. ";Sell 1x]"
    
    if deal.stock == 0 and deal.out_of_stock_time then
      local elapsed = (current_time - deal.out_of_stock_time) / 1000000
      local remaining_cooldown = math.max(0, math.floor(10 - (elapsed / 60)))
      stock_info = "OUT OF STOCK (Restocking in " .. remaining_cooldown .. "m)"
      display_button = "button[9.0," .. row_y .. ";2.0,0.7;disabled;Sold Out]"
    end

    formspec = formspec ..
      "item_image[0.6," .. row_y .. ";0.8,0.8;" .. deal.item .. "]" ..
      "label[1.6," .. (row_y + 0.15) .. ";" .. deal.label .. "]" ..
      "label[1.6," .. (row_y + 0.5) .. ";" .. stock_info .. "]" ..
      "label[5.8," .. (row_y + 0.3) .. ";Value: " .. deal.price .. " Minegeld]" ..
      display_button
      
    row_y = row_y + 0.9
  end

  formspec = formspec ..
    "box[0.5,6.0;10.5,0.02;#ffffff]" ..
    "list[current_player;main;1.7,6.3;8,2;]" ..
    "listring[current_player;main]"

  core.show_formspec(player_name, "folks:ghoti_market", formspec)
end

-- Modular execution hook run by roles.lua engine registry
function ghoti.on_interact(player)
  local player_name = player:get_player_name()
  local current_time = core.get_us_time()

  if #ghoti.market.active_deals == 0 or ((current_time - ghoti.market.last_roll_time) / 1000000 >= 3600) then
    refresh_market_deals()
  end

  ghoti.show_formspec(player_name)
end

-- Primary Formspec Field Interceptor
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:ghoti_market" then return false end
  local player_name = player:get_player_name()

  for i = 1, 5 do
    if fields["ghoti_sell_" .. i] then
      check_and_restock_items()
      
      local deal = ghoti.market.active_deals[i]
      
      if deal and deal.stock > 0 then
        local inv = player:get_inventory()
        
        if inv:contains_item("main", ItemStack(deal.item)) then
          inv:remove_item("main", ItemStack(deal.item .. " 1"))
          
          deal.stock = deal.stock - 1
          if deal.stock == 0 then
            deal.out_of_stock_time = core.get_us_time()
          end
          
          inv:add_item("main", ItemStack("currency:minegeld " .. deal.price))
          core.chat_send_player(player_name, core.colorize("#00ff00", "Ghoti: Thanks! Here is your " .. deal.price .. " Minegeld for the " .. deal.label .. "."))
          
          ghoti.show_formspec(player_name)
        else
          core.chat_send_player(player_name, core.colorize("#ff3333", "Ghoti: You don't have any " .. deal.label .. " in your bag!"))
        end
      elseif deal and deal.stock == 0 then
        core.chat_send_player(player_name, core.colorize("#ff3333", "Ghoti: I cannot buy more of that right now. I am completely full!"))
      end
      return true
    end
  end
end)

return ghoti
