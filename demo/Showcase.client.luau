--!nonstrict
--[[
	Kuik showcase — every option, method and handle in the library, wired to
	something you can see or press.

	StarterPlayer > StarterPlayerScripts, as a LocalScript, with the Kuik
	module in ReplicatedStorage. Opens on join; TAB toggles.

	Tabs:
	  Controls  every control type, and every option each one takes
	  Rows      row-level layout: descriptions, flat rows, gaps, ordering
	  Values    :Get / :Set / silent :Set / :Destroy on live handles
	  HUD       the six HUD components, fired by hand
	  Window    open/close, parallax, tab selection, backdrop
	  Theme     live theme and metric edits, then rebuild
	  About     version, exports, and the raw New/Tween escape hatches
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")

local Kuik = require(ReplicatedStorage:WaitForChild("Kuik"))

local LocalPlayer = Players.LocalPlayer

--- Snapshot of the shipped durations, so the motion-scale slider on the Theme
--- tab can multiply from a fixed base rather than compounding.
local BaseMotion = {}

for Name, Spec in Kuik.Theme.Motion do
	BaseMotion[Name] = Spec.Duration
end


--============================================================================
-- State
--============================================================================

local State = {
	--- Controls tab
	Enabled        = true,
	Volume         = 72,
	Mix            = 0.35,
	Sensitivity    = 1.4,
	Amount         = 5,
	Quality        = "High",
	Bind           = Enum.KeyCode.Tab,
	DisplayName    = LocalPlayer.DisplayName,

	--- Window tab
	Parallax       = 6,
	ParallaxOn     = true,
	Blur           = 22,

	--- The scrim darkens rather than lightens. Over a bright scene a light
	--- wash erases white rules and white type — which is exactly what
	--- happened over a blue sky the first time this ran.
	Wash           = 0.5,

	--- Theme tab
	FontChoice     = "Montserrat",
	RuleAlpha      = 0.45,
	RowAlpha       = 0.94,
	MotionSpeed    = 1,
	WindowWidth    = 460,
}


--============================================================================
-- HUD — built once, lives outside the window
--============================================================================

local Watermark = Kuik.Watermark({
	Side = "Left",
	Tag  = { Text = "SHOWCASE", Color = Kuik.Theme.Danger },
	Fields = {
		"KUIK_v" .. Kuik.Version.Version,
		string.format("QK-%s::%s", string.sub(tostring(os.time()), -8), LocalPlayer.Name),
		os.date("%B %d, %Y %I:%M %p"),
	},
})

local Hints = Kuik.Hints()
local HintBind = Hints:Add("TAB", "Toggle Showcase")
Hints:Add("SHIFT", "Sprint")
Hints:Add("1", "Equip Primary")

local Log = Kuik.Log({ Limit = 7 })
Log:Push("Welcome to the <b>Kuik</b> showcase.")
Log:Push('Your role is <font color="#5c9cff">CONSERVATOR</font>.')
Log:Push(string.format("Players online: %d/%d", #Players:GetPlayers(), Players.MaxPlayers))

local Console = Kuik.Console()
Console:Push("SUCCESS", string.format("quik %s loaded", Kuik.Version.Version))

--- Duration 0 means it persists until something destroys it.
local Banner = Kuik.Toast("Every control below is live. Nothing here is a mock.", { Duration = 0 })

--- Held so the HUD tab can add and remove them.
local ExtraHints = {}


--============================================================================
-- Window
--============================================================================

local Window
local Tabs
local Handles = {}

--- Rebuilt with the window, so the live loop re-reads them each tick.
local StatusPing
local StatusUptime

--- The card deck, built on demand from the Layers tab.
local Deck = nil
local DeckCards = {}

local function Build()
	Window = Kuik.Window({
		Title       = "Kuik",
		Subtitle    = "Every feature, on one screen",
		Key         = State.Bind,
		Open        = true,
		Width       = State.WindowWidth,
		Height      = 520,
		Blur        = State.Blur,
		Wash        = State.Wash,
		Parallax    = State.ParallaxOn and State.Parallax or 0,
		UnlockMouse = true,
	})

	local Categories = Window:Section("Categories", "Choose a category to configure.")

	Tabs = Categories:Tabs({
		Align    = "Left",
		Callback = function(Name)
			Console:Push("DEBUG", string.format("tab -> %s", Name))
		end,
	})

	local Controls = Tabs:Page("Controls")
	local Rows     = Tabs:Page("Rows")
	local Values   = Tabs:Page("Values")
	local Hud      = Tabs:Page("HUD")
	local WindowTab = Tabs:Page("Window")
	local Select    = Tabs:Page("Select")
	local Data      = Tabs:Page("Data")
	local Charts    = Tabs:Page("Charts")
	local Composite = Tabs:Page("Composite")
	local Pickers   = Tabs:Page("Pickers")
	local Media     = Tabs:Page("Media")
	local Layers    = Tabs:Page("Layers")
	local ThemeTab  = Tabs:Page("Theme")
	local About     = Tabs:Page("About")

	------------------------------------------------------------------
	-- Controls — one of everything
	------------------------------------------------------------------

	Handles.Toggle = Controls:Toggle({
		Label       = "Toggle",
		Description = "A boolean. The knob slides, the track dims when off.",
		Default     = State.Enabled,
		Callback    = function(Value)
			State.Enabled = Value
			Console:Push("INFO", "toggle = " .. tostring(Value))
		end,
	})

	Handles.Slider = Controls:Slider({
		Label       = "Slider — integer",
		Description = "Min 0, Max 100, Step 1. Drag the track.",
		Min = 0, Max = 100, Step = 1,
		Default     = State.Volume,
		Callback    = function(Value) State.Volume = Value end,
	})

	Handles.Fraction = Controls:Slider({
		Label       = "Slider — fractional",
		Description = "Step 0.05. The readout's precision follows the step.",
		Min = 0, Max = 1, Step = 0.05,
		Default     = State.Mix,
		Callback    = function(Value) State.Mix = Value end,
	})

	Handles.Formatted = Controls:Slider({
		Label       = "Slider — custom format",
		Description = "A Format function overrides the readout entirely.",
		Min = 0.1, Max = 5, Step = 0.1,
		Default     = State.Sensitivity,
		Format      = function(Value) return string.format("%.1fx", Value) end,
		Callback    = function(Value) State.Sensitivity = Value end,
	})

	Handles.Stepper = Controls:Stepper({
		Label       = "Stepper",
		Description = "Click the chip's left half to decrement, right half to increment.",
		Min = 0, Max = 20, Step = 1,
		Default     = State.Amount,
		Callback    = function(Value) State.Amount = Value end,
	})

	Handles.Dropdown = Controls:Dropdown({
		Label       = "Dropdown",
		Description = "Opens downward. Keep these high in a page — see Known limits.",
		Items       = { "Low", "Medium", "High", "Ultra" },
		Default     = State.Quality,
		Callback    = function(Value)
			State.Quality = Value
			Console:Push("INFO", "quality = " .. Value)
		end,
	})

	Handles.Keybind = Controls:Keybind({
		Label       = "Keybind",
		Description = "Click, then press a key. Escape cancels.",
		Default     = State.Bind,
		Callback    = function(Key)
			State.Bind = Key
			HintBind:Set(Key.Name, "Toggle Showcase")
			Console:Push("WARN", "rebind needs a window rebuild to take effect")
		end,
	})

	Handles.Input = Controls:Input({
		Label       = "Input",
		Description = "A text field with a placeholder.",
		Default     = State.DisplayName,
		Placeholder = "Display name",
		Callback    = function(Value, Enter)
			State.DisplayName = Value
			Console:Push("INFO", string.format("input = %q (enter=%s)", Value, tostring(Enter)))
		end,
	})

	Controls:Button({
		Label       = "Button",
		Description = "A white pill on the right. The label text is the Action option.",
		Action      = "Run",
		Callback    = function()
			Kuik.Notify({ Title = "Button fired" })
		end,
	})

	------------------------------------------------------------------
	-- Rows — the layout primitives underneath every control
	------------------------------------------------------------------

	Rows:Paragraph({
		Label = "Paragraph",
		Text  = "Prose with a label above it. No control, no fill — it sits at the same rhythm as a row so a page can mix explanation and configuration without a visual seam.",
	})

	Rows:Paragraph({
		Text = "A paragraph with no Label is body text on its own.",
	})

	Rows:Gap({ Height = 18 })

	Rows:Toggle({
		Label   = "Short row",
		Default = true,
	})

	Rows:Toggle({
		Label       = "Tall row",
		Description = "A Description makes the row taller and adds the dim second line.",
		Default     = false,
	})

	Rows:Toggle({
		Label       = "Flat row",
		Description = "Flat = true drops the row fill and the hover lift.",
		Flat        = true,
		Default     = true,
	})

	Rows:Gap({ Height = 18 })

	--- Declared last, drawn first — LayoutOrder overrides declaration order.
	Rows:Toggle({
		Label       = "Explicit LayoutOrder",
		Description = "Declared last in the source, but LayoutOrder = -1 floats it to the top of this page.",
		LayoutOrder = -1,
		Default     = false,
	})

	------------------------------------------------------------------
	-- Values — the handle API
	------------------------------------------------------------------

	Values:Paragraph({
		Label = "Handles",
		Text  = "Every control returns a handle with :Get(), :Set(Value) and :Set(Value, true). The silent form updates the visual without firing the callback — which is what you want when restoring saved settings.",
	})

	local Target = Values:Toggle({
		Label       = "Target",
		Description = "Watch the readout below as the buttons drive this.",
		Default     = false,
		Callback    = function(Value)
			Console:Push("INFO", "target callback fired: " .. tostring(Value))
		end,
	})

	local Readout = Values:Input({
		Label       = "Readout",
		Description = "Updated with the silent form, so it never fires its own callback.",
		Default     = tostring(Target:Get()),
	})

	Values:Button({
		Label       = ":Set(true)",
		Description = "Fires the target's callback — watch the console top-right.",
		Action      = "Set",
		Callback    = function()
			Target:Set(true)
			Readout:Set(tostring(Target:Get()), true)
		end,
	})

	Values:Button({
		Label       = ":Set(false, true)",
		Description = "Silent. The knob moves, no callback fires, nothing logs.",
		Action      = "Silent",
		Callback    = function()
			Target:Set(false, true)
			Readout:Set(tostring(Target:Get()), true)
		end,
	})

	local Doomed = Values:Toggle({
		Label       = "Disposable row",
		Description = "The button below calls :Destroy() on this row.",
		Default     = true,
	})

	Values:Button({
		Label       = ":Destroy()",
		Description = "Removes the row above from the page.",
		Action      = "Destroy",
		Callback    = function()
			if Doomed then
				Doomed:Destroy()
				Doomed = nil
				Console:Push("WARN", "row destroyed")
			end
		end,
	})

	------------------------------------------------------------------
	-- HUD
	------------------------------------------------------------------

	Hud:Paragraph({
		Label = "Toast",
		Text  = "A centred announcement bracketed by two rules. Duration 0 makes it persistent.",
	})

	Hud:Button({
		Label = "Timed toast", Description = "Fades itself after 3 seconds.",
		Action = "Toast",
		Callback = function()
			Kuik.Toast("This one expires.", { Duration = 3, Y = 96 })
		end,
	})

	Hud:Button({
		Label = "Coloured toast", Description = "The Color option tints the text and both rules.",
		Action = "Toast",
		Callback = function()
			Kuik.Toast("Round starting.", { Duration = 3, Y = 118, Color = Kuik.Theme.Warn })
		end,
	})

	Hud:Button({
		Label = "Rewrite the banner", Description = "Calls :Set() on the persistent toast at the top.",
		Action = "Set",
		Callback = function()
			Banner:Set(string.format("Rewritten at %s.", os.date("%I:%M:%S %p")))
		end,
	})

	Hud:Gap({ Height = 14 })

	Hud:Paragraph({
		Label = "Notify",
		Text  = "The one component with a fill: a card that drops in from the top edge.",
	})

	Hud:Button({
		Label = "Plain notify", Action = "Notify",
		Callback = function()
			Kuik.Notify({ Title = "<b>Chloé Mercier</b> joined", Duration = 4 })
		end,
	})

	Hud:Button({
		Label = "Notify with avatar", Description = "Takes an Image and a Width.",
		Action = "Notify",
		Callback = function()
			Kuik.Notify({
				Title = "You've joined <b>loll</b> and <b>kryptra</b>",
				Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60", LocalPlayer.UserId),
				Width = 300,
				Duration = 4,
			})
		end,
	})

	Hud:Gap({ Height = 14 })

	Hud:Paragraph({
		Label = "Hints, log and console",
		Text  = "The right-edge keycap stack, the bottom-left bracketed feed, and the top-right severity feed.",
	})

	Hud:Button({
		Label = "Add a hint", Description = "Hints:Add() returns a handle you can :Set() or :Destroy().",
		Action = "Add",
		Callback = function()
			local Hint = Hints:Add("F" .. (#ExtraHints + 1), "Extra action " .. (#ExtraHints + 1))
			table.insert(ExtraHints, Hint)
		end,
	})

	Hud:Button({
		Label = "Remove a hint", Action = "Remove",
		Callback = function()
			local Hint = table.remove(ExtraHints)

			if Hint then
				Hint:Destroy()
			end
		end,
	})

	Hud:Button({
		Label = "Push a log line", Description = "The feed keeps its last 7 lines and drops the rest off the top.",
		Action = "Push",
		Callback = function()
			Log:Push(string.format('<b>%s</b> voted <font color="#60d280">yes</font> at %s.',
				LocalPlayer.DisplayName, os.date("%I:%M:%S %p")))
		end,
	})

	Hud:Button({
		Label = "Clear the log", Action = "Clear",
		Callback = function() Log:Clear() end,
	})

	Hud:Button({
		Label = "All console levels", Description = "INFO, SUCCESS, WARN, ERROR, DEBUG — and an unknown level, which falls back to neutral.",
		Action = "Log",
		Callback = function()
			Console:Push("INFO",    "session established")
			Console:Push("SUCCESS", "session v4715 -> v4716")
			Console:Push("WARN",    "helsinki VOTE-1001 reason=Removed by server votekick.")
			Console:Push("ERROR",   "replication timeout after 30s")
			Console:Push("DEBUG",   "tick=1 dt=0.0166")
			Console:Push("NONSENSE", "unknown levels render neutral")
		end,
	})

	Hud:Gap({ Height = 14 })

	Hud:Paragraph({
		Label = "Watermark",
		Text  = "The monospace status line welded to the bottom edge. The reference has a setting for which side it sits on, so so does this.",
	})

	Hud:Dropdown({
		Label = "Watermark side", Description = "Calls Watermark:SetSide().",
		Items = { "Left", "Right" },
		Default = "Left",
		Callback = function(Value) Watermark:SetSide(Value) end,
	})

	Hud:Button({
		Label = "Rewrite the fields", Description = "Watermark:Set() replaces every field, and drops any left over from a longer state.",
		Action = "Set",
		Callback = function()
			Watermark:Set({ "KUIK_v" .. Kuik.Version.Version, os.date("%I:%M:%S %p") })
		end,
	})

	------------------------------------------------------------------
	-- Window
	------------------------------------------------------------------

	WindowTab:Paragraph({
		Label = "Open state",
		Text  = "Open, Close and SetOpen. Note that the window's open/close is NOT called Toggle — every container gets a :Toggle() row constructor mixed in, so that name is taken.",
	})

	WindowTab:Button({
		Label = "Close for 2 seconds", Description = "Window:Close(), then Window:Open() on a timer.",
		Action = "Close",
		Callback = function()
			Window:Close()
			task.delay(2, function() Window:Open() end)
		end,
	})

	WindowTab:Button({
		Label = "SetOpen(not IsOpen())", Description = "The form the bind key uses internally.",
		Action = "Flip",
		Callback = function()
			Window:SetOpen(not Window:IsOpen())
			task.delay(1.5, function() Window:SetOpen(true) end)
		end,
	})

	WindowTab:Gap({ Height = 14 })

	WindowTab:Paragraph({
		Label = "Parallax",
		Text  = "The interface drifts against camera motion and springs back. Turn it on, then look around.",
	})

	WindowTab:Toggle({
		Label = "UI Parallax", Description = "Move interface elements with camera motion.",
		Default = State.ParallaxOn,
		Callback = function(Value)
			State.ParallaxOn = Value
			Window:SetParallax(Value and State.Parallax or 0)
		end,
	})

	WindowTab:Stepper({
		Label = "Movement amount", Description = "Maximum drift in pixels, either axis.",
		Min = 0, Max = 24, Step = 1,
		Default = State.Parallax,
		Callback = function(Value)
			State.Parallax = Value

			if State.ParallaxOn then
				Window:SetParallax(Value)
			end
		end,
	})

	WindowTab:Gap({ Height = 14 })

	WindowTab:Paragraph({
		Label = "Tabs",
		Text  = "Tabs:Select() moves the shared white pill; Tabs:Active() reports where it is.",
	})

	WindowTab:Button({
		Label = "Select the Controls tab", Action = "Select",
		Callback = function() Tabs:Select("Controls") end,
	})

	WindowTab:Button({
		Label = "Report the active tab", Action = "Active",
		Callback = function()
			Console:Push("INFO", "active tab = " .. tostring(Tabs:Active()))
		end,
	})

	------------------------------------------------------------------
	-- Select — the selection widgets
	------------------------------------------------------------------

	Select:Paragraph({
		Label = "Structure and selection",
		Text  = "Dividers, collapsible groups, and the four ways to pick something.",
	})

	Select:Divider({ Label = "Divider" })

	Select:Radio({
		Label = "Radio", Description = "Exclusive. A hairline ring with a filled centre.",
		Items = { "Stereo", "Mono", "Headphones" },
		Default = "Stereo",
		Callback = function(Value) Console:Push("INFO", "radio = " .. Value) end,
	})

	Select:Checkbox({
		Label = "Checkbox", Description = "For when a switch would overstate the change.",
		Default = true,
	})

	Select:Chips({
		Label = "Chips", Description = "Multi-select, in the same pill shape as the tab bar.",
		Items = { "Melee", "Ranged", "Support", "Stealth", "Heavy" },
		Default = { "Melee", "Support" },
		Callback = function(Values)
			Console:Push("INFO", string.format("chips = %d selected", #Values))
		end,
	})

	Select:List({
		Label = "List", Description = "Scrollable. The selected row takes a left hairline, not a fill.",
		Items = { "us-east-1", "us-west-2", "eu-west-1", "ap-south-1", "sa-east-1", "af-south-1" },
		Default = "eu-west-1",
		Height = 120,
		Callback = function(Value) Console:Push("INFO", "region = " .. Value) end,
	})

	Select:Divider({})

	local Advanced = Select:Accordion({
		Label = "Accordion",
		Description = "A real container — anything that goes on a page goes in here.",
		Open = false,
		Callback = function(Open) Console:Push("DEBUG", "accordion open = " .. tostring(Open)) end,
	})

	Advanced:Toggle({ Label = "Nested toggle", Default = true })
	Advanced:Slider({ Label = "Nested slider", Min = 0, Max = 10, Step = 1, Default = 4 })

	local Deeper = Advanced:Accordion({ Label = "And they nest", Open = false })
	Deeper:Checkbox({ Label = "All the way down", Default = false })

	Select:Tree({
		Label = "Tree", Description = "Nested and expandable. Indentation is the only structure — no guides, no boxes.",
		Nodes = {
			{ Label = "game", Open = true, Children = {
				{ Label = "Workspace", Open = true, Children = {
					{ Label = "Baseplate" },
					{ Label = "SpawnLocation" },
				} },
				{ Label = "ReplicatedStorage", Children = { { Label = "Kuik" } } },
				{ Label = "StarterPlayer", Children = {
					{ Label = "StarterPlayerScripts", Children = { { Label = "KuikShowcase" } } },
				} },
			} },
		},
		Callback = function(Node) Console:Push("INFO", "tree = " .. tostring(Node.Label)) end,
	})

	Select:Divider({})

	Select:Dropdown({
		Label = "Dropdown at the bottom",
		Description = "Deliberately placed last: the menu now lives on the window overlay, so it escapes the body's clipping and flips upward here.",
		Items = { "Alpha", "Bravo", "Charlie", "Delta" },
		Default = "Alpha",
	})

	Select:Dropdown({
		Label = "Dropdown with a scroller",
		Description = "More items than Visible get their own spring-scrolled list.",
		Items = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten" },
		Default = "One",
		Visible = 5,
	})

	------------------------------------------------------------------
	-- Data — readouts
	------------------------------------------------------------------

	Data:Paragraph({
		Label = "Readouts",
		Text  = "Things the player reads rather than changes. Colour is allowed here, because here it means something.",
	})

	Data:Badge({
		Label = "Connection", Description = "A semantic tag. The only colour inside a row.",
		Text = "STABLE", Color = Kuik.Theme.Good,
	})

	Data:Badge({ Label = "Region", Text = "eu-west-1", Color = Kuik.Theme.Info })
	Data:Badge({ Label = "Build", Text = "PROTOTYPE", Color = Kuik.Theme.Danger })

	Data:Divider({})

	StatusPing = Data:Status({ Label = "Ping", Description = "Monospace key/value, the watermark's voice.", Value = "-- ms" })
	StatusUptime = Data:Status({ Label = "Session uptime", Value = "0s" })

	Data:Alert({
		Label = "Alert", Text = "A message with a semantic left rule. The rule carries the severity, so the text does not have to shout.",
		Color = Kuik.Theme.Warn,
	})

	Data:Alert({
		Label = "Connection lost", Text = "Reconnecting to eu-west-1.",
		Color = Kuik.Theme.Danger,
	})

	Data:Divider({})

	local Load = Data:Ring({
		Label = "Ring", Description = "Circular progress as ticks around a dial, not a filled arc.",
		Default = 0.62, Max = 1,
	})

	Data:Slider({
		Label = "Drive the ring", Min = 0, Max = 1, Step = 0.01, Default = 0.62,
		Format = function(V) return string.format("%d%%", V * 100) end,
		Callback = function(Value) Load:Set(Value) end,
	})

	local Download = Data:Progress({
		Label = "Determinate progress", Description = "The slider's track with no thumb.",
		Default = 0.35, Max = 1,
	})

	Data:Button({
		Label = "Run the progress bar", Action = "Run",
		Callback = function()
			task.spawn(function()
				for Step = 0, 20 do
					Download:Set(Step / 20)
					task.wait(0.08)
				end
			end)
		end,
	})

	local Memory = Data:Meter({
		Label = "Meter", Description = "Segmented gauge. Goes amber past 70%, red past 90% — the only widget that picks its own colour.",
		Default = 42, Max = 100, Warn = 0.7, Danger = 0.9, Segments = 24,
	})

	Data:Slider({
		Label = "Drive the meter", Min = 0, Max = 100, Step = 1, Default = 42,
		Callback = function(Value) Memory:Set(Value) end,
	})

	Data:Spinner({
		Label = "Spinner", Description = "Indeterminate. Eight dots chasing, for work with no knowable progress.",
	})

	Data:Rating({
		Label = "Rating", Description = "Click a bar. Clicking the current value clears it.",
		Count = 5, Default = 3,
		Callback = function(Value) Console:Push("INFO", "rating = " .. Value) end,
	})

	Data:Pagination({
		Label = "Pagination", Description = "Chevrons drawn from bars, like every glyph here.",
		Default = 1, Pages = 6,
		Callback = function(Page) Console:Push("DEBUG", "page = " .. Page) end,
	})

	Data:Breadcrumb({
		Path = { "game", "Workspace", "Map", "Platform" },
		Callback = function(Part) Console:Push("INFO", "crumb = " .. Part) end,
	})

	------------------------------------------------------------------
	-- Charts
	------------------------------------------------------------------

	Charts:Paragraph({
		Label = "Charts",
		Text  = "Drawn from rotated 1px frames — the same hairline the window is built from, just at an angle. No canvas, no assets.",
	})

	local Frames = {}

	for Index = 1, 24 do
		Frames[Index] = 55 + math.sin(Index / 3) * 6
	end

	local Fps = Charts:Sparkline({
		Label = "Sparkline", Description = "Inline, sized to sit where a control would.",
		Values = Frames, Limit = 24,
	})

	local Latency = Charts:Graph({
		Label = "Graph", Description = "Full width, with a baseline and min/max labels.",
		Values = { 30, 44, 38, 51, 29, 47, 35, 42 },
		Height = 96, Limit = 48,
	})

	Charts:Button({
		Label = "Feed both with live data", Description = "Pushes 40 samples in.",
		Action = "Feed",
		Callback = function()
			task.spawn(function()
				for Index = 1, 40 do
					Fps:Push(52 + math.random() * 12)
					Latency:Push(25 + math.random() * 40)
					task.wait(0.06)
				end
			end)
		end,
	})

	local Throughput = Charts:Bars({
		Label = "Bars", Description = "Where a sparkline shows shape, this shows magnitude.",
		Values = { 4, 9, 6, 12, 8, 3, 11, 7, 5, 10 },
		Height = 64, Limit = 16,
	})

	Charts:Button({
		Label = "Push a bar", Action = "Push",
		Callback = function() Throughput:Push(math.random(1, 14), 16) end,
	})

	Charts:Graph({
		Label = "Flat series", Description = "A constant series still renders — the extent is padded rather than divided by zero.",
		Values = { 5, 5, 5, 5, 5 }, Height = 50,
	})

	Charts:Sparkline({
		Label = "Empty series", Description = "Fewer than two points draws nothing rather than erroring.",
		Values = {},
	})

	------------------------------------------------------------------
	-- Composite
	------------------------------------------------------------------

	Composite:Paragraph({
		Label = "Composites",
		Text  = "The widgets built out of several others.",
	})

	Composite:Avatar({
		Label = LocalPlayer.DisplayName,
		Description = "CONSERVATOR · joined 4 minutes ago",
		UserId = LocalPlayer.UserId,
	})

	local Scores = Composite:Table({
		Label = "Table", Description = "Dim headers, monospace values — a table is read down, not across.",
		Columns = {
			{ Label = "Player", Width = 0.5 },
			{ Label = "Score",  Width = 0.25, Align = "Right" },
			{ Label = "Ping",   Width = 0.25, Align = "Right" },
		},
		Rows = {
			{ LocalPlayer.DisplayName, 41, "34ms" },
			{ "loll", 38, "51ms" },
			{ "kryptra", 22, "88ms" },
		},
	})

	Composite:Button({
		Label = "Shuffle the table", Action = "Shuffle",
		Callback = function()
			Scores:Set({
				{ LocalPlayer.DisplayName, math.random(0, 60), math.random(20, 120) .. "ms" },
				{ "loll", math.random(0, 60), math.random(20, 120) .. "ms" },
				{ "kryptra", math.random(0, 60), math.random(20, 120) .. "ms" },
			})
		end,
	})

	Composite:Vector({
		Label = "Vector", Description = "Three numeric fields on one row, for positions and offsets.",
		Default = { 0, 5, -12 }, Step = 0.1,
		Callback = function(Values)
			Console:Push("INFO", string.format("vector = %.1f, %.1f, %.1f", Values[1], Values[2], Values[3]))
		end,
	})

	Composite:Vector({
		Label = "Two axes", Description = "The axis list is yours to choose.",
		Axes = { "U", "V" }, Default = { 0.5, 0.25 }, Step = 0.01,
	})

	Composite:Color({
		Label = "Colour", Description = "A swatch and three channel tracks. Not a wheel — a settings panel wants RGB.",
		Default = Kuik.Theme.Info,
		Callback = function(Value)
			Console:Push("INFO", "colour = " .. string.format("#%02X%02X%02X",
				Value.R * 255, Value.G * 255, Value.B * 255))
		end,
	})

	------------------------------------------------------------------
	-- Pickers
	------------------------------------------------------------------

	Pickers:Paragraph({
		Label = "Pickers",
		Text  = "The controls that pick a value out of a continuous space rather than a list.",
	})

	Pickers:ColorPicker({
		Label = "Colour picker",
		Description = "A saturation/value field over a hue strip, with hairline crosshairs instead of pucks.",
		Default = Kuik.Theme.Info,
		Height = 110,
		Callback = function(Value)
			Console:Push("INFO", string.format("picked #%02X%02X%02X",
				Value.R * 255, Value.G * 255, Value.B * 255))
		end,
	})

	Pickers:Color({
		Label = "RGB channels",
		Description = "The compact form: a swatch and three tracks, when a full field is more than the setting deserves.",
		Default = Kuik.Theme.Good,
	})

	Pickers:Divider({})

	Pickers:Segmented({
		Label = "Segmented",
		Description = "The tab bar shrunk into a row. One sliding pill, same as the tabs.",
		Items = { "Off", "Low", "High", "Ultra" },
		Default = "High",
		Callback = function(Value) Console:Push("INFO", "segmented = " .. Value) end,
	})

	Pickers:Range({
		Label = "Range",
		Description = "Two thumbs on one track. Whichever is nearer the pointer is the one that moves.",
		Min = 0, Max = 100, Step = 1, Low = 25, High = 75,
		Callback = function(Low, High)
			Console:Push("DEBUG", string.format("range = %d..%d", Low, High))
		end,
	})

	Pickers:Range({
		Label = "Formatted range",
		Min = 0, Max = 24, Step = 0.5, Low = 8, High = 17,
		Format = function(Low, High)
			return string.format("%04.1f – %04.1f", Low, High)
		end,
	})

	------------------------------------------------------------------
	-- Media
	------------------------------------------------------------------

	Media:Paragraph({
		Label = "Media",
		Text  = "Images fade in on load rather than popping, and links go through Roblox's own browser prompt — which is all a client script can honestly do with a URL.",
	})

	Media:Image({
		Label = "Image embed", Description = "Fit = Contain letterboxes; Cover crops; Stretch distorts.",
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=420&h=420", LocalPlayer.UserId),
		Height = 140,
		Caption = "rbxthumb, letterboxed into the block.",
	})

	Media:Link({
		Label = "Roblox DevForum",
		Description = "Opens through GuiService's browser prompt.",
		Url = "https://devforum.roblox.com",
		Action = "Open",
		Callback = function(Url, Opened)
			Console:Push(Opened and "SUCCESS" or "WARN", "link " .. Url)
		end,
	})

	Media:Paragraph({
		Label = "Paragraph with an embed",
		Text  = "Prose can carry its own image underneath it.",
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", LocalPlayer.UserId),
		ImageHeight = 90,
	})

	------------------------------------------------------------------
	-- Layers — menus, prompts, child windows, card decks
	------------------------------------------------------------------

	Layers:Paragraph({
		Label = "Layers",
		Text  = "Everything that appears over the interface rather than in it.",
	})

	local ContextMenu = Kuik.Menu({
		Items = {
			{ Label = "Copy", Shortcut = "Ctrl+C" },
			{ Label = "Duplicate", Shortcut = "Ctrl+D" },
			{ Separator = true },
			{ Label = "Delete", Color = Kuik.Theme.Danger },
		},
		Callback = function(Item)
			Console:Push("INFO", "menu -> " .. tostring(Item.Label))
		end,
	})

	Layers:Button({
		Label = "Overlay menu", Description = "Unrolls at the pointer, flips at the screen edge, dismisses on an outside click.",
		Action = "Open",
		Callback = function()
			local At = UserInputService:GetMouseLocation()
			ContextMenu:Show(At.X, At.Y)
		end,
	})

	Layers:Button({
		Label = "Prompt", Description = "A modal question. Two rules, centred, takes the screen until answered. Escape dismisses.",
		Action = "Ask",
		Callback = function()
			Kuik.Prompt({
				Title = "Reset preferences?",
				Text = "Every setting returns to its shipped default. This cannot be undone.",
				Buttons = {
					{ Label = "Cancel", Value = "cancel" },
					{ Label = "Reset", Value = "reset", Primary = true },
				},
				Callback = function(Choice)
					Console:Push(Choice == "reset" and "WARN" or "INFO",
						"prompt -> " .. tostring(Choice))
				end,
			})
		end,
	})

	Layers:Divider({})

	local Detail = Window:Child({
		Title = "Detail",
		Subtitle = "A window owned by another",
		Width = 300,
		Height = 300,
	})

	Detail:Paragraph({
		Label = "Child window",
		Text  = "Opens beside its parent, closes when the parent closes, and is destroyed with it. It borrows the parent's backdrop rather than stacking a second blur.",
	})

	Detail:Toggle({ Label = "A setting in here", Default = true })
	Detail:Slider({ Label = "And another", Min = 0, Max = 10, Step = 1, Default = 6 })

	Layers:Button({
		Label = "Child window", Description = "Opens to the right of this one and shares its backdrop.",
		Action = "Toggle",
		Callback = function()
			Detail:SetOpen(not Detail:IsOpen())
		end,
	})

	Layers:Divider({ Label = "Card deck" })

	Layers:Paragraph({
		Text = "Several windows laid out horizontally: the focused one centre and full size, its neighbours shrunk back and dimmed. Chevrons at the screen edges step the focus, arrow keys work too, and clicking a card behind focuses it instead of interacting with it.",
	})

	Layers:Button({
		Label = "Build a three-card deck", Description = "Adds this window plus two more. Left/Right or the chevrons to move.",
		Action = "Deck",
		Callback = function()
			if Deck then
				Console:Push("WARN", "deck already built")
				return
			end

			Deck = Kuik.Cards({
				Gap = 50,
				Callback = function(Index) Console:Push("DEBUG", "card " .. Index) end,
			})

			for Index = 1, 2 do
				local Card = Kuik.Window({
					Title = "Card " .. Index,
					Subtitle = "One of the deck",
					Width = 380,
					Height = 420,
					Blur = 0,
					Wash = 1,
				})

				Card:Paragraph({
					Label = "Card " .. Index,
					Text = "A full window in its own right — everything still works while it is focused.",
				})

				Card:Toggle({ Label = "A setting", Default = Index == 1 })
				Card:Slider({ Label = "A value", Min = 0, Max = 100, Step = 1, Default = Index * 30 })
				Card:Segmented({ Label = "A mode", Items = { "A", "B", "C" }, Default = "B" })

				Card:Open()
				DeckCards[Index] = Card
			end

			Deck:Add(Window)
			Deck:Add(DeckCards[1])
			Deck:Add(DeckCards[2])

			Console:Push("SUCCESS", "deck built — Left/Right to move")
		end,
	})

	Layers:Button({
		Label = "Tear the deck down", Action = "Clear",
		Callback = function()
			if not Deck then
				return
			end

			Deck:Destroy()
			Deck = nil

			for Index, Card in DeckCards do
				Card:Destroy()
				DeckCards[Index] = nil
			end

			Window.Root.Position = UDim2.new(0.5, 0, 0.5, 0)

			local Scale = Window.Root:FindFirstChildOfClass("UIScale")
			if Scale then Scale.Scale = 1 end

			Window.Group.GroupTransparency = 0
			Window:SetParallax(State.ParallaxOn and State.Parallax or 0)
		end,
	})

	------------------------------------------------------------------
	-- Theme
	------------------------------------------------------------------

	ThemeTab:Paragraph({
		Label = "Live tokens",
		Text  = "Theme and Metrics are plain tables read at construction time. Motion picks up changes immediately; colour, font and size need a rebuild. The button at the bottom does that.",
	})

	ThemeTab:Slider({
		Label = "Motion scale",
		Description = "Multiplies every Theme.Motion duration. 1.0 is Lume's shipped timing. Takes effect on the very next tween.",
		Min = 0.25, Max = 3, Step = 0.05,
		Default = State.MotionSpeed,
		Format = function(Value) return string.format("%.2fx", Value) end,
		Callback = function(Value)
			State.MotionSpeed = Value

			for Name, Spec in Kuik.Theme.Motion do
				if BaseMotion[Name] then
					Spec.Duration = BaseMotion[Name] * Value
				end
			end
		end,
	})

	ThemeTab:Dropdown({
		Label = "Window easing",
		Description = "The curve the open animation runs on. Lume's default is outQuint.",
		Items = { "outQuint", "outQuad", "outCubic", "outBack", "outElastic", "linear" },
		Default = Kuik.Theme.Motion.enter.Easing,
		Callback = function(Value)
			Kuik.Theme.Motion.enter.Easing = Value
		end,
	})

	ThemeTab:Slider({
		Label = "Theme.RuleTransparency", Description = "How present the two vertical rules are. Rebuild to see it.",
		Min = 0, Max = 0.9, Step = 0.05,
		Default = State.RuleAlpha,
		Callback = function(Value)
			State.RuleAlpha = Value
			Kuik.Theme.RuleTransparency = Value
		end,
	})

	ThemeTab:Slider({
		Label = "Theme.RowTransparency", Description = "The barely-there row fill. 1 is invisible.",
		Min = 0.8, Max = 1, Step = 0.01,
		Default = State.RowAlpha,
		Callback = function(Value)
			State.RowAlpha = Value
			Kuik.Theme.RowTransparency = Value
			Kuik.Theme.RowHoverTransparency = math.max(0.8, Value - 0.06)
		end,
	})

	ThemeTab:Dropdown({
		Label = "Theme.Font", Description = "Montserrat is the reference match; Gotham is the built-in.",
		Items = { "Montserrat", "Gotham", "BuilderSans" },
		Default = State.FontChoice,
		Callback = function(Value)
			State.FontChoice = Value

			if Value == "Gotham" then
				Kuik.Theme.Font       = Font.fromEnum(Enum.Font.Gotham)
				Kuik.Theme.FontMedium = Font.fromEnum(Enum.Font.GothamMedium)
				Kuik.Theme.FontBold   = Font.fromEnum(Enum.Font.GothamBold)
			elseif Value == "BuilderSans" then
				Kuik.Theme.Font       = Font.fromEnum(Enum.Font.BuilderSans)
				Kuik.Theme.FontMedium = Font.fromEnum(Enum.Font.BuilderSansMedium)
				Kuik.Theme.FontBold   = Font.fromEnum(Enum.Font.BuilderSansBold)
			else
				Kuik.Theme.Font       = Font.fromName("Montserrat", Enum.FontWeight.Regular)
				Kuik.Theme.FontMedium = Font.fromName("Montserrat", Enum.FontWeight.Medium)
				Kuik.Theme.FontBold   = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
			end
		end,
	})

	ThemeTab:Stepper({
		Label = "Metrics.WindowWidth", Description = "Metrics is live too.",
		Min = 340, Max = 720, Step = 20,
		Default = State.WindowWidth,
		Callback = function(Value)
			State.WindowWidth = Value
			Kuik.Metrics.WindowWidth = Value
		end,
	})

	ThemeTab:Slider({
		Label = "Backdrop blur", Description = "The BlurEffect size while the window is open. Rebuild to apply.",
		Min = 0, Max = 48, Step = 1,
		Default = State.Blur,
		Callback = function(Value) State.Blur = Value end,
	})

	ThemeTab:Slider({
		Label = "Backdrop wash", Description = "Transparency of the white plate behind the type. Rebuild to apply.",
		Min = 0, Max = 1, Step = 0.01,
		Default = State.Wash,
		Callback = function(Value) State.Wash = Value end,
	})

	ThemeTab:Button({
		Label = "Rebuild the window", Description = "Destroys and reconstructs it so every token above takes effect.",
		Action = "Rebuild",
		Callback = function()
			Console:Push("WARN", "rebuilding window")

			task.defer(function()
				Window:Destroy()
				Build()
			end)
		end,
	})

	ThemeTab:Button({
		Label = "Reset the theme", Description = "Back to the shipped defaults, then rebuild.",
		Action = "Reset",
		Callback = function()
			for Name, Base in BaseMotion do
				Kuik.Theme.Motion[Name].Duration = Base
			end

			Kuik.Theme.Motion.enter.Easing  = "outQuint"
			Kuik.Theme.RuleTransparency     = 0.45
			Kuik.Theme.RowTransparency      = 0.94
			Kuik.Theme.RowHoverTransparency = 0.88
			Kuik.Theme.Font       = Font.fromName("Montserrat", Enum.FontWeight.Regular)
			Kuik.Theme.FontMedium = Font.fromName("Montserrat", Enum.FontWeight.Medium)
			Kuik.Theme.FontBold   = Font.fromName("Montserrat", Enum.FontWeight.SemiBold)
			Kuik.Metrics.WindowWidth = 460

			State.MotionSpeed = 1
			State.RuleAlpha   = 0.45
			State.RowAlpha    = 0.94
			State.FontChoice  = "Montserrat"
			State.WindowWidth = 460
			State.Blur        = 22
			State.Wash        = 0.5

			task.defer(function()
				Window:Destroy()
				Build()
			end)
		end,
	})

	------------------------------------------------------------------
	-- About
	------------------------------------------------------------------

	local Exports = {}

	for Key in pairs(Kuik) do
		table.insert(Exports, Key)
	end

	table.sort(Exports)

	About:Paragraph({
		Label = string.format("%s %s", Kuik.Version.Name, Kuik.Version.Version),
		Text  = "A Roblox UI library in the hairline-rule style. There is no panel — the window is two 1px vertical rules with nothing between them, and hierarchy comes from typography and negative space alone.",
	})

	About:Paragraph({
		Label = "Exports",
		Text  = table.concat(Exports, " · "),
	})

	About:Paragraph({
		Label = "Escape hatches",
		Text  = "Kuik.Screen() hands back the shared ScreenGui, and Kuik.New / Kuik.Tween are the same constructor and tween helper the library uses internally — so custom elements land on the same layer and the same motion curve.",
	})

	About:Button({
		Label = "Draw a custom element", Description = "Built with Kuik.New into Kuik.Screen(), animated with Kuik.Tween.",
		Action = "Draw",
		Callback = function()
			local Mark = Kuik.New("Frame", {
				Name                   = "CustomMark",
				Parent                 = Kuik.Screen(),
				BackgroundTransparency = 1,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, 0.82, 0),
				Size                   = UDim2.new(0, 0, 0, 40),
				ZIndex                 = 8,
			})

			for Index = 1, 2 do
				local Bar = Kuik.New("Frame", {
					Parent                 = Mark,
					BackgroundColor3       = Kuik.Theme.White,
					BackgroundTransparency = 1,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(0.5, 0.5),
					Position               = UDim2.new(0.5, 0, 0.5, 0),
					Size                   = UDim2.new(0, 1, 1, 0),
				})

				Kuik.Tween(Bar, {
					BackgroundTransparency = Kuik.Theme.RuleTransparency,
					Position = UDim2.new(0.5, Index == 1 and -90 or 90, 0.5, 0),
				}, 0.5)
			end

			local Label = Kuik.New("TextLabel", {
				Parent                 = Mark,
				BackgroundTransparency = 1,
				Text                   = "drawn with Kuik.New",
				TextColor3             = Kuik.Theme.White,
				TextTransparency       = 1,
				FontFace               = Kuik.Theme.FontMono,
				TextSize               = Kuik.Metrics.MonoSize + 2,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, 0.5, 0),
				Size                   = UDim2.new(0, 200, 1, 0),
			})

			Kuik.Tween(Label, { TextTransparency = 0 }, 0.5)

			task.delay(2.5, function()
				Mark:Destroy()
			end)
		end,
	})

	------------------------------------------------------------------
	-- A section after the tabs, so its rows persist across every page.
	------------------------------------------------------------------

	local Footer = Window:Section("Session", "Rows on a section sit below every page, whatever tab is active.")

	Footer:Paragraph({
		Text = string.format("%s · place %d · %d player(s)",
			LocalPlayer.DisplayName, game.PlaceId, #Players:GetPlayers()),
	})

	--- And a row added straight to the window, with no section or tab at all.
	Window:Toggle({
		Label       = "Bare row on the window",
		Description = "Containers nest, but they are optional — a window is itself a container.",
		Flat        = true,
		Default     = true,
	})

	Console:Push("SUCCESS", "showcase built")
end

Build()


--============================================================================
-- Live HUD
--============================================================================

--- The Data tab's two status rows, driven live.
task.spawn(function()
	local Started = os.clock()

	while true do
		task.wait(1)

		local Ok = pcall(function()
			StatusPing:Set(string.format("%d ms", math.random(28, 46)))
			StatusUptime:Set(string.format("%ds", math.floor(os.clock() - Started)))
		end)

		if not Ok then
			break
		end
	end
end)

Players.PlayerAdded:Connect(function(Player)
	Kuik.Notify({ Title = string.format("<b>%s</b> joined", Player.DisplayName) })
	Log:Push(string.format("%s joined the server.", Player.DisplayName))
end)

Players.PlayerRemoving:Connect(function(Player)
	Console:Push("WARN", string.format("%s reason=Left the server.", Player.Name))
	Log:Push(string.format("%s left the server.", Player.DisplayName))
end)
