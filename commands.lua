ChatCmdBuilder.new("folks", function(cmd)
  -- command for editing selected npc name
  cmd:sub("edit name :name:text", function(pname, new_name)
    local player = minetest.get_player_by_name(pname)
    if player then
      local meta = player:get_meta()
      if meta then
        local editing_npc = meta:get_string("folks_editing_npc")
        if editing_npc == "" then
          minetest.chat_send_player(pname, minetest.colorize("#ff0000", "You are not editing an NPC. Click the NPC you want to edit with the NPC editor item."))
          return
        end
        local npc = folks.backend.get_npc(editing_npc)
        if npc then
          folks.backend.get_npcs()[editing_npc]._npc_name = new_name
          -- minetest.log(dump(npc._npc_object))
          local npc_obj = folks.backend.get_npcs_obj(editing_npc)
          if npc_obj then
            npc_obj:set_properties({
              nametag = new_name,
            })
          end
          meta:set_string("folks_editing_npc", "")
          minetest.chat_send_player(pname, minetest.colorize("#00ff00", "Edited NPC: " .. editing_npc))
        end
      end
    end
  end)


  -- command for editing selected npc name color
  cmd:sub("edit name_color :color:text", function(pname, new_color)
    local player = minetest.get_player_by_name(pname)
    if player then
      local meta = player:get_meta()
      if meta then
        local editing_npc = meta:get_string("folks_editing_npc")
        if editing_npc == "" then
          minetest.chat_send_player(pname, minetest.colorize("#ff0000", "You are not editing an NPC. Click the NPC you want to edit with the NPC editor item."))
          return
        end
        local npc = folks.backend.get_npc(editing_npc)
        if npc then
          folks.backend.get_npcs()[editing_npc]._npc_name_color = new_color
          -- minetest.log(dump(npc._npc_object))
          local npc_obj = folks.backend.get_npcs_obj(editing_npc)
          if npc_obj then
            npc_obj:set_properties({
              nametag_color = new_color,
            })
          end
          meta:set_string("folks_editing_npc", "")
          minetest.chat_send_player(pname, minetest.colorize("#00ff00", "Edited NPC: " .. editing_npc))
        end
      end
    end
  end)


  -- command for editing selected npc texture
  cmd:sub("edit texture :name:text", function(pname, new_texture)
    -- add .png if not found in new_texture
    if string.find(new_texture, ".png", 0, true) == nil then
      new_texture = new_texture .. ".png"
    end


    local player = minetest.get_player_by_name(pname)
    if player then
      local meta = player:get_meta()
      if meta then
        local editing_npc = meta:get_string("folks_editing_npc")
        if editing_npc == "" then
          minetest.chat_send_player(pname, minetest.colorize("#ff0000", "You are not editing an NPC. Click the NPC you want to edit with the NPC editor item."))
          return
        end
        local npc = folks.backend.get_npc(editing_npc)
        if npc then
          folks.backend.get_npcs()[editing_npc]._npc_textures = {new_texture,}
          -- minetest.log(dump(npc._npc_object))
          local npc_obj = folks.backend.get_npcs_obj(editing_npc)
          if npc_obj then
            npc_obj:set_properties({
              textures = {new_texture,},
            })
          end
          meta:set_string("folks_editing_npc", "")
          minetest.chat_send_player(pname, minetest.colorize("#00ff00", "Edited NPC: " .. editing_npc))
        end
      end
    end
  end)


end, {
  description = "Manage folks npcs",
  privs = {
    folks_admin = true
  }
})
