ChatCmdBuilder.new("folks", function(cmd)
  cmd:sub("edit name :name:text", function(pname, npc_name)
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
          folks.backend.get_npcs()[editing_npc]._npc_name = npc_name
          -- minetest.log(dump(npc._npc_object))
          if npc._npc_object then
            npc._npc_object:set_properties({
              nametag = npc_name,
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
