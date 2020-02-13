
-- Wear out hoes, place soil
-- TODO Ignore group:flower
farming.registered_plants = {}

farming.hoe_on_use = function(itemstack, user, pointed_thing, uses)
	local pt = pointed_thing
	-- check if pointing at a node
	if not pt then
		return
	end
	if pt.type ~= "node" then
		return
	end

	local under = minetest.get_node(pt.under)
	local p = {x=pt.under.x, y=pt.under.y+1, z=pt.under.z}
	local above = minetest.get_node(p)

	-- return if any of the nodes is not registered
	if not minetest.registered_nodes[under.name] then
		return
	end
	if not minetest.registered_nodes[above.name] then
		return
	end

	-- check if the node above the pointed thing is air
	if above.name ~= "air" then
		return
	end

	-- check if pointing at soil
	if minetest.get_item_group(under.name, "soil") ~= 1 then
		return
	end

	-- check if (wet) soil defined
	local regN = minetest.registered_nodes
	if regN[under.name].soil == nil or regN[under.name].soil.wet == nil or regN[under.name].soil.dry == nil then
		return
	end

	if minetest.is_protected(pt.under, user:get_player_name()) then
		minetest.record_protection_violation(pt.under, user:get_player_name())
		return
	end
	if minetest.is_protected(pt.above, user:get_player_name()) then
		minetest.record_protection_violation(pt.above, user:get_player_name())
		return
	end

	-- turn the node into soil and play sound
	minetest.set_node(pt.under, {name = regN[under.name].soil.dry})
	minetest.sound_play("default_dig_crumbly", {
		pos = pt.under,
		gain = 0.5,
	})

	if not (creative and creative.is_enabled_for
			and creative.is_enabled_for(user:get_player_name())) then
		-- wear tool
		local wdef = itemstack:get_definition()
		itemstack:add_wear(65535/(uses-1))
		-- tool break sound
		if itemstack:get_count() == 0 and wdef.sound and wdef.sound.breaks then
			minetest.sound_play(wdef.sound.breaks, {pos = pt.above, gain = 0.5})
		end
	end
	return itemstack
end

function farming.plant_from_node_name(name)
   local plantname
   if string.find(name, "seed") then
      -- farming:seed_<name>
      plantname = name:split("_")[2]
   else
      -- farming:<name>_<stage>
      local modname_plantname = name:split("_")[1]
      plantname = modname_plantname:split(":")[2]
   end
   return farming.registered_plants[plantname]
end

local function growth_timescale(time)
   local divisor = 1
   local unit = "seconds"
   local over_three_months = false
   if time > (60 * 60 * 24 * 7 * 4 * 3) then
      over_three_months = true
      divisor = (60 * 60 * 24 * 7 * 4)
      unit =  "months"
   elseif time > (60 * 60 * 24 * 7) then
      divisor = (60 * 60 * 24 * 7)
      unit = "weeks"
   elseif time > (60 * 60 * 24) then
      divisor = (60 * 60 * 24)
      unit = "days"
   elseif time > (60 * 60) then
      divisor = (60 * 60)
      unit = "hours"
   elseif time > 60 then
      divisor = 60
      unit = "minutes"
   end
   return divisor, unit, over_three_months
end

farming.hoe_on_place = function(itemstack, user, pointed_thing)
   if pointed_thing
      and pointed_thing.type == "node"
   then
      local pos = pointed_thing.under
      local node = minetest.get_node(pos)

      local plant = farming.plant_from_node_name(node.name)

      if (not plant) or (not plant.custom_growth) then
         return
      end

      -- TODO: this is duplicated code from set_timer
      local growth = plant.custom_growth
      local grow_time = -1

      local biome = minetest.get_biome_data(pos)
      local heat_difference = math.abs(biome.heat-growth.optimum_heat)

      if growth.heat_scaling == "linear" then
         grow_time = (growth.heat_a*heat_difference) + growth.heat_base_speed
      elseif growth.heat_scaling == "exponential" then
         grow_time = (growth.heat_a*growth.heat_b^heat_difference)+growth.heat_base_speed
      end

      local lower_bound = grow_time - growth.variance
      local higher_bound = grow_time + growth.variance

      -- The above are per-stage, so multiple
      local full_lower_bound = lower_bound * (plant.steps - 1)
      local full_higher_bound = higher_bound * (plant.steps - 1)

      local flb_divisor, flb_unit, flb_over_three_months = growth_timescale(full_lower_bound)
      local fhb_divisor, fhb_unit, fhb_over_three_months = growth_timescale(full_higher_bound)

      if flb_over_three_months and fhb_over_three_months then
         minetest.chat_send_player(
            user:get_player_name(),
            "A " .. plant.description .. " will take over three months to fully grow here."
         )
      else
         local pretty_full_lower_bound = string.format("%.2f", full_lower_bound / flb_divisor)
         if flb_over_three_months then
            pretty_full_lower_bound = "3+"
         end

         local pretty_full_higher_bound = string.format("%.2f", full_higher_bound / fhb_divisor)
         if fhb_over_three_months then
            pretty_full_higher_bound = "3+"
         end

         minetest.chat_send_player(
            user:get_player_name(),
            "A " .. plant.description .. " will take from " .. pretty_full_lower_bound
               .. " " .. flb_unit .. " to " .. pretty_full_higher_bound .. " "
               .. fhb_unit .. " to fully grow here."
         )
      end
   end
   return itemstack
end

farming.hoe_on_secondary_use = function(itemstack,user,pointed_thing)
   local name = user:get_player_name()
   if not name then
      return
   end
   local pos = user:get_pos()
   local biome = minetest.get_biome_data(pos)

   minetest.chat_send_player(
      name,
      "The heat of this area is " .. minetest.get_heat(pos)
         .. " and the humidity is " .. minetest.get_humidity(pos)
   )
end

-- Register new hoes
farming.register_hoe = function(name, def)
	-- Check for : prefix (register new hoes in your mod's namespace)
	if name:sub(1,1) ~= ":" then
		name = ":" .. name
	end
	-- Check def table
	if def.description == nil then
		def.description = "Hoe"
	end
	if def.inventory_image == nil then
		def.inventory_image = "unknown_item.png"
	end
	if def.max_uses == nil then
		def.max_uses = 30
	end
	-- Register the tool
	minetest.register_tool(name, {
		description = def.description,
		inventory_image = def.inventory_image,
		on_use = function(itemstack, user, pointed_thing)
			return farming.hoe_on_use(itemstack, user, pointed_thing, def.max_uses)
		end,
                on_place = function(itemstack, user, pointed_thing)
                      return farming.hoe_on_place(itemstack, user, pointed_thing)
                end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			return farming.hoe_on_secondary_use(itemstack,user,pointed_thing)
		end,
		groups = def.groups,
		sound = {breaks = "default_tool_breaks"},
	})
	-- Register its recipe
	if def.recipe then
		minetest.register_craft({
			output = name:sub(2),
			recipe = def.recipe
		})
	elseif def.material then
		minetest.register_craft({
			output = name:sub(2),
			recipe = {
				{def.material, def.material},
				{"", "group:stick"},
				{"", "group:stick"}
			}
		})
	end
end

local function set_timer(pos,again)
	local node = minetest.get_node(pos)
	local name = node.name
	local growth = minetest.registered_nodes[name].custom_growth

	--default values
	local lower_bound = 166
	local higher_bound = 286
	if again == true then
		lower_bound = 40
		higher_bound = 80
	end

	if growth then
		local biome = minetest.get_biome_data(pos)
		local grow_time = -1 --Initial value

		if growth.heat_scaling then
			local heat_difference = math.abs(biome.heat-growth.optimum_heat)
			if growth.heat_scaling == "linear" then
				grow_time = growth.heat_a*heat_difference + growth.heat_base_speed
			elseif growth.heat_scaling == "exponential" then
				grow_time = (growth.heat_a*growth.heat_b^heat_difference)+growth.heat_base_speed
			end
		end

		if growth.humidity_scaling then
			local humidity_difference = math.abs(biome.humidity-growth.optimum_humidity)
			if growth.humidity_scaling == "linear" then
				grow_time = grow_time + growth.humidity_a*humidity_difference + growth.humidity_base_speed
			elseif growth.humidity_scaling == "exponential" then
				grow_time = grow_time + growth.humidity_a*growth.humidity_b^humidity_difference+growth.humidity_base_speed
			end
		end

		if grow_time == -1  then grow_time = 200 end --If the grow time wasen't changed we change it to a default value

		lower_bound = grow_time - growth.variance
		higher_bound = grow_time + growth.variance

		if again == true then
			lower_bound = lower_bound / 4
			higher_bound = higher_bound / 4
		end
	end
	--minetest.log("Lower bound:" .. lower_bound .. " upper:" .. higher_bound)
	minetest.get_node_timer(pos):start(math.random(lower_bound, higher_bound))
end

-- how often node timers for plants will tick, +/- some random value
local function tick(pos)
	set_timer(pos,false)
end
-- how often a growth failure tick is retried (e.g. too dark)
local function tick_again(pos)
	set_timer(pos,true)
end

-- Seed placement
farming.place_seed = function(itemstack, placer, pointed_thing, plantname)
	local pt = pointed_thing
	-- check if pointing at a node
	if not pt then
		return itemstack
	end
	if pt.type ~= "node" then
		return itemstack
	end

	local under = minetest.get_node(pt.under)
	local above = minetest.get_node(pt.above)

	local player_name = placer and placer:get_player_name() or ""

	if minetest.is_protected(pt.under, player_name) then
		minetest.record_protection_violation(pt.under, player_name)
		return
	end
	if minetest.is_protected(pt.above, player_name) then
		minetest.record_protection_violation(pt.above, player_name)
		return
	end

	-- return if any of the nodes is not registered
	if not minetest.registered_nodes[under.name] then
		return itemstack
	end
	if not minetest.registered_nodes[above.name] then
		return itemstack
	end

	-- check if pointing at the top of the node
	if pt.above.y ~= pt.under.y+1 then
		return itemstack
	end

	-- check if you can replace the node above the pointed node
	if not minetest.registered_nodes[above.name].buildable_to then
		return itemstack
	end

	-- check if pointing at soil
	if minetest.get_item_group(under.name, "soil") < 2 then
		return itemstack
	end

	-- add the node and remove 1 item from the itemstack
	minetest.add_node(pt.above, {name = plantname, param2 = 1})
	tick(pt.above)
	if not (creative and creative.is_enabled_for
			and creative.is_enabled_for(player_name)) then
		itemstack:take_item()
	end
	return itemstack
end

farming.grow_plant = function(pos, elapsed)
	local node = minetest.get_node(pos)
	local name = node.name
	local def = minetest.registered_nodes[name]

	if not def.next_plant then
		-- disable timer for fully grown plant
		return
	end

	-- grow seed
	if minetest.get_item_group(node.name, "seed") and def.fertility then
		local soil_node = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
		if not soil_node then
			tick_again(pos)
			return
		end
		-- omitted is a check for light, we assume seeds can germinate in the dark.
		for _, v in pairs(def.fertility) do
			if minetest.get_item_group(soil_node.name, v) ~= 0 then
				local placenode = {name = def.next_plant}
				if def.place_param2 then
					placenode.param2 = def.place_param2
				end
				minetest.swap_node(pos, placenode)
				if minetest.registered_nodes[def.next_plant].next_plant then
					tick(pos)
					return
				end
			end
		end

		return
	end

	-- check if on wet soil
	local below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
	if minetest.get_item_group(below.name, "soil") < 3 then
		tick_again(pos)
		return
	end

	-- check light
	local light = minetest.get_node_light(pos)
	if not light or light < def.minlight or light > def.maxlight then
		tick_again(pos)
		return
	end

	-- grow
	local placenode = {name = def.next_plant}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
	minetest.swap_node(pos, placenode)

	-- new timer needed?
	if minetest.registered_nodes[def.next_plant].next_plant then
		tick(pos)
	end
	return
end

-- Register plants
farming.register_plant = function(name, def)
	local mname = name:split(":")[1]
	local pname = name:split(":")[2]

	-- Check def table
	if not def.description then
		def.description = "Seed"
	end
	if not def.inventory_image then
		def.inventory_image = "unknown_item.png"
	end
	if not def.steps then
		return nil
	end
	if not def.minlight then
		def.minlight = 1
	end
	if not def.maxlight then
		def.maxlight = 14
	end
	if not def.fertility then
		def.fertility = {}
	end

	farming.registered_plants[pname] = def

	-- Register seed
	local lbm_nodes = {mname .. ":seed_" .. pname}
	local g = {seed = 1, snappy = 3, attached_node = 1, flammable = 2}
	for k, v in pairs(def.fertility) do
		g[v] = 1
	end
	minetest.register_node(":" .. mname .. ":seed_" .. pname, {
		description = def.description,
		tiles = {def.inventory_image},
		inventory_image = def.inventory_image,
		wield_image = def.inventory_image,
		drawtype = "signlike",
		groups = g,
		paramtype = "light",
		paramtype2 = "wallmounted",
		place_param2 = def.place_param2 or nil, -- this isn't actually used for placement
		walkable = false,
		sunlight_propagates = true,
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
		fertility = def.fertility,
		sounds = default.node_sound_dirt_defaults({
			dig = {name = "", gain = 0},
			dug = {name = "default_grass_footstep", gain = 0.2},
			place = {name = "default_place_node", gain = 0.25},
		}),

		on_place = function(itemstack, placer, pointed_thing)
			local under = pointed_thing.under
			local node = minetest.get_node(under)
			local udef = minetest.registered_nodes[node.name]
			if udef and udef.on_rightclick and
					not (placer and placer:is_player() and
					placer:get_player_control().sneak) then
				return udef.on_rightclick(under, node, placer, itemstack,
					pointed_thing) or itemstack
			end

			return farming.place_seed(itemstack, placer, pointed_thing, mname .. ":seed_" .. pname)
		end,
		next_plant = mname .. ":" .. pname .. "_1",
		on_timer = farming.grow_plant,
		minlight = def.minlight,
		maxlight = def.maxlight,
		custom_growth = def.custom_growth,
	})

	-- Register harvest
	minetest.register_craftitem(":" .. mname .. ":" .. pname, {
		description = pname:gsub("^%l", string.upper),
		inventory_image = mname .. "_" .. pname .. ".png",
		groups = def.groups or {flammable = 2},
	})

	-- Register growing steps
	for i = 1, def.steps do
		local base_rarity = 1
		if def.steps ~= 1 then
			base_rarity =  8 - (i - 1) * 7 / (def.steps - 1)
		end
		local drop = {
			items = {
				{items = {mname .. ":" .. pname}, rarity = base_rarity},
				{items = {mname .. ":" .. pname}, rarity = base_rarity * 2},
				{items = {mname .. ":seed_" .. pname}, rarity = base_rarity},
				{items = {mname .. ":seed_" .. pname}, rarity = base_rarity * 2},
			}
		}
		local nodegroups = {snappy = 3, flammable = 2, plant = 1, not_in_creative_inventory = 1, attached_node = 1}
		nodegroups[pname] = i

		local next_plant = nil

		if i < def.steps then
			next_plant = mname .. ":" .. pname .. "_" .. (i + 1)
			lbm_nodes[#lbm_nodes + 1] = mname .. ":" .. pname .. "_" .. i
		end

		minetest.register_node(":" .. mname .. ":" .. pname .. "_" .. i, {
			drawtype = "plantlike",
			waving = 1,
			tiles = {mname .. "_" .. pname .. "_" .. i .. ".png"},
			paramtype = "light",
			paramtype2 = def.paramtype2 or nil,
			place_param2 = def.place_param2 or nil,
			walkable = false,
			buildable_to = true,
			drop = drop,
			selection_box = {
				type = "fixed",
				fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
			},
			groups = nodegroups,
			sounds = default.node_sound_leaves_defaults(),
			next_plant = next_plant,
			on_timer = farming.grow_plant,
			minlight = def.minlight,
			maxlight = def.maxlight,
			custom_growth = def.custom_growth,
		})
	end

	-- replacement LBM for pre-nodetimer plants
	minetest.register_lbm({
		name = ":" .. mname .. ":start_nodetimer_" .. pname,
		nodenames = lbm_nodes,
		action = function(pos, node)
			tick_again(pos)
		end,
	})

	-- Return
	local r = {
		seed = mname .. ":seed_" .. pname,
		harvest = mname .. ":" .. pname
	}
	return r
end
