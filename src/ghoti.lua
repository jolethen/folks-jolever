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

-- Instance directory tracking individual state per unique NPC ID
ghoti.markets = {}

-- Tracks which player is talking to which unique NPC ID
local player_current_npc = {}

-- Pick 5 unique fishes out of the pool for a SPECIFIC NPC
local function refresh_npc_deals(npc_id)
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

  ghoti.markets[npc_id] = {
    active_deals = {},
    last_roll_time = core.get_us_time()
  }

  for _, idx in ipairs(indices) do
    local base_fish = fish_pool[idx]
    local random_stock = math.random(1, 10)
    
    table.insert(ghoti.markets[npc_id].active_deals, {
      item = base_fish.item,
      price = base_fish.price,
      label = base_fish.label,
      stock = random_stock,
      max_stock = random_stock,
      out_of_stock_time = nil
    })
  end
end

-- Checks and restocks items for a SPECIFIC NPC
local function check_and_restock_items(npc_id)
  local market = ghoti.markets[npc_id]
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

-- Generate user interface layout using the formspecs.lua design style
function ghoti.get_market_formspec(npc_id, npc_display_name)
  check_and_restock_items(npc_id)
  
  local market = ghoti.markets[npc_id]
  if not market then return "" end

  local current_time = core.get_us_time()
  local elapsed_seconds = (current_time - market.last_roll_time) / 1000000
  local time_left_mins = math.max(0, math.floor(60 - (elapsed_seconds / 60)))
  local escape = core.formspec_escape

  -- Mirroring the array table format from formspecs.lua
  local formspec = {
    "formspec_version[3]",
    "size[11.5,11.0]",
    "label[4.2,0.6;" .. escape(npc_display_name .. "'s Fish Market") .. "]",
    "label[0.7,1.2;" .. S("Offers refresh in: @1 minutes", time_left_mins) .. "]",
    "box[0.5,1.6;10.5,0.02;#ffffff]"
  }

  local row_y = 2.0
  for i, deal in ipairs(market.active_deals) do
    local stock_info = "Stock: " .. deal.stock .. "/" .. deal.max_stock
    local display_button = "button[9.0," .. row_y .. ";1.8,0.7;ghoti_sell_" .. i .. ";Sell 1x]"
    
    if deal.stock == 0 and deal.out_of_stock_time then
      local elapsed = (current_time - deal.out_of_stock_time) / 1000000
      local remaining_cooldown = math.max(0, math.floor(10 - (elapsed / 60)))
      stock_info = "SOLD OUT (Restocking in " .. remaining_cooldown .. "m)"
      display_button = "button_exit[9.0," .. row_y .. ";1.8,0.7;disabled;Sold Out]"
    end

    table.insert(formspec, "item_image[0.7," .. row_y .. ";0.8,0.8;" .. deal.item .. "]")
    table.insert(formspec, "label[1.8," .. (row_y + 0.05) .. ";" .. escape(deal.label) .. "]")
    table.insert(formspec, "label[1.8," .. (row_y + 0.45) .. ";" .. escape(stock_info) .. "]")
    table.insert(formspec, "label[5.8," .. (row_y + 0.25) .. ";Value: " .. deal.price .. " Minegeld]")
    table.insert(formspec, display_button)
      
    row_y = row_y + 1.0
  end

  table.insert(formspec, "box[0.5,7.2;10.5,0.02;#ffffff]")
  table.insert(formspec, "list[current_player;main;1.7,7.6;8,2;]")
  table.insert(formspec, "listring[current_player;main]")
  table.insert(formspec, "button_exit[10.0,0.3;1,0.6;folks_close_market;X]")

  return table.concat(formspec)
end

-- Central interaction handler called by your NPCs
function ghoti.on_interact(player, npc_id, npc_display_name)
  local player_name = player:get_player_name()
  player_current_npc[player_name] = { id = npc_id, name = npc_display_name }

  local market = ghoti.markets[npc_id]
  local current_time = core.get_us_time()
  
  if not market then
    refresh_npc_deals(npc_id)
  else
    local elapsed = (current_time - market.last_roll_time) / 1000000
    if elapsed >= 3600 then
      refresh_npc_deals(npc_id)
    else
      check_and_restock_items(npc_id)
    end
  end

  local fs = ghoti.get_market_formspec(npc_id, npc_display_name)
  core.show_formspec(player_name, "folks:ghoti_market", fs)
end

-- Formspec UI Intercept Event Handler
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:ghoti_market" then return false end
  local player_name = player:get_player_name()
  
  local npc_context = player_current_npc[player_name]
  if not npc_context then return true end
  
  local npc_id = npc_context.id
  local npc_display_name = npc_context.name
  local market = ghoti.markets[npc_id]
  if not market then return true end

  if fields.folks_close_market or fields.quit then
    player_current_npc[player_name] = nil
    return true
  end

  for i = 1, 5 do
    if fields["ghoti_sell_" .. i] then
      check_and_restock_items(npc_id)
      
      local deal = market.active_deals[i]
      
      if deal and deal.stock > 0 then
        local inv = player:get_inventory()
        
        if inv:contains_item("main", ItemStack(deal.item)) then
          inv:remove_item("main", ItemStack(deal.item .. " 1"))
          inv:add_item("main", ItemStack("currency:minegeld 5"))
          
          deal.stock = deal.stock - 1
          if deal.stock == 0 then
            deal.out_of_stock_time = core.get_us_time()
          end
          
          core.chat_send_player(player_name, core.colorize("#00ff00", npc_display_name .. ": Thanks! Here is your 5 Minegeld for the " .. deal.label .. "."))
          
          -- Clean, stable redrawing loop match
          local fs = ghoti.get_market_formspec(npc_id, npc_display_name)
          core.show_formspec(player_name, "folks:ghoti_market", fs)
        else
          core.chat_send_player(player_name, core.colorize("#ff3333", npc_display_name .. ": You don't have any " .. deal.label .. " in your bag!"))
        end
      elseif deal and deal.stock == 0 then
        core.chat_send_player(player_name, core.colorize("#ff3333", npc_display_name .. ": I cannot buy more of that right now. I am completely full!"))
      end
      return true
    end
  end
end)

core.register_on_leaveplayer(function(player)
  player_current_npc[player:get_player_name()] = nil
end)

return ghoti
