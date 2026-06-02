folks = {}
local version = "0.3.0"
local modpath = core.get_modpath("folks")
local srcpath = modpath .. "/src"

folks.util = dofile(srcpath .. "/util.lua")

dofile(modpath .. "/settings.lua")

dofile(srcpath .. "/api.lua")
dofile(srcpath .. "/commands.lua")
dofile(srcpath .. "/formspecs.lua")
dofile(srcpath .. "/items.lua")
dofile(srcpath .. "/privs.lua")

-- [Order Fix]: Load roles first so the npc logic can safely read the registry table
dofile(srcpath .. "/roles.lua")
dofile(srcpath .. "/npc.lua")

-- callback for collectible_skins
if core.get_modpath("collectible_skins") then
  collectible_skins.register_on_set_skin(function(p_name, skin_ID)
    local texture = collectible_skins.get_skin(skin_ID)
    folks.update_npc_texture(p_name, texture.texture)
  end)
end

core.log("action", "[FOLKS] Mod initialised. Running version " .. version)
