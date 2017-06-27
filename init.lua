local poi = {
	points = {}
}

minetest.register_privilege("poi", "Player may set Points of Interest.")

-- Loads the List of POI's
local function poi_openlist()
	local file = io.open(minetest.get_worldpath().."/poi.txt", "r")

	if file then
		local table = minetest.deserialize(file:read("*all"))
			if type(table) == "table" then
				poi.points = table.points
				return
			end
	end
end

-- Writes the List of POI's
local function poi_save()
	local file = io.open(minetest.get_worldpath().."/poi.txt", "w")
	if file then
		file:write(minetest.serialize({
			points = poi.points
		}))
		file:close()
	end
end

-- List the POI's with an optional Arg
local function poi_list(name, option)

   local list = ""
   local all = false
   
   minetest.chat_send_player(name, "Point's of Interest are:")

   if(option == "-a") then			-- Set Flag for Option all
      all = true
   
   end
   
   for key, value in pairs(poi.points) do	-- Build up the List
      if all then
         list = list .. key .. ": " .. value .. "\n"
      
      else
         list = list .. key .. "\n"
      
      end

   end

      minetest.chat_send_player(name, core.colorize('#FF6700',list)) -- Send List to Player		
      return true
end

-- Set's a POI
local function poi_set(name, poi_name)
  
   local player = minetest.get_player_by_name(name)
   local currpos = player:getpos(name)
   
   local exist = false
      
   if poi_exist(poi_name) then
	minetest.chat_send_player(name, core.colorize('#ff0000', "PoI <" .. poi_name .. "> exists."))
	return false

   end
	
   poi.points[poi_name] = minetest.pos_to_string(currpos)
   poi_save()
  

   minetest.log("action","[POI] "..name .. " has set the POI: " .. poi_name .. " at " .. minetest.pos_to_string(currpos) .. "\n")
   minetest.chat_send_player(name, core.colorize('#00ff00',"POI: " .. poi_name .. " at " .. minetest.pos_to_string(currpos) .." stored."))
   return true
     
end

-- Deletes a POI
local function poi_delete(name, poi_name)
	
   if(poi_name == nil or poi_name == "") then  -- No PoI-Name given ..
      minetest.chat_send_player(name, "Name of the PoI needed.")
      return false

   end
   
   if poi_exist(poi_name) == false then
	minetest.chat_send_player(name, core.colorize('#ff0000', "PoI <" .. poi_name .. "> unknown to delete."))
	return false
   end
   
   local list = ""
   
   list = poi_name .. ": " .. poi.points[poi_name]	-- Get the full Name of the PoI
   poi.points[poi_name] = nil -- and delete it

   minetest.log("action","[POI] "..name .. " has deleted POI-Name: " .. list .. "\n")
   minetest.chat_send_player(name, core.colorize('#ff0000',list .. " deleted."))
   poi_save()	-- Write the new list at the server
	
   return true
	
end

-- Reload or Reset the List of PoI's and load it new
local function poi_reload(name)
   poi.points = nil -- Deletes the List of PoI's
   poi_openlist() -- and Load it new
	
   minetest.chat_send_player(name, core.colorize('#ff0000', "POI-List reloaded."))
   return true

end

-- Jumps to PoI
function poi_jump(name, poi_name)		
   if (poi_exist(poi_name) == false) then
      minetest.chat_send_player(name, core.colorize('#ff0000', "Unknown Point of Interest: " .. poi_name .. "."))
      return false
      			
   end

   local Position = poi.points[poi_name]
   local player = minetest.get_player_by_name(name)
   
   player:setpos(minetest.string_to_pos(Position))
   minetest.chat_send_player(name, core.colorize('#00ff00',"You are moved to POI: " .. poi_name .. "."))
   return true

end


-- shows gui with all available PoIs
local function poi_gui(player_name)
	local list = ""
	for key, value in pairs(poi.points) do	-- Build up the List
   
         list = list .. key .. ","
      
	end
	minetest.show_formspec(player_name,"minetest_poi:thegui",
				"size[4,8]" ..
				"label[0.6,0;PoI-Gui, doubleclick on destination]"..
				"textlist[0.4,1;3,6;name;"..list..";selected_idx;false]"..
				"button_exit[0.4,7;3.4,1;poi.exit;Quit]"
)end

-- Callback for formspec
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "minetest_poi:thegui" then -- The form name
		local event = minetest.explode_textlist_event(fields.name)  -- get values of what was clicked
		if (event.type == "DCL") then               -- DCL =doubleclick CHG = leftclick single   by minetest definition
		    local i = 0
		    local teleport = ""
		    for key, value in pairs(poi.points) do	-- search for name of indexnumber
		      i = i+1
		      if i == event.index then 
			  teleport = key
			  break
		      end
		    end
		    poi_jump(player:get_player_name(), teleport) -- gogogo :D
		    return false
		    
		end
	end
end)

-- Changes a POI-Position
local function poi_move(name, poi_name)
     
   local exist = false
      
   if (poi_exist(poi_name) == false) then
	minetest.chat_send_player(name, core.colorize('#ff0000', "Unknown PoI <" .. poi_name .. ">."))
	return false

   end

   local player = minetest.get_player_by_name(name)
   local currpos = player:getpos(name)
   local oldpos = poi.points[poi_name]
   
   poi.points[poi_name] = minetest.pos_to_string(currpos)
   poi_save()
  
   minetest.log("action","[POI] "..name .. " has moved the POI: " .. poi_name .. " at " .. oldpos ..  " to Position: " .. minetest.pos_to_string(currpos) .. "\n")
   minetest.chat_send_player(name, core.colorize('#00ff00',"POI: " .. poi_name .. " at " .. oldpos .." moved to Position: " .. minetest.pos_to_string(currpos) .."\n"))
   return true

end

-- Check the PoI in the List? Return true if the Name exsists, else false
function poi_exist(poi_name)
   local exist = true
   
   local Position = poi.points[poi_name]
   if(Position == nil or Position == "") then
	exist = false 
   end
   
   return exist

end

poi_openlist() -- Initalize the List on Start
 
-- The Chatcommands to Register it in MT
minetest.register_chatcommand("poi_set", {
	params = "<poi_name>",
	description = "Set's a Point of Interest.",
	privs = {poi = true},
	func = function(name, poi_name)

		poi_set(name, poi_name)
      
	end,
})

minetest.register_chatcommand("poi_gui", {
	params = "",
	description = "Shows PoIs in a GUI.",
	privs = {interact = true},
	func = function(name)

      poi_gui(name)
      
	end,
})
minetest.register_chatcommand("poi_list", {
	params = "<-a>",
	description = "Shows you all Point's of Interest. Optional -a shows you all Point's of Interest with Coordinates.",
	privs = {interact = true},
	func = function(name, arg)

		poi_list(name, arg)
      
	end,
})

minetest.register_chatcommand("poi_delete", {
	params = "<poi_name>",
	description = "Deletes a Point of Interest.",
	privs = {poi = true},
	func = function(name, poi_name)

		poi_delete(name, poi_name)
		
	end,
})

minetest.register_chatcommand("poi_reload", {
	params = "",
	description = "Loads the List of POI's new.",
	privs = {poi = true},
	func = function(name)

		poi_reload(name)
		
	end,
})

minetest.register_chatcommand("poi_jump", {
	params = "<POI-Name>",
	description = "Jumps to the Position of the Point of Interest.",
	privs = {interact = true},
	func = function(name, poi_name)

		poi_jump(name, poi_name)

	end,
})

minetest.register_chatcommand("poi_move", {
	params = "<POI-Name>",
	description = "Changes the Position of the Point of Interest.",
	privs = {interact = true},
	func = function(name, poi_name)

		poi_move(name, poi_name)

	end,
})
