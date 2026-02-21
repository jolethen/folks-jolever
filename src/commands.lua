local S = core.get_translator("folks")

local IS_COLLECTIBLE_SKINS_ENABLED = core.get_modpath("collectible_skins")

local cmd = chatcmdbuilder.register("folks", {
  params = "help",
  description = S("Manage folks npcs"),
  privs = { folks_admin = true }
})



cmd:sub("add :id:number", function(sender, id)
  local p_pos = core.get_player_by_name(sender):get_pos()

  if not folks.get_npc(id) then
    folks.add_npc(p_pos, id)
  else
    folks.spawn_npc(id, p_pos)
  end
end)



cmd:sub("list", function(sender)
  local name_list = ""

  for id, npc in pairs(folks.get_npcs()) do
    name_list = name_list .. id .. ". " .. npc._npc_name .. "\n"
  end

  core.chat_send_player(sender, name_list)
end)


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



cmd:sub("help", function(sender)
  core.chat_send_player(sender,
    core.colorize("#ffff00", S("COMMANDS")) .. "\n"
    .. core.colorize("#00ffff", "/folks bind") .. core.colorize("#00aaaa"," <" .. S("player") .. ">: ") .. S("binds an NPC to a player (name and skin). It requires the Collectible Skins mod") .. "\n"
    .. core.colorize("#00ffff", "/folks list") .. ": " .. S("prints a list of all the existing NPCs")
  )
end)