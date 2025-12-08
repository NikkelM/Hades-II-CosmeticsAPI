modutil.mod.Path.Wrap("DeathAreaRoomTransition", function(base, source, args)
	-- Make sure that only one cosmetic from a group can be equipped at a time
	-- This can get out of sync if the player equips a modded cosmetic, plays vanilla and equips another cosmetic from the same group, then returns to modded, which will have both equipped at the same time
	-- This will always keep the cosmetic equipped that's first in the shop category list
	for _, category in ipairs(game.ScreenData.CosmeticsShop.ItemCategories) do
		for _, name in ipairs(category) do
			if game.GameState.WorldUpgrades[name] then
				-- Oh hey, this cosmetic is equipped! Unequip all of it's RemoveCosmetics just to be sure
				for _, toRemove in ipairs(game.WorldUpgradeData[name].RemoveCosmetics or {}) do
					if game.GameState.WorldUpgrades[toRemove] ~= nil then
						mod.DebugPrint("[CosmeticsAPI] Unequipping cosmetic '" .. toRemove ..
							"' because it is in the same group as another currently equipped cosmetic '" .. name ..
							"'. This can happen if you play vanilla and equip a cosmetic in a group you previously had a modded cosmetic equipped in. You might need to re-equip the proper cosmetic.",
							2)
					end
					game.GameState.WorldUpgrades[toRemove] = nil
				end
			end
		end
	end

	return base(source, args)
end)
