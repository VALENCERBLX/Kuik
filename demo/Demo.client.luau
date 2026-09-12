--!nonstrict
--[[
	Kuik quickstart — the smallest thing worth reading.

	A settings window on a key, and a HUD built out of panels rather than
	windows. Drop this in StarterPlayerScripts with Kuik beside it.
]]

local Players = game:GetService("Players")

local Kuik = require(script.Parent.Kuik)

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------
-- A settings window
--------------------------------------------------------------------------

local Settings = {
	Sensitivity = 0.4,
	Crosshair = true,
	Quality = "High",
}

local Window = Kuik.Window({
	Title    = "Settings",
	Subtitle = "right shift to close",
	Key      = Enum.KeyCode.RightShift,
	Open     = true,
})

local Tabs = Window:Tabs()

local Controls = Tabs:Page("Controls")

Controls:Slider({
	Label = "Sensitivity",
	Min = 0,
	Max = 1,
	Step = 0.05,
	Default = Settings.Sensitivity,
	Callback = function(Value)
		Settings.Sensitivity = Value
	end,
})

Controls:Keybind({ Label = "Interact", Default = Enum.KeyCode.E })

local Display = Tabs:Page("Display")

Display:Dropdown({
	Label = "Quality",
	Items = { "Low", "Medium", "High", "Ultra" },
	Default = Settings.Quality,
	Callback = function(Value)
		Settings.Quality = Value
	end,
})

Display:Toggle({
	Label = "Crosshair",
	Default = Settings.Crosshair,
	Callback = function(On)
		Settings.Crosshair = On
	end,
})

Display:Dropdown({
	Label = "Theme",
	Items = { "Remorse", "Redliner", "Ember", "Terminal", "Midnight", "Paper" },
	Default = "Remorse",
	Width = 130,
	Callback = function(Name)
		Kuik.SetTheme(Name)
	end,
})

--------------------------------------------------------------------------
-- A HUD, built out of panels
--------------------------------------------------------------------------

--- A panel is a window with no chrome: no header, no backdrop, no blur, no
--- scroller, and it does not unlock the mouse. Everything a window can do it
--- can do, so a HUD element is not a different kind of object.
local Vitals = Kuik.Panel({
	Dock   = "BottomLeft",
	Position = UDim2.new(0, 24, 1, -24),
	Width  = 240,
	Height = 74,
})

local Health = Vitals:Progress({
	Label = "Health",
	Default = 1,
	Flat = true,
	Color = Kuik.Theme.Good,
	Format = function(Value)
		return string.format("%d", math.floor(Value * 100 + 0.5))
	end,
})

local Stamina = Vitals:Progress({
	Label = "Stamina",
	Default = 1,
	Flat = true,
	Color = Kuik.Theme.Info,
})

local Watermark = Kuik.Watermark({ Tag = { Text = "KUIK" } })
Watermark:Set({ LocalPlayer.DisplayName, "demo" })

local Crosshair = Kuik.Crosshair({ Dot = true })

--------------------------------------------------------------------------
-- Wire the HUD to the character
--------------------------------------------------------------------------

local function Follow(Character)
	local Humanoid = Character:WaitForChild("Humanoid")

	local function Sync()
		Health:Set(Humanoid.Health / math.max(1, Humanoid.MaxHealth))
	end

	Humanoid.HealthChanged:Connect(Sync)
	Sync()
end

if LocalPlayer.Character then
	Follow(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(Follow)

task.spawn(function()
	while true do
		Stamina:Set(0.4 + math.abs(math.sin(os.clock())) * 0.6)
		Crosshair:SetVisible(Settings.Crosshair)
		task.wait(0.1)
	end
end)

Kuik.Toast("Kuik demo", { Duration = 2.5 })
