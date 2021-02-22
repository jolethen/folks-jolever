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
      "field[2,3.5;7,0.75;folk_texture;Folk Texture (with or without .png);", escape(table.concat(npc._npc_textures)), "]",
      "textarea[2,5;7,4;folk_messages;Messages (every line is a message);", escape(table.concat(npc._npc_messages, "\n")), "]",
      "button_exit[4,9.5;3,0.75;folk_save_edit;Save]",
      "button_exit[9.5,0.2;1,0.75;folk_close_edit;X]",
    }
  end

  return table.concat(formspec)
end


function folks.get_spawn_formspec()
  local escape = minetest.formspec_escape
  local npcs = folks.backend.get_npcs()
  local dropdown_items = {}

  for npc_id, npc in pairs(npcs) do
    table.insert(dropdown_items, escape(npc._npc_name .. " - " .. npc_id))
  end

  local formspec = {
    "formspec_version[3]",
    "size[9,8.5]",
    "label[3.7,1;Spawn NPC]",
    "button_exit[7.5,0.5;1,0.75;folks_close_spawner;X]",
    "dropdown[1,3;7,1;folks_select_npc;", table.concat(dropdown_items, ",") ,";1]",
    "button_exit[3,7;3,0.75;folks_spawn_npc;Spawn]",
  }

  return table.concat(formspec)
end


local function handle_edit_formspec(player, formname, fields)
  if fields.folk_save_edit then
    local p_name = player:get_player_name()
    if not minetest.check_player_privs(player:get_player_name(), { folks_admin=true }) then return end

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
          local msgs = string.split(fields.folk_messages, "\n")
          folks.edit_npc_name(editing_npc, fields.folk_name)
          folks.edit_npc_name_color(editing_npc, fields.folk_name_color)
          folks.edit_npc_texture(editing_npc, fields.folk_texture)
          folks.edit_npc_messages(editing_npc, msgs)
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
end


local function handle_spawn_formspec(player, formname, fields)
  if fields.folks_spawn_npc then
    local p_name = player:get_player_name()
    if not minetest.check_player_privs(p_name, { folks_admin=true }) then return end

    if fields.folks_select_npc ~= "" then
      local npc_id = string.split(fields.folks_select_npc, " - ")[2]
      if folks.spawn_npc(npc_id, player:get_pos()) then
        minetest.chat_send_player(p_name, minetest.colorize("#00ff00", "Spawned NPC: " .. npc_id))
        return
      end
    else
      minetest.chat_send_player(p_name, minetest.colorize("#ff0000", "No NPC selected"))
      return
    end
  end
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname == "folks:edit_npc_formspec" then
    handle_edit_formspec(player, formname, fields)
    return
  end

  if formname == "folks:spawn_npc_formspec" then
    handle_spawn_formspec(player, formname, fields)
    return
  end

  return
end)
