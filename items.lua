minetest.register_tool("folks:npc_spawner", {
  description = "Use this to spawn a NPC  at your position",
  inventory_image = "npc_spawner.png",
  groups = {oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, player, pointed_thing)
    local npc_id = folks.backend.get_unique_id()
    local new_npc = minetest.add_entity(player:get_pos(), "folks:npc", minetest.serialize({_npc_id = npc_id}))
    if new_npc then
      local entity = new_npc:get_luaentity()
      if entity then
        entity._npc_id = npc_id
        folks.backend.add_npc(new_npc)
      end
    end
    return
  end
})

minetest.register_tool("folks:npc_editor", {
  description = "Use this to edit the NPC you click",
  inventory_image = "npc_editor.png",
  groups = {oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, player, pointed_thing)
    if pointed_thing.type == "nothing" then return end

    local entity = pointed_thing.ref:get_luaentity()
    if entity._isfolk then
      if mobkit.is_alive(entity) and not entity._isremoved then
        -- TODO: show formspec to edit clicked npc
        local meta = player:get_meta()
        meta:set_string("folks_editing_npc", entity._npc_id)
        -- minetest.log(dump(entity._npc_object))
        minetest.chat_send_player(player:get_player_name(), minetest.colorize("#00ff00", "You are now editing NPC: " .. entity._npc_id))
        -- minetest.log(entity._npc_id or "none")
      end
    end
    return
  end
})

minetest.register_tool("folks:npc_remover", {
  description = "Use this to remove the NPC you click",
  inventory_image = "npc_remover.png",
  groups = {oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, player, pointed_thing)
    if pointed_thing.type == "nothing" then return end

    local entity = pointed_thing.ref:get_luaentity()
    if entity._isfolk and not entity._isremoved then
      mobkit.hq_die(entity)
      folks.backend.remove_npc(entity)
      return
    else
      return
    end
  end
})
