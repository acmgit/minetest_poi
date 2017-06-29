local poi = {

	points = {}

}

minetest.register_privilege("poi", "Player may set Points of Interest.")

-- Loads the List of POI's
function poi.openlist()
	local file = io.open(minetest.get_worldpath().."/poi.txt", "r") -- Try to open the file

	if file then -- is open?
		local table = minetest.deserialize(file:read("*all"))
			if type(table) == "table" then
				poi.points = table.points
				return
				
			end -- if type(table)
			
	end -- if file
	
end -- poi.openlist()

-- Writes the List of POI's
function poi.save()
	local file = io.open(minetest.get_worldpath().."/poi.txt", "w") -- Try to write the file
	
	if file then -- is open?
		file:write(minetest.serialize({
			points = poi.points
		}))
		file:close()
		
	end -- if file
	
end -- poi.save()

-- List the POI's with an optional Arg
function poi.list(name, option)

   local list = ""
   local all = false -- is option -a set?
   
   minetest.chat_send_player(name, poi.count() .. " Point's of Interest are:")

   if(option == "-a") then			-- Set Flag for Option all
      all = true
   
   end
   
   for key, value in poi.spairs(poi.points) do	-- Build up the List
      if all then
         list = list .. key .. ": " .. value .. "\n"
      
      else
         list = list .. key .. "\n"
      
      end -- if all

   end -- for key,value

   minetest.chat_send_player(name, core.colorize('#FF6700',list)) -- Send List to Player		
   return true
      
end -- poi.list()

-- Set's a POI
function poi.set(name, poi_name)
  
   local player = minetest.get_player_by_name(name)
   local currpos = player:getpos(name)
         
   if poi.exist(poi_name) then -- Ups, Name exists
	minetest.chat_send_player(name, core.colorize('#ff0000', "PoI <" .. poi_name .. "> exists."))
	return false -- Name exists, leave function

   end -- if poi.exist
	
   poi.points[poi_name] = minetest.pos_to_string(currpos) -- Insert the new Entry
   poi.save() -- and write the new List
  

   minetest.log("action","[POI] "..name .. " has set the POI: " .. poi_name .. " at " .. minetest.pos_to_string(currpos) .. "\n")
   minetest.chat_send_player(name, core.colorize('#00ff00',"POI: " .. poi_name .. " at " .. minetest.pos_to_string(currpos) .." stored."))
   return true
     
end -- poi.set()

-- Deletes a POI
function poi.delete(name, poi_name)
	
   if(poi_name == nil or poi_name == "") then  -- No PoI-Name given ..
      minetest.chat_send_player(name, "Name of the PoI needed.")
      return false -- can't delete a non-existing Entry, leave function

   end
   
   if poi.exist(poi_name) == false then
	minetest.chat_send_player(name, core.colorize('#ff0000', "PoI <" .. poi_name .. "> unknown to delete."))
	return false -- can't delete a non-existing Entry, leave function
	
   end -- if poi.exist
   
   local list = ""
   
   list = poi_name .. ": " .. poi.points[poi_name]	-- Get the full Name of the PoI and save it in a temporary var
   poi.points[poi_name] = nil -- and delete it

   minetest.log("action","[POI] "..name .. " has deleted POI-Name: " .. list .. "\n")
   minetest.chat_send_player(name, core.colorize('#ff0000',list .. " deleted."))
   poi.save()	-- Write the new list at the server
	
   return true
	
end -- poi.delete()

-- Reload or Reset the List of PoI's and load it new
function poi.reload(name)
   poi.points = nil -- Deletes the List of PoI's
   poi.openlist() -- and Load it new
	
   minetest.chat_send_player(name, core.colorize('#ff0000', "POI-List reloaded."))
   return true

end -- poi.reload()

-- Jumps to PoI
function poi.jump(name, poi_name)
		
   if (poi.exist(poi_name) == false) then -- Unknown or not existing Point of Interest
      minetest.chat_send_player(name, core.colorize('#ff0000', "Unknown Point of Interest: " .. poi_name .. "."))
      return false -- POI not in List, leave function
      			
   end -- if poi.exist

   local Position = poi.points[poi_name]
   local player = minetest.get_player_by_name(name)
   
   player:setpos(minetest.string_to_pos(Position)) -- Move Player to Point
   minetest.chat_send_player(name, core.colorize('#00ff00',"You are moved to POI: " .. poi_name .. "."))
   return true

end -- poi.jump()


-- shows gui with all available PoIs
function poi.gui(player_name)
	local list = ""
	for key, value in poi.spairs(poi.points) do	-- Build up the List
   
         list = list .. key .. ","
      
	end -- for key,value
	
	minetest.show_formspec(player_name,"minetest_poi:thegui",
				"size[4,8]" ..
				"label[0.6,0;PoI-Gui, doubleclick on destination]"..
				"textlist[0.4,1;3,5;name;"..list..";selected_idx;false]"..
				"label[0.6,6;".. poi.count() .. " Points in List]"..
				"button_exit[0.4,7;3.4,1;poi.exit;Quit]"
				)
end -- poi.gui()

-- Callback for formspec
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "minetest_poi:thegui" then -- The form name
		local event = minetest.explode_textlist_event(fields.name)  -- get values of what was clicked
		if (event.type == "DCL") then               -- DCL =doubleclick CHG = leftclick single   by minetest definition
		    local i = 0
		    local teleport = ""
		    for key, value in poi.spairs(poi.points) do	-- search for name of indexnumber
		      i = i+1
		      if i == event.index then 
			  teleport = key
			  break
			  
		      end -- if event.index
		      
		    end -- for key,value
		    
		    poi.jump(player:get_player_name(), teleport) -- gogogo :D
		    return false
		    
		end -- if event.type
		
	end -- if formname
end)

-- Changes a POI-Position
function poi.move(name, poi_name)
           
   if (poi.exist(poi_name) == false) then
	minetest.chat_send_player(name, core.colorize('#ff0000', "Unknown PoI <" .. poi_name .. ">."))
	return false

   end -- if poi.exist

   local exist = false
   local player = minetest.get_player_by_name(name)
   local currpos = player:getpos(name)
   local oldpos = poi.points[poi_name]
   
   poi.points[poi_name] = minetest.pos_to_string(currpos) -- Write the Position new
   poi.save() -- and write the List
  
   minetest.log("action","[POI] "..name .. " has moved the POI: " .. poi_name .. " at " .. oldpos ..  " to Position: " .. minetest.pos_to_string(currpos) .. "\n")
   minetest.chat_send_player(name, core.colorize('#00ff00',"POI: " .. poi_name .. " at " .. oldpos .." moved to Position: " .. minetest.pos_to_string(currpos) .."\n"))
   return true

end -- poi.move

function poi.spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do 
	keys[#keys+1] = k 
    end -- for k

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end -- if order

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end -- if keys
	
    end -- function()
    
end -- poi.spairs

-- Check the PoI in the List? Return true if the Name exsists, else false
function poi.exist(poi_name)
   local exist = true
   
   if(poi_name == "" or poi_name == nil) then
      exist = false
      
   else
	local Position = poi.points[poi_name]
	if(Position == nil or Position == "") then
		exist = false 
	
	end -- if Position == nil
	
   end -- if poi_name ==
   
   return exist

end -- poi.exist

function poi.count()
	local count = 0
	for _,key in pairs(poi.points) do
		count = count + 1
		
	end -- for _,key
	
	return count
end -- poi.count

poi.openlist() -- Initalize the List on Start


-- The Chatcommands to Register it in MT
minetest.register_chatcommand("poi_set", {
	params = "<poi_name>",
	description = "Set's a Point of Interest.",
	privs = {poi = true},
	func = function(name, poi_name)

		poi.set(name, poi_name)
      
	end,
})

minetest.register_chatcommand("poi_gui", {
	params = "",
	description = "Shows PoIs in a GUI.",
	privs = {interact = true},
	func = function(name)

      poi.gui(name)
      
	end,
})
minetest.register_chatcommand("poi_list", {
	params = "<-a>",
	description = "Shows you all Point's of Interest. Optional -a shows you all Point's of Interest with Coordinates.",
	privs = {interact = true},
	func = function(name, arg)

		poi.list(name, arg)
      
	end,
})

minetest.register_chatcommand("poi_delete", {
	params = "<poi_name>",
	description = "Deletes a Point of Interest.",
	privs = {poi = true},
	func = function(name, poi_name)

		poi.delete(name, poi_name)
		
	end,
})

minetest.register_chatcommand("poi_reload", {
	params = "",
	description = "Loads the List of POI's new.",
	privs = {poi = true},
	func = function(name)

		poi.reload(name)
		
	end,
})

minetest.register_chatcommand("poi_jump", {
	params = "<POI-Name>",
	description = "Jumps to the Position of the Point of Interest.",
	privs = {interact = true},
	func = function(name, poi_name)

		poi.jump(name, poi_name)

	end,
})

minetest.register_chatcommand("poi_move", {
	params = "<POI-Name>",
	description = "Changes the Position of the Point of Interest.",
	privs = {interact = true},
	func = function(name, poi_name)

		poi.move(name, poi_name)

	end,
})
