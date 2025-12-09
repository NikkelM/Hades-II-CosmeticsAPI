---@meta NikkelM-Cosmetics_API
local public = {}

---@class CosmeticData
---@field Id string The internal name of the cosmetic. Prefix this with your mod's "_PLUGIN.guid" to ensure uniqueness!
---@field Name table The display name of the cosmetic. Provide a table for localized names in the format of { de = "German Name", el = "Greek Name", en = "English Name", ... }. "en" key is required. Any missing languages will fall back to English.
---@field Description table The description text for the cosmetic. Prefix with "{$Keywords.CosmeticAdd}:" for Alt Decor, and "{$Keywords.CosmeticAltAdd}:" for Extra Decor. Provide a table for localized names in the format of { de = "German Description", el = "Greek Description", en = "English Description", ... }. "en" key is required. Any missing languages will fall back to English.
---@field FlavorText table The description text for the cosmetic. Provide a table for localized names in the format of { de = "German Flavor", el = "Greek Flavor", en = "English Flavor", ... }. "en" key is required. Any missing languages will fall back to English.
---@field ShopCategory string Which shop this cosmetic should be added to. Choose one of "CosmeticsShop_Tent" (Mel's Tent), "CosmeticsShop_Main" (Crossroads Main Grounds & West), "CosmeticsShop_Taverna" (Taverna & Crossroads West), "CosmeticsShop_PreRun" (Training Grounds).
---@field InsertAfterCosmetic string|nil The ID of an existing cosmetic in the same ShopCategory to insert this cosmetic after. Can insert after another custom cosmetic if the other one is added first. If nil, the cosmetic will be added to the end of the category.
---@field CosmeticsGroup string Which group of cosmetics to remove/replace this cosmetic with when equipped. Must be the ID of an existing cosmetic in the same ShopCategory. This cosmetic will be added to the same group, or create a group if none exists yet.
---@field CosmeticAnimationPath string The path to the asset texture for this cosmetic in your package.
---@field AnimationScale number|nil The scale factor for the cosmetic's asset in the Crossroads. If nil, defaults to 1.
---@field IconPath string The path to the shop menu icon for the cosmetic in your package. Usually has a resolution of 125x125 or 110x110. You can reuse the same asset as CosmeticAnimationPath with proper scaling in many cases.
---@field IconScale number|nil The scale factor for the cosmetic's icon in the shop menu. If nil, defaults to 1.
---@field GameStateRequirements table|nil The requirements that must be met to show this cosmetic in the shop. Supports all base game requirement logic. If nil, the cosmetic will always be eligible.
---@field Cost table|nil The resource costs to buy this cosmetic. For display purposes, limit to five different resources. If nil, will default to { CosmeticsPoints = 50 } (50 Kudos).
---@field InheritFrom table|nil Which existing cosmetics to inherit properties from. If nil, will default to { "DefaultCosmeticItem" }. If set to anything else, some default values for other properties may not work, depending on what you inherit from.
---@field AlwaysRevealImmediately boolean|nil If true, this cosmetic will be shown as purchaseable as soon as it's GameStateRequirements are met. If false, the game will wait until the next run to reveal the cosmetic in the shop. Defaults to false.
---@field CameraFocusId integer|nil If set, the camera will pan to this ID when equipping the cosmetic. Use to override panning to the first ID in SetAnimationIds or ActivateIds.
---@field SetAnimationIds table| nil Which ObjectIds to set when this cosmetic is equipped by the player. The camera will pan to the first ID in this table if CameraFocusId is not set. Cannot be set if ActivateIds or ActivateRoomObstacleIds are set. Note: There is no validation on this field, so ensure the IDs exist.
---@field ActivateIds table|nil Which ObjectIds to activate when this cosmetic is equipped. Cannot be set if SetAnimationIds or ActivateRoomObstacleIds are set. The camera will pan to the first ID in this table if CameraFocusId is not set. Note: There is no validation on this field, so ensure the IDs exist.
-- ---@field ActivateRoomObstacleIds table|nil Which RoomObstacleIds to activate when this cosmetic is equipped. Cannot be set if SetAnimationIds or ActivateIds are set. The camera will pan to the first ID in this table if CameraFocusId is not set. Not used for the API. Note: There is no validation on this field, so ensure the IDs exist.
-- ---@field ToggleCollision boolean|nil If true, toggles collision for the activated/deactivated objects when this cosmetic is equipped. Only used if ActivateRoomObstacleIds is set. Defaults to true. Not used for the API.
-- ---@field ToggleShadows boolean|nil If true, toggles shadows for the activated/deactivated objects when this cosmetic is equipped. Only used if ActivateRoomObstacleIds is set. Defaults to true. Not used for the API.
---@field OnRevealFunctionName string|nil The name of a function to call after the cosmetic is revealed, but before the camera pans back to Melinoe. You can use <_PLUGIN.guid .. "." .. "YourModFunctionName"> to reference a function in your mod's namespace. If nil, no function is called.
-- ---@field RotateOnly boolean|nil If true, indicates this cosmetic is part of a group of other cosmetics (an "Alt Decor"). If false, indicates this is an "Extra Decor" cosmetic. Defaults to true. Must be true if CosmeticsGroup is set. Not used for the API.
-- ---@field AlwaysRevealImmediately boolean|nil This cosmetic is the default for it's group and already visible in the world. Not used for the API.
---@field PanDuration number|nil The duration of the panning from Melinoe's location to the cosmetic's location in the Crossroads. If nil, defaults to 1 second.
---@field PreActivationHoldDuration number|nil The duration to hold before activating the cosmetic after panning to its location. If nil, defaults to 0.5 seconds.
---@field PostActivationHoldDuration number|nil The duration to hold after the new cosmetic is revealed. If nil, defaults to 1.5 seconds.
-- ---@field Removable boolean|nil If true, indicates this cosmetic can be removed again after buying it. If false, this cosmetic will always be visible in the Crossroads once bought. Defaults to true. Can only be set to false for cosmetics not part of a group through CosmeticsGroup. Not used in the API/always set to true.
---@field PreRevealVoiceLines table|nil A table of voicelines to play when this cosmetic is unlocked. Refer to existing voiceline tables for formatting. If nil, the default voicelines will be used. Input is not validated for correctness.
---@field RevealReactionVoiceLines table|nil A table of voicelines to play after this cosmetic is revealed, when the camera has panned back to Melinoe. Refer to existing voiceline tables for formatting. If nil, the default voicelines will be used. Input is not validated for correctness.
---@field CosmeticRemovedVoiceLines table|nil A table of voicelines to play when this cosmetic is removed. Refer to existing voiceline tables for formatting. If nil, the default voicelines will be used. Can only be used if Removable is true. Input is not validated for correctness.
---@field CosmeticReAddedVoiceLines table|nil A table of voicelines to play when this cosmetic is re-equipped after being removed. Refer to existing voiceline tables for formatting. If nil, the default voicelines will be used. Can only be used if Removable is true. Input is not validated for correctness.

---Registers a new cosmetic to be added to the game.
---@param cosmeticData CosmeticData The input data for the new cosmetic item. Must be a valid CosmeticData table.
---@return boolean successfullyRegistered True if the cosmetic was successfully registered, false otherwise.
public.RegisterCosmetic = function(cosmeticData) end

return public
