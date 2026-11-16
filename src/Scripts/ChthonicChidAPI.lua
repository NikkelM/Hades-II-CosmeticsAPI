-- #region Registration
mod.RegisteredChthonicChids = {}
mod.RegisteredChthonicChidCounts = {}

---@param cosmeticData ChthonicChidData
---@return boolean valid
function mod.ValidateChthonicChidData(cosmeticData)
	if not mod.ValidateCosmeticBaseData(cosmeticData) then
		return false
	end

	for _, field in ipairs({ "InheritFrom", "SetAnimationIds", "DeactivateIds", "AnimationOffsetX", "AnimationOffsetY" }) do
		if cosmeticData[field] ~= nil then
			mod.DebugPrint("[CosmeticsAPI] Error: Chthonic Chids cannot set " .. field .. ": " .. cosmeticData.Id, 1)
			return false
		end
	end

	local modId = cosmeticData.Id:match("^([^.]+)%..+$")
	local capacity = mod.ChthonicChidReservations[modId]
	if capacity == nil then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: No Chthonic Chid reservation for " .. cosmeticData.Id ..
			". Request space on the shelf through a CosmeticsAPI PR and prefix the cosmetic Id with `_PLUGIN.guid .. '.'`", 1)
		return false
	end

	if (mod.RegisteredChthonicChidCounts[modId] or 0) >= capacity then
		mod.DebugPrint(
			"[CosmeticsAPI] Error: Chthonic Chid reservation of " ..
			capacity .. " exceeded for " .. modId .. ": " .. cosmeticData.Id, 1)
		return false
	end

	return true
end

---Registers a new Chthonic Chid cosmetic.
---@param chidData ChthonicChidData The input data for the new Chthonic Chid.
---@return boolean successfullyRegistered True if the Chid was successfully registered, false otherwise.
public.RegisterChthonicChid = function(chidData)
	if type(chidData) == "table" then
		chidData.ShopCategory = "CosmeticsShop_PreRun"
		chidData.ActivateIds = {}
	end
	if not mod.ValidateChthonicChidData(chidData) then
		return false
	end

	local newGameCosmetic = mod.CreateCosmeticData(chidData)
	if newGameCosmetic == nil then
		return false
	end

	newGameCosmetic.AutoUnlockCosmeticName = "Cosmetic_CollectableShelf"
	mod.FinalizeCosmeticRegistration(chidData, newGameCosmetic, 0.247 * 391 / 94)

	local modId = chidData.Id:match("^([^.]+)%.")
	mod.RegisteredChthonicChidCounts[modId] = (mod.RegisteredChthonicChidCounts[modId] or 0) + 1
	table.insert(mod.RegisteredChthonicChids, chidData.Id)

	return true
end
-- #endregion

-- #region Display
local shelfAnchorId = 780519
local backSupportAnchorIds = { 780589, 780590 }
local sideSupportAnchorIds = { 780585, 780586 }
local chidSlotOffsets = {
	{ X = -170.018, Y = 22.867 },
	{ X = -104.018, Y = -10.133 },
	{ X = -38.018,  Y = -43.133 },
	{ X = 27.982,   Y = -76.133 },
	{ X = 93.982,   Y = -109.133 },
	{ X = 156.982,  Y = -140.633 },
}
local chidsPerRow = #chidSlotOffsets
local shelfRowSpacing = 180
local supportRowHeight = 200
local displayGroup = _PLUGIN.guid .. "." .. "ChthonicChidDisplay"
local backGroup = displayGroup .. "." .. "Back"
local frontGroup = displayGroup .. "." .. "Front"
local overlookStartFunctionName = _PLUGIN.guid .. "." .. "StartChthonicChidOverlook"

local function spawnDisplayObstacle(args, scale, ambient)
	local id = game.SpawnObstacle(args)
	game.SetScale({ Id = id, Fraction = scale })
	game.SetThingProperty({ DestinationId = id, Property = "Ambient", Value = ambient })
	game.SetThingProperty({ DestinationId = id, Property = "StopsUnits", Value = false })
	game.SetThingProperty({ DestinationId = id, Property = "StopsLight", Value = false })
	game.SetAlpha({ Id = id, Fraction = 0 })
	return id
end

-- #region DistanceTrigger/"Overlook"
function mod.EnterChthonicChidOverlook(room, args)
	game.LockCamera({
		Id = game.CurrentRun.Hero.ObjectId,
		OffsetX = -50,
		OffsetY = args.OffsetY,
		Duration = 0.75,
		Retarget = true,
		FromCurrentLocation = true,
	})
end

function mod.LeaveChthonicChidOverlook(room)
	game.LockCamera({
		Id = game.CurrentRun.Hero.ObjectId,
		OffsetX = 0,
		OffsetY = 0,
		Duration = 0.75,
		Retarget = true,
		FromCurrentLocation = true,
	})
end

function mod.StartChthonicChidOverlook(room, args)
	game.DistanceTrigger(room, {
		Id = args.Id,
		WithinDistance = 175,
		ScaleY = 0.65,
		RepeatBufferDistance = 75,
		Repeat = true,
		PostTriggerEvents = {
			{ FunctionName = _PLUGIN.guid .. "." .. "EnterChthonicChidOverlook", Args = { OffsetY = args.OffsetY } },
		},
		OnRepeatEvents = {
			{ FunctionName = _PLUGIN.guid .. "." .. "LeaveChthonicChidOverlook" },
		},
	})
end

local function setupChthonicChidOverlook(room, rowCount)
	local id = spawnDisplayObstacle({
		Name = "BlankObstacle",
		DestinationId = shelfAnchorId,
		OffsetX = 160,
		OffsetY = 180,
		Group = "Standing",
	}, 1.0, 0.0)
	local args = {
		Id = id,
		OffsetY = rowCount > 1 and -250 or -150,
	}

	for _, event in ipairs(room.StartUnthreadedEvents or {}) do
		-- Reusing the existing one if it still exists from being in the room before during this save load
		if event.FunctionName == overlookStartFunctionName then
			event.Args = args
			return
		end
	end

	room.StartUnthreadedEvents = game.ShallowCopyTable(room.StartUnthreadedEvents or {})
	table.insert(room.StartUnthreadedEvents, { FunctionName = overlookStartFunctionName, Args = args, Threaded = true })
end
-- #endregion

function mod.SetupChthonicChidDisplay(room)
	if room == nil or room.Name ~= "Hub_PreRun" then
		return
	end

	local cosmeticIds = mod.RegisteredChthonicChids
	if #cosmeticIds == 0 then
		return
	end


	-- Creating new groups to ensure sort order works
	game.CreateGroup({ Name = displayGroup, BlendMode = "Normal" })
	game.InsertGroupInFront({ Name = displayGroup, DestinationName = "Standing" })
	game.CreateGroup({ Name = backGroup, BlendMode = "Normal" })
	game.InsertGroupBehind({ Name = backGroup, DestinationName = "Standing" })
	game.CreateGroup({ Name = frontGroup, BlendMode = "Normal" })
	game.InsertGroupInFront({ Name = frontGroup, DestinationName = displayGroup })

	local rowCount = math.ceil(#cosmeticIds / chidsPerRow)
	local rows = {}
	local previousGroup = displayGroup
	for row = 1, rowCount do
		local rowData = {
			OffsetX = row == 1 and -15 or -35,
			OffsetY = -shelfRowSpacing * row,
			ShelfGroup = displayGroup .. "." .. "Row" .. (row + 2),
			ChidGroups = {},
		}
		rows[row] = rowData
		game.CreateGroup({ Name = rowData.ShelfGroup, BlendMode = "Normal" })
		game.InsertGroupInFront({ Name = rowData.ShelfGroup, DestinationName = previousGroup })
		previousGroup = rowData.ShelfGroup

		for column = chidsPerRow, 1, -1 do
			local name = rowData.ShelfGroup .. "." .. "Column" .. column
			game.CreateGroup({ Name = name, BlendMode = "Normal" })
			game.InsertGroupInFront({ Name = name, DestinationName = previousGroup })
			rowData.ChidGroups[column] = name
			previousGroup = name
		end
	end

	local structureIds = {}
	for row, rowData in ipairs(rows) do
		table.insert(structureIds, spawnDisplayObstacle({
			Name = row == 1 and "CrossroadsWoodenSlab01a" or "CrossroadsWoodenSlab01",
			DestinationId = shelfAnchorId,
			OffsetX = rowData.OffsetX,
			OffsetY = rowData.OffsetY,
			Group = rowData.ShelfGroup,
		}, 0.303, 0.155))

		for index, anchorId in ipairs(backSupportAnchorIds) do
			table.insert(structureIds, spawnDisplayObstacle({
				Name = "CrossroadsStick02",
				DestinationId = anchorId,
				OffsetX = row == 1 and 0 or -20,
				OffsetZ = supportRowHeight * row - (index == 1 and 10 or 0),
				Group = backGroup,
			}, 0.222, 0.431))
		end
	end

	local hasFourthShelf = rowCount > 1
	local supportOffsetsX = hasFourthShelf and { -23, -29 } or { -10, -17 }
	local supportOffsetZ = supportRowHeight + (hasFourthShelf and 120 or 0)
	local supportScaleY = hasFourthShelf and 1.8 or 1.0
	for index, anchorId in ipairs(sideSupportAnchorIds) do
		local id = spawnDisplayObstacle({
			Name = "CrossroadsStick01",
			DestinationId = anchorId,
			OffsetX = supportOffsetsX[index],
			OffsetZ = supportOffsetZ,
			Group = index == 1 and frontGroup or "Standing",
		}, 0.252, index == 1 and 0.669 or 0.403)
		game.SetScaleY({ Id = id, Fraction = supportScaleY })
		game.SetAngle({ Id = id, Angle = index == 1 and 8 or 9 })
		table.insert(structureIds, id)
	end

	for index, cosmeticId in ipairs(cosmeticIds) do
		local row = math.floor((index - 1) / chidsPerRow) + 1
		local column = (index - 1) % chidsPerRow + 1
		local rowData = rows[row]
		local slot = chidSlotOffsets[column]
		local id = spawnDisplayObstacle({
			Name = "BlankObstacle",
			DestinationId = shelfAnchorId,
			OffsetX = rowData.OffsetX + slot.X,
			OffsetY = rowData.OffsetY + slot.Y,
			Group = rowData.ChidGroups[column],
		}, 1.0, 0.155)
		local cosmetic = game.WorldUpgradeData[cosmeticId]
		cosmetic.ActivateIds = { id }
		game.SetAnimation({ DestinationId = id, Name = cosmetic.SetAnimationValue })
	end

	game.SetAlpha({ Ids = structureIds, Fraction = 1 })
	setupChthonicChidOverlook(room, rowCount)
end

-- #endregion
