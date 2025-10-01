folks = {}
local version = "0.2.0"
local modpath = core.get_modpath("folks")
local srcpath = modpath .. "/src"

-- check for collectible_skins
if core.get_modpath("collectible_skins") then
  folks.skins_c = true
else
  folks.skins_c = false
end

folks.util = dofile(srcpath .. "/util.lua")

dofile(modpath .. "/settings.lua")
dofile(srcpath .. "/backend_storage.lua")

dofile(srcpath .. "/api.lua")
dofile(srcpath .. "/commands.lua")
dofile(srcpath .. "/formspecs.lua")
dofile(srcpath .. "/items.lua")
dofile(srcpath .. "/npc.lua")
dofile(srcpath .. "/privs.lua")

core.after(0, function()
  local npcs = folks.load_npcs()
  -- if npcs then
  --   for id, npc in pairs(npcs) do
  --     core.log("action", core.serialize(npc))
  --     folks.spawn_npc(npc)
  --   end
  -- end
end)

-- callback for collectible_skins
if folks.skins_c then
  collectible_skins.register_on_set_skin(function(p_name, skin_ID)
    local texture = collectible_skins.get_skin(skin_ID)
    folks.update_npc_texture(p_name, texture.texture)
  end)
end

core.register_on_shutdown(function()
  folks.save_npcs()
end)

core.log("action", "[FOLKS] Mod initialised. Running version " .. version)
