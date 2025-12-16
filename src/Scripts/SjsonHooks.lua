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
