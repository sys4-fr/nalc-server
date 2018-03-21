nalc = {}

-- Remove node from a group
local function remove_group(name, group)
	local node = minetest.registered_nodes[name]
	
	if node then
		local groups = node.groups
		if groups then
			for g in pairs(groups) do
				if g == group then
					groups[g] = 0
					minetest.log("action", "[nalc_lib] "..name.." removed from group "..group..".")
				end
			end
			minetest.override_item(name, {groups = groups})
		else
			minetest.log("warning", "[nalc_lib] "..name.." has no groups, could not remove group "..group..".")
		end
	else
		minetest.log("warning", "[nalc_lib] "..name.." not registered, could not remove group "..group..".")
	end
end

-- Remove node from group "oddly_breakable_by_hand"
function nalc.not_hand_breakable(name)
	remove_group(name, "oddly_breakable_by_hand")
end
