dofile(minetest.get_modpath("poi") .. "/poi.lua")

for i,n in ipairs(points) do
   
    -- Register the POI's
    
    minetest.register_chatcommand("poi_" .. n.cmd, {
    privs = n.priv,
    description = n.desc,

    func = function(name, param)
	local player = minetest.get_player_by_name(name)
		player:setpos(n.pos)
		return true, n.msg
    end
    })

end
