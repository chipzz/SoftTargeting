local Number = Settings.VarType.Number

local function Options(...)
	local entries = { ... }
	return function()
		local container = Settings.CreateControlTextContainer()
		for i = 1, #entries, 2 do
			container:Add(entries[i], entries[i + 1])
		end
		return container:GetData()
	end
end

local ModeOptions = Options(
	Enum.SoftTargetEnableFlags.None,    "Off",
	Enum.SoftTargetEnableFlags.Gamepad, "Gamepad only",
	Enum.SoftTargetEnableFlags.Kbm,     "Keyboard & mouse only",
	Enum.SoftTargetEnableFlags.Any,     "Always")

local ArcOptions = Options(
	0, "Directly in front",
	1, "In front arc",
	2, "Anywhere in targeting area")

local ForceOptions = Options(
	0, "Off",
	1, "Enemies",
	2, "Friends")

local MatchLockedOptions = Options(
	0, "Off",
	1, "Hard-locked target only",
	2, "Also targets you attack")

local WithLockedOptions = Options(
	0, "Off",
	1, "Allowed",
	2, "Always")

local function UnitTypePage(key, noun)
	return {
		{ cvar = "SoftTarget" .. key, label = "Mode", options = ModeOptions,
		  tooltip = "When " .. noun .. " soft targeting is active." },
		{ cvar = "SoftTarget" .. key .. "Arc", label = "Arc", options = ArcOptions,
		  tooltip = "How far off your facing a " .. noun .. " soft target may be." },
		{ cvar = "SoftTarget" .. key .. "Range", label = "Range", slider = { 0, 45, 1 },
		  tooltip = "Maximum range in yards, limited by tab targeting range." },
		{ cvar = "SoftTargetNameplate" .. key, label = "Always show nameplate",
		  tooltip = "Always show the nameplate of the soft " .. noun .. " target." },
		{ cvar = "SoftTargetIcon" .. key, label = "Show icon",
		  tooltip = "Show an icon on the soft " .. noun .. " target." },
		{ cvar = "SoftTargetTooltip" .. key, label = "Show tooltip",
		  tooltip = "Show a tooltip for the soft " .. noun .. " target." },
	}
end

local ProtectedCVars = {
	SoftTargetEnemy = true,
	SoftTargetEnemyRange = true,
	SoftTargetForce = true,
	SoftTargetInteract = true,
	SoftTargetInteractRange = true,
}

local Pages = {
	{
		name = "Soft Targeting",
		controls = {
			{ header = "Locked Target" },
			{ cvar = "SoftTargetForce", label = "Set target to soft target", options = ForceOptions,
			  tooltip = "Automatically make the soft target your real target." },
			{ cvar = "SoftTargetMatchLocked", label = "Match locked target", options = MatchLockedOptions,
			  tooltip = "Make the soft target follow your locked target." },
			{ cvar = "SoftTargetWithLocked", label = "Soft target while locked", options = WithLockedOptions,
			  tooltip = "Allow soft target selection while you have a locked target." },
			{ cvar = "SoftTargetTooltipLocked", label = "Tooltip for locked target",
			  tooltip = "Show the soft target tooltip for your locked target as well." },
			{ header = "Display" },
			{ cvar = "SoftTargetNameplateSize", label = "Nameplate icon size", slider = { 0, 64, 1 },
			  tooltip = "Size of the soft target icon on nameplates (0 to disable)." },
			{ cvar = "SoftTargetTooltipDurationMs", label = "Tooltip duration (ms)", slider = { 0, 10000, 250 },
			  tooltip = "How long the soft target tooltip stays up." },
			{ cvar = "SoftTargetWorldtextSize", label = "World text size", slider = { 8, 64, 1 } },
			{ cvar = "SoftTargetWorldtextNearDist", label = "World text near distance", slider = { 0, 40, 1 } },
			{ cvar = "SoftTargetWorldtextFarDist", label = "World text far distance", slider = { 0, 100, 1 } },
			{ cvar = "SoftTargetWorldtextNearScale", label = "World text near scale", slider = { 0.5, 3, 0.1 } },
		},
	},
	{ name = "Enemy", controls = UnitTypePage("Enemy", "enemy") },
	{ name = "Friend", controls = UnitTypePage("Friend", "friend") },
	{ name = "Interact", controls = UnitTypePage("Interact", "interact") },
}

local interact = Pages[4].controls
table.insert(interact, { header = "Interact Extras" })
table.insert(interact, { cvar = "SoftTargetInteractRangeIsHard", label = "Hard range cutoff",
	tooltip = "Enforce the range even for things you could interact with right now." })
table.insert(interact, { cvar = "SoftTargetInteractOnlyInRange", label = "Only in range",
	tooltip = "Only soft target interacts that are within range." })
table.insert(interact, { cvar = "SoftTargetIconGameObject", label = "Icons on game objects",
	tooltip = "Show icons on interactable objects you cannot normally target." })
table.insert(interact, { cvar = "SoftTargetLowPriorityIcons", label = "Low priority icons",
	tooltip = "Show interact icons even when quest or loot effects already mark the target." })
table.insert(interact, { cvar = "softTargettingInteractKeySound",
	label = "Interact key sound", tooltip = "Play sound cues for the interact key." })

local function OutOfCombat()
	return not InCombatLockdown()
end

-- Settings.SetupCVar* build their setting objects in the caller's (insecure)
-- context, and Settings.GetSetting reads every registered setting, so those
-- taint Blizzard code such as action button clicks. Proxy settings are built
-- by Blizzard's secure handler instead.
local function RegisterCVar(category, control, variableType)
	local getValue, setValue, getDefault = Settings.CreateCVarAccessorClosures(control.cvar, variableType)
	return Settings.RegisterProxySetting(category, "SOFTTARGETING_" .. control.cvar:upper(), variableType,
		control.label, getDefault(), getValue, setValue)
end

local function AddControl(category, layout, control)
	if control.header then
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(control.header))
		return
	end

	-- The CVar set differs per client (SoftTargetInteractOnlyInRange is Forever-only).
	if not C_CVar.GetCVar(control.cvar) then
		return
	end

	local initializer
	if control.options then
		local setting = RegisterCVar(category, control, Number)
		initializer = Settings.CreateDropdown(category, setting, control.options, control.tooltip)
	elseif control.slider then
		local options = Settings.CreateSliderOptions(unpack(control.slider))
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		local setting = RegisterCVar(category, control, Number)
		initializer = Settings.CreateSlider(category, setting, options, control.tooltip)
	else
		local setting = RegisterCVar(category, control, Settings.VarType.Boolean)
		initializer = Settings.CreateCheckbox(category, setting, control.tooltip)
	end

	if ProtectedCVars[control.cvar] then
		initializer:AddModifyPredicate(OutOfCombat)
	end
end

do
	local root, rootLayout = Settings.RegisterVerticalLayoutCategory(Pages[1].name)
	for _, control in ipairs(Pages[1].controls) do
		AddControl(root, rootLayout, control)
	end

	for i = 2, #Pages do
		local page = Pages[i]
		local category, layout = Settings.RegisterVerticalLayoutSubcategory(root, page.name)
		for _, control in ipairs(page.controls) do
			AddControl(category, layout, control)
		end
	end

	Settings.RegisterAddOnCategory(root)
end
