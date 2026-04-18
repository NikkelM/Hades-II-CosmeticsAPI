-- Add the base cosmetic overrides for vanilla cosmetics here
-- You can most often get the SetAnimationValue from the Game/Obstacles/Crossroads.sjson file
-- Most obstacles in this file are named "Crossroads<Cosmetic name without 'Cosmetic_' prefix>01"
-- The SetAnimationValue we need is the "Thing.Graphic" of the obstacle, NOT the obstacle name itself
-- Some cosmetics may require additional overrides to work correctly with modded cosmetics, you can add them here as well
-- This is e.g. the case if the vanilla cosmetic defines ActivateIds, which would all get set to the new SetAnimationValue if no separate SetAnimationIds table is provided
mod.KnownExtraDecorBaseAnimations = {
	-- #region CosmeticsShop_Tent
	-- #endregion
	-- #region CosmeticsShop_Main
	Cosmetic_HecateKey = {
		SetAnimationValue = "Tilesets\\Crossroads\\Crossroads_Hecate_Key_01",
	},
	Cosmetic_BrokerLantern01 = {
		SetAnimationValue = "Tilesets\\Crossroads\\Crossroads_Broker_Lantern_01",
		-- Otherwise, all of it's ActivateIds get set to the SetAnimationValue
		SetAnimationIds = { 743049 },
	},
	Cosmetic_CauldronRing01 = {
		SetAnimationValue = "Tilesets\\Crossroads\\Crossroads_Terrain_StoneCircle_01",
	},
	-- #endregion
	-- #region CosmeticsShop_Taverna
	Cosmetic_TavernaStarMosaic = {
		SetAnimationValue = "Tilesets\\Crossroads\\Crossroads_Terrain_Taverna_Mosaic_01",
	},
	-- #endregion
	-- #region CosmeticsShop_PreRun
	Cosmetic_SkellyZagreusStatue = {
		SetAnimationValue = "Tilesets\\Crossroads\\Crossroads_Skelly_ZagreusStatue_01",
	},
	-- #endregion
}

mod.ValidLanguageCodes = {
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

mod.AddedCosmeticSjsonTextData = {}
mod.AddedCosmeticSjsonAnimationData = {}
-- Is used to track mappings of CosmeticIds to their lid animation paths, to be used in ApplyCauldronCookTopGraphic()
mod.RegisteredCauldrons = {}

---Logs a message at the specified log level with colour coding.
---@param t any The message to log.
---@param level number|nil The log level. 0 = Off, 1 = Errors, 2 = Warnings, 3 = Info, 4 = Debug. nil omits the level display.
function mod.LogMessage(t, level)
	if level == 1 then
		-- Using rom.log.error would actually throw an error
		print(string.format("\27[31m[ERROR] %s\27[0m", tostring(t)))
	elseif level == 2 then
		rom.log.warning(tostring(t))
	elseif level == 3 then
		rom.log.info(tostring(t))
	elseif level == 4 then
		rom.log.debug(tostring(t))
	end
end

---Prints a message to the console at the specified log level
---@param t any The message to print.
---@param level number|nil The verbosity level required to print the message. 0 = Off/Always printed, 1 = Errors, 2 = Warnings, 3 = Info, 4 = Debug
function mod.DebugPrint(t, level)
	level = level or 0
	if config.logLevel >= level then
		if type(t) == "table" then
			-- Tables are always logged without a level display
			mod.PrintTable(t, nil, nil)
		else
			mod.LogMessage(t, level)
		end
	end
end

---Prints a table (or any other printable entity) up to a certain depth.
---@param t any The table to print, can also be another printable entity.
---@param maxDepth number|nil The maximum depth to print the table to, after which it is cut off with ...
---@param indent number|nil The current indentation level.
function mod.PrintTable(t, maxDepth, indent)
	if type(t) ~= "table" then
		print(t)
		return
	end

	indent = indent or 0
	maxDepth = maxDepth or 20
	if indent > maxDepth then
		print(string.rep("  ", indent) .. "...")
		return
	end

	local formatting = string.rep("  ", indent)
	for k, v in pairs(t) do
		if type(v) == "table" then
			print(formatting .. k .. ":")
			mod.PrintTable(v, maxDepth, indent + 1)
		else
			print(formatting .. k .. ": " .. tostring(v))
		end
	end
end

---Logs a warning about an incorrect type in the passed cosmeticsData.
---@param fieldName string The name of the field with the incorrect type.
---@param expectedType string The expected type of the field.
---@param actualType string The actual type of the field.
---@param cosmeticId string The ID of the cosmetic data where the incorrect type was found.
function mod.WarnIncorrectType(fieldName, expectedType, actualType, cosmeticId)
	mod.DebugPrint("[CosmeticsAPI] Warning: Field '" .. fieldName .. "' has incorrect type '" ..
		actualType .. "' (expected '" .. expectedType ..
		"') in cosmetic data: " .. cosmeticId, 2)
end
