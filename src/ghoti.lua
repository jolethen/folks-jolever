-- ghoti.lua
local S = core.get_translator("folks")

local ghoti = {}

-- 1. Complete fish pool table (Using absolute external literals for the 'fishing' mod namespace)
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

-- Tracks which active player session is looking at which NPC numerical tracking ID
local player_current_npc = {}

-- Safely triggers a persistent storage reload via your core folks API layer
local function save_core_storage()
  local modpath = core.get_modpath("folks")
  local api_file = loadfile(modpath .. "/src/api.lua")
  if api_file then
    local env = getfenv(api_file)
    if env and env.update_storage then env.update_storage() end
  end
end

-- Pick 5 unique fishes out of the pool and assign them to the specific NPC's framework data table
local function refresh_ghoti_deals(npc_data)
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

  npc_data._ghoti_active_deals = {}
  for _, idx in ipairs(indices) do
    local base_fish = fish_pool[idx]
    local random_stock = math.random(1, 10)
    
    table.insert(npc_data._ghoti_active_deals, {
      item = base_fish.item,
      price = base_fish.price,
      label = base_fish.label,
      stock = random_stock,
      max_stock = random_stock,
      out_of_stock_time = nil
    })
  end
  npc_data._ghoti_last_roll_time = core.get_us_time()
  save_core_storage()
end

-- Checks if any depleted fish has been out of stock for 10 minutes (600 seconds)
local function check_and_restock_items(npc_data)
  if not npc_data._ghoti_active_deals then return end
  local current_time = core.get_us_time()
  local altered = false
  
  for _, deal in ipairs(npc_data._ghoti_active_deals) do
    if deal.stock == 0 and deal.out_of_stock_time then
      local seconds_elapsed = (current_time - deal.out_of_stock_time) / 1000000
      
      -- 10 minutes = 600 seconds
      if seconds_elapsed >= 600 then
        deal.stock = math.random(1, 10)
        deal.max_stock = deal.stock
        deal.out_of_stock_time = nil
        altered = true
      end
    end
  end
  
  if altered then save_core_storage() end
end

-- Generate the graphical user interface layout
function ghoti.show_formspec(player_name, npc_id)
  local npc_data = folks.get_npc(npc_id)
  if not npc_data then return end

  check_and_restock_items(npc_data)
  
  local current_time = core.get_us_time()
  local elapsed_seconds = (current_time - (npc_data._ghoti_last_roll_time or current_time)) / 1000000
  local time_left_mins = math.max(0, math.floor(60 - (elapsed_seconds / 60)))
  local npc_display_name = npc_data._npc_name or "Ghoti"

  -- WIDENED FORMAT TO FIX TEXT OVERLAPS
  local formspec = 
    "size[11.5,8.5]" ..
    "real_coordinates[true]" ..
    "title[0.5,0.4;" .. npc_display_name .. "'s Fish Market]" ..
    "label[0.5,0.9;Offers refresh in: " .. time_left_mins .. " minutes]" ..
    "box[0.5,1.2;10.5,0.02;#ffffff]"

  local row_y = 1.5
  for i, deal in ipairs(npc_data._ghoti_active_deals or {}) do
    local stock_info = "Stock: " .. deal.stock .. "/" .. deal.max_stock
    local display_button = "button[9.0," .. row_y .. ";2.0,0.7;ghoti_sell_" .. i .. ";Sell 1x]"
    
    if deal.stock == 0 and deal.out_of_stock_time then
      local elapsed = (current_time - deal.out_of_stock_time) / 1000000
      local remaining_cooldown = math.max(0, math.floor(10 - (elapsed / 60)))
      stock_info = "OUT OF STOCK (Restocking in " .. remaining_cooldown .. "m)"
      display_button = "button_exit[9.0," .. row_y .. ";2.0,0.7;disabled;Sold Out]"
    end

    formspec = formspec ..
      "item_image[0.6," .. row_y .. ";0.8,0.8;" .. deal.item .. "]" ..
      "label[1.6," .. (row_y + 0.1) .. ";" .. deal.label .. "]" ..
      "label[1.6," .. (row_y + 0.45) .. ";" .. stock_info .. "]" ..
      "label[5.8," .. (row_y + 0.25) .. ";Value: " .. deal.price .. " Gold]" ..
      display_button
      
    row_y = row_y + 0.9
  end

  formspec = formspec .. 
    "box[0.5,6.0;10.5,0.02;#ffffff]" ..
    "list[current_player;main;1.2,6.3;8,2;]" ..
    "listring[current_player;main]"

  core.show_formspec(player_name, "folks:ghoti_market", formspec)
end

-- This executes when Ghoti is right-clicked via the roles engine configuration hook
function ghoti.on_interact(player, npc_id)
  local npc_data = folks.get_npc(npc_id)
  if not npc_data then return end

  local player_name = player:get_player_name()
  player_current_npc[player_name] = npc_id

  local current_time = core.get_us_time()
  local elapsed = (current_time - (npc_data._ghoti_last_roll_time or 0)) / 1000000
  
  -- Total pool rotation trigger (1 hour) maps to framework table layout properties
  if not npc_data._ghoti_active_deals or #npc_data._ghoti_active_deals == 0 or elapsed >= 3600 then
    refresh_ghoti_deals(npc_data)
  else
    check_and_restock_items(npc_data)
  end

  ghoti.show_formspec(player_name, npc_id)
end

-- Formspec UI Intercept Event Handler
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:ghoti_market" then return false end
  local player_name = player:get_player_name()

  local npc_id = player_current_npc[player_name]
  local npc_data = folks.get_npc(npc_id)
  if not npc_data then return true end

  if fields.quit then
    player_current_npc[player_name] = nil
    return true
  end

  local npc_display_name = npc_data._npc_name or "Ghoti"

  for i = 1, 5 do
    if fields["ghoti_sell_" .. i] then
      check_and_restock_items(npc_data)
      
      local deal = npc_data._ghoti_active_deals[i]
      
      if deal and deal.stock > 0 then
        local inv = player:get_inventory()
        
        if inv:contains_item("main", ItemStack(deal.item)) then
          inv:remove_item("main", ItemStack(deal.item .. " 1"))
          
          deal.stock = deal.stock - 1
          
          if deal.stock == 0 then
            deal.out_of_stock_time = core.get_us_time()
          end

          -- Economy reward targeting the standard currency mod namespace format
          inv:add_item("main", ItemStack("currency:minegeld " .. deal.price))
          
          core.chat_send_player(player_name, core.colorize("#00ff00", npc_display_name .. ": Thanks! Here is your " .. deal.price .. " Gold for the " .. deal.label .. "."))
          
          save_core_storage()
          ghoti.show_formspec(player_name, npc_id)
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
