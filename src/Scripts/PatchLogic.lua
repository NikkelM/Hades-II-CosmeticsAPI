modutil.mod.Path.Wrap("DoPatches", function(base)
	local result = base()

	if game.GameState ~= nil then
		game.GameState.ModFamiliarCostumes = game.GameState.ModFamiliarCostumes or {}
		game.GameState.ModsNikkelMCosmeticsAPI = game.GameState.ModsNikkelMCosmeticsAPI or {}
		game.GameState.ModsNikkelMCosmeticsAPI.CardBacks = game.GameState.ModsNikkelMCosmeticsAPI.CardBacks or {}

		for index, textureNum in pairs(game.GameState.MetaUpgradeLayoutsArt or {}) do
			-- If the equipped texture is 1, it could also just be the vanilla fallback for a custom texture, so don't save it in the mod data
			if textureNum ~= 1 then
				if not mod.ActiveCardBackTextureNums[textureNum] then
					mod.DebugPrint("[CosmeticsAPI] Resetting orphaned card back TextureNum " .. tostring(textureNum)
						.. " on layout " .. tostring(index) .. " to default.", 2)
					textureNum = 1
				end
				mod.SelectCardBack(index, textureNum)
			end
		end

		if game.GameState.WorldUpgrades ~= nil and game.ScreenData ~= nil and game.ScreenData.CosmeticsShop ~= nil then
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
					local anyEquipped = game.GameState.WorldUpgrades[name]
					if not anyEquipped then
						for _, siblingName in ipairs(cosmeticData.RemoveCosmetics) do
							if game.GameState.WorldUpgrades[siblingName] then
								anyEquipped = true
								break
							end
						end
					end

					if not anyEquipped and cosmeticData.RotateOnly and game.GameState.WorldUpgradesAdded and game.GameState.WorldUpgradesAdded[name] then
						-- No cosmetic in this RotateOnly group is equipped, but this one is owned - re-equip it
						-- Only RotateOnly groups require one to always be equipped; non-RotateOnly groups allow having nothing equipped (the player can toggle them off)
						game.GameState.WorldUpgrades[name] = true
						mod.DebugPrint("[CosmeticsAPI] No cosmetic equipped in RotateOnly group containing '" ..
							name .. "', re-equipping owned cosmetic '" .. name .. "'.", 2)
					elseif game.GameState.WorldUpgrades[name] then
						-- This one is equipped - unequip all siblings to ensure only one is active
						for _, toRemove in ipairs(cosmeticData.RemoveCosmetics) do
							if game.GameState.WorldUpgrades[toRemove] ~= nil then
								mod.DebugPrint("[CosmeticsAPI] Unequipping cosmetic '" .. toRemove ..
									"' because it is in the same group as another currently equipped cosmetic '" .. name ..
									"'. This can happen if you play vanilla and equip a cosmetic in a group you previously had a modded cosmetic equipped in. You might need to re-equip the proper cosmetic.",
									2)
							end
							game.GameState.WorldUpgrades[toRemove] = nil
						end
					end

					::continue::
				end
			end
		end
	end

	return result
end)

-- This must be the same as the wrap for HubPostBountyLoad and HubPostDreamLoad
modutil.mod.Path.Wrap("DeathAreaRoomTransition", function(base, source, args)
	LoadPackages({ Names = mod.RegisteredCrossroadsPackages })
	mod.SetupChthonicChidDisplay(source)

	return base(source, args)
end)

-- If returning from a Chaos Trial, this will be called instead of DeathAreaRoomTransition
modutil.mod.Path.Wrap("HubPostBountyLoad", function(base, source, args)
	LoadPackages({ Names = mod.RegisteredCrossroadsPackages })
	mod.SetupChthonicChidDisplay(source)

	return base(source, args)
end)

-- If returning from a Dream Dive, this will be called instead of DeathAreaRoomTransition
modutil.mod.Path.Wrap("HubPostDreamLoad", function(base, source, args)
	LoadPackages({ Names = mod.RegisteredCrossroadsPackages })
	mod.SetupChthonicChidDisplay(source)

	return base(source, args)
end)

modutil.mod.Path.Wrap("SetupMap", function(base, source, args)
	LoadPackages({ Names = mod.RegisteredAlwaysLoadedPackages })

	return base(source, args)
end)
