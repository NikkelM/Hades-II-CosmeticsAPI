# Changelog

## v3.0.2

<!--Releasenotes start-->
- Allow adding Arcana Cards to existing packs.
<!--Releasenotes end-->

## v3.0.1

- Allow passing `AutoUnlock` to `RegisterFamiliarCostume`.
- The familiar skins menu now shows six skins per page instead of five.

## v3.0.0

- The mod now supports adding new skins for familiars through `RegisterFamiliarCostume`.
- Renamed `RegisterCardBackPackages` to `RegisterAlwaysLoadedPackages`. The old name can still be used.

## v2.1.1

- Fixed the new levels of the Chthonic Chids display shelf spawning as soon as another mod registers a Chid, even if the original shelf is not yet unlocked.

## v2.1.0

- Added support for `ActivateFunctionArgs`.
- Added support for `OnRevealFunctionArgs`.
- Cosmetics that create a new group can no longer pass `CosmeticsGroup`, and will instead create the group from their ID. The ID should be prefixed with `ModCosmetic_`.
- Fixed Arcana card layouts becoming unselectable if they have a modded card back equipped and the game is started without the mod that adds the card back.
- Removed the `enabled` config option.

## v2.0.0

- The mod now supports turning existing vanilla obstacles or mod-spawned obstacles into cosmetics.
- To create a new cosmetics group from an obstacle, define it as a cosmetic and set the `CreateCosmeticsGroup` property to `true`.
- See the Readme for the full guidance and restrictions.

## v1.2.0

- The mod now supports adding new Chthonic Chid cosmetics. Use `RegisterChthonicChid(chidData)` to register a new Chthonic Chid. To do so, you must first open a PR to reserve slots in `mod.ChthonicChidReservations` in `src\Scripts\Utils.lua`.
- Up to 12 Chthonic Chids can be added through mods with the current setup, which adds two new levels to the shelf.
- A template texture can be found in `img\Chthonic Chids\Chid_template.png`.
- Approaching the Chthonic Chid display case when new levels are added will also start an "overlook" camera animation to ensure all figurines can be properly viewed.

## v1.1.6

- Updated developer documentation.

## v1.1.5

- Fixed: The game may crash if invalid types are passed in during mod development.
- Fixed: Some minor typos across various warnings and log messages.
- Code optimizations.

## v1.1.4

- Fixed: If a modded cosmetic is added to a `RotateOnly` group (cosmetics that cannot be unequipped), the option to unequip it still shows, but does nothing.
- Fixed: If a cosmetic in a non-`RotateOnly` group is unequipped without replacement, the CosmeticsAPI will re-equip an owned cosmetic when the map is next loaded, instead of leaving the group unequipped. 

## v1.1.3

- Fixed: Table formatting in Readme is broken.

## v1.1.2

- Fixed: Navigating right from a rightmost Arcana card takes additional navigation events to select the Grasp count.

## v1.1.1

- Removed `CardBackScale` property, as the game won't honour it.
- Added recommended texture sizes for card back (pack) textures.
- Added example textures for card back (packs) to the Readme.

## v1.1.0

- The API now supports adding new Arcana card backs, and adds additional pages to the selection screen to display them. Use `RegisterCardBackPack(packData)` to register a card back pack and `RegisterCardBack(cardBackData)` to register card backs in a pack.
- `RegisterCardBackPackages(packageNamesArray)` allows registering one or more `.pkg` packages that the Cosmetics API will automatically load everywhere. This should only contain the in-run card pack textures required when a new Arcana is equipped during a run, e.g. through Judgment.
- `RegisterCrossroadsPackages(packageNamesArray)` allows registering one or more `.pkg` packages that the Cosmetics API will automatically load in the Crossroads. Use this to register packages containing cosmetics textures.

## v1.0.4

- Fixed an issue where the game could fall back and display a cosmetic you do not own if a mod is disabled while a cosmetic it added is equipped.
- Fixed an issue where returning from a Dream Dive would not run some validation logic.

## v1.0.3

- Added `ToggleCollision` property.
- Added vanilla `SetAnimationValue` for `Cosmetic_SkellyZagreusStatue`. 

## v1.0.2

- Fixed potential issues with modded and vanilla cosmetics being equipped at the same time if the mod was temporarily disabled and the player returns from a Chaos Trial.

## v1.0.1

- The default `RevealReactionVoiceLines` have been updated to include more varied voicelines by Melinoë.

## v1.0.0

- Initial release.
