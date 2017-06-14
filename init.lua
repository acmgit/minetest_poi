minetest.register_chatcommand("poi_hot", {
	privs = {
		interact = true
	},
	description = "Teleports you to House of Teleport",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		player:setpos({x = 10, y = 2.5, z = 55})
		return true, "Teleportet to HoT"
	end
})