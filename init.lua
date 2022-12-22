-- Public Inventory Plus Mod for Minetest
-- Created 2022 by activivan

local storage = minetest.get_mod_storage()
local S = minetest.get_translator(minetest.get_current_modname())
local conf = minetest.settings

local cols = tonumber(conf:get("pubinv_cols")) or 9
local rows = tonumber(conf:get("pubinv_rows")) or 3


-- ---------------------------
-- Detached inventory handling

local function save(inv_list)
	local data = {}

	for _, item in ipairs(inv_list) do
		table.insert(data, item:to_string())
	end

	storage:set_string("main", minetest.serialize(data))
end

local pi = minetest.create_detached_inventory("pi", {
	on_put = function(inv)
		save(inv:get_list("main"))
	end,
	on_take = function(inv)
		save(inv:get_list("main"))
	end,
})

pi:set_size("main", (cols * rows))

local function load()
	local data = storage:get("main")

	if data then
		local inv_list = minetest.deserialize(data)
		pi:set_list("main", inv_list)
	end
end

load()


-- ---------------------------
-- API

local pubinv = {} -- Remove "local" to make API globally accessible

pubinv.formspec = function(name)
	local inv_size = (minetest.get_inventory({ type="player", name=name })):get_size("main")
	local inv_rows = math.ceil(inv_size / cols)

	local size = "size["..cols..","..(rows + 1.25 + inv_rows)..";]"

	return (size..
			"label[0,0;"..S("Public inventory").."]"..
			"list[detached:pi;main;0,0.5;"..cols..","..rows..";]"..
			(mcl_formspec and mcl_formspec.get_itemslot_bg(0, 0.5, cols, rows) or "")..
			"label[0,"..(rows + 0.75)..";"..S("Your inventory").."]"..
			"list[current_player;main;0,"..(rows + 1.25)..";"..((inv_size > cols) and cols or inv_size)..","..((inv_size > cols) and inv_rows or 1)..";]"..
			(mcl_formspec and 
				mcl_formspec.get_itemslot_bg(0, (rows + 1.25), ((inv_size > cols) and cols or inv_size), ((inv_size > cols) and (inv_rows - 1) or 1))..
				((inv_size > cols) and mcl_formspec.get_itemslot_bg(0, (rows + inv_rows + 0.25), (inv_size - (cols * (inv_rows - 1))), 1) or "")
			or "")..
			"listring[]"), size
end

pubinv.open = function(name)
	minetest.show_formspec(name, "pubinv:pi", pubinv.formspec(name))
	return true, ""
end


-- ---------------------------
-- Integrations

minetest.register_chatcommand("pi", {
	params = "",
	description = S("Opens the public inventory"),
	func = function(name)
		pubinv.open(name)
	end,
})

if unified_inventory then
	unified_inventory.register_button("pubinv", {
		type = "image",
		image = "ui_icon_pubinv.png",
		tooltip = S("Public inventory"),
		hide_lite = false,
		action = function(player)
			pubinv.open(player:get_player_name())
		end
	})
end

if sfinv then
	sfinv.register_page("pubinv", {
		title = S("Public inventory"),
		get = function(self, player, context)
			local formspec, size = pubinv.formspec(player:get_player_name())
			return sfinv.make_formspec(player, context, formspec, false, size)
		end
	})
end
