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
		Description = "table",
		FlavorText = "table",
		ShopCategory = "string",
		IconPath = "string",
		CosmeticAnimationPath = "string",
		CosmeticsGroup = "string",
	}
	for fieldName, fieldType in pairs(requiredFields) do
		if cosmeticData[fieldName] == nil then
			mod.DebugPrint("[CosmeticsAPI] Error: Missing required field '" ..
				fieldName .. "' in cosmetic data, cannot register cosmetic: " .. tostring(cosmeticData.Id or "Unknown"), 1)
			return false
		elseif type(cosmeticData[fieldName]) ~= fieldType then
			mod.DebugPrint("[CosmeticsAPI] Error: Field '" .. fieldName .. "' has incorrect type '" ..
				type(cosmeticData[fieldName]) .. "' (expected '" .. fieldType ..
				"') in cosmetic data, cannot register cosmetic: " .. tostring(cosmeticData.Id or "Unknown"), 1)
			return false
		end
	end

	-- Ensure no cosmetic with this ID already exists
	if game.WorldUpgradeData[cosmeticData.Id] ~= nil then
		mod.DebugPrint("[CosmeticsAPI] Error: A cosmetic with ID '" .. cosmeticData.Id ..
			"' already exists, cannot register duplicate cosmetic. Make sure to prefix your cosmetic with you \"_PLUGIN.guid\"!",
			1)
		return false
	end

	-- Ensure the Name and FlavorText tables only contains valid language keys, and contains at least the english entry
	local hasEnglishName = false
	local hasEnglishDescription = false
	local hasEnglishFlavorText = false
	for _, textField in ipairs({ "Name", "Description", "FlavorText" }) do
		for langCode, _ in pairs(cosmeticData[textField]) do
			if langCode == "en" then
				if textField == "Name" then
					hasEnglishName = true
				elseif textField == "Description" then
					hasEnglishDescription = true
				else
					hasEnglishFlavorText = true
				end
			end
			if not mod.ValidLanguageCodes[langCode] then
				mod.DebugPrint("[CosmeticsAPI] Warning: Invalid language code '" .. tostring(langCode) ..
					"' in field '" .. textField .. "' of cosmetic data: " .. tostring(cosmeticData.Id or "Unknown"), 2)
			end
		end
	end
	if not hasEnglishName then
		mod.DebugPrint("[CosmeticsAPI] Warning: Missing default English ('en') entry in Name field of cosmetic data: " ..
			tostring(cosmeticData.Id or "Unknown"), 2)
	end
	if not hasEnglishDescription then
		mod.DebugPrint(
			"[CosmeticsAPI] Warning: Missing default English ('en') entry in Description field of cosmetic data: " ..
			tostring(cosmeticData.Id or "Unknown"), 2)
	end
	if not hasEnglishFlavorText then
		mod.DebugPrint(
			"[CosmeticsAPI] Warning: Missing default English ('en') entry in FlavorText field of cosmetic data: " ..
			tostring(cosmeticData.Id or "Unknown"), 2)
	end
	-- #endregion

	-- #region Name (Id), (Icon) IconPath, SetAnimationValue (CosmeticAnimationPath)
	local newGameCosmetic = {
		-- This is NOT the DisplayName field, but the internal ID
		Name = cosmeticData.Id,
		Icon = cosmeticData.Id .. "_Icon",
		SetAnimationValue = cosmeticData.Id .. "_Animation",
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

	-- #region ShopCategory
	local legalShopCategories = {
		CosmeticsShop_Tent = true,
		CosmeticsShop_Main = true,
		CosmeticsShop_Taverna = true,
		CosmeticsShop_PreRun = true,
	}
	-- Insert the new cosmetic into the correct shop category
	-- If InsertAfterCosmetic is set, insert it after that cosmetic, otherwise at the end of the category
	if legalShopCategories[cosmeticData.ShopCategory] then
		for _, category in ipairs(game.ScreenData.CosmeticsShop.ItemCategories) do
			if category.Name == cosmeticData.ShopCategory then
				local insertIndex = #category + 1
				local foundCosmeticToInsertAfter = false
				if cosmeticData.InsertAfterCosmetic ~= nil then
					for index, existingCosmeticId in ipairs(category) do
						if existingCosmeticId == cosmeticData.InsertAfterCosmetic then
							foundCosmeticToInsertAfter = true
							insertIndex = index + 1
							break
						end
					end
					if not foundCosmeticToInsertAfter then
						mod.DebugPrint("[CosmeticsAPI] Warning: Could not find InsertAfterCosmetic '" ..
							cosmeticData.InsertAfterCosmetic ..
							"' in category '" .. cosmeticData.ShopCategory ..
							"'. Inserting new cosmetic at the end of the category instead. Cosmetic ID: " ..
							tostring(cosmeticData.Id or "Unknown"), 2)
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

	-- #region AlwaysRevealImmediately
	if cosmeticData.AlwaysRevealImmediately ~= nil and type(cosmeticData.AlwaysRevealImmediately) == "boolean" then
		newGameCosmetic.AlwaysRevealImmediately = cosmeticData.AlwaysRevealImmediately
	elseif cosmeticData.AlwaysRevealImmediately ~= nil then
		mod.WarnIncorrectType("AlwaysRevealImmediately", "boolean", type(cosmeticData.AlwaysRevealImmediately),
			cosmeticData.Id)
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

	-- #region DeactivateIds
	if cosmeticData.DeactivateIds ~= nil and type(cosmeticData.DeactivateIds) == "table" then
		newGameCosmetic.DeactivateIds = cosmeticData.DeactivateIds
	elseif cosmeticData.DeactivateIds ~= nil then
		mod.WarnIncorrectType("DeactivateIds", "table", type(cosmeticData.DeactivateIds), cosmeticData.Id)
	end
	-- #endregion

	-- #region CosmeticsGroup
	-- Validate the cosmetic that the group points to exists
	if game.WorldUpgradeData[cosmeticData.CosmeticsGroup] == nil then
		mod.DebugPrint("[CosmeticsAPI] Error: CosmeticsGroup '" .. cosmeticData.CosmeticsGroup ..
			"' does not point to an existing cosmetic, cannot register cosmetic: " ..
			tostring(cosmeticData.Id or "Unknown"), 1)
		return false
	end
	-- This cosmetic already belongs to a group - collect all cosmetics in the same group, and add our new one to their RemoveCosmetics, as well as make all of them the RemoveCosmetics of our new one
	if game.WorldUpgradeData[cosmeticData.CosmeticsGroup].RemoveCosmetics ~= nil then
		-- Our cosmetic will remove all of these cosmetics when it is equipped
		newGameCosmetic.RemoveCosmetics = game.DeepCopyTable(game.WorldUpgradeData[cosmeticData.CosmeticsGroup]
			.RemoveCosmetics)
		-- Make sure to also remove the cosmetic provided as the group key when equipping our new cosmetic, as it won't be in its own RemoveCosmetics list that we just copied
		table.insert(newGameCosmetic.RemoveCosmetics, cosmeticData.CosmeticsGroup)
	else
		-- This cosmetic did not belong to a group yet (it was an Extra Decor cosmetic) - create a new group with just that one cosmetic and our new one
		newGameCosmetic.RemoveCosmetics = { cosmeticData.CosmeticsGroup }

		-- We also need to set a SetAnimationValue for the original cosmetic if it doesn't exist yet, otherwise unequipping the new cosmetic will not replace it with the base cosmetic animation
		-- Some cosmetics also need additional properties overridden, so we keep a list of known required overrides
		if not game.WorldUpgradeData[cosmeticData.CosmeticsGroup].SetAnimationValue then
			if mod.KnownExtraDecorBaseAnimations[cosmeticData.CosmeticsGroup] then
				for property, value in pairs(mod.KnownExtraDecorBaseAnimations[cosmeticData.CosmeticsGroup]) do
					game.WorldUpgradeData[cosmeticData.CosmeticsGroup][property] = value
				end
			else
				mod.DebugPrint(
					"[CosmeticsAPI] Error: The cosmetic to which you are adding an alternate version (CosmeticsGroup key): '" ..
					cosmeticData.CosmeticsGroup ..
					"' is an \"Extra Decor\" and does not have a SetAnimationValue defined in vanilla Hades II. The Cosmetics API keeps a list of known base animations for Extra Decor cosmetics, but this cosmetic is not on it. The base animation (and potential other required properties) must be added to the API before you can add an alternative version of the cosmetic. Please find the base animation and open a PR to add it to the \"mod.KnownExtraDecorBaseAnimations\" table in the \"Scripts/Utils.lua\" file on https://github.com/NikkelM/Hades-II-CosmeticsAPI",
					1)
			end
		end
	end

	-- Now, for all cosmetics in this group, add our new cosmetic to their RemoveCosmetics list
	for _, existingCosmeticId in ipairs(newGameCosmetic.RemoveCosmetics) do
		-- Skip adding ourselves to our own RemoveCosmetics list
		if existingCosmeticId ~= newGameCosmetic.Name then
			local existingCosmetic = game.WorldUpgradeData[existingCosmeticId]
			if existingCosmetic ~= nil then
				if existingCosmetic.RemoveCosmetics == nil then
					existingCosmetic.RemoveCosmetics = {}
				end
				-- Remember, the Name key is the Id of the cosmetic
				table.insert(existingCosmetic.RemoveCosmetics, newGameCosmetic.Name)
			else
				mod.DebugPrint("[CosmeticsAPI] Warning: Could not find existing cosmetic '" ..
					existingCosmeticId ..
					"' to add new cosmetic '" ..
					newGameCosmetic.Name .. "' to its RemoveCosmetics list. This should not be able to happen.", 2)
			end
		end
	end
	-- #endregion

	-- #region ActivateFunctionName
	if cosmeticData.ActivateFunctionName ~= nil and type(cosmeticData.ActivateFunctionName) == "string" then
		newGameCosmetic.ActivateFunctionName = cosmeticData.ActivateFunctionName
	elseif cosmeticData.ActivateFunctionName ~= nil then
		mod.WarnIncorrectType("ActivateFunctionName", "string", type(cosmeticData.ActivateFunctionName), cosmeticData.Id)
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

	-- #region CosmeticReEquipVoiceLines
	if cosmeticData.CosmeticReEquipVoiceLines ~= nil and type(cosmeticData.CosmeticReEquipVoiceLines) == "table" then
		newGameCosmetic.CosmeticReEquipVoiceLines = cosmeticData.CosmeticReEquipVoiceLines
	elseif cosmeticData.CosmeticReEquipVoiceLines ~= nil then
		mod.WarnIncorrectType("CosmeticReEquipVoiceLines", "table", type(cosmeticData.CosmeticReEquipVoiceLines),
			cosmeticData.Id)
	end
	-- #endregion

	-- #Cauldron-specifc: IsCauldron and CauldronLidAnimationPath
	if cosmeticData.IsCauldron ~= nil then
		if type(cosmeticData.IsCauldron) == "boolean" then		
			if cosmeticData.IsCauldron then
				-- If this is a cauldron, CauldronLidAnimationPath is required
				if cosmeticData.CauldronLidAnimationPath ~= nil and type(cosmeticData.CauldronLidAnimationPath) == "string" then
					mod.RegisteredCauldrons[cosmeticData.Id] = cosmeticData.CauldronLidAnimationPath
					-- In case the user forgot to set the ActiveFunctionName, set it for them
					-- But don't overwrite it if they set it to something custom
					if newGameCosmetic.ActivateFunctionName == nil then
						newGameCosmetic.ActivateFunctionName = "ApplyCauldronCookTopGraphic"
					end
				else
					mod.DebugPrint(
						"[CosmeticsAPI] Error: CauldronLidAnimationPath is required for cauldron cosmetics, cannot register cosmetic: " ..
						tostring(cosmeticData.Id or "Unknown"), 1)
					return false
				end
			end
		else
			mod.WarnIncorrectType("IsCauldron", "boolean", type(cosmeticData.IsCauldron), cosmeticData.Id)
		end
	elseif cosmeticData.CauldronLidAnimationPath ~= nil then
		mod.DebugPrint(
			"[CosmeticsAPI] Warning: CauldronLidAnimationPath is set but IsCauldron is not true, ignoring CauldronLidAnimationPath for cosmetic: " ..
			tostring(cosmeticData.Id or "Unknown"), 2)
	end
	-- #endregion

	-- #region ID/Add to WorldUpgradeData - Must be done last
	-- Equivalent to what ProcessDataStore would do
	game.WorldUpgradeData[cosmeticData.Id] = newGameCosmetic
	game.ProcessDataInheritance(game.WorldUpgradeData[cosmeticData.Id], game.WorldUpgradeData)
	game.ProcessSimpleExtractValues(game.WorldUpgradeData[cosmeticData.Id])
	-- #endregion

	-- #region Text Sjson Data
	-- This is used in SjsonHooks.lua to add texts to HelpText.sjson files
	local newGameCosmeticSjsonTextData = {
		Id = cosmeticData.Id,
		Name = cosmeticData.Name,
		Description = cosmeticData.Description,
		FlavorText = cosmeticData.FlavorText,
	}
	table.insert(mod.AddedCosmeticSjsonTextData, newGameCosmeticSjsonTextData)
	-- #endregion

	-- #region Animation & Icon Sjson Data
	-- Field validation for those we haven't validated already above
	if cosmeticData.IconScale ~= nil and type(cosmeticData.IconScale) ~= "number" then
		mod.WarnIncorrectType("IconScale", "number", type(cosmeticData.IconScale), cosmeticData.Id)
	end
	if cosmeticData.IconOffsetX ~= nil and type(cosmeticData.IconOffsetX) ~= "number" then
		mod.WarnIncorrectType("IconOffsetX", "number", type(cosmeticData.IconOffsetX), cosmeticData.Id)
	end
	if cosmeticData.IconOffsetY ~= nil and type(cosmeticData.IconOffsetY) ~= "number" then
		mod.WarnIncorrectType("IconOffsetY", "number", type(cosmeticData.IconOffsetY), cosmeticData.Id)
	end
	if cosmeticData.AnimationScale ~= nil and type(cosmeticData.AnimationScale) ~= "number" then
		mod.WarnIncorrectType("AnimationScale", "number", type(cosmeticData.AnimationScale), cosmeticData.Id)
	end
	if cosmeticData.AnimationInheritFrom ~= nil and type(cosmeticData.AnimationInheritFrom) ~= "string" then
		mod.WarnIncorrectType("AnimationInheritFrom", "string", type(cosmeticData.AnimationInheritFrom), cosmeticData.Id)
	end
	if cosmeticData.AnimationOffsetX ~= nil and type(cosmeticData.AnimationOffsetX) ~= "number" then
		mod.WarnIncorrectType("AnimationOffsetX", "number", type(cosmeticData.AnimationOffsetX), cosmeticData.Id)
	end
	if cosmeticData.AnimationOffsetY ~= nil and type(cosmeticData.AnimationOffsetY) ~= "number" then
		mod.WarnIncorrectType("AnimationOffsetY", "number", type(cosmeticData.AnimationOffsetY), cosmeticData.Id)
	end

	-- This is used in SjsonHooks.lua to add the animation and Icon to GUI_Screens_VFX.sjson
	local newGameCosmeticSjsonAnimationData = {
		Id = cosmeticData.Id,
		-- The Icon is made up of <cosmeticData.Id .. "_Icon">
		IconId = newGameCosmetic.Icon,
		IconPath = cosmeticData.IconPath,
		IconScale = cosmeticData.IconScale or 1.0,
		IconOffsetX = cosmeticData.IconOffsetX or 0,
		IconOffsetY = cosmeticData.IconOffsetY or 0,
		-- The Animation value is made up of <cosmeticData.Id .. "_Animation">
		AnimationId = newGameCosmetic.SetAnimationValue,
		AnimationInheritFrom = cosmeticData.AnimationInheritFrom,
		CosmeticAnimationPath = cosmeticData.CosmeticAnimationPath,
		AnimationScale = cosmeticData.AnimationScale or 1.0,
		AnimationOffsetX = cosmeticData.AnimationOffsetX or 0,
		AnimationOffsetY = cosmeticData.AnimationOffsetY or 0,
	}
	table.insert(mod.AddedCosmeticSjsonAnimationData, newGameCosmeticSjsonAnimationData)
	-- #endregion

	mod.DebugPrint("[CosmeticsAPI] Successfully registered new cosmetic: " .. cosmeticData.Id, 3)
	return true
end
