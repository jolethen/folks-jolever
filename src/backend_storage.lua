local storage = core.get_mod_storage()
local npcs = {} -- id: obj
local npcs_objects = {} -- id: {obj1, obj2}, more objects of the same NPC
local msg_for_players = {} -- npc_id: {p_name: msg_index}


function folks.load_npcs()
  npcs =  core.deserialize(storage:get_string("npcs")) or {}
  for npc_id, _ in pairs(npcs) do
    msg_for_players[npc_id] = {}
  end
  return npcs
end

function folks.get_npcs()
  return npcs
end

function folks.get_npcs_objs()
  return npcs_objects
end

function folks.get_unique_id()
  local id
  repeat
    id = folks.util.randomString(16)
  until npcs[id] == nil
  return id
end

function folks.add_npc(ref)
  local def = folks.util.deepcopy(core.registered_entities[ref:get_luaentity().name])
  local npc = {}
  local entity = ref:get_luaentity()
  npc._npc_pos = ref:get_pos()
  npc._npc_textures = entity.textures or def.initial_properties.textures
  npc._npc_name = entity._npc_name or def.initial_properties.nametag
  npc._npc_name_color = entity._npc_name_color or def.initial_properties.nametag_color
  npc._npc_id = entity._npc_id
  npc._npc_type = entity.name
  npc._bound_player = entity._bound_player
  npc._npc_messages = entity._npc_messages

  npcs[entity._npc_id] = npc

  msg_for_players[entity._npc_id] = {}

  -- that way I can serialize npcs without problems
  folks.set_npc_obj(entity._npc_id, entity._npc_object)
  folks.save_npcs()
end

function folks.remove_npc(npc_id)
  npcs[npc_id] = nil
  npcs_objects[npc_id] = nil

  folks.save_npcs()
end

function folks.save_npcs()
  storage:set_string("npcs", core.serialize(npcs))
end

function folks.get_npc(npc_id)
  return npcs[npc_id]
end

function folks.get_npc_objs(npc_id)
  return npcs_objects[npc_id]
end

function folks.set_npc_obj(npc_id, obj)
  if not npcs_objects[npc_id] then
    npcs_objects[npc_id] = {obj}
  else
    table.insert(npcs_objects[npc_id], obj)
  end
end

function folks.update_npc_texture(p_name, texture)
  for npc_id, npc in pairs(npcs) do
    if npc._bound_player == p_name then
      if npcs_objects[npc_id] then
        for _, npc_obj in pairs(npcs_objects[npc_id]) do
          npc_obj:set_properties({
            textures = {texture,},
          })
        end
        npcs[npc_id]._npc_textures = {texture}
      end
    end
  end
end


-- custom Messages
function folks.get_next_message_index(npc_id, p_name)
  if msg_for_players[npc_id][p_name] then
    local id = msg_for_players[npc_id][p_name]
    if id > #npcs[npc_id]._npc_messages then id = 1 end
    msg_for_players[npc_id][p_name] = id + 1
    return id
  end

  msg_for_players[npc_id][p_name] = 2  -- set the next id
  return 1  -- if p_name is not found means it's the first message
end

-- function folks.spawn_npc(ref)
--   local obj = core.add_entity(ref._npc_pos, ref._npc_type)
--   local npc = obj:get_properties()
--   npc._npc_pos = ref._npc_pos
--   npc._npc_textures = ref._npc_textures or npc.initial_properties.textures
--   npc._npc_name = ref._npc_name or npc.initial_properties.nametag
--   npc._npc_id = ref._npc_id
--   npc._npc_type = ref._npc_type
--   npc._npc_object = obj
--
--   npcs[ref._npc_id] = npc
--
-- end
--
-- function folks.despawn_npc(ref)
--   local npc = npcs[ref._npc_id]
--   npc._npc_object:remove()
--
--   npcs[ref._npc_id]["_npc_object"] = "heyo"
--   core.log("Despawning: " .. ref._npc_id)
-- end
