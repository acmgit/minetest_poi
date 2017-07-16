poi_namefilter = {}
poi_categories = {}

dofile(minetest.get_modpath("minetest_poi") .. "/namefilter.lua")
dofile(minetest.get_modpath("minetest_poi") .. "/categories.lua")

local storage = minetest.get_mod_storage()  -- initalize storage file of this mod. This can only happen here and should be always local
local poi = {

	points = {},
	filter = {},
	categories = {},
	max_categories
}

-- Options for Print_Message
local log = 0
local green = '#00FF00'
local red = '#FF0000'
local orange = '#FF6700'
local none = 99

minetest.register_privilege("poi", "Player may set Points of Interest.")


--[[
	********************************************
	***           Functions of POI                    ***
	********************************************
--]]

-- Loads the List of POI's
function poi.openlist()

	local load = storage:to_table()
	poi.points = load.fields

end -- poi.openlist()


-- Writes the List of POI's
function poi.save()

	storage:from_table({fields=poi.points})
	
end -- poi.save()

-- Loads the List of POI's  Read PoIs from the old file  --  Can be disabled in the future only for backward compatibility
function poi.oldlist(name)
	local file = io.open(minetest.get_worldpath().."/poi.txt", "r") -- Try to open the file

	if file then -- is open?
		local table = minetest.deserialize(file:read("*all"))
			if type(table) == "table" then
				poi.points = nil
				poi.points = table.points
				poi.print(name, "POI-List reloaded.", green)

			end -- if type(table)

	end -- if file

end -- poi.openlist()

-- Helpfunctions for the List-Command
function poi.list_filter(name)
	local list = ""
	local index = 0

	for key, value in pairs(poi.filter) do
		list = list .. key .. ": " .. value .. "\n"
		index = index + 1

	end -- for key, value
	
	poi.print(name, list, orange)
	poi.print(name, index .. " Filter in List.", green)
	
end -- poi.list_filter()

function poi.list_categories(name)
	local list = ""
	local index = 0

	for key, value in pairs(poi.categories) do
		list = list .. key .. ": " .. value .. "\n"
		index = index + 1

	end -- for key,value

	poi.print(name, list, orange) -- Send List to Player
	poi.print(name, index .. " Categories in List.", green) -- Send List to Player

end -- poi.list_categories()

-- List the POI's with an optional Arg
function poi.list(name, option)

	local list = ""
	local all = false 	-- is option list all set?
	local pos, cat
	local idx = 0	-- a given Index with the option -i <number>
	
-- Check Options for the Command List

	-- Lists only Filterwords
	if string.find(string.lower(option), "-f") ~= nil then
		poi.list_filter(name)
		return true

	end

	-- Lists only the Categories
	if string.find(string.lower(option), "-c") ~= nil then
		poi.list_categories(name)
		return true
	end

	-- List the full Entries of PoI's
	if string.find(string.lower(option), "-a") ~= nil then
		all = true

	end

	if string.find(string.lower(option), "-i") ~= nil then
		idx = tonumber(string.sub(string.lower(option), string.find(string.lower(option), "-i") + 2, -1))
		idx = idx or 0 -- Convert a invalid Number to 0
	end
	
	if (idx > 0) then
		poi.print(name, "Point's of Interest in Categorie " .. poi.get_categoriename(idx) .. " are:", green)
	
	else
		poi.print(name, poi.count() .. " Point's of Interest are:", green)
	
	end -- if(idx > 0)
	
	for key, value in poi.spairs(poi.points) do	-- Build up the List
		pos, cat = poi.split_pos_cat(value)
		if(idx > 0) then
			if(cat == idx) then
				if all then
					list = list .. key .. ": " .. pos .. "\n"

				else
					list = list .. key .. "\n"

				end -- if all
				
			end -- if (key == idx)
			
		else -- if(idx > 0)
			if all then
				list = list .. key .. ": " .. pos .. " Categorie: " .. poi.get_categoriename(cat) .. "\n"
				
			else
				list = list .. key .. "\n"
				
			end -- if(all)
			
		end -- if(key == idx)

	end -- for key,value

	poi.print(name, list, orange) -- Send List to Player
	return true

end -- poi.list()

-- Set's a POI
function poi.set(name, poi_name)

	local player = minetest.get_player_by_name(name)
	local currpos = player:getpos(name)
	local categorie, p_name
	
	p_name, categorie = poi.split_option(poi_name)
	
	if poi.exist(p_name) then -- Ups, Name exists
		if(poi.get_categorie(p_name) ~= categorie) then -- ok, we want to change the Categorie
			local value = poi.points[p_name]
			local pos, cat
			pos, cat = poi.split_pos_cat(poi.points[p_name])
			poi.points[p_name] = pos .. "{" .. tonumber(categorie) .. "}" -- Changes the Entry
			poi.print(name, name .. " has changed the POI: " .. p_name .. " at " .. pos .. " Categorie: " .. poi.get_categoriename(cat) .. " to Categorie: " .. poi.get_categoriename(categorie) .. "\n", log)
			poi.print(name, "POI: " .. p_name .. " at " .. pos .." in Categorie: " .. poi.get_categoriename(cat) .." changed to Categorie: " .. poi.get_categoriename(categorie), green)
			poi.save()
			return true
			
		else
			poi.print(name, "PoI <" .. p_name .. "> exists.", red)
			return false -- Name exists, leave function
		end -- if(poi.get_categorie)

	end -- if poi.exist

	if not poi.check_name(p_name) then
		poi.print(name, "Invalid Name <" .. p_name .. "> for PoI.", red)
		return false

	end -- if poi.check_name

	poi.points[p_name] = minetest.pos_to_string(currpos) .. "{" .. tonumber(categorie) .. "}"-- Insert the new Entry
	poi.save() -- and write the new List

	poi.print(name, name .. " has set the POI: " .. p_name .. " at " .. minetest.pos_to_string(currpos) .. " Categorie: {" .. poi.get_categoriename(categorie) .. "}\n", log)
	poi.print(name, "POI: " .. p_name .. " at " .. minetest.pos_to_string(currpos) .." in Categorie: " .. poi.get_categoriename(categorie) .." stored.", green)
	return true

end -- poi.set()

-- Deletes a POI
function poi.delete(name, poi_name)

	if(poi_name == nil or poi_name == "") then  -- No PoI-Name given ..
	
		poi.print(name, "Name of the PoI needed.", red)
		return false -- can't delete a non-existing Entry, leave function

	end

	if poi.exist(poi_name) == false then
		poi.print(name,  "PoI <" .. poi_name .. "> unknown to delete.", red)
		return false -- can't delete a non-existing Entry, leave function

	end -- if poi.exist

	local list = ""

	list = poi_name .. ": " .. poi.points[poi_name]	-- Get the full Name of the PoI and save it in a temporary var
	poi.points[poi_name] = nil -- and delete it

	poi.print(name, name .. " has deleted POI-Name: " .. list .. "\n", log)
	poi.print(name, list .. " deleted.", red)
	poi.save()	-- Write the new list at the server

	return true

end -- poi.delete()

-- Reload or Reset the List of PoI's and load it new
function poi.reload(name)
	poi.points = nil -- Deletes the List of PoI's
	poi.openlist() -- and Load it new

	poi.print(name, "POI-List reloaded.", red)
	return true

end -- poi.reload()

-- Jumps to PoI
function poi.jump(name, poi_name)

	if (poi.exist(poi_name) == false) then -- Unknown or not existing Point of Interest
		poi.print(name, "Unknown Point of Interest: " .. poi_name .. ".", red)
		return false -- POI not in List, leave function

	end -- if poi.exist

	local Position = poi.points[poi_name]
	Position = poi.split_pos_cat(Position)		-- Extract the Position
	
	local player = minetest.get_player_by_name(name)

	player:setpos(minetest.string_to_pos(Position)) -- Move Player to Point
	poi.print(name, "You are moved to POI: " .. poi_name .. ".", green)
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
		poi.print(name, "Unknown PoI <" .. poi_name .. ">.", red)
		return false

	end -- if poi.exist

	local exist = false
	local player = minetest.get_player_by_name(name)
	local currpos = player:getpos(name)
	local oldpos = poi.points[poi_name]
	local cat = poi.split_pos_cat(oldpos)
	
	poi.points[poi_name] = minetest.pos_to_string(currpos) .. "{" .. tonumber(cat) .. "}" -- Write the Position new
	poi.save() -- and write the List

	poi.print(name, name .. " has moved the POI: " .. poi_name .. " at " .. oldpos ..  " to Position: " .. minetest.pos_to_string(currpos) .. "\n", log)
	poi.print(name, "POI: " .. poi_name .. " at " .. oldpos .." moved to Position: " .. minetest.pos_to_string(currpos) .."\n", green)
	return true

end -- poi.move

-- Renames a POI
function poi.rename(name, poi_name)
	local oldname, newname

	if string.find(poi_name, ",") == nil then
		poi.print(name, "/poi_rename: No new Name for Point given.\n", red)
		return false
	end

	oldname = poi.trim(string.sub(poi_name,1, string.find(poi_name, ",")-1))

	if not poi.exist(oldname) then
		poi.print(name, "Point to rename not found.\n", red)
		return false
	end

	newname = poi.trim(string.sub(poi_name, string.find(poi_name, ",") + 1, -1))

	if not poi.check_name(newname) then
		poi.print(name, "Invalid new Pointname.\n", red)
		return false
	end

	if poi.exist(newname) then
		poi.print(name, "New Pointname already exists.\n", red)
		return false
	end

	local old_position
	old_position = poi.points[oldname] -- get the Positioni
	poi.points[newname] = old_position -- and make a new entry

	poi.points[oldname] = nil -- now deletes the old one
	poi.save()			-- saves the List
	
	poi.print(name, name .. " has renamed POI-Name: " .. oldname .. " to: " .. newname .. " - Position: " .. old_position .. "\n", log)
	poi.print(name, "PoI-Name: " .. oldname .. " renamed to " .. newname .. " - Position: " .. old_position .. "\n", green)

end -- poi.rename()

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

-- Checks the List and deletes invalid Poi's
function poi.validate(name)
	local count = 0 -- Value of invalid Entries
	local invalid_cat = 0 -- Value of Entries without Categorie
	local key, value
	
	for key, value in pairs(poi.points) do
		if not poi.check_name(key) then -- is the Name valid?
			count = count + 1
			poi.points[key] = nil
		
		else
			if value == nil then -- is the Position of the PoI valid?
				count = count + 1
				poi.points[key] = nil
			
			else -- Yeahh, valid Entry, let us see the Categorie ...
			
				if( not (string.find(poi.points[key], "{")) and not (string.find(poi.points[key], "}"))) then
					-- Entry without Categorie found
					invalid_cat = invalid_cat + 1
					poi.points[key] = value .. "{1}" -- Set Categorie to 1
				end -- if(string.find)
				
				local pos, cat
				pos, cat = poi.split_pos_cat(poi.points[key])
<<<<<<< HEAD
				if( (cat == nil) or (cat > poi.max_categories) or (cat <= 0) )then	-- Invalid Categorienumber found
=======
				if( (cat == nil) or (cat > poi.max_categories) or (cat <= 0) then	-- Invalid Categorienumber found
>>>>>>> 2c90a366c9d05534223c0da3304b6d948caddabb
					poi.points[key] = pos .. "{1}" -- Changes the Categorienumber to 1
					invalid_cat = invalid_cat + 1
					
				end -- if(cat ==)
				
			end -- if value
			
		end -- if check_name
		
	end -- for key,value
	
	if (count > 0) or (nocat > 0) then
		poi.print(name, name .. " has deleted with validate " .. count .. " PoI's.\n", log)
		poi.print(name, name .. " has found " .. invalid_cat .. " Entries with an invalid Categorie.\n", log)
		poi.print(name, count .. " invalid PoI's found and deleted.", red)
		poi.print(name, invalid .. " PoI's with an invalid Categorie found and set to 1.", red)
		poi.save()
		
	else
		poi.print(name, "No invalid PoI found.\n", green)
		
	end
					
end -- poi.validate

--[[
	********************************************
	***           Helpfunctions                        ***
	********************************************
--]]

-- Trims a String
function poi.trim(myString)
	return (string.gsub(myString, "^%s*(.-)%s*$", "%1"))

end -- poi.trim()

-- Checks the valid of the name
function poi.check_name(name)
	if (name == "") or (name == nil) then
		return false

	end -- if name

	local valid = true

	for key, value in ipairs(poi.filter) do
		if string.find(string.lower(name), string.lower(value)) ~= nil then
			valid = false
		end -- if string.find

	end -- for key,value

	return valid -- Name was in Filter?

end -- poi.check_name()

-- Count's the amount of Entries
function poi.count()
	local count = 0
	for _,key in pairs(poi.points) do
		count = count + 1

	end -- for _,key

	return count
end -- poi.count

-- Returns a sorted Table
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

-- Writes a Message in a specific color or Logs it
function poi.print(name, message, color)

	error = error or none	-- No Error given, set it to 99 (none)
	
	-- Logs a Message
	if(color == log) then
		minetest.log("action","[POI] "..name .. " : " .. message)
		return
	
	else
		if(color ~= none) then
			minetest.chat_send_player(name, core.colorize(color, message))
			return
		
		else 
			minetest.chat_send_player(name,  message)
			return
		
		end -- if(error ~=none)
		
	end -- if(error == log)
	
end -- print_message()

-- Returns the Entryname and the Categorieindex from an given Option
function poi.split_option(poi_name)
	local categorie, p_name
	
	categorie = 1	-- Set's categorie to 1 per default
	
	if(string.find(poi_name, ",") ~= nil) then
		p_name = poi.trim(string.sub(poi_name,1, string.find(poi_name, ",")-1))					-- Extract only the Name
		categorie = tonumber(poi.trim(string.sub(poi_name,string.find(poi_name, ",")+1,-1)))		-- Extract the Number of Categorie		

	else
		p_name = poi_name	-- No Categorie found, only a Name was given

	end
	
	return p_name, categorie

end -- poi.split_option()

-- Returns Coordinates and Categorieindex from an Entry
function poi.split_pos_cat(position)
	local pos, cat
	
	if( (string.find(position,"{")) and (string.find(position, "}"))) then
		pos = string.sub(position, 1, string.find(position, "{") - 1) -- Extract the Coords
		cat = tonumber(string.sub(position, string.find(position, "{") + 1, string.find(position, "}") - 1)) -- Extract the Categorie
		cat = cat or 1 -- Convert it in an invalid case to 1
		
	else
	
		-- No Categorie found
		pos = position
		cat = 1			-- Categorie general
	
	end -- if(string.find(position)
	
	return pos, cat

end -- poi.split_pos_cat()


-- Get's a Categoriename by Index
function poi.get_categoriename(cat)

	local categorie = "Unknown"
	
	for key, value in pairs(poi.categories) do
		if(key == cat) then
			categorie = value
			break
			
		end -- if(key == cat)
		
	end -- for key,value

	return categorie

end -- get_categoriename()

-- Gets a Categorie of an Entry
function poi.get_categorie(poi_name)
	local value, cat, pos
	
	value = poi.points[poi_name]
	pos, cat = poi.split_pos_cat(value)
	
	return cat

end -- get_categorie()

function poi.count_categories()
	local cat = 0
	
	for key,value in pairs(poi.categories) do
		cat = cat + 1
		
	end -- for key,value
	
	return cat

end -- count_categories()
	
--[[
	********************************************
	***         Commands to Register             ***
	********************************************
--]]

minetest.register_chatcommand("poi_set", {
	params = "<poi_name, categorie>",
	description = "Set's a Point of Interest or changes the Categorie of an existing Point.",
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
	params = "<-a> <-c> <-f> <-i Number>",
	description = "Shows Point's of Interest.\nOption -a shows Point's of Interest with Coordinates.\nOption -c shows you Categories.\nOption -f shows you the Namefilter\nOption -i <Number> shows only the Entries of the given Categorienumber",
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

-- This command can be deleted in futures version, it is only to read old lists of minetest-poi beta
minetest.register_chatcommand("poi_import", {
	params = "",
	description = "Imports the PoIs of older poi-mod version, this will delete all current PoIs",
	privs = {poi = true},
	func = function(name)

		poi.oldlist(name)
		poi.save()

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

minetest.register_chatcommand("poi_rename", {
	params = "<POI Old Name>,<POI New Name",
	description = "Changes the Name of the Point of Interest.",
	privs = {interact = true},
	func = function(name, poi_name)

		poi.rename(name, poi_name)

	end,
})

minetest.register_chatcommand("poi_validate", {
	params = "",
	description = "Validates the List of PoI's.",
	privs = {poi = true},
	func = function(name)

		poi.validate(name)

	end,
})


-- add button to unified_inventory
if (minetest.get_modpath("unified_inventory")) then
	unified_inventory.register_button("minetest_poi", {
		type = "image",
		image = "minetest_poi_button_32x32.png",
		tooltip = "Show Points of Interest",
		action = function(player)
			local player_name = player:get_player_name()
			if not player_name then return end
			poi.gui(player_name)
		end,
	})
end

--[[
	********************************************
	***           Start of the Mod                     ***
	********************************************
--]]

poi.openlist() -- Initalize the List on Start
poi.filter = poi_namefilter
poi.categories = poi_categories
poi.max_categories = poi.count_categories()

