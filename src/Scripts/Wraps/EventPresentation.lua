-- Fallback wrap for ShowMetaUpgradeCard to handle orphaned card back TextureNums.
-- When a mod that added card backs is removed, the saved TextureNum may reference a CardBack_XX animation that no longer exists.
-- This wrap auto-heals by resetting to the default card back (TextureNum 1).
modutil.mod.Path.Wrap("ShowMetaUpgradeCard", function(base, metaUpgradeName, x, y)
	if not game.IsEmpty(game.GameState.MetaUpgradeLayoutsArt) and game.GameState.CurrentMetaUpgradeLayout then
		local layoutIndex = game.GameState.CurrentMetaUpgradeLayout
		local cardBackIndex = game.GameState.MetaUpgradeLayoutsArt[layoutIndex]

		if cardBackIndex ~= nil and cardBackIndex ~= 1 then
			-- Check if this TextureNum is still valid (vanilla 1-40 or a registered modded card back)
			if not mod.ActiveCardBackTextureNums[cardBackIndex] then
				mod.DebugPrint("[CosmeticsAPI] Card back TextureNum " .. tostring(cardBackIndex)
					.. " is no longer valid (mod may have been removed). Resetting to default.", 2)
				game.GameState.MetaUpgradeLayoutsArt[layoutIndex] = 1
			end
		end
	end

	return base(metaUpgradeName, x, y)
end)
