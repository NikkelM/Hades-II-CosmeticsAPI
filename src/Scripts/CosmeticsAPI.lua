---@meta NikkelM-Cosmetics_API
-- Can add new versions of existing Alt Decor, or alternate versions of Extra Decor cosmetics
-- Can create new cosmetics groups for existing obstacles
-- After a cosmetic mod is uninstalled, the API re-equips an owned cosmetic in if one from that mod was equipped

---@param cosmeticData CosmeticBaseData
---@return boolean valid
function mod.ValidateCosmeticBaseData(cosmeticData)
	-- #region Basic Input Validation
	if type(cosmeticData) ~= "table" then
		mod.DebugPrint("[CosmeticsAPI] Error: Cosmetic registration expects cosmeticData to be a table.", 1)
		return false
	end

	-- Ensure required fields exist with correct types
	local requiredFields = {
		Id = "string",
		Name = "table",
		Description = "table",
		FlavorText = "table",
		ShopCategory = "string",
		IconPath = "string",
		CosmeticAnimationPath = "string",
	}

	for fieldName, fieldType in pairs(requiredFields) do
		if cosmeticData[fieldName] == nil then
			mod.DebugPrint("[CosmeticsAPI] Error: Missing required field '" ..
				fieldName .. "' in cosmetic data, cannot register cosmetic: " .. tostring(cosmeticData.Id or "Unknown"), 1)
			return false
		elseif type(cosmeticData[fieldName]) ~= fieldType then
			mod.ErrorIncorrectType(fieldName, fieldType, type(cosmeticData[fieldName]), cosmeticData.Id or "Unknown")
			return false
		end
	end

	if cosmeticData.Id == "" then
		mod.DebugPrint("[CosmeticsAPI] Error: Id must not be an empty string, cannot register cosmetic.", 1)
		return false
	end

	-- Ensure no cosmetic with this ID already exists
	if game.WorldUpgradeData[cosmeticData.Id] ~= nil then
		mod.DebugPrint("[CosmeticsAPI] Error: A cosmetic with ID '" .. cosmeticData.Id ..
			"' already exists, cannot register duplicate cosmetic. Make sure to prefix your cosmetic with your \"_PLUGIN.guid\"!",
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
	return true
end

---@param cosmeticData CosmeticData
---@return boolean valid
function mod.ValidateCosmeticData(cosmeticData)
	if not mod.ValidateCosmeticBaseData(cosmeticData) then
		return false
	end

	if cosmeticData.IsCauldron == true and type(cosmeticData.CauldronLidAnimationPath) ~= "string" then
		mod.ErrorIncorrectType("CauldronLidAnimationPath", "string", type(cosmeticData.CauldronLidAnimationPath),
			cosmeticData.Id)
		return false
	end

	local cosmeticsGroup = cosmeticData.CosmeticsGroup
	local createCosmeticsGroup = cosmeticData.CreateCosmeticsGroup == true
	if createCosmeticsGroup then
		if cosmeticsGroup ~= nil then
			mod.DebugPrint(
				"[CosmeticsAPI] Error: Omit CosmeticsGroup when CreateCosmeticsGroup is true. The cosmetic's Id is the group anchor: " ..
				cosmeticData.Id, 1)
			return false
		end
	elseif type(cosmeticsGroup) ~= "string" then
		mod.ErrorIncorrectType("CosmeticsGroup", "string", type(cosmeticsGroup), cosmeticData.Id)
		return false
	elseif cosmeticsGroup == "" then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: CosmeticsGroup must not be an empty string in cosmetic data, cannot register cosmetic: " ..
			cosmeticData.Id, 1)
		return false
	end

	if type(cosmeticData.RotateOnly) == "boolean" and not createCosmeticsGroup then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: RotateOnly can only be set when creating a cosmetics group, cannot register cosmetic: " ..
			cosmeticData.Id, 1)
		return false
	end

	if createCosmeticsGroup and cosmeticData.RotateOnly == true and cosmeticData.AutoUnlock ~= true then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: Creating a RotateOnly cosmetics group requires AutoUnlock = true on the cosmetic that has CreateCosmeticsGroup, cannot register cosmetic: " ..
			cosmeticData.Id, 1)
		return false
	end

	local groupData = game.WorldUpgradeData[cosmeticsGroup]
	if not createCosmeticsGroup and groupData == nil then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: CosmeticsGroup '" ..
			cosmeticsGroup ..
			"' does not point to an existing cosmetic group, cannot register cosmetic: " ..
			tostring(cosmeticData.Id or "Unknown"), 1)
		return false
	end

	local rotateOnly
	if createCosmeticsGroup then
		rotateOnly = cosmeticData.RotateOnly == true
	else
		rotateOnly = groupData.RotateOnly == true
	end
	local inheritedGameCosmetic = {
		Name = cosmeticData.Id,
		InheritFrom = { "DefaultCosmeticItem" },
	}
	if type(cosmeticData.InheritFrom) == "table" then
		inheritedGameCosmetic.InheritFrom = game.DeepCopyTable(cosmeticData.InheritFrom)
	end
	if type(cosmeticData.SetAnimationIds) == "table" then
		inheritedGameCosmetic.SetAnimationIds = game.DeepCopyTable(cosmeticData.SetAnimationIds)
	end
	game.ProcessDataInheritance(inheritedGameCosmetic, game.WorldUpgradeData)
	if inheritedGameCosmetic.SetAnimationIds ~= nil and not rotateOnly then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: Cosmetics using SetAnimationIds require a RotateOnly cosmetics group, cannot register cosmetic: " ..
			cosmeticData.Id, 1)
		return false
	end

	return true
end

---@param cosmeticData CosmeticData|ChthonicChidData
---@return table|nil newGameCosmetic
function mod.CreateCosmeticData(cosmeticData)
	-- #region Name (Id), (Icon) IconPath, SetAnimationValue (CosmeticAnimationPath)
	local newGameCosmetic = {
		-- This is NOT the DisplayName field, but the internal ID
		Name = cosmeticData.Id,
		Icon = cosmeticData.Id .. "_Icon",
		SetAnimationValue = cosmeticData.Id .. "_Animation",
	}
	-- #endregion

	-- #region InheritFrom
	if type(cosmeticData.InheritFrom) == "table" then
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
				if type(cosmeticData.InsertAfterCosmetic) == "string" then
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
				elseif cosmeticData.InsertAfterCosmetic ~= nil then
					mod.WarnIncorrectType("InsertAfterCosmetic", "string", type(cosmeticData.InsertAfterCosmetic),
						cosmeticData.Id)
				end
				table.insert(category, insertIndex, newGameCosmetic.Name)
				break
			end
		end
	else
		mod.DebugPrint("[CosmeticsAPI] Error: Invalid ShopCategory '" .. tostring(cosmeticData.ShopCategory) ..
			"' in cosmetic data, cannot register cosmetic: " .. tostring(cosmeticData.Id or "Unknown"), 1)
		return nil
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

	-- #region ToggleCollision
	if cosmeticData.ToggleCollision ~= nil and type(cosmeticData.ToggleCollision) == "boolean" then
		newGameCosmetic.ToggleCollision = cosmeticData.ToggleCollision
	elseif cosmeticData.ToggleCollision ~= nil then
		mod.WarnIncorrectType("ToggleCollision", "boolean", type(cosmeticData.ToggleCollision), cosmeticData.Id)
	end
	-- #endregion

	-- #region Activation callback
	if cosmeticData.ActivateFunctionName ~= nil and type(cosmeticData.ActivateFunctionName) == "string" then
		newGameCosmetic.ActivateFunctionName = cosmeticData.ActivateFunctionName
	elseif cosmeticData.ActivateFunctionName ~= nil then
		mod.WarnIncorrectType("ActivateFunctionName", "string", type(cosmeticData.ActivateFunctionName), cosmeticData.Id)
	end
	if type(cosmeticData.ActivateFunctionArgs) == "table" then
		newGameCosmetic.ActivateFunctionArgs = cosmeticData.ActivateFunctionArgs
	elseif cosmeticData.ActivateFunctionArgs ~= nil then
		mod.WarnIncorrectType("ActivateFunctionArgs", "table", type(cosmeticData.ActivateFunctionArgs), cosmeticData.Id)
	end
	-- #endregion

	-- #region Reveal callback
	if cosmeticData.OnRevealFunctionName ~= nil and type(cosmeticData.OnRevealFunctionName) == "string" then
		newGameCosmetic.OnRevealFunctionName = cosmeticData.OnRevealFunctionName
	elseif cosmeticData.OnRevealFunctionName ~= nil then
		mod.WarnIncorrectType("OnRevealFunctionName", "string", type(cosmeticData.OnRevealFunctionName), cosmeticData.Id)
	end
	if type(cosmeticData.OnRevealFunctionArgs) == "table" then
		newGameCosmetic.OnRevealFunctionArgs = cosmeticData.OnRevealFunctionArgs
	elseif cosmeticData.OnRevealFunctionArgs ~= nil then
		mod.WarnIncorrectType("OnRevealFunctionArgs", "table", type(cosmeticData.OnRevealFunctionArgs), cosmeticData.Id)
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
	else
		local cosmeticReactionMelinoeVoicelines = game.DeepCopyTable(game.GlobalVoiceLines.PositiveReactionVoiceLines)
		table.insert(cosmeticReactionMelinoeVoicelines,
			{ Cue = "/VO/Melinoe_1403", Text = "No harm in having just a bit of luxury..." })
		table.insert(cosmeticReactionMelinoeVoicelines, {
			Cue = "/VO/Melinoe_1401",
			Text = "Always wanted something like this in the tent...",
			GameStateRequirements = {
				{
					PathFromSource = true,
					Path = { "DefaultCategoryIndex" },
					Comparison = "==",
					Value = 1,
				},
			}
		})
		table.insert(cosmeticReactionMelinoeVoicelines, {
			Cue = "/VO/Melinoe_1404",
			Text = "That ought to raise the Shades' morale a bit...",
			GameStateRequirements = {
				{
					PathFromSource = true,
					Path = { "DefaultCategoryIndex" },
					Comparison = "!=",
					Value = 1,
				},
			}
		})
		-- Set default values ourselves, to prevent the only three default Melinoe voicelines from playing for each one
		newGameCosmetic.RevealReactionVoiceLines = {
			cosmeticReactionMelinoeVoicelines,
			{
				RandomRemaining = true,
				BreakIfPlayed = true,
				SuccessiveChanceToPlay = 0.75,
				ObjectType = "NPC_Skelly_01",
				Queue = "Always",
				{ Cue = "/VO/Skelly_0118", Text = "The path to perfection!" },
				{ Cue = "/VO/Skelly_0119", Text = "The path to perfection..." },
				{ Cue = "/VO/Skelly_0016", Text = "A fine choice." },
				{ Cue = "/VO/Skelly_0129", Text = "A fine selection!" },
				{ Cue = "/VO/Skelly_0130", Text = "A fine selection." },
				{ Cue = "/VO/Skelly_0063", Text = "Excellent!" },
			},
			{ GlobalVoiceLines = "DoraCosmeticReactionVoiceLines" },
		}
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
	return newGameCosmetic
end

---Registers a cosmetic, either as a variant in an existing group or as the creator of a new group.
---@param cosmeticData CosmeticData The input data for the new cosmetic item.
---@return boolean successfullyRegistered True if the cosmetic was successfully registered, false otherwise.
public.RegisterCosmetic = function(cosmeticData)
	if not mod.ValidateCosmeticData(cosmeticData) then
		return false
	end

	for _, fieldName in ipairs({ "CreateCosmeticsGroup", "AutoUnlock", "RotateOnly", "IsCauldron" }) do
		if cosmeticData[fieldName] ~= nil and type(cosmeticData[fieldName]) ~= "boolean" then
			mod.WarnIncorrectType(fieldName, "boolean", type(cosmeticData[fieldName]), cosmeticData.Id)
		end
	end

	-- #region CosmeticsGroup
	local cosmeticsGroup = cosmeticData.CosmeticsGroup
	local createCosmeticsGroup = cosmeticData.CreateCosmeticsGroup == true
	local groupData = game.WorldUpgradeData[cosmeticsGroup]
	local rotateOnly
	if createCosmeticsGroup then
		rotateOnly = cosmeticData.RotateOnly == true
	else
		rotateOnly = groupData.RotateOnly == true
	end

	local newGameCosmetic = mod.CreateCosmeticData(cosmeticData)
	if newGameCosmetic == nil then
		return false
	end
	newGameCosmetic.RotateOnly = rotateOnly

	if createCosmeticsGroup then
		newGameCosmetic.RemoveCosmetics = {}
		mod.DebugPrint("[CosmeticsAPI] Creating new cosmetics group from cosmetic '" .. cosmeticData.Id .. "'.", 3)
	elseif groupData.RemoveCosmetics ~= nil then
		-- Copy the anchor's sibling list so equipping the new cosmetic removes the other group members
		newGameCosmetic.RemoveCosmetics = game.DeepCopyTable(groupData.RemoveCosmetics)
		-- Make sure to also remove the cosmetic provided as the group key when equipping our new cosmetic, as it won't be in its own RemoveCosmetics list that we just copied
		table.insert(newGameCosmetic.RemoveCosmetics, cosmeticsGroup)
	else
		-- This cosmetic did not belong to a group yet (it was an Extra Decor cosmetic) - create a new group with just that one cosmetic and our new one
		newGameCosmetic.RemoveCosmetics = { cosmeticsGroup }

		-- We also need to set a SetAnimationValue for the original cosmetic if it doesn't exist yet, otherwise unequipping the new cosmetic will not replace it with the base cosmetic animation
		-- Some cosmetics also need additional properties overridden, so we keep a list of known required overrides
		if not groupData.SetAnimationValue then
			if mod.KnownExtraDecorBaseAnimations[cosmeticsGroup] then
				for property, value in pairs(mod.KnownExtraDecorBaseAnimations[cosmeticsGroup]) do
					groupData[property] = value
				end
			else
				mod.DebugPrint(
					"[CosmeticsAPI] Error: The cosmetic to which you are adding an alternate version (CosmeticsGroup key): '" ..
					cosmeticsGroup ..
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

	-- #Cauldron-specifc: IsCauldron and CauldronLidAnimationPath
	if cosmeticData.IsCauldron == true then
		mod.RegisteredCauldrons[cosmeticData.Id] = cosmeticData.CauldronLidAnimationPath
		-- In case the user forgot to set the ActiveFunctionName, set it for them
		-- But don't overwrite it if they set it to something custom
		if newGameCosmetic.ActivateFunctionName == nil then
			newGameCosmetic.ActivateFunctionName = "ApplyCauldronCookTopGraphic"
		end
	elseif cosmeticData.CauldronLidAnimationPath ~= nil then
		if type(cosmeticData.CauldronLidAnimationPath) ~= "string" then
			mod.WarnIncorrectType("CauldronLidAnimationPath", "string", type(cosmeticData.CauldronLidAnimationPath),
				cosmeticData.Id)
		elseif cosmeticData.IsCauldron == nil then
			mod.DebugPrint(
				"[CosmeticsAPI] Warning: CauldronLidAnimationPath is set but IsCauldron is not true, ignoring CauldronLidAnimationPath for cosmetic: " ..
				tostring(cosmeticData.Id or "Unknown"), 2)
		end
	end
	-- #endregion

	local successfullyRegistered = mod.FinalizeCosmeticRegistration(cosmeticData, newGameCosmetic)
	if not successfullyRegistered then
		return false
	end

	if cosmeticData.AutoUnlock == true then
		table.insert(game.GameData.WorldUpgradeAutomaticUnlocks, cosmeticData.Id)
	end

	return true
end

---@param cosmeticData CosmeticBaseData
---@param newGameCosmetic table
---@param defaultAnimationScale number|nil
---@return boolean successfullyRegistered
function mod.FinalizeCosmeticRegistration(cosmeticData, newGameCosmetic, defaultAnimationScale)
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
		AnimationScale = cosmeticData.AnimationScale or defaultAnimationScale or 1.0,
		AnimationOffsetX = cosmeticData.AnimationOffsetX or 0,
		AnimationOffsetY = cosmeticData.AnimationOffsetY or 0,
	}
	table.insert(mod.AddedCosmeticSjsonAnimationData, newGameCosmeticSjsonAnimationData)
	-- #endregion

	mod.DebugPrint("[CosmeticsAPI] Successfully registered new cosmetic: " .. cosmeticData.Id, 3)
	return true
end

---Registers one or more .pkg package files that contain the textures for cosmetics that are added to the Crossroads (including the Training Grounds).
---These packages will be automatically loaded by the CosmeticsAPI when entering the Crossroads.
---The .pkg files must be placed in your mod's `plugins_data` folder.
---@param packageNamesArray table A list of package names (table of strings) to register. Do not include the `.pkg` extension.
---@return boolean successfullyRegistered True if at least one package was successfully registered, false otherwise.
public.RegisterCrossroadsPackages = function(packageNamesArray)
	if type(packageNamesArray) ~= "table" then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: RegisterCrossroadsPackages expects a table of strings, got '" ..
			type(packageNamesArray) .. "'.", 1)
		return false
	end

	local registeredAny = false
	for _, name in ipairs(packageNamesArray) do
		if type(name) ~= "string" then
			mod.DebugPrint(
				"[CosmeticsAPI] Warning: Skipping non-string package name of type '" ..
				type(name) .. "' in RegisterCrossroadsPackages.", 2)
		elseif name == "" then
			mod.DebugPrint("[CosmeticsAPI] Warning: Skipping empty package name in RegisterCrossroadsPackages.", 2)
		else
			local alreadyRegistered = false
			for _, existing in ipairs(mod.RegisteredCrossroadsPackages) do
				if existing == name then
					alreadyRegistered = true
					break
				end
			end
			if not alreadyRegistered then
				table.insert(mod.RegisteredCrossroadsPackages, name)
				mod.DebugPrint("[CosmeticsAPI] Successfully registered new Crossroads package: " .. name, 3)
			end
			registeredAny = true
		end
	end

	return registeredAny
end
