poi = {
	points = {}
}

minetest.register_privilege("tourist", "Player may set Points of Interest.")
minetest.register_privilege("tour_guide", "Player may delete all Points of Interest.")

function poi.openlist()
	local file = io.open(minetest.get_worldpath().."/poi.txt", "r")

	if file then
		local table = minetest.deserialize(file:read("*all"))
			if type(table) == "table" then
				poi.points = table.points
				return
			end
	end
end

function poi.save()
	local file = io.open(minetest.get_worldpath().."/poi.txt", "w")
	if file then
		file:write(minetest.serialize({
			points = poi.points
		}))
		file:close()
	end
end
 
poi.openlist()
 

minetest.register_chatcommand("poi_set", {
	params = "<poi_name>",
	description = "Set's a Point of Interest.",
	privs = {tourist = true},
	func = function(name, poi_name)

		local player = minetest.get_player_by_name(name)
		local currpos = player:getpos(name)

		poi.points[poi_name] = minetest.pos_to_string(currpos)
		poi.save()
				
		print(name .. " has set the POI: " .. poi_name .. " at " .. minetest.pos_to_string(currpos) .. "\n")
		return true, "POI: " .. poi_name .. " at " .. minetest.pos_to_string(currpos) .." stored."
	end,
})

minetest.register_chatcommand("poi_list", {
	params = "<-a>",
	description = "Shows you all Point's of Interest. Optional -a shows you all Point's of Interest with Coordinates.",
	privs = {interact = true},
	func = function(name, arg)
		minetest.chat_send_player(name, "Point's of Interest are:")
		local list = ""
		
		for key, value in pairs(poi.points) do

			if(arg == "-a") then
				list = list .. key .. ": " .. value .. "\n"
			
			else
				list = list .. key .. "\n"
			
			end
			
		end
		
		minetest.chat_send_player(name, list)		
		return true
	end,
})

minetest.register_chatcommand("poi_delete", {
	params = "<poi_name>",
	description = "Deletes a Point of Interest.",
	privs = {tour_guide = true},
	func = function(name, poi_name)
	
		if(poi_name == nil or poi_name == "") then
			return false, "POI-Name needed."
		
		end
	
		local list = ""
		list = poi_name .. ": " .. poi.points[poi_name]

		poi.points[poi_name] = nil
		print(name .. " has deleted POI-Name: " .. list .. "\n")

		minetest.chat_send_player(name, list .. " deleted.")
		poi.save()	-- Write the new list at the server
		return true
	end,
})

minetest.register_chatcommand("poi_reload", {
	params = "",
	description = "Loads the List of POI's new.",
	privs = {tour_guide = true},
	func = function(name)
		
		poi.points = nil
		poi.openlist()
		
		print(name .. " has reloaded the POI-List\n")
		minetest.chat_send_player(name, "POI-List reloaded.")
		return true
	end,
})

minetest.register_chatcommand("poi", {
	params = "<POI-Name>",
	description = "Jumps to the Position of the Point of Interest.",
	privs = {interact = true},
	func = function(name, poi_name)
		
		local Position = poi.points[poi_name]
		
		if(Position == nil or Position == "") then
			return false, "Unknown Point of Interrest: " .. poi_name .. "."
			
		end
		
		local player = minetest.get_player_by_name(name)
		player:setpos(minetest.string_to_pos(Position))
		return true, "Moved to " .. poi_name .. "."

	end,
})
