dofile(minetest.get_modpath("sfinv") .. "/api.lua")

sfinv.register_page("sfinv:crafting", {
	title = "Main",
	get = function(self, player, context)
		return sfinv.make_formspec(player, context, [[
				list[current_player;craft;1.75,0.5;3,3;]
				list[current_player;craftpreview;5.75,1.5;1,1;]
				image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]
				image[0,7.85;1,1;gui_hb_bg.png]
				image[1,7.85;1,1;gui_hb_bg.png]
				image[2,7.85;1,1;gui_hb_bg.png]
				image[3,7.85;1,1;gui_hb_bg.png]
				image[4,7.85;1,1;gui_hb_bg.png]
				image[5,7.85;1,1;gui_hb_bg.png]
				image[6,7.85;1,1;gui_hb_bg.png]
				image[7,7.85;1,1;gui_hb_bg.png]
				listring[current_player;main]
				listring[current_player;main2]
			]], true)
	end
})
