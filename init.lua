folks = {}
local version = "0.2.0"
local modpath = minetest.get_modpath("folks")

-- check for collectible_skins 
if minetest.get_modpath("collectible_skins") then
  folks.skins_c = true
else
  folks.skins_c = false
end

folks.util = dofile(modpath .. "/util.lua")

dofile(modpath .. "/settings.lua")
if folks.backend_type == "storage" then
  folks.backend = dofile(modpath .. "/backend_storage.lua")
elseif folks.backend_type == "sqlite" then
  folks.backend = dofile(modpath .. "/backend_sqlite.lua")
else
  minetest.log("error", "[FOLKS] Invalid storage type")
  return
end

dofile(modpath .. "/api.lua")
dofile(modpath .. "/privs.lua")
dofile(modpath .. "/chatcmdbuilder.lua")
dofile(modpath .. "/commands.lua")
dofile(modpath .. "/formspecs.lua")
dofile(modpath .. "/items.lua")
dofile(modpath .. "/npc.lua")

minetest.after(0, function()
  local npcs = folks.backend.load_npcs()
  -- if npcs then
  --   for id, npc in pairs(npcs) do
  --     minetest.log("action", minetest.serialize(npc))
  --     folks.backend.spawn_npc(npc)
  --   end
  -- end
end)

-- callback for collectible_skins
if folks.skins_c then
  collectible_skins.register_on_set_skin(function(p_name, skin_ID)
    local texture = collectible_skins.get_skin(skin_ID)
    folks.backend.update_npc_texture(p_name, texture.texture)
  end)
end

minetest.register_on_shutdown(function()
  folks.backend.save_npcs()
end)

minetest.log("action", "[FOLKS] Mod initialised. Running version " .. version)
