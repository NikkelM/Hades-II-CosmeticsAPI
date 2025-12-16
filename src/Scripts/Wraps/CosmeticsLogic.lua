function mod.ApplyCauldronCookTopGraphic(source, args)
	if game.SessionMapState.CauldronCookTopId ~= nil then
		local lidAnimation = nil

		-- Check if the currently equipped Cauldron is a modded one, and set its lid animation if so
		for cosmeticId, lidAnimationPath in pairs(mod.RegisteredCauldrons) do
			if game.GameState.WorldUpgrades[cosmeticId] then
				lidAnimation = lidAnimationPath
				break
			end
		end

		if lidAnimation ~= nil then
			SetAnimation({ DestinationId = game.SessionMapState.CauldronCookTopId, Name = lidAnimation })
		end
	end
end

modutil.mod.Path.Wrap("ApplyCauldronCookTopGraphic", function(base, source, args)
	-- Apply a vanilla lid, or remove the lid
	base(source, args)
	-- If a modded lid should be added, do it now
	-- This function SHOULD NOT remove a lid/set the animation to nil, only apply lids (it was removed above if needed)
	mod.ApplyCauldronCookTopGraphic(source, args)
end)
