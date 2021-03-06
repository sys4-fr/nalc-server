--[[level1 = 100
level1_drop = "default:steelblock 10"
]]

local xp_table = {}
xp_table["default"] = {
	"stone_with_coal 1", "stone_with_iron 1", "stone_with_copper 1", "stone_with_tin 1",
	"stone_with_mese 2", "stone_with_gold 2", "stone_with_diamond 3"
}

if minetest.get_modpath("moreores") then
	xp_table["moreores"] = {
		"mineral_silver 2", "mineral_mithril 4"
	}
end

if minetest.get_modpath("technic") then
	xp_table["technic"] = {
		"mineral_uranium 3", "mineral_chromium 2", "mineral_zinc 1"
	}
end

for mod, data in pairs(xp_table) do
	for _, xp in ipairs(data) do
		local tab = string.split(xp, " ")
		nalc.def_xp(mod..":"..tab[1], tonumber(tab[2]))
	end
end

local players = {}

MAX_HUD_EXPERIENCE = 40

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = {
		
		experiencebar = 0,
		experiencetotal = 0,
		textnumber = 0,
		exphudnumber = 0,
		hud = player:hud_add({
			hud_elem_type = "statbar",
			position = {x=0.5,y=1},
			size = {x=20, y=5},
			text = "orb_hud.png",
			number = 40,
			alignment = {x=0,y=1},
			offset = {x=-200, y=-65},
		      }
		),
		
	
		hud2 = player:hud_add({
		    hud_elem_type = "text",
                    name = "player_hud:time",
                    position = {x=0.5,y=1},
                    text = "",
                    scale = {x=2,y=2},
                    alignment = {x=0,y=1},
                    number = 0xFF0000, --0xFFFFFF,
		    offset = {x=-240 , y=-65},
			}
		),
	}
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)


--add an experience orb if player digs node from xp group
minetest.register_on_dignode(function(pos, oldnode, digger)
	local namer = oldnode.name
	local see_if_mineral = minetest.get_item_group(namer, "xp")
	if see_if_mineral == 1 then
		minetest.env:add_entity(pos, "experience:orb")
	end
	if see_if_mineral == 2 then
		minetest.env:add_entity(pos, "experience:orb")
		minetest.env:add_entity(pos, "experience:orb")
	end
	if see_if_mineral == 3 then
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	end
	if see_if_mineral == 4 then
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	end
	if see_if_mineral == 6 then
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	end
	if see_if_mineral == 8 then
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	minetest.env:add_entity(pos, "experience:orb")
	end
end)
--give a new player some xp
minetest.register_on_newplayer(function(player)
	local file = io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "w")
	file:write("0")
	file:close()
end)
--set player's xp level to 0 if they die
minetest.register_on_dieplayer(function(player)
	local file = io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "w")
	file:write("0")
	file:close()
end)

--Allow people to collect orbs
minetest.register_globalstep(function(dtime)


local gameTime = minetest.get_gametime()


	for _,player in ipairs(minetest.get_connected_players()) do
		local pos = player:getpos()
		pos.y = pos.y+0.5
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "experience:orb" then
				--RIGHT HERE ADD IN THE CODE TO UPGRADE PLAYERS 
				object:setvelocity({x=0,y=0,z=0})
				object:get_luaentity().name = "STOP"
				minetest.sound_play("orb", {
					to_player = player:get_player_name(),
				})
				
				if io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "r") == nil then
				local file = io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "w")
				file:write("1")
				local experience = 1
				file:close()
				else  
				  
				local xp = io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "r")
				local experience = xp:read("*l")
				xp:close()
				
				if experience ~= nil then
					local new_xp = experience + 1
					local xp_write = io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "w")
					xp_write:write(new_xp)
					xp_write:close()
					--[[if new_xp == level1 then
						minetest.env:add_item(pos, level1_drop)
						minetest.sound_play("level_up", {
							to_player = player:get_player_name(),
						})
					end
					]]
				end
				
				end
				
				object:remove()
			end
		end
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 3)) do
			if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "experience:orb" then
				if object:get_luaentity().collect then
					local pos1 = pos
					pos1.y = pos1.y+0.2
					local pos2 = object:getpos()
					local vec = {x=pos1.x-pos2.x, y=pos1.y-pos2.y, z=pos1.z-pos2.z}
					vec.x = vec.x*3
					vec.y = vec.y*3
					vec.z = vec.z*3
					object:setvelocity(vec)
				end
			end
		end
		
				--Loop through all connected players
		for playerName,playerInfo in pairs(players) do
			local player = minetest.get_player_by_name(playerName)
			if player ~= nil then
			  
			  
				if playerInfo["textnumber"] == nil or playerInfo["textnumber"] <= 0 then
				    playerInfo["textnumber"] = 0
				    player:hud_change(playerInfo["hud2"], "text", playerInfo["textnumber"])
				end
				
				if playerInfo["experiencetotal"] == nil then
				  playerInfo["experiencetotal"] = 0
				  player:hud_change(playerInfo["hud2"], "text", playerInfo["textnumber"])
				end
				
				if playerInfo["experiencetotal"] == 0 then
				  playerInfo["textnumber"] = 0
				  player:hud_change(playerInfo["hud2"], "text", playerInfo["textnumber"])
				end
				
		--[[
		local xptemp = io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "r")
		if xptemp ~= nil then
		local xptemp2 = xptemp:read("*l")
		end
		if xptemp2 == nil then
		      local file = io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "w")	
		      file:write("0")
		      playerInfo["experiencetotal"] = 0
		      playerInfo["textnumber"] = 0
		      file:close()
		end
		]]

		local xptemp = io.open(minetest.get_worldpath().."/"..player:get_player_name().."_experience", "r")
		if xptemp ~= nil then
		local xptemp2 = xptemp:read("*l")
		      if xptemp2 ~= nil then
			    playerInfo["experiencetotal"] = xptemp2
		      end
		end
		if xptemp ~= nil then
		xptemp:close()
		end


				if (playerInfo["experiencetotal"]) ~= nil then
					playerInfo["experiencebar"] = (playerInfo["experiencetotal"] - ((playerInfo["textnumber"]) * 40))
				end

				
				--Update the players's hud xp bar
				local numBars = (playerInfo["experiencebar"]/MAX_HUD_EXPERIENCE)*40
				player:hud_change(playerInfo["hud"], "number", numBars)
				
				    while playerInfo["experiencebar"] >= MAX_HUD_EXPERIENCE do
					  playerInfo["textnumber"]= playerInfo["textnumber"] + 1
					  player:hud_change(playerInfo["hud2"], "text", playerInfo["textnumber"])
					  playerInfo["experiencebar"] = ((playerInfo["experiencetotal"]) - ((playerInfo["textnumber"]) * 40))
					  local numBars = (playerInfo["experiencebar"]/MAX_HUD_EXPERIENCE)*40
					  player:hud_change(playerInfo["hud"], "number", numBars)
				    end
				
				if playerInfo["experiencebar"] == 0 then
				      playerInfo["textnumber"] = 0
				      player:hud_change(playerInfo["hud2"], "text", playerInfo["textnumber"])
				end

				
			end
		end
		
	end
end)

minetest.register_entity("experience:orb", {
	physical = true,
	timer = 0,
	textures = {"orb.png"},
	visual_size = {x=0.15, y=0.15},
	collisionbox = {-0.17,-0.17,-0.17,0.17,0.17,0.17},
	on_activate = function(self, staticdata)
		self.object:set_armor_groups({immortal=1})
		self.object:setvelocity({x=0, y=1, z=0})
		self.object:setacceleration({x=0, y=-10, z=0})
	end,
	collect = true,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if (self.timer > 300) then
			self.object:remove()
		end
		local p = self.object:getpos()
		local nn = minetest.env:get_node(p).name
		local noder = minetest.env:get_node(p).name
		p.y = p.y - 0.3
		local nn = minetest.env:get_node(p).name
		if not minetest.registered_nodes[nn] or minetest.registered_nodes[nn].walkable then
			if self.physical_state then
				self.object:setvelocity({x=0, y=0, z=0})
				self.object:setacceleration({x=0, y=0, z=0})
				self.physical_state = false
				self.object:set_properties({
					physical = false
				})
			end
		else
			if not self.physical_state then
				self.object:setvelocity({x=0,y=0,z=0})
				self.object:setacceleration({x=0, y=-10, z=0})
				self.physical_state = true
				self.object:set_properties({
					physical = true
				})
			end
		end
	end,
})
