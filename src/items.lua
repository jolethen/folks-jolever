local S = core.get_translator("folks")

core.register_tool("folks:npc_creator", {
  description = S("Use this to create a new NPC  at your position"),
  inventory_image = "npc_creator.png",
  groups = {oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, player, pointed_thing)
    if not core.check_player_privs(player:get_player_name(), { folks_admin=true }) then return end
    folks.add_npc(player:get_pos())
  end
})

core.register_tool("folks:npc_editor", {
  description = S("Use this to edit the NPC you click"),
  inventory_image = "npc_editor.png",
  groups = {oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, player, pointed_thing)
    if pointed_thing.type == "nothing" or pointed_thing.type == "node" then return end
    if not core.check_player_privs(player:get_player_name(), { folks_admin=true }) then return end

    local entity = pointed_thing.ref:get_luaentity()
    if entity._isfolk then
      if mobkit.is_alive(entity) and not entity._isremoved then
        -- TODO: show formspec to edit clicked npc
        local meta = player:get_meta()
        meta:set_string("folks_editing_npc", entity._npc_id)
        -- core.log(dump(entity._npc_object))
        core.chat_send_player(player:get_player_name(), core.colorize("#00ff00", S("You are now editing NPC: @1", entity._npc_id)))
        -- core.log(entity._npc_id or "none")
        -- formspec
        core.show_formspec(player:get_player_name(), "folks:edit_npc_formspec", folks.get_edit_formspec(entity._npc_id))
        -- end formspec
      end
    end
  end
})

core.register_tool("folks:npc_remover", {
  description = S("Use this to remove the NPC you click"),
  inventory_image = "npc_remover.png",
  groups = {oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, player, pointed_thing)
    if pointed_thing.type == "nothing" or pointed_thing.type == "node" then return end
    if not core.check_player_privs(player:get_player_name(), { folks_admin=true }) then return end

    local entity = pointed_thing.ref:get_luaentity()
    if entity._isfolk and not entity._isremoved then
      if folks.get_npc(entity._npc_id) then
        for _, npc_obj in pairs(folks.get_npc_objs(entity._npc_id)) do
          npc_obj:remove()
        end
        folks.remove_npc(entity._npc_id)
      end
    end
  end
})

core.register_tool("folks:npc_spawner", {
  description = S("Use this to spawn an NPC that you had already created"),
  inventory_image = "npc_spawner.png",
  groups = {oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, player, pointed_thing)
    if not core.check_player_privs(player:get_player_name(), { folks_admin=true }) then return end

    core.show_formspec(player:get_player_name(), "folks:spawn_npc_formspec", folks.get_spawn_formspec())
  end
})

core.register_tool("folks:npc_despawner", {
  description = S("Use this to despawn without deleting the NPC you click"),
  inventory_image = "npc_despawner.png",
  groups = {oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, player, pointed_thing)
    if pointed_thing.type == "nothing" or pointed_thing.type == "node" then return end
    if not core.check_player_privs(player:get_player_name(), { folks_admin=true }) then return end

    pointed_thing.ref:remove()
  end
})
