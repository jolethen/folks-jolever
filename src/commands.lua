local S = core.get_translator("folks")

local IS_COLLECTIBLE_SKINS_ENABLED = core.get_modpath("collectible_skins")

local cmd = chatcmdbuilder.register("folks", {
  description = S("Manage folks npcs"),
  privs = { folks_admin = true }
})


-- command for editing selected npc name
cmd:sub("edit name :name:text", function(pname, new_name)
  local player = core.get_player_by_name(pname)
  if player then
    local meta = player:get_meta()
    if meta then
      local editing_npc = meta:get_int("folks_editing_npc")
      if editing_npc == "" then
        core.chat_send_player(pname, core.colorize("#ff0000", S("You are not editing an NPC. Click the NPC you want to edit with the NPC editor item.")))
        return
      end
      local npc = folks.get_npc(editing_npc)
      if npc then
        folks.edit_npc_name(editing_npc, new_name)
        meta:set_int("folks_editing_npc", 0)
        core.chat_send_player(pname, core.colorize("#00ff00", S("Edited NPC: @1", editing_npc)))
      end
    end
  end
end)


-- command for editing selected npc name color
cmd:sub("edit name_color :color:text", function(pname, new_color)
  local player = core.get_player_by_name(pname)
  if player then
    local meta = player:get_meta()
    if meta then
      local editing_npc = meta:get_int("folks_editing_npc")
      if editing_npc == "" then
        core.chat_send_player(pname, core.colorize("#ff0000", S("You are not editing an NPC. Click the NPC you want to edit with the NPC editor item.")))
        return
      end
      local npc = folks.get_npc(editing_npc)
      if npc then
        folks.edit_npc_name_color(editing_npc, new_color)
        meta:set_int("folks_editing_npc", 0)
        core.chat_send_player(pname, core.colorize("#00ff00", S("Edited NPC: @1", editing_npc)))
      end
    end
  end
end)


-- command for editing selected npc texture
cmd:sub("edit texture :name:text", function(pname, new_texture)
  local player = core.get_player_by_name(pname)
  if player then
    local meta = player:get_meta()
    if meta then
      local editing_npc = meta:get_int("folks_editing_npc")
      if editing_npc == "" then
        core.chat_send_player(pname, core.colorize("#ff0000", S("You are not editing an NPC. Click the NPC you want to edit with the NPC editor item.")))
        return
      end
      local npc = folks.get_npc(editing_npc)
      if npc then
        folks.edit_npc_texture(editing_npc, new_texture)
        meta:set_int("folks_editing_npc", 0)
        core.chat_send_player(pname, core.colorize("#00ff00", S("Edited NPC: @1", editing_npc)))
      end
    end
  end
end)



-- command to bind name and texture of npc to a player, needs collectible_skins
cmd:sub("bind :name:text", function(pname, bind_to)
  if IS_COLLECTIBLE_SKINS_ENABLED then
    local player = core.get_player_by_name(pname)
    if player then
      local meta = player:get_meta()
      if meta then
        local editing_npc = meta:get_int("folks_editing_npc")
        if editing_npc == "" then
          core.chat_send_player(pname, core.colorize("#ff0000", S("You are not editing an NPC. Click the NPC you want to edit with the NPC editor item.")))
          return
        end
        local npc = folks.get_npc(editing_npc)
        if npc then
          if folks.bind_npc_to_player(editing_npc, bind_to) then
            core.chat_send_player(pname, core.colorize("#00ff00", S("Edited NPC: @1", editing_npc)))
          else
            core.chat_send_player(pname, core.colorize("#ff0000", S("Couldn't retrieve player texture (is it online?)")))
          end
          meta:set_int("folks_editing_npc", 0)
        end
      end
    end
  else
    core.chat_send_player(pname, core.colorize("#ff0000", S("You need Collectible Skins to use this feature")))
  end
end)