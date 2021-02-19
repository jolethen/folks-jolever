function folks.edit_npc_name(npc_id, new_name)
  folks.backend.get_npcs()[npc_id]._npc_name = new_name
  local npc_obj = folks.backend.get_npcs_obj(npc_id)
  if npc_obj then
    npc_obj:set_properties({
      nametag = new_name,
    })
  end
end

function folks.edit_npc_name_color(npc_id, new_color)
  folks.backend.get_npcs()[npc_id]._npc_name_color = new_color
  local npc_obj = folks.backend.get_npcs_obj(npc_id)
  if npc_obj then
    npc_obj:set_properties({
      nametag_color = new_color,
    })
  end
end

function folks.edit_npc_texture(npc_id, new_texture)
  -- add .png if not found in new_texture
  if string.find(new_texture, ".png", 0, true) == nil then
    new_texture = new_texture .. ".png"
  end

  folks.backend.get_npcs()[npc_id]._npc_textures = {new_texture,}
  local npc_obj = folks.backend.get_npcs_obj(npc_id)
  if npc_obj then
    npc_obj:set_properties({
      textures = {new_texture,},
    })
  end
end

-- needs skins_collectible
-- returns false if couldn't retrieve player texture (ex. is offline)
function folks.bind_npc_to_player(npc_id, bind_to)
  local new_texture_obj = skins_collectible.get_player_skin(bind_to)
  if new_texture_obj == nil then return false end

  local new_texture = new_texture_obj.texture
  folks.backend.get_npcs()[npc_id]._npc_textures = {new_texture,}
  folks.backend.get_npcs()[npc_id]._npc_name = bind_to
  folks.backend.get_npcs()[npc_id]._bound_player = bind_to
  local npc_obj = folks.backend.get_npcs_obj(npc_id)
  if npc_obj then
    npc_obj:set_properties({
      nametag = bind_to,
      textures = {new_texture,},
      _bound_player = bind_to,
    })
  end

  return true
end

function folks.edit_npc_messages(npc_id, messages)
  folks.backend.get_npcs()[npc_id]._npc_messages = messages
end

function folks.get_npc_message(npc_id, index)
  local npc = folks.backend.get_npc(npc_id)

  if npc then
    if npc._npc_messages[index] == nil then return nil end

    return npc._npc_messages[index]
  end
end
