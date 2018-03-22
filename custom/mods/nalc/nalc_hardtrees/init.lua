--[[ Auteur : sys4

	Ce mod permet de :
	- Ne plus casser les arbres à la main
	- Supprimer haches et pioches en bois.
	- Fabriquer les outils en pierre avec du silex trouvé dans le gravier

	Remarque : Les sticks sont obtenables grâce au mod youngtrees de plantlife_modpack
]]

-- Suppression des haches et pioches en bois
minetest.unregister_item("default:axe_wood")
minetest.unregister_item("default:pick_wood")

-- Suppression du groupe oddly_breakable_by_hand pour les nodes en bois
local wood_nodes = {}
wood_nodes["default"] = {
	"tree", "pine_tree", "jungletree", "acacia_tree", "aspen_tree",
	"bush_stem", "acacia_bush_stem",
	"wood", "pine_wood", "junglewood", "acacia_wood", "aspen_wood",
}

if minetest.get_modpath("cherry_tree") then
	wood_nodes["cherry_tree"] = {"cherry_tree", "cherry_plank"}
end

if minetest.get_modpath("moretrees") and moretrees then
	wood_nodes["moretrees"] = {}
	local treelist = moretrees.treelist
	local j = 1
	for i in ipairs(treelist) do
		if treelist[i][1] ~= "poplar_small" then
			wood_nodes["moretrees"][j] = treelist[i][1].."_trunk"
			wood_nodes["moretrees"][j+1] = treelist[i][1].."_planks"
			j = j+2
		end
	end
	-- rubber_tree_trunk_empty
	wood_nodes["moretrees"][#wood_nodes["moretrees"]+1] = "rubber_tree_trunk_empty"
end

for mod, nodes in pairs(wood_nodes) do
	for _,name in ipairs(nodes) do
		nalc.not_hand_breakable(mod..":"..name)
	end
end

-- Recette de craft pour pioche et hache avec du silex
minetest.register_craft({
	output = "default:axe_stone",
	recipe = {
		{"default:flint", "default:flint", ""},
		{"default:flint", "default:stick", ""},
		{"", "default:stick", ""},
	}
})

minetest.register_craft({
	output = "default:pick_stone",
	recipe = {
		{"default:flint", "default:flint", "default:flint"},
		{"", "default:stick", ""},
		{"", "default:stick", ""},
	}
})
