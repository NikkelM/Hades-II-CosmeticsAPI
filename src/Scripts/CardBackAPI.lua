---@meta NikkelM-Cosmetics_API
-- Card Back Registration API
-- Allows mods to register new card back packs and the card backs belonging to them.
-- Packs appear in the Training Grounds cosmetics shop.
-- Individual card backs are unlocked by purchasing their associated pack.

-- Deterministic TextureNum allocation based on the card back's string ID.
-- Uses a simple string hash mapped to range 100+, ensuring the same ID always produces the same TextureNum regardless of mod load order.
-- Collisions are resolved by incrementing.
local function allocateTextureNum(cardBackId)
	local hash = 0
	for i = 1, #cardBackId do
		hash = (hash * 31 + string.byte(cardBackId, i)) % 100000
	end
	local textureNum = 100 + (hash % 99900)

	-- Resolve collisions with already-allocated TextureNums
	while mod.ActiveCardBackTextureNums[textureNum] do
		textureNum = textureNum + 1
	end
	return textureNum
end

---Registers a new card back pack to be added to the cosmetics shop in the Training Grounds.
---A pack is a cosmetic item that, when purchased, unlocks all card backs registered for it via `RegisterCardBack`.
---Must be called before registering any card backs that belong to this pack.
---@param packData CardBackPackData The input data for the new card back pack.
---@return boolean successfullyRegistered True if the pack was successfully registered, false otherwise.
public.RegisterCardBackPack = function(packData)
	-- #region Input Validation
	local requiredFields = {
		Id = "string",
		Name = "table",
		Description = "table",
		FlavorText = "table",
		IconPath = "string",
	}
	for fieldName, fieldType in pairs(requiredFields) do
		if packData[fieldName] == nil then
			mod.DebugPrint("[CosmeticsAPI] Error: Missing required field '" .. fieldName
				.. "' in card back pack data, cannot register pack: " .. tostring(packData.Id or "Unknown"), 1)
			return false
		elseif type(packData[fieldName]) ~= fieldType then
			mod.DebugPrint("[CosmeticsAPI] Error: Field '" .. fieldName .. "' has incorrect type '"
				.. type(packData[fieldName]) .. "' (expected '" .. fieldType
				.. "') in card back pack data, cannot register pack: " .. tostring(packData.Id or "Unknown"), 1)
			return false
		end
	end

	-- Ensure no WorldUpgradeData with this ID already exists
	if game.WorldUpgradeData[packData.Id] ~= nil then
		mod.DebugPrint("[CosmeticsAPI] Error: A WorldUpgradeData entry with ID '" .. packData.Id
			.. "' already exists, cannot register duplicate card back pack. "
			.. "Make sure to prefix your pack ID with your \"_PLUGIN.guid\"!", 1)
		return false
	end

	-- Ensure no pack with this ID is already registered
	if mod.RegisteredCardBackPacks[packData.Id] ~= nil then
		mod.DebugPrint("[CosmeticsAPI] Error: A card back pack with ID '" .. packData.Id
			.. "' is already registered through the CosmeticsAPI, cannot register duplicate. "
			.. "Make sure to prefix your pack ID with your \"_PLUGIN.guid\"!", 1)
		return false
	end

	-- Validate localized text fields
	for _, textField in ipairs({ "Name", "Description", "FlavorText" }) do
		local hasEnglish = false
		for langCode, _ in pairs(packData[textField]) do
			if langCode == "en" then
				hasEnglish = true
			end
			if not mod.ValidLanguageCodes[langCode] then
				mod.DebugPrint("[CosmeticsAPI] Warning: Invalid language code '" .. tostring(langCode)
					.. "' in field '" .. textField .. "' of card back pack data: " .. packData.Id, 2)
			end
		end
		if not hasEnglish then
			mod.DebugPrint("[CosmeticsAPI] Error: Missing required 'en' key in '" .. textField
				.. "' of card back pack data, cannot register pack: " .. packData.Id, 1)
			return false
		end
	end

	-- Validate optional fields
	if packData.IconScale ~= nil and type(packData.IconScale) ~= "number" then
		mod.WarnIncorrectType("IconScale", "number", type(packData.IconScale), packData.Id)
	end
	if packData.IconOffsetX ~= nil and type(packData.IconOffsetX) ~= "number" then
		mod.WarnIncorrectType("IconOffsetX", "number", type(packData.IconOffsetX), packData.Id)
	end
	if packData.IconOffsetY ~= nil and type(packData.IconOffsetY) ~= "number" then
		mod.WarnIncorrectType("IconOffsetY", "number", type(packData.IconOffsetY), packData.Id)
	end
	if packData.Cost ~= nil and type(packData.Cost) ~= "table" then
		mod.WarnIncorrectType("Cost", "table", type(packData.Cost), packData.Id)
	end
	if packData.GameStateRequirements ~= nil and type(packData.GameStateRequirements) ~= "table" then
		mod.WarnIncorrectType("GameStateRequirements", "table", type(packData.GameStateRequirements), packData.Id)
	end
	if packData.InsertAfterCosmetic ~= nil and type(packData.InsertAfterCosmetic) ~= "string" then
		mod.WarnIncorrectType("InsertAfterCosmetic", "string", type(packData.InsertAfterCosmetic), packData.Id)
	end
	if packData.PreRevealVoiceLines ~= nil and type(packData.PreRevealVoiceLines) ~= "table" then
		mod.WarnIncorrectType("PreRevealVoiceLines", "table", type(packData.PreRevealVoiceLines), packData.Id)
	end
	-- #endregion

	-- #region Create WorldUpgradeData entry
	local newPackCosmetic = {
		Name = packData.Id,
		InheritFrom = { "Cosmetic_CardDeck01" },
		Icon = packData.Id .. "_Icon",
		-- NumBackings is set later when card backs are registered for this pack
		NumBackings = 0,
		Removable = false,
		SkipFade = true,
		CameraFocusId = 589766, -- The Altar
	}

	-- #region Cost
	if packData.Cost ~= nil and type(packData.Cost) == "table" then
		newPackCosmetic.Cost = packData.Cost
	else
		newPackCosmetic.Cost = { CosmeticsPoints = 300 }
	end
	-- #endregion

	-- #region GameStateRequirements - default: require layout saving to be unlocked
	if packData.GameStateRequirements ~= nil and type(packData.GameStateRequirements) == "table" then
		newPackCosmetic.GameStateRequirements = packData.GameStateRequirements
	else
		newPackCosmetic.GameStateRequirements = {
			{ PathTrue = { "GameState", "WorldUpgradesAdded", "WorldUpgradeMetaUpgradeSaveLayout" } },
		}
	end
	-- #endregion

	-- #region PreRevealVoiceLines
	if packData.PreRevealVoiceLines ~= nil and type(packData.PreRevealVoiceLines) == "table" then
		newPackCosmetic.PreRevealVoiceLines = packData.PreRevealVoiceLines
	else
		newPackCosmetic.PreRevealVoiceLines = {
			Queue = "Interrupt",
			{
				PreLineWait = 0.35,
				UsePlayerSource = true,
				{ Cue = "/VO/Melinoe_5379", Text = "How about a new look for the old Arcana..." },
			},
			{ GlobalVoiceLines = "DoraCosmeticReactionVoiceLines" },
		}
	end
	-- #endregion
	-- #endregion

	-- #region Register in WorldUpgradeData
	game.WorldUpgradeData[packData.Id] = newPackCosmetic
	-- #endregion

	-- #region Insert into CosmeticsShop_PreRun
	local inserted = false
	for _, category in ipairs(game.ScreenData.CosmeticsShop.ItemCategories) do
		if category.Name == "CosmeticsShop_PreRun" then
			local insertIndex = #category + 1
			if packData.InsertAfterCosmetic ~= nil and type(packData.InsertAfterCosmetic) == "string" then
				local foundInsertTarget = false
				for index, existingCosmeticId in ipairs(category) do
					if existingCosmeticId == packData.InsertAfterCosmetic then
						foundInsertTarget = true
						insertIndex = index + 1
						break
					end
				end
				if not foundInsertTarget then
					mod.DebugPrint("[CosmeticsAPI] Warning: Could not find InsertAfterCosmetic '"
						.. packData.InsertAfterCosmetic
						.. "' in CosmeticsShop_PreRun. Inserting pack at end of category. Pack ID: "
						.. packData.Id, 2)
				end
			end
			table.insert(category, insertIndex, packData.Id)
			inserted = true
			break
		end
	end

	if not inserted then
		mod.DebugPrint("[CosmeticsAPI] Error: Could not find CosmeticsShop_PreRun category. "
			.. "Cannot register card back pack: " .. packData.Id, 1)
		game.WorldUpgradeData[packData.Id] = nil
		return false
	end
	-- #endregion

	-- #region Store SJSON data for hooks
	table.insert(mod.AddedCosmeticSjsonTextData, {
		Id = packData.Id,
		Name = packData.Name,
		Description = packData.Description,
		FlavorText = packData.FlavorText,
	})

	table.insert(mod.AddedCosmeticSjsonAnimationData, {
		Id = packData.Id,
		IconId = packData.Id .. "_Icon",
		IconPath = packData.IconPath,
		IconScale = packData.IconScale or 1.0,
		IconOffsetX = packData.IconOffsetX or 0,
		IconOffsetY = packData.IconOffsetY or 0,
		-- Card back packs don't have a crossroads animation - reuse icon as a dummy
		AnimationId = packData.Id .. "_Animation",
		CosmeticAnimationPath = packData.IconPath,
		AnimationScale = packData.IconScale or 1.0,
		AnimationOffsetX = packData.IconOffsetX or 0,
		AnimationOffsetY = packData.IconOffsetY or 0,
	})
	-- #endregion

	-- #region Track registration
	mod.RegisteredCardBackPacks[packData.Id] = {
		Id = packData.Id,
		CardBackCount = 0,
	}
	-- #endregion

	mod.DebugPrint("[CosmeticsAPI] Successfully registered new card back pack: " .. packData.Id, 3)
	return true
end

---Registers an individual card back. The card back is unlocked when its associated pack is purchased in the shop.
---The pack must be registered via `RegisterCardBackPack` before calling this function.
---The API auto-assigns a deterministic TextureNum derived from the card back's string ID, ensuring the same ID always maps to the same number regardless of mod load order.
---This TextureNum is used internally for animation name lookup and save persistence (GameState.MetaUpgradeLayoutsArt).
---@param cardBackData CardBackData The input data for the new card back.
---@return boolean successfullyRegistered True if the card back was successfully registered, false otherwise.
public.RegisterCardBack = function(cardBackData)
	-- #region Input Validation
	local requiredFields = {
		Id = "string",
		PackId = "string",
		DeckArtPath = "string",
		CardBackPath = "string",
	}
	for fieldName, fieldType in pairs(requiredFields) do
		if cardBackData[fieldName] == nil then
			mod.DebugPrint("[CosmeticsAPI] Error: Missing required field '" .. fieldName
				.. "' in card back data, cannot register card back: "
				.. tostring(cardBackData.Id or "Unknown"), 1)
			return false
		elseif type(cardBackData[fieldName]) ~= fieldType then
			mod.DebugPrint("[CosmeticsAPI] Error: Field '" .. fieldName .. "' has incorrect type '"
				.. type(cardBackData[fieldName]) .. "' (expected '" .. fieldType
				.. "') in card back data, cannot register card back: "
				.. tostring(cardBackData.Id or "Unknown"), 1)
			return false
		end
	end

	-- Ensure the pack exists
	if mod.RegisteredCardBackPacks[cardBackData.PackId] == nil then
		mod.DebugPrint("[CosmeticsAPI] Error: Card back pack '" .. cardBackData.PackId
			.. "' has not been registered yet. Register the pack with RegisterCardBackPack before registering card backs. "
			.. "Card back ID: " .. cardBackData.Id, 1)
		return false
	end

	-- Ensure no duplicate card back ID
	if mod.RegisteredCardBacks[cardBackData.Id] ~= nil then
		mod.DebugPrint("[CosmeticsAPI] Error: A card back with ID '" .. cardBackData.Id
			.. "' is already registered, cannot register duplicate.", 1)
		return false
	end

	-- Validate optional fields
	if cardBackData.DeckArtMouseoverPath ~= nil and type(cardBackData.DeckArtMouseoverPath) ~= "string" then
		mod.WarnIncorrectType("DeckArtMouseoverPath", "string", type(cardBackData.DeckArtMouseoverPath), cardBackData.Id)
	end
	if cardBackData.DeckArtScale ~= nil and type(cardBackData.DeckArtScale) ~= "number" then
		mod.WarnIncorrectType("DeckArtScale", "number", type(cardBackData.DeckArtScale), cardBackData.Id)
	end
	if cardBackData.CardBackScale ~= nil and type(cardBackData.CardBackScale) ~= "number" then
		mod.WarnIncorrectType("CardBackScale", "number", type(cardBackData.CardBackScale), cardBackData.Id)
	end
	-- #endregion

	-- #region Allocate stable TextureNum
	local textureNum = allocateTextureNum(cardBackData.Id)
	if textureNum == nil then
		return false
	end
	-- #endregion

	-- #region Append to LayoutSetArtOptions
	local artOption = {
		TextureNum = textureNum,
		GameStateRequirements = {
			{ PathTrue = { "GameState", "WorldUpgradesAdded", cardBackData.PackId } },
		},
	}
	table.insert(game.ScreenData.MetaUpgradeCardLayout.LayoutSetArtOptions, artOption)
	-- #endregion

	-- #region Store SJSON animation data
	local numStr = game.GetTwoDigitString(textureNum)
	table.insert(mod.AddedCardBackSjsonAnimationData, {
		Id = cardBackData.Id,
		TextureNum = textureNum,
		DeckArtName = "DeckArt_" .. numStr,
		DeckArtPath = cardBackData.DeckArtPath,
		DeckArtScale = cardBackData.DeckArtScale,
		DeckArtMouseoverName = "DeckArt_Mouseover_" .. numStr,
		DeckArtMouseoverPath = cardBackData.DeckArtMouseoverPath or cardBackData.DeckArtPath,
		CardBackName = "CardBack_" .. numStr,
		CardBackPath = cardBackData.CardBackPath,
		CardBackScale = cardBackData.CardBackScale,
	})
	-- #endregion

	-- #region Track registration
	mod.RegisteredCardBacks[cardBackData.Id] = {
		Id = cardBackData.Id,
		PackId = cardBackData.PackId,
		TextureNum = textureNum,
	}
	mod.ActiveCardBackTextureNums[textureNum] = true

	-- Update the pack's card back count and NumBackings
	local pack = mod.RegisteredCardBackPacks[cardBackData.PackId]
	pack.CardBackCount = pack.CardBackCount + 1
	game.WorldUpgradeData[cardBackData.PackId].NumBackings = pack.CardBackCount
	-- #endregion

	mod.DebugPrint("[CosmeticsAPI] Successfully registered new card back '" .. cardBackData.Id
		.. "' (TextureNum " .. textureNum .. ") in pack '" .. cardBackData.PackId .. "'", 3)
	return true
end

---Registers one or more .pkg package files that contain the card back textures used during the in-combat Arcana card flip animation.
---These packages will be loaded at ALL times (including during runs), not just in the Crossroads, because card back art is displayed when an Arcana is added (e.g. through Judgment).
---IMPORTANT: Only include CardBack_XX textures in these packages.
---Because they are always loaded, any unnecessary assets will consume memory permanently.
---Use `RegisterCrossroadsPackages` for DeckArt/DeckArtMouseover/IconPath textures that are only needed in the Crossroads.
---The .pkg files must be placed in your mod's `plugins_data` folder.
---@param packageNamesArray table A list of package names (table of strings) to register. Do not include the `.pkg` extension.
---@return boolean successfullyRegistered True if at least one package was successfully registered, false otherwise.
public.RegisterCardBackPackages = function(packageNamesArray)
	if type(packageNamesArray) ~= "table" then
		mod.DebugPrint("[CosmeticsAPI] Error: RegisterCardBackPackages expects a table of strings, got '"
			.. type(packageNamesArray) .. "'.", 1)
		return false
	end

	local registeredAny = false
	for _, packageName in ipairs(packageNamesArray) do
		if type(packageName) ~= "string" then
			mod.DebugPrint("[CosmeticsAPI] Warning: Skipping non-string package name of type '"
				.. type(packageName) .. "' in RegisterCardBackPackages.", 2)
		elseif packageName == "" then
			mod.DebugPrint("[CosmeticsAPI] Warning: Skipping empty package name in RegisterCardBackPackages.", 2)
		else
			local alreadyRegistered = false
			for _, existing in ipairs(mod.RegisteredCardBackPackages) do
				if existing == packageName then
					alreadyRegistered = true
					break
				end
			end
			if not alreadyRegistered then
				table.insert(mod.RegisteredCardBackPackages, packageName)
				mod.DebugPrint("[CosmeticsAPI] Successfully registered new card back package: " .. packageName, 3)
			end
			registeredAny = true
		end
	end

	return registeredAny
end
