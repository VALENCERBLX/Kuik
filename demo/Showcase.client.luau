--!nonstrict
--[[
	Kuik showcase — every control the library has, in one window.

	Drop this in StarterPlayerScripts as a LocalScript with Kuik somewhere it
	can require from. Right Shift opens the window.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Kuik = require(script.Parent.Kuik)

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------
-- The window
--------------------------------------------------------------------------

local Window = Kuik.Window({
	Title    = "Kuik",
	Subtitle = "every control, one window",
	Key      = Enum.KeyCode.RightShift,
	Parallax = 10,
	Open     = true,
	Width    = 520,
	Height   = 560,
})

local Tabs = Window:Tabs()

--------------------------------------------------------------------------
-- Controls
--------------------------------------------------------------------------

local Controls = Tabs:Page("Controls")

local Basics = Controls:Section("Basics", "The things you set a value with")

Basics:Toggle({
	Label = "Enabled",
	Description = "A switch, the default toggle",
	Default = true,
	Callback = function(On)
		Kuik.Toast(On and "on" or "off", { Duration = 1 })
	end,
})

Basics:Toggle({ Label = "Checkbox", Variant = "Check", Default = true })
Basics:Toggle({ Label = "Lozenge", Variant = "Pill", On = "YES", Off = "NO" })

Basics:Slider({
	Label = "Master volume",
	Description = "Springs while you drag, snaps when you set it",
	Min = 0,
	Max = 100,
	Step = 1,
	Default = 72,
	Format = function(Value)
		return string.format("%d%%", Value)
	end,
})

Basics:Slider({
	Label = "Sensitivity",
	Variant = "Ticks",
	Min = 0,
	Max = 10,
	Step = 1,
	Default = 4,
})

Basics:Range({ Label = "Match length", Min = 0, Max = 60, Low = 10, High = 45 })
Basics:Stepper({ Label = "Rounds", Min = 1, Max = 9, Default = 3 })
Basics:Rating({ Label = "Difficulty", Count = 5, Default = 3 })

local Choosing = Controls:Section("Choosing", "One of many, or several of many")

Choosing:Dropdown({
	Label = "Quality",
	Items = { "Potato", "Low", "Medium", "High", "Ultra" },
	Default = "High",
})

Choosing:Dropdown({
	Label = "Filters",
	Description = "Multi select, with a filter field",
	Items = { "Rifles", "Pistols", "Blades", "Explosives", "Tools" },
	Multi = true,
	Search = true,
	Default = { "Rifles" },
})

Choosing:Segmented({ Label = "View", Items = { "List", "Grid", "Map" }, Default = "Grid" })
Choosing:Radio({ Label = "Team", Items = { "Red", "Blue", "Spectate" }, Default = "Red" })
Choosing:Radio({ Label = "Slots", Items = { "1", "2", "3", "4" }, Columns = 2 })
Choosing:Chips({ Label = "Tags", Items = { "fast", "quiet", "loud", "heavy" }, Default = { "quiet" }, Max = 2 })
Choosing:List({ Label = "Servers", Items = { "eu-west", "us-east", "ap-south" }, Default = "eu-west", Height = 90 })

local Typing = Controls:Section("Typing", "Fields")

Typing:Input({ Label = "Display name", Default = LocalPlayer.DisplayName })
Typing:Input({ Label = "Rounds", Numeric = true, Default = 12, Min = 0, Max = 30 })
Typing:Input({ Label = "Passphrase", Password = true, Placeholder = "secret" })
Typing:Search({ Label = "Find a player" })
Typing:TextArea({ Label = "Notes", Height = 70, Placeholder = "anything" })
Typing:Tags({ Label = "Aliases", Default = { "kr3" } })
Typing:Keybind({ Label = "Open menu", Default = Enum.KeyCode.RightShift })
Typing:Vector({ Label = "Spawn offset", Default = { 0, 5, 0 }, Step = 0.1 })

--------------------------------------------------------------------------
-- Readouts
--------------------------------------------------------------------------

local Readouts = Tabs:Page("Readouts")

local Live = Readouts:Section("Live", "Driven from the frame loop below")

local Fps = Live:Status({ Label = "Frame rate", Value = "-" })
local Ping = Live:Status({ Label = "Ping", Value = "-" })

Live:Stat({
	Items = {
		{ Label = "kills", Value = 14 },
		{ Label = "deaths", Value = 3, Color = Kuik.Theme.Danger },
		{ Label = "assists", Value = 7 },
	},
})

local Graph = Live:Graph({ Label = "Frame time", Values = {}, Height = 90, Grid = 3 })
local Spark = Live:Sparkline({ Label = "Memory", Values = { 1, 3, 2, 5, 4 } })
local Bars = Live:Bars({ Label = "Damage dealt", Values = { 4, 9, 2, 7, 5, 8 } })

local Meters = Readouts:Section("Meters", "Progress in every shape")

Meters:Progress({ Label = "Download", Default = 0.62 })
Meters:Meter({ Label = "Heat", Default = 78, Warn = 0.6, Danger = 0.85 })
Meters:Ring({ Label = "Charge", Default = 0.4 })
Meters:Spinner({ Label = "Matchmaking", Description = "Still looking" })

local Sets = Readouts:Section("Sets", "Rows and trees")

Sets:Table({
	Label = "Scoreboard",
	Sortable = true,
	Columns = {
		{ Label = "Player", Width = 0.5 },
		{ Label = "Kills", Align = "Right" },
		{ Label = "Ping", Align = "Right" },
	},
	Rows = {
		{ "kr3ative", 14, "22ms" },
		{ "guest_01", 9, "48ms" },
		{ "guest_02", 2, "180ms" },
	},
})

Sets:Tree({
	Label = "Loadout",
	Nodes = {
		{
			Label = "Primary",
			Open = true,
			Children = { { Label = "Silenced rifle" }, { Label = "Marksman" } },
		},
		{ Label = "Secondary", Children = { { Label = "Sidearm" } } },
	},
})

Sets:Heatmap({
	Label = "Activity",
	Values = {
		{ 1, 3, 5, 2 },
		{ 4, 8, 6, 1 },
		{ 2, 5, 9, 3 },
	},
})

Sets:Timeline({
	Label = "Round history",
	Items = {
		{ Label = "Match started", Time = "0:00" },
		{ Label = "First blood", Text = "kr3ative", Time = "0:42", Color = Kuik.Theme.Good },
		{ Label = "Objective taken", Time = "3:15" },
	},
})

Sets:Pagination({ Label = "Page", Pages = 6, Default = 1 })

--------------------------------------------------------------------------
-- Colour
--------------------------------------------------------------------------

local Colour = Tabs:Page("Colour")

local Pickers = Colour:Section("Pickers", "Three ways to choose one")

Pickers:ColorPicker({ Label = "Accent", Default = Color3.fromRGB(255, 72, 72) })
Pickers:Color({ Label = "Tint", Default = Color3.fromRGB(96, 156, 255) })

Pickers:Swatches({
	Label = "Team colour",
	Items = {
		Color3.fromRGB(255, 72, 72),
		Color3.fromRGB(96, 156, 255),
		Color3.fromRGB(96, 210, 128),
		Color3.fromRGB(255, 176, 46),
	},
})

Pickers:Gradient({ Label = "Sky ramp", From = Color3.fromRGB(20, 30, 60), To = Color3.fromRGB(255, 150, 90) })

local Themes = Colour:Section("Themes", "Repaints what is already on screen")

local Names = {}

for Name in Kuik.Themes do
	table.insert(Names, Name)
end

table.sort(Names)

Themes:Dropdown({
	Label = "Theme",
	Items = Names,
	Default = Kuik.GetTheme(),
	Width = 130,
	Callback = function(Name)
		Kuik.SetTheme(Name)
	end,
})

--------------------------------------------------------------------------
-- Media
--------------------------------------------------------------------------

local Media = Tabs:Page("Media")

local Pictures = Media:Section("Pictures", "Every embed decides its own plate")

Pictures:Image({
	Label = "With a plate",
	Description = "The default dark well behind the picture",
	Image = "rbxassetid://106133215461722",
	Height = 120,
})

Pictures:Image({
	Label = "No plate",
	Description = "Background = false",
	Image = "rbxassetid://106133215461722",
	Background = false,
	Height = 120,
})

Pictures:Image({
	Label = "A plate of your own",
	Background = Color3.fromRGB(40, 20, 60),
	BackgroundTransparency = 0.2,
	Image = "rbxassetid://106133215461722",
	Height = 120,
})

Pictures:Gallery({
	Label = "Carousel",
	Height = 90,
	Width = 130,
	Items = {
		{ Image = "rbxassetid://106133215461722", Label = "one" },
		{ Image = "rbxassetid://106133215461722", Label = "two" },
		{ Image = "rbxassetid://106133215461722", Label = "three" },
	},
})

Pictures:Avatar({
	Label = LocalPlayer.DisplayName,
	Description = "@" .. LocalPlayer.Name,
	UserId = LocalPlayer.UserId,
})

local Playable = Media:Section("Playable", "Sound, video and 3D")

Playable:Audio({ Label = "Ambience", Sound = "rbxassetid://9046863579" })
Playable:Viewport({ Label = "Model preview", Spin = true, Height = 150 })

--------------------------------------------------------------------------
-- Content
--------------------------------------------------------------------------

local Content = Tabs:Page("Content")

local Type = Content:Section("Type", "Copy and structure")

Type:Header({ Label = "A header", Description = "Breaks a page without a section" })
Type:Paragraph({ Text = "Body copy. Rules and type, almost no fill, square by default." })
Type:Quote({ Text = "Two rules, no panel.", Author = "the brief" })

Type:Code({
	Label = "Usage",
	Text = 'local Window = Kuik.Window({ Title = "Settings" })\nWindow:Toggle({ Label = "Enabled" })',
})

Type:Breadcrumb({ Path = { "Home", "Settings", "Audio" } })
Type:Steps({ Label = "Setup", Items = { "Account", "Controls", "Done" }, Default = 2 })
Type:Marquee({ Text = "a ticker that scrolls forever, forever, forever" })

local Notices = Content:Section("Notices", "Four weights of the same idea")

for _, Kind in { "Accent", "Solid", "Outline", "Subtle" } do
	Notices:Alert({
		Label = Kind,
		Text = "An alert in the " .. string.lower(Kind) .. " variant.",
		Variant = Kind,
		Color = Kuik.Theme.Info,
	})
end

Notices:Callout({ Label = "A callout is an alert with no title.", Color = Kuik.Theme.Warn })

local Buttons = Content:Section("Buttons", "Six variants and a rule bar")

for _, Variant in { "Pill", "Solid", "Outline", "Ghost", "Text", "Rule" } do
	Buttons:Button({
		Label = Variant,
		Action = "Run",
		Variant = Variant,
		Callback = function()
			Kuik.Toast(Variant .. " pressed", { Duration = 1.2 })
		end,
	})
end

Buttons:Rule({
	Action = "Commit",
	Callback = function()
		Kuik.Toast("committed", { Duration = 1.2 })
	end,
})

Buttons:Divider({
	Label = "or start over",
	Callback = function()
		Kuik.Toast("started over", { Duration = 1.2 })
	end,
})

local Nesting = Content:Section("Nesting", "Containers inside containers")

local Group = Nesting:Group({ Label = "A group", Variant = "Outline" })
Group:Toggle({ Label = "Inside a group" })
Group:Slider({ Label = "Also inside", Max = 10, Default = 4 })

local Split = Nesting:Columns({ Count = 2 })
Split:Column(1):Toggle({ Label = "Left" })
Split:Column(2):Toggle({ Label = "Right" })

local Fold = Nesting:Accordion({ Label = "An accordion", Description = "Everything fits inside" })
Fold:Toggle({ Label = "Nested toggle" })
Fold:Slider({ Label = "Nested slider", Max = 100, Default = 30 })
Fold:Alert({ Label = "Nested alert", Text = "Containers all the way down." })

Nesting:Toolbar({
	Items = { { Label = "Copy" }, { Label = "Paste" }, { Label = "Reset", Color = Kuik.Theme.Danger } },
	Callback = function(Item)
		Kuik.Toast(Item.Label, { Duration = 1 })
	end,
})

--------------------------------------------------------------------------
-- Navigation
--------------------------------------------------------------------------

local Navigation = Tabs:Page("Navigation")

local Detail = Window:Child({ Title = "Detail", Subtitle = "a sub window", Width = 280 })
Detail:Paragraph({ Text = "Parented beside the window it belongs to." })
Detail:Button({ Label = "Close", Action = "Close", Callback = function() Detail:Close() end })

local Going = Navigation:Section("Links", "A link goes anywhere, not just to a URL")

Going:Link({ Label = "Go to Controls", Target = "Controls" })
Going:Link({ Label = "Open the detail window", Target = Detail, Action = "Open" })
Going:Link({ Label = "Jump to the frame rate readout", Target = Fps, Action = "Find" })
Going:Link({ Label = "Run something", Target = function() Kuik.Toast("ran", { Duration = 1 }) end })
Going:Link({ Label = "Open a URL", Url = "https://github.com/VALENCERBLX/Kuik" })

local Modals = Navigation:Section("Modals", "Nothing behind a prompt is reachable")

Modals:Button({
	Label = "Ask a question",
	Action = "Ask",
	Callback = function()
		Kuik.Prompt({
			Title = "Leave the match?",
			Text = "Your progress this round will not be saved.",
			Buttons = {
				{ Label = "Stay" },
				{ Label = "Leave", Primary = true, Value = "leave" },
			},
			Callback = function(Choice)
				Kuik.Toast(Choice == "leave" and "left" or "stayed", { Duration = 1.4 })
			end,
		})
	end,
})

local ContextMenu = Kuik.Menu({
	Items = {
		{ Label = "Inspect", Shortcut = "I" },
		{ Label = "Duplicate", Shortcut = "D" },
		{ Separator = true },
		{ Label = "Delete", Color = Kuik.Theme.Danger },
	},
	Callback = function(Item)
		Kuik.Toast(Item.Label, { Duration = 1 })
	end,
})

Modals:Button({
	Label = "Context menu",
	Action = "Show",
	Callback = function()
		ContextMenu:ShowAtMouse()
	end,
})

--------------------------------------------------------------------------
-- HUD
--------------------------------------------------------------------------

local HudPage = Tabs:Page("HUD")

local Screen = HudPage:Section("On the screen", "None of these live in a window")

local Pieces = {}

local function Build(Name, Make)
	Screen:Toggle({
		Label = Name,
		Callback = function(On)
			if Pieces[Name] then
				Pieces[Name]:Destroy()
				Pieces[Name] = nil
			end

			if On then
				Pieces[Name] = Make()
			end
		end,
	})
end

Build("Watermark", function()
	local Mark = Kuik.Watermark({ Tag = { Text = "KUIK" } })
	Mark:Set({ "showcase", LocalPlayer.DisplayName })
	return Mark
end)

Build("Crosshair", function()
	return Kuik.Crosshair({ Dot = true })
end)

Build("Ammo", function()
	return Kuik.Ammo({ Weapon = "SILENCED", Magazine = 7, Reserve = 21, Capacity = 7 })
end)

Build("Health bar", function()
	local Bar = Kuik.Bar({
		Label = "HEALTH",
		Max = 100,
		Default = 100,
		Warn = 0.5,
		Danger = 0.25,
		Width = 240,
	})

	task.spawn(function()
		local Value = 100

		while Bar.Frame.Parent do
			Value -= 7

			if Value <= 0 then
				Value = 100
			end

			Bar:Set(Value)
			task.wait(0.7)
		end
	end)

	return Bar
end)

Build("Objective", function()
	return Kuik.Objective({ Label = "OBJECTIVE", Text = "Reach the roof", Progress = 0.35 })
end)

Build("Hints", function()
	local Hints = Kuik.Hints()
	Hints:Add("E", "interact")
	Hints:Add("Q", "lean left")
	Hints:Add("R", "reload")
	return Hints
end)

Build("Compass", function()
	return Kuik.Compass()
end)

Build("Vignette", function()
	return Kuik.Vignette({ Strength = 0.4 })
end)

Build("Killfeed", function()
	local Feed = Kuik.Killfeed()

	task.spawn(function()
		while Feed.Frame.Parent do
			Feed:Push(LocalPlayer.DisplayName, "eliminated", "guard")
			task.wait(3)
		end
	end)

	return Feed
end)

Build("Console", function()
	local Console = Kuik.Console()

	task.spawn(function()
		local Levels = { "INFO", "SUCCESS", "WARN", "ERROR", "DEBUG" }
		local At = 0

		while Console.Frame.Parent do
			At = At % #Levels + 1
			Console:Push(Levels[At], "a line of output")
			task.wait(1.5)
		end
	end)

	return Console
end)

Build("Log", function()
	local Log = Kuik.Log()

	task.spawn(function()
		while Log.Frame.Parent do
			Log:Push("something happened")
			task.wait(2)
		end
	end)

	return Log
end)

Build("Timer", function()
	return Kuik.Timer({ Seconds = 120 })
end)

local Messages = HudPage:Section("Messages", "Transient")

Messages:Button({
	Label = "Toast",
	Action = "Show",
	Callback = function()
		Kuik.Toast("a toast between two rules", { Duration = 2 })
	end,
})

Messages:Button({
	Label = "Notify",
	Action = "Show",
	Callback = function()
		Kuik.Notify({ Title = "Saved", Text = "Everything is up to date." })
	end,
})

--------------------------------------------------------------------------
-- Panels
--------------------------------------------------------------------------

local PanelPage = Tabs:Page("Panels")

PanelPage:Paragraph({
	Text = "A panel is a window with the chrome stripped. Same controls, no "
		.. "header, no backdrop, no scroller — park it anywhere and drag it.",
})

local Loose = nil

PanelPage:Toggle({
	Label = "A loose panel",
	Description = "Draggable and resizable, docked top left",
	Callback = function(On)
		if Loose then
			Loose:Destroy()
			Loose = nil
		end

		if not On then
			return
		end

		Loose = Kuik.Panel({
			Dock = "TopLeft",
			Position = UDim2.new(0, 24, 0, 24),
			Width = 240,
			Height = 120,
			Draggable = true,
			Resizable = true,
			Variant = "Card",
		})

		Loose:Header({ Label = "Loose panel", Description = "Drag me" })
		Loose:Progress({ Label = "Stamina", Default = 0.6 })
	end,
})

local Deck = nil

PanelPage:Button({
	Label = "Card deck",
	Description = "A horizontal carousel of windows",
	Action = "Open",
	Callback = function()
		if Deck then
			Deck:Destroy()
			Deck = nil
			return
		end

		Deck = Kuik.Cards({ Gap = 90 })

		for Index = 1, 4 do
			local Card = Kuik.Window({
				Title = "Card " .. Index,
				Width = 300,
				Height = 340,
				Blur = 0,
				Wash = 0.5,
			})

			Card:Paragraph({ Text = "Left and right, or Q and E, move the deck." })
			Card:Slider({ Label = "A slider", Max = 100, Default = Index * 20 })

			Card:Button({
				Label = "Close the deck",
				Action = "Close",
				Callback = function()
					Deck:Destroy()
					Deck = nil
				end,
			})

			Deck:Add(Card)
		end
	end,
})

--------------------------------------------------------------------------
-- The frame loop that feeds the live readouts
--------------------------------------------------------------------------

local Elapsed = 0
local Frames = 0

RunService.RenderStepped:Connect(function(Delta)
	Elapsed += Delta
	Frames += 1

	if Elapsed < 0.25 then
		return
	end

	local Rate = Frames / Elapsed

	Fps:Set(string.format("%d fps", math.floor(Rate + 0.5)))
	Ping:Set(string.format("%d ms", math.floor(Delta * 1000 + 0.5)))

	Graph:Push(Delta * 1000)
	Spark:Push(math.random(1, 9))
	Bars:Push(math.random(1, 9))

	Elapsed = 0
	Frames = 0
end)

Tabs:Select("Controls")

Kuik.Toast("Right Shift to close", { Duration = 3 })
