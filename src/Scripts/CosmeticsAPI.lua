---@meta NikkelM-Cosmetics_API
-- Can add new versions of existing Alt Decor, or alternate versions of Extra Decor cosmetics
-- Cannot add completely new cosmetics
-- If your mod is uninstalled with a custom cosmetic equipped, the game will not show any asset in this location, and the player must re-equip a valid cosmetic, but the save can still be loaded

---Registers a new cosmetic to be added to the game.
---@param cosmeticData CosmeticData The input data for the new cosmetic item. Must be a valid CosmeticData table.
---@return boolean successfullyRegistered True if the cosmetic was successfully registered, false otherwise.
public.RegisterCosmetic = function(cosmeticData)
	-- #region Basic Input Validation
	-- Ensure required fields exist with correct types
	local requiredFields = {
		Id = "string",
		Name = "table",
		FlavorText = "table",
		ShopCategory = "string",
		Icon = "string",
		SetAnimationValue = "string",
		RemoveCosmetics = "string",
	}
	for _, field in ipairs(requiredFields) do
		if cosmeticData[field] == nil then
			mod.DebugPrint("[CosmeticsAPI] Error: Missing required field '" ..
				field .. "' in cosmetic data, cannot register cosmetic: " .. tostring(cosmeticData.Id or "Unknown"), 1)
			return false
		elseif type(cosmeticData[field]) ~= requiredFields[field] then
			mod.WarnIncorrectType(field, requiredFields[field], type(cosmeticData[field]),
				tostring(cosmeticData.Id or "Unknown"))
			return false
		end
	end

	-- Ensure exactly one of SetAnimationIds, ActivateIds, ActivateRoomObstacleIds is set
	local setCount = 0
	if cosmeticData.SetAnimationIds ~= nil then setCount = setCount + 1 end
	if cosmeticData.ActivateIds ~= nil then setCount = setCount + 1 end
	-- if cosmeticData.ActivateRoomObstacleIds ~= nil then setCount = setCount + 1 end
	if setCount > 1 or setCount == 0 then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: Exactly one of SetAnimationIds, ActivateIds, ActivateRoomObstacleIds must be set in cosmetic data, but you set " ..
			setCount .. ", cannot register cosmetic: " .. tostring(cosmeticData.Id or "Unknown"), 1)
		return false
	end

	-- Ensure no cosmetic with this ID already exists
	if game.WorldUpgradeData[cosmeticData.Id] ~= nil then
		mod.DebugPrint("[CosmeticsAPI] Error: A cosmetic with ID '" .. cosmeticData.Id ..
			"' already exists, cannot register duplicate cosmetic.", 1)
		return false
	end

	-- Ensure the Name and FlavorText tables only contains valid language keys
	local validLanguageCodes = {
		de = true,
		el = true,
		en = true,
		es = true,
		fr = true,
		it = true,
		ja = true,
		ko = true,
		pl = true,
		["pt-BR"] = true,
		ru = true,
		tr = true,
		uk = true,
		["zh-CN"] = true,
		["zh-TW"] = true,
	}
	for _, textField in ipairs({ "Name", "FlavorText" }) do
		for langCode, _ in pairs(cosmeticData[textField]) do
			if not validLanguageCodes[langCode] then
				mod.DebugPrint("[CosmeticsAPI] Warning: Invalid language code '" .. tostring(langCode) ..
					"' in field '" .. textField .. "' of cosmetic data: " .. tostring(cosmeticData.Id or "Unknown"), 2)
			end
		end
	end
	-- #endregion

	-- #region Id, Name, Icon, SetAnimationValue
	local newGameCosmetic = {
		-- This is NOT the DisplayName field, but the internal ID
		Name = cosmeticData.Id,
		Icon = cosmeticData.Icon,
		SetAnimationValue = cosmeticData.SetAnimationValue
	}
	-- #endregion

	-- #region InheritFrom
	if cosmeticData.InheritFrom ~= nil and type(cosmeticData) == "table" then
		newGameCosmetic.InheritFrom = cosmeticData.InheritFrom
	else
		newGameCosmetic.InheritFrom = { "DefaultCosmeticItem" }
		if cosmeticData.InheritFrom ~= nil then
			mod.WarnIncorrectType("InheritFrom", "table", type(cosmeticData.InheritFrom), cosmeticData.Id)
		end
	end
	-- #endregion

	-- #region Icon
	-- TODO: Must be added to GUI_Screens_VFX.sjson
	-- {
	-- Name = "CosmeticIcon_HecateKey"
	-- FilePath = "GUI\Screens\CosmeticIcons\cosmetic_hecateKey"
	-- Scale = 1.0
	-- }
	-- #endregion

	-- #region SetAnimationValue & AnimationScale
	-- TODO: Must create a new GUI animation for the SetAnimationValue with the correct scale
	-- {
	-- Name = "NikkelM-HadesBiomesCosmetics\Crossroads\Assets\Banner_Infernal"
	-- FilePath = "NikkelM-HadesBiomesCosmetics\Crossroads\Assets\Banner_Infernal"
	-- Scale = 3.57
	-- }
	-- #endregion

	-- #region FlavorText
	-- TODO: Must be hooked into HelpText under the new ID, respect localization input
	-- #endregion

	-- #region ShopCategory
	local legalShopCategories = {
		CosmeticsShop_Tent = true,
		CosmeticsShop_Main = true,
		CosmeticsShop_Taverna = true,
		CosmeticsShop_PreRun = true,
	}
	-- Insert the new cosmetic into the correct shop category
	-- If InsertAfterCosmeticInCategory is set, insert it after that cosmetic, otherwise at the end of the category
	if legalShopCategories[cosmeticData.ShopCategory] then
		for _, category in ipairs(game.ScreenData.CosmeticsShop.ItemCategories) do
			if category.Name == cosmeticData.ShopCategory then
				local insertIndex = #category + 1
				if cosmeticData.InsertAfterCosmeticInCategory ~= nil then
					for index, existingCosmeticId in ipairs(category) do
						if existingCosmeticId == cosmeticData.InsertAfterCosmeticInCategory then
							insertIndex = index + 1
							break
						end
					end
				end
				table.insert(category, insertIndex, newGameCosmetic.Name)
				break
			end
		end
	else
		mod.DebugPrint("[CosmeticsAPI] Error: Invalid ShopCategory '" .. tostring(cosmeticData.ShopCategory) ..
			"' in cosmetic data, cannot register cosmetic: " .. tostring(cosmeticData.Id or "Unknown"), 1)
		return false
	end
	-- #endregion

	-- #region GameStateRequirements
	if cosmeticData.GameStateRequirements ~= nil and type(cosmeticData.GameStateRequirements) == "table" then
		newGameCosmetic.GameStateRequirements = cosmeticData.GameStateRequirements
	else
		newGameCosmetic.GameStateRequirements = {}
		if cosmeticData.GameStateRequirements ~= nil then
			mod.WarnIncorrectType("GameStateRequirements", "table", type(cosmeticData.GameStateRequirements), cosmeticData.Id)
		end
	end
	-- #endregion

	-- #region Cost
	if cosmeticData.Cost ~= nil and type(cosmeticData.Cost) == "table" then
		newGameCosmetic.Cost = cosmeticData.Cost
	else
		newGameCosmetic.Cost = { CosmeticsPoints = 50 }
		if cosmeticData.Cost ~= nil then
			mod.WarnIncorrectType("Cost", "table", type(cosmeticData.Cost), cosmeticData.Id)
		end
	end
	-- #endregion

	-- #region CameraFocusId
	if cosmeticData.CameraFocusId ~= nil and type(cosmeticData.CameraFocusId) == "number" then
		newGameCosmetic.CameraFocusId = cosmeticData.CameraFocusId
	elseif cosmeticData.CameraFocusId ~= nil then
		mod.WarnIncorrectType("CameraFocusId", "number", type(cosmeticData.CameraFocusId), cosmeticData.Id)
	end
	-- #endregion

	-- #region SetAnimationIds
	if cosmeticData.SetAnimationIds ~= nil and type(cosmeticData.SetAnimationIds) == "table" then
		newGameCosmetic.SetAnimationIds = cosmeticData.SetAnimationIds
	elseif cosmeticData.SetAnimationIds ~= nil then
		mod.WarnIncorrectType("SetAnimationIds", "table", type(cosmeticData.SetAnimationIds), cosmeticData.Id)
	end
	-- #endregion

	-- #region ActivateIds
	if cosmeticData.ActivateIds ~= nil and type(cosmeticData.ActivateIds) == "table" then
		newGameCosmetic.ActivateIds = cosmeticData.ActivateIds
	elseif cosmeticData.ActivateIds ~= nil then
		mod.WarnIncorrectType("ActivateIds", "table", type(cosmeticData.ActivateIds), cosmeticData.Id)
	end
	-- #endregion

	-- #region RemoveCosmetics
	-- This cosmetic already belongs to a group - collect all cosmetics in the same group, and add our new one to their RemoveCosmetics, as well as make all of them the RemoveCosmetics of our new one
	if game.WorldUpgradeData[cosmeticData.RemoveCosmetics].RemoveCosmetics ~= nil then
		-- Our cosmetic will remove all of these cosmetics when it is equipped
		newGameCosmetic.RemoveCosmetics = game.WorldUpgradeData[cosmeticData.RemoveCosmetics].RemoveCosmetics
		-- Make sure to also remove the cosmetic provided as the group key, as it won't be in its own RemoveCosmetics list
		table.insert(newGameCosmetic.RemoveCosmetics, cosmeticData.RemoveCosmetics)
	else
		-- This cosmetic did not belong to a group yet (it was an Extra Decor cosmetic) - create a new group with just that one cosmetic and our new one
		newGameCosmetic.RemoveCosmetics = { cosmeticData.RemoveCosmetics }
	end
	-- Now, for all cosmetics in this group, add our new cosmetic to their RemoveCosmetics list
	for _, existingCosmeticId in ipairs(newGameCosmetic.RemoveCosmetics) do
		local existingCosmetic = game.WorldUpgradeData[existingCosmeticId]
		if existingCosmetic ~= nil then
			if existingCosmetic.RemoveCosmetics == nil then
				existingCosmetic.RemoveCosmetics = {}
			end
			table.insert(existingCosmetic.RemoveCosmetics, newGameCosmetic.Id)
		else
			mod.DebugPrint("[CosmeticsAPI] Warning: Could not find existing cosmetic '" ..
				existingCosmeticId ..
				"' to add new cosmetic '" ..
				newGameCosmetic.Id .. "' to its RemoveCosmetics list. This should not be able to happen.", 2)
		end
	end
	-- #endregion

	-- #region OnRevealFunctionName
	if cosmeticData.OnRevealFunctionName ~= nil and type(cosmeticData.OnRevealFunctionName) == "string" then
		newGameCosmetic.OnRevealFunctionName = cosmeticData.OnRevealFunctionName
	elseif cosmeticData.OnRevealFunctionName ~= nil then
		mod.WarnIncorrectType("OnRevealFunctionName", "string", type(cosmeticData.OnRevealFunctionName), cosmeticData.Id)
	end
	-- #endregion

	-- #region PanDuration
	if cosmeticData.PanDuration ~= nil and type(cosmeticData.PanDuration) == "number" then
		newGameCosmetic.PanDuration = cosmeticData.PanDuration
	elseif cosmeticData.PanDuration ~= nil then
		mod.WarnIncorrectType("PanDuration", "number", type(cosmeticData.PanDuration), cosmeticData.Id)
	end
	-- #endregion

	-- #region PreActivationHoldDuration
	if cosmeticData.PreActivationHoldDuration ~= nil and type(cosmeticData.PreActivationHoldDuration) == "number" then
		newGameCosmetic.PreActivationHoldDuration = cosmeticData.PreActivationHoldDuration
	elseif cosmeticData.PreActivationHoldDuration ~= nil then
		mod.WarnIncorrectType("PreActivationHoldDuration", "number", type(cosmeticData.PreActivationHoldDuration),
			cosmeticData.Id)
	end
	-- #endregion

	-- #region PostActivationHoldDuration
	if cosmeticData.PostActivationHoldDuration ~= nil and type(cosmeticData.PostActivationHoldDuration) == "number" then
		newGameCosmetic.PostActivationHoldDuration = cosmeticData.PostActivationHoldDuration
	elseif cosmeticData.PostActivationHoldDuration ~= nil then
		mod.WarnIncorrectType("PostActivationHoldDuration", "number", type(cosmeticData.PostActivationHoldDuration),
			cosmeticData.Id)
	end
	-- #endregion

	-- #region Removable
	-- Always set to true for the API, while adding completely new cosmetics is not supported
	newGameCosmetic.Removable = true
	-- #endregion

	-- #region PreRevealVoiceLines
	if cosmeticData.PreRevealVoiceLines ~= nil and type(cosmeticData.PreRevealVoiceLines) == "table" then
		newGameCosmetic.PreRevealVoiceLines = cosmeticData.PreRevealVoiceLines
	elseif cosmeticData.PreRevealVoiceLines ~= nil then
		mod.WarnIncorrectType("PreRevealVoiceLines", "table", type(cosmeticData.PreRevealVoiceLines), cosmeticData.Id)
	end
	-- #endregion

	-- #region RevealReactionVoiceLines
	if cosmeticData.RevealReactionVoiceLines ~= nil and type(cosmeticData.RevealReactionVoiceLines) == "table" then
		newGameCosmetic.RevealReactionVoiceLines = cosmeticData.RevealReactionVoiceLines
	elseif cosmeticData.RevealReactionVoiceLines ~= nil then
		mod.WarnIncorrectType("RevealReactionVoiceLines", "table", type(cosmeticData.RevealReactionVoiceLines),
			cosmeticData.Id)
	end
	-- #endregion

	-- #region CosmeticRemovedVoiceLines
	if cosmeticData.CosmeticRemovedVoiceLines ~= nil and type(cosmeticData.CosmeticRemovedVoiceLines) == "table" then
		newGameCosmetic.CosmeticRemovedVoiceLines = cosmeticData.CosmeticRemovedVoiceLines
	elseif cosmeticData.CosmeticRemovedVoiceLines ~= nil then
		mod.WarnIncorrectType("CosmeticRemovedVoiceLines", "table", type(cosmeticData.CosmeticRemovedVoiceLines),
			cosmeticData.Id)
	end
	-- #endregion

	-- #region CosmeticReAddedVoiceLines
	if cosmeticData.CosmeticReAddedVoiceLines ~= nil and type(cosmeticData.CosmeticReAddedVoiceLines) == "table" then
		newGameCosmetic.CosmeticReAddedVoiceLines = cosmeticData.CosmeticReAddedVoiceLines
	elseif cosmeticData.CosmeticReAddedVoiceLines ~= nil then
		mod.WarnIncorrectType("CosmeticReAddedVoiceLines", "table", type(cosmeticData.CosmeticReAddedVoiceLines),
			cosmeticData.Id)
	end
	-- #endregion

	-- #region ID/Add to WorldUpgradeData - Must be done last
	-- Equivalent to what ProcessDataStore would do
	game.WorldUpgradeData[cosmeticData.Id] = newGameCosmetic
	game.ProcessDataInheritance(game.WorldUpgradeData[cosmeticData.Id], game.WorldUpgradeData)
	game.ProcessSimpleExtractValues(game.WorldUpgradeData[cosmeticData.Id])
	-- #endregion

	mod.DebugPrint("[CosmeticsAPI] Successfully registered new cosmetic: " .. cosmeticData.Id, 3)
	return true
end
