---@meta NikkelM-Cosmetics_API

local registeredCostumes = {}

-- #region Shop Pagination
public.lovely_env.SetupFamiliarCostumePagination = function(screen)
	screen.ScrollOffset = 0
	screen.NumItems = #screen.ItemCategories[screen.OpenedFrom.Name]
	if screen.NumItems <= screen.ItemsPerPage then
		return
	end

	local cosmeticsShop = game.ScreenData.CosmeticsShop
	local offsetY = game.ScreenData.FamiliarCostumeShop.ItemStartY - cosmeticsShop.ItemStartY
	screen.ScrollbarSliderTopY = cosmeticsShop.ScrollbarSliderTopY + offsetY
	screen.ScrollbarSliderBottomY = cosmeticsShop.ScrollbarSliderBottomY + offsetY

	for _, name in ipairs({ "Scrollbar", "ScrollbarSlider", "ScrollUp", "ScrollDown" }) do
		local component = game.DeepCopyTable(cosmeticsShop.ComponentData[name])
		component.Y = component.Y + offsetY
		screen.ComponentData[name] = component
		table.insert(screen.ComponentData.Order, name)
	end
	screen.ComponentData.ScrollUp.Data.OnPressedFunctionName = _PLUGIN.guid .. "." .. "FamiliarCostumeScrollUp"
	screen.ComponentData.ScrollDown.Data.OnPressedFunctionName = _PLUGIN.guid .. "." .. "FamiliarCostumeScrollDown"
end

modutil.mod.Path.Wrap("FamiliarCostumeShopUpdateVisibility", function(base, screen, args)
	if screen.SelectedItem then
		game.MouseOffFamiliarCostumeItem(screen.SelectedItem)
	end

	if screen.Components.Scrollbar then
		game.GhostAdminUpdateScrollbarPresentation(screen, args)
	end

	game.Destroy({ Ids = screen.ButtonIds })

	return base(screen, args)
end)

local function scrollFamiliarCostumePage(screen, button, direction)
	local offset = screen.ScrollOffset + (direction * screen.ItemsPerPage)
	if offset < 0 or offset >= screen.NumItems then
		return
	end

	screen.ScrollOffset = offset
	game.GenericScrollPresentation(screen, button)
	game.FamiliarCostumeShopUpdateVisibility(screen, { AnimateSlider = true })
	game.wait(0.02)

	local rowOffset = direction < 0 and screen.ItemsPerPage - 1 or 0
	game.TeleportCursor({
		OffsetX = screen.ItemStartX - 30,
		OffsetY = screen.ItemStartY + rowOffset * screen.ItemSpacingY,
		ForceUseCheck = true,
	})
end

function mod.FamiliarCostumeScrollUp(screen, button)
	scrollFamiliarCostumePage(screen, button, -1)
end

function mod.FamiliarCostumeScrollDown(screen, button)
	scrollFamiliarCostumePage(screen, button, 1)
end

-- #endregion

-- #region Registration
---@param costume FamiliarCostumeData
---@return boolean valid
local function validateFamiliarCostumeData(costume)
	if type(costume) ~= "table" then
		mod.DebugPrint("[CosmeticsAPI] Error: Familiar costume registration expects costume data to be a table.", 1)
		return false
	end

	local requiredFields = {
		Id = "string",
		FamiliarName = "string",
		Name = "table",
		Description = "table",
		IconPath = "string",
	}
	for field, expected in pairs(requiredFields) do
		if costume[field] == nil then
			mod.DebugPrint("[CosmeticsAPI] Error: Missing required field '" .. field ..
				"' in familiar costume data, cannot register costume: " .. tostring(costume.Id or "Unknown"), 1)
			return false
		elseif type(costume[field]) ~= expected then
			mod.ErrorIncorrectType(field, expected, type(costume[field]), costume.Id or "Unknown")
			return false
		elseif costume[field] == "" then
			mod.DebugPrint("[CosmeticsAPI] Error: Familiar costume field '" .. field .. "' must not be empty.", 1)
			return false
		end
	end

	if game.WorldUpgradeData[costume.Id] ~= nil then
		mod.DebugPrint("[CosmeticsAPI] Error: A familiar costume with ID '" .. costume.Id ..
			"' already exists, cannot register duplicate costume. Make sure to prefix your costume with your \"_PLUGIN.guid\"!",
			1)
		return false
	end

	local optionalFields = {
		GrannyModel = "string",
		GrannyTexture = "string",
		IconScale = "number",
		Outline = "table",
		Cost = "table",
		GameStateRequirements = "table",
		AlwaysRevealImmediately = "boolean",
		AutoUnlock = "boolean",
		PreRevealVoiceLines = "table",
		SwitchCostumeVoiceLines = "table",
	}
	for field, expected in pairs(optionalFields) do
		if costume[field] ~= nil and type(costume[field]) ~= expected then
			mod.ErrorIncorrectType(field, expected, type(costume[field]), costume.Id)
			return false
		end
	end

	if costume.GrannyModel == nil and costume.GrannyTexture == nil then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: Familiar costume '" ..
			costume.Id .. "' requires at least one of GrannyModel or GrannyTexture.", 1)
		return false
	end
	if costume.GrannyModel == "" then
		mod.DebugPrint("[CosmeticsAPI] Error: Familiar costume '" .. costume.Id .. "' has an empty GrannyModel.", 1)
		return false
	end
	if costume.GrannyTexture == "" then
		mod.DebugPrint("[CosmeticsAPI] Error: Familiar costume '" .. costume.Id .. "' has an empty GrannyTexture.", 1)
		return false
	end

	for _, field in ipairs({ "Name", "Description" }) do
		if type(costume[field].en) ~= "string" then
			mod.DebugPrint(
				"[CosmeticsAPI] Error: Familiar costume '" .. costume.Id .. "' needs an English '" .. field .. "' entry.", 1)
			return false
		end

		for language, text in pairs(costume[field]) do
			if not mod.ValidLanguageCodes[language] then
				mod.DebugPrint("[CosmeticsAPI] Warning: Invalid language code '" .. tostring(language) ..
					"' in field '" .. field .. "' of familiar costume data: " .. costume.Id, 2)
			elseif type(text) ~= "string" then
				mod.ErrorIncorrectType(field .. "." .. language, "string", type(text), costume.Id)
				return false
			end
		end
	end

	return true
end

---Adds a costume to an existing familiar's costume shop.
---At least one of `GrannyModel` or `GrannyTexture` must be provided.
---@param costume FamiliarCostumeData The costume data to register.
---@return boolean successfullyRegistered True if the familiar costume was registered, false if it was rejected.
public.RegisterFamiliarCostume = function(costume)
	if not validateFamiliarCostumeData(costume) then
		return false
	end

	local familiar = game.FamiliarData[costume.FamiliarName]
	if not familiar or not game.ScreenData.FamiliarCostumeShop.ItemCategories[costume.FamiliarName] then
		mod.DebugPrint("[CosmeticsAPI] Error: No costume shop category for familiar '" .. costume.FamiliarName .. "'.", 1)
		return false
	end

	local upgrade = {
		Name = costume.Id,
		InheritFrom = { "DefaultFamiliarCostume" },
		Icon = costume.Id .. "_Icon",
		GrannyModel = costume.GrannyModel or game.WorldUpgradeData[familiar.DefaultCostume].GrannyModel,
		GrannyTexture = costume.GrannyTexture,
		Outline = costume.Outline,
		Cost = costume.Cost or { CosmeticsPoints = 50 },
		GameStateRequirements = costume.GameStateRequirements or {},
		AlwaysRevealImmediately = costume.AlwaysRevealImmediately,
		PreRevealVoiceLines = costume.PreRevealVoiceLines or {
			{ GlobalVoiceLines = "FamiliarMiscCostumeUnlocked" },
		},
		SwitchCostumeVoiceLines = costume.SwitchCostumeVoiceLines or {
			{ GlobalVoiceLines = "FamiliarMiscSwitchCostumeVoiceLines" },
		},
	}

	game.WorldUpgradeData[costume.Id] = upgrade
	game.ProcessDataInheritance(upgrade, game.WorldUpgradeData)
	game.ProcessSimpleExtractValues(upgrade)

	table.insert(game.ScreenData.FamiliarCostumeShop.ItemCategories[costume.FamiliarName], costume.Id)
	registeredCostumes[costume.Id] = costume.FamiliarName

	table.insert(mod.AddedCosmeticSjsonTextData, {
		Id = costume.Id,
		Name = costume.Name,
		Description = costume.Description,
	})

	table.insert(mod.AddedCosmeticSjsonAnimationData, {
		IconId = upgrade.Icon,
		IconPath = costume.IconPath,
		IconScale = costume.IconScale,
	})

	if costume.AutoUnlock == true then
		table.insert(game.GameData.WorldUpgradeAutomaticUnlocks, costume.Id)
	end

	mod.DebugPrint("[CosmeticsAPI] Successfully registered new familiar costume: " .. costume.Id, 3)
	return true
end
-- #endregion

-- #region Selection
local function getEquippedCostume(familiarName)
	local vanilla = game.GameState.FamiliarCostumes[familiarName]
	local familiar = game.FamiliarData[familiarName]
	local custom = game.GameState.ModFamiliarCostumes[familiarName]

	if familiar and (vanilla == nil or vanilla == familiar.DefaultCostume) and registeredCostumes[custom] == familiarName then
		return custom
	end

	return vanilla
end

---Selects an owned costume. Its appearance is applied the next time the familiar's costume is set up.
---@param familiarName string Internal familiar name, such as `FrogFamiliar`.
---@param id string ID of an owned costume for this familiar.
---@return boolean successfullySelected True if the selection was saved, false if the costume is unavailable.
public.SelectFamiliarCostume = function(familiarName, id)
	local familiar = game.FamiliarData[familiarName]
	if not familiar or not game.Contains(game.ScreenData.FamiliarCostumeShop.ItemCategories[familiarName], id) or not game.GameState.WorldUpgradesAdded[id] then
		mod.DebugPrint(
			"[CosmeticsAPI] Cannot select unavailable costume '" .. tostring(id) .. "' for '" .. tostring(familiarName) .. "'.",
			1)
		return false
	end

	if registeredCostumes[id] == familiarName then
		game.GameState.ModFamiliarCostumes[familiarName] = id
		game.GameState.FamiliarCostumes[familiarName] = familiar.DefaultCostume
	else
		game.GameState.ModFamiliarCostumes[familiarName] = nil
		game.GameState.FamiliarCostumes[familiarName] = id
	end

	return true
end

public.lovely_env.GetEquippedFamiliarCostume = getEquippedCostume
public.lovely_env.SelectFamiliarCostume = public.SelectFamiliarCostume
-- #endregion

-- #region Costume Setup
modutil.mod.Path.Wrap("SetupFamiliarCostume", function(base, familiar, args)
	local id = getEquippedCostume(familiar.Name)

	if familiar.CosmeticsAPIHasFamiliarTexture then
		game.SetThingProperty({ DestinationId = familiar.ObjectId, Property = "GrannyTexture", Value = "" })
		familiar.CosmeticsAPIHasFamiliarTexture = nil
	end

	local result = base(familiar, args)

	if registeredCostumes[id] == familiar.Name then
		local costume = game.WorldUpgradeData[id]
		game.SetThingProperty({ DestinationId = familiar.ObjectId, Property = "GrannyModel", Value = costume.GrannyModel })

		if costume.GrannyTexture then
			game.SetThingProperty({
				DestinationId = familiar.ObjectId,
				Property = "GrannyTexture",
				Value = costume.GrannyTexture
			})
			familiar.CosmeticsAPIHasFamiliarTexture = true
		end

		if costume.Outline then
			local outline = game.ShallowCopyTable(costume.Outline)
			outline.Id = familiar.ObjectId
			game.AddOutline(outline)
			familiar.HasOutline = true
		elseif familiar.HasOutline then
			game.RemoveOutline({ Id = familiar.ObjectId })
			familiar.HasOutline = nil
		end

		game.SetAnimation({ DestinationId = familiar.ObjectId, Name = (args and args.Animation) or familiar.IdleAnimation })
	end

	return result
end)
-- #endregion
