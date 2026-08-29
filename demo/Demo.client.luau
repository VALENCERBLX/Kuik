--!nonstrict
--[[
	Kuik demo — a rebuild of the reference settings panel and the HUD
	layer around it.

	Drop this in StarterPlayer > StarterPlayerScripts as a LocalScript, with
	the Kuik module in ReplicatedStorage.

	TAB opens the panel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Kuik = require(ReplicatedStorage:WaitForChild("Kuik"))

local LocalPlayer = Players.LocalPlayer

--- Everything the panel writes to. In a real game this is your settings
--- store; here it just holds values so the callbacks have somewhere to go.
local Settings = {
	FieldOfView      = 100,
	CameraSmoothing  = true,
	SmoothingStrength = 13,
	ShowInterface    = true,
	WatermarkSide    = "Left",
	Parallax         = true,
	ParallaxAmount   = 5,
	MasterVolume     = 80,
}


--============================================================================
-- HUD
--============================================================================

local Watermark = Kuik.Watermark({
	Side = Settings.WatermarkSide,
	Tag  = { Text = "PROTOTYPING", Color = Kuik.Theme.Danger },
	Fields = {
		"HL_v1",
		string.format("HL-260829-%s::%s", string.upper(string.sub(tostring(os.time()), -8)), LocalPlayer.Name),
		os.date("%B %d, %Y %I:%M %p"),
	},
})

local Hints = Kuik.Hints()
Hints:Add("SHIFT", "Sprint")
Hints:Add("1", "Equip Primary")
Hints:Add("Y", "Unlock Mouse")
Hints:Add("TAB", "Open Settings")

local Log = Kuik.Log({ Limit = 6 })
Log:Push("Welcome to <b>HAIRLINE</b>!")
Log:Push(string.format("Roblox Server: %s", game.JobId ~= "" and game.JobId or "studio"))
Log:Push(string.format("Players online: %d/%d", #Players:GetPlayers(), Players.MaxPlayers))
Log:Push('Your role is <font color="#5c9cff">CONSERVATOR</font>.')

local Console = Kuik.Console()
Console:Push("SUCCESS", "session v0 -> v1")

--- Persistent state: no duration, so it stays until something destroys it.
local Waiting = Kuik.Toast(
	string.format("The game cannot start until at least 5 players have joined. There are currently %d players in this server.", #Players:GetPlayers())
)


--============================================================================
-- Settings panel
--============================================================================

local Window = Kuik.Window({
	Title    = "Settings",
	Subtitle = "Manage your preferences",
	Key      = Enum.KeyCode.Tab,
	Parallax = Settings.Parallax and Settings.ParallaxAmount or 0,
})

local Categories = Window:Section("Categories", "Choose a category to configure.")
local Tabs       = Categories:Tabs()

local Camera = Tabs:Page("Camera")
local Visual = Tabs:Page("Visual")
local State  = Tabs:Page("State")
local Audio  = Tabs:Page("Audio")


--------------------------------------------------------------------------
-- Camera
--------------------------------------------------------------------------

Camera:Slider({
	Label       = "Field of View",
	Description = "Camera field of view.",
	Min = 60, Max = 120, Step = 1,
	Default     = Settings.FieldOfView,
	Callback    = function(Value)
		Settings.FieldOfView = Value

		if workspace.CurrentCamera then
			workspace.CurrentCamera.FieldOfView = Value
		end
	end,
})

Camera:Toggle({
	Label       = "Camera Smoothness",
	Description = "Smooth camera movement while looking around.",
	Default     = Settings.CameraSmoothing,
	Callback    = function(Value)
		Settings.CameraSmoothing = Value
	end,
})

Camera:Slider({
	Label       = "Smoothness",
	Description = "Camera smoothing strength.",
	Min = 0, Max = 30, Step = 1,
	Default     = Settings.SmoothingStrength,
	Callback    = function(Value)
		Settings.SmoothingStrength = Value
	end,
})


--------------------------------------------------------------------------
-- Visual
--------------------------------------------------------------------------

Visual:Toggle({
	Label       = "Show UI/UX",
	Description = "Show and configure interface elements.",
	Default     = Settings.ShowInterface,
	Callback    = function(Value)
		Settings.ShowInterface = Value
		Hints.Frame.Visible = Value
		Log.Frame.Visible = Value
	end,
})

Visual:Dropdown({
	Label       = "Watermark Side",
	Description = "Choose which side displays the bottom watermark.",
	Items       = { "Left", "Right" },
	Default     = Settings.WatermarkSide,
	Callback    = function(Value)
		Settings.WatermarkSide = Value
		Watermark:SetSide(Value)
	end,
})

Visual:Toggle({
	Label       = "UI Parallax",
	Description = "Move interface elements with camera motion.",
	Default     = Settings.Parallax,
	Callback    = function(Value)
		Settings.Parallax = Value
		Window:SetParallax(Value and Settings.ParallaxAmount or 0)
	end,
})

Visual:Stepper({
	Label       = "Movement amount",
	Description = "Adjust how far the interface drifts.",
	Min = 0, Max = 20, Step = 1,
	Default     = Settings.ParallaxAmount,
	Callback    = function(Value)
		Settings.ParallaxAmount = Value

		if Settings.Parallax then
			Window:SetParallax(Value)
		end
	end,
})


--------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------

State:Paragraph({
	Label = "Session",
	Text  = "Diagnostics for the current server. Values here are read-only and refresh on open.",
})

local PlayerCount = State:Input({
	Label       = "Players",
	Description = "Connected clients.",
	Default     = tostring(#Players:GetPlayers()),
})

State:Keybind({
	Label       = "Open settings",
	Description = "Rebind the key that opens this panel.",
	Default     = Enum.KeyCode.Tab,
	Callback    = function(Key)
		Console:Push("INFO", string.format("settings bind -> %s", Key.Name))
	end,
})

State:Button({
	Label       = "Reset preferences",
	Description = "Restore every setting to its default.",
	Action      = "Reset",
	Callback    = function()
		Console:Push("WARN", "preferences reset by user")
		Kuik.Notify({ Title = "Preferences reset" })
	end,
})


--------------------------------------------------------------------------
-- Audio
--------------------------------------------------------------------------

Audio:Slider({
	Label       = "Master volume",
	Description = "Overall output level.",
	Min = 0, Max = 100, Step = 1,
	Default     = Settings.MasterVolume,
	Callback    = function(Value)
		Settings.MasterVolume = Value
	end,
})

Audio:Slider({
	Label       = "Voice ducking",
	Description = "How far other audio drops while someone is speaking.",
	Min = 0, Max = 1, Step = 0.05,
	Default     = 0.4,
})


--============================================================================
-- Live HUD
--============================================================================

local function Refresh()
	local Count = #Players:GetPlayers()

	PlayerCount:Set(tostring(Count), true)

	if Count >= 5 then
		if Waiting then
			Waiting:Destroy()
			Waiting = nil
		end
	elseif Waiting then
		Waiting:Set(string.format(
			"The game cannot start until at least 5 players have joined. There are currently %d players in this server.",
			Count
		))
	end
end

Players.PlayerAdded:Connect(function(Player)
	Kuik.Notify({
		Title = string.format("<b>%s</b> joined", Player.DisplayName),
	})

	Log:Push(string.format("%s joined the server.", Player.DisplayName))
	Refresh()
end)

Players.PlayerRemoving:Connect(function(Player)
	Console:Push("WARN", string.format("%s VOTE-1001 reason=Left the server.", Player.Name))
	Log:Push(string.format("%s left the server.", Player.DisplayName))
	task.defer(Refresh)
end)

Refresh()
