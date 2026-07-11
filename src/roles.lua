-- roles.lua
roles = {}

local modpath = core.get_modpath("folks")

local ghoti_file = loadfile(modpath .. "/src/ghoti.lua")
local ghoti = ghoti_file and ghoti_file()

local quest_file = loadfile(modpath .. "/src/quests.lua")
local quest_sys = quest_file and quest_file()

local quest_gui_file = loadfile(modpath .. "/src/quests_gui.lua")
if quest_gui_file then
  quest_gui_file()
end

-- Load the new Weekly quest script cleanly with an error check wrap
local weekly_file, load_err = loadfile(modpath .. "/src/weekly_quests.lua")
local weekly_sys = nil
if weekly_file then
  local success, result = pcall(weekly_file)
  if success then
    weekly_sys = result
  else
    core.log("error", "[Weekly Terminal] Initialization runtime crash: " .. tostring(result))
  end
else
  core.log("error", "[Weekly Terminal] File loading crash/Missing path: " .. tostring(load_err))
end

-- FIX: Load the Witch module cleanly right here
local witch_file = loadfile(modpath .. "/src/witch.lua")
local witch_sys = witch_file and witch_file()

-- Safe-load Mike with pcall error wrapping
local mike_file, mike_err = loadfile(modpath .. "/src/mike.lua")
local mike_sys = nil
if mike_file then
  local success, result = pcall(mike_file)
  if success then mike_sys = result
  else core.log("error", "[Mike Merchant] Initialization runtime crash: " .. tostring(result)) end
else
  core.log("error", "[Mike Merchant] File loading crash/Missing path: " .. tostring(mike_err))
end

-- Safe-load Denji with pcall error wrapping
local denji_file, denji_err = loadfile(modpath .. "/src/denji.lua")
local denji_sys = nil
if denji_file then
  local success, result = pcall(denji_file)
  if success then denji_sys = result
  else core.log("error", "[Denji Merchant] Initialization runtime crash: " .. tostring(result)) end
else
  core.log("error", "[Denji Merchant] File loading crash/Missing path: " .. tostring(denji_err))
end

-- Safe-load Ben with pcall error wrapping
local ben_file, ben_err = loadfile(modpath .. "/src/ben.lua")
local ben_sys = nil
if ben_file then
  local success, result = pcall(ben_file)
  if success then ben_sys = result
  else core.log("error", "[Ben Merchant] Initialization runtime crash: " .. tostring(result)) end
else
  core.log("error", "[Ben Merchant] File loading crash/Missing path: " .. tostring(ben_err))
end

-- Safe-load Tom with pcall error wrapping
local tom_file, tom_err = loadfile(modpath .. "/src/tom.lua")
local tom_sys = nil
if tom_file then
  local success, result = pcall(tom_file)
  if success then tom_sys = result
  else core.log("error", "[Tom Merchant] Initialization runtime crash: " .. tostring(result)) end
else
  core.log("error", "[Tom Merchant] File loading crash/Missing path: " .. tostring(tom_err))
end

roles.registry = {
  ["ghoti"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self)
      else core.chat_send_player(player:get_player_name(), "[System Error]: Ghoti module failed.") end
    end
  },
  ["allison"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Allison module failed.") end
    end
  },
  ["phillips"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Phillips module failed.") end
    end
  },
  ["jack"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Jack module failed.") end
    end
  },
  ["david"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: David module failed.") end
    end
  },
  ["felix"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Felix module failed.") end
    end
  },
  ["james"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: James module failed.") end
    end
  },
  ["walker"] = {
    action = function(player, npc_self)
      if ghoti then ghoti.on_interact(player, npc_self) 
      else core.chat_send_player(player:get_player_name(), "[System Error]: Walker module failed.") end
    end
  },

  ["banker"] = {
    action = function(player, npc_self)
      local player_name = player:get_player_name()
      local formspec_name = "folks:bank_interface"
      local formspec = 
        "size[6,4]" ..
        "real_coordinates[true]" ..
        "label[2.5,0.5;Bank]" .. 
        "box[0.5,1.0;5,0.05;#ffffff]" ..
        "label[0.5,1.8;Welcome to the banking terminal!]" ..
        "label[0.5,2.3;Account services will appear here.]" ..
        "button_exit[2.0,3.2;2.0,0.6;close;Exit]"
      core.show_formspec(player_name, formspec_name, formspec)
    end
  },
  
  ["quester"] = {
    action = function(player, npc_self)
      if quest_sys then
        quest_sys.handle_npc_interaction(player, "Quester")
      else
        core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Quest subsystem failed to load."))
      end
    end
  },
  
  ["doctor"] = {
    action = function(player, npc_self)
      player:set_hp(player:get_properties().hp_max)
      core.chat_send_player(player:get_player_name(), "The Doctor has healed you!")
    end
  },

--- New Weekly Quests Entry (Cloned from Witch mapping)
  ["weeklyquests"] = {
    action = function(player, npc_self)
      if weekly_sys and weekly_sys.on_interact then
        weekly_sys.on_interact(player, npc_self)
      else
        core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Weekly terminal interface offline."))
      end
    end
  },
  --- FIX: New Witch NPC Entry
  ["witch"] = {
    action = function(player, npc_self)
      if witch_sys and witch_sys.on_interact then
        witch_sys.on_interact(player, npc_self)
      else
        core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Witch transmuting altar offline."))
      end
    end
  },

  --- NEW FORGOTTEN MONSTERS MERCHANT ROLES
  ["mike"] = {
    action = function(player, npc_self)
      if mike_sys and mike_sys.on_interact then mike_sys.on_interact(player, npc_self)
      else core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Mike's shop interface offline.")) end
    end
  },
  ["denji"] = {
    action = function(player, npc_self)
      if denji_sys and denji_sys.on_interact then denji_sys.on_interact(player, npc_self)
      else core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Denji's shop interface offline.")) end
    end
  },
  ["ben"] = {
    action = function(player, npc_self)
      if ben_sys and ben_sys.on_interact then ben_sys.on_interact(player, npc_self)
      else core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Ben's excavation shop offline.")) end
    end
  },
  ["tom"] = {
    action = function(player, npc_self)
      if tom_sys and tom_sys.on_interact then tom_sys.on_interact(player, npc_self)
      else core.chat_send_player(player:get_player_name(), core.colorize("#ff3333", "[System Error]: Tom's royal collection interface offline.")) end
    end
  }
}

return roles
