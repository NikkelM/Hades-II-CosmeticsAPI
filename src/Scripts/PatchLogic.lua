local function normalizeCosmeticEquipState()
	local worldUpgrades = game.GameState and game.GameState.WorldUpgrades
	if worldUpgrades == nil or game.ScreenData == nil or game.ScreenData.CosmeticsShop == nil then
		return
	end

	local worldUpgradesAdded = game.GameState.WorldUpgradesAdded or {}

	-- For each cosmetic group, ensure exactly one owned item is equipped
	-- Fixes two potential issues:
	-- 1. No cosmetic equipped (a mod that added the equipped cosmetic is no longer loaded) -> re-equip first *owned* cosmetic
	-- 2. Multiple cosmetics equipped (played vanilla and equipped a different cosmetic, then re-enabled the mod) -> keep first encountered, unequip rest
	for _, category in ipairs(game.ScreenData.CosmeticsShop.ItemCategories) do
		for _, name in ipairs(category) do
			local cosmeticData = game.WorldUpgradeData[name]
			if cosmeticData == nil or cosmeticData.RemoveCosmetics == nil then
				goto continue
			end

			-- Check if this cosmetic or any sibling is equipped
			local anyEquipped = worldUpgrades[name]
			if not anyEquipped then
				for _, siblingName in ipairs(cosmeticData.RemoveCosmetics) do
					if worldUpgrades[siblingName] then
						anyEquipped = true
						break
					end
				end
			end

			if not anyEquipped and worldUpgradesAdded[name] then
				-- No cosmetic in this group is equipped, but this one is owned - re-equip it
				worldUpgrades[name] = true
				mod.DebugPrint("[CosmeticsAPI] No cosmetic equipped in group containing '" ..
					name .. "', re-equipping owned cosmetic '" .. name .. "'.", 2)
			elseif worldUpgrades[name] then
				-- This one is equipped - unequip all siblings to ensure only one is active
				for _, toRemove in ipairs(cosmeticData.RemoveCosmetics) do
					if worldUpgrades[toRemove] ~= nil then
						mod.DebugPrint("[CosmeticsAPI] Unequipping cosmetic '" .. toRemove ..
							"' because it is in the same group as another currently equipped cosmetic '" .. name ..
							"'. This can happen if you play vanilla and equip a cosmetic in a group you previously had a modded cosmetic equipped in. You might need to re-equip the proper cosmetic.",
							2)
					end
					worldUpgrades[toRemove] = nil
				end
			end

			::continue::
		end
	end
end

-- This must be the same as the wrap for HubPostBountyLoad and HubPostDreamLoad
modutil.mod.Path.Wrap("DeathAreaRoomTransition", function(base, source, args)
	normalizeCosmeticEquipState()

	return base(source, args)
end)

-- If returning from a Chaos Trial, this will be called instead of DeathAreaRoomTransition
modutil.mod.Path.Wrap("HubPostBountyLoad", function(base, source, args)
	normalizeCosmeticEquipState()

	return base(source, args)
end)

-- If returning from a Dream Dive, this will be called instead of DeathAreaRoomTransition
modutil.mod.Path.Wrap("HubPostDreamLoad", function(base, source, args)
	normalizeCosmeticEquipState()

	return base(source, args)
end)
