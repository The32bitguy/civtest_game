-- Global farming namespace

farming = {}
farming.path = minetest.get_modpath("farming")

farming.mod = "civfarm"

-- Load files

dofile(farming.path .. "/api.lua")
dofile(farming.path .. "/nodes.lua")
dofile(farming.path .. "/hoes.lua")


-- WHEAT

farming.register_plant("farming:wheat", {
	description = "Wheat Seed",
	paramtype2 = "meshoptions",
	inventory_image = "farming_wheat_seed.png",
	steps = 8,
	minlight = 13,
	maxlight = default.LIGHT_MAX,
	fertility = {"grassland", "desert"},
	groups = {food_wheat = 1, flammable = 4},
	place_param2 = 3,
	custom_growth = {optimum_heat = 50, heat_scaling = "exponential", heat_a = 2.5, heat_b = 1.7, heat_base_speed = 5000, variance = 1250},
})

minetest.register_craftitem("farming:flour", {
	description = "Flour",
	inventory_image = "farming_flour.png",
	groups = {food_flour = 1, flammable = 1},
})

minetest.register_craftitem("farming:bread", {
	description = "Bread",
	inventory_image = "farming_bread.png",
	on_use = minetest.item_eat(5),
	groups = {food_bread = 1, flammable = 2},
})

minetest.register_craft({
	type = "shapeless",
	output = "farming:flour",
	recipe = {"farming:wheat", "farming:wheat", "farming:wheat", "farming:wheat"}
})

minetest.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "farming:bread",
	recipe = "farming:flour"
})


-- Cotton

farming.register_plant("farming:cotton", {
	description = "Cotton Seed",
	inventory_image = "farming_cotton_seed.png",
	steps = 8,
	minlight = 13,
	maxlight = default.LIGHT_MAX,
	fertility = {"grassland", "desert"},
	groups = {flammable = 4},
	custom_growth = {optimum_heat = 75, heat_scaling = "exponential", heat_a = 10, heat_b = 1.2, heat_base_speed = 2500, variance = 500},
})

minetest.register_craftitem("farming:string", {
	description = "String",
	inventory_image = "farming_string.png",
	groups = {flammable = 2},
})

minetest.register_craft({
	output = "wool:white",
	recipe = {
		{"farming:cotton", "farming:cotton"},
		{"farming:cotton", "farming:cotton"},
	}
})

minetest.register_craft({
	output = "farming:string 2",
	recipe = {
		{"farming:cotton"},
		{"farming:cotton"},
	}
})


-- Straw

minetest.register_craft({
	output = "farming:straw 3",
	recipe = {
		{"farming:wheat", "farming:wheat", "farming:wheat"},
		{"farming:wheat", "farming:wheat", "farming:wheat"},
		{"farming:wheat", "farming:wheat", "farming:wheat"},
	}
})

minetest.register_craft({
	output = "farming:wheat 3",
	recipe = {
		{"farming:straw"},
	}
})


-- Fuels

minetest.register_craft({
	type = "fuel",
	recipe = "farming:straw",
	burntime = 3,
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:wheat",
	burntime = 1,
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:cotton",
	burntime = 1,
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:string",
	burntime = 1,
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:hoe_wood",
	burntime = 5,
})

-- Potato

farming.register_plant("farming:potato", {
	description = "Potato Seed",
	paramtype2 = "meshoptions",
	inventory_image = "farming_potato_seed.png",
	steps = 4,
	minlight = 13,
	maxlight = default.LIGHT_MAX,
	fertility = {"grassland","desert"},
	groups = {food_potato = 1, flammable = 4},
	place_param2 = 3,
	custom_growth = {optimum_heat = 40, heat_scaling = "exponential", heat_a = 2.5, heat_b = 1.7, heat_base_speed = 10000, variance = 2500},
})

minetest.register_craftitem("farming:potato", {
	description = "Potato",
	inventory_image = "farming_potato.png",
	on_use = minetest.item_eat(5),
	groups = {food_potato = 1, flammable = 2},
})


minetest.register_craftitem("farming:baked_potato", {
	description = "Baked Potato",
	inventory_image = "farming_baked_potato.png",
	on_use = minetest.item_eat(5),
	groups = {food_potato = 1, flammable = 2},
})


minetest.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "farming:baked_potato",
	recipe = "farming:potato"
})
