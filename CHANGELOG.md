# Changelog

## v1.1.0

<!--Releasenotes start-->
- New: `RegisterCrossroadsPackages(packageNamesArray)` now allows registering one or more `.pkg` packages that the Cosmetics API will automatically load in the Crossroads. Use this to register packages containing the cosmetic textures.
<!--Releasenotes end-->

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
