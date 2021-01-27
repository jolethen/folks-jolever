folks = {}
local version = "0.0.0-alpha"
local modpath = minetest.get_modpath("folks")


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

dofile(modpath .. "/privs.lua")
dofile(modpath .. "/chatcmdbuilder.lua")
dofile(modpath .. "/commands.lua")
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

minetest.register_on_shutdown(function()
  folks.backend.on_shutdown()
end)

minetest.log("action", "[FOLKS] Mod initialised. Running version " .. version)
