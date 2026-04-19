# Cosmetics API

Developer library to simplify adding new Crossroads cosmetics to Hades II. Does nothing by itself.

## Features

Through this library, you can easily add new cosmetic items to the Crossroads, as offered by Dora.
You can add alternative versions of *any* existing cosmetic, both "Alt Decor" and "Extra Decor" items are supported.
Adding entirely new cosmetics (in different locations), or replacing assets that aren't already a cosmetic is *not* supported.

The library will automatically handle grouping cosmetics so that equipping one will unequip any other already equipped cosmetic in the same group.
You can provide names, descriptions and flavour texts for various languages, as well as customize the voicelines used when purchasing, equipping or unequipping the cosmetic.

For even more advanced usecases, you can also provide a function name that is called when your cosmetic is bought or equipped.

You can also register new **Arcana Card Back** packs. The API handles shop integration, animation hookup and pagination when the card back selection screen exceeds one page.

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

### Registering Packages

If your cosmetics use custom textures bundled in `.pkg` files, you can register those packages so the API loads them when entering the Crossroads.
Place your `.pkg` (and `.pkg_manifest`) files in your mod's `plugins_data` folder and call `RegisterCrossroadsPackages` with a table of package names (without the `.pkg` extension):

```lua
CosmeticsAPI.RegisterCrossroadsPackages({ "AuthorName-ModNameCosmetics" })
```

The API will automatically load all registered packages when the player enters the Crossroads (including the Training Grounds), regardless of which transition is used (`DeathAreaRoomTransition`, `HubPostBountyLoad`, or `HubPostDreamLoad`).
Duplicate package names are silently ignored.

You can alternatively also load the packages yourself within your mod code.

### Registering Cosmetics

Now, you can add a new cosmetic by calling `CosmeticsAPI.RegisterCosmetic(cosmeticData)`, where `cosmeticData` is of type `CosmeticData`.
If you have your development environment set up correctly, VS Code should offer autocompletion and type hints for this table.
Otherwise, you can always refer to the `def.lua` file in the Cosmetics API source, or the below example, for all available fields.

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
		-- "{$Keywords.CosmeticSwap}:" resolves to "Alt Decor" with a tooltip for something that replaces something, "{$Keywords.CosmeticAltAdd}:" to "Extra Decor" with a tooltip that it adds or replaces something similar, and {$Keywords.CosmeticAdd} resolves to "Extra Decor" for something that did not exist before. You should not need to use CosmeticAdd, since all cosmetics added through the Cosmetics API replace an existing cosmetic.
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
	-- You can often reuse your animation path asset as an icon if you scale it correctly, though the icon might look grainy and be harder to decipher if the cosmetic is detailed
	IconPath = "AuthorName-ModName\\FolderPath\\Pillars_Chronos_Icon",

	-- OPTIONAL FIELDS (with their defaults)
	AnimationScale = 1,
	AnimationInheritFrom = nil,
	AnimationOffsetX = 0,
	AnimationOffsetY = 0,
	IconScale = 1,
	IconOffsetX = 0,
	IconOffsetY = 0,
	-- Which other cosmetic in the same shop category to insert your new one after, or nil to add to the end
	InsertAfterCosmetic = nil,
	-- Try to limit to a maximum of four resources (including CosmeticsPoints) for optimal display in the UI
	Cost = {
		CosmeticsPoints = 50,
	},
	-- Must be met before the cosmetic becomes available for purchase
	GameStateRequirements = {},
	-- Note: some field validations performed by the API are disabled if you provide this property
	InheritFrom = { "DefaultCosmeticItem" },
	-- If the new cosmetic can show up in the shop as soon as eligible, even if the shop has already been viewed in the current Crossroads session. Otherwise, will show after the next run
	AlwaysRevealImmediately = false,
	-- Overrides where the camera pans when equipping the cosmetic
	CameraFocusId = nil,
	-- At least one of SetAnimationIds or ActivateIds must be provided (or inherited)
	SetAnimationIds = nil,
	ActivateIds = nil,
	DeactivateIds = nil,
	ToggleCollision = nil,
	ActivateFunctionName = nil,
	OnRevealFunctionName = nil,
	PanDuration = 1,
	PreActivationHoldDuration = 0.5,
	PostActivationHoldDuration = 1.5,
	PreRevealVoiceLines = { ... },
	RevealReactionVoiceLines = { ... },
	CosmeticRemovedVoiceLines = { ... },
	CosmeticReEquipVoiceLines = { ... },
	-- If your cosmetic is a new cauldron, you will need to set this to true so the API knows to apply cauldron-specific logic (like handling which cauldron lid the game uses)
	IsCauldron = false,
	-- Cauldron scaling and location is not changeable through sjson, if your lid is not aligned properly, you will need to change your asset directly
	CauldronLidAnimationPath = nil,
})
```

### Registering Card Back Packs

You can add new Arcana card back packs to the Training Grounds cosmetics shop.
Each pack unlocks a set of card backs when purchased.
The API handles shop display, animation hookup and pagination when the selection screen exceeds one page.

Card backs require **three types of textures**, in different packages:

| Texture | Used Where | Package Type |
|---------|-----------|-------------|
| **DeckArt** (idle) + **DeckArtMouseover** (hover) | Card back picker overlay in the Crossroads | `RegisterCrossroadsPackages` |
| **IconPath** (shop preview) | Training Grounds cosmetics shop | `RegisterCrossroadsPackages` |
| **CardBack** (in-combat flip) | During runs when an Arcana is added | `RegisterCardBackPackages` |

First, register your packages:

```lua
-- DeckArt textures + shop icon - only needed in the Crossroads
CosmeticsAPI.RegisterCrossroadsPackages({ "AuthorName-ModName-DeckArt" })

-- CardBack textures - loaded at ALL times (including during runs), keep these packages small!
CosmeticsAPI.RegisterCardBackPackages({ "AuthorName-ModName-CardBacks" })
```

Then register a card back pack:

```lua
CosmeticsAPI.RegisterCardBackPack({
	-- REQUIRED FIELDS
	Id = _PLUGIN.guid .. "." .. "MyCardBackPack",
	Name = {
		en = "Custom Card Backs",
	},
	Description = {
		en = "A set of custom card backs for the Arcana.",
	},
	FlavorText = {
		en = "Every card tells a story.",
	},
	-- Shop preview icon - a small thumbnail. See vanilla examples: GUI\Screens\CosmeticIcons\cosmetic_deckMisc
	IconPath = "AuthorName-ModName\\Icons\\MyPackIcon",

	-- OPTIONAL FIELDS (with their defaults)
	IconScale = 1,
	IconOffsetX = 0,
	IconOffsetY = 0,
	Cost = { CosmeticsPoints = 300 },
	-- Unlocking Arcana card packs will always require layout saving to be unlocked (WorldUpgradeMetaUpgradeSaveLayout), in addition to any custom checks
	GameStateRequirements = nil,
	-- Insert after a specific cosmetic in the Training Grounds shop, or nil to append to end
	InsertAfterCosmetic = nil,
	-- Defaults to "How about a new look for the old Arcana..." when nil
	PreRevealVoiceLines = nil,
})
```

### Registering Card Backs

After registering a pack, register individual card backs for it:

```lua
CosmeticsAPI.RegisterCardBack({
	-- REQUIRED FIELDS
	Id = _PLUGIN.guid .. "." .. "MyCardBack_01",
	-- Must match a previously registered pack ID
	PackId = _PLUGIN.guid .. "." .. "MyCardBackPack",
	-- Idle card art for the selection overlay. See vanilla: GUI\Screens\MetaUpgrade\DeckArt\Deck01
	DeckArtPath = "AuthorName-ModName\\DeckArt\\MyDeck01",
	-- Card back for the in-combat flip animation. See vanilla: GUI\Screens\CardBack\CardBack01
	CardBackPath = "AuthorName-ModName\\CardBack\\MyCardBack01",

	-- OPTIONAL FIELDS
	-- Highlighted variant shown on hover. See vanilla: GUI\Screens\MetaUpgrade\DeckArt\DeckMouseover01
	-- If nil, uses DeckArtPath (no hover effect)
	DeckArtMouseoverPath = "AuthorName-ModName\\DeckArt\\MyDeckMouseover01",
	DeckArtScale = nil,
	CardBackScale = nil,
})
```

Card backs from the same pack will appear grouped together in the selection screen.
The API automatically handles pagination when the total number of unlocked card backs exceeds 40 (one page).

## Important Note & Contributing

If you want to add a variant cosmetic for a base game "Extra Decor" item, the Cosmetics API *must* know the `CosmeticAnimationPath` (`SetAnimationValue`) of the base game cosmetic, as these are not part of the cosmetics definition for all "Extra Decor" items.
The Cosmetics API has a list of known animation names for some cosmetics (naturally growing on-demand), so if you want to add a new variant, you must first open a PR against the Cosmetics API to add the unknown animation name to the list.
If the Cosmetics API does not know the base animation name, it will throw an error when you try to register your new cosmetic.

You can find the list under [`./src/Scripts/Utils.lua`, `mod.KnownExtraDecorBaseAnimations`](https://github.com/NikkelM/Hades-II-CosmeticsAPI/blob/main/src/Scripts/Utils.lua).

You can most often get the `SetAnimationValue` from the `Game/Obstacles/Crossroads.sjson` file.
Most obstacles in this file are named `"Crossroads<Cosmetic name without "Cosmetic_" prefix>01"`.
The `SetAnimationValue` we need is the `Thing.Graphic` of the obstacle, *NOT* the obstacle name itself.

Some cosmetics may require additional overrides to work correctly with modded cosmetics, you can add them there as well.
This is e.g. the case if the vanilla cosmetic defines `ActivateIds`, which would all get set to the new `SetAnimationValue` if no separate `SetAnimationIds` table is provided.
