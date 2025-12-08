-- Called after all other mods have loaded - executes Sjson hooks for all newly added cosmetics here
-- #region HelpText
local order = {
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
		for _, cosmetic in ipairs(mod.AddedCosmeticSjsonData) do
			helpTextEntry = {
				Id = cosmetic.Id,
				DisplayName = cosmetic.Name[language] or cosmetic.Name.en or "Unnamed Cosmetic",
				Description = cosmetic.Description[language] or cosmetic.Description.en or "No Description",
			}
			flavorTextEntry = {
				Id = cosmetic.Id .. "_Flavor",
				Description = cosmetic.FlavorText[language] or cosmetic.FlavorText.en or "No Flavor Text",
			}

			table.insert(data.Texts, sjson.to_object(helpTextEntry, order))
			table.insert(data.Texts, sjson.to_object(flavorTextEntry, order))
		end
	end)
end
-- #endregion
