local function normalizeCosmeticEquipState()
	local worldUpgrades = game.GameState and game.GameState.WorldUpgrades
	if worldUpgrades == nil or game.ScreenData == nil or game.ScreenData.CosmeticsShop == nil then
		return
	end

	local worldUpgradesAdded = game.GameState.WorldUpgradesAdded or {}

	-- Reset any orphaned card back TextureNums (from uninstalled mods) to the default (1)
	if game.GameState.MetaUpgradeLayoutsArt then
		for layoutIndex, textureNum in pairs(game.GameState.MetaUpgradeLayoutsArt) do
			if textureNum ~= nil and not mod.ActiveCardBackTextureNums[textureNum] then
				mod.DebugPrint("[CosmeticsAPI] Resetting orphaned card back TextureNum " .. tostring(textureNum)
					.. " on layout " .. tostring(layoutIndex) .. " to default.", 2)
				game.GameState.MetaUpgradeLayoutsArt[layoutIndex] = 1
			end
		end
	end

	-- For each cosmetic group, normalize the equip state
	-- Fixes two potential issues:
	-- 1. For RotateOnly groups (mandatory, always one equipped): if none is equipped (a mod that added the equipped cosmetic is no longer loaded) -> re-equip first *owned* cosmetic
	--    Non-RotateOnly groups allow having nothing equipped (player can toggle them off), so those are left alone.
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

			if not anyEquipped and worldUpgradesAdded[name] and cosmeticData.RotateOnly then
				-- No cosmetic in this RotateOnly group is equipped, but this one is owned - re-equip it
				-- Only RotateOnly groups require one to always be equipped; non-RotateOnly groups allow having nothing equipped (the player can toggle them off)
				worldUpgrades[name] = true
				mod.DebugPrint("[CosmeticsAPI] No cosmetic equipped in RotateOnly group containing '" ..
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
	LoadPackages({ Names = mod.RegisteredCrossroadsPackages })
	LoadPackages({ Names = mod.RegisteredCardBackPackages })
	normalizeCosmeticEquipState()

	return base(source, args)
end)

-- If returning from a Chaos Trial, this will be called instead of DeathAreaRoomTransition
modutil.mod.Path.Wrap("HubPostBountyLoad", function(base, source, args)
	LoadPackages({ Names = mod.RegisteredCrossroadsPackages })
	LoadPackages({ Names = mod.RegisteredCardBackPackages })
	normalizeCosmeticEquipState()

	return base(source, args)
end)

-- If returning from a Dream Dive, this will be called instead of DeathAreaRoomTransition
modutil.mod.Path.Wrap("HubPostDreamLoad", function(base, source, args)
	LoadPackages({ Names = mod.RegisteredCrossroadsPackages })
	LoadPackages({ Names = mod.RegisteredCardBackPackages })
	normalizeCosmeticEquipState()

	return base(source, args)
end)

-- Card back packages must be loaded at all times as they are also used during runs
modutil.mod.Path.Wrap("SetupMap", function(base, source, args)
	LoadPackages({ Names = mod.RegisteredCardBackPackages })

	return base(source, args)
end)
