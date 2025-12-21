local keyMaxVisibleKeepsakes = "NikkelM-Cosmetics_API-MaxVisibleKeepsakes"
local keyScrollOffset = "NikkelM-Cosmetics_API-ScrollOffset"
local keyActiveEntries = "NikkelM-Cosmetics_API-ActiveEntries"
local keyNumItems = "NikkelM-Cosmetics_API-NumItems"
local keyScrollUp = "NikkelM-Cosmetics_API-ScrollUp"
local keyScrollDown = "NikkelM-Cosmetics_API-ScrollDown"

-- TODO: Eleven for the eleven keepsakes
local scrollArrowXPositions = { 158, 275, 390, 510, 620, 733, 850, 970, 1085, 1195, 1314 }

function game.createScrollArrowData(x, isUpArrow)
	print("Creating scroll arrow at X: " .. x .. " Is Up Arrow: " .. tostring(isUpArrow))
	return {
		Graphic = isUpArrow and "ButtonCodexUp" or "ButtonCodexDown",
		GroupName = "Combat_Menu_Overlay",
		X = x,
		Y = isUpArrow and 120 or 700,
		Alpha = 0.0,
		Scale = 1.0,
		InputBlockDuration = 0.02,
		Data = {
			OnPressedFunctionName = isUpArrow and function(...)
				return MetaUpgradeCardScreenLayoutSetSwapScrollUp(...)
			end or function(...)
				return MetaUpgradeCardScreenLayoutSetSwapScrollDown(...)
			end,
			ControlHotkey = isUpArrow and "MenuUp" or "MenuDown",
		},
	}
end

function game.MetaUpgradeCardScreenLayoutSetSwapUpdateVisibility(screen, args)
	print("Updating Meta Upgrade Card Screen Layout Set Swap Visibility")
	args = args or {}
	-- activeKeepsakeIDs, disabledKeepsakeIDs = {}, {}
	local components = screen.Components

	screen.RowMax = screen.RowMax or 4
	local rowMin = math.ceil(screen.RowMax / 2)

	local startIndex = screen[keyScrollOffset] + 1
	local endIndex = math.min(screen[keyScrollOffset] + screen[keyMaxVisibleKeepsakes], #screen[keyActiveEntries])
	print("Showing keepsakes from index " .. tostring(startIndex) .. " to " .. tostring(endIndex))

	-- local componentOffsetList = {
	-- 	Frame = { offsetx = 0, offsety = 10 },
	-- 	Bar = { offsetx = 0, offsety = 80 },
	-- 	BarFill = { offsetx = 0, offsety = 80 },
	-- 	Rank = { offsetx = 0, offsety = screen.RankOffsetY },
	-- 	Sticker = { offsetx = 30, offsety = -40 },
	-- 	Lock = { offsetx = 0, offsety = 0 },
	-- }

	-- local favouriteKeepsakeVisible = false
	-- local favouriteButtonKey = nil

	-- for index, buttonKey in ipairs(screen[keyActiveEntries]) do
	-- 	local item = components[buttonKey]
	-- 	if item ~= nil and GameState.SaveFirstKeepsakeName == item.Data.Gift then
	-- 		if index >= startIndex and index <= endIndex then
	-- 			favouriteKeepsakeVisible = true
	-- 			favouriteButtonKey = buttonKey
	-- 			break
	-- 		end
	-- 	end
	-- end

	-- for index, buttonKey in ipairs(screen[keyActiveEntries]) do
		-- local item = components[buttonKey]

		-- if item ~= nil then
			-- if index >= startIndex and index <= endIndex then
				-- local x = screen.LayoutSetArtOptionsStartX - screen.LayoutSetArtOptionsSpacingX * rowMin / 2 + ((index - 1) % screen.RowMax + 0.5) * screen.LayoutSetArtOptionsSpacingX
				-- local y = screen.LayoutSetArtOptionsStartY + math.floor((index - startIndex) / screen.RowMax) * 2 * (screen.LayoutSetArtOptionsSpacingY / 2)

				-- item.OffsetX = x
				-- item.OffsetY = y

				-- TP the Keepsake Textures like selected texture
				-- Teleport({ Id = item.Id, OffsetX = x, OffsetY = y })

				-- for k, v in pairs(componentOffsetList) do
				-- 	if components[buttonKey .. k] then
				-- 		Teleport({ Id = components[buttonKey .. k].Id, OffsetX = x + v.offsetx, OffsetY = y + v.offsety })
				-- 	end
				-- end

				-- if item.NewIcon then
					-- Teleport({ Id = item.NewIcon.Id, OffsetX = x, OffsetY = y - 30 })
				-- end

				-- Add Keepsakes to list to be shown later
				-- table.insert(activeKeepsakeIDs, item.Id)

				-- for k, v in pairs(componentOffsetList) do
				-- 	if components[buttonKey .. k] then
				-- 		if k ~= "Bar" and k ~= "BarFill" then
				-- 			table.insert(activeKeepsakeIDs, components[buttonKey .. k].Id)
				-- 		end
				-- 	end
				-- end

				-- if item.NewIcon then
				-- 	table.insert(activeKeepsakeIDs, item.NewIcon.Id)
				-- end
			-- else
				-- table.insert(disabledKeepsakeIDs, item.Id)
				-- for k, v in pairs(componentOffsetList) do
				-- 	if components[buttonKey .. k] then
				-- 		table.insert(disabledKeepsakeIDs, components[buttonKey .. k].Id)
				-- 	end
				-- end
				-- if item.NewIcon then
				-- 	table.insert(disabledKeepsakeIDs, item.NewIcon.Id)
				-- end
			-- end

			-- if GameState.SaveFirstKeepsakeName == item.Data.Gift then
			-- 	if favouriteKeepsakeVisible and buttonKey == favouriteButtonKey then
			-- 		SetSaveFirstIcon(screen, components[buttonKey])
			-- 	else
			-- 		ClearSaveFirstIcon(screen, components[buttonKey])
			-- 	end
			-- end
		-- end
	-- end

	-- SetAlpha({ Ids = activeKeepsakeIDs, Fraction = 1, Duration = 0.1 })
	-- UseableOn({ Ids = activeKeepsakeIDs })

	-- SetAlpha({ Ids = disabledKeepsakeIDs, Fraction = 0, Duration = 0.1 })
	-- UseableOff({ Ids = disabledKeepsakeIDs, ForceHighlightOff = true })

	if not args.IgnoreArrows then
		print("Updating Scroll Arrows")
		local canScrollUp = screen[keyScrollOffset] > 0
		local canScrollDown = screen[keyScrollOffset] + screen[keyMaxVisibleKeepsakes] < screen[keyNumItems]
		print("Can Scroll Up: " .. tostring(canScrollUp) .. " Can Scroll Down: " .. tostring(canScrollDown))
		print("Total Items: " .. tostring(screen[keyNumItems]) .. " Scroll Offset: " .. tostring(screen[keyScrollOffset]) .. " Max Visible: " .. tostring(screen[keyMaxVisibleKeepsakes]))

		for i, x in ipairs(scrollArrowXPositions) do
			local upKey = keyScrollUp .. i
			local downKey = keyScrollDown .. i

			print("Processing arrow index " .. tostring(i) .. " at X position " .. tostring(x))
			if x == 733 then
				if components[upKey] then
					if canScrollUp then
						print("Enabling Up Arrow at index " .. tostring(i))
						SetAlpha({ Id = components[upKey].Id, Fraction = 1.0, Duration = 0.1 })
						UseableOn({ Id = components[upKey].Id })
					else
						print("Disabling Up Arrow at index " .. tostring(i))
						SetAlpha({ Id = components[upKey].Id, Fraction = 0.3, Duration = 0.1 })
						UseableOff({ Id = components[upKey].Id, ForceHighlightOff = true })
					end
				end

				if components[downKey] then
					if canScrollDown then
						print("Enabling Down Arrow at index " .. tostring(i))
						SetAlpha({ Id = components[downKey].Id, Fraction = 1.0, Duration = 0.1 })
						UseableOn({ Id = components[downKey].Id })
					else
						print("Disabling Down Arrow at index " .. tostring(i))
						SetAlpha({ Id = components[downKey].Id, Fraction = 0.3, Duration = 0.1 })
						UseableOff({ Id = components[downKey].Id, ForceHighlightOff = true })
					end
				end
			else
				if components[upKey] then
					if canScrollUp then
						print("Enabling Up Arrow at index " .. tostring(i))
						UseableOn({ Id = components[upKey].Id })
					else
						print("Disabling Up Arrow at index " .. tostring(i))
						UseableOff({ Id = components[upKey].Id, ForceHighlightOff = true })
					end
				end

				if components[downKey] then
					if canScrollDown then
						print("Enabling Down Arrow at index " .. tostring(i))
						UseableOn({ Id = components[downKey].Id })
					else
						print("Disabling Down Arrow at index " .. tostring(i))
						UseableOff({ Id = components[downKey].Id, ForceHighlightOff = true })
					end
				end
			end
		end
	end
end

function MetaUpgradeCardScreenLayoutSetSwapScrollUp(screen, button)
	print("Scrolling Up")
	if screen[keyScrollOffset] <= 0 then
		return
	end
	screen[keyScrollOffset] = screen[keyScrollOffset] - screen[keyMaxVisibleKeepsakes]
	GenericScrollPresentation(screen, button)
	-- TODO
	game.MetaUpgradeCardScreenLayoutSetSwapUpdateVisibility(screen, { ScrolledUp = true })

	wait(0.02)

	-- checkForCurrentKeepsake(screen)
end

function MetaUpgradeCardScreenLayoutSetSwapScrollDown(screen, button)
	print("Scrolling Down")
	if screen[keyScrollOffset] + screen[keyMaxVisibleKeepsakes] >= screen[keyNumItems] then
		return
	end
	screen[keyScrollOffset] = screen[keyScrollOffset] + screen[keyMaxVisibleKeepsakes]
	GenericScrollPresentation(screen, button)
	-- TODO
	game.MetaUpgradeCardScreenLayoutSetSwapUpdateVisibility(screen, { ScrolledDown = true })
	wait(0.02)
	-- checkForCurrentKeepsake(screen)
end
