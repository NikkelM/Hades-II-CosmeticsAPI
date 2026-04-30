-- Pagination wraps for the card back (Arcana Layout Art) selection overlay
local ITEMS_PER_PAGE = 40

local DEFAULT_START_X = 150
local DEFAULT_START_Y = 230
local DEFAULT_SPACING_X = 180
local DEFAULT_SPACING_Y = 200
local DEFAULT_NUM_COLUMNS = 10
local DEFAULT_NEW_ICON_OFFSET_X = 0
local DEFAULT_NEW_ICON_OFFSET_Y = -110

local cardLayoutComponentData = game.ScreenData.MetaUpgradeCardLayout.ComponentData

-- One pair per grid column X position, plus a center visible pair due to even number of columns
local arrowXPositions = {}
for col = 0, 9 do
	table.insert(arrowXPositions, DEFAULT_START_X + col * DEFAULT_SPACING_X)
end

local function createArrowData(x, isUp)
	return {
		Graphic = isUp and "ButtonCodexUp" or "ButtonCodexDown",
		GroupName = "HUD_Main",
		X = x,
		Y = isUp and 120 or 950,
		Alpha = 0.0,
		Scale = 1.0,
		UseableOff = true,
		InputBlockDuration = 0.02,
		Data = {
			OnPressedFunctionName = isUp and function(...)
				return mod.CardBackPagePrev(...)
			end or function(...)
				return mod.CardBackPageNext(...)
			end,
		},
	}
end

-- Per-column invisible arrows for keyboard/controller navigation (no ControlHotkeys)
for i, x in ipairs(arrowXPositions) do
	cardLayoutComponentData["CosmeticsAPI_ScrollUp" .. i] = createArrowData(x, true)
	cardLayoutComponentData["CosmeticsAPI_ScrollDown" .. i] = createArrowData(x, false)
end

-- Centered visible arrows for mouse clicking (between columns 5 and 6)
cardLayoutComponentData["CosmeticsAPI_VisibleUp"] = {
	Graphic = "ButtonCodexUp",
	GroupName = "HUD_Main",
	X = 960,
	Y = 120,
	Alpha = 0.0,
	Scale = 1.0,
	UseableOff = true,
	Data = {
		OnPressedFunctionName = function(...)
			return mod.CardBackPagePrev(...)
		end,
		ControlHotkeys = { "MenuUp" },
	},
}

cardLayoutComponentData["CosmeticsAPI_VisibleDown"] = {
	Graphic = "ButtonCodexDown",
	GroupName = "HUD_Main",
	X = 960,
	Y = 950,
	Alpha = 0.0,
	Scale = 1.0,
	UseableOff = true,
	Data = {
		OnPressedFunctionName = function(...)
			return mod.CardBackPageNext(...)
		end,
		ControlHotkeys = { "MenuDown" },
	},
}

function mod.CardBackPageNext(screen, button)
	local eligibleOptions = screen.CosmeticsAPI_EligibleOptions or {}
	local totalPages = math.max(1, math.ceil(#eligibleOptions / ITEMS_PER_PAGE))
	local currentPage = screen.CosmeticsAPI_CardBackPage or 1

	if currentPage < totalPages then
		screen.CosmeticsAPI_CardBackPage = currentPage + 1
		game.GenericScrollPresentation(screen, button)
		mod.CardBackUpdatePageVisibility(screen)
		game.wait(0.02)
		mod.CardBackTeleportToFirstItem(screen)
	end
end

function mod.CardBackPagePrev(screen, button)
	local currentPage = screen.CosmeticsAPI_CardBackPage or 1

	if currentPage > 1 then
		screen.CosmeticsAPI_CardBackPage = currentPage - 1
		game.GenericScrollPresentation(screen, button)
		mod.CardBackUpdatePageVisibility(screen)
		game.wait(0.02)
		mod.CardBackTeleportToFirstItem(screen)
	end
end

function mod.CardBackTeleportToFirstItem(screen)
	local eligibleOptions = screen.CosmeticsAPI_EligibleOptions or {}
	local currentPage = screen.CosmeticsAPI_CardBackPage or 1
	local pageStart = (currentPage - 1) * ITEMS_PER_PAGE + 1
	local firstOption = eligibleOptions[pageStart]
	if firstOption then
		local comp = screen.Components["LayoutSetArtOption" .. firstOption.dataIndex]
		if comp and comp.OffsetX then
			TeleportCursor({ OffsetX = comp.OffsetX, OffsetY = comp.OffsetY, ForceUseCheck = true })
		end
	end
end

function mod.CardBackUpdatePageVisibility(screen)
	local currentPage = screen.CosmeticsAPI_CardBackPage or 1
	local eligibleOptions = screen.CosmeticsAPI_EligibleOptions or {}
	local totalPages = math.max(1, math.ceil(#eligibleOptions / ITEMS_PER_PAGE))

	local startIndex = (currentPage - 1) * ITEMS_PER_PAGE + 1
	local endIndex = currentPage * ITEMS_PER_PAGE

	local numColumns = screen.LayoutSetArtOptionsNumColumns or DEFAULT_NUM_COLUMNS
	local startX = screen.LayoutSetArtOptionsStartX or DEFAULT_START_X
	local startY = screen.LayoutSetArtOptionsStartY or DEFAULT_START_Y
	local spacingX = screen.LayoutSetArtOptionsSpacingX or DEFAULT_SPACING_X
	local spacingY = screen.LayoutSetArtOptionsSpacingY or DEFAULT_SPACING_Y
	local newIconOffsetX = screen.LayoutSetArtOptionsNewIconOffsetX or DEFAULT_NEW_ICON_OFFSET_X
	local newIconOffsetY = screen.LayoutSetArtOptionsNewIconOffsetY or DEFAULT_NEW_ICON_OFFSET_Y
	local currentTextureNum = game.GameState.MetaUpgradeLayoutsArt[screen.SwappingLayoutArtIndex] or 1
	local highlightPlaced = false

	for displayIndex, optionInfo in ipairs(eligibleOptions) do
		local component = screen.Components["LayoutSetArtOption" .. optionInfo.dataIndex]
		if component ~= nil then
			-- Reset hover state on all items (prevents stale mouseover animation/scale after page change)
			SetAnimation({ DestinationId = component.Id, Name = "DeckArt_" .. game.GetTwoDigitString(optionInfo.textureNum) })
			SetScale({ Id = component.Id, Fraction = screen.LayoutSetArtOptionsScale or 0.75, Duration = 0.0 })

			if displayIndex >= startIndex and displayIndex <= endIndex then
				local positionOnPage = displayIndex - startIndex
				local col = positionOnPage % numColumns
				local row = math.floor(positionOnPage / numColumns)
				local x = startX + ScreenCenterNativeOffsetX + col * spacingX
				local y = startY + ScreenCenterNativeOffsetY + row * spacingY

				Teleport({ Id = component.Id, OffsetX = x, OffsetY = y })
				component.OffsetX = x
				component.OffsetY = y
				SetAlpha({ Id = component.Id, Fraction = 1.0, Duration = 0.0 })
				UseableOn({ Id = component.Id })

				if component.NewIcon ~= nil then
					Teleport({
						Id = component.NewIcon.Id,
						OffsetX = x + newIconOffsetX,
						OffsetY = y + newIconOffsetY
					})
					if not game.GameState.LayoutSetArtViewed[optionInfo.textureNum] then
						SetAlpha({ Id = component.NewIcon.Id, Fraction = 1.0, Duration = 0.0 })
					else
						SetAlpha({ Id = component.NewIcon.Id, Fraction = 0.0, Duration = 0.0 })
					end
				end

				if currentTextureNum == optionInfo.textureNum then
					Teleport({ Id = screen.Components.LayoutArtSwapSelectionHighlight.Id, DestinationId = component.Id })
					highlightPlaced = true
				end
			else
				SetAlpha({ Id = component.Id, Fraction = 0.0, Duration = 0.0 })
				UseableOff({ Id = component.Id })
				if component.NewIcon ~= nil then
					SetAlpha({ Id = component.NewIcon.Id, Fraction = 0.0, Duration = 0.0 })
				end
			end
		end
	end

	-- If the equipped card back is on a different page, move the highlight offscreen
	if not highlightPlaced and screen.Components.LayoutArtSwapSelectionHighlight then
		Teleport({ Id = screen.Components.LayoutArtSwapSelectionHighlight.Id, OffsetX = -1000, OffsetY = -1000 })
	end

	-- Show/hide arrow buttons - only enable arrows for columns that have items on the current page
	local canScrollUp = currentPage > 1
	local canScrollDown = currentPage < totalPages

	local pageItemCount = math.min(endIndex, #eligibleOptions) - startIndex + 1
	local lastRow = math.floor((pageItemCount - 1) / numColumns)
	local lastRowItemCount = pageItemCount - lastRow * numColumns
	-- First row always has numColumns items (or pageItemCount if less than one full row)
	local firstRowItemCount = math.min(pageItemCount, numColumns)

	for i, _ in ipairs(arrowXPositions) do
		local columnIndex = i
		local upKey = "CosmeticsAPI_ScrollUp" .. i
		local downKey = "CosmeticsAPI_ScrollDown" .. i

		-- Up arrows: invisible, only for columns that have items in the first row, to prevent navigating right from selecting an arrow and switching pages
		if screen.Components[upKey] then
			if canScrollUp and columnIndex <= firstRowItemCount then
				UseableOn({ Id = screen.Components[upKey].Id })
			else
				UseableOff({ Id = screen.Components[upKey].Id, ForceHighlightOff = true })
			end
		end

		-- Down arrows: invisible, only for columns that have items in the last row, to prevent navigating right from selecting an arrow and switching pages
		if screen.Components[downKey] then
			if canScrollDown and columnIndex <= lastRowItemCount then
				UseableOn({ Id = screen.Components[downKey].Id })
			else
				UseableOff({ Id = screen.Components[downKey].Id, ForceHighlightOff = true })
			end
		end
	end

	-- Visible centered arrows (mouse-only)
	local visibleUpArrow = screen.Components.CosmeticsAPI_VisibleUp
	if visibleUpArrow then
		if canScrollUp then
			SetAlpha({ Id = visibleUpArrow.Id, Fraction = 1.0, Duration = 0.1 })
			UseableOn({ Id = visibleUpArrow.Id })
		else
			SetAlpha({ Id = visibleUpArrow.Id, Fraction = 0.0, Duration = 0.0 })
			UseableOff({ Id = visibleUpArrow.Id })
		end
	end
	local visibleDownArrow = screen.Components.CosmeticsAPI_VisibleDown
	if visibleDownArrow then
		if canScrollDown then
			SetAlpha({ Id = visibleDownArrow.Id, Fraction = 1.0, Duration = 0.1 })
			UseableOn({ Id = visibleDownArrow.Id })
		else
			SetAlpha({ Id = visibleDownArrow.Id, Fraction = 0.0, Duration = 0.0 })
			UseableOff({ Id = visibleDownArrow.Id })
		end
	end
end

modutil.mod.Path.Wrap("MetaUpgradeCardScreenLayoutSetSwapOpen", function(base, screen, button)
	base(screen, button)

	if screen.SwappingLayoutArtIndex == nil then
		return
	end

	local eligibleOptions = {}
	for i, option in ipairs(screen.LayoutSetArtOptions) do
		if screen.Components["LayoutSetArtOption" .. i] ~= nil then
			table.insert(eligibleOptions, {
				dataIndex = i,
				textureNum = option.TextureNum,
			})
		end
	end

	if #eligibleOptions <= ITEMS_PER_PAGE then
		-- No pagination needed - disable all per-column arrows so cursor can't navigate to them
		for i, _ in ipairs(arrowXPositions) do
			local upComp = screen.Components["CosmeticsAPI_ScrollUp" .. i]
			if upComp then
				UseableOff({ Id = upComp.Id })
			end
			local downComp = screen.Components["CosmeticsAPI_ScrollDown" .. i]
			if downComp then
				UseableOff({ Id = downComp.Id })
			end
		end
		return
	end

	screen.CosmeticsAPI_EligibleOptions = eligibleOptions

	local currentTextureNum = game.GameState.MetaUpgradeLayoutsArt[screen.SwappingLayoutArtIndex] or 1
	local startPage = 1
	for displayIdx, optionInfo in ipairs(eligibleOptions) do
		if optionInfo.textureNum == currentTextureNum then
			startPage = math.ceil(displayIdx / ITEMS_PER_PAGE)
			break
		end
	end
	screen.CosmeticsAPI_CardBackPage = startPage

	-- Recreate visible centered arrows so they draw on top of the background
	-- (within HUD_Main, higher entity IDs draw in front; pairs() creation order is non-deterministic)
	for _, visKey in ipairs({ "CosmeticsAPI_VisibleUp", "CosmeticsAPI_VisibleDown" }) do
		local old = screen.Components[visKey]
		if old then
			local isUp = visKey == "CosmeticsAPI_VisibleUp"
			Destroy({ Id = old.Id })
			local newComp = CreateScreenComponent({
				Name = isUp and "ButtonCodexUp" or "ButtonCodexDown",
				X = 960,
				Y = isUp and 120 or 950,
				Group = "HUD_Main",
				Scale = 1.0,
				Alpha = 0.0,
			}) or {}
			newComp.OnPressedFunctionName = old.OnPressedFunctionName
			newComp.ControlHotkeys = old.ControlHotkeys
			newComp.Screen = screen
			screen.Components[visKey] = newComp
		end
	end

	mod.CardBackUpdatePageVisibility(screen)
end)

modutil.mod.Path.Wrap("MetaUpgradeCardScreenLayoutSetSwapClose", function(base, screen, button)
	base(screen, button)

	for i, _ in ipairs(arrowXPositions) do
		local upComp = screen.Components["CosmeticsAPI_ScrollUp" .. i]
		if upComp then
			SetAlpha({ Id = upComp.Id, Fraction = 0.0, Duration = 0.0 })
			UseableOff({ Id = upComp.Id })
		end
		local downComp = screen.Components["CosmeticsAPI_ScrollDown" .. i]
		if downComp then
			SetAlpha({ Id = downComp.Id, Fraction = 0.0, Duration = 0.0 })
			UseableOff({ Id = downComp.Id })
		end
	end
	for _, visKey in ipairs({ "CosmeticsAPI_VisibleUp", "CosmeticsAPI_VisibleDown" }) do
		local comp = screen.Components[visKey]
		if comp then
			SetAlpha({ Id = comp.Id, Fraction = 0.0, Duration = 0.0 })
			UseableOff({ Id = comp.Id })
		end
	end

	screen.CosmeticsAPI_EligibleOptions = nil
	screen.CosmeticsAPI_CardBackPage = nil
end)
