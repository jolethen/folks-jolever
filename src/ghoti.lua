-- ghoti.lua
local S = core.get_translator("folks")

local ghoti = {}

-- 1. Complete fish pool table (All prices strictly set to 5 Minegeld)
local fish_pool = {
  {item = "fishing:fish_bluefin",        price = 5,  label = "Bluefin Tuna"},
  {item = "fishing:fish_blueram",        price = 5,  label = "Blue Ram Cichlid"},
  {item = "fishing:fish_catfish",        price = 5,  label = "Catfish"},
  {item = "fishing:fish_plaice",         price = 5,  label = "Plaice"},
  {item = "fishing:fish_salmon",         price = 5,  label = "Salmon"},
  {item = "fishing:fish_clownfish",      price = 5,  label = "Clownfish"},
  {item = "fishing:fish_pike",           price = 5,  label = "Pike"},
  {item = "fishing:fish_flathead",       price = 5,  label = "Flathead Fish"},
  {item = "fishing:fish_pufferfish",     price = 5,  label = "Pufferfish"},
  {item = "fishing:fish_cichlid",        price = 5,  label = "Cichlid"},
  {item = "fishing:fish_coy",            price = 5,  label = "Coy Fish"},
  {item = "fishing:fish_tilapia",        price = 5,  label = "Tilapia"},
  {item = "fishing:fish_trevally",       price = 5,  label = "Trevally"},
  {item = "fishing:fish_angler",         price = 5,  label = "Anglerfish"},
  {item = "fishing:fish_jellyfish",      price = 5,  label = "Jellyfish"},
  {item = "fishing:fish_seahorse",       price = 5,  label = "Seahorse"},
  {item = "fishing:fish_seahorse_green", price = 5,  label = "Green Seahorse"},
  {item = "fishing:fish_seahorse_pink",  price = 5,  label = "Pink Seahorse"},
  {item = "fishing:fish_seahorse_blue",  price = 5,  label = "Blue Seahorse"},
  {item = "fishing:fish_seahorse_yellow",price = 5,  label = "Yellow Seahorse"},
  {item = "fishing:fish_parrot",         price = 5,  label = "Parrotfish"},
  {item = "fishing:fish_piranha",        price = 5,  label = "Piranha"},
  {item = "fishing:fish_tuna",           price = 5,  label = "Tuna"},
  {item = "fishing:fish_trout",          price = 5,  label = "Trout"},
  {item = "fishing:fish_cod",            price = 5,  label = "Raw Cod"},
  {item = "fishing:fish_flounder",       price = 5,  label = "Flounder"},
  {item = "fishing:fish_redsnapper",     price = 5,  label = "Red Snapper"},
  {item = "fishing:fish_squid",          price = 5,  label = "Squid"},
  {item = "fishing:fish_shrimp",         price = 5,  label = "Shrimp"},
  {item = "fishing:fish_carp",           price = 5,  label = "Carp"},
  {item = "fishing:fish_tetra",          price = 5,  label = "Neon Tetra"},
  {item = "fishing:fish_mackerel",       price = 5,  label = "Mackerel"}
}

-- Multi-NPC market directory tracking individual stock and display names per unique key
ghoti.markets = {}

-- Tracks which active player session is talking to which specific NPC instance
local player_current_npc = {}

-- Helper function to generate a reliable unique string key from the npc_self object
local function get_npc_key(npc_self)
  if not npc_self then return "default" end
  if npc_self._npc_id then return tostring(npc_self._npc_id) end
  if npc_self.object then 
    local pos = npc_self.object:get_pos()
    if pos then return math.floor(pos.x) .. "_" .. math.floor(pos.y) .. "_" .. math.floor(pos.z) end
  end
  return tostring(npc_self)
end

-- Helper function to resolve the active name string directly from the NPC object
local function get_npc_display_name(npc_self)
  if not npc_self then return "Fisherman" end
  -- Checks fallback path sequence for standard folks structure
  if npc_self._npc_id and folks and folks.get_npc then
    local npc_data = folks.get_npc(npc_self._npc_id)
    if npc_data and npc_data._npc_name then
      return npc_data._npc_name
    end
  end
  if npc_self.initial_properties and npc_self.initial_properties.nametag then
    return npc_self.initial_properties.nametag
  end
  return "Fisherman"
end

-- Pick 5 unique fishes out of the pool for a SPECIFIC NPC
local function refresh_npc_deals(npc_key, display_name)
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

  ghoti.markets[npc_key] = {
    title_name = display_name,
    active_deals = {},
    last_roll_time = core.get_us_time()
  }

  for _, idx in ipairs(indices) do
    local base_fish = fish_pool[idx]
    local random_stock = math.random(1, 10)
    
    table.insert(ghoti.markets[npc_key].active_deals, {
      item = base_fish.item,
      price = base_fish.price,
      label = base_fish.label,
      stock = random_stock,
      max_stock = random_stock,
      out_of_stock_time = nil
    })
  end
end

-- Checks background stock restock timers for a SPECIFIC NPC
local function check_and_restock_items(npc_key)
  local market = ghoti.markets[npc_key]
  if not market then return end

  local current_time = core.get_us_time()
  
  for _, deal in ipairs(market.active_deals) do
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

-- Fixed layout utilizing real_coordinates structure with isolated NPC instance reference
function ghoti.show_formspec(player_name, npc_key)
  check_and_restock_items(npc_key)
  
  local market = ghoti.markets[npc_key]
  local current_time = core.get_us_time()
  local elapsed_seconds = (current_time - market.last_roll_time) / 1000000
  local time_left_mins = math.max(0, math.floor(60 - (elapsed_seconds / 60)))
  
  -- Generates personalized name dynamically e.g. "Allison's Fish Market"
  local shop_title = market.title_name .. "'s Fish Market"

  local formspec = 
    "size[11.5,8.5]" ..
    "real_coordinates[true]" ..
    "label[0.5,0.5;" .. shop_title .. "]" ..
    "label[0.5,0.9;Offers refresh in: " .. time_left_mins .. " minutes]" ..
    "box[0.5,1.2;10.5,0.02;#ffffff]"

  local row_y = 1.5
  for i, deal in ipairs(market.active_deals) do
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

-- Hook entry parsing down the verified NPC entity instance reference
function ghoti.on_interact(player, npc_self)
  local player_name = player:get_player_name()
  local npc_key = get_npc_key(npc_self)
  local display_name = get_npc_display_name(npc_self)
  
  player_current_npc[player_name] = npc_key

  local current_time = core.get_us_time()
  
  -- If this specific NPC has no market registered yet, or an hour has passed, spin up fresh unique deals
  if not ghoti.markets[npc_key] or ((current_time - ghoti.markets[npc_key].last_roll_time) / 1000000 >= 3600) then
    refresh_npc_deals(npc_key, display_name)
  else
    check_and_restock_items(npc_key)
  end

  ghoti.show_formspec(player_name, npc_key)
end

-- Formspec submission receiver handling unique active pools
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:ghoti_market" then return false end
  local player_name = player:get_player_name()

  local npc_key = player_current_npc[player_name]
  if not npc_key or not ghoti.markets[npc_key] then return true end

  if fields.quit then
    player_current_npc[player_name] = nil
    return true
  end

  local market = ghoti.markets[npc_key]

  for i = 1, 5 do
    if fields["ghoti_sell_" .. i] then
      check_and_restock_items(npc_key)
      
      local deal = market.active_deals[i]
      
      if deal and deal.stock > 0 then
        local inv = player:get_inventory()
        
        if inv:contains_item("main", ItemStack(deal.item)) then
          inv:remove_item("main", ItemStack(deal.item .. " 1"))
          
          deal.stock = deal.stock - 1
          if deal.stock == 0 then
            deal.out_of_stock_time = core.get_us_time()
          end
          
          -- Pay out exactly 5 Minegeld notes
          inv:add_item("main", ItemStack("currency:minegeld " .. deal.price))
          core.chat_send_player(player_name, core.colorize("#00ff00", market.title_name .. ": Thanks! Here is your " .. deal.price .. " Minegeld for the " .. deal.label .. "."))
          
          ghoti.show_formspec(player_name, npc_key)
        else
          core.chat_send_player(player_name, core.colorize("#ff3333", market.title_name .. ": You don't have any " .. deal.label .. " in your bag!"))
        end
      elseif deal and deal.stock == 0 then
        core.chat_send_player(player_name, core.colorize("#ff3333", market.title_name .. ": I cannot buy more of that right now!"))
      end
      return true
    end
  end
end)

core.register_on_leaveplayer(function(player)
  player_current_npc[player:get_player_name()] = nil
end)

return ghoti
