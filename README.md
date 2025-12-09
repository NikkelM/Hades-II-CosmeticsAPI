# Cosmetics API

Developer library to simplify adding new Crossroads cosmetics to Hades II. Does nothing by itself.

## Features

Through this library, you can easily add new cosmetic items to the Crossroads, as offered by Dora.
You can add alternative versions of *any* existing cosmetic, both "Alt Decor" and "Extra Decor" items are supported.
Adding entirely new cosmetics (in different locations) is *not* supported.

The library will automatically handle grouping cosmetics so that equipping one will unequip any other already equipped cosmetic in the same group.
You can provide names, descriptions and flavour texts for various languages, as well as customize the voicelines used when purchasing, equipping or unequipping the cosmetic.

For even more advanced usecases, you can also provide a function name that is called when your cosmetic is equipped.

## Usage

Start by adding `NikkelM-Cosmetics_API` as a dependency in your `thunderstore.toml` (ensure you use the latest version):

```toml
NikkelM-Cosmetics_API = "1.0.0"
```

Next, include the Cosmetics API in your `main.lua`, alongside other dependencies:

```lua
---@module "NikkelM-Cosmetics_API"
CosmeticsAPI = mods["NikkelM-Cosmetics_API"]
```

Now, you can add a new cosmetic by calling `CosmeticsAPI.RegisterCosmetic(cosmeticData)`, where `cosmeticData` is of type `CosmeticData`.
If you have your development environment set up correctly, VS Code should offer autocompletion and type hints for this table.
Otherwise, you can always refer to the `def.lua` file in the Cosmetics API source for all available fields.

```lua
CosmeticsAPI.RegisterCosmetic({
	-- REQUIRED FIELDS
	Id = _PLUGIN.guid .. "." .. "Cosmetic_Pillars_Chronos",
	-- At least "en" must be provided for Name, Description and FlavorText
	Name = {
		en = "Pillars, Timeless",
		de = "...",
	},
	Description = {
		-- "{$Keywords.CosmeticSwap}:" resolves to "Alt Decor" with a tooltip for something that replaces something, "{$Keywords.CosmeticAltAdd}:" to "Extra Decor" with a tooltip that it replaces something similar, and {$Keywords.CosmeticAdd} resolves to "Extra Decor" for something that did not exist before.
		en = "{$Keywords.CosmeticSwap}: Time-worn monoliths that stand tall to either side of the {#BoldFormatGraftDark}Cauldron{#Prev}.",
		de = "...",
	},
	FlavorText = {
		en = "Nothing stands the test of time they say, yet these pillars beg to differ.",
		de = "...",
	},
	-- Which of Dora's shop locations to add this cosmetic to. One of "CosmeticsShop_Tent" (Mel's Tent), "CosmeticsShop_Main" (Crossroads Main Grounds & West), "CosmeticsShop_Taverna" (Taverna & Crossroads West), "CosmeticsShop_PreRun" (Training Grounds)
	ShopCategory = "CosmeticsShop_Main",
	-- Which existing cosmetic the new one is a variant of
	CosmeticsGroup = "Cosmetic_CauldronPillars01",
	-- The in-world asset when the cosmetic is equipped
	CosmeticAnimationPath = "AuthorName-ModName\\FolderPath\\Pillars_Chronos",
	-- You can often reuse your animation path asset as an icon if you scale it correctly
	IconPath = "AuthorName-ModName\\FolderPath\\Pillars_Chronos_Icon",
	-- OPTIONAL FIELDS (with their defaults)
	AnimationScale = 1,
	IconScale = 1,
	-- Which other cosmetic in the same category to insert your new one after, or nil to add to the end
	InsertAfterCosmetic = nil,
	Cost = {
		CosmeticsPoints = 50,
	},
	GameStateRequirements = {},
	-- Some field validations are disabled if you provide this property
	InheritFrom = { "DefaultCosmeticItem" },
	-- If the new cosmetic can show up in the shop as soon as eligible, even if the shop has already been viewed in the current Crossroads session. Otherwise, will show after the next run
	AlwaysRevealImmediately = false,
	-- Overrides where the camera pans when equipping the cosmetic
	CameraFocusId = nil,
	-- One of SetAnimationIds or ActivateIds must be provided (or inherited)
	SetAnimationIds = nil,
	ActivateIds = nil,
	OnRevealFunctionName = nil,
	PanDuration = 1,
	PreActivationHoldDuration = 0.5,
	PostActivationHoldDuration = 1.5,
	PreRevealVoiceLines = { ... },
	RevealReactionVoiceLines = { ... },
	CosmeticRemovedVoiceLines = { ... },
	CosmeticReAddedVoiceLines = { ... },
})
```

## Important Note

If you want to add a variant cosmetic for a base game "Extra Decor" item, the Cosmetics API *must* know the `CosmeticAnimationPath (SetAnimationValue)` of the base game cosmetic, as these are not part of the cosmetics definition for "Extra Decor" items.
The Cosmetics API has a list of known animation names for some cosmetics, but if you want to add a new variant, you must first open a PR against the Cosmetics API to add the unknown animation name to the list.
If the Cosmetics API does not know the base animation name, it will throw an error when you try to register your new cosmetic.

You can find the list under [`./src/Scripts/Utils.lua`, `mod.KnownExtraDecorBaseAnimations`](https://github.com/NikkelM/Hades-II-CosmeticsAPI/blob/main/src/Scripts/Utils.lua).

New file paths have the format `CosmeticId = "FilePath"`.
You can most often get the FilePath from the `Game/Obstacles/Crossroads.sjson` file.
Most obstacles in this file are named `"Crossroads<Cosmetic name without "Cosmetic_" prefix>01"`.
The filepath we need is the `Thing.Graphic` of the obstacle, *NOT* the obstacle name itself.
