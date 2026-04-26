---@meta NikkelM-Cosmetics_API
local public = {}

---@class CosmeticData
---@field Id string The internal name of the cosmetic. Prefix this with your mod's `_PLUGIN.guid` to ensure uniqueness!
---@field Name table The display name of the cosmetic. Provide a table for localized names in the format of { de = "German Name", el = "Greek Name", en = "English Name", ... }. "en" key is required. Any missing languages will fall back to English.
---@field Description table The description text for the cosmetic. Prefix with "{$Keywords.CosmeticSwap}:" for Alt Decor that replaces something, "{$Keywords.CosmeticAltAdd}:" for Extra Decor that adds or replaces something similar, and "{$Keywords.CosmeticAdd}:" for Extra Decor that adds something entirely new (you should not need to use this one, as all modded cosmetics replace something existing). Provide a table for localized names in the format of { de = "German Description", el = "Greek Description", en = "English Description", ... }. "en" key is required. Any missing languages will fall back to English.
---@field FlavorText table The description text for the cosmetic. Provide a table for localized names in the format of { de = "German Flavor", el = "Greek Flavor", en = "English Flavor", ... }. "en" key is required. Any missing languages will fall back to English.
---@field ShopCategory string Which shop this cosmetic should be added to. Choose one of "CosmeticsShop_Tent" (Mel's Tent), "CosmeticsShop_Main" (Crossroads Main Grounds & West), "CosmeticsShop_Taverna" (Taverna & Crossroads West), "CosmeticsShop_PreRun" (Training Grounds).
---@field InsertAfterCosmetic string|nil The ID of an existing cosmetic in the same ShopCategory to insert this cosmetic after. Can insert after another custom cosmetic if the other one is added first. If nil, the cosmetic will be added to the end of the category.
---@field CosmeticsGroup string Which group of cosmetics to remove/replace this cosmetic with when equipped. Must be the ID of an existing cosmetic in the same ShopCategory. This cosmetic will be added to the same group, or create a group if none exists yet.
---@field CosmeticAnimationPath string The path to the asset texture for this cosmetic in your package.
---@field AnimationScale number|nil The scale factor for the cosmetic's asset in the Crossroads. If nil, defaults to 1.
---@field AnimationInheritFrom string|nil An existing sjson object to inherit from for the cosmetic animation (e.g. "CriticalItemWorldObject01" for a new Cauldron). If nil, no inheritance is applied.
---@field AnimationOffsetX number|nil The X offset to apply to the cosmetic's animation in the Crossroads. Positive values move the item right, negative values move it left. If nil, defaults to 0.
---@field AnimationOffsetY number|nil The Y offset to apply to the cosmetic's animation in the Crossroads. Positive values move the item down, negative values move it up. If nil, defaults to 0.
---@field IconPath string The path to the shop menu icon for the cosmetic in your package. You can reuse the same asset as CosmeticAnimationPath with proper scaling in many cases, though the icon might look noisy and be hard to read if the cosmetic is detailed.
---@field IconScale number|nil The scale factor for the cosmetic's icon in the shop menu. If nil, defaults to 1.
---@field IconOffsetX number|nil The X offset to apply to the cosmetic's icon in the shop menu. Positive values move the icon right, negative values move it left. If nil, defaults to 0.
---@field IconOffsetY number|nil The Y offset to apply to the cosmetic's icon in the shop menu. Positive values move the icon down, negative values move it up. If nil, defaults to 0.
---@field GameStateRequirements table|nil The requirements that must be met to show this cosmetic in the shop. Supports all base game requirement logic. If nil, the cosmetic will always be eligible.
---@field Cost table|nil The resource costs to buy this cosmetic. For display purposes, limit to five different resources. If nil, will default to { CosmeticsPoints = 50 } (50 Kudos).
---@field InheritFrom table|nil Which existing cosmetics to inherit properties from. If nil, will default to { "DefaultCosmeticItem" }. If set to anything else, some default values for other properties may not work, depending on what you inherit from, and the API will not validate some otherwise required fields, so ensure you know what you're doing.
---@field AlwaysRevealImmediately boolean|nil If true, this cosmetic will be shown as purchaseable as soon as it's GameStateRequirements are met. If false, the game will wait until the next run to reveal the cosmetic in the shop. Defaults to false.
---@field CameraFocusId integer|nil If set, the camera will pan to this ID when equipping the cosmetic. Use to override panning to the first ID in SetAnimationIds or ActivateIds.
---@field SetAnimationIds table| nil Which ObjectIds to set the animation to when this cosmetic is equipped. The camera will pan to the first ID in this table if CameraFocusId is not set. If ActivateIds is also set, those IDs will be activated, but the animation value will only apply to the IDs in SetAnimationIds. Note: There is no validation on this field, so ensure the IDs exist.
---@field ActivateIds table|nil Which ObjectIds to activate when this cosmetic is equipped. The camera will pan to the first ID in this table if CameraFocusId is not set. Note: There is no validation on this field, so ensure the IDs exist.
---@field DeactivateIds table|nil Which ObjectIds to deactivate when this cosmetic is equipped. Note: There is no validation on this field, so ensure the IDs exist.
-- ---@field ActivateRoomObstacleIds table|nil Which RoomObstacleIds to activate when this cosmetic is equipped. Cannot be set if SetAnimationIds or ActivateIds are set. The camera will pan to the first ID in this table if CameraFocusId is not set. Not used for the API. Note: There is no validation on this field, so ensure the IDs exist.
---@field ToggleCollision boolean|nil If true, toggles collision for the activated/deactivated objects when this cosmetic is equipped. Should be the same as for the base cosmetic you're adding an alternative to in most cases. Defaults to nil.
-- ---@field ToggleShadows boolean|nil If true, toggles shadows for the activated/deactivated objects when this cosmetic is equipped. Only used if ActivateRoomObstacleIds is set. Defaults to true. Not used for the API.
---@field ActivateFunctionName string|nil The name of a function to call whenever the cosmetic is equipped. You can use <_PLUGIN.guid .. "." .. "YourModFunctionName"> to reference a function in your mod's namespace. If nil, no function is called.
---@field OnRevealFunctionName string|nil The name of a function to call after the cosmetic is revealed, but before the camera pans back to Melinoe. You can use <_PLUGIN.guid .. "." .. "YourModFunctionName"> to reference a function in your mod's namespace. If nil, no function is called.
-- ---@field RotateOnly boolean|nil If true, indicates this cosmetic is part of a group of other cosmetics (an "Alt Decor"). If false, indicates this is an "Extra Decor" cosmetic. Defaults to true. Must be true if CosmeticsGroup is set. Not used for the API.
---@field PanDuration number|nil The duration of the panning from Melinoe's location to the cosmetic's location in the Crossroads. If nil, defaults to 1 second.
---@field PreActivationHoldDuration number|nil The duration to hold before activating the cosmetic after panning to its location. If nil, defaults to 0.5 seconds.
---@field PostActivationHoldDuration number|nil The duration to hold after the new cosmetic is revealed. If nil, defaults to 1.5 seconds.
-- ---@field Removable boolean|nil If true, indicates this cosmetic can be removed again after buying it. If false, this cosmetic will always be visible in the Crossroads once bought. Defaults to true. Can only be set to false for cosmetics not part of a group through CosmeticsGroup. Not used in the API/always set to true.
---@field PreRevealVoiceLines table|nil A table of voicelines to play when this cosmetic is unlocked. Refer to existing voiceline tables for formatting. If nil, the default voicelines will be used. Input is not validated for correctness.
---@field RevealReactionVoiceLines table|nil A table of voicelines to play after this cosmetic is revealed, when the camera is panning back to Melinoe. Refer to existing voiceline tables for formatting. If nil, default voicelines will be used. Input is not validated for correctness.
---@field CosmeticRemovedVoiceLines table|nil A table of voicelines to play when this cosmetic is removed. Refer to existing voiceline tables for formatting. If nil, the default voicelines will be used. Can only be used if Removable is true. Input is not validated for correctness.
---@field CosmeticReEquipVoiceLines table|nil A table of voicelines to play when this cosmetic is re-equipped after being removed. Refer to existing voiceline tables for formatting. If nil, the default voicelines will be used. Can only be used if Removable is true. Input is not validated for correctness.
---@field IsCauldron boolean|nil If true, indicates this cosmetic is a cauldron. If set to true, CauldronLidAnimationPath is required. Defaults to false.
---@field CauldronLidAnimationPath string|nil The path to the asset texture for the cauldron lid animation in your package. Required if IsCauldron is true. Note that the position and scale of the lid in-game is preset and cannot be changed, modify your asset if needed.

---Registers a new cosmetic to be added to the game.
---@param cosmeticData CosmeticData The input data for the new cosmetic item. Must be a valid CosmeticData table.
---@return boolean successfullyRegistered True if the cosmetic was successfully registered, false otherwise.
public.RegisterCosmetic = function(cosmeticData) end

---Registers one or more .pkg package files that contain the textures for cosmetics that are added to the Crossroads (including the Training Grounds).
---These packages will be automatically loaded by the CosmeticsAPI when entering the Crossroads.
---The .pkg files must be placed in your mod's `plugins_data` folder.
---@param packageNamesArray table A list of package names (table of strings) to register. Do not include the `.pkg` extension.
---@return boolean successfullyRegistered True if at least one package was successfully registered, false otherwise.
public.RegisterCrossroadsPackages = function(packageNamesArray) end

---@class CardBackPackData
---@field Id string Unique pack identifier. Prefix this with your mod's `_PLUGIN.guid` to ensure uniqueness!
---@field Name table Localized display name. { en = "Arcana, English Name", de = "Arkana (Deutscher Name)", ... }. "en" key is required.
---@field Description table Localized description. { en = "Set of language-based card backs.", ... }. "en" key is required.
---@field FlavorText table Localized flavor text. { en = "Language is a strange thing...", ... }. "en" key is required.
---@field IconPath string Path to the shop preview icon texture for this pack. This usually shows three different card backs in a slight spread overlayed on each other. See `GUI\Screens\CosmeticIcons\cosmetic_deckMisc`. This texture should be in a package registered via `RegisterCrossroadsPackages`, as the shop is only accessible in the Crossroads.
---@field IconScale number|nil Scale for the icon. Defaults to 1.
---@field IconOffsetX number|nil X offset for the icon. Defaults to 0.
---@field IconOffsetY number|nil Y offset for the icon. Defaults to 0.
---@field Cost table|nil Resource costs. Defaults to { CosmeticsPoints = 300 }.
---@field GameStateRequirements table|nil Shop visibility requirements. Defaults to requiring WorldUpgradeMetaUpgradeSaveLayout (layout saving unlocked).
---@field InsertAfterCosmetic string|nil ID of an existing cosmetic in CosmeticsShop_PreRun to insert after. If nil, appended to end.
---@field PreRevealVoiceLines table|nil Custom voice lines on purchase. If nil, uses a default Melinoe line.

---Registers a new card back pack to be added to the cosmetics shop in the Training Grounds.
---A pack is a cosmetic item that, when purchased, unlocks all card backs registered for it via `RegisterCardBack`.
---Must be called before registering any card backs that belong to this pack.
---@param packData CardBackPackData The input data for the new card back pack.
---@return boolean successfullyRegistered True if the pack was successfully registered, false otherwise.
public.RegisterCardBackPack = function(packData) end

---@class CardBackData
---@field Id string Unique card back identifier. Prefix this with your mod's `_PLUGIN.guid` to ensure uniqueness!
---@field PackId string The ID of the CardBackPack this card back belongs to. Must have been registered first via `RegisterCardBackPack`.
---@field DeckArtPath string Path to the idle/normal card art texture shown in the card back picker overlay (Arcana screen). This is the default state before hovering. See `GUI\Screens\MetaUpgrade\DeckArt\Deck10`. This texture should be in a package registered via `RegisterCrossroadsPackages`, as the picker is only accessible in the Crossroads.
---@field DeckArtMouseoverPath string|nil Path to the highlighted/brighter variant of the card art, shown on hover in the picker overlay. Each vanilla card back has a separate mouseover texture - see `GUI\Screens\MetaUpgrade\DeckArt\DeckMouseover10`. This texture should be in the same Crossroads package as DeckArtPath. If nil, uses DeckArtPath (no hover effect).
---@field CardBackPath string Path to the card back texture shown during the in-combat Arcana card flip animation (e.g. when gaining an Arcana through Judgment). See `GUI\Screens\CardBack\CardBack10`. This texture should be in a package registered via `RegisterCardBackPackages`, as it must be available at all times including during runs.
---@field DeckArtScale number|nil Scale for DeckArt animation in the selection UI.

---Registers an individual card back. The card back is unlocked when its associated pack is purchased in the shop.
---The pack must be registered via `RegisterCardBackPack` before calling this function.
---The API auto-assigns a deterministic TextureNum derived from the card back's string ID, ensuring the same ID always maps to the same number regardless of mod load order.
---This TextureNum is used internally for animation name lookup and save persistence (GameState.MetaUpgradeLayoutsArt).
---@param cardBackData CardBackData The input data for the new card back.
---@return boolean successfullyRegistered True if the card back was successfully registered, false otherwise.
public.RegisterCardBack = function(cardBackData) end

---Registers one or more .pkg package files that contain the card back textures used during the in-combat Arcana card flip animation.
---These packages will be loaded at ALL times (including during runs), not just in the Crossroads, because card back art is displayed when an Arcana is added (e.g. through Judgment).
---IMPORTANT: Only include CardBack_XX textures in these packages.
---Because they are always loaded, any unnecessary assets will consume memory permanently.
---Use `RegisterCrossroadsPackages` for DeckArt/DeckArtMouseover/IconPath textures that are only needed in the Crossroads.
---The .pkg files must be placed in your mod's `plugins_data` folder.
---@param packageNamesArray table A list of package names (table of strings) to register. Do not include the `.pkg` extension.
---@return boolean successfullyRegistered True if at least one package was successfully registered, false otherwise.
public.RegisterCardBackPackages = function(packageNamesArray) end

return public
