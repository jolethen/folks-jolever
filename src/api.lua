local storage = core.get_mod_storage()

local function generate_id() end
local function update_storage() end

local npcs = {} -- id: obj
local npcs_objects = {} -- id: {obj1, obj2}, more objects of the same NPC. Caricata dai singoli PNG all'attivazione tramite set_npc_obj
local msg_for_players = {} -- npc_id: {p_name: msg_index}
local converted_old_npcs = {} -- npc_old_id: npc_id


-- non esporre
local function convert_old_format_npcs()
  local to_convert = false

  for npc_id, _ in pairs(npcs) do
    if type(npc_id) ~= "number" then
      to_convert = true
    end
    break
  end

  if not to_convert then return end

  local new_npcs, i = {}, 1

  for npc_id, npc in pairs(npcs) do
    new_npcs[i] = folks.util.deepcopy(npc)
    new_npcs[i]._npc_id = i
    converted_old_npcs[npc_id] = i
    i = i + 1
  end

  npcs = new_npcs
  update_storage()

  core.log("action", "[Folks] NPCs successfully converted into the new format")
end



-- non esporre
local function load_npcs()
  npcs =  core.deserialize(storage:get_string("npcs")) or {}

  convert_old_format_npcs()

  for npc_id, _ in pairs(npcs) do
    msg_for_players[npc_id] = {}
  end
end

load_npcs()



-- TODO: non penso serva davvero
core.register_on_shutdown(function()
  update_storage()
end)





----------------------------------------------
---------------------CORE---------------------
----------------------------------------------

function folks.add_npc(pos, id)
  -- TODO: in futuro possibilità di specificare manualmente ID (verificando che non sia già preso)
  if id ~= nil then
    if type(id) ~= "number" or npcs[id] ~= nil then return end
  end

  local npc_id = id or generate_id()
  local new_npc = core.add_entity(pos, "folks:npc", core.serialize({_npc_id = npc_id}))

  new_npc:get_luaentity()._npc_id = npc_id

  local entity = new_npc:get_luaentity()
  local def = folks.util.deepcopy(core.registered_entities[entity.name])
  local npc = {}

  npc._npc_pos = new_npc:get_pos()
  npc._npc_textures = entity.textures or def.initial_properties.textures
  npc._npc_name = entity._npc_name or def.initial_properties.nametag
  npc._npc_name_color = entity._npc_name_color or def.initial_properties.nametag_color
  npc._npc_id = entity._npc_id
  npc._npc_type = entity.name
  npc._bound_player = entity._bound_player
  npc._npc_messages = entity._npc_messages

  npcs[entity._npc_id] = npc

  msg_for_players[entity._npc_id] = {}
  mobkit.remember(entity, "_npc_id", npc_id)

  -- that way I can serialize npcs without problems
  folks.set_npc_obj(entity._npc_id, entity._npc_object)
  update_storage()

  return true
end

function folks.remove_npc(npc_id)
  npcs[npc_id] = nil
  npcs_objects[npc_id] = nil

  update_storage()
end



function folks.edit_npc_name(npc_id, new_name)
  folks.get_npc(npc_id)._npc_name = new_name

  local npc_objs = folks.get_npc_objs(npc_id)

  for _, npc_obj in pairs(npc_objs) do
    if npc_obj then
      npc_obj:set_properties({nametag = new_name})
    end
  end
end



function folks.edit_npc_name_color(npc_id, new_color)
  folks.get_npc(npc_id)._npc_name_color = new_color

  local npc_objs = folks.get_npc_objs(npc_id)

  for _, npc_obj in pairs(npc_objs) do
    if npc_obj then
      npc_obj:set_properties({nametag_color = new_color})
    end
  end
end



function folks.edit_npc_texture(npc_id, new_texture)
  -- add .png if not found in new_texture
  if string.find(new_texture, ".png", 0, true) == nil then
    new_texture = new_texture .. ".png"
  end

  folks.get_npc(npc_id)._npc_textures = {new_texture}

  local npc_objs = folks.get_npc_objs(npc_id)

  for _, npc_obj in pairs(npc_objs) do
    if npc_obj then
      npc_obj:set_properties({textures = {new_texture}})
    end
  end
end



-- needs collectible_skins
-- returns false if couldn't retrieve player texture (ex. is offline)
function folks.bind_npc_to_player(npc_id, bind_to)
  local new_texture_obj = collectible_skins.get_player_skin(bind_to)
  if new_texture_obj == nil then return false end

  local new_texture = new_texture_obj.texture
  local npc = folks.get_npc(npc_id)

  npc._npc_textures = {new_texture,}
  npc._npc_name = bind_to
  npc._bound_player = bind_to

  local npc_objs = folks.get_npc_objs(npc_id)
  for _, npc_obj in pairs(npc_objs) do
    if npc_obj then
      npc_obj:set_properties({
        nametag = bind_to,
        textures = {new_texture,},
        _bound_player = bind_to,
      })
    end
  end

  return true
end



function folks.edit_npc_messages(npc_id, messages)
  folks.get_npc(npc_id)._npc_messages = messages
end



function folks.update_npc_texture(p_name, texture)
  for npc_id, npc in pairs(npcs) do
    if npc._bound_player == p_name then
      if npcs_objects[npc_id] then
        for _, npc_obj in pairs(npcs_objects[npc_id]) do
          npc_obj:set_properties({textures = {texture}})
        end
        npcs[npc_id]._npc_textures = {texture}
      end
    end
  end
end



function folks.spawn_npc(npc_id, position)
  local npc = folks.get_npc(npc_id)

  if npc then
    local spawned_npc = core.add_entity(position, "folks:npc", core.serialize({_npc_id = npc_id}))
    local entity = spawned_npc:get_luaentity()

    entity._npc_id = npc_id
    spawned_npc:set_properties({
      textures = {table.concat(npc._npc_textures)},
      nametag = npc._npc_name,
      nametag_color = npc._npc_name_color
    })

    folks.set_npc_obj(npc_id, spawned_npc)
    folks.edit_npc_messages(npc_id, npc._npc_messages)
    mobkit.remember(entity, "_npc_id", npc_id)
    return true
  end
end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

-- non esporre
function folks.migrate_npc_id(entity, npc_id)
  npc_id = converted_old_npcs[npc_id]
  mobkit.remember(entity, "_npc_id", npc_id)
end





----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function folks.get_npcs()
  return npcs
end



function folks.get_npcs_objs()
  return npcs_objects
end



function folks.get_npc(npc_id)
  return npcs[npc_id]
end



function folks.get_npc_objs(npc_id)
  return npcs_objects[npc_id]
end



function folks.get_npc_message(npc_id, index)
  local npc = folks.get_npc(npc_id)

  if npc then
    if npc._npc_messages[index] == nil then return nil end

    return npc._npc_messages[index]
  end
end



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





----------------------------------------------
-----------------SETTERS----------------------
----------------------------------------------

-- non esporre
function folks.set_npc_obj(npc_id, obj)
  if not npcs_objects[npc_id] then
    npcs_objects[npc_id] = {obj}
  else
    table.insert(npcs_objects[npc_id], obj)
  end
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function generate_id()
  for i = 1, 9999 do
    if npcs[i] == nil then
      return i
    end
  end
end



function update_storage()
  storage:set_string("npcs", core.serialize(npcs))
end