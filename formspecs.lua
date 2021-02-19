function folks.get_edit_formspec(npc_id)
  local npc = folks.backend.get_npc(npc_id)
  local escape = minetest.formspec_escape
  local formspec = {}
  if npc then
    formspec = {
      "formspec_version[3]",
      "size[11,11]",
      "label[4.85,1;Edit Folk]",
      "field[2,2;3,0.75;folk_name;Folk name;", escape(npc._npc_name), "]",
      "field[6,2;3,0.75;folk_name_color;Folk Name Color;", escape(npc._npc_name_color), "]",
      "field[2,3.5;7,0.75;folk_texture;Folk Texture (with or without .png);", escape(table.concat(npc._npc_textures, "")), "]",
      "textarea[2,5;7,4;folk_messages;Messages (every line is a message);", escape(npc._npc_messages), "]",
      "button_exit[4,9.5;3,0.75;folk_save_edit;Save]",
      "button_exit[9.5,0.2;1,0.75;folk_close_edit;X]",
    }
  end

  return table.concat(formspec, "")
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "folks:edit_npc_formspec" then return end

  if fields.folk_save_edit then
    local cmd = minetest.chatcommands["folks"]
    local p_name = player:get_player_name()
    local privs, _ = minetest.check_player_privs(p_name, cmd.privs)
    if not privs then return end

    if player then
      local meta = player:get_meta()
      if meta then
        local editing_npc = meta:get_string("folks_editing_npc")
        if editing_npc == "" then
          minetest.chat_send_player(p_name, minetest.colorize("#ff0000", "You are not editing an NPC. Click the NPC you want to edit with the NPC editor item."))
          return
        end
        local npc = folks.backend.get_npc(editing_npc)
        if npc then
          folks.edit_npc_name(editing_npc, fields.folk_name)
          folks.edit_npc_name_color(editing_npc, fields.folk_name_color)
          folks.edit_npc_texture(editing_npc, fields.folk_texture)
          folks.edit_npc_messages(editing_npc, fields.folk_messages)
          meta:set_string("folks_editing_npc", "")
          minetest.chat_send_player(p_name, minetest.colorize("#00ff00", "Edited NPC: " .. editing_npc))
        end
      end
    end
  end

  if fields.folk_close_edit then
    if player then
      local meta = player:get_meta()
      if meta then
        minetest.chat_send_player(player:get_player_name(), minetest.colorize("#00ff00", "Exited from NPC: " .. meta:get_string("folks_editing_npc")))
        meta:set_string("folks_editing_npc", "")
      end
    end
  end
end)
