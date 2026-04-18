-- Called after all other mods have loaded - executes Sjson hooks for all newly added cosmetics here
-- #region HelpText
local textOrder = {
	"Id",
	"InheritFrom",
	"DisplayName",
	"Description",
	"OverwriteLocalization"
}

local helpTextEntry = nil
local flavorTextEntry = nil
for language, _ in pairs(mod.ValidLanguageCodes) do
	local hadesTwoHelpTextFile = rom.path.combine(rom.paths.Content(),
		"Game/Text/" .. language .. "/HelpText." .. language .. ".sjson")

	sjson.hook(hadesTwoHelpTextFile, function(data)
		for _, cosmetic in ipairs(mod.AddedCosmeticSjsonTextData) do
			helpTextEntry = {
				Id = cosmetic.Id,
				DisplayName = cosmetic.Name[language] or cosmetic.Name.en or "Unnamed Cosmetic",
				Description = cosmetic.Description[language] or cosmetic.Description.en or "No Description",
			}
			flavorTextEntry = {
				Id = cosmetic.Id .. "_Flavor",
				Description = cosmetic.FlavorText[language] or cosmetic.FlavorText.en or "No Flavor Text",
			}

			table.insert(data.Texts, sjson.to_object(helpTextEntry, textOrder))
			table.insert(data.Texts, sjson.to_object(flavorTextEntry, textOrder))
		end
	end)
end
-- #endregion

-- #region Cosmetic Animations & Shop Icons
local animationOrder = {
	"Name",
	"InheritFrom",
	"FilePath",
	"Scale",
	"OffsetX",
	"OffsetY",
}

local cosmeticAnimationEntry = nil
local cosmeticIconEntry = nil
local hadesTwoObstacleCrossroadsVFXFile = rom.path.combine(rom.paths.Content(),
	"Game/Animations/Obstacle_Crossroads_VFX.sjson")

for _, cosmetic in ipairs(mod.AddedCosmeticSjsonAnimationData) do
	sjson.hook(hadesTwoObstacleCrossroadsVFXFile, function(data)
		cosmeticIconEntry = {
			Name = cosmetic.IconId,
			FilePath = cosmetic.IconPath,
			Scale = cosmetic.IconScale or 1.0,
			OffsetX = cosmetic.IconOffsetX or 0,
			OffsetY = cosmetic.IconOffsetY or 0,
		}
		cosmeticAnimationEntry = {
			Name = cosmetic.AnimationId,
			InheritFrom = cosmetic.AnimationInheritFrom,
			FilePath = cosmetic.CosmeticAnimationPath,
			Scale = cosmetic.AnimationScale or 1.0,
			OffsetX = cosmetic.AnimationOffsetX or 0,
			OffsetY = cosmetic.AnimationOffsetY or 0,
		}

		table.insert(data.Animations, sjson.to_object(cosmeticAnimationEntry, animationOrder))
		table.insert(data.Animations, sjson.to_object(cosmeticIconEntry, animationOrder))
	end)
end
-- #endregion

-- #region Card Back Animations (DeckArt, DeckArt_Mouseover, CardBack)
local cardBackAnimationOrder = {
	"Name",
	"InheritFrom",
	"FilePath",
	"Scale",
	"Material",
}

local hadesTwoGUIScreensVFXFile = rom.path.combine(rom.paths.Content(),
	"Game/Animations/GUI_Screens_VFX.sjson")

sjson.hook(hadesTwoGUIScreensVFXFile, function(data)
	for _, cardBack in ipairs(mod.AddedCardBackSjsonAnimationData) do
		-- DeckArt_XX - selection UI art (inherits from DeckArt_01 like vanilla entries)
		local deckArtEntry = {
			Name = cardBack.DeckArtName,
			InheritFrom = "DeckArt_01",
			FilePath = cardBack.DeckArtPath,
			Material = "Unlit",
		}
		if cardBack.DeckArtScale then
			deckArtEntry.Scale = cardBack.DeckArtScale
		end
		table.insert(data.Animations, sjson.to_object(deckArtEntry, cardBackAnimationOrder))

		-- DeckArt_Mouseover_XX - hover state art
		local deckArtMouseoverEntry = {
			Name = cardBack.DeckArtMouseoverName,
			FilePath = cardBack.DeckArtMouseoverPath,
			Material = "Unlit",
		}
		if cardBack.DeckArtScale then
			deckArtMouseoverEntry.Scale = cardBack.DeckArtScale
		end
		table.insert(data.Animations, sjson.to_object(deckArtMouseoverEntry, cardBackAnimationOrder))

		-- CardBack_XX - in-combat card flip art
		local cardBackEntry = {
			Name = cardBack.CardBackName,
			FilePath = cardBack.CardBackPath,
			Material = "Unlit",
		}
		if cardBack.CardBackScale then
			cardBackEntry.Scale = cardBack.CardBackScale
		end
		table.insert(data.Animations, sjson.to_object(cardBackEntry, cardBackAnimationOrder))
	end
end)
-- #endregion
