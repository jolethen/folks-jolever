folks.default_npc = {
  initial_properties = {
    hp_max = 9999,
    physical = true,
    collide_with_objects = false,
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "npc.b3d",
    textures = {
      {"npc.png"},
    },
    pushable = false,
    nametag = "Folk",
    nametag_color = "#ffffff",
  },

  -- mobkit properties
  timeout = 0,
  max_hp = 9999,
  buoyancy = -1,
  lung_capacity = 200,
  on_step = mobkit.stepfunc,
  -- on_activate = mobkit.actfunc,
  on_activate = function(self, staticdata, dtime_s)
    if staticdata ~= nil then
      staticdata = minetest.deserialize(staticdata)
      if staticdata._npc_id ~= nil then
        self.memory = {}
        self.memory._npc_id = staticdata._npc_id
      else
        self.memory = folks.util.deepcopy(staticdata.memory)
      end
      local npc_data = folks.backend.load_npc(self.memory._npc_id)
      if npc_data then
        self.object:set_properties({
          nametag = npc_data._npc_name,
          nametag_color = npc_data._npc_name_color,
        })
        self._npc_id = self.memory._npc_id
      end
    end

    mobkit.actfunc(self, staticdata, dtime_s)
  end,
  get_staticdata = mobkit.statfunc,
  view_range = 24,
  max_speed = 10,
  jump_height = 10,
  logic = function(self)
    mobkit.vitals(self)
    local prty = mobkit.get_queue_priority(self)

    local pos = self.object:get_pos()

    if prty < 10 then
      local plyr = mobkit.get_nearby_player(self)
      if plyr and vector.distance(pos,plyr:get_pos()) < 8 then
        mobkit.lq_turn2pos(self, plyr:get_pos())
        return
      end
    end
  end,


  on_rightclick = function(self, player)
    minetest.chat_send_player(player:get_player_name(), "Yo che mi clicchi")
  end,

  on_punch = function(self, puncher, t_from_last, tool_cap, dir, dmg)
    minetest.log("action", minetest.serialize(tool_cap))
  end,

  -- custom properties
  _isfolk = true,
  _isremoved = false,
}



minetest.register_entity("folks:npc", folks.default_npc)
