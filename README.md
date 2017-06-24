# Points of Interest

A Mod for Minetest.

This Mod adds PoI's, Point's of Interest to your World.
If you have set a PoI, you can everytime jump back to the PoI with a simple Chatcommand.

With the Chatcommand /poi_list, you can see everytime a List of all Points of Interest.
With /poi_list -a you can see it additional with the Coordinates in the World.

To Jump now to the PoI's, use the command /poi_jump <Name>.

If you have the Privs, you can organize Point of Interest with the command /poi_set <Name>
and /poi_delete <Name>.
Or you can reload the whole List with the command /poi_reload. 

As Admin, you can grant Privs for the Player.
All the Points will be stored at a File in your World-Directory with the name: poi.txt

## Privileges

interact:<br>
/poi_jump [name]<br>
/poi_list [-a]<br>

poi:<br>
/poi_set [name]<br>
/poi_delete [name]<br>
/poi_reload<br>


## Install

You have to rename the folder from "minetest_poi/" to "poi/".

## Depends

none

## License

License: WTFPL
