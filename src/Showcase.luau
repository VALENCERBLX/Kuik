--!nonstrict
--- Showcase.luau — every control the library has, in one window.
---
---   Kuik.Showcase()
---
--- Built for looking at rather than for reading: if something is broken, it is
--- broken here, and every control is present with realistic options so the
--- window doubles as a test page.

local Players = game:GetService("Players")

local Palette  = require(script.Parent.Theme)
local Util     = require(script.Parent.Util)
local Controls = require(script.Parent.Controls)

local Theme = Palette.Tokens

local LocalPlayer = Players.LocalPlayer

--- A stand-in picture. Any asset works; this one is only here so the media
--- controls have something to draw.
local PICTURE = "rbxassetid://106133215461722"

return function(Kuik, Options)
	Options = Options or {}

	local Window = Kuik.Window({
		Title    = Options.Title or "Kuik",
		Subtitle = Options.Subtitle or string.format("%s - every control", Kuik.Version.Version),
		Width    = Options.Width or 540,
		Height   = Options.Height or 620,
		Key      = Options.Key,
		Open     = Options.Open ~= false,
		Blur     = Options.Blur,
		Parallax = Options.Parallax or 8,
	})

	--- Anything that throws is reported in the window rather than in the
	--- output, so a broken control is visible where it should have been.
	local Broken = {}

	local function Safe(Page, Name, Build)
		local Ok, Err = pcall(Build)

		if Ok then
			return
		end

		table.insert(Broken, Name)

		Page:Alert({
			Label = Name .. " failed to build",
			Text = tostring(Err),
			Color = Theme.Danger,
		})
	end

	local Tabs = Window:Tabs()

	----------------------------------------------------------------------
	-- Input
	----------------------------------------------------------------------

	local Input = Tabs:Page("Input")

	local Switches = Input:Section("Switches", "Three looks, one behaviour")

	Safe(Switches, "Toggle", function()
		Switches:Toggle({ Label = "Switch", Description = "The default toggle", Default = true })
	end)

	Safe(Switches, "Checkbox", function()
		Switches:Checkbox({ Label = "Checkbox", Description = "A box and a tick", Default = true })
	end)

	Safe(Switches, "Tristate", function()
		Switches:Tristate({ Label = "Tristate", Description = "Off, on, or neither" })
	end)

	Safe(Switches, "Toggle pill", function()
		Switches:Toggle({ Label = "Lozenge", Variant = "Pill", On = "YES", Off = "NO" })
	end)

	local Numbers = Input:Section("Numbers", "Anything with a range")

	Safe(Numbers, "Slider", function()
		Numbers:Slider({ Label = "Slider", Min = 0, Max = 100, Default = 62 })
	end)

	Safe(Numbers, "Slider ticks", function()
		Numbers:Slider({ Label = "Notched", Variant = "Ticks", Min = 0, Max = 10, Step = 1, Default = 4 })
	end)

	Safe(Numbers, "Range", function()
		Numbers:Range({ Label = "Range", Min = 0, Max = 100, Low = 25, High = 70 })
	end)

	Safe(Numbers, "Stepper", function()
		Numbers:Stepper({ Label = "Stepper", Min = 0, Max = 9, Default = 3 })
	end)

	Safe(Numbers, "Knob", function()
		Numbers:Knob({ Label = "Knob", Min = 0, Max = 11, Default = 7 })
	end)

	Safe(Numbers, "Rating", function()
		Numbers:Rating({ Label = "Rating", Default = 3 })
	end)

	Safe(Numbers, "Vector", function()
		Numbers:Vector({ Label = "Vector", Default = { 0, 5, 0 }, Step = 0.1 })
	end)

	local Fields = Input:Section("Fields", "Typing")

	Safe(Fields, "Input", function()
		Fields:Input({ Label = "Text", Default = LocalPlayer and LocalPlayer.DisplayName or "name" })
	end)

	Safe(Fields, "Numeric", function()
		Fields:Input({ Label = "Numeric", Numeric = true, Default = 12, Min = 0, Max = 30 })
	end)

	Safe(Fields, "Password", function()
		Fields:Input({ Label = "Password", Password = true, Placeholder = "secret" })
	end)

	Safe(Fields, "TextArea", function()
		Fields:TextArea({ Label = "Text area", Height = 64, Placeholder = "several lines" })
	end)

	Safe(Fields, "Search", function()
		Fields:Search({ Label = "Search" })
	end)

	Safe(Fields, "Autocomplete", function()
		Fields:Autocomplete({
			Label = "Autocomplete",
			Items = { "Halcyon", "Continental", "Freeport", "Undertown", "Spire" },
		})
	end)

	Safe(Fields, "Keybind", function()
		Fields:Keybind({ Label = "Keybind", Default = Enum.KeyCode.E })
	end)

	Safe(Fields, "Tags", function()
		Fields:Tags({ Label = "Tags", Default = { "quiet" } })
	end)

	local Choosing = Input:Section("Choosing", "One of many, or several")

	Safe(Choosing, "Dropdown", function()
		Choosing:Dropdown({
			Label = "Dropdown",
			Items = { "Potato", "Low", "Medium", "High", "Ultra" },
			Default = "High",
		})
	end)

	Safe(Choosing, "Multi dropdown", function()
		Choosing:Dropdown({
			Label = "Multi select",
			Items = { "Rifles", "Pistols", "Blades", "Tools" },
			Multi = true,
			Search = true,
			Default = { "Rifles" },
		})
	end)

	Safe(Choosing, "Segmented", function()
		Choosing:Segmented({ Label = "Segmented", Items = { "List", "Grid", "Map" }, Default = "Grid" })
	end)

	Safe(Choosing, "Radio", function()
		Choosing:Radio({ Label = "Radio", Items = { "Red", "Blue", "Spectate" }, Default = "Red" })
	end)

	Safe(Choosing, "Radio columns", function()
		Choosing:Radio({ Label = "Radio grid", Items = { "1", "2", "3", "4" }, Columns = 2 })
	end)

	Safe(Choosing, "Chips", function()
		Choosing:Chips({ Label = "Chips", Items = { "fast", "quiet", "loud", "heavy" }, Default = { "quiet" } })
	end)

	Safe(Choosing, "List", function()
		Choosing:List({ Label = "List", Items = { "eu-west", "us-east", "ap-south" }, Default = "eu-west", Height = 84 })
	end)

	----------------------------------------------------------------------
	-- Pickers
	----------------------------------------------------------------------

	local Pickers = Tabs:Page("Pickers")

	local When = Pickers:Section("When", "Dates and times")

	Safe(When, "Date", function()
		When:Date({ Label = "Date", Default = os.time() })
	end)

	Safe(When, "DateRange", function()
		When:DateRange({ Label = "Date range", From = os.time() })
	end)

	Safe(When, "Time", function()
		When:Time({ Label = "Time", Default = 9 * 60 + 30, Step = 15 })
	end)

	Safe(When, "Time 12h", function()
		When:Time({ Label = "Time, twelve hour", Default = 13 * 60 + 45, Hours = 12 })
	end)

	Safe(When, "Calendar", function()
		When:Calendar({ Label = "Calendar" })
	end)

	local Colours = Pickers:Section("Colour", "Four ways to choose one")

	Safe(Colours, "ColorPicker", function()
		Colours:ColorPicker({ Label = "Picker", Default = Color3.fromRGB(255, 72, 72) })
	end)

	Safe(Colours, "Color", function()
		Colours:Color({ Label = "Channels", Default = Color3.fromRGB(96, 156, 255) })
	end)

	Safe(Colours, "Swatches", function()
		Colours:Swatches({
			Label = "Swatches",
			Items = {
				Color3.fromRGB(255, 72, 72),
				Color3.fromRGB(255, 176, 46),
				Color3.fromRGB(96, 210, 128),
				Color3.fromRGB(96, 156, 255),
				Color3.fromRGB(255, 255, 255),
			},
		})
	end)

	Safe(Colours, "Gradient", function()
		Colours:Gradient({
			Label = "Gradient",
			From = Color3.fromRGB(20, 30, 60),
			To = Color3.fromRGB(255, 150, 90),
		})
	end)

	local Themes = Pickers:Section("Themes", "Repaints what is already on screen")

	local Names = {}

	for Name in Kuik.Themes do
		table.insert(Names, Name)
	end

	table.sort(Names)

	Safe(Themes, "Theme", function()
		Themes:Dropdown({
			Label = "Theme",
			Items = Names,
			Default = Kuik.GetTheme(),
			Width = 130,
			Callback = function(Name)
				Kuik.SetTheme(Name)
			end,
		})
	end)

	Safe(Themes, "Radius", function()
		Themes:Slider({
			Label = "Corner radius",
			Description = "Applies to whatever is built next",
			Min = 0,
			Max = 16,
			Step = 1,
			Default = Kuik.Metrics.RowRadius,
			Callback = function(Value)
				Kuik.Metrics.RowRadius = Value
				Kuik.Metrics.CardRadius = Value
				Kuik.Metrics.PillRadius = Value * 60
			end,
		})
	end)

	----------------------------------------------------------------------
	-- Readouts
	----------------------------------------------------------------------

	local Data = Tabs:Page("Data")

	local Single = Data:Section("Single values", "One number, several ways")

	Safe(Single, "Status", function()
		Single:Status({ Label = "Status", Value = "22ms" })
	end)

	Safe(Single, "Badge", function()
		Single:Badge({ Label = "Badge", Text = "beta", Color = Theme.Warn })
	end)

	Safe(Single, "Progress", function()
		Single:Progress({ Label = "Progress", Default = 0.62 })
	end)

	Safe(Single, "AsciiBar", function()
		Single:AsciiBar({ Label = "Ascii bar", Default = 0.4 })
	end)

	Safe(Single, "Meter", function()
		Single:Meter({ Label = "Meter", Default = 78, Warn = 0.6, Danger = 0.85 })
	end)

	Safe(Single, "Ring", function()
		Single:Ring({ Label = "Ring", Default = 0.45 })
	end)

	Safe(Single, "Spinner", function()
		Single:Spinner({ Label = "Spinner", Description = "Still working" })
	end)

	Safe(Single, "Stat", function()
		Single:Stat({
			NumberSize = 20,
			Items = {
				{ Label = "kills", Value = 14 },
				{ Label = "deaths", Value = 3, Color = Theme.Danger },
				{ Label = "assists", Value = 7 },
			},
		})
	end)

	local Series = Data:Section("Series", "Numbers over time")

	Safe(Series, "Sparkline", function()
		Series:Sparkline({ Label = "Sparkline", Values = { 1, 5, 2, 8, 3, 6, 4 } })
	end)

	Safe(Series, "Graph", function()
		Series:Graph({ Label = "Graph", Values = { 1, 4, 2, 7, 3, 8, 5, 9 }, Grid = 3 })
	end)

	Safe(Series, "Bars", function()
		Series:Bars({ Label = "Bars", Values = { 3, 7, 2, 9, 4, 6 } })
	end)

	Safe(Series, "Waveform", function()
		Series:Waveform({
			Label = "Waveform",
			Values = { 0.2, 0.9, 0.4, 1, 0.3, 0.7, 0.5, 0.85, 0.25, 0.6 },
		})
	end)

	Safe(Series, "VU", function()
		Series:VU({ Label = "VU meter" }):Set({ 0.78, 0.52 })
	end)

	Safe(Series, "Scatter", function()
		Series:Scatter({
			Label       = "Scatter",
			Description = "Two numbers against each other",
			Points      = {
				{ 1, 2 }, { 2, 3 }, { 3, 3 }, { 4, 5 },
				{ 5, 4 }, { 6, 7 }, { 7, 6 }, { 8, 9 },
			},
		})
	end)

	Safe(Series, "Donut", function()
		Series:Donut({
			Label = "Where it went",
			Items = {
				{ Label = "rent", Value = 60, Color = Theme.Accent },
				{ Label = "food", Value = 30, Color = Theme.Good },
				{ Label = "the rest", Value = 10, Color = Theme.Warn },
			},
		})
	end)

	local Sets = Data:Section("Sets", "More than one thing at a time")

	Safe(Sets, "Table", function()
		Sets:Table({
			Label = "Table",
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
	end)

	Safe(Sets, "Compare", function()
		Sets:Compare({
			Label = "Compare",
			Items = { "Free", "Pro" },
			Best = 2,
			Rows = {
				{ "Seats", 1, 10 },
				{ "Support", false, true },
				{ "History", "7 days", "forever" },
			},
		})
	end)

	Safe(Sets, "Tree", function()
		Sets:Tree({
			Label = "Tree",
			Nodes = {
				{
					Label = "Primary",
					Open = true,
					Children = { { Label = "Silenced rifle" }, { Label = "Marksman" } },
				},
				{ Label = "Secondary", Children = { { Label = "Sidearm" } } },
			},
		})
	end)

	Safe(Sets, "Timeline", function()
		Sets:Timeline({
			Label = "Timeline",
			Items = {
				{ Label = "Match started", Time = "0:00" },
				{ Label = "First blood", Text = "kr3ative", Time = "0:42", Color = Theme.Good },
				{ Label = "Objective taken", Time = "3:15" },
			},
		})
	end)

	Safe(Sets, "Kanban", function()
		Sets:Kanban({
			Label = "Kanban",
			Height = 170,
			Columns = {
				{ Label = "Todo", Cards = { "Scout the roof", { Label = "Buy a key", Text = "from the fixer" } } },
				{ Label = "Doing", Cards = { "Tail the courier" } },
				{ Label = "Done", Cards = { "Change clothes" } },
			},
		})
	end)

	Safe(Sets, "Heatmap", function()
		Sets:Heatmap({
			Label = "Heatmap",
			Values = { { 1, 3, 5, 2 }, { 4, 8, 6, 1 }, { 2, 5, 9, 3 } },
		})
	end)

	Safe(Sets, "Treemap", function()
		Sets:Treemap({
			Label = "Treemap",
			Items = {
				{ Label = "Gear", Value = 40 },
				{ Label = "Bribes", Value = 25 },
				{ Label = "Rent", Value = 20 },
				{ Label = "Other", Value = 15 },
			},
		})
	end)

	Safe(Sets, "Pagination", function()
		Sets:Pagination({ Label = "Pagination", Pages = 6 })
	end)

	Safe(Sets, "LoadMore", function()
		Sets:LoadMore({
			Label = "Load more",
			Callback = function()
				task.wait(0.6)
				return false
			end,
		})
	end)

	----------------------------------------------------------------------
	-- Content
	----------------------------------------------------------------------

	local Content = Tabs:Page("Content")

	local Type = Content:Section("Type", "Copy")

	Safe(Type, "Header", function()
		Type:Header({ Label = "Header", Description = "A heading and a rule" })
	end)

	Safe(Type, "Paragraph", function()
		Type:Paragraph({ Text = "Body copy. Rules and type, almost no fill, square by default." })
	end)

	Safe(Type, "Quote", function()
		Type:Quote({ Text = "Two rules, no panel.", Author = "the brief" })
	end)

	Safe(Type, "Code", function()
		Type:Code({
			Label = "Code",
			Text = 'local Window = Kuik.Window({ Title = "Settings" })\nWindow:Toggle({ Label = "Enabled" })',
		})
	end)

	Safe(Type, "Motd", function()
		Type:Motd({ Label = "MOTD", Text = "Server restarts in ten minutes. Bank your money." })
	end)

	Safe(Type, "Marquee", function()
		Type:Marquee({ Text = "a ticker that scrolls sideways forever and ever and ever" })
	end)

	Safe(Type, "Kbd", function()
		Type:Kbd({ Label = "Sprint", Keys = { "Shift", "W" } })
	end)

	local Notices = Content:Section("Notices", "Four weights of the same idea")

	for _, Kind in { "Accent", "Solid", "Outline", "Subtle" } do
		Safe(Notices, "Alert " .. Kind, function()
			Notices:Alert({
				Label = Kind,
				Text = "An alert in the " .. string.lower(Kind) .. " variant.",
				Variant = Kind,
				Color = Theme.Info,
			})
		end)
	end

	Safe(Notices, "Callout", function()
		Notices:Callout({ Label = "A callout is an alert with no title.", Color = Theme.Warn })
	end)

	local Actions = Content:Section("Actions", "Six variants and three rules")

	for _, Variant in { "Pill", "Solid", "Outline", "Ghost", "Text", "Rule" } do
		Safe(Actions, "Button " .. Variant, function()
			Actions:Button({
				Label = Variant,
				Action = "Run",
				Variant = Variant,
				Callback = function()
					Kuik.Toast(Variant .. " pressed", { Duration = 1.2 })
				end,
			})
		end)
	end

	Safe(Actions, "SplitButton", function()
		Actions:SplitButton({
			Label = "Split button",
			Action = "Deploy",
			Items = { { Label = "Dry run" }, { Separator = true }, { Label = "Rollback", Color = Theme.Danger } },
			Callback = function()
				Kuik.Toast("deployed", { Duration = 1.2 })
			end,
			Chose = function(Item)
				Kuik.Toast(Item.Label, { Duration = 1.2 })
			end,
		})
	end)

	Safe(Actions, "Toolbar", function()
		Actions:Toolbar({
			Items = { { Label = "Copy" }, { Label = "Paste" }, { Label = "Reset", Color = Theme.Danger } },
			Callback = function(Item)
				Kuik.Toast(Item.Label, { Duration = 1 })
			end,
		})
	end)

	Safe(Actions, "Rule button", function()
		Actions:Rule({
			Action = "A full width rule button",
			Callback = function()
				Kuik.Toast("committed", { Duration = 1.2 })
			end,
		})
	end)

	Safe(Actions, "Clickable divider", function()
		Actions:Divider({
			Label = "or start over",
			Callback = function()
				Kuik.Toast("started over", { Duration = 1.2 })
			end,
		})
	end)

	local Nesting = Content:Section("Nesting", "Containers inside containers")

	Safe(Nesting, "Breadcrumb", function()
		Nesting:Breadcrumb({ Path = { "Home", "Settings", "Audio" } })
	end)

	Safe(Nesting, "Steps", function()
		Nesting:Steps({ Label = "Steps", Items = { "Account", "Controls", "Done" }, Default = 2 })
	end)

	Safe(Nesting, "Group", function()
		local Bin = Nesting:Group({ Label = "Group", Variant = "Outline" })
		Bin:Toggle({ Label = "Inside a group" })
		Bin:Slider({ Label = "Also inside", Max = 10, Default = 4 })
	end)

	Safe(Nesting, "Columns", function()
		local Split = Nesting:Columns({ Count = 2 })
		Split:Column(1):Toggle({ Label = "Left" })
		Split:Column(2):Toggle({ Label = "Right" })
	end)

	Safe(Nesting, "Accordion", function()
		local Fold = Nesting:Accordion({ Label = "Accordion", Description = "Everything fits inside" })
		Fold:Toggle({ Label = "Nested toggle" })
		Fold:Slider({ Label = "Nested slider", Max = 100, Default = 30 })
		Fold:Alert({ Label = "Nested alert", Text = "Containers all the way down." })
	end)

	Safe(Nesting, "Well", function()
		local Bowl = Nesting:Well({ Height = 70 })
		Bowl:Paragraph({ Text = "A well is the plainest container there is." })
	end)

	Safe(Nesting, "Split", function()
		local Pane = Nesting:Split({ Height = 100, At = 0.4 })
		Pane:Left():Paragraph({ Text = "Drag the rule between these." })
		Pane:Right():Toggle({ Label = "Right pane" })
	end)

	Safe(Nesting, "Skeleton", function()
		Nesting:Skeleton({ Lines = 3 })
	end)

	----------------------------------------------------------------------
	-- Media
	----------------------------------------------------------------------

	local Media = Tabs:Page("Media")

	local Plates = Media:Section("Embeds", "Every embed decides its own plate")

	Safe(Plates, "Image", function()
		Plates:Image({ Label = "With a plate", Image = PICTURE, Height = 110 })
	end)

	Safe(Plates, "Image bare", function()
		Plates:Image({ Label = "No plate", Description = "Background = false", Image = PICTURE, Background = false, Height = 110 })
	end)

	Safe(Plates, "Image tinted", function()
		Plates:Image({
			Label = "A plate of your own",
			Image = PICTURE,
			Background = Color3.fromRGB(40, 20, 60),
			BackgroundTransparency = 0.2,
			Height = 110,
		})
	end)

	Safe(Plates, "Icon", function()
		Plates:Icon({ Label = "Icon", Image = PICTURE })
	end)

	Safe(Plates, "Avatar", function()
		Plates:Avatar({
			Label = LocalPlayer and LocalPlayer.DisplayName or "player",
			Description = "an avatar row",
			UserId = LocalPlayer and LocalPlayer.UserId or 1,
		})
	end)

	Safe(Plates, "Gallery", function()
		Plates:Gallery({
			Label = "Gallery",
			Height = 90,
			Width = 130,
			Items = {
				{ Image = PICTURE, Label = "one" },
				{ Image = PICTURE, Label = "two" },
				{ Image = PICTURE, Label = "three" },
			},
		})
	end)

	Safe(Plates, "Carousel", function()
		Plates:Carousel({
			Label = "Carousel",
			Height = 110,
			Items = {
				{ Image = PICTURE, Label = "first" },
				{ Image = PICTURE, Label = "second" },
				{ Image = PICTURE, Label = "third" },
			},
		})
	end)

	Safe(Plates, "Carousel deck", function()
		Plates:Carousel({
			Label       = "Carousel, deck",
			Description = "The ones either side show behind the one in focus",
			Variant     = "Deck",
			Height      = 130,
			Tilt        = 2,
			Items = {
				{ Image = PICTURE, Label = "first" },
				{ Image = PICTURE, Label = "second" },
				{ Image = PICTURE, Label = "third" },
				{ Image = PICTURE, Label = "fourth" },
			},
		})
	end)

	Safe(Plates, "Zoom", function()
		Plates:Zoom({
			Label       = "Zoom",
			Description = "Hover for the loupe, wheel to change it",
			Image       = PICTURE,
			Height      = 130,
			Crosshair   = true,
		})
	end)

	Safe(Plates, "Zoom pan", function()
		Plates:Zoom({
			Label       = "Zoom, panned",
			Description = "Drag to move, wheel to scale about the pointer",
			Image       = PICTURE,
			Height      = 130,
			Mode        = "Pan",
			Factor      = 1,
		})
	end)

	local Playing = Media:Section("Transport", "Sound, video and 3D")

	Safe(Playing, "Scrubber", function()
		Playing:Scrubber({ Label = "Scrubber", Length = 180, Default = 42 }):SetBuffered(0.7)
	end)

	Safe(Playing, "Volume", function()
		Playing:Volume({ Label = "Volume", Default = 0.7 })
	end)

	Safe(Playing, "Audio", function()
		Playing:Audio({ Label = "Audio", Sound = "rbxassetid://9046863579" })
	end)

	Safe(Playing, "Viewport", function()
		Playing:Viewport({ Label = "Viewport", Description = "Drag to turn", Spin = true, Height = 150 })
	end)

	----------------------------------------------------------------------
	-- Overlays
	----------------------------------------------------------------------

	local Overlays = Tabs:Page("Overlays")

	local Held = {}

	local Modals = Overlays:Section("Modals", "Things that draw over everything")

	Safe(Modals, "Prompt", function()
		Modals:Button({
			Label = "Prompt",
			Description = "Nothing behind it is reachable",
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
	end)

	Safe(Modals, "Menu", function()
		local Menu = Kuik.Menu({
			Items = {
				{ Label = "Inspect", Shortcut = "I" },
				{ Label = "Duplicate", Shortcut = "D" },
				{ Separator = true },
				{ Label = "Delete", Color = Theme.Danger },
			},
			Callback = function(Item)
				Kuik.Toast(Item.Label, { Duration = 1 })
			end,
		})

		Held.Menu = Menu

		Modals:Button({
			Label = "Context menu",
			Action = "Show",
			Callback = function()
				Menu:ShowAtMouse()
			end,
		})
	end)

	Safe(Modals, "Menu in the house style", function()
		local Rails = Kuik.Menu({
			Items = { "Copy", "Paste", { Separator = true }, "Delete" },
			Variant = "Rules",
		})

		Held.Rails = Rails

		Modals:Button({
			Label       = "Rules menu",
			Description = "The same menu with two hairlines instead of a plate",
			Action      = "Show",
			Callback    = function()
				Rails:ShowAtMouse()
			end,
		})
	end)

	Safe(Modals, "Popover", function()
		local Popover = Kuik.Popover({ Width = 220 })

		Popover:Paragraph({ Text = "A popover flips above its anchor when there is no room below." })
		Popover:Toggle({ Label = "It is a container" })

		Held.Popover = Popover

		local Row = Modals:Button({
			Label = "Popover",
			Action = "Open",
			Callback = function()
				Popover:Show(Held.PopoverAnchor)
			end,
		})

		Held.PopoverAnchor = Row.Frame
	end)

	Safe(Modals, "Sheet", function()
		local Sheet = Kuik.Sheet({ Height = 220 })

		Sheet:Header({ Label = "Bottom sheet", Description = "Rises from the bottom edge" })
		Sheet:Slider({ Label = "A slider in a sheet", Max = 100, Default = 40 })
		Sheet:Rule({ Action = "Close", Callback = function() Sheet:Close() end })

		Held.Sheet = Sheet

		Modals:Button({
			Label = "Bottom sheet",
			Action = "Open",
			Callback = function()
				Sheet:Show()
			end,
		})
	end)

	Safe(Modals, "Drawer", function()
		local Drawer = Kuik.Drawer({ Width = 240, Side = "Left" })

		Drawer:Header({ Label = "Drawer", Description = "Slides in from the edge" })
		Drawer:List({ Label = "Navigation", Items = { "Home", "Contracts", "Store", "Settings" }, Height = 110 })
		Drawer:Rule({ Action = "Close", Callback = function() Drawer:Close() end })

		Held.Drawer = Drawer

		Modals:Button({
			Label = "Navigation drawer",
			Action = "Open",
			Callback = function()
				Drawer:Flip()
			end,
		})
	end)

	Safe(Modals, "Coach", function()
		Modals:Button({
			Label = "Guided tour",
			Description = "Rings each thing in turn",
			Action = "Start",
			Callback = function()
				Kuik.Coach({
					Steps = {
						{ Label = "The tabs", Text = "Every page of this window hangs off here.", Target = Tabs.Frame },
						{ Label = "This window", Text = "A window can be dragged, docked, resized and themed.", Target = Window.Root },
						{ Label = "That is it", Text = "Everything else is in the pages." },
					},
				}):Start()
			end,
		})
	end)

	--- The white layer, given its own section because it is the one thing in the
	--- library you cannot judge from a screenshot.
	local White = Overlays:Section("The white layer",
		"A white shape stands in for something, then hands over to it")

	Safe(White, "Plate", function()
		local Button = nil

		Button = White:Button({
			Label       = "Plate reveal",
			Description = "A window that arrives as a white plate",
			Action      = "Open",
			Callback    = function()
				if Held.Plated then
					Held.Plated:Destroy()
				end

				Held.Plated = Kuik.Window({
					Title    = "Revealed",
					Subtitle = "arrived as a plate",
					Variant  = "Card",
					Width    = 320,
					Height   = 240,
					Reveal   = { From = Button and Button.Frame },
					Open     = true,
				})

				Held.Plated:Paragraph({
					Text = "The plate grows wide, opens down, and burns off while "
						.. "this resolves underneath it.",
				})

				Held.Plated:Rule({
					Action   = "Close",
					Callback = function()
						Held.Plated:Destroy(true)
						Held.Plated = nil
					end,
				})
			end,
		})
	end)

	Safe(White, "Row plate", function()
		White:Button({
			Label       = "Row reveal",
			Description = "One control arriving as a plate",
			Action      = "Add",
			Callback    = function()
				White:Toggle({
					Label       = "Arrived",
					Description = "built with Reveal = true",
					Reveal      = true,
					Default     = true,
				})
			end,
		})
	end)

	Safe(White, "Wipe", function()
		White:Button({
			Label       = "Wipe",
			Description = "A white bar sweeps across and leaves the text behind",
			Action      = "Run",
			Callback    = function()
				if Held.Wiped then
					Held.Wiped:Destroy()
				end

				Held.Wiped = White:Paragraph({
					Text = "Uncovered by a bar travelling across it, rather than "
						.. "faded up in place.",
				})

				task.defer(function()
					Kuik.Wipe(Held.Wiped.Frame)
				end)
			end,
		})
	end)

	Safe(White, "Trail", function()
		White:Toggle({
			Label       = "Afterimage",
			Description = "A white ghost that trails a moving panel",
			Callback    = function(On)
				if Held.Trailed then
					Held.Trailed:Destroy()
					Held.Trailed = nil
				end

				if not On then
					return
				end

				--- A Panel has no chrome and no padding of its own, so it needs
				--- both if anything is going to be put inside it.
				local Panel = Kuik.Panel({
					Position      = UDim2.new(0, 40, 0.5, 0),
					Anchor        = Vector2.new(0, 0.5),
					Width         = 190,
					Height        = 78,
					Variant       = "Card",
					PaddingTop    = 12,
					PaddingBottom = 12,
					Open          = true,
				})

				Panel:Header({ Label = "Watch me", Description = "and the smear behind" })

				local Ghost = Kuik.Follow(Panel.Root, { Span = 120, Reach = 0.4 })

				--- Sent back and forth so the smear is actually visible.
				task.spawn(function()
					local At = 0

					while Panel:IsAlive() do
						At = 1 - At
						Panel:SetPosition(UDim2.new(At, 0, 0.5, 0), "layout")
						task.wait(1.4)
					end
				end)

				Held.Trailed = {
					Destroy = function()
						Ghost:Destroy()
						Panel:Destroy(true)
					end,
				}
			end,
		})
	end)

	Safe(White, "Flash", function()
		White:Button({
			Label       = "Flash",
			Description = "Full white, held, then decays — a cut you can hide behind",
			Action      = "Flash",
			Callback    = function()
				Kuik.Flash({ Peak = 0.92, Hold = 0.17 })
			end,
		})
	end)

	local Windows = Overlays:Section("Windows", "A window is a rectangle you put things in")

	Safe(Windows, "Child", function()
		local Child = Window:Child({ Title = "Child", Subtitle = "parked beside its parent", Width = 260 })

		Child:Paragraph({ Text = "A sub window belongs to the one that made it." })
		Child:Rule({ Action = "Close", Callback = function() Child:Close() end })

		Held.Child = Child

		Windows:Button({
			Label = "Sub window",
			Action = "Open",
			Callback = function()
				Child:SetOpen(not Child:IsOpen())
			end,
		})
	end)

	Safe(Windows, "Panel", function()
		Windows:Toggle({
			Label = "Loose panel",
			Description = "No chrome, draggable, resizable",
			Callback = function(On)
				if Held.Panel then
					Held.Panel:Destroy()
					Held.Panel = nil
				end

				if not On then
					return
				end

				local Panel = Kuik.Panel({
					Dock = "TopLeft",
					Position = UDim2.new(0, 24, 0, 24),
					Width = 250,
					Height = 130,
					Draggable = true,
					Resizable = true,
					Variant = "Card",
				})

				Panel:Header({ Label = "Loose panel", Description = "Drag me" })
				Panel:Progress({ Label = "Stamina", Default = 0.6 })

				Held.Panel = Panel
			end,
		})
	end)

	Safe(Windows, "Chrome", function()
		Windows:Toggle({
			Label = "Desktop chrome",
			Description = "Title bar, window controls, status bar",
			Callback = function(On)
				if Held.Chrome then
					Held.Chrome:Destroy()
					Held.Chrome = nil
				end

				if not On then
					return
				end

				local Chrome = Kuik.Window({
					Title = "Desktop",
					TitleBar = true,
					StatusBar = "ready",
					Variant = "Card",
					Width = 320,
					Height = 220,
					Dock = "TopRight",
					--- Kuik.Safe puts an offset in the visible screen's terms
					--- rather than the layer's, which starts above it. Without
					--- it "24 from the top" is 34 pixels off the top edge, and
					--- the title bar is the part that goes missing.
					Position = UDim2.new(1, -24, 0, Kuik.Safe(0) + 24),
					Blur = 0,
					Wash = 1,
					Backdrop = false,
					Draggable = true,
					Resizable = true,
					Open = true,
				})

				Chrome:Paragraph({ Text = "Minimise, maximise and close are in the bar." })
				Chrome:Toggle({ Label = "A setting" })

				Held.Chrome = Chrome
			end,
		})
	end)

	Safe(Windows, "Deck", function()
		Windows:Button({
			Label = "Card deck",
			Description = "A horizontal carousel of windows",
			Action = "Open",
			Callback = function()
				if Held.Deck then
					Held.Deck:Destroy()
					Held.Deck = nil
					return
				end

				local Deck = Kuik.Cards({ Gap = 90 })

				for Index = 1, 4 do
					local Card = Kuik.Window({
						Title = "Card " .. Index,
						Width = 300,
						Height = 320,
						Blur = 0,
						Wash = 0.5,
					})

					Card:Paragraph({ Text = "Left and right, or Q and E, move the deck." })
					Card:Slider({ Label = "A slider", Max = 100, Default = Index * 20 })

					Card:Rule({
						Action = "Close the deck",
						Callback = function()
							Deck:Destroy()
							Held.Deck = nil
						end,
					})

					Deck:Add(Card)
				end

				Held.Deck = Deck
			end,
		})
	end)

	----------------------------------------------------------------------
	-- HUD
	----------------------------------------------------------------------

	--------------------------------------------------------------------------
	-- Play
	--------------------------------------------------------------------------

	local Play = Tabs:Page("Play")

	local Round = Play:Section("A round of something",
		"The controls a game wants and an application does not")

	Safe(Round, "Leaderboard", function()
		Round:Leaderboard({
			Label       = "Leaderboard",
			Description = "Your own row is pinned, however far down you are",
			Me          = LocalPlayer and LocalPlayer.DisplayName or "you",
			Height      = 150,
			Entries     = {
				{ Name = "0x428a2f", Value = 4820 },
				{ Name = "kryptra", Value = 3110 },
				{ Name = "morbussi", Value = 2740 },
				{ Name = LocalPlayer and LocalPlayer.DisplayName or "you", Value = 1290,
					UserId = LocalPlayer and LocalPlayer.UserId or nil },
				{ Name = "whew123p", Value = 640 },
			},
		})
	end)

	Safe(Round, "Versus", function()
		local Match = Round:Versus({
			Label      = "Possession",
			LeftLabel  = "HOME",
			RightLabel = "AWAY",
			Left       = 62,
			Right      = 38,
		})

		Held.Match = {
			Destroy = function() end,
		}

		Round:Button({
			Label       = "Score",
			Description = "One bar shared by two sides",
			Action      = "Away",
			Callback    = function()
				Match:Add(0, 12)
			end,
		})
	end)

	Safe(Round, "Wallet", function()
		local Purse = Round:Wallet({
			Label       = "Kions",
			Description = "Rolls to its new value, and says what changed",
			Default     = 5250,
			Unit        = "kions",
		})

		Round:Button({
			Label    = "Earn",
			Action   = "+1,750",
			Callback = function()
				Purse:Add(1750)
			end,
		})
	end)

	local Carrying = Play:Section("Carrying", "What you have and what you pick")

	Safe(Carrying, "Slots", function()
		Carrying:Slots({
			Label       = "Bag",
			Description = "Empty cells are drawn, because nine spaces means something",
			Count       = 12,
			Across      = 6,
			Items       = {
				{ Label = "Medkit", Count = 3, Color = Theme.Good },
				{ Label = "Ammo", Count = 120 },
				nil,
				{ Label = "Keycard", Color = Theme.Warn },
			},
		})
	end)

	Safe(Carrying, "Radial", function()
		Carrying:Radial({
			Label = "Emote",
			Items = {
				{ Label = "wave" }, { Label = "point" }, { Label = "sit" },
				{ Label = "dance" }, { Label = "salute" }, { Label = "shrug" },
			},
		})
	end)

	local Lists = Play:Section("Lists", "The general ones that came with them")

	Safe(Lists, "Sortable", function()
		Lists:Sortable({
			Label       = "Loadout",
			Description = "Drag a row to reorder it",
			Items       = { "Primary", "Secondary", "Melee", "Utility" },
		})
	end)

	Safe(Lists, "Confirm", function()
		Lists:Confirm({
			Label       = "Delete save",
			Description = "Two presses, and it disarms if you walk away",
			Action      = "Delete",
			Callback    = function()
				Kuik.Toast("deleted", { Duration = 1.2 })
			end,
		})
	end)

	Safe(Lists, "Empty", function()
		Lists:Empty({
			Text   = "No rounds played yet",
			Detail = "Your last twenty will show up here",
			Action = "Find a game",
		})
	end)

	local Hud = Tabs:Page("HUD")

	local Screen = Hud:Section("On the screen", "None of these live in a window")

	local Pieces = {}

	local function Toggleable(Name, Description, Make)
		Screen:Toggle({
			Label = Name,
			Description = Description,
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

	Toggleable("Watermark", "A monospaced strip along the bottom", function()
		local Mark = Kuik.Watermark({ Tag = { Text = "KUIK" } })
		Mark:Set({ Kuik.Version.Version, LocalPlayer and LocalPlayer.DisplayName or "player" })
		return Mark
	end)

	Toggleable("Crosshair", "Four ticks that spread", function()
		return Kuik.Crosshair({ Dot = true })
	end)

	Toggleable("Viewfinder", "Corner brackets and a tally", function()
		local Finder = Kuik.Viewfinder()
		Finder:SetRecording(true)
		return Finder
	end)

	Toggleable("Health bar", "A meter that drains", function()
		local Bar = Kuik.Bar({ Label = "HEALTH", Max = 100, Default = 100, Warn = 0.5, Danger = 0.25, Width = 240 })

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

	Toggleable("Ammo", "A weapon and a count", function()
		return Kuik.Ammo({ Weapon = "SILENCED", Magazine = 7, Reserve = 21, Capacity = 7 })
	end)

	Toggleable("Objective", "A labelled block with progress", function()
		return Kuik.Objective({ Label = "OBJECTIVE", Text = "Reach the roof", Progress = 0.35 })
	end)

	Toggleable("Hints", "The key rail", function()
		local Hints = Kuik.Hints()
		Hints:Add("E", "interact")
		Hints:Add("Q", "lean left")
		Hints:Add("R", "reload")
		return Hints
	end)

	Toggleable("Compass", "A heading strip", function()
		return Kuik.Compass()
	end)

	Toggleable("Vignette", "Darkened edges", function()
		return Kuik.Vignette({ Strength = 0.4 })
	end)

	Safe(Screen, "Arrival", function()
		Screen:Button({
			Label       = "Arrival screen",
			Description = "The loading screen, and the bar that uncovers it",
			Action      = "Show",
			Callback    = function()
				local Arrival = Kuik.Arrival({
					Title    = 'You\'re arriving at "West Haven Offices"',
					Subtitle = "Placing you in the level",
					Status   = "Loaded West Haven Offices",
					Footer   = {
						"Everything on this screen was measured off a recording.",
						"Press nothing; it leaves on its own.",
					},
				})

				task.spawn(function()
					for Step = 1, 10 do
						task.wait(0.18)
						Arrival:SetProgress(Step / 10)
					end

					Arrival:SetStatus("Placing you")
					task.wait(0.5)
					Arrival:Done()
				end)
			end,
		})
	end)

	Toggleable("Feed", "Centred notices, newest at the bottom", function()
		local Feed = Kuik.Feed()

		task.spawn(function()
			local Lines = {
				{ "Killed ArmIles_AndHeadless and 13 more" },
				{ "You've earned: 7,000 Kions" },
				{ "After Tax: 5,250 Kions", Theme.Good },
			}

			local At = 0

			while Feed.Frame.Parent do
				At = At % #Lines + 1
				Feed:Push(Lines[At][1], { Color = Lines[At][2] })
				task.wait(1.6)
			end
		end)

		return Feed
	end)

	Toggleable("Killfeed", "Lines that fade themselves", function()
		local Feed = Kuik.Killfeed()

		task.spawn(function()
			while Feed.Frame.Parent do
				Feed:Push(LocalPlayer and LocalPlayer.DisplayName or "you", "eliminated", "a guard")
				task.wait(3)
			end
		end)

		return Feed
	end)

	Toggleable("Console", "Levelled output", function()
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

	Toggleable("Log", "Bulleted lines, bottom left", function()
		local Log = Kuik.Log()

		task.spawn(function()
			while Log.Frame.Parent do
				Log:Push("something happened")
				task.wait(2)
			end
		end)

		return Log
	end)

	Toggleable("Timer", "A dial and a clock", function()
		return Kuik.Timer({ Seconds = 120 })
	end)

	Toggleable("Action button", "A floating action button", function()
		return Kuik.Fab({
			Label = "new contract",
			Callback = function()
				Kuik.Toast("pressed", { Duration = 1 })
			end,
		})
	end)

	local Messages = Hud:Section("Messages", "Transient")

	Safe(Messages, "Toast", function()
		Messages:Button({
			Label = "Toast",
			Action = "Show",
			Callback = function()
				Kuik.Toast("a toast between two rules", { Duration = 2 })
			end,
		})
	end)

	Safe(Messages, "Notify", function()
		Messages:Button({
			Label = "Notify",
			Action = "Show",
			Callback = function()
				Kuik.Notify({ Title = "Saved", Text = "Everything is up to date." })
			end,
		})
	end)

	----------------------------------------------------------------------

	Tabs:Select("Input")

	--- Anything that failed is listed once, at the top, so a broken build is
	--- obvious without scrolling.
	if #Broken > 0 then
		Window:SetTitle(Options.Title or "Kuik",
			string.format("%d control(s) failed: %s", #Broken, table.concat(Broken, ", ")))
	end

	Window.Broken = Broken
	Window.Held = Held

	--- Everything the showcase parked outside the window goes with it.
	Window:OnDestroy(function()
		for _, Piece in Pieces do
			Piece:Destroy()
		end

		for _, Piece in Held do
			if type(Piece) == "table" and Piece.Destroy then
				Piece:Destroy()
			end
		end
	end)

	return Window
end
