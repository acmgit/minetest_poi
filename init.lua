poi_namefilter = {}
poi_categories = {}

local storage = minetest.get_mod_storage()  -- initalize storage file of this mod. This can only happen here and should be always local
poi = {

	points = {},
	filter = {},
	categories = {},
	modpath = minetest.get_modpath(minetest.get_current_modname()),
    modname = minetest.get_current_modname()
}

-- Load support for intllib.
local S

if(minetest.get_modpath("intllib")) then
    S = dofile(poi.modpath .."/intllib.lua")
    print("[MOD] " .. poi.modname .. ": translating in intllib-mode.")
    
else
    S = minetest.get_translator(poi.modname)
    print("[MOD] " .. poi.modname .. ": translating in minetest-mode.")
    
end -- if(minetest.get_modpath(

poi.get_translator = S

dofile(poi.modpath .. "/namefilter.lua")   -- avoid servercrash loop if someone decided to rename the modfolder !
dofile(poi.modpath .. "/categories.lua")

-- Options for Print_Message
local log = 0
local green = '#00FF00'
local red = '#FF0000'
local orange = '#FF6700'
local none = 99

-- Options for Categories and Gui management
local call_list = {}   -- important array to find jump station in lists reduced by categories
local lastchoice = ""  -- last choosen destination from gui by single_click (android support and useful for extended gui in the future)
local selected_category = 0
local choosen_name = 0
local selected_point = ""
local drop_down = 0
local catlist = ""


minetest.register_privilege("poi", S("Player may set and manage Points of Interest."))


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

-- Helpfunctions for the List-Command
function poi.list_filter(name)
	local list = ""
	local index = 0

	for key, value in pairs(poi.filter) do
		list = list .. key .. ": " .. value .. "\n"
		index = index + 1

	end -- for key, value
	
	poi.print(name, list, orange)
	poi.print(name, index .. S(" Filter in List."), green)
	
end -- poi.list_filter()

function poi.list_categories(name)
	local list = ""
	local index = 0

	for key, value in pairs(poi.categories) do
		list = list .. key .. ": " .. value .. "\n"
		index = index + 1

	end -- for key,value

	poi.print(name, list, orange) -- Send List to Player
	poi.print(name, index .. S(" Categories in List."), green) -- Send List to Player

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
		if(idx == nil) then -- Option wan't a Number, then try to find out the Categorie by Name
			idx = poi.get_categorienumber(poi.trim(string.sub(string.lower(option), string.find(string.lower(option), "-i") + 2, -1)))
			
		end
		
		idx = idx or 0 -- Convert a invalid Number to 0
	end
	
	if (idx > 0) then
		poi.print(name, S("Point's of Interest in Categorie ") .. poi.get_categoriename(idx) .. S(" are:"), green)
	
	else
		poi.print(name, poi.count() .. S(" Point's of Interest are:"), green)
	
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
				list = list .. key .. ": " .. pos .. S(" Categorie: ") .. poi.get_categoriename(cat) .. "\n"
				
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
	
	-- Check Categorie, if Unknown then set it to General
	if categorie == 0 then categorie = 1
	end
	
	if poi.exist(p_name) then -- Ups, Name exists
		if(poi.get_categorie(p_name) ~= categorie) then -- ok, we want to change the Categorie
			if(categorie == -1) then	-- Invalid Categoriename?
				poi.print(name, S("Given Categorie don't exists."), red)
				return false
				
			end -- if(poi.get_categoriename())
			
			local value = poi.points[p_name]
			local pos, cat
			pos, cat = poi.split_pos_cat(poi.points[p_name])
			poi.points[p_name] = pos .. "{" .. tonumber(categorie) .. "}" -- Changes the Entry
			poi.print(name, name .. S(" has changed the POI: ") .. p_name .. S(" at ") .. pos .. S(" Categorie: ") .. poi.get_categoriename(cat) .. S(" to Categorie: ") .. poi.get_categoriename(categorie) .. "\n", log)
			poi.print(name, "POI: " .. p_name .. S(" at ") .. pos .. S(" in Categorie: ") .. poi.get_categoriename(cat) .. S(" changed to Categorie: ") .. poi.get_categoriename(categorie), green)
			poi.save()
			return true
			
		else
			poi.print(name, "PoI <" .. p_name .. S("> in Categorie <") .. categorie .. " - " .. poi.get_categoriename(categorie) .. S("> already exists."), red)
			return false -- Name exists, leave function
			
		end -- if(poi.get_categorie)

	end -- if poi.exist

	if not poi.check_name(p_name) then
		poi_name = poi.convertnil(poi_name) -- convert possible NIL		
		poi.print(name, S("Invalid or Forbidden Name <") .. p_name .. S("> for PoI."), red)
		return false

	end -- if poi.check_name

	if(categorie == -1) then  -- Checks invalid Categoriename, then set it on new Entry to 1
		poi.print(name, S("Warning: Unkown Categorie, set to Categorie 1."), red)
		categorie = 1
	end
	
	poi.points[p_name] = minetest.pos_to_string(currpos) .. "{" .. tonumber(categorie) .. "}"-- Insert the new Entry
	poi.save() -- and write the new List

	poi.print(name, name .. S(" has set the POI: ") .. p_name .. S(" at ") .. minetest.pos_to_string(currpos) .. S(" Categorie: ") .. "{" .. poi.get_categoriename(categorie) .. "}\n", log)
	poi.print(name, "POI: " .. p_name .. S(" at ") .. minetest.pos_to_string(currpos) .. S(" in Categorie: ") .. poi.get_categoriename(categorie) .. S(" stored."), green)
	return true

end -- poi.set()

-- Deletes a POI
function poi.delete(name, poi_name)

	if(poi_name == nil or poi_name == "") then  -- No PoI-Name given ..
	
		poi.print(name, S("Name of the PoI needed."), red)
		return false -- can't delete a non-existing Entry, leave function

	end

	if poi.exist(poi_name) == false then

		poi_name = poi.convertnil(poi_name) -- convert possible NIL
		poi.print(name,  "PoI <" .. poi_name .. S("> unknown to delete."), red)
		return false -- can't delete a non-existing Entry, leave function

	end -- if poi.exist

	local list = ""

	list = poi_name .. ": " .. poi.points[poi_name]	-- Get the full Name of the PoI and save it in a temporary var
	poi.points[poi_name] = nil -- and delete it

	poi.print(name, name .. S(" has deleted POI-Name: ") .. list .. "\n", log)
	poi.print(name, list .. S(" deleted."), red)
	poi.save()	-- Write the new list at the server

	return true

end -- poi.delete()

-- Reload or Reset the List of PoI's and load it new
function poi.reload(name)
	poi.points = nil -- Deletes the List of PoI's
	poi.openlist() -- and Load it new

	poi.print(name, S("POI-List reloaded."), red)
	return true

end -- poi.reload()

-- Jumps to PoI
function poi.jump(name, poi_name)

	if (poi.exist(poi_name) == false) then -- Unknown or not existing Point of Interest
		poi_name = poi.convertnil(poi_name) -- convert possible NIL			
		poi.print(name, S("Unknown Point of Interest: ") .. poi_name .. ".", red)
		return false -- POI not in List, leave function

	end -- if poi.exist

	local Position = poi.points[poi_name]
	Position = poi.split_pos_cat(Position)		-- Extract the Position
	
	local player = minetest.get_player_by_name(name)
	lastchoice = ""                                 -- set lastchoice back to zero

	poi.play_soundeffect(name, "teleport") -- Play's a Sound
	player:setpos(minetest.string_to_pos(Position)) -- Move Player to Point
	poi.print(name, S("You are moved to POI: ") .. poi_name .. ".", green)
	return true

end -- poi.jump()



-- ***********************************
-- ***********************************
-- ** The Gui section starting here **
-- ***********************************
-- ***********************************


-- shows gui with all available PoIs
function poi.gui(player_name, showup, main)
	local list = ""
	local showcat =  ""
	local cat
	local count = 0
	local manageme = ""
	
	
	
	for key, value in poi.spairs(poi.points) do	-- Build up the List
	cat = poi.get_categorie(key)
	
	  if not showup then
	    drop_down = 0
	    
	    if list == "" then
	               
		  list = key
	      
	    else
	   
		  list = list .. "," .. key
	      
	    end
	    count = count +1
	    call_list[count] = key  -- makes it easier to find jump point
	  else
	    drop_down = poi.get_categorienumber(showup)
	    --showcat = "label[0.6,0.4;Category is: "..showup.."]" -- show choosen categorie in gui ##not needed anymore 
	    if poi.get_categorienumber(showup) == cat then
	      if list == "" then
	   
		  list = key
	      
	      else
	   
		  list = list .. "," .. key
	      
	      end
	      count = count +1
	      call_list[count] = key  -- makes it easier to find jump point
	    end
	  end

	end -- for key,value

	if minetest.get_player_privs(player_name).poi then
	    manageme = "button[5,6.5;2,1;poimanager;" .. S("Manage PoI") .. "]"
	end
		
	if main then
	      minetest.show_formspec(player_name,"minetest_poi:thegui",                            -- The main gui for everyone with interact
				      "size[7,8]" ..
				      "label[0.4,0;> ".. S("Double-click on destination to teleport") .. " <]"..
				      --showcat..
				      "textlist[0.4,1;3,5;name;"..list..";selected_idx;false]"..
				      "label[0.6,6;".. count .. S(" points in list") .. "]" ..
				      "label[4.3,0.5; ".. S("Categories") .. " ]" ..
				      "dropdown[4,1;2,1;dname;"..catlist..";"..drop_down.."]"..
				      "button[0.4,6.5;1,1;poitelme;".. S("Go") .. "]" ..
				      "button[1.4,6.5;2,1;poishowall;" .. S("Show all") .. "]" ..manageme..
				      "button_exit[0.4,7.4;3.4,1;poiexit;" .. S("Quit") .. "]"
				      )
	else
	      minetest.show_formspec(player_name,"minetest_poi:manager",                            -- The management gui for people with poi priv
				      "size[7,9]" ..
				      "textlist[0.4,0;3,5;maname;"..list..";"..choosen_name..";false]"..
				      "textlist[4,0;2,2;madname;"..catlist..";"..selected_category..";false]".. 
				      "button[4,2.5;2,1;reload;" .. S("Reload") .. "]" ..
				      "button[4,3.5;2,1;validate;" .. S("Validate") .. "]"..
				      "field[0.3,5.4;7,1;managename;                                                                                      - ".. S("Enter Name").." -;"..selected_point.."]"..
				      "button[0.4,6;6,1;set;" .. S("Set Point or change Categorie") .. "]"..
				      "button[0.4,7;2,1;rename;" .. S("Rename") .. "]"..
				      "button[2.4,7;2,1;move;" .. S("Move") .. "]"..
				      "image_button[5.4,7;1,1;minetest_poi_deleteme.png;delete;]"..
				      "button_exit[0.4,8;3,1;doexit;" .. S("Quit") .. "]"..
				      "button[3.4,8;3,1;goback;" .. S("Back") .. "]"
				      )
	end
end -- poi.gui()

-- Callback for formspec
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "minetest_poi:thegui" and player then -- The form name and player must be online
	
		
		local event = minetest.explode_textlist_event(fields.name)  -- get values of what was clicked
		
		    
		if fields.poiexit then
			lastchoice = nil
			choosen_name = 0
			selected_point = ""
			return false
		end
		
		if fields.poishowall then
		    lastchoice = nil
		    poi.gui(player:get_player_name(), nil, true)
		    return false
		end
		
		if fields.poimanager then
		    poi.gui(player:get_player_name(), nil, false)
		    return false
		end
		

		if fields.poitelme and lastchoice ~= "" then                -- single click and go-Button is much easier for tablet users
		    poi.jump(player:get_player_name(), lastchoice)
		    return false
		end
		
		
		if (event.type == "CHG") and event.index then              -- save the last choosen PoI by singleclick
		    lastchoice = call_list[event.index]
		end
		
		
		if fields.dname and fields.dname ~= "" then
			  poi.gui(player:get_player_name(), fields.dname, true)
		end
		
		
		if (event.type == "DCL") then               -- DCL =doubleclick CHG = leftclick single   by minetest definition
		   poi.jump(player:get_player_name(), call_list[event.index])
		  return false
		end -- if event.type
		
		

	end -- if formname
	
	if formname == "minetest_poi:manager" and player then -- The form name and player must be online
	
		local youaretheboss = minetest.get_player_privs(player:get_player_name()).server
		local event = minetest.explode_textlist_event(fields.maname)  -- get values of what was clicked in PoI
		local catevent = minetest.explode_textlist_event(fields.madname)  -- get values of what was clicked in Categories
	
		if fields.goback then
			selected_category = 0
			choosen_name = 0
			selected_point = ""
			poi.gui(player:get_player_name(), nil, true)
			return false
		end
		
		if fields.doexit then
			selected_category = 0
			choosen_name = 0
			selected_point = ""
			return false
		end
		
		if fields.reload then
			poi.reload(player:get_player_name())
			poi.gui(player:get_player_name(), nil, false)
		end
		
		if fields.validate then
			poi.validate(player:get_player_name())
			poi.gui(player:get_player_name(), nil, false)
		end
		
		if fields.delete then
		      if youaretheboss then                                      -- Sorry I couldn't resist :D
			poi.delete(player:get_player_name(),selected_point)
			poi.gui(player:get_player_name(), nil, false)
		      else
			poi.print(player:get_player_name(),S(" >>> Sorry this button is for admin only, please use /poi_delete ")..selected_point,red)
		      end
		end
		
		if fields.move then
			poi.move(player:get_player_name(),selected_point)
			poi.gui(player:get_player_name(), nil, false)
			
		end
		
		if fields.rename then
			poi.rename(player:get_player_name(),selected_point..","..fields.managename)
			poi.gui(player:get_player_name(), nil, false)
		end
		
		if fields.managename then
			choosen_name = 0
			selected_point = fields.managename
			poi.gui(player:get_player_name(), nil, false)
		end
		
		if fields.set then
			poi.set(player:get_player_name(), selected_point..","..selected_category)
			selected_category = 0
			choosen_name = 0
			selected_point = ""
			poi.gui(player:get_player_name(), nil, false)
		end
		
		if (event.type == "CHG") and event.index then              -- save the last choosen poi
		    selected_point = call_list[event.index]
		    choosen_name = event.index
		    selected_category = poi.get_categorie(selected_point)
		    poi.gui(player:get_player_name(), nil, false)
		end
		
		if (catevent.type == "CHG") and catevent.index then              -- save the last choosen category
		    selected_category = catevent.index
		    poi.gui(player:get_player_name(), nil, false)
		end
	end
		
end)


-- *********************************
-- *********************************
-- ** The Gui section ending here **
-- *********************************
-- *********************************

-- Changes a POI-Position
function poi.move(name, poi_name)

	if (poi.exist(poi_name) == false) then
		poi_name = poi.convertnil(poi_name) -- convert possible NIL		
		poi.print(name, S("Unknown PoI <") .. poi_name .. ">.", red)
		return false

	end -- if poi.exist

	local exist = false
	local player = minetest.get_player_by_name(name)
	local currpos = player:getpos(name)
	local oldpos, cat = poi.split_pos_cat(poi.points[poi_name])
	
	poi.points[poi_name] = minetest.pos_to_string(currpos) .. "{" .. tonumber(cat) .. "}" -- Write the Position new
	poi.save() -- and write the List

	poi.print(name, name .. S(" has moved the POI: ") .. poi_name .. S(" at ") .. oldpos ..  S(" to Position: ") .. minetest.pos_to_string(currpos) .. "\n", log)
	poi.print(name, "POI: " .. poi_name .. S(" at ") .. oldpos .. S(" moved to Position: ") .. minetest.pos_to_string(currpos) .."\n", green)
	return true

end -- poi.move

-- Renames a POI
function poi.rename(name, poi_name)
	local oldname, newname

	if string.find(poi_name, ",") == nil then
		poi.print(name, S("/poi_rename: No new Name for Point given.") .. "\n", red)
		return false
	end

	oldname = poi.trim(string.sub(poi_name,1, string.find(poi_name, ",")-1))

	if not poi.exist(oldname) then
		poi.print(name, S("Point to rename not found.") .. "\n", red)
		return false
	end

	newname = poi.trim(string.sub(poi_name, string.find(poi_name, ",") + 1, -1))

	if not poi.check_name(newname) then
		poi.print(name, S("Invalid new Pointname.") .. "\n", red)
		return false
	end

	if poi.exist(newname) then
		poi.print(name, S("New Pointname already exists.") .. "\n", red)
		return false
	end

	local old_position
	old_position = poi.points[oldname] -- get the Positioni
	poi.points[newname] = old_position -- and make a new entry

	poi.points[oldname] = nil -- now deletes the old one
	poi.save()			-- saves the List
	
	poi.print(name, name .. S(" has renamed POI-Name: ") .. oldname .. S(" to: ") .. newname .. S(" - Position: ") .. old_position .. "\n", log)
	poi.print(name, S("PoI-Name: ") .. oldname .. S(" renamed to ") .. newname ..  S(" - Position: ") .. old_position .. "\n", green)

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
				if( (cat == nil) or (cat > poi.max_categories) or (cat <= 0) )then	-- Invalid Categorienumber found
					poi.points[key] = pos .. "{1}" -- Changes the Categorienumber to 1
					invalid_cat = invalid_cat + 1
					
				end -- if(cat ==)
				
			end -- if value
			
		end -- if check_name
		
	end -- for key,value
	
	if (count > 0) or (invalid_cat > 0) then
		poi.print(name, name .. " has deleted with validate " .. count .. " PoI's.\n", log)
		poi.print(name, name .. " has found " .. invalid_cat .. " Entries with an invalid Categorie.\n", log)
		poi.print(name, count .. S(" invalid PoI's found and deleted."), red)
		poi.print(name, invalid_cat .. S(" PoI's with an invalid Categorie found and set to 1."), red)
		poi.save()
		
	else
		poi.print(name, S("No invalid PoI found.") .. "\n", green)
		
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


-- builds the list of Categories for drop down menu in the gui
function poi.build_cat_list()
      for key, value in pairs(poi_categories) do      -- build the dropdown menu
	  
	  if catlist == "" then
	  
	   catlist = value
	   
	  else
	    
	    catlist = catlist .. "," .. value
	  
	  end
      end
end
      

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
		
		if(categorie == nil) then -- Categorie was not a Number, then check the name
			categorie = poi.trim(string.sub(poi_name,string.find(poi_name, ",")+1,-1))
			categorie = poi.get_categorienumber(categorie)	-- Find the Categorienumber
			if(categorie == nil) then	-- Puuhhh, unknown Categorie
				categorie = -1		-- ok, set it to 1
			
			end -- if(categorie == nil) -- unknown Name
		
		end -- if(categorie == nil)
		
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

-- Gets a Categorienumber by Name
function poi.get_categorienumber(name)

	local categorie = nil

	if(name == "" or name == nil) then
		return categorie
		
	end -- if(name)
		
	name = string.lower(name)
	
	for key, value in pairs(poi.categories) do
		if(string.lower(value) == name) then
			categorie = key
			break
			
		end -- if(string.lower)
		
	end -- for key,value
	
	return categorie

end -- poi.get_categorienumber()
		
	
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

function poi.play_soundeffect(name, soundname)

	if(soundname == nil or soundname == "") then
		soundname = "teleport"
	
	end -- if(soundname)

	minetest.sound_play("minetest_poi_" .. soundname, {
		to_player = name,
		loop = false,
	})
			
	--poi.print(name, name .. " has played the Sound: " .. poi.modpath .. "/sounds/minetest_poi_" .. soundname .. ".ogg.", log)
	
end -- poi.play_soundeffect()

function poi.convertnil(poi_name)

	if(poi_name == nil) then
		poi_name = " "
	
	end
	
	return poi_name

end -- poi.convertnil()

--[[
	********************************************
	***         Commands to Register             ***
	********************************************
--]]

minetest.register_chatcommand("poi_set", {
	params = S("<poi_name, Categorie[number]>"),
	description = S("Set's a Point of Interest or changes the Categorie of an existing Point."),
	privs = {poi = true},
	func = function(name, poi_name)

		poi.set(name, poi_name)

	end,
})

minetest.register_chatcommand("poi_gui", {
	params = "",
	description = S("Shows PoIs in a GUI."),
	privs = {interact = true},
	func = function(name)

      poi.gui(name,nil,true)

	end,
})
minetest.register_chatcommand("poi_list", {
	params = S("<-a> <-c> <-f> <-i [Categorie[Number]]>"),
	description = S("Shows Point's of Interest.\nOption -a shows Point's of Interest with Coordinates.\nOption -c shows you Categories.\nOption -f shows you the Namefilter\nOption -i <Categorie[number]> shows only the Entries of the given Categorienumber or Name"),
	privs = {interact = true},
	func = function(name, arg)

		poi.list(name, arg)

	end,
})

minetest.register_chatcommand("poi_delete", {
	params = S("<POI-Name>"),
	description = S("Deletes a Point of Interest."),
	privs = {poi = true},
	func = function(name, poi_name)

		poi.delete(name, poi_name)

	end,
})

minetest.register_chatcommand("poi_reload", {
	params = "",
	description = S("Loads the List of POI's new."),
	privs = {poi = true},
	func = function(name)

		poi.reload(name)

	end,
})


minetest.register_chatcommand("poi_jump", {
	params = S("<POI-Name>"),
	description = S("Jumps to the Position of the Point of Interest."),
	privs = {interact = true},
	func = function(name, poi_name)

		poi.jump(name, poi_name)

	end,
})

minetest.register_chatcommand("poi_move", {
	params = S("<POI-Name>"),
	description = S("Changes the Position of the Point of Interest."),
	privs = {poi = true},
	func = function(name, poi_name)

		poi.move(name, poi_name)

	end,
})

minetest.register_chatcommand("poi_rename", {
	params = S("<POI Old Name>,<POI New Name>"),
	description = S("Changes the Name of the Point of Interest."),
	privs = {poi = true},
	func = function(name, poi_name)

		poi.rename(name, poi_name)

	end,
})

minetest.register_chatcommand("poi_validate", {
	params = "",
	description = S("Validates the List of PoI's."),
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
		tooltip = S("Show Points of Interest"),
		hide_lite=true,
		action = function(player)
			local player_name = player:get_player_name()
			if not player_name then return end
			if minetest.check_player_privs(player_name, {interact=true}) then
			  poi.gui(player_name,nil,true)
			else
			  minetest.chat_send_player(player_name,core.colorize(red, S("You need the"))..core.colorize(green, S(" interact"))..core.colorize(red,S(" priv, please type"))..core.colorize(green,S(" /rules"))..core.colorize(red,S(" and search for the keyword")))
			end
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
poi.build_cat_list()

print("[MOD] " .. minetest.get_current_modname() .. " loaded.")
