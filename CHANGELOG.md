# Changelog

## v1.1.1

<!--Releasenotes start-->
- Removed `CardBackScale` property, as the game won't honour it.
- Added recommended texture sizes for card back (pack) textures.
- Added example textures for card back (packs) to the Readme.
<!--Releasenotes end-->

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
