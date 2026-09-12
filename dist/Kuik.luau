--!nonstrict
-- Kuik 2.0.0 - bundled from src/ by tools/build.py.
-- Comments are stripped so the whole library fits inside Roblox's 200,000
-- character limit for a ModuleScript Source assignment.
-- Read src/ instead; that is the source of truth.
local KuikModules = {}
local KuikLoaded = {}
local function KuikRequire(Name)
	local Cached = KuikLoaded[Name]
	if Cached ~= nil then
		return Cached
	end
	local Factory = KuikModules[Name]
	if not Factory then
		error("Kuik: no module named " .. tostring(Name), 2)
	end
	local Result = Factory()
	KuikLoaded[Name] = Result
	return Result
end
KuikModules[""] = function()
local Palette  = KuikRequire("Theme")
local Util     = KuikRequire("Util")
local Motion   = KuikRequire("Motion")
local Parts    = KuikRequire("Parts")
local Scroll   = KuikRequire("Scroll")
local Screen   = KuikRequire("Screen")
local Controls = KuikRequire("Controls")
local Layout   = KuikRequire("Layout")
local Window   = KuikRequire("Window")
local Hud      = KuikRequire("Hud")
local Layers   = KuikRequire("Layers")
local Reveal   = KuikRequire("Reveal")
local Kuik = {}
Kuik.Version = {
	Name    = "Kuik",
	Version = "2.0.0",
}
Kuik.Theme   = Palette.Tokens
Kuik.Metrics = Palette.Metrics
Kuik.Themes  = Palette.Themes
Kuik.Window = Window
function Kuik.Panel(Options)
	return Window(Util.Merge({
		Variant     = "Bare",
		Wash        = 1,
		Blur        = 0,
		Backdrop    = false,
		UnlockMouse = false,
		Scroll      = false,
		Fit         = false,
		Open        = true,
		Width       = 220,
		Height      = 80,
	}, Options))
end
function Kuik.Card(Options)
	return Window(Util.Merge({ Variant = "Card" }, Options))
end
Kuik.Menu    = Layers.Menu
Kuik.Prompt  = Layers.Prompt
Kuik.Cards   = Layers.Cards
Kuik.Popover = Layers.Popover
Kuik.Sheet   = Layers.Sheet
Kuik.Drawer  = Layers.Drawer
Kuik.Coach   = Layers.Coach
Kuik.Toast     = Hud.Toast
Kuik.Notify    = Hud.Notify
Kuik.Hints     = Hud.Hints
Kuik.Log       = Hud.Log
Kuik.Arrival   = Hud.Arrival
Kuik.Feed      = Hud.Feed
Kuik.Console   = Hud.Console
Kuik.Watermark = Hud.Watermark
Kuik.Bar       = Hud.Bar
Kuik.Timer     = Hud.Timer
Kuik.Ammo      = Hud.Ammo
Kuik.Crosshair = Hud.Crosshair
Kuik.Killfeed  = Hud.Killfeed
Kuik.Objective = Hud.Objective
Kuik.Vignette  = Hud.Vignette
Kuik.Compass   = Hud.Compass
Kuik.Fab       = Hud.Fab
Kuik.Viewfinder = Hud.Viewfinder
Kuik.Reticle   = Hud.Crosshair
function Kuik.SetTheme(Theme, Repaint)
	return Palette.Set(Theme, Repaint)
end
function Kuik.GetTheme()
	return Palette.Name()
end
function Kuik.RegisterTheme(Name, Overlay)
	Palette.Register(Name, Overlay)
	return Kuik
end
function Kuik.OnTheme(Handler)
	return Palette.OnChange(Handler)
end
Kuik.Controls = Controls
function Kuik.Register(Name, Constructor)
	Controls[Name] = Constructor
	return Kuik
end
Kuik.New       = Util.New
Kuik.Text      = Util.Text
Kuik.Tween     = Motion.Tween
Kuik.Spring    = Motion.SpringTo
Kuik.Motion    = Motion
Kuik.Util      = Util
Kuik.Parts     = Parts
Kuik.Scroll    = Scroll.Attach
Kuik.Gleam     = Scroll.Gleam
Kuik.Edges     = Scroll.Edges
Kuik.Reveal    = Reveal
Kuik.Plate     = Reveal.Plate
Kuik.Follow    = Reveal.Follow
Kuik.Ghost     = Reveal.Ghost
Kuik.Trail     = Reveal.Trail
Kuik.Wipe      = Reveal.Wipe
Kuik.Close     = Reveal.Close
Kuik.Cover     = Reveal.Cover
Kuik.Flash     = Reveal.Flash
Kuik.Row       = Parts.Row
Kuik.Block     = Parts.Block
Kuik.Attach    = Layout.Attach
Kuik.Tooltip   = Parts.Tooltip
function Kuik.Showcase(Options)
	return KuikRequire("Showcase")(Kuik, Options)
end
function Kuik.Screen()
	return Screen.Get()
end
Kuik.Inset = Screen.Inset
Kuik.Cover = Screen.Cover
Kuik.Safe  = Screen.Safe
function Kuik.Blocked()
	return Screen.Blocked()
end
function Kuik.Reset()
	Screen.Destroy()
	for _, Effect in game:GetService("Lighting"):GetChildren() do
		if Effect.Name == "KuikBlur" then
			Effect:Destroy()
		end
	end
end
return Kuik
end
KuikModules["Controls"] = function()
local Controls = {}
local Sets = {
	KuikRequire("Controls/Inputs"),
	KuikRequire("Controls/Data"),
	KuikRequire("Controls/Colour"),
	KuikRequire("Controls/Pickers"),
	KuikRequire("Controls/Media"),
	KuikRequire("Controls/Content"),
	KuikRequire("Controls/More"),
	KuikRequire("Controls/Play"),
}
for _, Set in Sets do
	for Name, Constructor in Set do
		Controls[Name] = Constructor
	end
end
return Controls
end
KuikModules["Controls/Colour"] = function()
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Clamp   = Util.Clamp
local Hex     = Util.Hex
local Round   = Util.Round
local Tween = Motion.Tween
local Block       = Parts.Block
local BlockHandle = Parts.BlockHandle
local Draggable   = Parts.Draggable
local Controls = {}
local function Readout(Built, Value)
	local Slot = Built.Aside or Built.Frame
	local Swatch = New("Frame", {
		Name             = "Swatch",
		Parent           = Slot,
		BackgroundColor3 = Value,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0),
		Position         = UDim2.new(1, 0, 0, 0),
		Size             = UDim2.new(0, 34, 0, 20),
		ZIndex           = 3,
	}, {
		Corner(Metrics.ChipRadius),
		Stroke(Theme.White, 0.7, 1),
	})
	local Label = Text({
		Parent           = Slot,
		Text             = Hex(Value),
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -40, 0.5, 0),
		Size             = UDim2.new(0, 60, 0, 12),
		AutomaticSize    = Enum.AutomaticSize.None,
		ZIndex           = 3,
	})
	Palette.Release(Swatch)
	return Swatch, Label
end
function Controls.Color(Container, Options)
	local Handle = {}
	local Value = Options.Default or Color3.fromRGB(255, 255, 255)
	local Built = Block(Container, Options)
	local Swatch, Label = Readout(Built, Value)
	List(7).Parent = Built.Content
	local Channels = { { "R", Value.R }, { "G", Value.G }, { "B", Value.B } }
	local Fills = {}
	local Stops = {}
	local function Compose(Notify)
		Value = Color3.new(Channels[1][2], Channels[2][2], Channels[3][2])
		Swatch.BackgroundColor3 = Value
		Label.Text = Hex(Value)
		if Notify and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	for Index, Channel in Channels do
		local Line = New("Frame", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 14),
			LayoutOrder            = Index,
		})
		Text({
			Parent           = Line,
			Text             = Channel[1],
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Size             = UDim2.new(0, 12, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		local Track = New("Frame", {
			Parent                 = Line,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.82,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, 16, 0.5, 0),
			Size                   = UDim2.new(1, -16, 0, Metrics.SliderTrack),
		}, {
			Corner(2),
		})
		local Tint = Index == 1 and Color3.fromRGB(255, 96, 96)
			or Index == 2 and Color3.fromRGB(96, 210, 128)
			or Color3.fromRGB(96, 156, 255)
		local Fill = New("Frame", {
			Parent           = Track,
			BackgroundColor3 = Tint,
			BorderSizePixel  = 0,
			Size             = UDim2.new(Channel[2], 0, 1, 0),
		}, {
			Corner(2),
		})
		Palette.Release(Fill)
		Fills[Index] = Fill
		local Grab = New("TextButton", {
			Parent                 = Line,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Position               = UDim2.new(0, 16, 0, 0),
			Size                   = UDim2.new(1, -16, 1, 0),
			ZIndex                 = 3,
		})
		local Stop = Draggable(Grab, Track, function(X)
			Channel[2] = Clamp(X, 0, 1)
			Fill.Size = UDim2.new(Channel[2], 0, 1, 0)
			Compose(true)
		end)
		table.insert(Stops, Stop)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Channels[1][2], Channels[2][2], Channels[3][2] = NewValue.R, NewValue.G, NewValue.B
		for Index, Fill in Fills do
			Fill.Size = UDim2.new(Channels[Index][2], 0, 1, 0)
		end
		Compose(not Silent)
		return Handle
	end
	Compose(false)
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		for _, Stop in Stops do
			Stop()
		end
	end)
	return Result
end
function Controls.ColorPicker(Container, Options)
	local Handle = {}
	local Value = Options.Default or Color3.fromRGB(255, 255, 255)
	local Hue, Saturation, Brightness = Value:ToHSV()
	local Built = Block(Container, Options)
	local Swatch, Label = Readout(Built, Value)
	List(8).Parent = Built.Content
	local Field = New("Frame", {
		Parent           = Built.Content,
		BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, Options.Height or 96),
		LayoutOrder      = 1,
		ClipsDescendants = true,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
	})
	Palette.Release(Field)
	New("Frame", {
		Parent                 = Field,
		BackgroundColor3       = Color3.new(1, 1, 1),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 2,
	}, {
		New("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	New("Frame", {
		Parent                 = Field,
		BackgroundColor3       = Color3.new(0, 0, 0),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	}, {
		New("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(0, 0, 0)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}),
	})
	local Marker = New("Frame", {
		Parent                 = Field,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Size                   = UDim2.new(0, 13, 0, 13),
		ZIndex                 = 5,
	})
	for Index = 1, 2 do
		New("Frame", {
			Parent           = Marker,
			BackgroundColor3 = Theme.White,
			BorderSizePixel  = 0,
			AnchorPoint      = Vector2.new(0.5, 0.5),
			Position         = UDim2.new(0.5, 0, 0.5, 0),
			Size             = Index == 1 and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 1, 1, 0),
			ZIndex           = 5,
		})
	end
	local Strip_ = New("Frame", {
		Parent           = Built.Content,
		BorderSizePixel  = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size             = UDim2.new(1, 0, 0, 12),
		LayoutOrder      = 2,
		ClipsDescendants = true,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0.000, 1, 1)),
				ColorSequenceKeypoint.new(0.166, Color3.fromHSV(0.166, 1, 1)),
				ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
				ColorSequenceKeypoint.new(0.500, Color3.fromHSV(0.500, 1, 1)),
				ColorSequenceKeypoint.new(0.666, Color3.fromHSV(0.666, 1, 1)),
				ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
				ColorSequenceKeypoint.new(1.000, Color3.fromHSV(1.000, 1, 1)),
			}),
		}),
	})
	Palette.Release(Strip_)
	local HueMarker = New("Frame", {
		Parent           = Strip_,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 0),
		Size             = UDim2.new(0, 2, 1, 0),
		ZIndex           = 3,
	})
	local function Compose(Notify)
		Value = Color3.fromHSV(Hue, Saturation, Brightness)
		Field.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
		Swatch.BackgroundColor3 = Value
		Label.Text = Hex(Value)
		Tween(Marker, { Position = UDim2.new(Saturation, 0, 1 - Brightness, 0) }, "drag")
		Tween(HueMarker, { Position = UDim2.new(Hue, 0, 0, 0) }, "drag")
		if Notify and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	local StopField = Draggable(Field, Field, function(X, Y)
		Saturation, Brightness = X, 1 - Y
		Compose(true)
	end)
	local StopStrip = Draggable(Strip_, Strip_, function(X)
		Hue = X
		Compose(true)
	end)
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Hue, Saturation, Brightness = NewValue:ToHSV()
		Compose(not Silent)
		return Handle
	end
	function Handle:GetHSV()
		return Hue, Saturation, Brightness
	end
	Compose(false)
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		StopField()
		StopStrip()
	end)
	return Result
end
function Controls.Swatches(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Value = Options.Default or Items[1]
	local Cells = {}
	local Built = Block(Container, Options)
	New("UIListLayout", {
		Parent            = Built.Content,
		Padding           = UDim.new(0, 6),
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		Wraps             = true,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local function Render()
		for _, Cell in Cells do
			local On = Cell.Colour == Value
			Tween(Cell.Ring, { Transparency = On and 0 or 1 }, "hover")
			Tween(Cell.Frame, {
				Size = On and UDim2.new(0, 26, 0, 26) or UDim2.new(0, 22, 0, 22),
			}, "toss")
		end
	end
	for Index, Colour_ in Items do
		local Cell = New("Frame", {
			Parent           = Built.Content,
			BackgroundColor3 = Colour_,
			BorderSizePixel  = 0,
			Size             = UDim2.new(0, 22, 0, 22),
			LayoutOrder      = Index,
		}, {
			Corner(Round(Options, 11)),
		})
		Palette.Release(Cell)
		local Ring = Stroke(Theme.White, 1, 2)
		Ring.Parent = Cell
		local Button = New("TextButton", {
			Parent                 = Cell,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 3,
		})
		Cells[Index] = { Frame = Cell, Ring = Ring, Colour = Colour_ }
		Button.Activated:Connect(function()
			if Handle:IsDisabled() then
				return
			end
			Handle:Set(Colour_)
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Gradient(Container, Options)
	local Handle = {}
	local From = Options.From or Color3.fromRGB(255, 255, 255)
	local To = Options.To or Color3.fromRGB(0, 0, 0)
	local Rotation = Options.Rotation or 0
	local Built = Block(Container, Options, Options.Height or 34)
	local Bar = New("Frame", {
		Parent           = Built.Content,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 1, 0),
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
	})
	Palette.Release(Bar)
	local Ramp = New("UIGradient", {
		Parent   = Bar,
		Rotation = Rotation,
		Color    = ColorSequence.new(From, To),
	})
	function Handle:Get()
		return From, To, Rotation
	end
	function Handle:Set(NewFrom, NewTo, NewRotation)
		From = NewFrom or From
		To = NewTo or To
		Rotation = NewRotation or Rotation
		Ramp.Color = ColorSequence.new(From, To)
		Ramp.Rotation = Rotation
		if Options.Callback then
			task.spawn(Options.Callback, From, To, Rotation)
		end
		return Handle
	end
	return BlockHandle(Built, Handle, Options)
end
return Controls
end
KuikModules["Controls/Content"] = function()
local GuiService = game:GetService("GuiService")
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Shared  = KuikRequire("Shared")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Hex     = Util.Hex
local Round   = Util.Round
local Colour  = Util.Colour
local Tween      = Motion.Tween
local Enter      = Motion.Enter
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Row         = Parts.Row
local Block       = Parts.Block
local Common      = Parts.Common
local BlockHandle = Parts.BlockHandle
local Controls = {}
local function Face(Parent, Options, Width, Height)
	local Variant = Options.Variant or "Pill"
	local Accent = Colour(Options, Variant == "Pill" and Theme.White or Theme.Accent)
	local Label = Options.Action or Options.Text or "Run"
	local Frame = New("Frame", {
		Name                   = "Face",
		Parent                 = Parent,
		BackgroundColor3       = Accent,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = Width and UDim2.new(0, Width, 0, Height or Metrics.TabHeight)
			or UDim2.new(1, 0, 0, Height or Metrics.TabHeight),
	}, {
		Corner(Round(Options, math.floor((Height or Metrics.TabHeight) / 2))),
	})
	local Ink = New("TextLabel", {
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Text                   = Label,
		TextColor3             = Theme.White,
		FontFace               = Theme.FontMedium,
		TextSize               = Options.TextSize or (Metrics.ValueSize),
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextYAlignment         = Enum.TextYAlignment.Center,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		RichText               = true,
		Size                   = UDim2.new(1, -12, 1, 0),
		Position               = UDim2.new(0, 6, 0, 0),
		ZIndex                 = 2,
	})
	local Ring = nil
	local Brackets = nil
	if Variant == "Outline" then
		Ring = Stroke(Accent, 0.55, 1)
		Ring.Parent = Frame
	elseif Variant == "Rule" then
		Brackets = {}
		for Index = 1, 2 do
			Brackets[Index] = New("Frame", {
				Name                   = Index == 1 and "Left" or "Right",
				Parent                 = Frame,
				BackgroundColor3       = Accent,
				BackgroundTransparency = Theme.RuleTransparency,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(Index - 1, 0.5),
				Position               = UDim2.new(Index - 1, 0, 0.5, 0),
				Size                   = UDim2.new(0, 1, 1, 0),
				ZIndex                 = 3,
			})
		end
	end
	local Levels = {
		Pill    = { 0, 0.18, 0.42 },
		Solid   = { 0.12, 0, 0.35 },
		Outline = { 1, 0.9, 0.82 },
		Ghost   = { 1, 0.92, 0.86 },
		Text    = { 1, 1, 1 },
		Rule    = { 1, 0.94, 0.88 },
	}
	local Level = Levels[Variant] or Levels.Pill
	local OnLight = Variant == "Pill" or Variant == "Solid"
	Ink.TextColor3 = OnLight and Theme.Black or Accent
	if Variant == "Text" then
		Ink.Text = string.format('<u>%s</u>', Label)
		Ink.TextColor3 = Accent
	end
	local function Paint(State)
		local Index = State == "press" and 3 or State == "hover" and 2 or 1
		Tween(Frame, { BackgroundTransparency = Level[Index] },
			State == "press" and "press" or "hover")
		if Brackets then
			for _, Bracket in Brackets do
				Tween(Bracket, {
					BackgroundTransparency = Index == 1 and Theme.RuleTransparency or 0,
				}, "hover")
			end
		end
		if Ring then
			Tween(Ring, { Transparency = Index == 1 and 0.55 or 0.25 }, "hover")
		end
		if not OnLight then
			Tween(Ink, { TextTransparency = Index == 1 and 0 or 0 }, "hover")
		end
	end
	Frame.BackgroundTransparency = Level[1]
	return Frame, Ink, Paint, Accent
end
function Controls.Button(Container, Options)
	local Handle = {}
	local Full = Options.Full == true or Options.Variant == "Bar"
	local Width = Options.Width or 80
	local Built = Row(Container, Util.Merge(Options, {
		Reserve = Full and 0 or Width,
		Gap = Full and 10 or 8,
	}))
	local Slot = Full and Built:Foot(Options.Height or Metrics.TabHeight) or Built:Reserve(Width)
	local Merged = Options
	if Options.Variant == "Bar" then
		Merged = Util.Merge(Options, { Variant = "Rule" })
	end
	local Frame, Ink, Paint = Face(Slot, Merged,
		not Full and Width or nil, Options.Height)
	if Full then
		Frame.AnchorPoint = Vector2.new(0, 0)
		Frame.Position = UDim2.new(0, 0, 0, 0)
	end
	local Button = New("TextButton", {
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 4,
	})
	Button.MouseEnter:Connect(function()
		if not Handle:IsDisabled() then
			Paint("hover")
		end
	end)
	Button.MouseLeave:Connect(function()
		Paint("rest")
	end)
	Button.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		Paint("press")
		task.delay(MotionTime("press"), function()
			Paint("rest")
		end)
		if Options.Callback then
			task.spawn(Options.Callback, Handle)
		end
	end)
	function Handle:SetAction(NewText)
		SwapText(Ink, NewText)
		return Handle
	end
	function Handle:Press()
		if Options.Callback then
			task.spawn(Options.Callback, Handle)
		end
		return Handle
	end
	Handle.Face = Frame
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
		Dim = { Ink },
	})
end
function Controls.Rule(Container, Options)
	local Handle = {}
	local Frame = New("Frame", {
		Name                   = "RuleButton",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 34),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, Metrics.RowPadding),
	})
	local Face_, Ink, Paint = Face(Frame, Util.Merge(Options, {
		Variant = Options.Variant or "Rule",
		Action = Options.Action or Options.Label or "Continue",
	}), nil, Options.Height or 34)
	Face_.AnchorPoint = Vector2.new(0, 0)
	Face_.Position = UDim2.new(0, 0, 0, 0)
	local Button = New("TextButton", {
		Parent                 = Face_,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 4,
	})
	Button.MouseEnter:Connect(function()
		if not Handle:IsDisabled() then
			Paint("hover")
		end
	end)
	Button.MouseLeave:Connect(function()
		Paint("rest")
	end)
	Button.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		Paint("press")
		task.delay(MotionTime("press"), function()
			Paint("rest")
		end)
		if Options.Callback then
			task.spawn(Options.Callback, Handle)
		end
	end)
	function Handle:SetAction(NewText)
		SwapText(Ink, NewText)
		return Handle
	end
	Handle.Face = Face_
	return Common(Handle, Frame, Options, { Inputs = { Button }, Dim = { Ink } })
end
function Controls.Divider(Container, Options)
	Options = Options or {}
	local Handle = {}
	local Clickable = Options.Callback ~= nil
	local Frame = New("Frame", {
		Name                   = "Divider",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Label and 22 or (Options.Height or 13)),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, Metrics.RowPadding),
	})
	local Accent = Colour(Options, Theme.White)
	local Lines = {}
	local function Line(Order)
		local Bar = New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Accent,
			BackgroundTransparency = Options.Transparency or Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, Options.Thickness or 1),
			LayoutOrder            = Order,
		})
		table.insert(Lines, Bar)
		return Bar
	end
	local Label = nil
	if not Options.Label then
		local Bar = Line(1)
		Bar.AnchorPoint = Vector2.new(0, 0.5)
		Bar.Position = UDim2.new(0, 0, 0.5, 0)
	else
		Strip(10).Parent = Frame
		local Left = Line(1)
		Left.Size = UDim2.new(0, Options.Inset or 12, 0, Options.Thickness or 1)
		Label = Text({
			Parent           = Frame,
			Text             = Options.Label,
			TextSize         = Options.TextSize or Metrics.CaptionSize,
			TextTransparency = Theme.TextTertiary,
			AutomaticSize    = Enum.AutomaticSize.X,
			Size             = UDim2.new(0, 0, 0, 14),
			LayoutOrder      = 2,
		})
		local Right = Line(3)
		Right.Size = UDim2.new(0, 0, 0, Options.Thickness or 1)
		New("UIFlexItem", {
			Parent   = Right,
			FlexMode = Enum.UIFlexMode.Fill,
		})
	end
	if Clickable then
		local Button = New("TextButton", {
			Parent                 = Frame,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 4,
		})
		local function Light(On)
			for _, Bar in Lines do
				Tween(Bar, { BackgroundTransparency = On and 0 or Theme.RuleTransparency }, "hover")
			end
			if Label then
				Tween(Label, {
					TextTransparency = On and Theme.TextPrimary or Theme.TextTertiary,
				}, "hover")
			end
		end
		Button.MouseEnter:Connect(function() Light(true) end)
		Button.MouseLeave:Connect(function() Light(false) end)
		Button.Activated:Connect(function()
			if not Handle:IsDisabled() then
				task.spawn(Options.Callback, Handle)
			end
		end)
	end
	if Label then
		function Handle:SetLabel(NewText)
			SwapText(Label, NewText)
			return Handle
		end
	end
	return Common(Handle, Frame, Options, {})
end
function Controls.Gap(Container, Options)
	Options = Options or {}
	local Frame = New("Frame", {
		Name                   = "Gap",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 12),
		LayoutOrder            = Options.LayoutOrder or 0,
	})
	return Common({}, Frame, Options, {})
end
function Controls.Paragraph(Container, Options)
	local Handle = {}
	local Frame = New("Frame", {
		Name                   = "Paragraph",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(2, Metrics.RowPadding, 6, Metrics.RowPadding),
		List(Options.Gap or 5),
	})
	if Options.Label then
		Text({
			Parent      = Frame,
			Text        = Options.Label,
			FontFace    = Theme.FontMedium,
			TextSize    = Options.LabelSize or (Metrics.SubheadSize),
			TextWrapped = true,
			LayoutOrder = 1,
		})
	end
	local Body = nil
	if Options.Text and Options.Text ~= "" then
		Body = Text({
			Parent           = Frame,
			Text             = Options.Text,
			TextSize         = Options.TextSize or (Metrics.BodySize),
			TextTransparency = Options.Emphasis and Theme.TextPrimary or Theme.TextSecondary,
			TextXAlignment   = Options.Align == "Center" and Enum.TextXAlignment.Center
				or Options.Align == "Right" and Enum.TextXAlignment.Right
				or Enum.TextXAlignment.Left,
			TextWrapped      = true,
			LineHeight       = Options.LineHeight or 1,
			LayoutOrder      = 2,
		})
	end
	local Picture = nil
	if Options.Image then
		local Fill, Alpha = Util.Surface(Options, Theme.EmbedColor, Theme.EmbedTransparency)
		Picture = New("ImageLabel", {
			Parent                 = Frame,
			BackgroundColor3       = Fill,
			BackgroundTransparency = Options.ImageBackgroundTransparency or Alpha,
			BorderSizePixel        = 0,
			Image                  = Util.Asset(Options.Image),
			ImageTransparency      = 1,
			ImageColor3            = Options.ImageColor or Theme.White,
			ScaleType              = Util.ScaleType(Options.ImageScaleType or Options.Fit),
			Size                   = UDim2.new(1, 0,
				Options.ImageScaleHeight or 0,
				Options.ImageHeight or 110),
			LayoutOrder            = 3,
		}, Util.Radius(Options, Metrics.CardRadius) > 0
			and { Corner(Util.Radius(Options, Metrics.CardRadius)) }
			or nil)
		Tween(Picture, { ImageTransparency = Options.ImageTransparency or 0 }, "fade")
	end
	function Handle:Set(NewText)
		if Body then
			SwapText(Body, NewText)
		end
		return Handle
	end
	function Handle:SetImage(NewImage)
		if Picture then
			Picture.Image = Util.Asset(NewImage)
		end
		return Handle
	end
	function Handle:SetBackground(Fill, Alpha)
		if not Picture then
			return Handle
		end
		if Fill == false then
			Tween(Picture, { BackgroundTransparency = 1 }, "fade")
		else
			Picture.BackgroundColor3 = Fill or Theme.EmbedColor
			Tween(Picture, { BackgroundTransparency = Alpha or 0 }, "fade")
		end
		return Handle
	end
	Handle.Picture = Picture
	Handle.Body = Body
	return Common(Handle, Frame, Options, { Description = Body })
end
function Controls.Quote(Container, Options)
	local Handle = {}
	local Accent = Colour(Options, Theme.White)
	local Frame = New("Frame", {
		Name                   = "Quote",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(4, Metrics.RowPadding),
	})
	local Bar = New("Frame", {
		Name                   = "Bar",
		Parent                 = Frame,
		BackgroundColor3       = Accent,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, 2, 0, 0),
	})
	local Column = New("Frame", {
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 14, 0, 0),
		Size                   = UDim2.new(1, -14, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		List(4),
	})
	Parts.Span(Bar, Column, true)
	local Body = Text({
		Parent           = Column,
		Text             = Options.Text or "",
		TextSize         = Options.TextSize or Metrics.RowDescSize,
		TextTransparency = Theme.TextSecondary,
		TextWrapped      = true,
		LayoutOrder      = 1,
	})
	if Options.Author then
		Text({
			Parent           = Column,
			Text             = Options.Author,
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			LayoutOrder      = 2,
		})
	end
	function Handle:Set(NewText)
		SwapText(Body, NewText)
		return Handle
	end
	return Common(Handle, Frame, Options, {})
end
function Controls.Code(Container, Options)
	local Handle = {}
	local Source = Options.Text or ""
	local Built = Block(Container, Options)
	local Sheet = New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = select(2, Util.Surface(Options, Theme.EmbedColor, 0.35)),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(8, 10),
		List(1),
	})
	local Lines = {}
	local function Render()
		for _, Line in Lines do
			Line:Destroy()
		end
		table.clear(Lines)
		local Number = 0
		for Piece in string.gmatch(Source .. "\n", "(.-)\n") do
			Number += 1
			local Line = New("Frame", {
				Parent                 = Sheet,
				BackgroundTransparency = 1,
				Size                   = UDim2.new(1, 0, 0, 14),
				LayoutOrder            = Number,
			})
			if Options.Numbers ~= false then
				Text({
					Parent           = Line,
					Text             = tostring(Number),
					FontFace         = Theme.FontMono,
					TextSize         = Metrics.MonoSize,
					TextTransparency = Theme.TextDisabled,
					TextXAlignment   = Enum.TextXAlignment.Right,
					TextYAlignment   = Enum.TextYAlignment.Center,
					Size             = UDim2.new(0, 20, 1, 0),
					AutomaticSize    = Enum.AutomaticSize.None,
				})
			end
			Text({
				Parent           = Line,
				Text             = Piece,
				FontFace         = Theme.FontMono,
				TextSize         = Metrics.MonoBoldSize,
				TextTransparency = Theme.TextSecondary,
				TextYAlignment   = Enum.TextYAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Position         = UDim2.new(0, Options.Numbers == false and 0 or 28, 0, 0),
				Size             = UDim2.new(1, Options.Numbers == false and 0 or -28, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
			})
			table.insert(Lines, Line)
		end
	end
	function Handle:Get()
		return Source
	end
	function Handle:Set(NewSource)
		Source = NewSource
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Alert(Container, Options)
	local Handle = {}
	local Accent = Colour(Options, Theme.Info)
	local Variant = Options.Variant or "Accent"
	local Frame = New("Frame", {
		Name                   = "Alert",
		Parent                 = Container,
		BackgroundColor3       = Accent,
		BackgroundTransparency = Variant == "Solid" and 0.78 or 0.94,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Util.Radius(Options, Metrics.RowRadius)),
	})
	if Variant == "Outline" then
		Frame.BackgroundTransparency = 1
		Stroke(Accent, 0.55, 1).Parent = Frame
	end
	local Accented = nil
	if Variant ~= "Subtle" and Variant ~= "Outline" then
		Accented = New("Frame", {
			Name             = "Accent",
			Parent           = Frame,
			BackgroundColor3 = Accent,
			BorderSizePixel  = 0,
			Position         = UDim2.new(0, 0, 0, 0),
			Size             = UDim2.new(0, Options.Thickness or 2, 0, 0),
			ZIndex           = 2,
		})
	end
	local Column = New("Frame", {
		Name                   = "Column",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, Metrics.RowPadding, 0, 0),
		Size                   = UDim2.new(1, -(Metrics.RowPadding * 2), 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Padding(11, 0, 11, 0),
		List(3),
	})
	if Accented then
		Parts.Span(Accented, Column, true)
	end
	local Title = Text({
		Parent      = Column,
		Text        = Options.Label or "",
		FontFace    = Theme.FontMedium,
		TextSize    = Metrics.SubheadSize,
		TextColor3  = Accent,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	local Body = nil
	if Options.Text and Options.Text ~= "" then
		Body = Text({
			Parent           = Column,
			Text             = Options.Text,
			TextSize         = Metrics.BodySize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	if Options.Visible ~= false then
		Enter(Frame, "BackgroundTransparency", Frame.BackgroundTransparency, "fade")
	end
	function Handle:Set(NewTitle, NewText)
		if NewTitle then
			SwapText(Title, NewTitle)
		end
		if NewText and Body then
			SwapText(Body, NewText)
		end
		return Handle
	end
	function Handle:SetColor(NewColour, Animate)
		Accent = NewColour
		Motion.Paint(Title, { TextColor3 = NewColour }, Animate)
		Motion.Paint(Frame, { BackgroundColor3 = NewColour }, Animate)
		local Bar = Frame:FindFirstChild("Accent")
		if Bar then
			Motion.Paint(Bar, { BackgroundColor3 = NewColour }, Animate)
		end
		return Handle
	end
	function Handle:Pulse()
		local Rest = Frame.BackgroundTransparency
		Frame.BackgroundTransparency = math.max(0, Rest - 0.2)
		Tween(Frame, { BackgroundTransparency = Rest }, "fade")
		return Handle
	end
	return Common(Handle, Frame, Options, { Label = Title, Description = Body })
end
function Controls.Callout(Container, Options)
	return Controls.Alert(Container, Util.Merge(Options, {
		Label = Options.Label or Options.Text,
		Text = Options.Label and Options.Text or nil,
		Variant = Options.Variant or "Subtle",
	}))
end
function Controls.Accordion(Container, Options, Owner)
	local Handle = {}
	local Open = Options.Open == true
	local Frame = New("Frame", {
		Name                   = "Accordion",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
		ClipsDescendants       = true,
	}, {
		List(Metrics.RowGap),
	})
	local Header = New("TextButton", {
		Name                   = "Header",
		Parent                 = Frame,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RowTransparency,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = 1,
	}, {
		Corner(Util.Radius(Options, Metrics.RowRadius)),
		Padding(10, Metrics.RowPadding),
	})
	New("UISizeConstraint", {
		Parent  = Header,
		MinSize = Vector2.new(0, Options.Description and Metrics.RowHeightTall or Metrics.RowHeight),
	})
	Parts.Dress(Header, Options)
	local Column = New("Frame", {
		Parent                 = Header,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(1, -30, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		List(2),
	})
	local Title = Text({
		Parent      = Column,
		Text        = Options.Label or "",
		TextSize    = Metrics.RowLabelSize,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	local Detail = nil
	if Options.Description then
		Detail = Text({
			Parent           = Column,
			Text             = Options.Description,
			TextSize         = Metrics.RowDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	local Chevron, Arms = Util.Chevron(Header, 12, "Down")
	Chevron.AnchorPoint = Vector2.new(1, 0.5)
	Chevron.Position = UDim2.new(1, 0, 0.5, 0)
	local Shell = New("Frame", {
		Name                   = "Shell",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		ClipsDescendants       = true,
		LayoutOrder            = 2,
	})
	local Body = New("Frame", {
		Name                   = "Body",
		Parent                 = Shell,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		Visible                = Open,
	}, {
		Padding(0, 0, 12, 0),
		List(Metrics.RowGap),
	})
	local Order = 0
	local function Render(Animate)
		for Index, Arm in Arms do
			local Target = Open
				and (Index == 1 and -45 or 45)
				or (Index == 1 and 45 or -45)
			if Animate then
				Tween(Arm, { Rotation = Target }, "morph")
			else
				Arm.Rotation = Target
			end
		end
		if Open then
			Shell.AutomaticSize = Enum.AutomaticSize.None
			local Height = Body.AbsoluteSize.Y
			Body.Visible = true
			if not Animate or Height <= 0 then
				Shell.AutomaticSize = Enum.AutomaticSize.Y
				return
			end
			Shell.Size = UDim2.new(1, 0, 0, 0)
			Tween(Shell, { Size = UDim2.new(1, 0, 0, Height) }, "reveal")
			task.delay(MotionTime("expand"), function()
				if Open then
					Shell.AutomaticSize = Enum.AutomaticSize.Y
				end
			end)
		else
			Shell.AutomaticSize = Enum.AutomaticSize.None
			if Animate then
				Tween(Shell, { Size = UDim2.new(1, 0, 0, 0) }, "snap")
				task.delay(MotionTime("snap"), function()
					if not Open then
						Body.Visible = false
					end
				end)
			else
				Shell.Size = UDim2.new(1, 0, 0, 0)
				Body.Visible = false
			end
		end
	end
	local Button = Header
	Button.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		Open = not Open
		Render(true)
		if Options.Callback then
			task.spawn(Options.Callback, Open)
		end
	end)
	Header.MouseEnter:Connect(function()
		Tween(Header, { BackgroundTransparency = Theme.RowHoverTransparency }, "hover")
	end)
	Header.MouseLeave:Connect(function()
		Tween(Header, { BackgroundTransparency = Theme.RowTransparency }, "hover")
	end)
	function Handle:_Mount()
		return Body
	end
	function Handle:_Order()
		Order += 1
		return Order
	end
	function Handle:_Overlay()
		return Owner and Owner._Overlay and Owner:_Overlay() or nil
	end
	function Handle:_Register(Close)
		if Owner and Owner._Register then
			Owner:_Register(Close)
		end
	end
	function Handle:_Window()
		return Owner and Owner._Window and Owner:_Window() or nil
	end
	function Handle:IsOpen()
		return Open
	end
	function Handle:SetOpen(Value, Animate)
		Open = Value == true
		Render(Animate ~= false)
		return Handle
	end
	Render(false)
	Common(Handle, Frame, Options, {
		Label = Title,
		Description = Detail,
		Inputs = { Button },
	})
	return Shared.Attach(Handle)
end
function Controls.Breadcrumb(Container, Options)
	local Handle = {}
	local Path = Options.Path or {}
	local Frame = New("Frame", {
		Name                   = "Breadcrumb",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 24),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, Metrics.RowPadding),
		Strip(7),
	})
	local function Render()
		for _, Child in Frame:GetChildren() do
			if Child:IsA("GuiObject") then
				Child:Destroy()
			end
		end
		for Index, Part in Path do
			local Last = Index == #Path
			local Entry = New("TextButton", {
				Parent                 = Frame,
				BackgroundTransparency = 1,
				Text                   = tostring(Part),
				TextColor3             = Theme.White,
				TextTransparency       = Last and Theme.TextPrimary or Theme.TextSecondary,
				FontFace               = Last and Theme.FontMedium or Theme.Font,
				TextSize               = Metrics.ValueSize,
				AutoButtonColor        = false,
				AutomaticSize          = Enum.AutomaticSize.X,
				Size                   = UDim2.new(0, 0, 1, 0),
				LayoutOrder            = Index * 2,
			})
			Entry.Activated:Connect(function()
				if Options.Callback then
					task.spawn(Options.Callback, Part, Index)
				end
			end)
			if not Last then
				New("TextLabel", {
					Parent                 = Frame,
					BackgroundTransparency = 1,
					Text                   = Options.Separator or "/",
					TextColor3             = Theme.White,
					TextTransparency       = Theme.TextDisabled,
					FontFace               = Theme.FontMono,
					TextSize               = Metrics.MonoBoldSize,
					AutomaticSize          = Enum.AutomaticSize.X,
					Size                   = UDim2.new(0, 0, 1, 0),
					LayoutOrder            = Index * 2 + 1,
				})
			end
		end
	end
	function Handle:Get()
		return Path
	end
	function Handle:Set(NewPath)
		Path = NewPath
		Render()
		return Handle
	end
	function Handle:Push(Part)
		table.insert(Path, Part)
		Render()
		return Handle
	end
	Render()
	return Common(Handle, Frame, Options, {})
end
function Controls.Steps(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local At = Options.Default or 1
	local Marks = {}
	local Built = Block(Container, Options)
	List(2).Parent = Built.Content
	for Index, Item in Items do
		local Line = New("Frame", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 24),
			LayoutOrder            = Index,
		}, {
			Strip(10),
		})
		local Pip = New("Frame", {
			Parent                 = Line,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(0, 14, 0, 14),
			LayoutOrder            = 1,
		}, {
			Corner(7),
			Stroke(Theme.White, Theme.TextTertiary, 1),
		})
		local Number = Text({
			Parent           = Pip,
			Text             = tostring(Index),
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextXAlignment   = Enum.TextXAlignment.Center,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Size             = UDim2.new(1, 0, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		local Label = Text({
			Parent           = Line,
			Text             = tostring(Item),
			TextSize         = Metrics.ValueSize,
			TextTransparency = Theme.TextSecondary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			AutomaticSize    = Enum.AutomaticSize.X,
			Size             = UDim2.new(0, 0, 1, 0),
			LayoutOrder      = 2,
		})
		Marks[Index] = { Pip = Pip, Number = Number, Label = Label }
	end
	local function Render()
		for Index, Mark in Marks do
			local Done = Index < At
			local Here = Index == At
			Tween(Mark.Pip, { BackgroundTransparency = Done and 0 or 1 }, "item")
			Tween(Mark.Number, {
				TextColor3 = Done and Theme.Black or Theme.White,
				TextTransparency = Here and Theme.TextPrimary
					or Done and 0 or Theme.TextDisabled,
			}, "hover")
			Tween(Mark.Label, {
				TextTransparency = Here and Theme.TextPrimary
					or Done and Theme.TextSecondary or Theme.TextDisabled,
			}, "hover")
		end
	end
	function Handle:Get()
		return At
	end
	function Handle:Set(Index)
		At = Util.Clamp(Index, 1, math.max(1, #Items))
		Render()
		return Handle
	end
	function Handle:Next()
		return Handle:Set(At + 1)
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Avatar(Container, Options)
	local Handle = {}
	local Size = Options.Size or 30
	local Fill, Alpha = Util.Surface(Options, Theme.EmbedColor, 0.6)
	local Frame = New("TextButton", {
		Name                   = "Avatar",
		Parent                 = Container,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RowTransparency,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 0, Size + 22),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Util.Radius(Options, Metrics.RowRadius)),
		Padding(0, Metrics.RowPadding),
		Strip(11),
	})
	Parts.Dress(Frame, Options)
	local Image = Options.Image
	if not Image and Options.UserId then
		Image = Util.Headshot(Options.UserId, Size * 2)
	end
	local Portrait = New("ImageLabel", {
		Parent                 = Frame,
		BackgroundColor3       = Fill,
		BackgroundTransparency = Alpha,
		BorderSizePixel        = 0,
		Image                  = Util.Asset(Image),
		Size                   = UDim2.new(0, Size, 0, Size),
		LayoutOrder            = 1,
	}, {
		Corner(Options.Square and Util.Radius(Options, Metrics.ChipRadius) or math.floor(Size / 2)),
	})
	local Column = New("Frame", {
		Parent                 = Frame,
		BackgroundTransparency = 1,
		AutomaticSize          = Enum.AutomaticSize.Y,
		Size                   = UDim2.new(1, -(Size + 30), 0, 0),
		LayoutOrder            = 2,
	}, {
		List(1),
	})
	local Name = Text({
		Parent      = Column,
		Text        = Options.Label or "",
		TextSize    = Metrics.SubheadSize,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
	})
	local Detail = Text({
		Parent           = Column,
		Text             = Options.Description or "",
		TextSize         = Metrics.ValueSize,
		TextTransparency = Theme.TextSecondary,
		TextTruncate     = Enum.TextTruncate.AtEnd,
		LayoutOrder      = 2,
	})
	function Handle:Set(NewName, NewDetail)
		if NewName then
			SwapText(Name, NewName)
		end
		if NewDetail then
			SwapText(Detail, NewDetail)
		end
		return Handle
	end
	function Handle:SetImage(NewImage)
		Portrait.Image = Util.Asset(NewImage)
		return Handle
	end
	function Handle:SetUser(UserId)
		Portrait.Image = Util.Headshot(UserId, Size * 2)
		return Handle
	end
	if Options.Callback then
		Frame.Activated:Connect(function()
			task.spawn(Options.Callback, Handle)
		end)
	end
	Handle.Picture = Portrait
	return Common(Handle, Frame, Options, { Label = Name, Description = Detail })
end
function Controls.Link(Container, Options, Owner)
	local Handle = {}
	local Target = Options.Target
	local Url = Options.Url
	local Accent = Colour(Options, Theme.Info)
	local Built = Row(Container, Util.Merge(Options, { Reserve = 84 }))
	Built:Reserve(84)
	Built.Label.Text = string.format('<font color="%s"><u>%s</u></font>',
		Hex(Accent), Options.Label or Url or "Link")
	if not Options.Description and Built.Description then
		local Kind = Url and "Opens a link"
			or type(Target) == "string" and string.format("Goes to %s", Target)
			or type(Target) == "function" and "Runs an action"
			or type(Target) == "table" and (Target.Root and "Opens a window" or "Jumps to a setting")
			or nil
		if Kind then
			Built.Description.Text = Kind
		end
	end
	local Pill = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Accent,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 84, 0, Metrics.TabHeight - 4),
	}, {
		Corner(Round(Options, 13)),
		Padding(0, 10),
		Strip(6, Enum.HorizontalAlignment.Center),
	})
	New("TextLabel", {
		Parent                 = Pill,
		BackgroundTransparency = 1,
		Text                   = Options.Action or (Url and "Open" or "Go"),
		TextColor3             = Accent,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.ValueSize,
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 1, 0),
		LayoutOrder            = 1,
	})
	local Arrow = Util.Chevron(Pill, 8, "Right", 0)
	Arrow.LayoutOrder = 2
	local Button = Built.Frame
	Button.MouseEnter:Connect(function()
		Tween(Pill, { BackgroundTransparency = 0.66 }, "hover")
	end)
	Button.MouseLeave:Connect(function()
		Tween(Pill, { BackgroundTransparency = 0.82 }, "hover")
	end)
	local function Follow()
		local Window = Owner and Owner._Window and Owner:_Window()
		if type(Target) == "function" then
			task.spawn(Target)
			return "action"
		end
		if type(Target) == "string" then
			if Window and Window:GoTo(Target) then
				return "page"
			end
			return "missing"
		end
		if type(Target) == "table" then
			if Target.Root and Target.Open then
				Target:Open()
				return "window"
			end
			if Target.Frame and Window and Window:Reveal(Target) then
				return "element"
			end
		end
		if typeof(Target) == "Instance" and Window and Window:Reveal(Target) then
			return "element"
		end
		if Url then
			local Opened = pcall(function()
				GuiService:OpenBrowserWindow(Url)
			end)
			return Opened and "url" or "blocked"
		end
		return "missing"
	end
	function Handle:Get()
		return Target or Url
	end
	function Handle:Set(NewTarget)
		Target = NewTarget
		return Handle
	end
	function Handle:Follow()
		return Follow()
	end
	Button.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		Tween(Pill, { BackgroundTransparency = 0.45 }, "press")
		task.delay(MotionTime("press"), function()
			Tween(Pill, { BackgroundTransparency = 0.82 }, "hover")
		end)
		local Kind = Follow()
		if Options.Callback then
			task.spawn(Options.Callback, Kind, Target or Url)
		end
	end)
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
	})
end
function Controls.Toolbar(Container, Options)
	local Handle = {}
	local Frame = New("Frame", {
		Name                   = "Toolbar",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 26),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, Metrics.RowPadding),
		Strip(Options.Gap or 6,
			Options.Align == "Right" and Enum.HorizontalAlignment.Right
			or Options.Align == "Center" and Enum.HorizontalAlignment.Center
			or Enum.HorizontalAlignment.Left),
	})
	local Buttons = {}
	for Index, Item in Options.Items or {} do
		local Accent = Item.Color or Colour(Options, Theme.White)
		local Pill = New("TextButton", {
			Parent                 = Frame,
			BackgroundColor3       = Accent,
			BackgroundTransparency = 0.88,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			LayoutOrder            = Index,
		}, {
			Corner(Round(Options, 13)),
			Padding(0, 10),
		})
		local Label = New("TextLabel", {
			Parent                 = Pill,
			BackgroundTransparency = 1,
			Text                   = tostring(Item.Label or Item),
			TextColor3             = Accent,
			FontFace               = Theme.Font,
			TextSize               = Metrics.CaptionSize,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			ZIndex                 = 2,
		})
		local Button = Pill
		Button.MouseEnter:Connect(function()
			Tween(Pill, { BackgroundTransparency = 0.7 }, "hover")
		end)
		Button.MouseLeave:Connect(function()
			Tween(Pill, { BackgroundTransparency = 0.88 }, "hover")
		end)
		Button.Activated:Connect(function()
			if Item.Callback then
				task.spawn(Item.Callback, Item)
			elseif Options.Callback then
				task.spawn(Options.Callback, Item, Index)
			end
		end)
		Buttons[Index] = { Pill = Pill, Label = Label }
	end
	Handle.Buttons = Buttons
	return Common(Handle, Frame, Options, {})
end
function Controls.Header(Container, Options)
	local Handle = {}
	local Frame = New("Frame", {
		Name                   = "Header",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(Options.Top or 10, Metrics.RowPadding, 2, Metrics.RowPadding),
		List(4),
	})
	local Title = Text({
		Parent      = Frame,
		Text        = Options.Label or "",
		FontFace    = Theme.FontMedium,
		TextSize    = Options.TextSize or Metrics.SectionTitleSize,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	local Detail = nil
	if Options.Description then
		Detail = Text({
			Parent           = Frame,
			Text             = Options.Description,
			TextSize         = Metrics.SectionDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	if Options.Rule ~= false then
		New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 1),
			LayoutOrder            = 3,
		})
	end
	return Common(Handle, Frame, Options, { Label = Title, Description = Detail })
end
function Controls.Group(Container, Options, Owner)
	local Handle = {}
	local Frame = New("Frame", {
		Name                   = Options.Name or "Group",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		List(Options.Gap or Metrics.RowGap),
	})
	Parts.Dress(Frame, Util.Merge({ Variant = "Flat" }, Options))
	if Options.Variant and Options.Variant ~= "Flat" then
		Corner(Util.Radius(Options, Metrics.RowRadius)).Parent = Frame
		Padding(Options.Inset or 10, Options.Inset or 10).Parent = Frame
	end
	local Body = Frame
	if Options.Label then
		local Head = New("Frame", {
			Parent                 = Frame,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			LayoutOrder            = 0,
		}, {
			Padding(0, Metrics.RowPadding),
			List(2),
		})
		Text({
			Parent      = Head,
			Text        = Options.Label,
			FontFace    = Theme.FontMedium,
			TextSize    = Options.LabelSize or Metrics.RowLabelSize,
			TextWrapped = true,
			LayoutOrder = 1,
		})
		if Options.Description then
			Text({
				Parent           = Head,
				Text             = Options.Description,
				TextSize         = Metrics.ValueSize,
				TextTransparency = Theme.TextSecondary,
				TextWrapped      = true,
				LayoutOrder      = 2,
			})
		end
	end
	local Order = 0
	function Handle:_Mount()
		return Body
	end
	function Handle:_Order()
		Order += 1
		return Order
	end
	function Handle:_Overlay()
		return Owner and Owner._Overlay and Owner:_Overlay() or nil
	end
	function Handle:_Register(Close)
		if Owner and Owner._Register then
			Owner:_Register(Close)
		end
	end
	function Handle:_Window()
		return Owner and Owner._Window and Owner:_Window() or nil
	end
	Common(Handle, Frame, Options, {})
	return Shared.Attach(Handle)
end
function Controls.Columns(Container, Options, Owner)
	local Handle = {}
	local Count = Options.Count or 2
	local Gap = Options.Gap or 8
	local Frame = New("Frame", {
		Name                   = "Columns",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, Options.Inset or 0),
		New("UIListLayout", {
			Padding           = UDim.new(0, Gap),
			FillDirection     = Enum.FillDirection.Horizontal,
			SortOrder         = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
	})
	local Columns = {}
	local Weights = Options.Weights or {}
	local Total = 0
	for Index = 1, Count do
		Total += Weights[Index] or 1
	end
	for Index = 1, Count do
		local Share = (Weights[Index] or 1) / Total
		local Column = New("Frame", {
			Name                   = "Column" .. Index,
			Parent                 = Frame,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(Share, -Gap * (Count - 1) / Count, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			LayoutOrder            = Index,
		}, {
			List(Options.RowGap or Metrics.RowGap),
		})
		local Order = 0
		local Each = { Frame = Column }
		function Each:_Mount()
			return Column
		end
		function Each:_Order()
			Order += 1
			return Order
		end
		function Each:_Overlay()
			return Owner and Owner._Overlay and Owner:_Overlay() or nil
		end
		function Each:_Register(Close)
			if Owner and Owner._Register then
				Owner:_Register(Close)
			end
		end
		function Each:_Window()
			return Owner and Owner._Window and Owner:_Window() or nil
		end
		Columns[Index] = Shared.Attach(Each)
	end
	function Handle:Column(Index)
		return Columns[Index]
	end
	function Handle:Each()
		return Columns
	end
	return Common(Handle, Frame, Options, {})
end
return Controls
end
KuikModules["Controls/Data"] = function()
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Scroll  = KuikRequire("Scroll")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Clamp   = Util.Clamp
local Round   = Util.Round
local Colour  = Util.Colour
local FormatNumber = Util.FormatNumber
local Tween      = Motion.Tween
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Row         = Parts.Row
local Block       = Parts.Block
local Common      = Parts.Common
local BlockHandle = Parts.BlockHandle
local Layered     = Parts.Layered
local SlidingMark = Parts.SlidingMark
local Polyline    = Parts.Polyline
local ChartPoints = Parts.ChartPoints
local Extent      = Parts.Extent
local Controls = {}
function Controls.Status(Container, Options)
	local Handle = {}
	local Width = Options.Width or 170
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Value = Text({
		Parent           = Built.Mount,
		Text             = tostring(Options.Value or ""),
		FontFace         = Options.Mono == false and Theme.Font or Theme.FontMono,
		TextSize         = Options.Mono == false and Metrics.RowDescSize or Metrics.MonoBoldSize,
		TextColor3       = Options.ValueColor or Theme.White,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		TextTruncate     = Enum.TextTruncate.AtEnd,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	function Handle:Get()
		return Value.Text
	end
	function Handle:Set(NewValue, NewColour, Animate)
		SwapText(Value, tostring(NewValue))
		if NewColour then
			Motion.Paint(Value, { TextColor3 = NewColour }, Animate)
			Motion.Paint(Value, { TextTransparency = 0 }, Animate)
		end
		return Handle
	end
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end
function Controls.Stat(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Cells = {}
	local Built = Block(Container, Options, Options.Height or 52)
	Strip(Options.Gap or 10).Parent = Built.Content
	for Index, Item in Items do
		local Cell = New("Frame", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1 / #Items, -(Options.Gap or 10), 1, 0),
			LayoutOrder            = Index,
		}, {
			List(2),
		})
		local Number = Text({
			Parent       = Cell,
			Text         = tostring(Item.Value or "0"),
			FontFace     = Theme.FontMedium,
			TextColor3   = Item.Color or Colour(Options, Theme.White),
			TextSize     = Options.NumberSize or 22,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped  = false,
			Size          = UDim2.new(1, 0, 0, (Options.NumberSize or 22) + 4),
			AutomaticSize = Enum.AutomaticSize.None,
			LayoutOrder  = 1,
		})
		local Caption = Text({
			Parent           = Cell,
			Text             = tostring(Item.Label or ""),
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			LayoutOrder      = 2,
		})
		if Options.Rules ~= false then
			New("Frame", {
				Parent                 = Cell,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.RuleTransparency,
				BorderSizePixel        = 0,
				Size                   = UDim2.new(1, 0, 0, 1),
				LayoutOrder            = 3,
			})
		end
		Cells[Index] = { Number = Number, Caption = Caption }
	end
	function Handle:Set(Index, Value, Colour_, Animate)
		local Cell = Cells[Index]
		if not Cell then
			return Handle
		end
		SwapText(Cell.Number, tostring(Value))
		if Colour_ then
			Motion.Paint(Cell.Number, { TextColor3 = Colour_ }, Animate)
		end
		return Handle
	end
	return BlockHandle(Built, Handle, Options)
end
function Controls.Badge(Container, Options)
	local Handle = {}
	local Accent = Colour(Options, Theme.Neutral)
	local Built = Row(Container, Util.Merge(Options, { Reserve = 92 }))
	Built:Reserve(92)
	local Solid = Options.Variant == "Solid"
	local Pill = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Accent,
		BackgroundTransparency = Solid and 0 or 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 0, 20),
	}, {
		Corner(Round(Options, 10)),
		Padding(0, 9),
	})
	if Options.Variant == "Outline" then
		Pill.BackgroundTransparency = 1
		Stroke(Accent, 0.5, 1).Parent = Pill
	end
	local Label = New("TextLabel", {
		Parent                 = Pill,
		BackgroundTransparency = 1,
		Text                   = Options.Text or "",
		TextColor3             = Solid and Theme.Black or Accent,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.CaptionSize,
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 1, 0),
	})
	function Handle:Set(NewText, NewColour, Animate)
		SwapText(Label, NewText)
		if NewColour then
			Motion.Paint(Label, { TextColor3 = Solid and Theme.Black or NewColour }, Animate)
			Motion.Paint(Pill, { BackgroundColor3 = NewColour }, Animate)
		end
		return Handle
	end
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end
function Controls.Progress(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0
	local Maximum = Options.Max or 1
	local Accent = Colour(Options, Theme.White)
	local Built = Row(Container, Util.Merge(Options, { Reserve = 70, Gap = 10 }))
	Built:Reserve(70)
	local Readout = Text({
		Parent           = Built.Mount,
		Text             = "",
		TextSize         = Metrics.RowDescSize,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Foot = Built:Foot(Options.Thickness or Metrics.SliderTrack)
	local Track = New("Frame", {
		Parent                 = Foot,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
	}, {
		Corner(2),
	})
	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Accent,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
	}, {
		Corner(2),
	})
	local Running = false
	local function Render(Animate)
		local Alpha = Maximum > 0 and Clamp(Value / Maximum, 0, 1) or 0
		Readout.Text = Options.Format and Options.Format(Value, Maximum)
			or string.format("%d%%", math.floor(Alpha * 100 + 0.5))
		if Animate == false then
			Fill.Size = UDim2.new(Alpha, 0, 1, 0)
		else
			Tween(Fill, { Size = UDim2.new(Alpha, 0, 1, 0) }, "snap")
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	function Handle:SetMax(NewMax)
		Maximum = NewMax
		Render()
		return Handle
	end
	function Handle:Indeterminate(On)
		Running = On ~= false
		if not Running then
			Render()
			return Handle
		end
		Readout.Text = ""
		Fill.Size = UDim2.new(0.3, 0, 1, 0)
		task.spawn(function()
			while Running and Fill.Parent do
				Tween(Fill, { Position = UDim2.new(0.7, 0, 0, 0) }, "layout")
				task.wait(0.55)
				Tween(Fill, { Position = UDim2.new(0, 0, 0, 0) }, "layout")
				task.wait(0.55)
			end
		end)
		return Handle
	end
	Render(false)
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Destroy = function()
			Running = false
		end,
	})
end
function Controls.Meter(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0
	local Maximum = Options.Max or 100
	local Segments = Options.Segments or 24
	local Accent = Colour(Options, Theme.White)
	local Built = Block(Container, Options, Options.Height or 18)
	local Bars = {}
	Strip(3).Parent = Built.Content
	for Index = 1, Segments do
		Bars[Index] = New("Frame", {
			Parent                 = Built.Content,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.85,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1 / Segments, -3, 1, 0),
			LayoutOrder            = Index,
		})
	end
	local function Render()
		local Alpha = Maximum > 0 and Clamp(Value / Maximum, 0, 1) or 0
		local Lit = math.floor(Alpha * Segments + 0.5)
		local Paint = Accent
		if Options.Danger and Alpha >= Options.Danger then
			Paint = Theme.Danger
		elseif Options.Warn and Alpha >= Options.Warn then
			Paint = Theme.Warn
		end
		for Index, Bar in Bars do
			local On = Index <= Lit
			Tween(Bar, {
				BackgroundColor3       = On and Paint or Theme.White,
				BackgroundTransparency = On and 0.05 or 0.85,
			}, "hover")
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue)
		Value = NewValue
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Ring(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0
	local Maximum = Options.Max or 1
	local Count = Options.Ticks or 36
	local Radius = Options.Radius_ or Options.Size or 26
	local Accent = Colour(Options, Theme.White)
	local Box = Radius * 2 + 6
	local Built = Row(Container, Util.Merge(Options, { Reserve = Box, MountHeight = Box }))
	Built:Reserve(Box)
	local Dial = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Box, 0, Box),
	})
	local Ticks = {}
	for Index = 1, Count do
		local Angle = (Index - 1) / Count * math.pi * 2 - math.pi / 2
		Ticks[Index] = New("Frame", {
			Parent                 = Dial,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.85,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, math.cos(Angle) * Radius, 0.5, math.sin(Angle) * Radius),
			Size                   = UDim2.new(0, 5, 0, 1),
			Rotation               = math.deg(Angle),
		})
	end
	local Readout = Text({
		Parent         = Dial,
		Text           = "",
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoLargeSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local function Render()
		local Alpha = Maximum > 0 and Clamp(Value / Maximum, 0, 1) or 0
		local Lit = math.floor(Alpha * Count + 0.5)
		SwapText(Readout, Options.Format and Options.Format(Value, Maximum)
			or string.format("%d%%", math.floor(Alpha * 100 + 0.5)))
		for Index, Tick in Ticks do
			Tween(Tick, {
				BackgroundColor3       = Index <= Lit and Accent or Theme.White,
				BackgroundTransparency = Index <= Lit and 0.05 or 0.85,
			}, "hover")
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue)
		Value = NewValue
		Render()
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end
function Controls.Spinner(Container, Options)
	local Handle = {}
	local Built = Row(Container, Util.Merge(Options, { Reserve = 18 }))
	Built:Reserve(18)
	local Ring = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 16, 0, 16),
	})
	local Dots = {}
	local Count = Options.Dots or 8
	for Index = 1, Count do
		local Angle = (Index - 1) / Count * math.pi * 2
		Dots[Index] = New("Frame", {
			Parent                 = Ring,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = 0.9,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, math.cos(Angle) * 7, 0.5, math.sin(Angle) * 7),
			Size                   = UDim2.new(0, 2, 0, 2),
		}, {
			Corner(1),
		})
	end
	local Running = true
	task.spawn(function()
		local Head = 0
		while Running and Ring.Parent do
			Head = Head % Count + 1
			for Index, Dot in Dots do
				local Distance = (Index - Head) % Count
				Dot.BackgroundTransparency = math.min(0.9, Distance / Count + 0.1)
			end
			task.wait(Options.Interval or 0.08)
		end
	end)
	function Handle:Stop()
		Running = false
		return Handle
	end
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Destroy = function()
			Running = false
		end,
	})
end
function Controls.Sparkline(Container, Options)
	local Handle = {}
	local Values = Options.Values or {}
	local Width = Options.Width or 120
	local Height = Options.Height or 22
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Canvas = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Height),
		ClipsDescendants       = true,
	})
	local Pool = {}
	local function Render()
		if #Values < 2 then
			Polyline(Canvas, Pool, {}, Theme.White, 1, 1)
			return
		end
		local Minimum, Maximum = Extent(Values, Options)
		Polyline(Canvas, Pool, ChartPoints(Values, Width, Height, Minimum, Maximum),
			Colour(Options, Theme.White), 0.15, Options.Thickness or 1)
	end
	function Handle:Get()
		return Values
	end
	function Handle:Set(NewValues)
		Values = NewValues
		Render()
		return Handle
	end
	function Handle:Push(Value, Limit)
		table.insert(Values, Value)
		while #Values > (Limit or Options.Limit or 40) do
			table.remove(Values, 1)
		end
		Render()
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end
function Controls.Graph(Container, Options)
	local Handle = {}
	local Values = Options.Values or {}
	local Height = Options.Height or 96
	local Built = Block(Container, Options, Height)
	local Canvas = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, Options.Axis == false and 0 or -34, 1, 0),
		ClipsDescendants       = true,
	})
	local High, Low = nil, nil
	if Options.Axis ~= false then
		local Axis = New("Frame", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(1, 0),
			Position               = UDim2.new(1, 0, 0, 0),
			Size                   = UDim2.new(0, 30, 1, 0),
		})
		High = Text({
			Parent           = Axis,
			Text             = "",
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextXAlignment   = Enum.TextXAlignment.Right,
			Size             = UDim2.new(1, 0, 0, 10),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		Low = Text({
			Parent           = Axis,
			Text             = "",
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextXAlignment   = Enum.TextXAlignment.Right,
			AnchorPoint      = Vector2.new(0, 1),
			Position         = UDim2.new(0, 0, 1, 0),
			Size             = UDim2.new(1, 0, 0, 10),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
	end
	for Index = 0, Options.Grid or 0 do
		New("Frame", {
			Parent                 = Canvas,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.9,
			BorderSizePixel        = 0,
			Position               = UDim2.new(0, 0, Index / math.max(1, Options.Grid or 1), 0),
			Size                   = UDim2.new(1, 0, 0, 1),
			ZIndex                 = 0,
		})
	end
	New("Frame", {
		Parent                 = Canvas,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, 0),
		Size                   = UDim2.new(1, 0, 0, 1),
		ZIndex                 = 0,
	})
	local Line = New("Frame", {
		Parent                 = Canvas,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	local Pool = {}
	local function Render()
		if #Values < 2 then
			Polyline(Line, Pool, {}, Theme.White, 1, 1)
			return
		end
		local Minimum, Maximum = Extent(Values, Options)
		if High then
			SwapText(High, FormatNumber(Maximum, Options.Step or 1))
			SwapText(Low, FormatNumber(Minimum, Options.Step or 1))
		end
		local Width = Canvas.AbsoluteSize.X
		if Width <= 0 then
			return
		end
		Polyline(Line, Pool, ChartPoints(Values, Width, Height, Minimum, Maximum),
			Colour(Options, Theme.White), 0.1, Options.Thickness or 1)
	end
	Canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(Render)
	function Handle:Get()
		return Values
	end
	function Handle:Set(NewValues)
		Values = NewValues
		Render()
		return Handle
	end
	function Handle:Push(Value, Limit)
		table.insert(Values, Value)
		while #Values > (Limit or Options.Limit or 60) do
			table.remove(Values, 1)
		end
		Render()
		return Handle
	end
	task.defer(Render)
	return BlockHandle(Built, Handle, Options)
end
function Controls.Bars(Container, Options)
	local Handle = {}
	local Values = Options.Values or {}
	local Height = Options.Height or 64
	local Bars = {}
	local Built = Block(Container, Options, Height)
	New("UIListLayout", {
		Parent            = Built.Content,
		Padding           = UDim.new(0, 3),
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	})
	local function Render()
		local Minimum, Maximum = Extent(Values, Options)
		local Range = Maximum - Minimum
		for Index, Value in Values do
			local Alpha = Range > 0 and (Value - Minimum) / Range or 0.5
			local Bar = Bars[Index]
			if not Bar then
				Bar = New("Frame", {
					Parent                 = Built.Content,
					BackgroundColor3       = Colour(Options, Theme.White),
					BackgroundTransparency = 1,
					BorderSizePixel        = 0,
					Size                   = UDim2.new(1 / #Values, -3, 0, 0),
					LayoutOrder            = Index,
				}, {
					Corner(Util.Radius(Options, 1)),
				})
				Bars[Index] = Bar
				Tween(Bar, { BackgroundTransparency = 0.15 }, "fade")
			end
			Tween(Bar, {
				Size = UDim2.new(1 / #Values, -3, 0, math.max(1, Alpha * Height)),
			}, "toss")
		end
		for Index = #Values + 1, #Bars do
			local Bar = Bars[Index]
			if Bar then
				Tween(Bar, { BackgroundTransparency = 1 }, "exit")
				task.delay(MotionTime("exit"), function()
					Bar:Destroy()
				end)
				Bars[Index] = nil
			end
		end
	end
	function Handle:Get()
		return Values
	end
	function Handle:Set(NewValues)
		Values = NewValues
		Render()
		return Handle
	end
	function Handle:Push(Value, Limit)
		table.insert(Values, Value)
		while #Values > (Limit or Options.Limit or 24) do
			table.remove(Values, 1)
		end
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Heatmap(Container, Options)
	local Handle = {}
	local Grid = Options.Values or {}
	local Cells = {}
	local Rows = #Grid
	local Columns = Rows > 0 and #Grid[1] or 0
	local Built = Block(Container, Options, Options.Height or (Rows * 14))
	New("UIGridLayout", {
		Parent      = Built.Content,
		CellSize    = UDim2.new(1 / math.max(Columns, 1), -2, 0, Options.Cell or 12),
		CellPadding = UDim2.new(0, 2, 0, 2),
		SortOrder   = Enum.SortOrder.LayoutOrder,
		FillDirectionMaxCells = Columns,
	})
	local function Render()
		local Low, High = math.huge, -math.huge
		for _, Line in Grid do
			for _, Value in Line do
				Low = math.min(Low, Value)
				High = math.max(High, Value)
			end
		end
		if Low == math.huge then
			Low, High = 0, 1
		end
		if Low == High then
			High = Low + 1
		end
		local Order = 0
		for Y, Line in Grid do
			for X, Value in Line do
				Order += 1
				local Alpha = (Value - Low) / (High - Low)
				local Cell = Cells[Order]
				if not Cell then
					Cell = New("Frame", {
						Parent                 = Built.Content,
						BackgroundColor3       = Colour(Options, Theme.White),
						BackgroundTransparency = 1,
						BorderSizePixel        = 0,
						LayoutOrder            = Order,
					}, {
						Corner(Util.Radius(Options, 1)),
					})
					Cells[Order] = Cell
				end
				Tween(Cell, { BackgroundTransparency = 1 - Alpha * 0.92 }, "fade")
			end
		end
	end
	function Handle:Set(NewGrid)
		Grid = NewGrid
		Rows = #Grid
		Columns = Rows > 0 and #Grid[1] or 0
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Rating(Container, Options)
	local Handle = {}
	local Count = Options.Count or 5
	local Value = Options.Default or 0
	local Bars = {}
	local Width = Count * 16
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Strip_ = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, 16),
	}, {
		Strip(4),
	})
	local function Render()
		for Index, Bar in Bars do
			Tween(Bar, { Size = UDim2.new(0, 12, 0, Index <= Value and 14 or 8) }, "toss")
			Tween(Bar, { BackgroundTransparency = Index <= Value and 0 or 0.82 }, "hover")
		end
	end
	for Index = 1, Count do
		local Bar = New("Frame", {
			Parent                 = Strip_,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = 0.82,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(0, 12, 0, 8),
			LayoutOrder            = Index,
		}, {
			Corner(1),
		})
		local Button = New("TextButton", {
			Parent                 = Bar,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 4, 1, 6),
			Position               = UDim2.new(0, -2, 0, -3),
			ZIndex                 = 3,
		})
		Bars[Index] = Bar
		Button.Activated:Connect(function()
			if Handle:IsDisabled() or Options.ReadOnly then
				return
			end
			Handle:Set(Index == Value and 0 or Index)
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = Clamp(NewValue, 0, Count)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end
function Controls.Pagination(Container, Options)
	local Handle = {}
	local Page = Options.Default or 1
	local Pages = Options.Pages or 1
	local Built = Row(Container, Util.Merge(Options, { Reserve = 110 }))
	Built:Reserve(110)
	Strip(8, Enum.HorizontalAlignment.Right).Parent = Built.Mount
	local function Arrow(Order, Direction)
		local Button = New("TextButton", {
			Parent                 = Built.Mount,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(0, 18, 0, 18),
			LayoutOrder            = Order,
		})
		Util.Chevron(Button, 14, Direction < 0 and "Left" or "Right")
		return Button
	end
	local Previous = Arrow(1, 1)
	local Readout = New("TextLabel", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		Text                   = "",
		TextColor3             = Theme.White,
		FontFace               = Theme.FontMono,
		TextSize               = Metrics.MonoBoldSize,
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 1, 0),
		LayoutOrder            = 2,
	})
	local Next = Arrow(3, -1)
	local function Render()
		SwapText(Readout, string.format("%d / %d", Page, Pages))
	end
	function Handle:Get()
		return Page
	end
	function Handle:Set(NewPage, Silent)
		Page = Clamp(math.floor(NewPage), 1, math.max(1, Pages))
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Page)
		end
		return Handle
	end
	function Handle:SetPages(Count)
		Pages = math.max(1, Count)
		Page = Clamp(Page, 1, Pages)
		Render()
		return Handle
	end
	Previous.Activated:Connect(function() Handle:Set(Page - 1) end)
	Next.Activated:Connect(function() Handle:Set(Page + 1) end)
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Previous, Next },
	})
end
function Controls.List(Container, Options)
	local Handle = {}
	local Value = Options.Default
	local Entries = {}
	local Items = Options.Items or {}
	local Built = Block(Container, Options, Options.Height or 132)
	local Sheet = New("ScrollingFrame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.Y,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.Y,
		ClipsDescendants       = true,
	})
	local Canvas, Rows = Layered(Sheet, 1)
	local Scroller = Scroll.Attach(Sheet, "Y")
	local Mark = SlidingMark(Canvas, { Color = Options.Color })
	local function Render()
		local Chosen = nil
		for Item, Bits in Entries do
			local On = Item == Value
			if On then
				Chosen = Bits.Entry
			end
			Tween(Bits.Label, {
				TextTransparency = On and Theme.TextPrimary or Theme.TextSecondary,
			}, "hover")
		end
		Mark:To(Chosen, Canvas)
	end
	local function Build()
		for _, Bits in Entries do
			Bits.Entry:Destroy()
		end
		table.clear(Entries)
		for Index, Item in Items do
			local Entry = New("TextButton", {
				Parent                 = Rows,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 0, Options.EntryHeight or 24),
				LayoutOrder            = Index,
			})
			local Label = Text({
				Parent           = Entry,
				Text             = tostring(Item),
				TextSize         = Metrics.ValueSize,
				TextTransparency = Theme.TextSecondary,
				TextYAlignment   = Enum.TextYAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Position         = UDim2.new(0, 10, 0, 0),
				Size             = UDim2.new(1, -14, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
			})
			Entries[Item] = { Entry = Entry, Label = Label }
			Entry.MouseEnter:Connect(function()
				Tween(Entry, { BackgroundTransparency = 0.94 }, "hover")
			end)
			Entry.MouseLeave:Connect(function()
				Tween(Entry, { BackgroundTransparency = 1 }, "hover")
			end)
			Entry.Activated:Connect(function()
				if Handle:IsDisabled() then
					return
				end
				Handle:Set(Item)
			end)
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	function Handle:SetItems(NewItems)
		Items = NewItems or {}
		Build()
		Render()
		return Handle
	end
	Build()
	Render()
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		Scroller:Destroy()
	end)
	return Result
end
function Controls.Table(Container, Options)
	local Handle = {}
	local Columns = Options.Columns or {}
	local Rows = Options.Rows or {}
	local Built = Block(Container, Options)
	List(2).Parent = Built.Content
	local Body = {}
	local Sort = { Column = nil, Descending = false }
	local function MakeRow(Cells, Header, Order)
		local Line = New("Frame", {
			Parent                 = Built.Content,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, Header and 18 or (Options.RowHeight or 20)),
			LayoutOrder            = Order,
		}, {
			Strip(0),
		})
		for Index, Column in Columns do
			local Content = Cells[Index]
			local Cell = Text({
				Parent           = Line,
				Text             = Content == nil and "" or tostring(Content),
				FontFace         = Header and Theme.Font or Theme.FontMono,
				TextSize         = Header and (Metrics.CaptionSize) or Metrics.MonoBoldSize,
				TextTransparency = Header and Theme.TextTertiary or Theme.TextSecondary,
				TextXAlignment   = Column.Align == "Right" and Enum.TextXAlignment.Right
					or Column.Align == "Center" and Enum.TextXAlignment.Center
					or Enum.TextXAlignment.Left,
				TextYAlignment   = Enum.TextYAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Size             = UDim2.new(Column.Width or (1 / #Columns), -6, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
				LayoutOrder      = Index,
			})
			if Header and Options.Sortable then
				local Button = New("TextButton", {
					Parent                 = Cell,
					BackgroundTransparency = 1,
					Text                   = "",
					AutoButtonColor        = false,
					Size                   = UDim2.new(1, 0, 1, 0),
					ZIndex                 = 3,
				})
				Button.Activated:Connect(function()
					Sort.Descending = Sort.Column == Index and not Sort.Descending or false
					Sort.Column = Index
					table.sort(Rows, function(A, B)
						local Left, Right = A[Index], B[Index]
						if type(Left) == "number" and type(Right) == "number" then
							if Sort.Descending then
								return Left > Right
							end
							return Left < Right
						end
						if Sort.Descending then
							return tostring(Left) > tostring(Right)
						end
						return tostring(Left) < tostring(Right)
					end)
					Handle:Set(Rows)
				end)
			end
		end
		if not Header and Options.Callback then
			local Button = New("TextButton", {
				Parent                 = Line,
				BackgroundTransparency = 1,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 1, 0),
				ZIndex                 = 3,
			})
			Line.MouseEnter:Connect(function()
				Tween(Line, { BackgroundTransparency = 0.94 }, "hover")
			end)
			Line.MouseLeave:Connect(function()
				Tween(Line, { BackgroundTransparency = 1 }, "hover")
			end)
			Button.Activated:Connect(function()
				task.spawn(Options.Callback, Cells, Order - 2)
			end)
		end
		return Line
	end
	local function Render()
		for _, Line in Body do
			Line:Destroy()
		end
		table.clear(Body)
		for Index, Line in Rows do
			table.insert(Body, MakeRow(Line, false, Index + 2))
		end
	end
	local Names = {}
	for Index, Column in Columns do
		Names[Index] = Column.Label or Column[1] or ""
	end
	MakeRow(Names, true, 1)
	New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 1),
		LayoutOrder            = 2,
	})
	function Handle:Get()
		return Rows
	end
	function Handle:Set(NewRows)
		Rows = NewRows
		Render()
		return Handle
	end
	function Handle:Push(Line, Limit)
		table.insert(Rows, Line)
		while Limit and #Rows > Limit do
			table.remove(Rows, 1)
		end
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Tree(Container, Options)
	local Handle = {}
	local Selected = nil
	local Rows = {}
	local Built = Block(Container, Options)
	local Canvas, Lines = Layered(Built.Content, 1)
	local Order = 0
	local Mark = SlidingMark(Canvas, { Color = Options.Color })
	local function Render()
		local Chosen = nil
		for _, Record in Rows do
			local On = Record.Node == Selected
			if On and Record.Entry.Visible then
				Chosen = Record.Entry
			end
			Tween(Record.Label, {
				TextTransparency = On and Theme.TextPrimary or Theme.TextSecondary,
			}, "hover")
		end
		Mark:To(Chosen, Canvas)
	end
	local function Build(Nodes, Depth, Parent)
		for _, Node in Nodes do
			Order += 1
			local Children = Node.Children or {}
			local Open = Node.Open == true
			local Entry = New("TextButton", {
				Parent                 = Lines,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 0, Options.EntryHeight or 22),
				LayoutOrder            = Order,
				Visible                = Parent == nil or Parent.Expanded,
			})
			local Indent = 10 + Depth * 14
			local Twist, Arms = nil, nil
			if #Children > 0 then
				Twist, Arms = Util.Chevron(Entry, 9, Open and "Down" or "Right", Theme.TextTertiary)
				Twist.AnchorPoint = Vector2.new(0, 0.5)
				Twist.Position = UDim2.new(0, Indent - 9, 0.5, 0)
			end
			local Label = Text({
				Parent           = Entry,
				Text             = tostring(Node.Label or ""),
				TextSize         = Metrics.ValueSize,
				TextTransparency = Theme.TextSecondary,
				TextYAlignment   = Enum.TextYAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Position         = UDim2.new(0, Indent + 4, 0, 0),
				Size             = UDim2.new(1, -(Indent + 8), 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
			})
			local Record = {
				Node     = Node,
				Entry    = Entry,
				Label    = Label,
				Arms     = Arms,
				Expanded = Open,
				Kids     = {},
				Parent   = Parent,
			}
			table.insert(Rows, Record)
			if Parent then
				table.insert(Parent.Kids, Record)
			end
			Entry.MouseEnter:Connect(function()
				Tween(Entry, { BackgroundTransparency = 0.94 }, "hover")
			end)
			Entry.MouseLeave:Connect(function()
				Tween(Entry, { BackgroundTransparency = 1 }, "hover")
			end)
			Entry.Activated:Connect(function()
				if #Children > 0 then
					Record.Expanded = not Record.Expanded
					if Arms then
						for Index, Arm in Arms do
							Tween(Arm, {
								Rotation = Record.Expanded
									and (Index == 1 and -45 or 45)
									or (Index == 1 and 45 or -45),
							}, "morph")
						end
					end
					local function Apply(Node_, Visible)
						for _, Kid in Node_.Kids do
							Kid.Entry.Visible = Visible
							Apply(Kid, Visible and Kid.Expanded)
						end
					end
					Apply(Record, Record.Expanded)
				end
				Selected = Node
				Render()
				if Options.Callback then
					task.spawn(Options.Callback, Node)
				end
			end)
			Build(Children, Depth + 1, Record)
		end
	end
	Build(Options.Nodes or {}, 0, nil)
	function Handle:Get()
		return Selected
	end
	function Handle:Set(Node)
		Selected = Node
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Timeline(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Built = Block(Container, Options)
	List(0).Parent = Built.Content
	local function Render()
		for _, Child in Built.Content:GetChildren() do
			if Child:IsA("GuiObject") then
				Child:Destroy()
			end
		end
		for Index, Item in Items do
			local Entry = New("Frame", {
				Parent                 = Built.Content,
				BackgroundTransparency = 1,
				Size                   = UDim2.new(1, 0, 0, 0),
				AutomaticSize          = Enum.AutomaticSize.Y,
				LayoutOrder            = Index,
			}, {
				Padding(0, 0, 10, 0),
			})
			local Line = nil
			if Index < #Items then
				Line = New("Frame", {
					Parent                 = Entry,
					BackgroundColor3       = Theme.White,
					BackgroundTransparency = 0.8,
					BorderSizePixel        = 0,
					Position               = UDim2.new(0, 5, 0, 12),
					Size                   = UDim2.new(0, 1, 0, 0),
				})
			end
			New("Frame", {
				Parent           = Entry,
				BackgroundColor3 = Item.Color or Colour(Options, Theme.White),
				BorderSizePixel  = 0,
				Position         = UDim2.new(0, 2, 0, 6),
				Size             = UDim2.new(0, 7, 0, 7),
			}, {
				Corner(4),
			})
			local Column = New("Frame", {
				Parent                 = Entry,
				BackgroundTransparency = 1,
				Position               = UDim2.new(0, 20, 0, 0),
				Size                   = UDim2.new(1, -20, 0, 0),
				AutomaticSize          = Enum.AutomaticSize.Y,
			}, {
				List(2),
			})
			if Line then
				Parts.Span(Line, Column, true, 2)
			end
			Text({
				Parent      = Column,
				Text        = tostring(Item.Label or ""),
				TextSize    = Metrics.BodySize,
				TextWrapped = true,
				LayoutOrder = 1,
			})
			if Item.Text then
				Text({
					Parent           = Column,
					Text             = Item.Text,
					TextSize         = Metrics.CaptionSize,
					TextTransparency = Theme.TextSecondary,
					TextWrapped      = true,
					LayoutOrder      = 2,
				})
			end
			if Item.Time then
				Text({
					Parent           = Column,
					Text             = tostring(Item.Time),
					FontFace         = Theme.FontMono,
					TextSize         = Metrics.MonoSize,
					TextTransparency = Theme.TextTertiary,
					LayoutOrder      = 3,
				})
			end
		end
	end
	function Handle:Set(NewItems)
		Items = NewItems
		Render()
		return Handle
	end
	function Handle:Push(Item)
		table.insert(Items, Item)
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Donut(Container, Options)
	local Handle = {}
	local Parts_ = Options.Items or {}
	local Size = Options.Size or 96
	local Thickness = Options.Thickness or 8
	local Wedges = {}
	local Built = Block(Container, Options, math.max(Size, #Parts_ * 18 + 8))
	local Face = New("Frame", {
		Name                   = "Donut",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, Size, 0, Size),
	})
	New("Frame", {
		Name                   = "Track",
		Parent                 = Face,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
	}, {
		Corner(math.floor(Size / 2)),
		Stroke(Theme.White, 0.9, Thickness),
	})
	local Segments = {}
	local function Arc(From, To, Tint, Alpha)
		local Steps = math.max(2, math.ceil(math.abs(To - From) / 0.14))
		for Step = 0, Steps do
			local Turn = From + (To - From) * (Step / Steps)
			local Radius = (Size - Thickness) / 2
			local X = math.cos(Turn) * Radius
			local Y = math.sin(Turn) * Radius
			local Key = #Segments + 1
			local Dot = Segments[Key]
			if not Dot or not Dot.Parent then
				Dot = New("Frame", {
					Name                   = "Arc",
					Parent                 = Face,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(0.5, 0.5),
				}, {
					Corner(math.floor(Thickness / 2)),
				})
				Segments[Key] = Dot
			end
			Dot.BackgroundColor3 = Tint
			Dot.BackgroundTransparency = Alpha or 0
			Dot.Position = UDim2.new(0.5, X, 0.5, Y)
			Dot.Size = UDim2.new(0, Thickness, 0, Thickness)
			Dot.Visible = true
		end
	end
	local Legend = New("Frame", {
		Name                   = "Legend",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.new(1, 0, 0, 0),
		Size                   = UDim2.new(1, -(Size + 16), 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		List(4),
	})
	local Middle = Text({
		Parent         = Face,
		Text           = Options.Text or "",
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoLargeSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AnchorPoint    = Vector2.new(0.5, 0.5),
		Position       = UDim2.new(0.5, 0, 0.5, 0),
		Size           = UDim2.new(0, Size - Thickness * 3, 0, 30),
		AutomaticSize  = Enum.AutomaticSize.None,
		ZIndex         = 3,
	})
	local function Render()
		local Total = 0
		for _, Part in Parts_ do
			Total += math.max(0, Part.Value or 0)
		end
		Total = math.max(Total, Options.Total or 0)
		for _, Dot in Segments do
			Dot.Visible = false
		end
		local Used = 0
		local Turn = -math.pi / 2
		for Index, Part in Parts_ do
			local Share = Total > 0 and math.max(0, Part.Value or 0) / Total or 0
			local Sweep = Share * math.pi * 2
			if Sweep > 0.001 then
				Arc(Turn, Turn + Sweep, Part.Color or Colour(Options, Theme.White))
			end
			Turn += Sweep
			Used += Share
			local Row = Wedges[Index]
			if not Row then
				local Line = New("Frame", {
					Name                   = "Part",
					Parent                 = Legend,
					BackgroundTransparency = 1,
					Size                   = UDim2.new(1, 0, 0, 14),
					LayoutOrder            = Index,
				}, {
					Strip(6),
				})
				local Chip = New("Frame", {
					Parent                 = Line,
					BorderSizePixel        = 0,
					Size                   = UDim2.new(0, 6, 0, 6),
					LayoutOrder            = 1,
				}, {
					Corner(Round(Options, 3)),
				})
				local Name_ = Text({
					Parent         = Line,
					Text           = "",
					TextSize       = Metrics.CaptionSize,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate   = Enum.TextTruncate.AtEnd,
					AutomaticSize  = Enum.AutomaticSize.X,
					Size           = UDim2.new(0, 0, 1, 0),
					LayoutOrder    = 2,
				})
				local Amount = Text({
					Parent           = Line,
					Text             = "",
					FontFace         = Theme.FontMono,
					TextSize         = Metrics.MonoSize,
					TextTransparency = Theme.TextTertiary,
					TextXAlignment   = Enum.TextXAlignment.Right,
					TextYAlignment   = Enum.TextYAlignment.Center,
					AnchorPoint      = Vector2.new(1, 0),
					Position         = UDim2.new(1, 0, 0, 0),
					Size             = UDim2.new(0, 54, 1, 0),
					AutomaticSize    = Enum.AutomaticSize.None,
				})
				Row = { Frame = Line, Chip = Chip, Name = Name_, Amount = Amount }
				Wedges[Index] = Row
			end
			Row.Frame.Visible = true
			Row.Chip.BackgroundColor3 = Part.Color or Colour(Options, Theme.White)
			Row.Name.Text = tostring(Part.Label or "")
			Row.Amount.Text = string.format("%d%%", math.floor(Share * 100 + 0.5))
		end
		for Index = #Parts_ + 1, #Wedges do
			Wedges[Index].Frame.Visible = false
		end
		if Options.Text == nil then
			Middle.Text = string.format("%d%%", math.floor(Used * 100 + 0.5))
		end
	end
	function Handle:Set(NewParts)
		Parts_ = NewParts or {}
		Render()
		return Handle
	end
	function Handle:SetText(Message)
		SwapText(Middle, tostring(Message))
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Scatter(Container, Options)
	local Handle = {}
	local Points = Options.Points or {}
	local Height = Options.Height or 140
	local Dots = {}
	local Built = Block(Container, Options, Height)
	local Field = New("Frame", {
		Name                   = "Field",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ClipsDescendants       = true,
	})
	New("Frame", {
		Name                   = "Bottom",
		Parent                 = Field,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, 0),
		Size                   = UDim2.new(1, 0, 0, 1),
	})
	New("Frame", {
		Name                   = "Side",
		Parent                 = Field,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, 1, 1, 0),
	})
	local function Render()
		local LowX, HighX = Options.MinX, Options.MaxX
		local LowY, HighY = Options.MinY, Options.MaxY
		for _, Point in Points do
			local X, Y = Point[1] or Point.X or 0, Point[2] or Point.Y or 0
			LowX = math.min(LowX or X, X)
			HighX = math.max(HighX or X, X)
			LowY = math.min(LowY or Y, Y)
			HighY = math.max(HighY or Y, Y)
		end
		local SpanX = math.max(1e-6, (HighX or 1) - (LowX or 0))
		local SpanY = math.max(1e-6, (HighY or 1) - (LowY or 0))
		for Index, Point in Points do
			local X, Y = Point[1] or Point.X or 0, Point[2] or Point.Y or 0
			local Dot = Dots[Index]
			if not Dot or not Dot.Parent then
				Dot = New("Frame", {
					Name                   = "Point",
					Parent                 = Field,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
				}, {
					Corner(Round(Options, 4)),
				})
				Dots[Index] = Dot
			end
			local Across = (X - (LowX or 0)) / SpanX
			local Up = (Y - (LowY or 0)) / SpanY
			local Wide = Point.Size or Options.Dot or 6
			Dot.Visible = true
			Dot.BackgroundColor3 = Point.Color or Colour(Options, Theme.White)
			Tween(Dot, {
				Position = UDim2.new(Across, 0, 1 - Up, 0),
				Size = UDim2.new(0, Wide, 0, Wide),
				BackgroundTransparency = Point.Transparency or 0.25,
			}, "layout")
		end
		for Index = #Points + 1, #Dots do
			Dots[Index].Visible = false
		end
	end
	function Handle:Set(NewPoints)
		Points = NewPoints or {}
		Render()
		return Handle
	end
	function Handle:Add(X, Y, Extra)
		local Point = Extra or {}
		Point[1], Point[2] = X, Y
		table.insert(Points, Point)
		Render()
		return Handle
	end
	function Handle:Clear()
		Points = {}
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
return Controls
end
KuikModules["Controls/Inputs"] = function()
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Scroll  = KuikRequire("Scroll")
local Screen  = KuikRequire("Screen")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Clamp   = Util.Clamp
local Quantise = Util.Quantise
local FormatNumber = Util.FormatNumber
local Round   = Util.Round
local Colour  = Util.Colour
local Shade   = Util.Shade
local Tween      = Motion.Tween
local MotionTime = Motion.MotionTime
local SwapText   = Motion.SwapText
local Row         = Parts.Row
local Block       = Parts.Block
local Common      = Parts.Common
local BlockHandle = Parts.BlockHandle
local Layered     = Parts.Layered
local SlidingMark = Parts.SlidingMark
local Draggable   = Parts.Draggable
local Controls = {}
local function Hit(Parent, ZIndex)
	return New("TextButton", {
		Name                   = "Hit",
		Parent                 = Parent,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = ZIndex or 3,
	})
end
local function Chip(Parent, Width, Height, Options)
	return New("Frame", {
		Name                   = "Chip",
		Parent                 = Parent,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Height),
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
	})
end
function Controls.Toggle(Container, Options)
	local Handle = {}
	local Variant = Options.Variant or "Switch"
	local Accent = Colour(Options, Theme.White)
	local Value
	if Variant == "Tri" then
		Value = Options.Default
	else
		Value = Options.Default == true
	end
	local Reserve = (Variant == "Check" or Variant == "Tri") and (Options.Size or Metrics.CheckSize)
		or Variant == "Pill" and 52
		or Metrics.ToggleWidth
	local Built = Row(Container, Util.Merge(Options, { Reserve = Reserve }))
	Built:Reserve(Reserve)
	local Render
	if Variant == "Check" or Variant == "Tri" then
		local Side = Options.Size or Metrics.CheckSize
		local Box = New("Frame", {
			Name                   = "Box",
			Parent                 = Built.Mount,
			BackgroundColor3       = Accent,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(1, 0, 0.5, 0),
			Size                   = UDim2.new(0, Side, 0, Side),
		}, {
			Corner(Util.Radius(Options, 3)),
			Stroke(Theme.White, Theme.TextTertiary, 1),
		})
		local Arms = {}
		for Index = 1, 2 do
			Arms[Index] = New("Frame", {
				Parent                 = Box,
				BackgroundColor3       = Theme.Black,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(Index == 1 and 0.36 or 0.6, 0, Index == 1 and 0.62 or 0.46, 0),
				Size                   = UDim2.new(0, math.max(4, Side * (Index == 1 and 0.32 or 0.56)), 0, 2),
				Rotation               = Index == 1 and 45 or -45,
			})
		end
		local Bar = New("Frame", {
			Parent                 = Box,
			BackgroundColor3       = Theme.Black,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, math.max(6, Side * 0.55), 0, 2),
		})
		Render = function()
			local Mixed = Value == nil
			Tween(Box, { BackgroundTransparency = Value == false and 1 or 0 }, "item")
			for _, Arm in Arms do
				Tween(Arm, { BackgroundTransparency = Value == true and 0 or 1 }, "item")
			end
			Tween(Bar, { BackgroundTransparency = Mixed and 0 or 1 }, "item")
		end
	elseif Variant == "Pill" then
		local Pill = New("Frame", {
			Name                   = "Pill",
			Parent                 = Built.Mount,
			BackgroundColor3       = Accent,
			BackgroundTransparency = 0.88,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(1, 0, 0.5, 0),
			Size                   = UDim2.new(0, 52, 0, Metrics.ChipHeight),
		}, {
			Corner(Round(Options, math.floor(Metrics.ChipHeight / 2))),
		})
		local Label = Text({
			Parent         = Pill,
			Text           = "OFF",
			TextColor3     = Accent,
			FontFace       = Theme.FontMedium,
			TextSize       = Metrics.MonoLargeSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Size           = UDim2.new(1, 0, 1, 0),
			AutomaticSize  = Enum.AutomaticSize.None,
		})
		Render = function()
			SwapText(Label, Value and (Options.On or "ON") or (Options.Off or "OFF"))
			Tween(Pill, { BackgroundTransparency = Value and 0.6 or 0.9 }, "item")
			Tween(Label, { TextTransparency = Value and 0 or Theme.TextSecondary }, "item")
		end
	else
		local Track = New("Frame", {
			Name             = "Track",
			Parent           = Built.Mount,
			BackgroundColor3 = Accent,
			BorderSizePixel  = 0,
			AnchorPoint      = Vector2.new(1, 0.5),
			Position         = UDim2.new(1, 0, 0.5, 0),
			Size             = UDim2.new(0, Metrics.ToggleWidth, 0, Metrics.ToggleHeight),
		}, {
			Corner(Round(Options, math.floor(Metrics.ToggleHeight / 2))),
		})
		local KnobSize = Metrics.ToggleHeight - Metrics.KnobInset * 2
		local Knob = New("Frame", {
			Name             = "Knob",
			Parent           = Track,
			BackgroundColor3 = Theme.Black,
			BorderSizePixel  = 0,
			AnchorPoint      = Vector2.new(0, 0.5),
			Position         = UDim2.new(0, Metrics.KnobInset, 0.5, 0),
			Size             = UDim2.new(0, KnobSize, 0, KnobSize),
		}, {
			Corner(Round(Options, math.floor(KnobSize / 2))),
		})
		Render = function(Animate)
			local Target = Value
				and UDim2.new(1, -Metrics.KnobInset - KnobSize, 0.5, 0)
				or UDim2.new(0, Metrics.KnobInset, 0.5, 0)
			local Transparency = Value and 0 or 0.55
			if Animate == false then
				Knob.Position = Target
				Track.BackgroundTransparency = Transparency
			else
				Tween(Knob, { Position = Target }, "toss")
				Tween(Track, { BackgroundTransparency = Transparency }, "item")
			end
		end
	end
	local Button = Built.Frame
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		if Variant == "Tri" then
			Value = NewValue
		else
			Value = NewValue == true
		end
		Render(true)
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	function Handle:Cycle()
		if Variant ~= "Tri" then
			return Handle:Set(not Value)
		end
		if Value == false then
			return Handle:Set(true)
		elseif Value == true then
			return Handle:Set(nil)
		end
		return Handle:Set(false)
	end
	Button.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		Handle:Cycle()
	end)
	Render(false)
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
	})
end
function Controls.Checkbox(Container, Options)
	return Controls.Toggle(Container, Util.Merge(Options, { Variant = "Check" }))
end
function Controls.Switch(Container, Options)
	return Controls.Toggle(Container, Util.Merge(Options, { Variant = "Switch" }))
end
function Controls.Slider(Container, Options)
	local Handle = {}
	local Minimum = Options.Min or 0
	local Maximum = Options.Max or 100
	local Step    = Options.Step or 0
	local Value   = Clamp(Options.Default or Minimum, Minimum, Maximum)
	local Accent  = Colour(Options, Theme.White)
	local Built = Row(Container, Util.Merge(Options, { Reserve = 70, Gap = 10 }))
	Built:Reserve(70)
	local Readout = Text({
		Parent           = Built.Mount,
		Text             = Options.Format and Options.Format(Value) or FormatNumber(Value, Step),
		TextSize         = Metrics.RowDescSize,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Foot = Built:Foot(20)
	local Track = New("Frame", {
		Name                   = "Track",
		Parent                 = Foot,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(1, 0, 0, Options.Thickness or Metrics.SliderTrack),
		ZIndex                 = 2,
	}, {
		Corner(2),
	})
	if Options.Variant == "Ticks" and Step > 0 and (Maximum - Minimum) / Step <= 40 then
		local Count = math.floor((Maximum - Minimum) / Step)
		for Index = 0, Count do
			New("Frame", {
				Parent                 = Track,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 0.7,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(Index / Count, 0, 0.5, 0),
				Size                   = UDim2.new(0, 1, 0, 7),
				ZIndex                 = 1,
			})
		end
	end
	local Fill = New("Frame", {
		Name             = "Fill",
		Parent           = Track,
		BackgroundColor3 = Accent,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
		ZIndex           = 2,
	}, {
		Corner(2),
	})
	local Thumb = New("Frame", {
		Name             = "Thumb",
		Parent           = Track,
		BackgroundColor3 = Accent,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0, 0, 0.5, 0),
		Size             = UDim2.new(0, Metrics.SliderThumbWidth, 0, Metrics.SliderThumbHeight),
		ZIndex           = 3,
	}, {
		Corner(Util.Radius(Options, 1)),
	})
	local function Fraction()
		local Span = Maximum - Minimum
		return Span > 0 and (Value - Minimum) / Span or 0
	end
	local function Render(Role)
		Readout.Text = Options.Format and Options.Format(Value) or FormatNumber(Value, Step)
		local Alpha = Fraction()
		if Role == false then
			Fill.Size = UDim2.new(Alpha, 0, 1, 0)
			Thumb.Position = UDim2.new(Alpha, 0, 0.5, 0)
		else
			Tween(Fill, { Size = UDim2.new(Alpha, 0, 1, 0) }, Role or "snap")
			Tween(Thumb, { Position = UDim2.new(Alpha, 0, 0.5, 0) }, Role or "snap")
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = Clamp(Quantise(NewValue, Step), Minimum, Maximum)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	function Handle:SetRange(NewMin, NewMax)
		Minimum, Maximum = NewMin or Minimum, NewMax or Maximum
		Value = Clamp(Value, Minimum, Maximum)
		Render()
		return Handle
	end
	local Grab = New("TextButton", {
		Parent                 = Foot,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 4,
	})
	local Stop = Draggable(Grab, Track, function(X)
		if Handle:IsDisabled() then
			return
		end
		local Raw = Minimum + X * (Maximum - Minimum)
		local Next = Clamp(Quantise(Raw, Step), Minimum, Maximum)
		local Changed = Next ~= Value
		Value = Next
		Render("drag")
		if Changed and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end, function()
		Tween(Thumb, { Size = UDim2.new(0, Metrics.SliderThumbWidth, 0, Metrics.SliderThumbHeight) }, "toss")
		if Options.Released then
			task.spawn(Options.Released, Value)
		end
	end)
	Grab.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Tween(Thumb, {
				Size = UDim2.new(0, Metrics.SliderThumbWidth + 2, 0, Metrics.SliderThumbHeight + 3),
			}, "snap")
		end
	end)
	Render(false)
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Grab },
		Destroy = Stop,
	})
end
function Controls.Range(Container, Options)
	local Handle = {}
	local Minimum = Options.Min or 0
	local Maximum = Options.Max or 100
	local Step = Options.Step or 1
	local Low = Clamp(Options.Low or Minimum, Minimum, Maximum)
	local High = Clamp(Options.High or Maximum, Minimum, Maximum)
	local Accent = Colour(Options, Theme.White)
	local Built = Row(Container, Util.Merge(Options, { Reserve = 100, Gap = 10 }))
	Built:Reserve(100)
	local Readout = Text({
		Parent           = Built.Mount,
		Text             = "",
		TextSize         = Metrics.RowDescSize,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Foot = Built:Foot(20)
	local Track = New("Frame", {
		Parent                 = Foot,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(1, 0, 0, Metrics.SliderTrack),
		ZIndex                 = 2,
	}, {
		Corner(2),
	})
	local Span = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Accent,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
		ZIndex           = 2,
	}, {
		Corner(2),
	})
	local function Thumb()
		return New("Frame", {
			Parent           = Track,
			BackgroundColor3 = Accent,
			BorderSizePixel  = 0,
			AnchorPoint      = Vector2.new(0.5, 0.5),
			Position         = UDim2.new(0, 0, 0.5, 0),
			Size             = UDim2.new(0, Metrics.SliderThumbWidth, 0, Metrics.SliderThumbHeight),
			ZIndex           = 3,
		}, {
			Corner(1),
		})
	end
	local LowThumb, HighThumb = Thumb(), Thumb()
	local function Fraction(Value)
		return Maximum > Minimum and (Value - Minimum) / (Maximum - Minimum) or 0
	end
	local function Render(Role)
		local A, B = Fraction(Low), Fraction(High)
		Readout.Text = Options.Format and Options.Format(Low, High)
			or string.format("%s - %s", FormatNumber(Low, Step), FormatNumber(High, Step))
		Tween(Span, { Position = UDim2.new(A, 0, 0, 0), Size = UDim2.new(B - A, 0, 1, 0) }, Role or "snap")
		Tween(LowThumb, { Position = UDim2.new(A, 0, 0.5, 0) }, Role or "snap")
		Tween(HighThumb, { Position = UDim2.new(B, 0, 0.5, 0) }, Role or "snap")
	end
	local Grab = New("TextButton", {
		Parent                 = Foot,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 4,
	})
	local Stop = Draggable(Grab, Track, function(X)
		if Handle:IsDisabled() then
			return
		end
		local Value = Clamp(Quantise(Minimum + X * (Maximum - Minimum), Step), Minimum, Maximum)
		if math.abs(Value - Low) <= math.abs(Value - High) then
			Low = math.min(Value, High)
		else
			High = math.max(Value, Low)
		end
		Render("drag")
		if Options.Callback then
			task.spawn(Options.Callback, Low, High)
		end
	end)
	function Handle:Get()
		return Low, High
	end
	function Handle:Set(NewLow, NewHigh, Silent)
		Low = Clamp(Quantise(NewLow, Step), Minimum, Maximum)
		High = Clamp(Quantise(NewHigh, Step), Low, Maximum)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Low, High)
		end
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Grab },
		Destroy = Stop,
	})
end
function Controls.Stepper(Container, Options)
	local Handle = {}
	local Minimum = Options.Min or 0
	local Maximum = Options.Max or 100
	local Step    = Options.Step or 1
	local Value   = Clamp(Options.Default or Minimum, Minimum, Maximum)
	local Wrap    = Options.Wrap == true
	local Width = Options.Width or Metrics.ChipWidth
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Plate = Chip(Built.Mount, Width, Metrics.ChipHeight, Options)
	local Readout = Text({
		Parent         = Plate,
		Text           = Options.Format and Options.Format(Value) or FormatNumber(Value, Step),
		TextSize       = Metrics.ValueSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Button = Hit(Plate)
	local function Render()
		SwapText(Readout, Options.Format and Options.Format(Value) or FormatNumber(Value, Step))
		Tween(Plate, { BackgroundTransparency = math.max(0, Theme.ChipTransparency - 0.3) }, "press")
		task.delay(MotionTime("press"), function()
			Tween(Plate, { BackgroundTransparency = Theme.ChipTransparency }, "hover")
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		local Wanted = Quantise(NewValue, Step)
		if Wrap then
			if Wanted > Maximum then
				Wanted = Minimum
			elseif Wanted < Minimum then
				Wanted = Maximum
			end
		end
		Value = Clamp(Wanted, Minimum, Maximum)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	Button.Activated:Connect(function(Input)
		if Handle:IsDisabled() then
			return
		end
		local Middle = Plate.AbsolutePosition.X + Plate.AbsoluteSize.X / 2
		local X = Input and Input.Position and Input.Position.X
			or UserInputService:GetMouseLocation().X
		Handle:Set(Value + (X < Middle and -Step or Step))
	end)
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
	})
end
function Controls.Input(Container, Options)
	local Handle = {}
	local Value = Options.Default and tostring(Options.Default) or ""
	local Width = Options.Width or 140
	local Multiline = Options.Multiline == true
	local Height = Multiline and (Options.Height or 76) or (Metrics.ChipHeight + 3)
	local Built = Row(Container, Util.Merge(Options,
		{ Reserve = Multiline and 0 or Width, Gap = Multiline and 10 or 8 }))
	local Holder = Multiline and Built:Foot(Height) or Built:Reserve(Width)
	local Field = New("TextBox", {
		Name                   = "Field",
		Parent                 = Holder,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Multiline and Vector2.new(0, 0) or Vector2.new(1, 0.5),
		Position               = Multiline and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 0, 0.5, 0),
		Size                   = Multiline and UDim2.new(1, 0, 1, 0) or UDim2.new(0, Width, 0, Height),
		Text                   = Value,
		PlaceholderText        = Options.Placeholder or "",
		PlaceholderColor3      = Theme.White,
		TextColor3             = Theme.White,
		FontFace               = Options.Mono and Theme.FontMono or Theme.Font,
		TextSize               = Metrics.ValueSize,
		TextXAlignment         = Multiline and Enum.TextXAlignment.Left
			or (Options.Align == "Left" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center),
		TextYAlignment         = Multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		ClearTextOnFocus       = Options.ClearOnFocus == true,
		MultiLine              = Multiline,
		TextWrapped            = Multiline,
		TextEditable           = true,
		ZIndex                 = 3,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(Multiline and 8 or 0, 8),
	})
	local function Show(Content)
		if Options.Password then
			return string.rep("\u{2022}", #Content)
		end
		return Content
	end
	local function Commit(Entered)
		local Raw = Options.Password and Value or Field.Text
		if Options.MaxLength and #Raw > Options.MaxLength then
			Raw = string.sub(Raw, 1, Options.MaxLength)
		end
		if Options.Numeric then
			local Parsed = tonumber(Raw)
			if not Parsed then
				Field.Text = Show(Value)
				return
			end
			if Options.Min then
				Parsed = math.max(Options.Min, Parsed)
			end
			if Options.Max then
				Parsed = math.min(Options.Max, Parsed)
			end
			Value = tostring(Parsed)
			Field.Text = Value
			if Options.Callback then
				task.spawn(Options.Callback, Parsed, Entered)
			end
			return
		end
		Value = Raw
		Field.Text = Show(Value)
		if Options.Callback then
			task.spawn(Options.Callback, Value, Entered)
		end
	end
	if Options.Password then
		Field.Text = Show(Value)
		Field:GetPropertyChangedSignal("Text"):Connect(function()
			local Shown = Field.Text
			if Shown ~= Show(Value) then
				local Added = #Shown - #Value
				if Added > 0 then
					Value ..= string.sub(Shown, #Shown - Added + 1)
				elseif Added < 0 then
					Value = string.sub(Value, 1, #Value + Added)
				end
				Field.Text = Show(Value)
			end
		end)
	end
	function Handle:Get()
		return Options.Numeric and tonumber(Value) or Value
	end
	function Handle:Set(NewValue, Silent)
		Value = tostring(NewValue)
		Field.Text = Show(Value)
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Handle:Get(), false)
		end
		return Handle
	end
	function Handle:Focus()
		Field:CaptureFocus()
		return Handle
	end
	Field.Focused:Connect(function()
		Tween(Field, { BackgroundTransparency = math.max(0, Theme.ChipTransparency - 0.25) }, "hover")
	end)
	Field.FocusLost:Connect(function(Entered)
		Tween(Field, { BackgroundTransparency = Theme.ChipTransparency }, "hover")
		Commit(Entered)
	end)
	if Options.Live then
		Field:GetPropertyChangedSignal("Text"):Connect(function()
			if not Options.Password and Options.Callback then
				task.spawn(Options.Callback, Field.Text, false)
			end
		end)
	end
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Field },
	})
end
function Controls.TextArea(Container, Options)
	return Controls.Input(Container, Util.Merge(Options, { Multiline = true }))
end
function Controls.Search(Container, Options)
	local Merged = Util.Merge(Options, {
		Live = Options.Live ~= false,
		Placeholder = Options.Placeholder or "Search",
		Width = Options.Width or 180,
		Align = "Left",
	})
	local Handle = Controls.Input(Container, Merged)
	local Field = Handle.Frame:FindFirstChild("Field", true)
	if Field then
		Field.Size = UDim2.new(0, Merged.Width, 0, Metrics.ChipHeight + 3)
		local Lens = New("Frame", {
			Name                   = "Lens",
			Parent                 = Field,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(1, -2, 0.5, 0),
			Size                   = UDim2.new(0, 10, 0, 10),
			ZIndex                 = 4,
		}, {
			Corner(5),
			Stroke(Theme.White, Theme.TextTertiary, 1),
		})
		New("Frame", {
			Parent                 = Lens,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.TextTertiary,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 0),
			Position               = UDim2.new(0.78, 0, 0.78, 0),
			Size                   = UDim2.new(0, 4, 0, 1),
			Rotation               = 45,
			ZIndex                 = 4,
		})
	end
	return Handle
end
function Controls.Keybind(Container, Options)
	local Handle = {}
	local Value = Options.Default or Enum.KeyCode.Unknown
	local Listening = false
	local Width = Options.Width or 90
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Plate = Chip(Built.Mount, Width, Metrics.ChipHeight + 2, Options)
	local Readout = Text({
		Parent         = Plate,
		Text           = Value.Name,
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoBoldSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Button = Hit(Plate)
	function Handle:Get()
		return Value
	end
	function Handle:Set(KeyCode, Silent)
		Value = KeyCode
		Readout.Text = KeyCode.Name
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	function Handle:IsListening()
		return Listening
	end
	local Connection = nil
	Button.Activated:Connect(function()
		if Listening or Handle:IsDisabled() then
			return
		end
		Listening = true
		Readout.Text = "..."
		Tween(Plate, { BackgroundTransparency = math.max(0, Theme.ChipTransparency - 0.25) }, "hover")
		Connection = UserInputService.InputBegan:Connect(function(Input, Processed)
			local Keyboard = Input.UserInputType == Enum.UserInputType.Keyboard
			local Mouse = Options.Mouse and (
				Input.UserInputType == Enum.UserInputType.MouseButton2
				or Input.UserInputType == Enum.UserInputType.MouseButton3)
			if Processed or not (Keyboard or Mouse) then
				return
			end
			Connection:Disconnect()
			Connection = nil
			Listening = false
			Tween(Plate, { BackgroundTransparency = Theme.ChipTransparency }, "hover")
			if Input.KeyCode == Enum.KeyCode.Escape then
				Readout.Text = Value.Name
				return
			end
			if Input.KeyCode == Enum.KeyCode.Backspace then
				Handle:Set(Enum.KeyCode.Unknown)
				return
			end
			Handle:Set(Mouse and Input.UserInputType or Input.KeyCode)
		end)
	end)
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
		Destroy = function()
			if Connection then
				Connection:Disconnect()
			end
		end,
	})
end
function Controls.Vector(Container, Options)
	local Handle = {}
	local Axes = Options.Axes or { "X", "Y", "Z" }
	local Values = {}
	local Fields = {}
	for Index in Axes do
		Values[Index] = (Options.Default and Options.Default[Index]) or 0
	end
	local Built = Block(Container, Options, 26)
	Strip(6).Parent = Built.Content
	local function Fire()
		if Options.Callback then
			task.spawn(Options.Callback, table.clone(Values))
		end
	end
	for Index, Axis in Axes do
		local Cell = New("Frame", {
			Parent                 = Built.Content,
			BackgroundColor3       = Theme.Black,
			BackgroundTransparency = Theme.ChipTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1 / #Axes, -6, 1, 0),
			LayoutOrder            = Index,
		}, {
			Corner(Util.Radius(Options, Metrics.ChipRadius)),
			Padding(0, 8),
		})
		Text({
			Parent           = Cell,
			Text             = Axis,
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Size             = UDim2.new(0, 10, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		local Field = New("TextBox", {
			Parent                 = Cell,
			BackgroundTransparency = 1,
			Text                   = FormatNumber(Values[Index], Options.Step or 0.01),
			TextColor3             = Theme.White,
			FontFace               = Theme.FontMono,
			TextSize               = Metrics.MonoBoldSize,
			TextXAlignment         = Enum.TextXAlignment.Right,
			ClearTextOnFocus       = false,
			Position               = UDim2.new(0, 12, 0, 0),
			Size                   = UDim2.new(1, -12, 1, 0),
		})
		Fields[Index] = Field
		Field.FocusLost:Connect(function()
			local Parsed = tonumber(Field.Text)
			if Parsed then
				Values[Index] = Parsed
				Fire()
			end
			Field.Text = FormatNumber(Values[Index], Options.Step or 0.01)
		end)
	end
	function Handle:Get()
		return table.clone(Values)
	end
	function Handle:Set(NewValues, Silent)
		for Index in Axes do
			Values[Index] = NewValues[Index] or Values[Index]
			Fields[Index].Text = FormatNumber(Values[Index], Options.Step or 0.01)
		end
		if not Silent then
			Fire()
		end
		return Handle
	end
	return BlockHandle(Built, Handle, Options)
end
function Controls.Dropdown(Container, Options, Owner)
	local Handle = {}
	local Items = Options.Items or {}
	local Multi = Options.Multi == true
	local Open = false
	local Width = Options.Width or 110
	local EntryHeight = Options.EntryHeight or 24
	local Value = Options.Default
	local Chosen = {}
	if Multi then
		for _, Item in (type(Value) == "table" and Value or {}) do
			Chosen[Item] = true
		end
	elseif Value == nil then
		Value = Items[1]
	end
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Plate = Chip(Built.Mount, Width, Metrics.ChipHeight + 2, Options)
	Padding(0, 8).Parent = Plate
	local Readout = Text({
		Parent         = Plate,
		Text           = "",
		TextSize       = Metrics.ValueSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		Size           = UDim2.new(1, -12, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Chevron, Arms = Util.Chevron(Plate, 10, "Down")
	Chevron.AnchorPoint = Vector2.new(1, 0.5)
	Chevron.Position = UDim2.new(1, 0, 0.5, 0)
	local Layer = Owner and Owner._Overlay and Owner:_Overlay() or Screen.Get()
	local Menu = New("Frame", {
		Name                   = "DropdownMenu",
		Parent                 = Layer,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.12,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Width, 0, 0),
		Visible                = false,
		ClipsDescendants       = true,
		ZIndex                 = 41,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Stroke(Theme.White, 0.78, 1),
	})
	local Inner = New("CanvasGroup", {
		Name                   = "Inner",
		Parent                 = Menu,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		GroupTransparency      = 1,
		ZIndex                 = 42,
	}, {
		Padding(4),
		List(4),
	})
	local Filter = nil
	if Options.Search then
		Filter = New("TextBox", {
			Name                   = "Filter",
			Parent                 = Inner,
			BackgroundColor3       = Theme.Black,
			BackgroundTransparency = 0.4,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 20),
			Text                   = "",
			PlaceholderText        = "Filter",
			PlaceholderColor3      = Theme.White,
			TextColor3             = Theme.White,
			FontFace               = Theme.Font,
			TextSize               = Metrics.MonoLargeSize,
			ClearTextOnFocus       = false,
			LayoutOrder            = 1,
			ZIndex                 = 43,
		}, {
			Corner(Util.Radius(Options, 3)),
			Padding(0, 6),
		})
	end
	local Sheet = New("ScrollingFrame", {
		Name                   = "Scroll",
		Parent                 = Inner,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, Filter and -24 or 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.Y,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.Y,
		ClipsDescendants       = true,
		LayoutOrder            = 2,
		ZIndex                 = 42,
	})
	local Canvas, Rows = Layered(Sheet, 1)
	local Scroller = Scroll.Attach(Sheet, "Y", { Depth = 14 })
	local Entries = {}
	local Order = {}
	local Mark = nil
	local function Summary()
		if not Multi then
			return tostring(Value)
		end
		local Names = {}
		for _, Item in Items do
			if Chosen[Item] then
				table.insert(Names, tostring(Item))
			end
		end
		if #Names == 0 then
			return Options.Empty or "None"
		end
		if #Names > 2 then
			return string.format("%d selected", #Names)
		end
		return table.concat(Names, ", ")
	end
	local function Render()
		Readout.Text = Summary()
		local Marked = nil
		for Item, Bits in Entries do
			local On = Multi and Chosen[Item] == true or Item == Value
			if On and not Multi then
				Marked = Bits.Entry
			end
			Tween(Bits.Label, {
				TextTransparency = On and Theme.TextPrimary or Theme.TextSecondary,
			}, "hover")
			if Bits.Tick then
				Tween(Bits.Tick, { BackgroundTransparency = On and 0 or 1 }, "item")
			end
		end
		if Mark then
			Mark:To(Marked, Canvas)
		end
	end
	local function Visible()
		local Count = 0
		for _, Item in Items do
			if Entries[Item] and Entries[Item].Entry.Visible then
				Count += 1
			end
		end
		return Count
	end
	local function Height()
		return math.min(math.max(Visible(), 1), Options.Visible or 6) * (EntryHeight + 1)
			+ 8 + (Filter and 24 or 0)
	end
	local function Place()
		local Origin = Layer.AbsolutePosition
		local Full = Height()
		local Below = Plate.AbsolutePosition.Y + Plate.AbsoluteSize.Y + 5
		local Viewport = Screen.Get().AbsoluteSize.Y
		local Upward = Viewport > 0 and Below + Full > Viewport - 8
		Menu.Position = UDim2.fromOffset(
			Plate.AbsolutePosition.X - Origin.X,
			Upward and (Plate.AbsolutePosition.Y - Origin.Y - 5) or (Below - Origin.Y)
		)
		Menu.AnchorPoint = Vector2.new(0, Upward and 1 or 0)
	end
	local function Close()
		if not Open then
			return
		end
		Open = false
		if Following then
			Following:Disconnect()
			Following = nil
		end
		for Index, Arm in Arms do
			Tween(Arm, { Rotation = Index == 1 and 45 or -45 }, "morph")
		end
		Tween(Menu, { Size = UDim2.new(0, Width, 0, 0) }, "snap")
		Tween(Inner, { GroupTransparency = 1 }, "exit")
		task.delay(MotionTime("snap"), function()
			if not Open then
				Menu.Visible = false
			end
		end)
	end
	local Following = nil
	local function Show()
		Open = true
		Place()
		Menu.Size = UDim2.new(0, Width, 0, 0)
		Menu.Visible = true
		Inner.GroupTransparency = 1
		for Index, Arm in Arms do
			Tween(Arm, { Rotation = Index == 1 and -45 or 45 }, "morph")
		end
		Tween(Menu, { Size = UDim2.new(0, Width, 0, Height()) }, "reveal")
		Tween(Inner, { GroupTransparency = 0 }, "fade")
		if Following then
			Following:Disconnect()
		end
		Following = RunService.RenderStepped:Connect(function()
			if not Open then
				return
			end
			if Plate.AbsoluteSize.X <= 0 or not Plate.Visible then
				Close()
				return
			end
			Place()
		end)
	end
	local function Fire()
		if not Options.Callback then
			return
		end
		if Multi then
			task.spawn(Options.Callback, Handle:Get())
		else
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Get()
		if not Multi then
			return Value
		end
		local Out = {}
		for _, Item in Items do
			if Chosen[Item] then
				table.insert(Out, Item)
			end
		end
		return Out
	end
	function Handle:Set(NewValue, Silent)
		if Multi then
			table.clear(Chosen)
			for _, Item in NewValue or {} do
				Chosen[Item] = true
			end
		else
			Value = NewValue
		end
		Render()
		if not Silent then
			Fire()
		end
		return Handle
	end
	function Handle:Open()
		Show()
		return Handle
	end
	function Handle:Close()
		Close()
		return Handle
	end
	function Handle:IsOpen()
		return Open
	end
	local function Build()
		for _, Bits in Entries do
			Bits.Entry:Destroy()
		end
		table.clear(Entries)
		table.clear(Order)
		for Index, Item in Items do
			local Entry = New("TextButton", {
				Parent                 = Rows,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 0, EntryHeight),
				LayoutOrder            = Index,
				ZIndex                 = 43,
			}, {
				Corner(Util.Radius(Options, Metrics.RowRadius)),
			})
			local Tick = nil
			local Inset = 9
			if Multi then
				Inset = 22
				local Box = New("Frame", {
					Parent                 = Entry,
					BackgroundTransparency = 1,
					AnchorPoint            = Vector2.new(0, 0.5),
					Position               = UDim2.new(0, 7, 0.5, 0),
					Size                   = UDim2.new(0, 10, 0, 10),
					ZIndex                 = 44,
				}, {
					Corner(2),
					Stroke(Theme.White, Theme.TextTertiary, 1),
				})
				Tick = New("Frame", {
					Parent                 = Box,
					BackgroundColor3       = Theme.White,
					BackgroundTransparency = 1,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(0.5, 0.5),
					Position               = UDim2.new(0.5, 0, 0.5, 0),
					Size                   = UDim2.new(0, 5, 0, 5),
					ZIndex                 = 45,
				})
			end
			local Label = Text({
				Parent           = Entry,
				Text             = tostring(Item),
				TextSize         = Metrics.ValueSize,
				TextTransparency = Theme.TextSecondary,
				TextYAlignment   = Enum.TextYAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Position         = UDim2.new(0, Inset, 0, 0),
				Size             = UDim2.new(1, -(Inset + 4), 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
				ZIndex           = 44,
			})
			Entries[Item] = { Entry = Entry, Label = Label, Tick = Tick }
			table.insert(Order, Item)
			Entry.MouseEnter:Connect(function()
				Tween(Entry, { BackgroundTransparency = 0.9 }, "hover")
			end)
			Entry.MouseLeave:Connect(function()
				Tween(Entry, { BackgroundTransparency = 1 }, "hover")
			end)
			Entry.Activated:Connect(function()
				if Multi then
					Chosen[Item] = not Chosen[Item] or nil
					Render()
					Fire()
					Tween(Menu, { Size = UDim2.new(0, Width, 0, Height()) }, "snap")
				else
					Value = Item
					Render()
					Fire()
					Close()
				end
			end)
		end
	end
	function Handle:SetItems(NewItems, Silent)
		Items = NewItems or {}
		if not Multi and not table.find(Items, Value) then
			Value = Items[1]
		end
		Build()
		Render()
		if not Silent then
			Fire()
		end
		return Handle
	end
	function Handle:Items()
		return Items
	end
	Build()
	Mark = SlidingMark(Canvas)
	if Filter then
		Filter:GetPropertyChangedSignal("Text"):Connect(function()
			local Needle = string.lower(Filter.Text)
			for Item, Bits in Entries do
				Bits.Entry.Visible = Needle == ""
					or string.find(string.lower(tostring(Item)), Needle, 1, true) ~= nil
			end
			if Open then
				Tween(Menu, { Size = UDim2.new(0, Width, 0, Height()) }, "snap")
			end
		end)
	end
	local Button = Hit(Plate)
	Button.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		if Open then
			Close()
		else
			Show()
		end
	end)
	Plate.MouseEnter:Connect(function()
		Tween(Plate, { BackgroundTransparency = math.max(0, Theme.ChipTransparency - 0.18) }, "hover")
	end)
	Plate.MouseLeave:Connect(function()
		Tween(Plate, { BackgroundTransparency = Theme.ChipTransparency }, "hover")
	end)
	local function Within(Object, Point)
		local Top, Size = Object.AbsolutePosition, Object.AbsoluteSize
		return Point.X >= Top.X and Point.X <= Top.X + Size.X
			and Point.Y >= Top.Y and Point.Y <= Top.Y + Size.Y
	end
	local Outside = UserInputService.InputBegan:Connect(function(Input)
		if not Open then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local Point = Input.Position
		if not Within(Menu, Point) and not Within(Plate, Point) then
			Close()
		end
	end)
	if Owner and Owner._Register then
		Owner:_Register(Close)
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
		Destroy = function()
			Outside:Disconnect()
			if Following then
				Following:Disconnect()
			end
			Scroller:Destroy()
			Menu:Destroy()
		end,
	})
end
function Controls.Radio(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Value = Options.Default or Items[1]
	local Buttons = {}
	local Accent = Colour(Options, Theme.White)
	local Built = Block(Container, Options)
	local Columns = Options.Columns or 1
	if Columns > 1 then
		New("UIGridLayout", {
			Parent       = Built.Content,
			CellSize     = UDim2.new(1 / Columns, -6, 0, 24),
			CellPadding  = UDim2.new(0, 6, 0, 4),
			SortOrder    = Enum.SortOrder.LayoutOrder,
			FillDirectionMaxCells = Columns,
		})
	else
		List(4).Parent = Built.Content
	end
	local function Render()
		for Item, Bits in Buttons do
			local Selected = Item == Value
			Tween(Bits.Dot, { Size = Selected and UDim2.new(0, 6, 0, 6) or UDim2.new(0, 0, 0, 0) }, "toss")
			Tween(Bits.Dot, { BackgroundTransparency = Selected and 0 or 1 }, "hover")
			Tween(Bits.Ring, { Transparency = Selected and 0 or Theme.TextTertiary }, "hover")
			Tween(Bits.Label, {
				TextTransparency = Selected and Theme.TextPrimary or Theme.TextSecondary,
			}, "hover")
		end
	end
	for Index, Item in Items do
		local Entry = New("TextButton", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 0, 24),
			LayoutOrder            = Index,
		})
		Strip(9).Parent = Entry
		local Circle = New("Frame", {
			Parent                 = Entry,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(0, 13, 0, 13),
			LayoutOrder            = 1,
		}, {
			Corner(7),
		})
		local Ring = Stroke(Accent, Theme.TextTertiary, 1)
		Ring.Parent = Circle
		local Dot = New("Frame", {
			Parent                 = Circle,
			BackgroundColor3       = Accent,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, 0, 0, 0),
		}, {
			Corner(4),
		})
		local Label = Text({
			Parent           = Entry,
			Text             = tostring(Item),
			TextSize         = Metrics.ValueSize,
			TextTransparency = Theme.TextSecondary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			AutomaticSize    = Columns > 1 and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			Size             = Columns > 1 and UDim2.new(1, -22, 1, 0) or UDim2.new(0, 0, 1, 0),
			LayoutOrder      = 2,
		})
		Buttons[Item] = { Ring = Ring, Dot = Dot, Label = Label }
		Entry.Activated:Connect(function()
			if Handle:IsDisabled() then
				return
			end
			Handle:Set(Item)
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Chips(Container, Options)
	local Handle = {}
	local Selected = {}
	local Pills = {}
	local Accent = Colour(Options, Theme.White)
	for _, Item in Options.Default or {} do
		Selected[Item] = true
	end
	local Built = Block(Container, Options)
	New("UIListLayout", {
		Parent              = Built.Content,
		Padding             = UDim.new(0, 6),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Wraps               = true,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
	})
	local function Render()
		for Item, Bits in Pills do
			local On = Selected[Item] == true
			Tween(Bits.Pill, { BackgroundTransparency = On and 0 or 1 }, "hover")
			Tween(Bits.Label, {
				TextColor3       = On and Theme.Black or Theme.White,
				TextTransparency = On and 0 or Theme.TextSecondary,
			}, "hover")
			Bits.Stroke.Transparency = On and 1 or 0.65
		end
	end
	local function Count()
		local Total = 0
		for _, On in Selected do
			if On then
				Total += 1
			end
		end
		return Total
	end
	for Index, Item in Options.Items or {} do
		local Pill = New("TextButton", {
			Parent                 = Built.Content,
			BackgroundColor3       = Accent,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, 24),
			LayoutOrder            = Index,
		}, {
			Corner(Round(Options, 12)),
			Padding(0, 11),
		})
		local Ring = Stroke(Theme.White, 0.65, 1)
		Ring.Parent = Pill
		local Label = New("TextLabel", {
			Parent                 = Pill,
			BackgroundTransparency = 1,
			Text                   = tostring(Item),
			TextColor3             = Theme.White,
			TextTransparency       = Theme.TextSecondary,
			FontFace               = Theme.Font,
			TextSize               = Metrics.ValueSize,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			ZIndex                 = 2,
		})
		local Button = Pill
		Pills[Item] = { Pill = Pill, Label = Label, Stroke = Ring }
		Button.Activated:Connect(function()
			if Handle:IsDisabled() then
				return
			end
			if Options.Single then
				table.clear(Selected)
				Selected[Item] = true
			elseif Selected[Item] then
				Selected[Item] = nil
			elseif not Options.Max or Count() < Options.Max then
				Selected[Item] = true
			else
				Tween(Pill, { BackgroundTransparency = 0.7 }, "press")
				task.delay(MotionTime("press"), function()
					Tween(Pill, { BackgroundTransparency = 1 }, "hover")
				end)
				return
			end
			Render()
			if Options.Callback then
				task.spawn(Options.Callback, Handle:Get())
			end
		end)
	end
	function Handle:Get()
		local Out = {}
		for _, Item in Options.Items or {} do
			if Selected[Item] then
				table.insert(Out, Item)
			end
		end
		return Out
	end
	function Handle:Set(Values, Silent)
		table.clear(Selected)
		for _, Item in Values or {} do
			Selected[Item] = true
		end
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Handle:Get())
		end
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Segmented(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Value = Options.Default or Items[1]
	local Buttons = {}
	local Built = Block(Container, Options, Options.Height or 28)
	local Track = New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = 0.65,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
	}, {
		Corner(Round(Options, 14)),
		Padding(3),
	})
	local Highlight = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		Size             = UDim2.new(1 / math.max(#Items, 1), 0, 1, 0),
		ZIndex           = 1,
	}, {
		Corner(Round(Options, 11)),
	})
	local Strip_ = New("Frame", {
		Parent                 = Track,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 2,
	})
	Strip(0).Parent = Strip_
	local function Render()
		for Index, Item in Items do
			local On = Item == Value
			if On then
				Tween(Highlight, { Position = UDim2.new((Index - 1) / #Items, 0, 0, 0) }, "morph")
			end
			Tween(Buttons[Item], {
				TextColor3       = On and Theme.Black or Theme.White,
				TextTransparency = On and 0 or Theme.TextSecondary,
			}, "hover")
		end
	end
	for Index, Item in Items do
		local Button = New("TextButton", {
			Parent                 = Strip_,
			BackgroundTransparency = 1,
			Text                   = tostring(Item),
			TextColor3             = Theme.White,
			TextTransparency       = Theme.TextSecondary,
			FontFace               = Theme.Font,
			TextSize               = Metrics.ValueSize,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			AutoButtonColor        = false,
			Size                   = UDim2.new(1 / #Items, 0, 1, 0),
			LayoutOrder            = Index,
			ZIndex                 = 3,
		})
		Buttons[Item] = Button
		Button.Activated:Connect(function()
			if Handle:IsDisabled() then
				return
			end
			Handle:Set(Item)
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Tags(Container, Options)
	local Handle = {}
	local Values = table.clone(Options.Default or {})
	local Built = Block(Container, Options)
	local Wrap = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	})
	New("UIListLayout", {
		Parent            = Wrap,
		Padding           = UDim.new(0, 6),
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		Wraps             = true,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local Field = nil
	local Pills = {}
	local function Fire()
		if Options.Callback then
			task.spawn(Options.Callback, table.clone(Values))
		end
	end
	local Render
	local function MakePill(Value, Index)
		local Pill = New("Frame", {
			Parent                 = Wrap,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = 0.86,
			BorderSizePixel        = 0,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, 22),
			LayoutOrder            = Index,
		}, {
			Corner(Round(Options, 11)),
			Padding(0, 7, 0, 9),
			Strip(6),
		})
		Text({
			Parent           = Pill,
			Text             = tostring(Value),
			TextSize         = Metrics.CaptionSize,
			TextTransparency = Theme.TextSecondary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			AutomaticSize    = Enum.AutomaticSize.X,
			Size             = UDim2.new(0, 0, 1, 0),
			LayoutOrder      = 1,
		})
		local Cross = New("TextButton", {
			Parent                 = Pill,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(0, 10, 0, 10),
			LayoutOrder            = 2,
		})
		for Arm = 1, 2 do
			New("Frame", {
				Parent                 = Cross,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.TextTertiary,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, 0.5, 0),
				Size                   = UDim2.new(0, 9, 0, 1),
				Rotation               = Arm == 1 and 45 or -45,
			})
		end
		Cross.Activated:Connect(function()
			local At = table.find(Values, Value)
			if At then
				table.remove(Values, At)
				Render()
				Fire()
			end
		end)
		return Pill
	end
	Render = function()
		for _, Pill in Pills do
			Pill:Destroy()
		end
		table.clear(Pills)
		for Index, Value in Values do
			Pills[Index] = MakePill(Value, Index)
		end
		if Field then
			Field.LayoutOrder = #Values + 1
		end
	end
	Field = New("TextBox", {
		Parent                 = Wrap,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Options.Width or 90, 0, 22),
		Text                   = "",
		PlaceholderText        = Options.Placeholder or "Add",
		PlaceholderColor3      = Theme.White,
		TextColor3             = Theme.White,
		FontFace               = Theme.Font,
		TextSize               = Metrics.CaptionSize,
		ClearTextOnFocus       = false,
		LayoutOrder            = 999,
	}, {
		Corner(Round(Options, 11)),
		Padding(0, 8),
	})
	Field.FocusLost:Connect(function(Entered)
		local Word = string.gsub(Field.Text, "^%s*(.-)%s*$", "%1")
		Field.Text = ""
		if not Entered or Word == "" then
			return
		end
		if Options.Max and #Values >= Options.Max then
			return
		end
		if not Options.Duplicates and table.find(Values, Word) then
			return
		end
		table.insert(Values, Word)
		Render()
		Fire()
		Field:CaptureFocus()
	end)
	function Handle:Get()
		return table.clone(Values)
	end
	function Handle:Set(NewValues, Silent)
		Values = table.clone(NewValues or {})
		Render()
		if not Silent then
			Fire()
		end
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Tristate(Container, Options)
	return Controls.Toggle(Container, Util.Merge(Options, { Variant = "Tri" }))
end
function Controls.Autocomplete(Container, Options, Owner)
	local Handle = {}
	local Value = Options.Default or ""
	local Width = Options.Width or 160
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Field = New("TextBox", {
		Name                   = "Field",
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.ChipHeight + 3),
		Text                   = Value,
		PlaceholderText        = Options.Placeholder or "Type to search",
		PlaceholderColor3      = Theme.White,
		TextColor3             = Theme.White,
		FontFace               = Theme.Font,
		TextSize               = Metrics.ValueSize,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ClearTextOnFocus       = false,
		ZIndex                 = 3,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(0, 8),
	})
	local Layer = Owner and Owner._Overlay and Owner:_Overlay() or Screen.Get()
	local Menu = New("Frame", {
		Name                   = "Suggestions",
		Parent                 = Layer,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.12,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Width, 0, 0),
		Visible                = false,
		ClipsDescendants       = true,
		ZIndex                 = 41,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Stroke(Theme.White, 0.78, 1),
		Padding(4),
		List(1),
	})
	local Rows = {}
	local Height = 22
	local function Hide()
		Menu.Visible = false
	end
	local function Suggest()
		for _, Row_ in Rows do
			Row_:Destroy()
		end
		table.clear(Rows)
		local Needle = string.lower(Field.Text)
		local Source = Options.Items or {}
		if Options.Source then
			Source = Options.Source(Field.Text) or {}
		end
		local Shown = 0
		for _, Item in Source do
			local Text_ = tostring(Item)
			if Needle == "" or string.find(string.lower(Text_), Needle, 1, true) then
				Shown += 1
				if Shown > (Options.Visible or 6) then
					break
				end
				local Entry = New("TextButton", {
					Parent                 = Menu,
					BackgroundColor3       = Theme.White,
					BackgroundTransparency = 1,
					BorderSizePixel        = 0,
					Text                   = "",
					AutoButtonColor        = false,
					Size                   = UDim2.new(1, 0, 0, Height),
					LayoutOrder            = Shown,
					ZIndex                 = 43,
				})
				Text({
					Parent           = Entry,
					Text             = Text_,
					TextSize         = Metrics.ValueSize,
					TextTransparency = Theme.TextSecondary,
					TextYAlignment   = Enum.TextYAlignment.Center,
					TextTruncate     = Enum.TextTruncate.AtEnd,
					Position         = UDim2.new(0, 8, 0, 0),
					Size             = UDim2.new(1, -12, 1, 0),
					AutomaticSize    = Enum.AutomaticSize.None,
					ZIndex           = 44,
				})
				Entry.MouseEnter:Connect(function()
					Tween(Entry, { BackgroundTransparency = 0.9 }, "hover")
				end)
				Entry.MouseLeave:Connect(function()
					Tween(Entry, { BackgroundTransparency = 1 }, "hover")
				end)
				Entry.Activated:Connect(function()
					Handle:Set(Text_)
					Hide()
				end)
				table.insert(Rows, Entry)
			end
		end
		if Shown == 0 then
			Hide()
			return
		end
		local Origin = Layer.AbsolutePosition
		Menu.Position = UDim2.fromOffset(
			Field.AbsolutePosition.X - Origin.X,
			Field.AbsolutePosition.Y + Field.AbsoluteSize.Y + 4 - Origin.Y)
		Menu.Visible = true
		Menu.Size = UDim2.new(0, Width, 0, 0)
		Tween(Menu, { Size = UDim2.new(0, Width, 0, math.min(Shown, Options.Visible or 6) * (Height + 1) + 8) }, "reveal")
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Field.Text = NewValue
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	Field:GetPropertyChangedSignal("Text"):Connect(Suggest)
	Field.Focused:Connect(Suggest)
	Field.FocusLost:Connect(function(Entered)
		Value = Field.Text
		task.delay(0.15, Hide)
		if Options.Callback then
			task.spawn(Options.Callback, Value, Entered)
		end
	end)
	if Owner and Owner._Register then
		Owner:_Register(Hide)
	end
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Field },
		Destroy = function()
			Menu:Destroy()
		end,
	})
end
return Controls
end
KuikModules["Controls/Media"] = function()
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Scroll  = KuikRequire("Scroll")
local Screen  = KuikRequire("Screen")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Clamp   = Util.Clamp
local Round   = Util.Round
local Colour  = Util.Colour
local Tween      = Motion.Tween
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Row         = Parts.Row
local Block       = Parts.Block
local Common      = Parts.Common
local BlockHandle = Parts.BlockHandle
local Draggable   = Parts.Draggable
local Controls = {}
local function Well(Parent, Options, Height)
	local Fill, Alpha = Util.Surface(Options, Theme.EmbedColor, Theme.EmbedTransparency)
	local Frame = New("Frame", {
		Name                   = "Well",
		Parent                 = Parent,
		BackgroundColor3       = Fill,
		BackgroundTransparency = Alpha,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, Height and 0 or 1, Height or 0),
		ClipsDescendants       = Options.Clip ~= false,
	}, {
		Corner(Util.Radius(Options, Metrics.CardRadius)),
	})
	if Options.Inset then
		Padding(Options.Inset).Parent = Frame
	end
	return Frame
end
local function Reveal(Picture, Target)
	local function Show()
		Tween(Picture, { ImageTransparency = Target or 0 }, "fade")
	end
	if Picture.IsLoaded then
		task.defer(Show)
	else
		Picture:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if Picture.IsLoaded then
				Show()
			end
		end)
		task.delay(3, Show)
	end
end
function Controls.Image(Container, Options)
	local Handle = {}
	local Height = Options.Height or 140
	local Built = Block(Container, Options, Height + (Options.Caption and 18 or 0))
	local Holder = Well(Built.Content, Options, Height)
	local Picture = New("ImageLabel", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Image                  = Util.Asset(Options.Image),
		ImageTransparency      = 1,
		ImageColor3            = Options.ImageColor or Theme.White,
		ScaleType              = Util.ScaleType(Options.Fit),
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	Reveal(Picture, Options.Transparency)
	local Caption = nil
	if Options.Caption then
		Caption = Text({
			Parent           = Built.Content,
			Text             = Options.Caption,
			TextSize         = Metrics.CaptionSize,
			TextTransparency = Theme.TextTertiary,
			TextWrapped      = true,
			Position         = UDim2.new(0, 0, 0, Height + 4),
			Size             = UDim2.new(1, 0, 0, 0),
		})
	end
	function Handle:Set(NewImage)
		Picture.ImageTransparency = 1
		Picture.Image = Util.Asset(NewImage)
		Reveal(Picture, Options.Transparency)
		return Handle
	end
	function Handle:SetCaption(NewCaption)
		if Caption then
			SwapText(Caption, NewCaption)
		end
		return Handle
	end
	function Handle:SetBackground(Fill, Alpha)
		if Fill == false then
			Tween(Holder, { BackgroundTransparency = 1 }, "fade")
		else
			Holder.BackgroundColor3 = Fill or Theme.EmbedColor
			Tween(Holder, { BackgroundTransparency = Alpha or 0 }, "fade")
		end
		return Handle
	end
	Handle.Picture = Picture
	Handle.Well = Holder
	return BlockHandle(Built, Handle, Options)
end
function Controls.Icon(Container, Options)
	local Handle = {}
	local Size = Options.Size or 24
	local Built = Row(Container, Util.Merge(Options, { Reserve = Size }))
	Built:Reserve(Size)
	local Fill, Alpha = Util.Surface(Options, Theme.EmbedColor, 1)
	local Picture = New("ImageLabel", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Fill,
		BackgroundTransparency = Alpha,
		BorderSizePixel        = 0,
		Image                  = Util.Asset(Options.Image),
		ImageColor3            = Options.ImageColor or Theme.White,
		ImageTransparency      = 1,
		ScaleType              = Util.ScaleType(Options.Fit),
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Size, 0, Size),
	}, {
		Corner(Util.Radius(Options, 0)),
	})
	Reveal(Picture, Options.Transparency)
	function Handle:Set(NewImage)
		Picture.Image = Util.Asset(NewImage)
		return Handle
	end
	Handle.Picture = Picture
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end
function Controls.Gallery(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Height = Options.Height or 96
	local Width = Options.Width or 140
	local Value = Options.Default
	local Cells = {}
	local Built = Block(Container, Options, Height)
	local Sheet = New("ScrollingFrame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.X,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.X,
		ClipsDescendants       = true,
	}, {
		Strip(Options.Gap or 8),
	})
	local Scroller = Scroll.Attach(Sheet, "X", { Depth = 26 })
	local function Render()
		for _, Cell in Cells do
			local On = Cell.Item == Value
			Tween(Cell.Ring, { Transparency = On and 0.2 or 1 }, "hover")
			Tween(Cell.Picture, { ImageTransparency = On and 0 or (Options.Dim or 0.25) }, "fade")
		end
	end
	for Index, Item in Items do
		local Image = type(Item) == "table" and Item.Image or Item
		local Cell = New("Frame", {
			Parent                 = Sheet,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(0, Width, 1, 0),
			LayoutOrder            = Index,
		})
		local Holder = Well(Cell, Options)
		local Picture = New("ImageLabel", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Image),
			ImageTransparency      = 1,
			ScaleType              = Util.ScaleType(Options.Fit, Enum.ScaleType.Fit),
			Size                   = UDim2.new(1, 0, 1, 0),
		})
		Reveal(Picture, Options.Dim or 0.25)
		local Ring = Util.Stroke(Colour(Options, Theme.White), 1, 1)
		Ring.Parent = Holder
		if type(Item) == "table" and Item.Label then
			Text({
				Parent           = Holder,
				Text             = Item.Label,
				TextSize         = Metrics.CaptionSize,
				TextTransparency = 0,
				TextYAlignment   = Enum.TextYAlignment.Bottom,
				AnchorPoint      = Vector2.new(0, 1),
				Position         = UDim2.new(0, 6, 1, -4),
				Size             = UDim2.new(1, -12, 0, 14),
				AutomaticSize    = Enum.AutomaticSize.None,
				ZIndex           = 3,
			})
		end
		local Button = New("TextButton", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 4,
		})
		Cells[Index] = { Item = Item, Picture = Picture, Ring = Ring, Cell = Holder }
		Button.Activated:Connect(function()
			Handle:Set(Item)
			if Options.Expand ~= false then
				Handle:Expand(Index)
			end
		end)
	end
	local Open = nil
	function Handle:Expand(Index)
		local Cell = Cells[Index]
		if not Cell or Open then
			return Handle
		end
		local Layer = Screen.Get()
		local From = Cell.Cell
		if From.AbsoluteSize.X < 2 then
			return Handle
		end
		local Scrim = New("TextButton", {
			Name                   = "GalleryBackdrop",
			Parent                 = Layer,
			BackgroundColor3       = Theme.Scrim,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 400,
		})
		Screen.Cover(Scrim)
		local Start = From.AbsolutePosition - Layer.AbsolutePosition
		local Span = From.AbsoluteSize
		local Big = New("ImageLabel", {
			Name                   = "Expanded",
			Parent                 = Layer,
			BackgroundColor3       = Theme.EmbedColor,
			BackgroundTransparency = Theme.EmbedTransparency,
			BorderSizePixel        = 0,
			Image                  = Cell.Picture.Image,
			ScaleType              = Enum.ScaleType.Fit,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0, Start.X + Span.X / 2, 0, Start.Y + Span.Y / 2),
			Size                   = UDim2.new(0, Span.X, 0, Span.Y),
			ZIndex                 = 401,
		}, {
			Corner(Util.Radius(Options, Metrics.CardRadius)),
		})
		local Room = Layer.AbsoluteSize
		local Wide = math.max(120, Room.X - 120)
		local Tall = math.max(120, Room.Y - 120)
		Tween(Scrim, { BackgroundTransparency = Options.Wash or 0.35 }, "enter")
		Tween(Big, {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, Wide, 0, Tall),
		}, "expand")
		local function Shut()
			if not Open then
				return
			end
			Open = nil
			Tween(Scrim, { BackgroundTransparency = 1 }, "exit")
			Tween(Big, {
				Position = UDim2.new(0, Start.X + Span.X / 2, 0, Start.Y + Span.Y / 2),
				Size = UDim2.new(0, Span.X, 0, Span.Y),
			}, "exit")
			task.delay(MotionTime("exit") * 1.2, function()
				Scrim:Destroy()
				Big:Destroy()
			end)
		end
		Open = { Close = Shut }
		Scrim.Activated:Connect(Shut)
		return Handle
	end
	function Handle:Collapse()
		if Open then
			Open.Close()
		end
		return Handle
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	Render()
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		Scroller:Destroy()
		Handle:Collapse()
	end)
	return Result
end
function Controls.Viewport(Container, Options)
	local Handle = {}
	local Height = Options.Height or 160
	local Built = Block(Container, Options, Height)
	local Holder = Well(Built.Content, Options, Height)
	local Frame = New("ViewportFrame", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		Ambient                = Options.Ambient or Color3.fromRGB(160, 160, 160),
		LightColor             = Options.LightColor or Color3.fromRGB(255, 255, 255),
		LightDirection         = Options.LightDirection or Vector3.new(-1, -1, -1),
	})
	local Camera = New("Camera", { Parent = Frame })
	Frame.CurrentCamera = Camera
	local Model = nil
	local Yaw = Options.Yaw or 0
	local Pitch = Options.Pitch or math.rad(-12)
	local Distance = Options.Distance or 0
	local function Aim()
		if not Model then
			return
		end
		local Centre, Size = nil, Vector3.zero
		if Model:IsA("Model") then
			local Ok, Box = pcall(function()
				return Model:GetBoundingBox()
			end)
			if Ok then
				Centre, Size = Box.Position, select(2, Model:GetBoundingBox())
			end
		elseif Model:IsA("BasePart") then
			Centre, Size = Model.Position, Model.Size
		end
		if not Centre then
			return
		end
		local Reach = Distance > 0 and Distance or math.max(Size.Magnitude, 1) * 1.1
		local Offset = CFrame.fromEulerAnglesYXZ(Pitch, Yaw, 0) * CFrame.new(0, 0, Reach)
		Camera.CFrame = CFrame.new(Centre) * Offset
		Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Centre)
	end
	function Handle:SetModel(Instance_)
		if Model then
			Model:Destroy()
		end
		Model = Instance_ and Instance_:Clone() or nil
		if Model then
			Model.Parent = Frame
			task.defer(Aim)
		end
		return Handle
	end
	function Handle:SetAngle(NewYaw, NewPitch)
		Yaw = NewYaw or Yaw
		Pitch = NewPitch or Pitch
		Aim()
		return Handle
	end
	function Handle:SetDistance(NewDistance)
		Distance = NewDistance
		Aim()
		return Handle
	end
	local function Placeholder()
		local Model = Instance.new("Model")
		Model.Name = "Placeholder"
		local Reach = 2
		local Thin = 0.06
		for Axis = 1, 3 do
			for First = -1, 1, 2 do
				for Second = -1, 1, 2 do
					local Size, Offset
					if Axis == 1 then
						Size = Vector3.new(Reach * 2, Thin, Thin)
						Offset = Vector3.new(0, First * Reach, Second * Reach)
					elseif Axis == 2 then
						Size = Vector3.new(Thin, Reach * 2, Thin)
						Offset = Vector3.new(First * Reach, 0, Second * Reach)
					else
						Size = Vector3.new(Thin, Thin, Reach * 2)
						Offset = Vector3.new(First * Reach, Second * Reach, 0)
					end
					local Bar = Instance.new("Part")
					Bar.Anchored = true
					Bar.CanCollide = false
					Bar.CastShadow = false
					Bar.Material = Enum.Material.SmoothPlastic
					Bar.Color = Options.PlaceholderColor or Theme.White
					Bar.Size = Size
					Bar.CFrame = CFrame.new(Offset)
					Bar.Parent = Model
				end
			end
		end
		local Core = Instance.new("Part")
		Core.Anchored = true
		Core.CanCollide = false
		Core.CastShadow = false
		Core.Material = Enum.Material.SmoothPlastic
		Core.Color = Options.PlaceholderColor or Theme.White
		Core.Transparency = 0.75
		Core.Size = Vector3.new(Reach, Reach, Reach)
		Core.CFrame = CFrame.new()
		Core.Parent = Model
		Model.PrimaryPart = Core
		return Model
	end
	if Options.Model then
		Handle:SetModel(Options.Model)
	elseif Options.Placeholder ~= false then
		local Stand = Placeholder()
		Handle:SetModel(Stand)
		Stand:Destroy()
	end
	local Stop = nil
	if Options.Drag ~= false then
		local Last = nil
		Stop = Draggable(Frame, Frame, function(X, Y)
			if Last then
				Yaw -= (X - Last.X) * math.pi * 2
				Pitch = Clamp(Pitch + (Y - Last.Y) * math.pi, -1.4, 1.4)
				Aim()
			end
			Last = Vector2.new(X, Y)
		end, function()
			Last = nil
		end)
	end
	local Spinning = Options.Spin == true
	if Spinning then
		task.spawn(function()
			while Spinning and Frame.Parent do
				Yaw += (Options.Speed or 0.6) * 0.03
				Aim()
				task.wait(0.03)
			end
		end)
	end
	function Handle:SetSpin(On)
		if On and not Spinning then
			Spinning = true
			task.spawn(function()
				while Spinning and Frame.Parent do
					Yaw += (Options.Speed or 0.6) * 0.03
					Aim()
					task.wait(0.03)
				end
			end)
		else
			Spinning = On == true
		end
		return Handle
	end
	Handle.Viewport = Frame
	Handle.Camera = Camera
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		Spinning = false
		if Stop then
			Stop()
		end
	end)
	return Result
end
function Controls.Video(Container, Options)
	local Handle = {}
	local Height = Options.Height or 160
	local Built = Block(Container, Options, Height + 16)
	local Holder = Well(Built.Content, Options, Height)
	local Frame = New("VideoFrame", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		Video                  = Util.Asset(Options.Video),
		Looped                 = Options.Loop == true,
		Volume                 = Options.Volume or 1,
	})
	local Track = New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.85,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, 0, 0, Height + 8),
		Size                   = UDim2.new(1, 0, 0, 2),
	})
	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
	})
	local Play = New("TextButton", {
		Parent                 = Holder,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.4,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, 34, 0, 34),
		ZIndex                 = 4,
	}, {
		Corner(17),
	})
	for Index = 1, 2 do
		New("Frame", {
			Parent                 = Play,
			BackgroundColor3       = Theme.White,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 1, 0.5, Index == 1 and -3 or 3),
			Size                   = UDim2.new(0, 12, 0, 2),
			Rotation               = Index == 1 and 32 or -32,
			ZIndex                 = 5,
		})
	end
	local Playing = false
	local function Sync()
		Play.Visible = not Playing
		local Length = Frame.TimeLength
		if Length > 0 then
			Tween(Fill, { Size = UDim2.new(Clamp(Frame.TimePosition / Length, 0, 1), 0, 1, 0) }, "hover")
		end
	end
	Play.Activated:Connect(function()
		Playing = true
		Frame:Play()
		Sync()
	end)
	Frame.Ended:Connect(function()
		Playing = false
		Sync()
	end)
	local Ticking = true
	task.spawn(function()
		while Ticking and Frame.Parent do
			if Playing then
				Sync()
			end
			task.wait(0.2)
		end
	end)
	function Handle:Play()
		Playing = true
		Frame:Play()
		Sync()
		return Handle
	end
	function Handle:Pause()
		Playing = false
		Frame:Pause()
		Sync()
		return Handle
	end
	function Handle:Set(NewVideo)
		Frame.Video = Util.Asset(NewVideo)
		return Handle
	end
	Handle.Video = Frame
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		Ticking = false
	end)
	return Result
end
function Controls.Audio(Container, Options)
	local Handle = {}
	local Built = Block(Container, Options, 34)
	local Sound = New("Sound", {
		Parent   = Built.Frame,
		SoundId  = Util.Asset(Options.Sound),
		Volume   = Options.Volume or 0.5,
		Looped   = Options.Loop == true,
	})
	Strip(10).Parent = Built.Content
	local Play = New("TextButton", {
		Parent                 = Built.Content,
		BackgroundColor3       = Colour(Options, Theme.White),
		BackgroundTransparency = 0.86,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 24, 0, 24),
		LayoutOrder            = 1,
	}, {
		Corner(Round(Options, 12)),
	})
	local Arms = {}
	for Index = 1, 2 do
		Arms[Index] = New("Frame", {
			Parent                 = Play,
			BackgroundColor3       = Theme.White,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 1, 0.5, Index == 1 and -2 or 2),
			Size                   = UDim2.new(0, 9, 0, 2),
			Rotation               = Index == 1 and 32 or -32,
			ZIndex                 = 2,
		})
	end
	local Bar = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -100, 1, 0),
		LayoutOrder            = 2,
	})
	local Track = New("Frame", {
		Parent                 = Bar,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.85,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(1, 0, 0, 2),
	})
	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
	})
	local Clock = Text({
		Parent           = Built.Content,
		Text             = "0:00",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(0, 44, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
		LayoutOrder      = 3,
	})
	local function Stamp(Seconds)
		local Whole = math.max(0, math.floor(Seconds))
		return string.format("%d:%02d", Whole // 60, Whole % 60)
	end
	local Playing = false
	local function Sync()
		local Length = Sound.TimeLength
		if Length > 0 then
			Tween(Fill, { Size = UDim2.new(Clamp(Sound.TimePosition / Length, 0, 1), 0, 1, 0) }, "hover")
		end
		Clock.Text = Stamp(Sound.TimePosition)
		for Index, Arm in Arms do
			Arm.Rotation = Playing and 0 or (Index == 1 and 32 or -32)
			Arm.Position = Playing
				and UDim2.new(0.5, Index == 1 and -3 or 3, 0.5, 0)
				or UDim2.new(0.5, 1, 0.5, Index == 1 and -2 or 2)
			Arm.Size = Playing and UDim2.new(0, 2, 0, 10) or UDim2.new(0, 9, 0, 2)
		end
	end
	Play.Activated:Connect(function()
		Playing = not Playing
		if Playing then
			Sound:Resume()
		else
			Sound:Pause()
		end
		Sync()
	end)
	local Stop = Draggable(Bar, Track, function(X)
		if Sound.TimeLength > 0 then
			Sound.TimePosition = X * Sound.TimeLength
			Sync()
		end
	end)
	local Ticking = true
	task.spawn(function()
		while Ticking and Built.Frame.Parent do
			if Playing then
				Sync()
			end
			task.wait(0.25)
		end
	end)
	function Handle:Play()
		Playing = true
		Sound:Play()
		Sync()
		return Handle
	end
	function Handle:Pause()
		Playing = false
		Sound:Pause()
		Sync()
		return Handle
	end
	function Handle:Set(NewSound)
		Sound.SoundId = Util.Asset(NewSound)
		return Handle
	end
	Handle.Sound = Sound
	Sync()
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		Ticking = false
		Stop()
		Sound:Stop()
	end)
	return Result
end
function Controls.Marquee(Container, Options)
	local Handle = {}
	local Frame = New("Frame", {
		Name                   = "Marquee",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 18),
		ClipsDescendants       = true,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, Metrics.RowPadding),
	})
	local Label = Text({
		Parent           = Frame,
		Text             = Options.Text or "",
		FontFace         = Options.Mono and Theme.FontMono or Theme.Font,
		TextSize         = Options.TextSize or (Metrics.ValueSize),
		TextTransparency = Theme.TextSecondary,
		TextYAlignment   = Enum.TextYAlignment.Center,
		AutomaticSize    = Enum.AutomaticSize.X,
		Size             = UDim2.new(0, 0, 1, 0),
	})
	local Running = true
	task.spawn(function()
		while Running and Frame.Parent do
			local Span = Label.AbsoluteSize.X
			local View = Frame.AbsoluteSize.X
			if Span > View and View > 0 then
				Label.Position = UDim2.new(0, View, 0, 0)
				local Distance = View + Span
				local Time = Distance / (Options.Speed or 40)
				Tween(Label, { Position = UDim2.new(0, -Span, 0, 0) },
					{ Duration = Time, Easing = "linear" })
				task.wait(Time + 0.2)
			else
				Label.Position = UDim2.new(0, 0, 0, 0)
				task.wait(1)
			end
		end
	end)
	function Handle:Set(NewText)
		Label.Text = NewText
		return Handle
	end
	return Common(Handle, Frame, Options, {
		Destroy = function()
			Running = false
		end,
	})
end
return Controls
end
KuikModules["Controls/More"] = function()
local UserInputService = game:GetService("UserInputService")
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Scroll  = KuikRequire("Scroll")
local Screen  = KuikRequire("Screen")
local Shared  = KuikRequire("Shared")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Keycap  = Util.Keycap
local Clamp   = Util.Clamp
local Round   = Util.Round
local Colour  = Util.Colour
local Hex     = Util.Hex
local Tween      = Motion.Tween
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Row         = Parts.Row
local Block       = Parts.Block
local Common      = Parts.Common
local BlockHandle = Parts.BlockHandle
local Draggable   = Parts.Draggable
local Controls = {}
function Controls.Skeleton(Container, Options)
	local Handle = {}
	local Lines = Options.Lines or 3
	local Frame = New("Frame", {
		Name                   = "Skeleton",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(6, Metrics.RowPadding),
		List(Options.Gap or 8),
	})
	local Bars = {}
	local Widths = { 1, 0.92, 0.78, 0.86, 0.64 }
	for Index = 1, Lines do
		Bars[Index] = New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.9,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(Widths[(Index - 1) % #Widths + 1], 0, 0, Options.Height or 10),
			LayoutOrder            = Index,
		}, {
			Corner(Util.Radius(Options, 2)),
		})
	end
	local Running = true
	task.spawn(function()
		local Up = true
		while Running and Frame.Parent do
			for _, Bar in Bars do
				Tween(Bar, { BackgroundTransparency = Up and 0.82 or 0.94 }, "fade")
			end
			Up = not Up
			task.wait(0.6)
		end
	end)
	function Handle:Stop()
		Running = false
		return Handle
	end
	return Common(Handle, Frame, Options, {
		Destroy = function()
			Running = false
		end,
	})
end
function Controls.Well(Container, Options, Owner)
	local Handle = {}
	local Fill, Alpha = Util.Surface(Options, Theme.EmbedColor, Theme.EmbedTransparency)
	local Frame = New("Frame", {
		Name                   = "Well",
		Parent                 = Container,
		BackgroundColor3       = Fill,
		BackgroundTransparency = Alpha,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 0),
		AutomaticSize          = Options.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		ClipsDescendants       = Options.Clip ~= false,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Util.Radius(Options, Metrics.CardRadius)),
		Padding(Options.Inset or 10),
		List(Options.Gap or Metrics.RowGap),
	})
	if Options.Stroke ~= false then
		Stroke(Options.Color or Theme.White, 0.85, 1).Parent = Frame
	end
	local Order = 0
	function Handle:_Mount()
		return Frame
	end
	function Handle:_Order()
		Order += 1
		return Order
	end
	function Handle:_Overlay()
		return Owner and Owner._Overlay and Owner:_Overlay() or nil
	end
	function Handle:_Register(Close)
		if Owner and Owner._Register then
			Owner:_Register(Close)
		end
	end
	function Handle:_Window()
		return Owner and Owner._Window and Owner:_Window() or nil
	end
	Common(Handle, Frame, Options, {})
	return Shared.Attach(Handle)
end
function Controls.LoadMore(Container, Options)
	local Handle = {}
	local Busy = false
	local Done = false
	local Frame = New("Frame", {
		Name                   = "LoadMore",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 30),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, Metrics.RowPadding),
	})
	local Accent = Colour(Options, Theme.White)
	local Label = Text({
		Parent           = Frame,
		Text             = Options.Label or "Load more",
		TextColor3       = Accent,
		FontFace         = Theme.FontMedium,
		TextSize         = Metrics.ValueSize,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Center,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local function Bar(Side)
		return New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Accent,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(Side, 0.5),
			Position               = UDim2.new(Side, 0, 0.5, 0),
			Size                   = UDim2.new(0.32, 0, 0, 1),
		})
	end
	local Left, Right = Bar(0), Bar(1)
	local Button = New("TextButton", {
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	Button.MouseEnter:Connect(function()
		if not Done then
			Tween(Label, { TextTransparency = 0 }, "hover")
			Tween(Left, { BackgroundTransparency = 0.2 }, "hover")
			Tween(Right, { BackgroundTransparency = 0.2 }, "hover")
		end
	end)
	Button.MouseLeave:Connect(function()
		Tween(Label, { TextTransparency = Theme.TextSecondary }, "hover")
		Tween(Left, { BackgroundTransparency = Theme.RuleTransparency }, "hover")
		Tween(Right, { BackgroundTransparency = Theme.RuleTransparency }, "hover")
	end)
	Button.Activated:Connect(function()
		if Busy or Done or Handle:IsDisabled() or not Options.Callback then
			return
		end
		Busy = true
		SwapText(Label, Options.Loading or "Loading")
		task.spawn(function()
			local More = Options.Callback(Handle)
			Busy = false
			if More == false then
				Handle:Finish()
			else
				SwapText(Label, Options.Label or "Load more")
			end
		end)
	end)
	function Handle:Finish(Message)
		Done = true
		Button.Active = false
		SwapText(Label, Message or Options.Empty or "Nothing more")
		Tween(Label, { TextTransparency = Theme.TextDisabled }, "fade")
		return Handle
	end
	function Handle:Reset()
		Done = false
		Busy = false
		Button.Active = true
		SwapText(Label, Options.Label or "Load more")
		return Handle
	end
	return Common(Handle, Frame, Options, { Inputs = { Button } })
end
function Controls.Kanban(Container, Options, Owner)
	local Handle = {}
	local Columns = Options.Columns or {}
	local Built = Block(Container, Options, Options.Height or 200)
	Strip(Options.Gap or 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top).Parent = Built.Content
	local Lanes = {}
	for Index, Column in Columns do
		local Lane = New("Frame", {
			Name                   = "Lane",
			Parent                 = Built.Content,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.96,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1 / #Columns, -(Options.Gap or 8), 1, 0),
			LayoutOrder            = Index,
		}, {
			Corner(Util.Radius(Options, Metrics.RowRadius)),
			Padding(8, 8),
			List(6),
		})
		Text({
			Parent           = Lane,
			Text             = tostring(Column.Label or Column),
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			LayoutOrder      = 1,
		})
		New("Frame", {
			Parent                 = Lane,
			BackgroundColor3       = Column.Color or Colour(Options, Theme.White),
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 1),
			LayoutOrder            = 2,
		})
		local Sheet = New("ScrollingFrame", {
			Parent                 = Lane,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 1, -22),
			CanvasSize             = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize    = Enum.AutomaticSize.Y,
			ScrollBarThickness     = 0,
			ScrollingDirection     = Enum.ScrollingDirection.Y,
			ClipsDescendants       = true,
			LayoutOrder            = 3,
		}, {
			List(4),
		})
		Scroll.Attach(Sheet, "Y", { Depth = 12 })
		local Cards = {}
		local function Add(Card)
			local Ticket = New("TextButton", {
				Parent                 = Sheet,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.RowTransparency,
				BorderSizePixel        = 0,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 0, 0),
				AutomaticSize          = Enum.AutomaticSize.Y,
				LayoutOrder            = #Cards + 1,
			}, {
				Corner(Util.Radius(Options, Metrics.RowRadius)),
				Padding(7, 8),
				List(2),
			})
			Text({
				Parent      = Ticket,
				Text        = tostring(type(Card) == "table" and Card.Label or Card),
				TextSize    = Metrics.CaptionSize,
				TextWrapped = true,
				LayoutOrder = 1,
			})
			if type(Card) == "table" and Card.Text then
				Text({
					Parent           = Ticket,
					Text             = Card.Text,
					TextSize         = Metrics.TinySize,
					TextTransparency = Theme.TextTertiary,
					TextWrapped      = true,
					LayoutOrder      = 2,
				})
			end
			local Button = Ticket
			Ticket.MouseEnter:Connect(function()
				Tween(Ticket, { BackgroundTransparency = Theme.RowHoverTransparency }, "hover")
			end)
			Ticket.MouseLeave:Connect(function()
				Tween(Ticket, { BackgroundTransparency = Theme.RowTransparency }, "hover")
			end)
			Button.Activated:Connect(function()
				if Options.Callback then
					task.spawn(Options.Callback, Card, Column.Label or Column)
				end
			end)
			table.insert(Cards, Ticket)
			return Ticket
		end
		for _, Card in Column.Cards or {} do
			Add(Card)
		end
		Lanes[Index] = { Frame = Lane, Sheet = Sheet, Add = Add, Cards = Cards }
	end
	function Handle:Lane(Index)
		return Lanes[Index]
	end
	function Handle:Push(Index, Card)
		local Lane = Lanes[Index]
		if Lane then
			Lane.Add(Card)
		end
		return Handle
	end
	return BlockHandle(Built, Handle, Options)
end
function Controls.Compare(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Rows = Options.Rows or {}
	local Built = Block(Container, Options)
	List(2).Parent = Built.Content
	local Wide = Options.LabelWidth or 0.4
	local Share = (1 - Wide) / math.max(1, #Items)
	local function Line(Cells, Header, Order)
		local Frame = New("Frame", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, Header and 20 or 18),
			LayoutOrder            = Order,
		}, {
			Strip(0),
		})
		Text({
			Parent           = Frame,
			Text             = tostring(Cells[1] or ""),
			FontFace         = Header and Theme.FontMedium or Theme.Font,
			TextSize         = Metrics.CaptionSize,
			TextTransparency = Header and Theme.TextPrimary or Theme.TextSecondary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			Size             = UDim2.new(Wide, -6, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
			LayoutOrder      = 1,
		})
		for Index = 1, #Items do
			local Value = Cells[Index + 1]
			local Best = Options.Best == Index
			local Content = Value
			if Value == true then
				Content = "yes"
			elseif Value == false then
				Content = "-"
			end
			Text({
				Parent           = Frame,
				Text             = tostring(Content or ""),
				FontFace         = Header and Theme.FontMedium or Theme.FontMono,
				TextSize         = Header and (Metrics.CaptionSize) or Metrics.MonoBoldSize,
				TextColor3       = Best and Colour(Options, Theme.Accent) or Theme.White,
				TextTransparency = Best and 0 or (Header and Theme.TextPrimary or Theme.TextSecondary),
				TextXAlignment   = Enum.TextXAlignment.Center,
				TextYAlignment   = Enum.TextYAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Size             = UDim2.new(Share, -4, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
				LayoutOrder      = Index + 1,
			})
		end
		return Frame
	end
	local Head = { "" }
	for Index, Item in Items do
		Head[Index + 1] = Item
	end
	Line(Head, true, 1)
	New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 1),
		LayoutOrder            = 2,
	})
	local Body = {}
	local function Render()
		for _, Frame in Body do
			Frame:Destroy()
		end
		table.clear(Body)
		for Index, Cells in Rows do
			table.insert(Body, Line(Cells, false, Index + 2))
		end
	end
	function Handle:Set(NewRows)
		Rows = NewRows
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Treemap(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Built = Block(Container, Options, Options.Height or 140)
	local Canvas = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ClipsDescendants       = true,
	})
	local Tiles = {}
	local function Render()
		for _, Tile in Tiles do
			Tile:Destroy()
		end
		table.clear(Tiles)
		local Total = 0
		for _, Item in Items do
			Total += math.max(0, Item.Value or 0)
		end
		if Total <= 0 then
			return
		end
		local X, Y, Width, Height = 0, 0, 1, 1
		local Horizontal = true
		local Left = Total
		for Index, Item in Items do
			local Share = math.max(0, Item.Value or 0) / Left
			local Last = Index == #Items
			local TileWidth = Horizontal and (Last and Width or Width * Share) or Width
			local TileHeight = Horizontal and Height or (Last and Height or Height * Share)
			local Tile = New("Frame", {
				Parent                 = Canvas,
				BackgroundColor3       = Item.Color or Colour(Options, Theme.White),
				BackgroundTransparency = 0.2 + (Index % 3) * 0.14,
				BorderSizePixel        = 0,
				Position               = UDim2.new(X, 1, Y, 1),
				Size                   = UDim2.new(TileWidth, -2, TileHeight, -2),
			}, {
				Corner(Util.Radius(Options, 2)),
				Padding(4, 5),
			})
			Text({
				Parent           = Tile,
				Text             = tostring(Item.Label or ""),
				TextSize         = Metrics.TinySize,
				TextColor3       = Theme.Black,
				TextTransparency = 0.1,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Size             = UDim2.new(1, 0, 0, 12),
				AutomaticSize    = Enum.AutomaticSize.None,
			})
			table.insert(Tiles, Tile)
			if Horizontal then
				X += TileWidth
				Width -= TileWidth
			else
				Y += TileHeight
				Height -= TileHeight
			end
			Left -= math.max(0, Item.Value or 0)
			Horizontal = not Horizontal
		end
	end
	function Handle:Set(NewItems)
		Items = NewItems
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Motd(Container, Options)
	local Handle = {}
	local Accent = Colour(Options, Theme.Accent)
	local Frame = New("Frame", {
		Name                   = "Motd",
		Parent                 = Container,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = select(2, Util.Surface(Options, Theme.EmbedColor, 0.4)),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(10, 12),
		List(4),
	})
	Stroke(Accent, 0.7, 1).Parent = Frame
	if Options.Label then
		Text({
			Parent           = Frame,
			Text             = Options.Label,
			FontFace         = Theme.FontMono,
			TextColor3       = Accent,
			TextSize         = Metrics.MonoBoldSize,
			TextTransparency = 0,
			LayoutOrder      = 1,
		})
	end
	local Body = Text({
		Parent           = Frame,
		Text             = Options.Text or "",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoBoldSize,
		TextTransparency = Theme.TextSecondary,
		TextWrapped      = true,
		LayoutOrder      = 2,
	})
	function Handle:Set(NewText)
		SwapText(Body, NewText)
		return Handle
	end
	return Common(Handle, Frame, Options, { Description = Body })
end
function Controls.AsciiBar(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0
	local Maximum = Options.Max or 1
	local Cells = Options.Cells or 24
	local Full = Options.Full or "="
	local Empty = Options.Empty or "-"
	local Built = Row(Container, Util.Merge(Options, { Reserve = Options.Width or 200 }))
	Built:Reserve(Options.Width or 200)
	local Readout = Text({
		Parent           = Built.Mount,
		Text             = "",
		FontFace         = Theme.FontMono,
		TextColor3       = Colour(Options, Theme.White),
		TextSize         = Metrics.MonoBoldSize,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local function Render()
		local Alpha = Maximum > 0 and Clamp(Value / Maximum, 0, 1) or 0
		local Lit = math.floor(Alpha * Cells + 0.5)
		Readout.Text = string.format("[%s%s] %3d%%",
			string.rep(Full, Lit),
			string.rep(Empty, Cells - Lit),
			math.floor(Alpha * 100 + 0.5))
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue)
		Value = NewValue
		Render()
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end
function Controls.Kbd(Container, Options)
	local Handle = {}
	local Built = Row(Container, Util.Merge(Options, { Reserve = Options.Width or 150 }))
	Built:Reserve(Options.Width or 150)
	local Strip_ = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(1, 0, 0, 20),
	}, {
		Strip(5, Enum.HorizontalAlignment.Right),
	})
	for Index, Key in Options.Keys or {} do
		local Cap = New("Frame", {
			Parent                 = Strip_,
			BackgroundColor3       = Theme.Black,
			BackgroundTransparency = Theme.ChipTransparency,
			BorderSizePixel        = 0,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			LayoutOrder            = Index,
		}, {
			Corner(Util.Radius(Options, 3)),
			Padding(0, 6),
			Stroke(Theme.White, 0.75, 1),
		})
		New("TextLabel", {
			Parent                 = Cap,
			BackgroundTransparency = 1,
			Text                   = typeof(Key) == "EnumItem" and Key.Name or tostring(Key),
			TextColor3             = Theme.White,
			TextTransparency       = Theme.TextSecondary,
			FontFace               = Theme.FontMono,
			TextSize               = Metrics.MonoSize,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
		})
	end
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end
function Controls.Scrubber(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0
	local Length = Options.Length or 100
	local Built = Row(Container, Util.Merge(Options, { Reserve = 90, Gap = 10 }))
	Built:Reserve(90)
	local function Stamp(Seconds)
		local Whole = math.max(0, math.floor(Seconds))
		return string.format("%d:%02d", Whole // 60, Whole % 60)
	end
	local Clock = Text({
		Parent           = Built.Mount,
		Text             = "",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Foot = Built:Foot(16)
	local Track = New("Frame", {
		Parent                 = Foot,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.85,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(1, 0, 0, 2),
	}, {
		Corner(1),
	})
	local Buffer = New("Frame", {
		Parent                 = Track,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.6,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, 0, 1, 0),
	})
	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
		ZIndex           = 2,
	})
	local Head = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0, 0, 0.5, 0),
		Size             = UDim2.new(0, 3, 0, 10),
		ZIndex           = 3,
	})
	local function Render(Role)
		local Alpha = Length > 0 and Clamp(Value / Length, 0, 1) or 0
		Clock.Text = string.format("%s / %s", Stamp(Value), Stamp(Length))
		Tween(Fill, { Size = UDim2.new(Alpha, 0, 1, 0) }, Role or "snap")
		Tween(Head, { Position = UDim2.new(Alpha, 0, 0.5, 0) }, Role or "snap")
	end
	local Grab = New("TextButton", {
		Parent                 = Foot,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 4,
	})
	local Stop = Draggable(Grab, Track, function(X)
		if Handle:IsDisabled() then
			return
		end
		Value = X * Length
		Render("drag")
		if Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end)
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, NewLength)
		Value = NewValue
		Length = NewLength or Length
		Render()
		return Handle
	end
	function Handle:SetBuffered(Alpha)
		Tween(Buffer, { Size = UDim2.new(Clamp(Alpha, 0, 1), 0, 1, 0) }, "fade")
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Grab },
		Destroy = Stop,
	})
end
function Controls.Volume(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0.5
	local Muted = Options.Muted == true
	local Built = Row(Container, Util.Merge(Options, { Reserve = 150 }))
	Built:Reserve(150)
	local Bar = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(1, 0, 0, 18),
	}, {
		Strip(8),
	})
	local Speaker = New("TextButton", {
		Parent                 = Bar,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 16, 1, 0),
		LayoutOrder            = 1,
		ZIndex                 = 3,
	})
	New("Frame", {
		Parent                 = Speaker,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.TextSecondary,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 1, 0.5, 0),
		Size                   = UDim2.new(0, 4, 0, 6),
	})
	local Arcs = {}
	for Index = 1, 2 do
		Arcs[Index] = New("Frame", {
			Parent                 = Speaker,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.TextTertiary,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, 6 + Index * 3, 0.5, 0),
			Size                   = UDim2.new(0, 1, 0, 4 + Index * 4),
		})
	end
	local Well = New("Frame", {
		Parent                 = Bar,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -30, 1, 0),
		LayoutOrder            = 2,
	})
	local Track = New("Frame", {
		Parent                 = Well,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.85,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(1, 0, 0, 2),
	}, {
		Corner(1),
	})
	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		Size             = UDim2.new(Value, 0, 1, 0),
	})
	local function Render()
		local Shown = Muted and 0 or Value
		Tween(Fill, { Size = UDim2.new(Shown, 0, 1, 0) }, "snap")
		for Index, Arc in Arcs do
			Tween(Arc, {
				BackgroundTransparency = Shown > Index * 0.33 and Theme.TextTertiary or 1,
			}, "hover")
		end
	end
	local Stop = Draggable(Well, Track, function(X)
		if Handle:IsDisabled() then
			return
		end
		Muted = false
		Value = Clamp(X, 0, 1)
		Render()
		if Options.Callback then
			task.spawn(Options.Callback, Value, Muted)
		end
	end)
	Speaker.Activated:Connect(function()
		Muted = not Muted
		Render()
		if Options.Callback then
			task.spawn(Options.Callback, Muted and 0 or Value, Muted)
		end
	end)
	function Handle:Get()
		return Muted and 0 or Value, Muted
	end
	function Handle:Set(NewValue, Silent)
		Value = Clamp(NewValue, 0, 1)
		Muted = false
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value, false)
		end
		return Handle
	end
	function Handle:SetMuted(On)
		Muted = On == true
		Render()
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Speaker },
		Destroy = Stop,
	})
end
function Controls.Knob(Container, Options)
	local Handle = {}
	local Minimum = Options.Min or 0
	local Maximum = Options.Max or 1
	local Value = Clamp(Options.Default or Minimum, Minimum, Maximum)
	local Size = Options.Size or 40
	local Sweep = Options.Sweep or 280
	local Built = Row(Container, Util.Merge(Options, { Reserve = Size, MountHeight = Size }))
	Built:Reserve(Size)
	local Dial = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Size, 0, Size),
	}, {
		Corner(math.floor(Size / 2)),
		Stroke(Theme.White, 0.8, 1),
	})
	local Ticks = {}
	local Count = Options.Ticks or 20
	for Index = 1, Count do
		local Angle = math.rad(-90 - Sweep / 2 + (Index - 1) / (Count - 1) * Sweep)
		Ticks[Index] = New("Frame", {
			Parent                 = Dial,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.85,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, math.cos(Angle) * (Size / 2 - 3), 0.5, math.sin(Angle) * (Size / 2 - 3)),
			Size                   = UDim2.new(0, 3, 0, 1),
			Rotation               = math.deg(Angle),
		})
	end
	local Pointer = New("Frame", {
		Parent           = Dial,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 1),
		Position         = UDim2.new(0.5, 0, 0.5, 0),
		Size             = UDim2.new(0, 2, 0, Size / 2 - 6),
		ZIndex           = 3,
	})
	local Readout = Text({
		Parent         = Dial,
		Text           = "",
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
		ZIndex         = 4,
	})
	local function Render(Role)
		local Alpha = Maximum > Minimum and (Value - Minimum) / (Maximum - Minimum) or 0
		local Lit = math.floor(Alpha * Count + 0.5)
		Tween(Pointer, { Rotation = -Sweep / 2 + Alpha * Sweep }, Role or "snap")
		Readout.Text = Options.Format and Options.Format(Value)
			or Util.FormatNumber(Value, Options.Step or 0.01)
		for Index, Tick in Ticks do
			Tick.BackgroundTransparency = Index <= Lit and 0.1 or 0.85
		end
	end
	local Anchor = nil
	local Stop = Draggable(Dial, Dial, function(_, Y)
		if Handle:IsDisabled() then
			return
		end
		if not Anchor then
			Anchor = { Y = Y, Value = Value }
		end
		local Delta = (Anchor.Y - Y) * (Maximum - Minimum) * (Options.Sensitivity or 1.5)
		Value = Clamp(Util.Quantise(Anchor.Value + Delta, Options.Step or 0), Minimum, Maximum)
		Render("drag")
		if Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end, function()
		Anchor = nil
	end)
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = Clamp(NewValue, Minimum, Maximum)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Destroy = Stop,
	})
end
function Controls.VU(Container, Options)
	local Handle = {}
	local Channels = Options.Channels or 2
	local Segments = Options.Segments or 18
	local Built = Block(Container, Options, Options.Height or (Channels * 10))
	List(3).Parent = Built.Content
	local Rows = {}
	for Channel = 1, Channels do
		local Line = New("Frame", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 6),
			LayoutOrder            = Channel,
		}, {
			Strip(2),
		})
		local Cells = {}
		for Index = 1, Segments do
			local Warm = Index > Segments * 0.8
			local Hot = Index > Segments * 0.93
			Cells[Index] = New("Frame", {
				Parent                 = Line,
				BackgroundColor3       = Hot and Theme.Danger or Warm and Theme.Warn or Colour(Options, Theme.Good),
				BackgroundTransparency = 0.88,
				BorderSizePixel        = 0,
				Size                   = UDim2.new(1 / Segments, -2, 1, 0),
				LayoutOrder            = Index,
			})
		end
		Rows[Channel] = { Cells = Cells, Peak = 0 }
	end
	function Handle:Set(Levels)
		for Channel, Row_ in Rows do
			local Level = type(Levels) == "table" and Levels[Channel] or Levels or 0
			local Lit = math.floor(Clamp(Level, 0, 1) * Segments + 0.5)
			Row_.Peak = math.max(Row_.Peak - 0.02, Lit / Segments)
			local PeakCell = math.floor(Row_.Peak * Segments + 0.5)
			for Index, Cell in Row_.Cells do
				Cell.BackgroundTransparency = Index <= Lit and 0.05
					or Index == PeakCell and 0.4
					or 0.88
			end
		end
		return Handle
	end
	Handle:Set(0)
	return BlockHandle(Built, Handle, Options)
end
function Controls.Waveform(Container, Options)
	local Handle = {}
	local Values = Options.Values or {}
	local Height = Options.Height or 54
	local Built = Block(Container, Options, Height)
	local Canvas = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ClipsDescendants       = true,
	}, {
		Strip(1),
	})
	local Bars = {}
	local Played = 0
	local function Render()
		for _, Bar in Bars do
			Bar:Destroy()
		end
		table.clear(Bars)
		local Count = #Values
		if Count == 0 then
			return
		end
		for Index, Sample in Values do
			local Reach = Clamp(math.abs(Sample), 0, 1)
			local Before = Index / Count <= Played
			Bars[Index] = New("Frame", {
				Parent                 = Canvas,
				BackgroundColor3       = Before and Colour(Options, Theme.Accent) or Theme.White,
				BackgroundTransparency = Before and 0.1 or 0.72,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0, 0.5),
				Position               = UDim2.new(0, 0, 0.5, 0),
				Size                   = UDim2.new(1 / Count, -1, Reach, 0),
				LayoutOrder            = Index,
			})
		end
	end
	function Handle:Set(NewValues)
		Values = NewValues
		Render()
		return Handle
	end
	function Handle:SetPlayed(Alpha)
		Played = Clamp(Alpha, 0, 1)
		Render()
		return Handle
	end
	Render()
	return BlockHandle(Built, Handle, Options)
end
function Controls.Zoom(Container, Options)
	local Handle = {}
	local Height = Options.Height or 160
	local Lens = Options.Lens or 90
	local Mode = Options.Mode or "Loupe"
	local Least = Options.Min or 1
	local Most = Options.Max or 8
	local Factor = Clamp(Options.Factor or 2.5, Least, Most)
	local Step = Options.Step or 0.25
	local Built = Block(Container, Options, Height)
	local Fill, Alpha = Util.Surface(Options, Theme.EmbedColor, Theme.EmbedTransparency)
	local Well = New("Frame", {
		Name                   = "Well",
		Parent                 = Built.Content,
		BackgroundColor3       = Fill,
		BackgroundTransparency = Alpha,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ClipsDescendants       = true,
	}, {
		Corner(Util.Radius(Options, Metrics.CardRadius)),
	})
	local Picture = New("ImageLabel", {
		Name                   = "Picture",
		Parent                 = Well,
		BackgroundTransparency = 1,
		Image                  = Util.Asset(Options.Image),
		ScaleType              = Util.ScaleType(Options.Fit),
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	local Readout = nil
	if Options.Readout ~= false then
		Readout = Text({
			Parent                 = Well,
			Name                   = "Readout",
			Text                   = "1.0x",
			TextSize               = Metrics.MonoLargeSize,
			FontFace               = Theme.FontMono,
			TextXAlignment         = Enum.TextXAlignment.Right,
			TextTransparency       = Theme.TextSecondary,
			AnchorPoint            = Vector2.new(1, 1),
			Position               = UDim2.new(1, -6, 1, -4),
			Size                   = UDim2.new(0, 54, 0, 14),
			AutomaticSize          = Enum.AutomaticSize.None,
			ZIndex                 = 6,
		})
	end
	local function Announce()
		if Readout then
			Readout.Text = string.format("%.1fx", Factor)
		end
		if Options.Callback then
			task.spawn(Options.Callback, Factor)
		end
	end
	local Connections = {}
	local Apply, Track
	if Mode == "Pan" then
		local OffsetX, OffsetY = 0, 0
		Picture.Size = UDim2.new(0, 0, 0, 0)
		local function Bound()
			local Size = Well.AbsoluteSize
			local Span = Vector2.new(Size.X * Factor, Size.Y * Factor)
			OffsetX = Clamp(OffsetX, math.min(0, Size.X - Span.X), 0)
			OffsetY = Clamp(OffsetY, math.min(0, Size.Y - Span.Y), 0)
		end
		local Lights = Scroll.Edges(Well, { Depth = 30, ZIndex = 4 })
		local function Room()
			local Size = Well.AbsoluteSize
			local Over = Vector2.new(
				math.max(0, Size.X * Factor - Size.X),
				math.max(0, Size.Y * Factor - Size.Y))
			Lights:Set({
				Left   = Over.X > 0 and (-OffsetX) / Over.X or 0,
				Right  = Over.X > 0 and (Over.X + OffsetX) / Over.X or 0,
				Top    = Over.Y > 0 and (-OffsetY) / Over.Y or 0,
				Bottom = Over.Y > 0 and (Over.Y + OffsetY) / Over.Y or 0,
			})
		end
		Apply = function(Animate)
			local Size = Well.AbsoluteSize
			Bound()
			Picture.Size = UDim2.new(0, Size.X * Factor, 0, Size.Y * Factor)
			if Animate then
				Motion.Tween(Picture, { Position = UDim2.new(0, OffsetX, 0, OffsetY) }, "morph")
			else
				Motion.Halt(Picture, "Position")
				Picture.Position = UDim2.new(0, OffsetX, 0, OffsetY)
			end
			Room()
		end
		Track = function(X, Y, Next)
			local Size = Well.AbsoluteSize
			local PointX, PointY = X * Size.X, Y * Size.Y
			local ImageX = (PointX - OffsetX) / Factor
			local ImageY = (PointY - OffsetY) / Factor
			Factor = Clamp(Next, Least, Most)
			OffsetX = PointX - ImageX * Factor
			OffsetY = PointY - ImageY * Factor
			Apply(true)
			Announce()
		end
		local LastX, LastY = nil, nil
		local Stop = Draggable(Well, Well, function(X, Y)
			local Size = Well.AbsoluteSize
			if LastX then
				OffsetX += (X - LastX) * Size.X
				OffsetY += (Y - LastY) * Size.Y
				Apply(false)
			end
			LastX, LastY = X, Y
		end, function()
			LastX, LastY = nil, nil
		end)
		table.insert(Connections, Stop)
		function Handle:Pan(X, Y)
			OffsetX, OffsetY = X or OffsetX, Y or OffsetY
			Apply(true)
			return Handle
		end
	else
		local Loupe = New("Frame", {
			Name                   = "Loupe",
			Parent                 = Well,
			BackgroundColor3       = Theme.Scrim,
			BackgroundTransparency = 0.2,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Size                   = UDim2.new(0, Lens, 0, Lens),
			Visible                = false,
			ClipsDescendants       = true,
			ZIndex                 = 5,
		}, {
			Corner(Round(Options, math.floor(Lens / 2))),
			Stroke(Theme.White, 0.6, 1),
		})
		local Magnified = New("ImageLabel", {
			Name                   = "Magnified",
			Parent                 = Loupe,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Options.Image),
			ScaleType              = Util.ScaleType(Options.Fit),
			Size                   = UDim2.new(0, 0, 0, 0),
			ZIndex                 = 5,
		})
		local Crosshair = nil
		if Options.Crosshair then
			Crosshair = New("Frame", {
				Name                   = "Crosshair",
				Parent                 = Loupe,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 0.55,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, 0.5, 0),
				Size                   = UDim2.new(0, 1, 0, 9),
				ZIndex                 = 6,
			})
		end
		local LensX, LensY = 0.5, 0.5
		Apply = function()
			local Size = Well.AbsoluteSize
			local Wide, Tall = Size.X * Factor, Size.Y * Factor
			Magnified.Size = UDim2.new(0, Wide, 0, Tall)
			Magnified.Position = UDim2.new(0, Lens / 2 - LensX * Wide, 0, Lens / 2 - LensY * Tall)
			Loupe.Position = UDim2.new(LensX, 0, LensY, 0)
		end
		Track = function(X, Y, Next)
			LensX, LensY = X, Y
			if Next then
				Factor = Clamp(Next, Least, Most)
				Announce()
			end
			Loupe.Visible = true
			Apply()
		end
		local Stop = Draggable(Well, Well, function(X, Y)
			Track(X, Y)
		end, function()
			if not UserInputService.MouseEnabled then
				Loupe.Visible = false
			end
		end)
		table.insert(Connections, Stop)
		Handle.Loupe = Loupe
		Handle.Magnified = Magnified
		Handle.Crosshair = Crosshair
	end
	table.insert(Connections, Well:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		Apply(false)
	end))
	local Over = false
	local AtX, AtY = nil, nil
	table.insert(Connections, Well.MouseEnter:Connect(function()
		Over = true
	end))
	table.insert(Connections, Well.MouseLeave:Connect(function()
		Over = false
		AtX, AtY = nil, nil
		if Handle.Loupe then
			Handle.Loupe.Visible = false
		end
	end))
	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		if not Over then
			AtX, AtY = nil, nil
			return
		end
		AtX, AtY = Parts.Locate("Input", Input.Position, Well)
		if AtX and Options.Hover ~= false and Handle.Loupe then
			Track(AtX, AtY)
		end
	end))
	local Claim = Options.Wheel == nil and "Ctrl" or Options.Wheel
	if Claim ~= false then
		table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
			if Input.UserInputType ~= Enum.UserInputType.MouseWheel or not Over or not AtX then
				return
			end
			if Claim == "Ctrl" and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.LeftSuper)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightSuper)) then
				return
			end
			Track(AtX, AtY, Factor + Input.Position.Z * Step * math.max(1, Factor * 0.5))
		end))
	end
	function Handle:Set(NewImage)
		Picture.Image = Util.Asset(NewImage)
		if Handle.Magnified then
			Handle.Magnified.Image = Util.Asset(NewImage)
		end
		return Handle
	end
	function Handle:SetFactor(Next, Animate)
		Factor = Clamp(Next or Factor, Least, Most)
		Apply(Animate ~= false)
		Announce()
		return Handle
	end
	function Handle:GetFactor()
		return Factor
	end
	function Handle:Reset()
		return Handle:SetFactor(Options.Factor or 2.5, true)
	end
	Handle.Picture = Picture
	Handle.Well = Well
	Apply(false)
	Announce()
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		for _, Item in Connections do
			if type(Item) == "function" then
				Item()
			else
				Item:Disconnect()
			end
		end
		table.clear(Connections)
	end)
	return Result
end
function Controls.Carousel(Container, Options, Owner)
	local Handle = {}
	local Items = Options.Items or {}
	local At = 1
	local Deck = Options.Variant == "Deck"
	local Built = Block(Container, Options, (Options.Height or 120) + 16)
	local Window_ = New("Frame", {
		Name                   = "Viewport",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 120),
		ClipsDescendants       = Options.Clip ~= false,
	})
	local Rail = Deck and Window_ or New("Frame", {
		Name                   = "Rail",
		Parent                 = Window_,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(#Items, 0, 1, 0),
	}, {
		Strip(0),
	})
	local Dots = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 1),
		Position               = UDim2.new(0.5, 0, 1, 0),
		Size                   = UDim2.new(1, 0, 0, 12),
	}, {
		Strip(5, Enum.HorizontalAlignment.Center),
	})
	local Lights = Scroll.Edges(Window_, { Depth = 34, ZIndex = 4 })
	local function Arrow(Direction)
		local Button = New("TextButton", {
			Name                   = Direction < 0 and "Previous" or "Next",
			Parent                 = Window_,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			AnchorPoint            = Vector2.new(Direction < 0 and 0 or 1, 0.5),
			Position               = UDim2.new(Direction < 0 and 0 or 1, 0, 0.5, 0),
			Size                   = UDim2.new(0, 26, 1, 0),
			ZIndex                 = 6,
		})
		local Arms = {}
		for Index = 1, 2 do
			Arms[Index] = New("Frame", {
				Parent                 = Button,
				BackgroundColor3       = Colour(Options, Theme.White),
				BackgroundTransparency = 0.4,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, 0.5, Index == 1 and -4 or 4),
				Size                   = UDim2.new(0, 9, 0, 1),
				Rotation               = Direction * (Index == 1 and -45 or 45),
				ZIndex                 = 6,
			})
		end
		local function Light(On)
			for _, Arm in Arms do
				Tween(Arm, { BackgroundTransparency = On and 0 or 0.4 }, "hover")
			end
			Tween(Button, {
				Position = UDim2.new(Direction < 0 and 0 or 1, On and Direction * 3 or 0, 0.5, 0),
			}, "toss")
		end
		Button.MouseEnter:Connect(function() Light(true) end)
		Button.MouseLeave:Connect(function() Light(false) end)
		Button.Activated:Connect(function()
			Handle:Step(Direction)
		end)
		return Button
	end
	local Previous, Next = Arrow(-1), Arrow(1)
	local Marks = {}
	local Panes = {}
	for Index, Item in Items do
		local Pane = New("Frame", {
			Name                   = "Pane",
			Parent                 = Rail,
			BackgroundTransparency = 1,
			Size                   = Deck
				and UDim2.new(Options.Spread or 0.56, 0, 1, 0)
				or UDim2.new(1 / #Items, 0, 1, 0),
			AnchorPoint            = Deck and Vector2.new(0.5, 0.5) or Vector2.new(0, 0),
			Position               = Deck and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 0, 0, 0),
			LayoutOrder            = Index,
		}, {
			Padding(0, 4),
			List(6),
		})
		if Deck then
			New("UIScale", { Parent = Pane, Scale = 1 })
		end
		if type(Item) == "table" and Item.Image then
			New("ImageLabel", {
				Parent                 = Pane,
				BackgroundColor3       = Theme.EmbedColor,
				BackgroundTransparency = Theme.EmbedTransparency,
				BorderSizePixel        = 0,
				Image                  = Util.Asset(Item.Image),
				ScaleType              = Util.ScaleType(Options.Fit, Enum.ScaleType.Crop),
				Size                   = UDim2.new(1, 0, 1, Item.Label and -20 or 0),
				LayoutOrder            = 1,
			}, {
				Corner(Util.Radius(Options, Metrics.CardRadius)),
			})
		end
		if type(Item) == "table" and Item.Label then
			Text({
				Parent           = Pane,
				Text             = Item.Label,
				TextSize         = Metrics.CaptionSize,
				TextTransparency = Theme.TextSecondary,
				TextXAlignment   = Enum.TextXAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				LayoutOrder      = 2,
			})
		elseif type(Item) ~= "table" then
			Text({
				Parent           = Pane,
				Text             = tostring(Item),
				TextSize         = Metrics.BodySize,
				TextXAlignment   = Enum.TextXAlignment.Center,
				TextYAlignment   = Enum.TextYAlignment.Center,
				Size             = UDim2.new(1, 0, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
				LayoutOrder      = 1,
			})
		end
		Panes[Index] = Pane
		local Dot = New("Frame", {
			Parent                 = Dots,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = 0.8,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(0, 5, 0, 5),
			LayoutOrder            = Index,
		}, {
			Corner(3),
		})
		local Hit = New("TextButton", {
			Parent                 = Dot,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Position               = UDim2.new(0, -3, 0, -5),
			Size                   = UDim2.new(1, 6, 1, 10),
			ZIndex                 = 3,
		})
		Hit.Activated:Connect(function()
			Handle:Show(Index)
		end)
		Marks[Index] = Dot
	end
	local function Render(Animate)
		if Deck then
			local Step = Options.Step or 0.42
			local Shrink = Options.Shrink or 0.12
			local Dim = Options.Dim or 0.68
			local Tilt = Options.Tilt or 0
			for Index, Pane in Panes do
				local Away = Index - At
				local Depth = math.min(math.abs(Away), 3)
				local Place = UDim2.new(0.5 + Away * Step, 0, 0.5, 0)
				local Scale = 1 - Depth * Shrink
				local Alpha = Away == 0 and 0 or Dim
				Pane.ZIndex = 20 - Depth
				Pane.Visible = Depth <= (Options.Reach or 3)
				local Scaler = Pane:FindFirstChildOfClass("UIScale")
				if Animate == false then
					Motion.Halt(Pane, "Position")
					Pane.Position = Place
					Pane.Rotation = Away * Tilt
					if Scaler then
						Motion.Halt(Scaler, "Scale")
						Scaler.Scale = Scale
					end
				else
					Tween(Pane, { Position = Place, Rotation = Away * Tilt }, "layout")
					if Scaler then
						Tween(Scaler, { Scale = Scale }, "layout")
					end
				end
				for _, Item in Pane:GetDescendants() do
					if Item:IsA("ImageLabel") then
						Tween(Item, { ImageTransparency = Alpha },
							Animate == false and "instant" or "fade")
					end
				end
			end
		else
			local Target = UDim2.new(-(At - 1), 0, 0, 0)
			if Animate == false then
				Motion.Halt(Rail, "Position")
				Rail.Position = Target
			else
				Tween(Rail, { Position = Target }, "layout")
			end
		end
		for Index, Dot in Marks do
			Tween(Dot, { BackgroundTransparency = Index == At and 0 or 0.8 }, "hover")
			Tween(Dot, { Size = UDim2.new(0, Index == At and 12 or 5, 0, 5) }, "morph")
		end
		local Behind = (At - 1) / math.max(1, #Items - 1)
		local Ahead = (#Items - At) / math.max(1, #Items - 1)
		Lights:Set({
			Left   = Deck and 0 or Behind,
			Right  = Deck and 0 or Ahead,
			Top    = 0,
			Bottom = 0,
		}, Animate == false and "instant" or nil)
		Previous.Visible = At > 1
		Next.Visible = At < #Items
	end
	function Handle:Get()
		return At
	end
	function Handle:Show(Index, Silent)
		At = Clamp(Index, 1, math.max(1, #Items))
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, At, Items[At])
		end
		return Handle
	end
	function Handle:Next()
		return Handle:Show(At % math.max(1, #Items) + 1)
	end
	function Handle:Previous()
		return Handle:Show((At - 2) % math.max(1, #Items) + 1)
	end
	function Handle:Step(Direction)
		return Handle:Show(Clamp(At + Direction, 1, math.max(1, #Items)))
	end
	Render(false)
	if Options.Auto then
		local Running = true
		task.spawn(function()
			while Running and Built.Frame.Parent do
				task.wait(Options.Auto)
				Handle:Next()
			end
		end)
		local Result = BlockHandle(Built, Handle, Options)
		Result:OnDestroy(function()
			Running = false
		end)
		return Result
	end
	return BlockHandle(Built, Handle, Options)
end
function Controls.SplitButton(Container, Options, Owner)
	local Handle = {}
	local Width = Options.Width or 110
	local Accent = Colour(Options, Theme.White)
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Shell = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.TabHeight),
	}, {
		Strip(1, Enum.HorizontalAlignment.Right),
	})
	local Main = New("TextButton", {
		Parent                 = Shell,
		BackgroundColor3       = Accent,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, -26, 1, 0),
		LayoutOrder            = 1,
	}, {
		Corner(Round(Options, math.floor(Metrics.TabHeight / 2))),
	})
	local Items = Options.Items or {}
	local At = Clamp(Options.Default or 0, 0, #Items)
	local function Name(Item)
		if type(Item) == "table" then
			return tostring(Item.Label or Item.Text or Item.Name or "")
		end
		return tostring(Item)
	end
	local Caption = New("TextLabel", {
		Name                   = "Action",
		Parent                 = Main,
		BackgroundTransparency = 1,
		Text                   = At > 0 and Name(Items[At]) or (Options.Action or "Run"),
		TextColor3             = Theme.Black,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.ValueSize,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		TextXAlignment         = Enum.TextXAlignment.Center,
		Size                   = UDim2.new(1, -8, 1, 0),
		Position               = UDim2.new(0, 4, 0, 0),
		ZIndex                 = 2,
	})
	local Caret = New("TextButton", {
		Parent                 = Shell,
		BackgroundColor3       = Accent,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 25, 1, 0),
		LayoutOrder            = 2,
	}, {
		Corner(Round(Options, math.floor(Metrics.TabHeight / 2))),
	})
	local _, Arms = Util.Chevron(Caret, 10, "Down", 0)
	for _, Arm in Arms do
		Arm.BackgroundColor3 = Theme.Black
	end
	local Menu = nil
	function Handle:Run()
		local Item = Items[At]
		if type(Item) == "table" and Item.Callback then
			task.spawn(Item.Callback, Item, Handle)
		elseif Options.Callback then
			task.spawn(Options.Callback, Item, Handle)
		end
		return Handle
	end
	function Handle:Get()
		return At, Items[At]
	end
	function Handle:Select(Index, Silent)
		At = Clamp(Index, 1, math.max(1, #Items))
		SwapText(Caption, Name(Items[At]))
		if not Silent then
			if Options.Chose then
				task.spawn(Options.Chose, Items[At], At, Handle)
			end
			if Options.RunOnSelect ~= false then
				Handle:Run()
			end
		end
		return Handle
	end
	function Handle:SetAction(NewText)
		SwapText(Caption, tostring(NewText))
		return Handle
	end
	Main.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		Handle:Run()
	end)
	Caret.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		if not Menu then
			local Entries = {}
			for Index, Item in Items do
				if type(Item) == "table" and Item.Separator then
					table.insert(Entries, Item)
				else
					table.insert(Entries, {
						Label    = Name(Item),
						Shortcut = type(Item) == "table" and Item.Shortcut or nil,
						Color    = type(Item) == "table" and Item.Color or nil,
						Callback = function()
							Handle:Select(Index)
						end,
					})
				end
			end
			Menu = KuikRequire("Layers").Menu({
				Items = Entries,
				Width = Options.MenuWidth or 150,
				Parent = Owner and Owner._Overlay and Owner:_Overlay() or Screen.Get(),
			})
		end
		local Point = Caret.AbsolutePosition
		Menu:Show(Point.X, Point.Y + Caret.AbsoluteSize.Y + 4)
	end)
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Main, Caret },
		Destroy = function()
			if Menu then
				Menu:Destroy()
			end
		end,
	})
end
function Controls.Split(Container, Options, Owner)
	local Handle = {}
	local At = Clamp(Options.At or 0.5, 0.1, 0.9)
	local Vertical = Options.Vertical == true
	local Thickness = Options.Thickness or 7
	local Frame = New("Frame", {
		Name                   = "Split",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 180),
		LayoutOrder            = Options.LayoutOrder or 0,
		ClipsDescendants       = true,
	}, {
		Padding(0, Options.Inset or 0),
	})
	local function Pane(Name)
		local Sheet = New("Frame", {
			Name                   = Name,
			Parent                 = Frame,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 1, 0),
		}, {
			List(Options.Gap or 8),
		})
		local Order = 0
		local Each = { Frame = Sheet }
		function Each:_Mount()
			return Sheet
		end
		function Each:_Order()
			Order += 1
			return Order
		end
		function Each:_Overlay()
			return Owner and Owner._Overlay and Owner:_Overlay() or nil
		end
		function Each:_Register(Close)
			if Owner and Owner._Register then
				Owner:_Register(Close)
			end
		end
		function Each:_Window()
			return Owner and Owner._Window and Owner:_Window() or nil
		end
		return Shared.Attach(Each), Sheet
	end
	local Left, LeftFrame = Pane("First")
	local Right, RightFrame = Pane("Second")
	local Bar = New("Frame", {
		Name                   = "Divider",
		Parent                 = Frame,
		BackgroundColor3       = Colour(Options, Theme.White),
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		ZIndex                 = 4,
	})
	local Grip = New("TextButton", {
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		ZIndex                 = 5,
	})
	local function Place(Animate)
		local First = Vertical
			and UDim2.new(1, 0, At, -Thickness / 2)
			or UDim2.new(At, -Thickness / 2, 1, 0)
		local Second = Vertical
			and UDim2.new(1, 0, 1 - At, -Thickness / 2)
			or UDim2.new(1 - At, -Thickness / 2, 1, 0)
		local SecondAt = Vertical
			and UDim2.new(0, 0, At, Thickness / 2)
			or UDim2.new(At, Thickness / 2, 0, 0)
		if Animate == false then
			LeftFrame.Size = First
			RightFrame.Size = Second
			RightFrame.Position = SecondAt
		else
			Tween(LeftFrame, { Size = First }, "drag")
			Tween(RightFrame, { Size = Second, Position = SecondAt }, "drag")
		end
		Bar.Position = Vertical and UDim2.new(0.5, 0, At, 0) or UDim2.new(At, 0, 0.5, 0)
		Bar.Size = Vertical and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 1, 1, 0)
		Grip.Position = Bar.Position
		Grip.Size = Vertical and UDim2.new(1, 0, 0, Thickness * 2) or UDim2.new(0, Thickness * 2, 1, 0)
	end
	local Stop = Draggable(Grip, Frame, function(X, Y)
		if Handle:IsDisabled() then
			return
		end
		At = Clamp(Vertical and Y or X, Options.Min or 0.12, Options.Max or 0.88)
		Place(false)
		if Options.Callback then
			task.spawn(Options.Callback, At)
		end
	end)
	Grip.MouseEnter:Connect(function()
		Tween(Bar, { BackgroundTransparency = 0.1 }, "hover")
	end)
	Grip.MouseLeave:Connect(function()
		Tween(Bar, { BackgroundTransparency = Theme.RuleTransparency }, "hover")
	end)
	function Handle:Left()
		return Left
	end
	function Handle:Right()
		return Right
	end
	function Handle:Get()
		return At
	end
	function Handle:Set(Fraction, Animate)
		At = Clamp(Fraction, 0.05, 0.95)
		Place(Animate)
		return Handle
	end
	Place(false)
	return Common(Handle, Frame, Options, { Destroy = Stop })
end
function Controls.Empty(Container, Options)
	local Handle = {}
	local Built = Block(Container, Options, nil)
	local Middle = New("Frame", {
		Name                   = "Empty",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Padding(Options.Inset or 18, 0),
		List(8, nil, Enum.HorizontalAlignment.Center),
	})
	local Mark = New("Frame", {
		Name                   = "Mark",
		Parent                 = Middle,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 18, 0, 18),
		Rotation               = 45,
		LayoutOrder            = 1,
	}, {
		Stroke(Colour(Options, Theme.White), Theme.TextDisabled, 1),
	})
	if Options.Icon then
		Mark.Rotation = 0
		New("ImageLabel", {
			Parent                 = Mark,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Options.Icon),
			ImageColor3            = Colour(Options, Theme.White),
			ImageTransparency      = Theme.TextSecondary,
			Size                   = UDim2.new(1, 0, 1, 0),
		})
		for _, Child in Mark:GetChildren() do
			if Child:IsA("UIStroke") then
				Child:Destroy()
			end
		end
	end
	local Line = Text({
		Parent           = Middle,
		Text             = Options.Text or "Nothing here yet",
		TextSize         = Metrics.BodySize,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Center,
		TextWrapped      = true,
		LayoutOrder      = 2,
	})
	local Under = nil
	if Options.Detail then
		Under = Text({
			Parent           = Middle,
			Text             = Options.Detail,
			TextSize         = Metrics.CaptionSize,
			TextTransparency = Theme.TextDisabled,
			TextXAlignment   = Enum.TextXAlignment.Center,
			TextWrapped      = true,
			LayoutOrder      = 3,
		})
	end
	if Options.Action then
		local Pill = New("TextButton", {
			Name                   = "Action",
			Parent                 = Middle,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = 0.86,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, Metrics.TabHeight),
			LayoutOrder            = 4,
		}, {
			Corner(Round(Options, math.floor(Metrics.TabHeight / 2))),
			Padding(0, 16),
		})
		Text({
			Parent         = Pill,
			Text           = Options.Action,
			TextSize       = Metrics.ValueSize,
			FontFace       = Theme.FontMedium,
			TextYAlignment = Enum.TextYAlignment.Center,
			AutomaticSize  = Enum.AutomaticSize.X,
			Size           = UDim2.new(0, 0, 1, 0),
			ZIndex         = 2,
		})
		Pill.MouseEnter:Connect(function()
			Tween(Pill, { BackgroundTransparency = 0.74 }, "hover")
		end)
		Pill.MouseLeave:Connect(function()
			Tween(Pill, { BackgroundTransparency = 0.86 }, "hover")
		end)
		Pill.Activated:Connect(function()
			if Options.Callback then
				task.spawn(Options.Callback)
			end
		end)
	end
	function Handle:Set(Message, Detail)
		SwapText(Line, tostring(Message))
		if Detail and Under then
			SwapText(Under, tostring(Detail))
		end
		return Handle
	end
	return BlockHandle(Built, Handle, Options)
end
function Controls.Confirm(Container, Options)
	local Handle = {}
	local Width = Options.Width or 110
	local Armed = false
	local Token = 0
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Accent = Options.Color or Theme.Danger
	local Button = New("TextButton", {
		Name                   = "Confirm",
		Parent                 = Built.Mount,
		BackgroundColor3       = Accent,
		BackgroundTransparency = 0.88,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.TabHeight),
	}, {
		Corner(Round(Options, math.floor(Metrics.TabHeight / 2))),
	})
	local Label = Text({
		Parent         = Button,
		Text           = Options.Action or "Delete",
		TextColor3     = Accent,
		FontFace       = Theme.FontMedium,
		TextSize       = Metrics.ValueSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
		ZIndex         = 2,
	})
	local Timer = New("Frame", {
		Name                   = "Window",
		Parent                 = Button,
		BackgroundColor3       = Accent,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, 0),
		Size                   = UDim2.new(0, 0, 0, 1),
		ZIndex                 = 3,
	})
	local function Disarm(Animate)
		Armed = false
		Token += 1
		SwapText(Label, Options.Action or "Delete")
		Tween(Button, { BackgroundTransparency = 0.88 }, "hover")
		Tween(Timer, { Size = UDim2.new(0, 0, 0, 1) },
			Animate == false and "instant" or "exit")
	end
	Button.Activated:Connect(function()
		if Handle:IsDisabled() then
			return
		end
		if Armed then
			Disarm(false)
			if Options.Callback then
				task.spawn(Options.Callback)
			end
			return
		end
		Armed = true
		Token += 1
		local Mine = Token
		SwapText(Label, Options.Sure or "Sure?")
		Tween(Button, { BackgroundTransparency = 0.7 }, "hover")
		Motion.Halt(Timer, "Size")
		Timer.Size = UDim2.new(1, 0, 0, 1)
		Tween(Timer, { Size = UDim2.new(0, 0, 0, 1) },
			{ Duration = Options.Window or 3, Easing = "linear" })
		task.delay(Options.Window or 3, function()
			if Token == Mine and Armed then
				Disarm(true)
			end
		end)
	end)
	Button.MouseLeave:Connect(function()
		if Armed and Options.Leave ~= false then
			Disarm(true)
		end
	end)
	function Handle:IsArmed()
		return Armed
	end
	function Handle:Disarm()
		Disarm(true)
		return Handle
	end
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
	})
end
function Controls.Sortable(Container, Options)
	local Handle = {}
	local Items = {}
	local Rows = {}
	local Tall = Options.RowHeight or 30
	local Gap = Options.Gap or 4
	for Index, Item in Options.Items or {} do
		Items[Index] = Item
	end
	local Built = Block(Container, Options, #Items * (Tall + Gap))
	local Holder = New("Frame", {
		Name                   = "Sortable",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	local Held = nil
	local function Place(Index)
		return (Index - 1) * (Tall + Gap)
	end
	local function Settle(Animate)
		for Index, Row in Rows do
			if Row ~= Held then
				local Target = UDim2.new(0, 0, 0, Place(Index))
				if Animate == false then
					Motion.Halt(Row.Frame, "Position")
					Row.Frame.Position = Target
				else
					Tween(Row.Frame, { Position = Target }, "layout")
				end
			end
		end
	end
	local function Build(Index, Item)
		local Frame = New("TextButton", {
			Name                   = "Item",
			Parent                 = Holder,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RowTransparency,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			Position               = UDim2.new(0, 0, 0, Place(Index)),
			Size                   = UDim2.new(1, 0, 0, Tall),
		}, {
			Corner(Util.Radius(Options, Metrics.RowRadius)),
			Padding(0, 10),
		})
		local Grip = New("Frame", {
			Name                   = "Grip",
			Parent                 = Frame,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, 0, 0.5, 0),
			Size                   = UDim2.new(0, 10, 0, 10),
		})
		for Bar = 1, 3 do
			New("Frame", {
				Parent                 = Grip,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.TextDisabled,
				BorderSizePixel        = 0,
				Position               = UDim2.new(0, 0, 0, (Bar - 1) * 4),
				Size                   = UDim2.new(1, 0, 0, 1),
			})
		end
		local Label = Text({
			Parent         = Frame,
			Text           = tostring(type(Item) == "table" and Item.Label or Item),
			TextSize       = Metrics.ValueSize,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate   = Enum.TextTruncate.AtEnd,
			Position       = UDim2.new(0, 18, 0, 0),
			Size           = UDim2.new(1, -18, 1, 0),
			AutomaticSize  = Enum.AutomaticSize.None,
		})
		return { Frame = Frame, Label = Label, Item = Item }
	end
	for Index, Item in Items do
		Rows[Index] = Build(Index, Item)
	end
	local Connections = {}
	local Grab, From = nil, nil
	local function Where(Point)
		local Origin = Holder.AbsolutePosition
		return Point.Y - Origin.Y
	end
	for Index, Row in Rows do
		table.insert(Connections, Row.Frame.InputBegan:Connect(function(Input)
			if Input.UserInputType ~= Enum.UserInputType.MouseButton1
				and Input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if Handle:IsDisabled() then
				return
			end
			Held = Row
			Grab = Where(Input.Position) - Row.Frame.Position.Y.Offset
			From = table.find(Rows, Row)
			Row.Frame.ZIndex = 5
			Tween(Row.Frame, { BackgroundTransparency = 0.7 }, "hover")
		end))
	end
	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
		if not Held then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseMovement
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local Top = Clamp(Where(Input.Position) - (Grab or 0), 0,
			math.max(0, (#Rows - 1) * (Tall + Gap)))
		Motion.Halt(Held.Frame, "Position")
		Held.Frame.Position = UDim2.new(0, 0, 0, Top)
		local Wanted = Clamp(math.floor(Top / (Tall + Gap) + 0.5) + 1, 1, #Rows)
		local At = table.find(Rows, Held)
		if At and Wanted ~= At then
			table.remove(Rows, At)
			table.insert(Rows, Wanted, Held)
			Settle(true)
		end
	end))
	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input)
		if not Held then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local Landed = Held
		Tween(Landed.Frame, { BackgroundTransparency = Theme.RowTransparency }, "hover")
		Landed.Frame.ZIndex = 1
		Held = nil
		Settle(true)
		local To = table.find(Rows, Landed)
		if To and From and To ~= From and Options.Callback then
			task.spawn(Options.Callback, Handle:Get(), From, To)
		end
		From = nil
	end))
	function Handle:Get()
		local Order = {}
		for Index, Row in Rows do
			Order[Index] = Row.Item
		end
		return Order
	end
	function Handle:Move(FromIndex, ToIndex)
		local Row = Rows[FromIndex]
		if not Row then
			return Handle
		end
		table.remove(Rows, FromIndex)
		table.insert(Rows, Clamp(ToIndex, 1, #Rows + 1), Row)
		Settle(true)
		return Handle
	end
	Settle(false)
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
	end)
	return Result
end
return Controls
end
KuikModules["Controls/Pickers"] = function()
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Screen  = KuikRequire("Screen")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Clamp   = Util.Clamp
local Round   = Util.Round
local Colour  = Util.Colour
local Tween      = Motion.Tween
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Row         = Parts.Row
local Block       = Parts.Block
local Common      = Parts.Common
local BlockHandle = Parts.BlockHandle
local Controls = {}
local DAY = 86400
local MONTHS = {
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
}
local WEEKDAYS = { "S", "M", "T", "W", "T", "F", "S" }
local function Midnight(When)
	local Parts_ = os.date("!*t", When or os.time())
	return os.time({
		year = Parts_.year,
		month = Parts_.month,
		day = Parts_.day,
		hour = 0,
		min = 0,
		sec = 0,
	})
end
local function Stamp(When, Format)
	return os.date(Format or "!%d %b %Y", When)
end
local function Month(When)
	local Parts_ = os.date("!*t", When)
	local First = os.time({ year = Parts_.year, month = Parts_.month, day = 1, hour = 0 })
	local Next = os.time({
		year = Parts_.month == 12 and Parts_.year + 1 or Parts_.year,
		month = Parts_.month == 12 and 1 or Parts_.month + 1,
		day = 1,
		hour = 0,
	})
	return First, math.floor((Next - First) / DAY), Parts_
end
local function Shift(When, By)
	local Parts_ = os.date("!*t", When)
	local Total = (Parts_.year * 12 + Parts_.month - 1) + By
	return os.time({
		year = math.floor(Total / 12),
		month = Total % 12 + 1,
		day = 1,
		hour = 0,
	})
end
function Controls.Calendar(Container, Options)
	local Handle = {}
	local Accent = Colour(Options, Theme.Accent)
	local Today = Midnight()
	local Cursor = Midnight(Options.Default or Today)
	local Range = Options.Range == true
	local From = Options.From and Midnight(Options.From) or (not Range and Cursor or nil)
	local To = Options.To and Midnight(Options.To) or nil
	local Built = Block(Container, Options)
	local Head = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 22),
		LayoutOrder            = 1,
	})
	local function Arrow(Direction)
		local Button = New("TextButton", {
			Parent                 = Head,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			AnchorPoint            = Vector2.new(Direction < 0 and 0 or 1, 0.5),
			Position               = UDim2.new(Direction < 0 and 0 or 1, 0, 0.5, 0),
			Size                   = UDim2.new(0, 20, 0, 20),
			ZIndex                 = 3,
		})
		Util.Chevron(Button, 12, Direction < 0 and "Left" or "Right")
		return Button
	end
	local Back = Arrow(-1)
	local Forward = Arrow(1)
	local Title = Text({
		Parent         = Head,
		Text           = "",
		FontFace       = Theme.FontMedium,
		TextSize       = Metrics.BodySize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, -48, 1, 0),
		Position       = UDim2.new(0, 24, 0, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Week = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 14),
		LayoutOrder            = 2,
	}, {
		Strip(0),
	})
	for _, Letter in WEEKDAYS do
		Text({
			Parent           = Week,
			Text             = Letter,
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextDisabled,
			TextXAlignment   = Enum.TextXAlignment.Center,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Size             = UDim2.new(1 / 7, 0, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
	end
	local Grid = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.CellHeight and Options.CellHeight * 6 or 132),
		LayoutOrder            = 3,
	}, {
		New("UIGridLayout", {
			CellSize    = UDim2.new(1 / 7, -2, 0, Options.CellHeight or 20),
			CellPadding = UDim2.new(0, 2, 0, 2),
			SortOrder   = Enum.SortOrder.LayoutOrder,
			FillDirectionMaxCells = 7,
		}),
	})
	List(6).Parent = Built.Content
	local Cells = {}
	local function Paint()
		for _, Cell in Cells do
			local Day = Cell.Day
			local Selected = false
			local Inside = false
			if Range then
				Selected = Day == From or Day == To
				Inside = From and To and Day > From and Day < To
			else
				Selected = Day == From
			end
			Tween(Cell.Frame, {
				BackgroundColor3 = Selected and Accent or Theme.White,
				BackgroundTransparency = Selected and 0 or (Inside and 0.82 or 1),
			}, "hover")
			Cell.Label.TextColor3 = Selected and Theme.Black or Theme.White
			Cell.Label.TextTransparency = Selected and 0
				or (Cell.Outside and Theme.TextDisabled or Theme.TextSecondary)
			Cell.Mark.Visible = Day == Today
			Cell.Mark.BackgroundColor3 = Selected and Theme.Black or Accent
		end
	end
	local function Fire()
		if not Options.Callback then
			return
		end
		if Range then
			task.spawn(Options.Callback, From, To)
		else
			task.spawn(Options.Callback, From)
		end
	end
	local function Draw()
		for _, Cell in Cells do
			Cell.Frame:Destroy()
		end
		table.clear(Cells)
		local First, Days, Parts_ = Month(Cursor)
		SwapText(Title, string.format("%s %d", MONTHS[Parts_.month], Parts_.year))
		local Lead = os.date("!*t", First).wday - 1
		local Start = First - Lead * DAY
		for Index = 0, 41 do
			local Day = Start + Index * DAY
			local Outside = Day < First or Day >= First + Days * DAY
			local Cell = New("Frame", {
				Parent                 = Grid,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				LayoutOrder            = Index,
			}, {
				Corner(Util.Radius(Options, 3)),
			})
			local Label = Text({
				Parent           = Cell,
				Text             = os.date("!%d", Day),
				FontFace         = Theme.FontMono,
				TextSize         = Metrics.MonoBoldSize,
				TextTransparency = Outside and Theme.TextDisabled or Theme.TextSecondary,
				TextXAlignment   = Enum.TextXAlignment.Center,
				TextYAlignment   = Enum.TextYAlignment.Center,
				Size             = UDim2.new(1, 0, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
			})
			local Mark = New("Frame", {
				Parent                 = Cell,
				BackgroundColor3       = Accent,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 1),
				Position               = UDim2.new(0.5, 0, 1, -2),
				Size                   = UDim2.new(0, 3, 0, 1),
				Visible                = false,
				ZIndex                 = 3,
			})
			local Button = New("TextButton", {
				Parent                 = Cell,
				BackgroundTransparency = 1,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 1, 0),
				ZIndex                 = 4,
			})
			table.insert(Cells, {
				Frame = Cell,
				Label = Label,
				Mark = Mark,
				Day = Day,
				Outside = Outside,
			})
			Button.MouseEnter:Connect(function()
				if Day ~= From and Day ~= To then
					Tween(Cell, { BackgroundTransparency = 0.9 }, "hover")
				end
			end)
			Button.MouseLeave:Connect(function()
				Paint()
			end)
			Button.Activated:Connect(function()
				if Handle:IsDisabled() then
					return
				end
				if not Range then
					From = Day
				elseif From == nil or (From and To) then
					From, To = Day, nil
				elseif Day < From then
					From = Day
				else
					To = Day
				end
				Paint()
				Fire()
			end)
		end
		Paint()
	end
	Back.Activated:Connect(function()
		Cursor = Shift(Cursor, -1)
		Draw()
	end)
	Forward.Activated:Connect(function()
		Cursor = Shift(Cursor, 1)
		Draw()
	end)
	function Handle:Get()
		if Range then
			return From, To
		end
		return From
	end
	function Handle:Set(A, B, Silent)
		From = A and Midnight(A) or nil
		To = B and Midnight(B) or nil
		Cursor = From or Cursor
		Draw()
		if not Silent then
			Fire()
		end
		return Handle
	end
	function Handle:Show(When)
		Cursor = Midnight(When)
		Draw()
		return Handle
	end
	Draw()
	return BlockHandle(Built, Handle, Options)
end
local function Popped(Built, Options, Owner, Width, Build)
	local Layer = Owner and Owner._Overlay and Owner:_Overlay() or Screen.Get()
	local Open = false
	local Panel = New("Frame", {
		Name                   = "Picker",
		Parent                 = Layer,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Width, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		Visible                = false,
		ZIndex                 = 45,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Stroke(Theme.White, 0.78, 1),
		Padding(6),
	})
	local Inner = New("CanvasGroup", {
		Parent                 = Panel,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		GroupTransparency      = 1,
		ZIndex                 = 46,
	}, {
		List(6),
	})
	local Order = 0
	local Host = {
		_Mount = function()
			return Inner
		end,
		_Order = function()
			Order += 1
			return Order
		end,
		_Overlay = function()
			return Layer
		end,
		_Register = function() end,
		_Window = function()
			return Owner and Owner._Window and Owner:_Window() or nil
		end,
	}
	KuikRequire("Shared").Attach(Host)
	Build(Host)
	local function Place()
		local Origin = Layer.AbsolutePosition
		local Anchor = Built.Mount
		Panel.Position = UDim2.fromOffset(
			Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X - Width - Origin.X,
			Anchor.AbsolutePosition.Y + Anchor.AbsoluteSize.Y + 4 - Origin.Y)
	end
	local function Close()
		if not Open then
			return
		end
		Open = false
		Tween(Inner, { GroupTransparency = 1 }, "exit")
		task.delay(MotionTime("exit"), function()
			if not Open then
				Panel.Visible = false
			end
		end)
	end
	local function Show()
		Open = true
		Place()
		Panel.Visible = true
		Inner.GroupTransparency = 1
		Tween(Inner, { GroupTransparency = 0 }, "fade")
	end
	if Owner and Owner._Register then
		Owner:_Register(Close)
	end
	return {
		Panel = Panel,
		Show = Show,
		Close = Close,
		Toggle = function()
			if Open then
				Close()
			else
				Show()
			end
		end,
		IsOpen = function()
			return Open
		end,
	}
end
function Controls.Date(Container, Options, Owner)
	local Handle = {}
	local Value = Midnight(Options.Default or os.time())
	local Width = Options.Width or 120
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Chip = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.ChipHeight + 2),
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(0, 8),
	})
	local Readout = Text({
		Parent         = Chip,
		Text           = Stamp(Value, Options.Format),
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoBoldSize,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Sheet = nil
	local Pop = Popped(Built, Options, Owner, Options.PanelWidth or 220, function(Host)
		Sheet = Host:Calendar({
			Default = Value,
			Color = Options.Color,
			Flat = true,
			Callback = function(Picked)
				Value = Picked
				SwapText(Readout, Stamp(Value, Options.Format))
				if Options.Callback then
					task.spawn(Options.Callback, Value)
				end
				if Options.StayOpen ~= true then
					Pop.Close()
				end
			end,
		})
	end)
	local Button = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	Button.Activated:Connect(function()
		if not Handle:IsDisabled() then
			Pop.Toggle()
		end
	end)
	function Handle:Get()
		return Value
	end
	function Handle:Set(When, Silent)
		Value = Midnight(When)
		Readout.Text = Stamp(Value, Options.Format)
		if Sheet then
			Sheet:Set(Value, nil, true)
		end
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
		return Handle
	end
	function Handle:Text()
		return Readout.Text
	end
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
		Destroy = function()
			Pop.Panel:Destroy()
		end,
	})
end
function Controls.DateRange(Container, Options, Owner)
	local Handle = {}
	local Width = Options.Width or 170
	local From = Options.From and Midnight(Options.From) or Midnight(os.time())
	local To = Options.To and Midnight(Options.To) or nil
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Chip = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.ChipHeight + 2),
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(0, 8),
	})
	local Readout = Text({
		Parent         = Chip,
		Text           = "",
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoBoldSize,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local function Render()
		Readout.Text = string.format("%s - %s",
			Stamp(From, Options.Format or "!%d %b"),
			To and Stamp(To, Options.Format or "!%d %b") or "...")
	end
	local Sheet = nil
	local Pop = Popped(Built, Options, Owner, Options.PanelWidth or 220, function(Host)
		Sheet = Host:Calendar({
			Range = true,
			From = From,
			To = To,
			Color = Options.Color,
			Flat = true,
			Callback = function(A, B)
				From, To = A, B
				Render()
				if Options.Callback then
					task.spawn(Options.Callback, From, To)
				end
			end,
		})
	end)
	local Button = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	Button.Activated:Connect(function()
		if not Handle:IsDisabled() then
			Pop.Toggle()
		end
	end)
	function Handle:Get()
		return From, To
	end
	function Handle:Set(A, B, Silent)
		From = A and Midnight(A) or From
		To = B and Midnight(B) or nil
		Render()
		if Sheet then
			Sheet:Set(From, To, true)
		end
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, From, To)
		end
		return Handle
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
		Destroy = function()
			Pop.Panel:Destroy()
		end,
	})
end
function Controls.Time(Container, Options)
	local Handle = {}
	local Minutes = Clamp(Options.Default or 0, 0, 24 * 60 - 1)
	local Step = Options.Step or 5
	local Twelve = Options.Hours == 12
	local Width = Options.Width or 110
	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)
	local Chip = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.ChipHeight + 2),
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(0, 4),
		Strip(2, Enum.HorizontalAlignment.Center),
	})
	local function Nudge(By)
		return function()
			if Handle:IsDisabled() then
				return
			end
			Minutes = (Minutes + By) % (24 * 60)
			Handle:Set(Minutes)
		end
	end
	local Down = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 16, 1, 0),
		LayoutOrder            = 1,
		ZIndex                 = 3,
	})
	Util.Chevron(Down, 10, "Left")
	local Readout = Text({
		Parent         = Chip,
		Text           = "",
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoLargeSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, -40, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
		LayoutOrder    = 2,
	})
	local Up = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 16, 1, 0),
		LayoutOrder            = 3,
		ZIndex                 = 3,
	})
	Util.Chevron(Up, 10, "Right")
	local function Render()
		local Hour = math.floor(Minutes / 60)
		local Minute = Minutes % 60
		if Twelve then
			local Suffix = Hour < 12 and "am" or "pm"
			local Shown = Hour % 12
			Readout.Text = string.format("%d:%02d %s", Shown == 0 and 12 or Shown, Minute, Suffix)
		else
			Readout.Text = string.format("%02d:%02d", Hour, Minute)
		end
	end
	Down.Activated:Connect(Nudge(-Step))
	Up.Activated:Connect(Nudge(Step))
	function Handle:Get()
		return Minutes
	end
	function Handle:Set(Value, Silent)
		Minutes = Clamp(Value, 0, 24 * 60 - 1)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Minutes)
		end
		return Handle
	end
	function Handle:Text()
		return Readout.Text
	end
	Render()
	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Down, Up },
	})
end
return Controls
end
KuikModules["Controls/Play"] = function()
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Scroll  = KuikRequire("Scroll")
local Screen  = KuikRequire("Screen")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Clamp   = Util.Clamp
local Round   = Util.Round
local Colour  = Util.Colour
local FormatNumber = Util.FormatNumber
local Tween      = Motion.Tween
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Block       = Parts.Block
local Common      = Parts.Common
local BlockHandle = Parts.BlockHandle
local Controls = {}
function Controls.Leaderboard(Container, Options)
	local Handle = {}
	local Rows = {}
	local Height = Options.Height or 168
	local Mine = Options.Me
	local Built = Block(Container, Options, Height)
	local Sheet = New("ScrollingFrame", {
		Name                   = "Board",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, Mine and -30 or 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.Y,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.Y,
	}, {
		List(Options.Gap or 2),
	})
	local Scroller = Scroll.Attach(Sheet, "Y", { Depth = 20 })
	local function Line(Parent, Order)
		local Frame = New("Frame", {
			Name                   = "Place",
			Parent                 = Parent,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, Options.RowHeight or 26),
			LayoutOrder            = Order or 0,
		}, {
			Corner(Util.Radius(Options, Metrics.RowRadius)),
		})
		local Rank = Text({
			Parent           = Frame,
			Text             = "",
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoLargeSize,
			TextTransparency = Theme.TextTertiary,
			TextXAlignment   = Enum.TextXAlignment.Right,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Position         = UDim2.new(0, 0, 0, 0),
			Size             = UDim2.new(0, 22, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		local Face = New("ImageLabel", {
			Name                   = "Face",
			Parent                 = Frame,
			BackgroundColor3       = Theme.EmbedColor,
			BackgroundTransparency = Theme.EmbedTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, 30, 0.5, 0),
			Size                   = UDim2.new(0, 18, 0, 18),
			Visible                = false,
		}, {
			Corner(Round(Options, 9)),
		})
		local Name_ = Text({
			Parent         = Frame,
			Text           = "",
			TextSize       = Metrics.ValueSize,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate   = Enum.TextTruncate.AtEnd,
			Position       = UDim2.new(0, 34, 0, 0),
			Size           = UDim2.new(1, -(34 + 74), 1, 0),
			AutomaticSize  = Enum.AutomaticSize.None,
		})
		local Value = Text({
			Parent           = Frame,
			Text             = "",
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoLargeSize,
			TextXAlignment   = Enum.TextXAlignment.Right,
			TextYAlignment   = Enum.TextYAlignment.Center,
			AnchorPoint      = Vector2.new(1, 0),
			Position         = UDim2.new(1, -4, 0, 0),
			Size             = UDim2.new(0, 70, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		return { Frame = Frame, Rank = Rank, Face = Face, Name = Name_, Value = Value }
	end
	local function Paint(Row, Entry, Place)
		Row.Rank.Text = tostring(Entry.Rank or Place)
		SwapText(Row.Name, tostring(Entry.Name or Entry.Label or ""))
		SwapText(Row.Value, Entry.Text or FormatNumber(Entry.Value or 0))
		if Entry.UserId then
			Row.Face.Image = Util.Headshot(Entry.UserId, 48)
			Row.Face.Visible = true
			Row.Name.Position = UDim2.new(0, 54, 0, 0)
			Row.Name.Size = UDim2.new(1, -(54 + 74), 1, 0)
		else
			Row.Face.Visible = false
			Row.Name.Position = UDim2.new(0, 30, 0, 0)
			Row.Name.Size = UDim2.new(1, -(30 + 74), 1, 0)
		end
		local Own = Mine ~= nil and (Entry.Id == Mine or Entry.UserId == Mine
			or Entry.Name == Mine)
		Tween(Row.Frame, {
			BackgroundTransparency = Own and 0.9 or 1,
		}, "fade")
		Tween(Row.Name, {
			TextTransparency = Own and 0 or Theme.TextPrimary,
		}, "fade")
		return Own
	end
	local Pinned, Mark = nil, nil
	if Mine then
		Mark = New("Frame", {
			Name                   = "Divide",
			Parent                 = Built.Content,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 1),
			Position               = UDim2.new(0, 0, 1, -28),
			Size                   = UDim2.new(1, 0, 0, 1),
		})
		local Holder = New("Frame", {
			Name                   = "Mine",
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(0, 1),
			Position               = UDim2.new(0, 0, 1, 0),
			Size                   = UDim2.new(1, 0, 0, 26),
		})
		Pinned = Line(Holder)
	end
	function Handle:Set(Entries)
		Entries = Entries or {}
		if Options.Sort ~= false then
			table.sort(Entries, function(A, B)
				return (A.Value or 0) > (B.Value or 0)
			end)
		end
		for Index, Entry in Entries do
			local Row = Rows[Index]
			if not Row then
				Row = Line(Sheet, Index)
				Rows[Index] = Row
			end
			Row.Frame.Visible = true
			Row.Frame.LayoutOrder = Index
			local Own = Paint(Row, Entry, Index)
			if Own and Pinned then
				Paint(Pinned, Entry, Index)
			end
		end
		for Index = #Entries + 1, #Rows do
			Rows[Index].Frame.Visible = false
		end
		return Handle
	end
	function Handle:Get()
		return #Rows
	end
	function Handle:Clear()
		for _, Row in Rows do
			Row.Frame:Destroy()
		end
		table.clear(Rows)
		return Handle
	end
	if Options.Entries then
		Handle:Set(Options.Entries)
	end
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		Scroller:Destroy()
	end)
	return Result
end
function Controls.Slots(Container, Options)
	local Handle = {}
	local Count = Options.Count or 12
	local Across = Options.Across or 6
	local Size = Options.Size or 42
	local Gap = Options.Gap or 6
	local Items = {}
	local Cells = {}
	local Value = nil
	local Rows = math.ceil(Count / Across)
	local Height = Rows * Size + (Rows - 1) * Gap
	local Built = Block(Container, Options, Height)
	local Grid = New("Frame", {
		Name                   = "Slots",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Height),
	}, {
		New("UIGridLayout", {
			CellSize        = UDim2.new(0, Size, 0, Size),
			CellPadding     = UDim2.new(0, Gap, 0, Gap),
			SortOrder       = Enum.SortOrder.LayoutOrder,
			FillDirectionMaxCells = Across,
		}),
	})
	local function Render()
		for Index, Cell in Cells do
			local Item = Items[Index]
			local On = Value == Index
			Tween(Cell.Frame, {
				BackgroundTransparency = Item and 0.82 or 0.94,
			}, "fade")
			Tween(Cell.Edge, {
				Transparency = On and 0.1 or (Item and 0.72 or 0.88),
			}, "hover")
			Cell.Edge.Color = Item and (Item.Color or Colour(Options, Theme.White))
				or Theme.White
			Cell.Picture.Visible = Item ~= nil and Item.Image ~= nil
			if Item and Item.Image then
				Cell.Picture.Image = Util.Asset(Item.Image)
			end
			Cell.Tally.Visible = Item ~= nil and (Item.Count or 0) > 1
			Cell.Tally.Text = Item and tostring(Item.Count or "") or ""
			Cell.Mark.Visible = Item ~= nil and Item.Image == nil
			Cell.Mark.Text = Item and tostring(Item.Label or ""):sub(1, 2):upper() or ""
		end
	end
	for Index = 1, Count do
		local Frame = New("TextButton", {
			Name                   = "Slot",
			Parent                 = Grid,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.94,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			LayoutOrder            = Index,
		}, {
			Corner(Util.Radius(Options, Metrics.RowRadius)),
		})
		local Edge = Stroke(Theme.White, 0.88, 1)
		Edge.Parent = Frame
		local Picture = New("ImageLabel", {
			Name                   = "Picture",
			Parent                 = Frame,
			BackgroundTransparency = 1,
			ScaleType              = Enum.ScaleType.Fit,
			Size                   = UDim2.new(1, -8, 1, -8),
			Position               = UDim2.new(0, 4, 0, 4),
			Visible                = false,
		})
		local Mark = Text({
			Parent         = Frame,
			Text           = "",
			FontFace       = Theme.FontMono,
			TextSize       = Metrics.MonoLargeSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Size           = UDim2.new(1, 0, 1, 0),
			AutomaticSize  = Enum.AutomaticSize.None,
			Visible        = false,
		})
		local Tally = Text({
			Parent           = Frame,
			Text             = "",
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextXAlignment   = Enum.TextXAlignment.Right,
			TextYAlignment   = Enum.TextYAlignment.Bottom,
			AnchorPoint      = Vector2.new(1, 1),
			Position         = UDim2.new(1, -3, 1, -2),
			Size             = UDim2.new(0, 20, 0, 10),
			AutomaticSize    = Enum.AutomaticSize.None,
			ZIndex           = 3,
			Visible          = false,
		})
		Cells[Index] = { Frame = Frame, Edge = Edge, Picture = Picture, Mark = Mark, Tally = Tally }
		Frame.Activated:Connect(function()
			Handle:Select(Index)
		end)
	end
	function Handle:Set(Index, Item)
		Items[Index] = Item
		Render()
		return Handle
	end
	function Handle:Fill(List_)
		table.clear(Items)
		for Index, Item in List_ or {} do
			Items[Index] = Item
		end
		Render()
		return Handle
	end
	function Handle:Get(Index)
		if Index then
			return Items[Index]
		end
		return Value, Items[Value]
	end
	function Handle:Select(Index, Silent)
		Value = Index
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Index, Items[Index])
		end
		return Handle
	end
	function Handle:Clear()
		table.clear(Items)
		Value = nil
		Render()
		return Handle
	end
	if Options.Items then
		Handle:Fill(Options.Items)
	else
		Render()
	end
	return BlockHandle(Built, Handle, Options)
end
function Controls.Wallet(Container, Options)
	local Handle = {}
	local Amount = Options.Default or 0
	local Shown = Amount
	local Built = Block(Container, Options, nil)
	local Line = New("Frame", {
		Name                   = "Wallet",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 26),
	}, {
		Strip(8),
	})
	if Options.Icon then
		New("ImageLabel", {
			Name                   = "Coin",
			Parent                 = Line,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Options.Icon),
			ImageColor3            = Colour(Options, Theme.White),
			Size                   = UDim2.new(0, 16, 0, 16),
			LayoutOrder            = 1,
		})
	end
	local Readout = Text({
		Parent         = Line,
		Text           = FormatNumber(Amount),
		TextColor3     = Colour(Options, Theme.White),
		FontFace       = Theme.FontMono,
		TextSize       = Options.TextSize or Metrics.CountSize,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize  = Enum.AutomaticSize.X,
		Size           = UDim2.new(0, 0, 1, 0),
		LayoutOrder    = 2,
	})
	local Unit = nil
	if Options.Unit then
		Unit = Text({
			Parent           = Line,
			Text             = Options.Unit,
			TextSize         = Metrics.CaptionSize,
			TextTransparency = Theme.TextSecondary,
			TextYAlignment   = Enum.TextYAlignment.Bottom,
			AutomaticSize    = Enum.AutomaticSize.X,
			Size             = UDim2.new(0, 0, 1, -4),
			LayoutOrder      = 3,
		})
	end
	local Change = Text({
		Parent           = Line,
		Text             = "",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoLargeSize,
		TextTransparency = 1,
		TextYAlignment   = Enum.TextYAlignment.Center,
		AutomaticSize    = Enum.AutomaticSize.X,
		Size             = UDim2.new(0, 0, 1, 0),
		LayoutOrder      = 4,
	})
	local Rolling = nil
	local function Roll()
		if Rolling then
			return
		end
		local Link
		local function Stop()
			if Link then
				Link:Disconnect()
			end
			if Rolling == Link then
				Rolling = nil
			end
		end
		Link = RunService.Heartbeat:Connect(function(Delta)
			if not Readout.Parent then
				Stop()
				return
			end
			local Step = 1 - math.exp(-(Options.Speed or 9) * math.min(Delta, 1 / 20))
			Shown += (Amount - Shown) * Step
			if math.abs(Amount - Shown) < 0.5 then
				Shown = Amount
				Stop()
			end
			Readout.Text = FormatNumber(math.floor(Shown + 0.5))
		end)
		Rolling = Link
	end
	function Handle:Get()
		return Amount
	end
	function Handle:Set(NewAmount, Silent)
		local Was = Amount
		Amount = NewAmount or 0
		Roll()
		local Delta = Amount - Was
		if Delta ~= 0 and Options.Change ~= false then
			Change.Text = string.format("%s%s", Delta > 0 and "+" or "-",
				FormatNumber(math.abs(Delta)))
			Change.TextColor3 = Delta > 0 and Theme.Good or Theme.Danger
			Change.TextTransparency = 0
			task.delay(Options.Hold or 1.2, function()
				if Change.Parent then
					Tween(Change, { TextTransparency = 1 }, "fade")
				end
			end)
		end
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Amount, Delta)
		end
		return Handle
	end
	function Handle:Add(Delta, Silent)
		return Handle:Set(Amount + (Delta or 0), Silent)
	end
	Handle.Readout = Readout
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		if Rolling then
			Rolling:Disconnect()
			Rolling = nil
		end
	end)
	return Result
end
function Controls.Radial(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Radius = Options.Radius or 66
	local Value = Options.Default
	local Wedges = {}
	local Span = (Radius + 34) * 2
	local Built = Block(Container, Options, Span)
	local Wheel = New("Frame", {
		Name                   = "Wheel",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, 0),
		Size                   = UDim2.new(0, Span, 0, Span),
	})
	New("Frame", {
		Name                   = "Ring",
		Parent                 = Wheel,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, Radius * 2, 0, Radius * 2),
	}, {
		Corner(Radius),
		Stroke(Theme.White, Theme.RuleTransparency, 1),
	})
	local Centre = Text({
		Parent         = Wheel,
		Text           = Options.Label or "",
		TextSize       = Metrics.ValueSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AnchorPoint    = Vector2.new(0.5, 0.5),
		Position       = UDim2.new(0.5, 0, 0.5, 0),
		Size           = UDim2.new(0, Radius, 0, 30),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Needle = New("Frame", {
		Name                   = "Needle",
		Parent                 = Wheel,
		BackgroundColor3       = Colour(Options, Theme.White),
		BackgroundTransparency = 0.4,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, Radius, 0, 1),
		Visible                = false,
		ZIndex                 = 2,
	})
	local function Angle(Index)
		return -math.pi / 2 + (Index - 1) * (math.pi * 2) / math.max(1, #Items)
	end
	local function Render()
		for Index, Wedge in Wedges do
			local On = Value == Index
			Tween(Wedge.Label, {
				TextTransparency = On and 0 or Theme.TextSecondary,
			}, "hover")
			Tween(Wedge.Dot, {
				BackgroundTransparency = On and 0 or 0.7,
				Size = UDim2.new(0, On and 8 or 5, 0, On and 8 or 5),
			}, "morph")
		end
		if Value and Items[Value] then
			local Turn = Angle(Value)
			Needle.Visible = true
			Needle.Rotation = math.deg(Turn)
			SwapText(Centre, tostring(Items[Value].Label or Items[Value]))
		else
			Needle.Visible = false
			SwapText(Centre, Options.Label or "")
		end
	end
	for Index, Item in Items do
		local Turn = Angle(Index)
		local X = math.cos(Turn) * Radius
		local Y = math.sin(Turn) * Radius
		local Dot = New("Frame", {
			Name                   = "Dot",
			Parent                 = Wheel,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = 0.7,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, X, 0.5, Y),
			Size                   = UDim2.new(0, 5, 0, 5),
			ZIndex                 = 3,
		}, {
			Corner(Round(Options, 3)),
		})
		local Label = Text({
			Parent         = Wheel,
			Text           = tostring(type(Item) == "table" and Item.Label or Item),
			TextSize       = Metrics.CaptionSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			AnchorPoint    = Vector2.new(0.5, 0.5),
			Position       = UDim2.new(0.5, X * 1.28, 0.5, Y * 1.28),
			Size           = UDim2.new(0, 84, 0, 16),
			AutomaticSize  = Enum.AutomaticSize.None,
			ZIndex         = 3,
		})
		Wedges[Index] = { Dot = Dot, Label = Label, Item = Item }
	end
	local Hit = New("TextButton", {
		Name                   = "Pick",
		Parent                 = Wheel,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 4,
	})
	local function Toward(Point)
		local Origin = Wheel.AbsolutePosition
		local Size = Wheel.AbsoluteSize
		if Size.X <= 0 or #Items == 0 then
			return nil
		end
		local X = Point.X - (Origin.X + Size.X / 2)
		local Y = Point.Y - (Origin.Y + Size.Y / 2)
		if math.sqrt(X * X + Y * Y) < (Options.Dead or 18) then
			return nil
		end
		local Turn = math.atan2(Y, X) + math.pi / 2
		local Slice = (math.pi * 2) / #Items
		local Index = math.floor(Turn / Slice + 0.5) % #Items + 1
		return Index
	end
	local Connections = {}
	table.insert(Connections, Hit.MouseMoved:Connect(function()
		if Options.Hover == false then
			return
		end
	end))
	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseMovement or Options.Hover == false then
			return
		end
		local Index = Toward(Input.Position)
		if Index and Index ~= Value then
			Handle:Select(Index, true)
		end
	end))
	Hit.Activated:Connect(function()
		if Value then
			Handle:Choose(Value)
		end
	end)
	function Handle:Get()
		return Value, Items[Value]
	end
	function Handle:Select(Index, Silent)
		Value = Index
		Render()
		if not Silent and Options.Hovered then
			task.spawn(Options.Hovered, Index, Items[Index])
		end
		return Handle
	end
	function Handle:Choose(Index)
		Value = Index or Value
		Render()
		if Value and Options.Callback then
			task.spawn(Options.Callback, Value, Items[Value])
		end
		return Handle
	end
	Render()
	local Result = BlockHandle(Built, Handle, Options)
	Result:OnDestroy(function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
	end)
	return Result
end
function Controls.Versus(Container, Options)
	local Handle = {}
	local Left = Options.Left or 0
	local Right = Options.Right or 0
	local Built = Block(Container, Options, nil)
	local Head = New("Frame", {
		Name                   = "Heads",
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 18),
	})
	local function Side(Anchor, Name, Tint)
		local Label = Text({
			Parent         = Head,
			Text           = Name or "",
			TextSize       = Metrics.CaptionSize,
			TextColor3     = Tint,
			TextXAlignment = Anchor == 0 and Enum.TextXAlignment.Left
				or Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			AnchorPoint    = Vector2.new(Anchor, 0),
			Position       = UDim2.new(Anchor, 0, 0, 0),
			Size           = UDim2.new(0.5, -4, 1, 0),
			AutomaticSize  = Enum.AutomaticSize.None,
		})
		local Score = Text({
			Parent         = Head,
			Text           = "0",
			FontFace       = Theme.FontMono,
			TextColor3     = Tint,
			TextSize       = Metrics.MonoLargeSize,
			TextXAlignment = Anchor == 0 and Enum.TextXAlignment.Left
				or Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			AnchorPoint    = Vector2.new(Anchor, 0),
			Position       = UDim2.new(Anchor, 0, 0, 0),
			Size           = UDim2.new(0.5, -4, 1, 0),
			AutomaticSize  = Enum.AutomaticSize.None,
			Visible        = false,
		})
		return Label, Score
	end
	local HomeTint = Options.LeftColor or Colour(Options, Theme.White)
	local AwayTint = Options.RightColor or Theme.Danger
	local HomeName = Side(0, Options.LeftLabel, HomeTint)
	local AwayName = Side(1, Options.RightLabel, AwayTint)
	local Track = New("Frame", {
		Name                   = "Track",
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.9,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, Options.Thickness or 3),
	}, {
		Corner(Round(Options, 2)),
	})
	local Home = New("Frame", {
		Name                   = "Home",
		Parent                 = Track,
		BackgroundColor3       = HomeTint,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.new(0.5, 0, 0, 0),
		Size                   = UDim2.new(0.25, 0, 1, 0),
	})
	local Away = New("Frame", {
		Name                   = "Away",
		Parent                 = Track,
		BackgroundColor3       = AwayTint,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0),
		Position               = UDim2.new(0.5, 0, 0, 0),
		Size                   = UDim2.new(0.25, 0, 1, 0),
	})
	New("Frame", {
		Name                   = "Middle",
		Parent                 = Track,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.4,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, 1, 0, (Options.Thickness or 3) + 4),
		ZIndex                 = 2,
	})
	local Readout = Text({
		Parent           = Built.Content,
		Text             = "",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Center,
		Size             = UDim2.new(1, 0, 0, 12),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local function Render(Animate)
		local Total = math.max(1, Left + Right)
		local Share = Left / Total
		local Role = Animate == false and "instant" or "layout"
		Tween(Home, { Size = UDim2.new(Share * 0.5, 0, 1, 0) }, Role)
		Tween(Away, { Size = UDim2.new((1 - Share) * 0.5, 0, 1, 0) }, Role)
		SwapText(HomeName, string.format("%s  %s",
			tostring(Options.LeftLabel or "Home"), FormatNumber(Left)))
		SwapText(AwayName, string.format("%s  %s",
			FormatNumber(Right), tostring(Options.RightLabel or "Away")))
		Readout.Text = string.format("%d%%  ·  %d%%",
			math.floor(Share * 100 + 0.5), math.floor((1 - Share) * 100 + 0.5))
	end
	function Handle:Get()
		return Left, Right
	end
	function Handle:Set(NewLeft, NewRight, Silent)
		Left = NewLeft or Left
		Right = NewRight or Right
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Left, Right)
		end
		return Handle
	end
	function Handle:Add(ToLeft, ToRight)
		return Handle:Set(Left + (ToLeft or 0), Right + (ToRight or 0))
	end
	Render(false)
	return BlockHandle(Built, Handle, Options)
end
return Controls
end
KuikModules["Hud"] = function()
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Screen  = KuikRequire("Screen")
local Reveal  = KuikRequire("Reveal")
local Parts   = KuikRequire("Parts")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Rule    = Util.Rule
local Glyph   = Util.Glyph
local Keycap  = Util.Keycap
local Clamp   = Util.Clamp
local Hex     = Util.Hex
local Round   = Util.Round
local Colour  = Util.Colour
local Tween      = Motion.Tween
local Enter      = Motion.Enter
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Hud = {}
local Column = nil
local function Toasts(Y)
	if Column and Column.Parent then
		return Column
	end
	Column = New("Frame", {
		Name                   = "Toasts",
		Parent                 = Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, Screen.Safe(0) + (Y or 52)),
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 5,
	}, {
		List(8, nil, Enum.HorizontalAlignment.Center),
	})
	return Column
end
function Hud.Toast(Message, Options)
	Options = Options or {}
	local Stack = Options.Parent or Toasts(Options.Y)
	local Holder = New("Frame", {
		Name                   = "Toast",
		Parent                 = Stack,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 0, 0, 18),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 5,
	}, {
		Strip(10, Enum.HorizontalAlignment.Center),
	})
	if Options.Parent then
		Holder.AnchorPoint = Vector2.new(0.5, 0)
		Holder.Position = UDim2.new(0.5, 0, 0, Options.Y or 58)
	end
	local function Bracket(Order)
		return New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Options.Color or Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(0, 1, 1, 0),
			LayoutOrder            = Order,
		})
	end
	Bracket(1)
	local Label = New("TextLabel", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Text                   = Message,
		TextColor3             = Options.Color or Theme.White,
		FontFace               = Theme.Font,
		TextSize               = Options.TextSize or (Metrics.BodySize),
		RichText               = true,
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 1, 0),
		LayoutOrder            = 2,
	})
	Bracket(3)
	Enter(Label, "TextTransparency", 0, "fade")
	for _, Child in Holder:GetChildren() do
		if Child:IsA("Frame") then
			Enter(Child, "BackgroundTransparency", Theme.RuleTransparency, "fade")
		end
	end
	local Handle = { Frame = Holder, Label = Label }
	function Handle:Set(NewText)
		SwapText(Label, NewText)
		return Handle
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	if Options.Duration and Options.Duration > 0 then
		task.delay(Options.Duration, function()
			if not Holder.Parent then
				return
			end
			Tween(Label, { TextTransparency = 1 }, "fade")
			for _, Child in Holder:GetChildren() do
				if Child:IsA("Frame") then
					Tween(Child, { BackgroundTransparency = 1 }, "fade")
				end
			end
			task.delay(MotionTime("fade"), function()
				Holder:Destroy()
			end)
		end)
	end
	return Handle
end
function Hud.Notify(Options)
	Options = Options or {}
	local Card = New("Frame", {
		Name                   = "Notify",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = 0.25,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 1),
		Position               = UDim2.new(0.5, 0, 0, 0),
		Size                   = UDim2.new(0, Options.Width or 260, 0, 46),
		ZIndex                 = 6,
	}, {
		Corner(Util.Radius(Options, Metrics.CardRadius)),
		Padding(0, Metrics.RowPadding),
		Strip(10),
	})
	if Options.Image then
		New("ImageLabel", {
			Parent                 = Card,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Options.Image),
			Size                   = UDim2.new(0, 24, 0, 24),
			LayoutOrder            = 1,
		}, {
			Corner(Round(Options, 12)),
		})
	end
	local Column = New("Frame", {
		Parent                 = Card,
		BackgroundTransparency = 1,
		AutomaticSize          = Enum.AutomaticSize.Y,
		Size                   = UDim2.new(1, Options.Image and -44 or -10, 0, 0),
		LayoutOrder            = 2,
	}, {
		List(1),
	})
	New("TextLabel", {
		Parent                 = Column,
		BackgroundTransparency = 1,
		Text                   = Options.Title or "",
		TextColor3             = Options.Color or Theme.White,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.SubheadSize,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		RichText               = true,
		Size                   = UDim2.new(1, 0, 0, 18),
		LayoutOrder            = 1,
	})
	if Options.Text then
		Text({
			Parent           = Column,
			Text             = Options.Text,
			TextSize         = Metrics.CaptionSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	Tween(Card, { Position = UDim2.new(0.5, 0, 0, Options.Y or 62) }, "toss")
	local Handle = { Frame = Card }
	function Handle:Destroy()
		Tween(Card, { Position = UDim2.new(0.5, 0, 0, 0) }, "exit")
		task.delay(MotionTime("exit"), function()
			Card:Destroy()
		end)
	end
	if Options.Callback then
		local Button = New("TextButton", {
			Parent                 = Card,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 3,
		})
		Button.Activated:Connect(function()
			task.spawn(Options.Callback)
			Handle:Destroy()
		end)
	end
	task.delay(Options.Duration or 4, function()
		if Card.Parent then
			Handle:Destroy()
		end
	end)
	return Handle
end
function Hud.Hints(Options)
	Options = Options or {}
	local Right = Options.Side ~= "Left"
	local Down = Options.Align == "Bottom"
	local Up = Options.Align == "Top"
	local Anchor = Vector2.new(Right and 1 or 0, Up and 0 or (Down and 1 or 0.5))
	local Holder = New("Frame", {
		Name                   = "Hints",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Anchor,
		Position               = Options.Position or UDim2.new(
			Right and 1 or 0, Right and -(Options.Inset or 14) or (Options.Inset or 14),
			Up and 0 or (Down and 1 or 0.5),
			Up and (Options.Y or 90) or (Down and -(Options.Y or 90) or (Options.Y or 0))),
		Size                   = UDim2.new(0, Options.Width or 240, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = Options.ZIndex or 4,
	}, {
		List(Options.Gap or 9, Enum.FillDirection.Vertical,
			Right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left),
	})
	local Hints = { Frame = Holder }
	local Order = 0
	local Entries = {}
	local function Badge(Line, Spec)
		local Tall = Options.BadgeSize or 16
		if Spec.Icon then
			return New("ImageLabel", {
				Name                   = "Icon",
				Parent                 = Line,
				BackgroundTransparency = 1,
				Image                  = Util.Asset(Spec.Icon),
				ImageColor3            = Spec.Color or Theme.White,
				ImageTransparency      = Theme.TextSecondary,
				Size                   = UDim2.new(0, Tall, 0, Tall),
				LayoutOrder            = 1,
			})
		end
		if Spec.Mouse then
			local Body = New("Frame", {
				Name                   = "Mouse",
				Parent                 = Line,
				BackgroundTransparency = 1,
				Size                   = UDim2.new(0, math.floor(Tall * 0.68), 0, Tall),
				LayoutOrder            = 1,
			}, {
				Corner(Round(Options, math.floor(Tall * 0.34))),
				Stroke(Theme.White, Theme.TextTertiary, 1),
			})
			local Side = tostring(Spec.Mouse):lower()
			if Side ~= "middle" then
				New("Frame", {
					Name                   = "Button",
					Parent                 = Body,
					BackgroundColor3       = Spec.Color or Theme.White,
					BackgroundTransparency = Theme.TextSecondary,
					BorderSizePixel        = 0,
					Position               = UDim2.new(Side == "right" and 0.5 or 0, 0, 0, 0),
					Size                   = UDim2.new(0.5, 0, 0.42, 0),
				})
			else
				New("Frame", {
					Name                   = "Wheel",
					Parent                 = Body,
					BackgroundColor3       = Spec.Color or Theme.White,
					BackgroundTransparency = Theme.TextSecondary,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(0.5, 0),
					Position               = UDim2.new(0.5, 0, 0, 3),
					Size                   = UDim2.new(0, 2, 0.34, 0),
				})
			end
			return Body
		end
		local Keys = Spec.Keys
		if not Keys then
			Keys = Spec.Key and { Spec.Key } or (Spec.Hold and { Spec.Hold } or nil)
		end
		if not Keys then
			return nil
		end
		local Group = New("Frame", {
			Name                   = "Keys",
			Parent                 = Line,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(0, 0, 0, Tall),
			AutomaticSize          = Enum.AutomaticSize.X,
			LayoutOrder            = 1,
		}, {
			Strip(4),
		})
		for Index, Key in Keys do
			if Index > 1 then
				Text({
					Parent           = Group,
					Text             = "+",
					TextSize         = Metrics.TinySize,
					TextTransparency = Theme.TextDisabled,
					TextYAlignment   = Enum.TextYAlignment.Center,
					AutomaticSize    = Enum.AutomaticSize.X,
					Size             = UDim2.new(0, 0, 1, 0),
					LayoutOrder      = Index * 2 - 1,
				})
			end
			local Cap = New("Frame", {
				Name                   = "Cap",
				Parent                 = Group,
				BackgroundTransparency = 1,
				Size                   = UDim2.new(0, 0, 0, Tall),
				AutomaticSize          = Enum.AutomaticSize.X,
				LayoutOrder            = Index * 2,
			}, {
				Padding(0, 5),
				Corner(Round(Options, 3)),
				Stroke(Spec.Color or Theme.White, Theme.TextTertiary, 1),
			})
			Text({
				Parent         = Cap,
				Text           = tostring(Key),
				TextColor3     = Spec.Color or Theme.White,
				FontFace       = Theme.FontMedium,
				TextSize       = Options.KeySize or Metrics.CaptionSize,
				TextYAlignment = Enum.TextYAlignment.Center,
				AutomaticSize  = Enum.AutomaticSize.X,
				Size           = UDim2.new(0, 0, 1, 0),
			})
		end
		return Group
	end
	function Hints:Add(First, Second)
		local Spec = type(First) == "table" and First or { Key = First, Action = Second }
		Order += 1
		local Line = New("Frame", {
			Name                   = "Hint",
			Parent                 = Holder,
			BackgroundTransparency = 1,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, Options.BadgeSize or 16),
			LayoutOrder            = Spec.Order or Order,
		})
		local Row = New("Frame", {
			Name                   = "Row",
			Parent                 = Line,
			BackgroundTransparency = 1,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
		}, {
			Strip(Options.Inner or 8, Right
				and Enum.HorizontalAlignment.Right
				or Enum.HorizontalAlignment.Left),
		})
		local Mark = Badge(Row, Spec)
		local Label = Text({
			Parent           = Row,
			Text             = tostring(Spec.Action or Spec.Text or ""),
			TextColor3       = Spec.TextColor or Theme.White,
			TextTransparency = Spec.Quiet == false and 0 or Theme.TextSecondary,
			FontFace         = Theme.Font,
			TextSize         = Options.TextSize or Metrics.ValueSize,
			TextYAlignment   = Enum.TextYAlignment.Center,
			AutomaticSize    = Enum.AutomaticSize.X,
			Size             = UDim2.new(0, 0, 1, 0),
			LayoutOrder      = 2,
		})
		local Fill = nil
		if Spec.Hold then
			local Track = New("Frame", {
				Name                   = "Hold",
				Parent                 = Line,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.RuleTransparency,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0, 1),
				Position               = UDim2.new(0, 0, 1, 1),
				Size                   = UDim2.new(0, 0, 0, 1),
				ZIndex                 = 2,
			})
			Parts.Span(Track, Row, false)
			Fill = New("Frame", {
				Name                   = "Fill",
				Parent                 = Track,
				BackgroundColor3       = Spec.Color or Theme.White,
				BorderSizePixel        = 0,
				Size                   = UDim2.new(0, 0, 1, 0),
			})
		end
		local Entry = { Frame = Line, Label = Label, Badge = Mark, Fill = Fill }
		function Entry:Set(NewFirst, NewSecond)
			local Next = type(NewFirst) == "table" and NewFirst
				or { Key = NewFirst, Action = NewSecond }
			if Next.Action or Next.Text then
				SwapText(Label, tostring(Next.Action or Next.Text))
			end
			if Next.Key or Next.Keys or Next.Mouse or Next.Icon or Next.Hold then
				if Mark then
					Mark:Destroy()
				end
				Mark = Badge(Row, Next)
				Entry.Badge = Mark
			end
			return Entry
		end
		function Entry:SetProgress(Amount, Animate)
			if not Fill then
				return Entry
			end
			local Target = UDim2.new(Clamp(Amount or 0, 0, 1), 0, 1, 0)
			if Animate == false then
				Motion.Halt(Fill, "Size")
				Fill.Size = Target
			else
				Tween(Fill, { Size = Target }, "snap")
			end
			return Entry
		end
		function Entry:SetVisible(Value)
			Line.Visible = Value ~= false
			return Entry
		end
		function Entry:Destroy()
			local At = table.find(Entries, Entry)
			if At then
				table.remove(Entries, At)
			end
			Line:Destroy()
		end
		table.insert(Entries, Entry)
		if Options.Reveal ~= false then
			Motion.FadeIn(Line, 0, "enter")
		end
		return Entry
	end
	function Hints:Set(List)
		Hints:Clear()
		for _, Spec in List or {} do
			Hints:Add(Spec)
		end
		return Hints
	end
	function Hints:Clear()
		for _, Entry in table.clone(Entries) do
			Entry:Destroy()
		end
		table.clear(Entries)
		for _, Child in Holder:GetChildren() do
			if Child:IsA("GuiObject") then
				Child:Destroy()
			end
		end
		return Hints
	end
	function Hints:Count()
		return #Entries
	end
	function Hints:SetVisible(Value)
		Holder.Visible = Value ~= false
		return Hints
	end
	function Hints:Destroy()
		Holder:Destroy()
	end
	return Hints
end
function Hud.Log(Options)
	Options = Options or {}
	local Limit = Options.Limit or 8
	local Holder = New("Frame", {
		Name                   = "Log",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 12, 1, -(Options.Bottom or 34)),
		Size                   = UDim2.new(0, Options.Width or 262, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 4,
	})
	local Left = Rule(Holder, Vector2.new(0, 0))
	Left.Position = UDim2.new(0, 0, 0, 0)
	local Right = Rule(Holder, Vector2.new(1, 0))
	Right.Position = UDim2.new(1, 0, 0, 0)
	local Stack = New("Frame", {
		Name                   = "Stack",
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Padding(2, 12, 2, 12),
		List(6),
	})
	Parts.Span(Left, Stack, true)
	Parts.Span(Right, Stack, true)
	local Log = { Frame = Holder }
	local Entries = {}
	local Order = 0
	function Log:Push(Message, Colour_)
		Order += 1
		local Line = New("Frame", {
			Parent                 = Stack,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			LayoutOrder            = Order,
		})
		local Mark = Glyph(Line, 11, Theme.TextTertiary)
		Mark.Position = UDim2.new(0, 0, 0, 1)
		local Label = Text({
			Parent      = Line,
			Text        = Message,
			TextColor3  = Colour_ or Theme.White,
			TextSize    = Metrics.ValueSize,
			TextWrapped = true,
			Position    = UDim2.new(0, 18, 0, 0),
			Size        = UDim2.new(1, -18, 0, 0),
		})
		table.insert(Entries, Line)
		while #Entries > Limit do
			local Oldest = table.remove(Entries, 1)
			Oldest:Destroy()
		end
		Label.TextTransparency = 1
		Tween(Label, { TextTransparency = Theme.TextPrimary }, "fade")
		return Label
	end
	function Log:Clear()
		for _, Line in Entries do
			Line:Destroy()
		end
		table.clear(Entries)
	end
	function Log:Destroy()
		Holder:Destroy()
	end
	return Log
end
function Hud.Feed(Options)
	Options = Options or {}
	local Limit = Options.Limit or 5
	local Life = Options.Life or 4
	local Holder = New("Frame", {
		Name                   = "Feed",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 1),
		Position               = Options.Position or UDim2.new(0.5, 0, 0.62, 0),
		Size                   = UDim2.new(0, Options.Width or 520, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = Options.ZIndex or 5,
	}, {
		List(Options.Gap or 10, nil, Enum.HorizontalAlignment.Center),
	})
	local Feed = { Frame = Holder }
	local Entries = {}
	local Widths = {}
	local Order = 0
	function Feed:Push(Message, Extra)
		Extra = Extra or {}
		Order += 1
		local Tall = Options.Height or 22
		local Row = New("Frame", {
			Name                   = "Notice",
			Parent                 = Holder,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(0, 0, 0, Tall),
			LayoutOrder            = Order,
		})
		local Line = New("Frame", {
			Name                   = "Line",
			Parent                 = Row,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, 0, 1, 0),
			AutomaticSize          = Enum.AutomaticSize.X,
			ZIndex                 = 3,
		}, {
			Strip(Options.Inner or 10, Enum.HorizontalAlignment.Center),
		})
		local Wire = New("Frame", {
			Name                   = "Wire",
			Parent                 = Row,
			BackgroundColor3       = Extra.Color or Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, 0, 0, 1),
			ZIndex                 = 1,
		}, {
			New("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.25, 0),
					NumberSequenceKeypoint.new(0.75, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
		if Extra.Icon then
			New("ImageLabel", {
				Name                   = "Icon",
				Parent                 = Line,
				BackgroundTransparency = 1,
				Image                  = Util.Asset(Extra.Icon),
				ImageColor3            = Extra.Color or Theme.White,
				ImageTransparency      = Theme.TextSecondary,
				Size                   = UDim2.new(0, 14, 0, 14),
				LayoutOrder            = 1,
				ZIndex                 = 3,
			})
		else
			local Mark = Glyph(Line, 12, Theme.TextTertiary)
			Mark.LayoutOrder = 1
			Mark.ZIndex = 3
			for _, Bar in Mark:GetChildren() do
				Bar.ZIndex = 3
				Bar.BackgroundColor3 = Extra.Color or Theme.White
			end
		end
		local Label = Text({
			Parent         = Line,
			Text           = Message,
			TextColor3     = Extra.Color or Theme.White,
			TextSize       = Options.TextSize or Metrics.BodySize,
			TextYAlignment = Enum.TextYAlignment.Center,
			AutomaticSize  = Enum.AutomaticSize.X,
			Size           = UDim2.new(0, 0, 1, 0),
			LayoutOrder    = 2,
			ZIndex         = 3,
		})
		local function Fit()
			Row.Size = UDim2.new(0, Line.AbsoluteSize.X, 0, Tall)
		end
		table.insert(Widths, Line:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit))
		task.defer(Fit)
		table.insert(Entries, Row)
		for Index, Each in Entries do
			local Line_ = Each:FindFirstChild("Wire")
			if Line_ then
				local Body = Each:FindFirstChild("Line")
				local Span = Body and Body.AbsoluteSize.X or Each.AbsoluteSize.X
				Tween(Line_, {
					Size = UDim2.new(0, Index == #Entries and (Span + 90) or 0, 0, 1),
				}, Index == #Entries and "reveal" or "exit")
			end
		end
		Motion.FadeIn(Row, 0, "enter")
		while #Entries > Limit do
			local Oldest = table.remove(Entries, 1)
			if Oldest.Parent then
				Motion.Out(Oldest, function()
					Oldest:Destroy()
				end, "exit")
			end
		end
		if Life > 0 then
			task.delay(Life, function()
				local At = table.find(Entries, Row)
				if At then
					table.remove(Entries, At)
				end
				if Row.Parent then
					Motion.Out(Row, function()
						Row:Destroy()
					end, "exit")
				end
			end)
		end
		return Label
	end
	function Feed:Clear()
		table.clear(Entries)
		for _, Row in Holder:GetChildren() do
			if Row.Name == "Notice" then
				Row:Destroy()
			end
		end
		return Feed
	end
	function Feed:Destroy()
		for _, Watcher in Widths do
			Watcher:Disconnect()
		end
		table.clear(Widths)
		Holder:Destroy()
	end
	return Feed
end
function Hud.Arrival(Options)
	Options = Options or {}
	local Screen_ = Options.Parent or Screen.Get()
	local Sheet = New("Frame", {
		Name                   = "Arrival",
		Parent                 = Screen_,
		BackgroundColor3       = Options.Color or Theme.Black,
		BackgroundTransparency = Options.Transparency or 0,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = Options.ZIndex or 3000,
	})
	Screen.Cover(Sheet)
	New("TextButton", {
		Name                   = "Block",
		Parent                 = Sheet,
		Text                   = "",
		AutoButtonColor        = false,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 1,
	})
	local Arrival = { Frame = Sheet }
	local Chip = New("Frame", {
		Name                   = "Status",
		Parent                 = Sheet,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0, Screen.Safe(Options.StatusAt or 0.094)),
		Size                   = UDim2.new(0, 0, 0, 26),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 3,
	})
	local Inside = New("Frame", {
		Name                   = "Inside",
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 0, 1, 0),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 3,
	}, {
		Padding(0, 14),
	})
	Rule(Chip, Vector2.new(0, 0.5)).Position = UDim2.new(0, 0, 0.5, 0)
	local Right = Rule(Chip, Vector2.new(1, 0.5))
	Right.Position = UDim2.new(1, 0, 0.5, 0)
	local Status = Text({
		Parent         = Inside,
		Text           = Options.Status or "",
		TextSize       = Options.StatusSize or Metrics.CaptionSize,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize  = Enum.AutomaticSize.X,
		Size           = UDim2.new(0, 0, 1, 0),
		ZIndex         = 3,
	})
	local Middle = New("Frame", {
		Name                   = "Middle",
		Parent                 = Sheet,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, Screen.Safe(Options.TitleAt or 0.5)),
		Size                   = UDim2.new(0, Options.Width or 640, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 3,
	}, {
		List(Options.Gap or 12, nil, Enum.HorizontalAlignment.Center),
	})
	local Title = Text({
		Parent         = Middle,
		Text           = Options.Title or "",
		TextSize       = Options.TitleSize or Metrics.SubtitleSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped    = true,
		LayoutOrder    = 1,
		ZIndex         = 3,
	})
	local Subtitle = nil
	if Options.Subtitle then
		Subtitle = Text({
			Parent           = Middle,
			Text             = Options.Subtitle,
			TextSize         = Options.SubtitleSize or Metrics.CaptionSize,
			TextTransparency = Theme.TextTertiary,
			TextXAlignment   = Enum.TextXAlignment.Center,
			TextWrapped      = true,
			LayoutOrder      = 2,
			ZIndex           = 3,
		})
	end
	local Track, Fill = nil, nil
	if Options.Progress ~= false then
		Track = New("Frame", {
			Name                   = "Track",
			Parent                 = Middle,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(0, Options.TrackWidth or 220, 0, 1),
			LayoutOrder            = 3,
			ZIndex                 = 3,
		})
		Fill = New("Frame", {
			Name                   = "Fill",
			Parent                 = Track,
			BackgroundColor3       = Colour(Options, Theme.White),
			BackgroundTransparency = 0,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(0, 0, 1, 0),
			ZIndex                 = 3,
		})
	end
	local Footer = nil
	if Options.Footer then
		Footer = New("Frame", {
			Name                   = "Footer",
			Parent                 = Sheet,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(0.5, 1),
			Position               = UDim2.new(0.5, 0, 1, -(Options.FooterAt or 26)),
			Size                   = UDim2.new(0, Options.Width or 640, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			ZIndex                 = 3,
		}, {
			List(3, nil, Enum.HorizontalAlignment.Center),
		})
		local Lines = type(Options.Footer) == "table" and Options.Footer or { Options.Footer }
		for Index, Line in Lines do
			Text({
				Parent           = Footer,
				Text             = tostring(Line),
				TextSize         = Metrics.TinySize,
				TextTransparency = Theme.TextTertiary,
				TextXAlignment   = Enum.TextXAlignment.Center,
				LayoutOrder      = Index,
				ZIndex           = 3,
			})
		end
	end
	local Closing = nil
	if Options.Reveal ~= false then
		Status.TextTransparency = 1
		if Right then
			Right.BackgroundTransparency = 1
		end
		task.defer(function()
			if not Sheet.Parent then
				return
			end
			local Wide = math.max(120, Chip.AbsoluteSize.X)
			local Origin = Chip.AbsolutePosition - Sheet.AbsolutePosition
			Closing = Reveal.Close(nil, {
				Parent = Sheet,
				Rect   = { Origin.X, Origin.Y, Wide, Chip.AbsoluteSize.Y },
				ZIndex = 6,
			})
			Tween(Status, { TextTransparency = 0 }, "enter")
			if Right then
				Tween(Right, { BackgroundTransparency = Theme.RuleTransparency }, "enter")
			end
		end)
		Motion.FadeIn(Middle, 0.12, "enter")
		if Footer then
			Motion.FadeIn(Footer, 0.2, "enter")
		end
	end
	local function Fit()
		Chip.Position = UDim2.new(0.5, 0, 0, Screen.Safe(Options.StatusAt or 0.094))
		Middle.Position = UDim2.new(0.5, 0, 0,
			Screen.Safe(Options.TitleAt or 0.5) - Title.AbsoluteSize.Y / 2)
	end
	local Sizing = Sheet:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
	local Measuring = Title:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
	task.defer(Fit)
	function Arrival:SetStatus(Message)
		SwapText(Status, tostring(Message))
		return Arrival
	end
	function Arrival:SetTitle(Message, Under)
		SwapText(Title, tostring(Message))
		if Under and Subtitle then
			SwapText(Subtitle, tostring(Under))
		end
		return Arrival
	end
	function Arrival:SetProgress(Amount, Animate)
		if not Fill then
			return Arrival
		end
		local Target = UDim2.new(Clamp(Amount or 0, 0, 1), 0, 1, 0)
		if Animate == false then
			Motion.Halt(Fill, "Size")
			Fill.Size = Target
		else
			Tween(Fill, { Size = Target }, "layout")
		end
		return Arrival
	end
	function Arrival:Done(Then)
		Motion.Fade(Sheet, 1, "exit")
		task.delay(MotionTime("exit") * 1.4, function()
			Sizing:Disconnect()
			Measuring:Disconnect()
			if Sheet.Parent then
				Sheet:Destroy()
			end
			if Then then
				task.spawn(Then)
			end
		end)
		return Arrival
	end
	function Arrival:Destroy()
		if Closing then
			Closing.Cancel()
		end
		Sizing:Disconnect()
		Measuring:Disconnect()
		Sheet:Destroy()
	end
	Arrival.Status = Status
	Arrival.Title = Title
	Arrival.Subtitle = Subtitle
	Arrival.Track = Track
	return Arrival
end
function Hud.Console(Options)
	Options = Options or {}
	local Levels = {
		INFO    = Theme.Neutral,
		SUCCESS = Theme.Good,
		WARN    = Theme.Warn,
		ERROR   = Theme.Danger,
		DEBUG   = Theme.Info,
	}
	local Holder = New("Frame", {
		Name                   = "Console",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.new(1, -14, 0, Screen.Safe(0) + (Options.Y or 8)),
		Size                   = UDim2.new(0, Options.Width or 520, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 4,
	}, {
		List(3, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right),
	})
	local Console = { Frame = Holder, Levels = Levels }
	local Order = 0
	function Console:Push(Level, Message, Duration)
		Order += 1
		local Colour_ = Levels[string.upper(Level or "INFO")] or Theme.Neutral
		local Label = New("TextLabel", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			RichText               = true,
			Text                   = string.format('<font color="%s">%s</font> %s',
				Hex(Colour_), string.upper(Level or "INFO"), Message),
			TextColor3             = Theme.White,
			FontFace               = Theme.FontMono,
			TextSize               = Metrics.MonoBoldSize,
			TextXAlignment         = Enum.TextXAlignment.Right,
			AutomaticSize          = Enum.AutomaticSize.XY,
			Size                   = UDim2.new(0, 0, 0, 0),
			LayoutOrder            = Order,
		})
		task.delay(Duration or Options.Duration or 6, function()
			if not Label.Parent then
				return
			end
			Tween(Label, { TextTransparency = 1 }, "fade")
			task.delay(MotionTime("fade"), function()
				Label:Destroy()
			end)
		end)
		return Label
	end
	function Console:Destroy()
		Holder:Destroy()
	end
	return Console
end
function Hud.Watermark(Options)
	Options = Options or {}
	local Side = Options.Side or "Left"
	local Holder = New("Frame", {
		Name                   = "Watermark",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(Side == "Right" and 1 or 0, 1),
		Position               = UDim2.new(Side == "Right" and 1 or 0,
			Side == "Right" and -14 or 14, 1, -6),
		Size                   = UDim2.new(0, 0, 0, 12),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 4,
	}, {
		Strip(Options.Gap or 22),
	})
	local Watermark = { Frame = Holder }
	local Labels = {}
	local function Field(Index, Content, Colour_, Animate)
		local Label = Labels[Index]
		if not Label then
			Label = New("TextLabel", {
				Parent                 = Holder,
				BackgroundTransparency = 1,
				RichText               = true,
				TextColor3             = Colour_ or Theme.White,
				TextTransparency       = Colour_ and 0 or Theme.TextSecondary,
				FontFace               = Theme.FontMono,
				TextSize               = Metrics.MonoSize,
				TextXAlignment         = Enum.TextXAlignment.Left,
				AutomaticSize          = Enum.AutomaticSize.X,
				Size                   = UDim2.new(0, 0, 1, 0),
				LayoutOrder            = Index,
			})
			Labels[Index] = Label
		end
		Label.Text = Content
		if Colour_ then
			Motion.Paint(Label, { TextColor3 = Colour_, TextTransparency = 0 }, Animate)
		end
		return Label
	end
	function Watermark:Set(Fields)
		local Index = 0
		if Options.Tag then
			Index += 1
			Field(Index, Options.Tag.Text or Options.Tag, Options.Tag.Color or Theme.Danger)
		end
		for _, Content in Fields do
			Index += 1
			Field(Index, tostring(Content))
		end
		for Extra = Index + 1, #Labels do
			if Labels[Extra] then
				Labels[Extra]:Destroy()
				Labels[Extra] = nil
			end
		end
		return Watermark
	end
	function Watermark:SetSide(NewSide)
		Side = NewSide
		Holder.AnchorPoint = Vector2.new(NewSide == "Right" and 1 or 0, 1)
		Holder.Position = UDim2.new(NewSide == "Right" and 1 or 0,
			NewSide == "Right" and -14 or 14, 1, -6)
		return Watermark
	end
	function Watermark:Destroy()
		Holder:Destroy()
	end
	if Options.Fields then
		Watermark:Set(Options.Fields)
	end
	return Watermark
end
function Hud.Bar(Options)
	Options = Options or {}
	local Handle = {}
	local Value = Options.Default or Options.Max or 100
	local Maximum = Options.Max or 100
	local Holder = New("Frame", {
		Name                   = Options.Name or "Bar",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Options.AnchorPoint or Vector2.new(0, 1),
		Position               = Options.Position or UDim2.new(0, 24, 1, -24),
		Size                   = UDim2.new(0, Options.Width or 220, 0, Options.Height or 26),
		ZIndex                 = 5,
	})
	local Label = nil
	if Options.Label then
		Label = Text({
			Parent           = Holder,
			Text             = Options.Label,
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			Size             = UDim2.new(1, 0, 0, 10),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
	end
	local Track = New("Frame", {
		Parent                 = Holder,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.86,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, 0),
		Size                   = UDim2.new(1, 0, 0, Options.Thickness or 6),
	}, {
		Corner(Util.Radius(Options, 0)),
	})
	local Ghost = New("Frame", {
		Parent                 = Track,
		BackgroundColor3       = Options.GhostColor or Theme.Danger,
		BackgroundTransparency = 0.4,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 1, 0),
		ZIndex           = 2,
	})
	local Readout = nil
	if Options.Readout ~= false then
		Readout = Text({
			Parent           = Holder,
			Text             = "",
			FontFace         = Theme.FontMedium,
			TextSize         = Metrics.ValueSize,
			TextXAlignment   = Enum.TextXAlignment.Right,
			AnchorPoint      = Vector2.new(1, 1),
			Position         = UDim2.new(1, 0, 1, -(Options.Thickness or 6) - 4),
			Size             = UDim2.new(0, 80, 0, 14),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
	end
	local function Render()
		local Alpha = Maximum > 0 and Clamp(Value / Maximum, 0, 1) or 0
		local Paint = Colour(Options, Theme.White)
		if Options.Danger and Alpha <= Options.Danger then
			Paint = Theme.Danger
		elseif Options.Warn and Alpha <= Options.Warn then
			Paint = Theme.Warn
		end
		Tween(Fill, { Size = UDim2.new(Alpha, 0, 1, 0), BackgroundColor3 = Paint }, "snap")
		Tween(Ghost, { Size = UDim2.new(Alpha, 0, 1, 0) },
			Ghost.Size.X.Scale > Alpha and "reveal" or "snap")
		if Readout then
			Readout.Text = Options.Format and Options.Format(Value, Maximum)
				or string.format("%d", math.floor(Value + 0.5))
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, NewMax)
		Value = NewValue
		Maximum = NewMax or Maximum
		Render()
		return Handle
	end
	function Handle:SetPosition(Position)
		Holder.Position = Position
		return Handle
	end
	function Handle:SetVisible(Visible)
		Holder.Visible = Visible ~= false
		return Handle
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	Render()
	return Handle
end
function Hud.Timer(Options)
	Options = Options or {}
	local Handle = {}
	local Value = Options.Seconds or 0
	local Running = false
	local Holder = New("Frame", {
		Name                   = "Timer",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = Options.Position or UDim2.new(0.5, 0, 0, Options.Y or 56),
		Size                   = UDim2.new(0, 0, 0, 20),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 5,
	}, {
		Strip(9, Enum.HorizontalAlignment.Center),
	})
	local function Bracket(Order)
		return New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(0, 1, 1, 0),
			LayoutOrder            = Order,
		})
	end
	Bracket(1)
	local Dial = New("Frame", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 11, 0, 11),
		LayoutOrder            = 2,
	}, {
		Corner(6),
		Stroke(Theme.White, 0.3, 1),
	})
	local Hand = New("Frame", {
		Parent           = Dial,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 1),
		Position         = UDim2.new(0.5, 0, 0.5, 0),
		Size             = UDim2.new(0, 1, 0, 4),
	})
	local Label = New("TextLabel", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Text                   = "",
		TextColor3             = Theme.White,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.RowDescSize,
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 1, 0),
		LayoutOrder            = 3,
	})
	Bracket(4)
	local function Render()
		local Whole = math.max(0, math.floor(Value))
		Label.Text = string.format("%d:%02d", Whole // 60, Whole % 60)
		Hand.Rotation = (Whole % 60) / 60 * 360
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(Seconds)
		Value = Seconds
		Render()
		return Handle
	end
	function Handle:Start()
		if Running then
			return Handle
		end
		Running = true
		task.spawn(function()
			while Running and Holder.Parent do
				task.wait(1)
				if not Running then
					break
				end
				Value += Options.Up and 1 or -1
				if not Options.Up and Value <= 0 then
					Value = 0
					Running = false
					Render()
					if Options.Callback then
						task.spawn(Options.Callback)
					end
					break
				end
				Render()
			end
		end)
		return Handle
	end
	function Handle:Stop()
		Running = false
		return Handle
	end
	function Handle:Destroy()
		Running = false
		Holder:Destroy()
	end
	Handle.Frame = Holder
	Render()
	if Options.Autostart ~= false and Options.Seconds then
		Handle:Start()
	end
	return Handle
end
function Hud.Ammo(Options)
	Options = Options or {}
	local Handle = {}
	local Magazine = Options.Magazine or 0
	local Reserve = Options.Reserve or 0
	local Holder = New("Frame", {
		Name                   = "Ammo",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 1),
		Position               = Options.Position
			or UDim2.new(1, -(Options.X or 240), 1, -(Options.Y or 90)),
		Size                   = UDim2.new(0, Options.Width or 130, 0, 44),
		ZIndex                 = 5,
	})
	local function Bracket(Anchor)
		return New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(Anchor, 0.5),
			Position               = UDim2.new(Anchor, 0, 0.5, 0),
			Size                   = UDim2.new(0, 1, 0.8, 0),
		})
	end
	Bracket(0)
	Bracket(1)
	local Name = New("TextLabel", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Text                   = Options.Weapon or "",
		TextColor3             = Theme.White,
		TextTransparency       = Theme.TextSecondary,
		FontFace               = Theme.Font,
		TextSize               = Metrics.CaptionSize,
		TextXAlignment         = Enum.TextXAlignment.Center,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, 0),
		Size                   = UDim2.new(1, -20, 0, 14),
		Rotation               = Options.Rotation or -8,
	})
	local Count = New("TextLabel", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Text                   = "",
		TextColor3             = Theme.White,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.CountSize,
		TextXAlignment         = Enum.TextXAlignment.Center,
		AnchorPoint            = Vector2.new(0.5, 1),
		Position               = UDim2.new(0.5, 0, 1, 0),
		Size                   = UDim2.new(1, -20, 0, 26),
		RichText               = true,
		Rotation               = Options.Rotation or -8,
	})
	local function Render()
		local Low = math.max(1, math.floor((Options.Capacity or Magazine) * 0.25))
		local Colour_ = Magazine == 0 and Theme.Danger
			or Magazine <= Low and Theme.Warn
			or Theme.White
		Count.Text = string.format('<font color="%s">%d</font><font transparency="0.55">/%d</font>',
			Hex(Colour_), Magazine, Reserve)
	end
	function Handle:Get()
		return Magazine, Reserve
	end
	function Handle:Set(NewMagazine, NewReserve)
		Magazine = NewMagazine or Magazine
		Reserve = NewReserve or Reserve
		Render()
		return Handle
	end
	function Handle:SetWeapon(Weapon)
		SwapText(Name, Weapon)
		return Handle
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	Render()
	return Handle
end
function Hud.Crosshair(Options)
	Options = Options or {}
	local Handle = {}
	local Gap = Options.Gap or 5
	local Length = Options.Length or 6
	local Holder = New("Frame", {
		Name                   = "Crosshair",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, 40, 0, 40),
		ZIndex                 = 4,
	})
	local Ticks = {}
	local Layout = {
		{ 0.5, 0, 0.5, 1, 0, 1, 0, Length },
		{ 0.5, 1, 0.5, 1, 0, 1, 0, Length },
		{ 0, 0.5, 1, 0.5, 0, Length, 0, 1 },
		{ 1, 0.5, 1, 0.5, 0, Length, 0, 1 },
	}
	for Index, Spec in Layout do
		Ticks[Index] = New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Options.Color or Theme.White,
			BackgroundTransparency = Options.Transparency or 0.15,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(Spec[3], Spec[4]),
			Position               = UDim2.new(Spec[1], 0, Spec[2], 0),
			Size                   = UDim2.new(Spec[5], Spec[6], Spec[7], Spec[8]),
		})
	end
	local Dot = nil
	if Options.Dot then
		Dot = New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Options.Color or Theme.White,
			BackgroundTransparency = Options.Transparency or 0.15,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, 2, 0, 2),
		})
	end
	local function Render(Spread, Role)
		local Reach = Gap + (Spread or 0)
		Tween(Ticks[1], { Position = UDim2.new(0.5, 0, 0.5, -Reach) }, Role or "drag")
		Tween(Ticks[2], { Position = UDim2.new(0.5, 0, 0.5, Reach) }, Role or "drag")
		Tween(Ticks[3], { Position = UDim2.new(0.5, -Reach, 0.5, 0) }, Role or "drag")
		Tween(Ticks[4], { Position = UDim2.new(0.5, Reach, 0.5, 0) }, Role or "drag")
	end
	function Handle:SetSpread(Spread)
		Render(Spread)
		return Handle
	end
	function Handle:Hit(Colour_)
		for _, Tick in Ticks do
			Tick.BackgroundColor3 = Colour_ or Theme.Danger
			Tween(Tick, { BackgroundColor3 = Options.Color or Theme.White }, "fade")
		end
		Render(6, "toss")
		task.delay(0.08, function() Render(0, "toss") end)
		return Handle
	end
	function Handle:SetVisible(Visible)
		Holder.Visible = Visible ~= false
		return Handle
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	Render(0, "instant")
	return Handle
end
function Hud.Killfeed(Options)
	Options = Options or {}
	local Limit = Options.Limit or 5
	local Holder = New("Frame", {
		Name                   = "Killfeed",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.new(1, -14, 0, Screen.Safe(0) + (Options.Y or 46)),
		Size                   = UDim2.new(0, Options.Width or 340, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 5,
	}, {
		List(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right),
	})
	local Feed = { Frame = Holder }
	local Lines = {}
	local Order = 0
	function Feed:Push(Actor, Verb, Target, Colour_)
		Order += 1
		local Line = New("TextLabel", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			RichText               = true,
			Text                   = string.format(
				'<font color="%s">%s</font>  <font transparency="0.5">%s</font>  <font color="%s">%s</font>',
				Hex(Colour_ or Theme.White), Actor,
				Verb or "eliminated",
				Hex(Theme.Danger), Target),
			TextColor3             = Theme.White,
			TextTransparency       = 1,
			FontFace               = Theme.FontMedium,
			TextSize               = Metrics.ValueSize,
			TextXAlignment         = Enum.TextXAlignment.Right,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, 16),
			LayoutOrder            = Order,
		})
		Tween(Line, { TextTransparency = 0 }, "fade")
		table.insert(Lines, Line)
		while #Lines > Limit do
			local Oldest = table.remove(Lines, 1)
			Oldest:Destroy()
		end
		task.delay(Options.Duration or 7, function()
			if not Line.Parent then
				return
			end
			Tween(Line, { TextTransparency = 1 }, "fade")
			task.delay(MotionTime("fade"), function()
				local At = table.find(Lines, Line)
				if At then
					table.remove(Lines, At)
				end
				Line:Destroy()
			end)
		end)
		return Line
	end
	function Feed:Clear()
		for _, Line in Lines do
			Line:Destroy()
		end
		table.clear(Lines)
	end
	function Feed:Destroy()
		Holder:Destroy()
	end
	return Feed
end
function Hud.Objective(Options)
	Options = Options or {}
	local Handle = {}
	local Holder = New("Frame", {
		Name                   = "Objective",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0, 0),
		Position               = Options.Position
			or UDim2.new(0, Options.X or 14, 0, Screen.Safe(0) + (Options.Y or 22)),
		Size                   = UDim2.new(0, Options.Width or 260, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 5,
	})
	local Stack = New("Frame", {
		Name                   = "Stack",
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Padding(0, 0, 0, 12),
		List(3),
	})
	local Left = Rule(Holder, Vector2.new(0, 0))
	Left.Position = UDim2.new(0, 0, 0, 0)
	Parts.Span(Left, Stack, true)
	local Label = Text({
		Parent           = Stack,
		Text             = Options.Label or "OBJECTIVE",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		LayoutOrder      = 1,
	})
	local Body = Text({
		Parent      = Stack,
		Text        = Options.Text or "",
		TextSize    = Metrics.BodySize,
		TextWrapped = true,
		LayoutOrder = 2,
	})
	local Fill = nil
	if Options.Progress ~= nil then
		local Track = New("Frame", {
			Parent                 = Stack,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.85,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 2),
			LayoutOrder            = 3,
		})
		Fill = New("Frame", {
			Parent           = Track,
			BackgroundColor3 = Colour(Options, Theme.White),
			BorderSizePixel  = 0,
			Size             = UDim2.new(Options.Progress, 0, 1, 0),
		})
	end
	function Handle:Set(Content, Progress)
		if Content then
			SwapText(Body, Content)
		end
		if Progress and Fill then
			Tween(Fill, { Size = UDim2.new(Clamp(Progress, 0, 1), 0, 1, 0) }, "snap")
		end
		return Handle
	end
	function Handle:SetLabel(NewLabel)
		SwapText(Label, NewLabel)
		return Handle
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	return Handle
end
function Hud.Vignette(Options)
	Options = Options or {}
	local Handle = {}
	local Depth = Options.Depth or 120
	local Strength = Options.Strength or 0.55
	local Holder = New("Frame", {
		Name                   = "Vignette",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 1,
		Active                 = false,
	})
	if not Options.Parent then
		Screen.Cover(Holder)
	end
	local Edges = {}
	local Sides = {
		{ Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1, 0, 0, Depth), Rotation = 90, Flip = true },
		{ Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, 0, 0, Depth), Rotation = 90, Flip = false },
		{ Anchor = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, Depth, 1, 0), Rotation = 0, Flip = true },
		{ Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, Depth, 1, 0), Rotation = 0, Flip = false },
	}
	for Index, Side in Sides do
		Edges[Index] = New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Options.Color or Theme.Scrim,
			BackgroundTransparency = Strength,
			BorderSizePixel        = 0,
			AnchorPoint            = Side.Anchor,
			Position               = Side.Position,
			Size                   = Side.Size,
			Active                 = false,
		}, {
			New("UIGradient", {
				Rotation = Side.Rotation,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, Side.Flip and 0 or 1),
					NumberSequenceKeypoint.new(1, Side.Flip and 1 or 0),
				}),
			}),
		})
	end
	function Handle:Set(NewStrength, Colour_, Animate)
		Strength = NewStrength
		for _, Edge in Edges do
			if Colour_ then
				Motion.Paint(Edge, { BackgroundColor3 = Colour_ }, Animate)
			end
			Tween(Edge, { BackgroundTransparency = NewStrength }, "fade")
		end
		return Handle
	end
	function Handle:Pulse(Colour_, Peak)
		for _, Edge in Edges do
			Edge.BackgroundColor3 = Colour_ or Theme.Danger
			Edge.BackgroundTransparency = Peak or 0.25
			Tween(Edge, {
				BackgroundTransparency = Strength,
				BackgroundColor3 = Options.Color or Theme.Scrim,
			}, "fade")
		end
		return Handle
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	return Handle
end
function Hud.Compass(Options)
	Options = Options or {}
	local RunService = game:GetService("RunService")
	local Handle = {}
	local Span = Options.Span or 180
	local Holder = New("Frame", {
		Name                   = "Compass",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = Options.Position
			or UDim2.new(0.5, 0, 0, Screen.Safe(0) + (Options.Y or 22)),
		Size                   = UDim2.new(0, Options.Width or 320, 0, 20),
		ClipsDescendants       = true,
		ZIndex                 = 4,
	})
	local Strip_ = New("Frame", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	local Points = Options.Points or {
		{ 0, "N" }, { 45, "NE" }, { 90, "E" }, { 135, "SE" },
		{ 180, "S" }, { 225, "SW" }, { 270, "W" }, { 315, "NW" },
	}
	local Marks = {}
	for _, Point in Points do
		Marks[#Marks + 1] = {
			Angle = Point[1],
			Label = Text({
				Parent           = Strip_,
				Text             = Point[2],
				FontFace         = Theme.FontMono,
				TextSize         = Metrics.MonoBoldSize,
				TextXAlignment   = Enum.TextXAlignment.Center,
				TextYAlignment   = Enum.TextYAlignment.Center,
				AnchorPoint      = Vector2.new(0.5, 0.5),
				Size             = UDim2.new(0, 30, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
			}),
		}
	end
	New("Frame", {
		Parent           = Holder,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 1),
		Position         = UDim2.new(0.5, 0, 1, 0),
		Size             = UDim2.new(0, 1, 0, 6),
		ZIndex           = 2,
	})
	local function Place(Heading)
		for _, Mark in Marks do
			local Delta = (Mark.Angle - Heading + 540) % 360 - 180
			local Alpha = Delta / Span
			Mark.Label.Position = UDim2.new(0.5 + Alpha, 0, 0.5, 0)
			Mark.Label.TextTransparency = Clamp(math.abs(Alpha) * 2.2 - 0.2, 0, 1)
		end
	end
	local Connection = RunService.RenderStepped:Connect(function()
		local Camera = workspace.CurrentCamera
		if not Camera then
			return
		end
		local Look = Camera.CFrame.LookVector
		local Heading = (math.deg(math.atan2(-Look.X, -Look.Z)) + 360) % 360
		Place(Heading)
	end)
	function Handle:Destroy()
		Connection:Disconnect()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	return Handle
end
function Hud.Fab(Options)
	Options = Options or {}
	local Handle = {}
	local Size = Options.Size or 48
	local Accent = Colour(Options, Theme.Accent)
	local Button = New("TextButton", {
		Name                   = "Fab",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundColor3       = Accent,
		BackgroundTransparency = 0.1,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		AnchorPoint            = Options.AnchorPoint or Vector2.new(1, 1),
		Position               = Options.Position or UDim2.new(1, -24, 1, -24),
		Size                   = UDim2.new(0, Size, 0, Size),
		ZIndex                 = 7,
	}, {
		Corner(Round(Options, math.floor(Size / 2))),
	})
	local Arms = {}
	if Options.Image then
		New("ImageLabel", {
			Parent                 = Button,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Options.Image),
			ImageColor3            = Theme.Black,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, Size * 0.45, 0, Size * 0.45),
			ZIndex                 = 8,
		})
	else
		for Index = 1, 2 do
			Arms[Index] = New("Frame", {
				Parent                 = Button,
				BackgroundColor3       = Theme.Black,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, 0.5, 0),
				Size                   = Index == 1
					and UDim2.new(0, Size * 0.36, 0, 2)
					or UDim2.new(0, 2, 0, Size * 0.36),
				ZIndex                 = 8,
			})
		end
	end
	local Label = nil
	if Options.Label then
		Label = New("TextLabel", {
			Parent                 = Button,
			BackgroundTransparency = 1,
			Text                   = Options.Label,
			TextColor3             = Theme.White,
			TextTransparency       = Theme.TextSecondary,
			FontFace               = Theme.FontMono,
			TextSize               = Metrics.MonoSize,
			TextXAlignment         = Enum.TextXAlignment.Right,
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(0, -8, 0.5, 0),
			Size                   = UDim2.new(0, 120, 0, 14),
			ZIndex                 = 8,
		})
	end
	Button.MouseEnter:Connect(function()
		Tween(Button, { Size = UDim2.new(0, Size + 4, 0, Size + 4), BackgroundTransparency = 0 }, "toss")
	end)
	Button.MouseLeave:Connect(function()
		Tween(Button, { Size = UDim2.new(0, Size, 0, Size), BackgroundTransparency = 0.1 }, "toss")
	end)
	local Turned = false
	Button.Activated:Connect(function()
		if Options.Rotates ~= false and #Arms > 0 then
			Turned = not Turned
			for _, Arm in Arms do
				Tween(Arm, { Rotation = Turned and 45 or 0 }, "morph")
			end
		end
		if Options.Callback then
			task.spawn(Options.Callback, Handle)
		end
	end)
	function Handle:SetLabel(Text_)
		if Label then
			SwapText(Label, Text_)
		end
		return Handle
	end
	function Handle:SetVisible(Visible)
		Button.Visible = Visible ~= false
		return Handle
	end
	function Handle:Destroy()
		Button:Destroy()
	end
	Handle.Frame = Button
	return Handle
end
function Hud.Viewfinder(Options)
	Options = Options or {}
	local Handle = {}
	local Inset = Options.Inset or 60
	local Reach = Options.Reach or 26
	local Holder = New("Frame", {
		Name                   = "Viewfinder",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -Inset * 2, 1, -Inset * 2),
		Position               = UDim2.new(0, Inset, 0, Inset),
		ZIndex                 = 4,
		Active                 = false,
	})
	local Accent = Colour(Options, Theme.White)
	for X = 0, 1 do
		for Y = 0, 1 do
			for Axis = 1, 2 do
				New("Frame", {
					Parent                 = Holder,
					BackgroundColor3       = Accent,
					BackgroundTransparency = Options.Transparency or 0.25,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(X, Y),
					Position               = UDim2.new(X, 0, Y, 0),
					Size                   = Axis == 1
						and UDim2.new(0, Reach, 0, 1)
						or UDim2.new(0, 1, 0, Reach),
					Active                 = false,
				})
			end
		end
	end
	local Tally = nil
	if Options.Recording ~= false then
		Tally = New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Theme.Danger,
			BorderSizePixel        = 0,
			Position               = UDim2.new(0, 0, 0, -18),
			Size                   = UDim2.new(0, 7, 0, 7),
			Visible                = false,
			Active                 = false,
		}, {
			Corner(4),
		})
		Text({
			Parent           = Holder,
			Name             = "Tally",
			Text             = Options.Label or "REC",
			FontFace         = Theme.FontMono,
			TextColor3       = Theme.Danger,
			TextSize         = Metrics.MonoSize,
			Position         = UDim2.new(0, 12, 0, -22),
			Size             = UDim2.new(0, 60, 0, 12),
			AutomaticSize    = Enum.AutomaticSize.None,
			Visible          = false,
		})
	end
	local Blinking = false
	function Handle:SetRecording(On)
		Blinking = On == true
		local Label = Holder:FindFirstChild("Tally")
		if Tally then
			Tally.Visible = Blinking
		end
		if Label then
			Label.Visible = Blinking
		end
		if not Blinking then
			return Handle
		end
		task.spawn(function()
			while Blinking and Holder.Parent do
				Tween(Tally, { BackgroundTransparency = 0 }, "fade")
				task.wait(0.5)
				Tween(Tally, { BackgroundTransparency = 0.8 }, "fade")
				task.wait(0.5)
			end
		end)
		return Handle
	end
	function Handle:Destroy()
		Blinking = false
		Holder:Destroy()
	end
	Handle.Frame = Holder
	return Handle
end
return Hud
end
KuikModules["Layers"] = function()
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Palette = KuikRequire("Theme")
local Shared  = KuikRequire("Shared")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Screen  = KuikRequire("Screen")
local Reveal  = KuikRequire("Reveal")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
local Clamp   = Util.Clamp
local Round   = Util.Round
local Colour  = Util.Colour
local Rule    = Util.Rule
local Tween      = Motion.Tween
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Parts = nil
local function Bits()
	if not Parts then
		Parts = KuikRequire("Parts")
	end
	return Parts
end
local Layers = {}
local function Shell(Frame, Inner, Options, Fallback)
	local Variant = Options.Variant or Metrics.OverlayVariant or Fallback or "Card"
	if Variant == "Rules" then
		Frame.BackgroundColor3 = Options.Fill or Theme.Scrim
		Frame.BackgroundTransparency = Options.FillTransparency == nil
			and 0.45 or Options.FillTransparency
		local Left = Rule(Frame, Vector2.new(0, 0))
		Left.Position = UDim2.new(0, 0, 0, 0)
		Left.ZIndex = (Frame.ZIndex or 1) + 1
		local Right = Rule(Frame, Vector2.new(1, 0))
		Right.Position = UDim2.new(1, 0, 0, 0)
		Right.ZIndex = Left.ZIndex
		if Inner then
			Bits().Span(Left, Inner, true)
			Bits().Span(Right, Inner, true)
		end
		return Variant, { Left, Right }
	end
	if Variant == "Bare" then
		Frame.BackgroundTransparency = Options.FillTransparency == nil
			and 1 or Options.FillTransparency
		return Variant, {}
	end
	Frame.BackgroundColor3 = Options.Fill or Theme.Scrim
	Frame.BackgroundTransparency = Options.FillTransparency == nil
		and 0.12 or Options.FillTransparency
	Corner(Util.Radius(Options, Metrics.ChipRadius)).Parent = Frame
	Stroke(Theme.White, Options.EdgeTransparency or 0.78, 1).Parent = Frame
	return Variant, {}
end
Layers.Shell = Shell
local function Attach(Object)
	return Shared.Attach(Object)
end
function Layers.Menu(Options)
	Options = Options or {}
	local Items = Options.Items or {}
	local Width = Options.Width or 150
	local EntryHeight = Options.EntryHeight or 24
	local Open = false
	local Layer = Options.Parent or Screen.Get()
	local Menu = New("Frame", {
		Name                   = "Menu",
		Parent                 = Layer,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Width, 0, 0),
		Visible                = false,
		ClipsDescendants       = true,
		ZIndex                 = 60,
	})
	local Inner = New("CanvasGroup", {
		Parent                 = Menu,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		GroupTransparency      = 1,
		ZIndex                 = 61,
	}, {
		Padding(4),
		List(1),
	})
	Shell(Menu, Inner, Options)
	local Handle = { Frame = Menu }
	local Height = 8
	local Opening = nil
	for Index, Item in Items do
		if Item.Separator then
			New("Frame", {
				Parent                 = Inner,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.RuleTransparency,
				BorderSizePixel        = 0,
				Size                   = UDim2.new(1, 0, 0, 1),
				LayoutOrder            = Index,
			})
			Height += 2
		else
			local Entry = New("TextButton", {
				Parent                 = Inner,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 0, EntryHeight),
				LayoutOrder            = Index,
				ZIndex                 = 62,
			}, {
				Corner(Util.Radius(Options, Metrics.RowRadius)),
			})
			Text({
				Parent           = Entry,
				Text             = tostring(Item.Label or Item),
				TextSize         = Metrics.ValueSize,
				TextTransparency = Item.Color and 0 or Theme.TextSecondary,
				TextColor3       = Item.Color or Theme.White,
				TextYAlignment   = Enum.TextYAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Position         = UDim2.new(0, 9, 0, 0),
				Size             = UDim2.new(1, -13, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
				ZIndex           = 63,
			})
			if Item.Shortcut then
				Text({
					Parent           = Entry,
					Text             = Item.Shortcut,
					FontFace         = Theme.FontMono,
					TextSize         = Metrics.MonoSize,
					TextTransparency = Theme.TextDisabled,
					TextXAlignment   = Enum.TextXAlignment.Right,
					TextYAlignment   = Enum.TextYAlignment.Center,
					Position         = UDim2.new(0, 0, 0, 0),
					Size             = UDim2.new(1, -9, 1, 0),
					AutomaticSize    = Enum.AutomaticSize.None,
					ZIndex           = 63,
				})
			end
			Entry.MouseEnter:Connect(function()
				Tween(Entry, { BackgroundTransparency = 0.9 }, "hover")
			end)
			Entry.MouseLeave:Connect(function()
				Tween(Entry, { BackgroundTransparency = 1 }, "hover")
			end)
			Entry.Activated:Connect(function()
				Handle:Close()
				if Item.Callback then
					task.spawn(Item.Callback, Item)
				elseif Options.Callback then
					task.spawn(Options.Callback, Item)
				end
			end)
			Height += EntryHeight + 1
		end
	end
	function Handle:Show(X, Y)
		Open = true
		Armed = os.clock() + 0.15
		local Origin = Layer.AbsolutePosition
		local Viewport = Screen.Get().AbsoluteSize
		local Left = X - Origin.X
		local Top = Y - Origin.Y
		if Viewport.X > 0 and X + Width > Viewport.X - 8 then
			Left -= Width
		end
		if Viewport.Y > 0 and Y + Height > Viewport.Y - 8 then
			Top -= Height
		end
		Menu.Position = UDim2.fromOffset(Left, Top)
		Menu.Visible = true
		Inner.GroupTransparency = 1
		if Options.Reveal then
			Menu.Size = UDim2.new(0, Width, 0, Height)
			if Opening then
				Opening.Cancel()
			end
			Opening = Reveal.Plate(Inner, {
				Parent = Menu,
				Rect   = { 0, 0, Width, Height },
				To     = 0,
				From   = Options.From,
				Radius = Util.Radius(Options, Metrics.CardRadius),
			})
		end
		if not Opening or not Opening.Face then
			Menu.Size = UDim2.new(0, Width, 0, 0)
			Tween(Menu, { Size = UDim2.new(0, Width, 0, Height) }, "reveal")
			Tween(Inner, { GroupTransparency = 0 }, "fade")
		end
		return Handle
	end
	function Handle:ShowAtMouse()
		local Point = UserInputService:GetMouseLocation()
		return Handle:Show(Point.X, Point.Y)
	end
	function Handle:Close()
		if not Open then
			return Handle
		end
		Open = false
		Tween(Menu, { Size = UDim2.new(0, Width, 0, 0) }, "snap")
		Tween(Inner, { GroupTransparency = 1 }, "exit")
		task.delay(MotionTime("snap"), function()
			if not Open then
				Menu.Visible = false
			end
		end)
		return Handle
	end
	function Handle:IsOpen()
		return Open
	end
	local Armed = 0
	local Outside = UserInputService.InputBegan:Connect(function(Input)
		if not Open or os.clock() < Armed then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local Point = Input.Position
		local Top, Size = Menu.AbsolutePosition, Menu.AbsoluteSize
		if not (Point.X >= Top.X and Point.X <= Top.X + Size.X
			and Point.Y >= Top.Y and Point.Y <= Top.Y + Size.Y) then
			Handle:Close()
		end
	end)
	function Handle:Destroy()
		Outside:Disconnect()
		Menu:Destroy()
	end
	return Handle
end
function Layers.Prompt(Options)
	Options = Options or {}
	local Handle = {}
	local Width = Options.Width or 340
	local Answered = false
	local Blur = nil
	Screen.Enter()
	local Backdrop = New("Frame", {
		Name                   = "PromptBackdrop",
		Parent                 = Screen.Get(),
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 70,
	})
	Screen.Cover(Backdrop)
	local Modal = New("TextButton", {
		Parent                 = Backdrop,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Active                 = true,
		Selectable             = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		Modal                  = true,
		ZIndex                 = 70,
	})
	local Root = New("Frame", {
		Name                   = "Prompt",
		Parent                 = Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = Options.Position or UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 71,
	})
	local Group = New("CanvasGroup", {
		Parent                 = Root,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		GroupTransparency      = 1,
		ZIndex                 = 71,
	})
	local Column = New("Frame", {
		Parent                 = Group,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Padding(22, 26, 20, 26),
		List(8),
	})
	local Variant = Options.Variant or "Rules"
	local function Side(Anchor)
		local Edge = New("Frame", {
			Parent                 = Group,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(Anchor, 0),
			Position               = UDim2.new(Anchor, 0, 0, 0),
			Size                   = UDim2.new(0, 1, 0, 0),
			ZIndex                 = 72,
		})
		return Edge
	end
	local LeftRule, RightRule = nil, nil
	local function Stretch(Animate)
		if not LeftRule then
			return
		end
		local Tall = Column.AbsoluteSize.Y
		for _, Edge in { LeftRule, RightRule } do
			if Animate == false then
				Motion.Halt(Edge, "Size")
				Edge.Size = UDim2.new(0, 1, 0, Tall)
			else
				Tween(Edge, { Size = UDim2.new(0, 1, 0, Tall) }, "reveal")
			end
		end
	end
	if Variant == "Rules" then
		LeftRule, RightRule = Side(0), Side(1)
		Column:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			Stretch(true)
		end)
	else
		Group.BackgroundColor3 = Options.Fill or Theme.Scrim
		Group.BackgroundTransparency = Options.FillTransparency == nil
			and 0.08 or Options.FillTransparency
		Corner(Util.Radius(Options, Metrics.CardRadius)).Parent = Group
		if Options.Stroke ~= false then
			Stroke(Theme.White, 0.82, 1).Parent = Group
		end
	end
	Text({
		Parent      = Column,
		Text        = Options.Title or "",
		TextSize    = Metrics.SectionTitleSize + 2,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	if Options.Text then
		Text({
			Parent           = Column,
			Text             = Options.Text,
			TextSize         = Metrics.BodySize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	local Slot = New("Frame", {
		Name                   = "Slot",
		Parent                 = Column,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = 3,
	}, {
		List(8),
	})
	local Buttons = New("Frame", {
		Parent                 = Column,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Metrics.TabHeight + 8),
		LayoutOrder            = 4,
	}, {
		Strip(8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom),
	})
	local Key = nil
	local function Finish(Choice)
		if Answered then
			return
		end
		Answered = true
		Screen.Exit()
		Modal.Modal = false
		Modal.Active = false
		Backdrop.Visible = false
		if Key then
			Key:Disconnect()
		end
		if Blur then
			Tween(Blur, { Size = 0 }, "exit")
		end
		Tween(Group, { GroupTransparency = 1 }, "exit")
		if LeftRule then
			Tween(LeftRule, { Size = UDim2.new(0, 1, 0, 0) }, "exit")
			Tween(RightRule, { Size = UDim2.new(0, 1, 0, 0) }, "exit")
		end
		task.delay(MotionTime("exit") * 1.2, function()
			if Blur then
				Blur:Destroy()
			end
			Root:Destroy()
			Backdrop:Destroy()
		end)
		if Options.Callback then
			task.spawn(Options.Callback, Choice)
		end
	end
	for Index, Button in Options.Buttons or { { Label = "OK" } } do
		local Primary = Button.Primary == true
		local Accent = Button.Color or Theme.White
		local Pill = New("TextButton", {
			Parent                 = Buttons,
			BackgroundColor3       = Accent,
			BackgroundTransparency = Primary and 0 or 0.88,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, Metrics.TabHeight),
			LayoutOrder            = Index,
		}, {
			Corner(Round(Options, math.floor(Metrics.TabHeight / 2))),
			Padding(0, 16),
		})
		New("TextLabel", {
			Parent                 = Pill,
			BackgroundTransparency = 1,
			Text                   = Button.Label or "OK",
			TextColor3             = Primary and Theme.Black or Accent,
			FontFace               = Theme.FontMedium,
			TextSize               = Metrics.BodySize,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			ZIndex                 = 2,
		})
		local Hit = Pill
		Hit.MouseEnter:Connect(function()
			Tween(Pill, { BackgroundTransparency = Primary and 0.15 or 0.78 }, "hover")
		end)
		Hit.MouseLeave:Connect(function()
			Tween(Pill, { BackgroundTransparency = Primary and 0 or 0.88 }, "hover")
		end)
		Hit.Activated:Connect(function()
			if Button.Callback then
				task.spawn(Button.Callback)
			end
			Finish(Button.Value or Button.Label)
		end)
	end
	function Handle:Close(Choice)
		Finish(Choice)
		return Handle
	end
	function Handle:Slot()
		return Slot
	end
	Handle.Root = Root
	Handle.Frame = Root
	local BlurSize = Options.Blur == nil and 18 or Options.Blur
	if BlurSize > 0 then
		Blur = New("BlurEffect", { Parent = Lighting, Size = 0, Name = "KuikBlur" })
		Tween(Blur, { Size = BlurSize }, "enter")
	end
	if LeftRule then
		LeftRule.Size = UDim2.new(0, 1, 0, 0)
		RightRule.Size = UDim2.new(0, 1, 0, 0)
	end
	Tween(Backdrop, { BackgroundTransparency = Options.Wash == nil and 0.45 or Options.Wash }, "enter")
	if Options.Reveal then
		task.defer(function()
			local Arrived = Group.Parent and Reveal.Plate(Group, {
				Parent = Group.Parent,
				Now    = true,
				To     = 0,
				From   = Options.From,
				Radius = Util.Radius(Options, Metrics.CardRadius),
			})
			if not Arrived or not Arrived.Face then
				Tween(Group, { GroupTransparency = 0 }, "enter")
			end
		end)
	else
		Tween(Group, { GroupTransparency = 0 }, "enter")
	end
	task.defer(function()
		Stretch(true)
	end)
	Key = UserInputService.InputBegan:Connect(function(Input, Processed)
		if Processed then
			return
		end
		if Input.KeyCode == Enum.KeyCode.Escape and Options.Dismissable ~= false then
			Finish(nil)
		elseif Input.KeyCode == Enum.KeyCode.Return and Options.Confirm then
			Finish(Options.Confirm)
		end
	end)
	return Handle
end
function Layers.Cards(Options)
	Options = Options or {}
	local Deck = {}
	local Windows = {}
	local Focus = 1
	local Reach = math.huge
	local Dead = false
	local Gap = Options.Gap or 110
	local Shrink = Options.Scale or 0.82
	local Dim = Options.Fade or 0.55
	local Grey = Options.Grey or 0.45
	local Layer = Options.Parent or Screen.Get()
	local Offsets = { [-1] = -300, [1] = 300 }
	local function Arrow(Direction)
		local Button = New("TextButton", {
			Name                   = Direction < 0 and "Previous" or "Next",
			Parent                 = Layer,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, 46, 0, 92),
			Visible                = false,
			ZIndex                 = 1200,
		})
		local Arms = {}
		for Index = 1, 2 do
			Arms[Index] = New("Frame", {
				Parent                 = Button,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 0.35,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, 0.5, Index == 1 and -7 or 7),
				Size                   = UDim2.new(0, 20, 0, 2),
				Rotation               = Direction * (Index == 1 and -46 or 46),
			}, {
				Corner(1),
			})
		end
		local Bar = New("Frame", {
			Parent                 = Button,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.8,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, Direction * 15, 0.5, 0),
			Size                   = UDim2.new(0, 1, 0.62, 0),
		})
		local function Light(On)
			for _, Arm in Arms do
				Tween(Arm, { BackgroundTransparency = On and 0 or 0.35 }, "hover")
			end
			Tween(Bar, { BackgroundTransparency = On and 0.5 or 0.8 }, "hover")
			Tween(Button, {
				Position = UDim2.new(0.5, Offsets[Direction] + (On and Direction * 4 or 0), 0.5, 0),
			}, "toss")
		end
		Button.MouseEnter:Connect(function() Light(true) end)
		Button.MouseLeave:Connect(function() Light(false) end)
		return Button
	end
	local Previous, Next = Arrow(-1), Arrow(1)
	local Counter = New("TextLabel", {
		Name                   = "DeckCount",
		Parent                 = Layer,
		BackgroundTransparency = 1,
		Text                   = "",
		TextColor3             = Theme.White,
		TextTransparency       = Theme.TextTertiary,
		FontFace               = Theme.FontMono,
		TextSize               = Metrics.MonoBoldSize,
		AnchorPoint            = Vector2.new(0.5, 1),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, 80, 0, 14),
		Visible                = false,
		ZIndex                 = 1200,
	})
	local function Layout(Animate, Fresh)
		if Dead then
			return
		end
		for Index, Entry in Windows do
			local Window = Entry.Window
			if not Window:IsAlive() then
				continue
			end
			local Offset = Index - Focus
			local Centre = Offset == 0
			local Step = Window.Root.AbsoluteSize.X * Shrink + Gap
			local X = Offset * Step
			Window.Root.ZIndex = 1000 - math.abs(Offset)
			Window.Root.Visible = true
			local Target = UDim2.new(0.5, X, 0.5, 0)
			local Scale = Centre and 1 or Shrink
			local Transparency = Centre and 0 or Dim
			local Moves = Animate and Index ~= Fresh
			Window:SetPosition(Target, Moves and "layout" or false)
			if Moves then
				Tween(Entry.Scale, { Scale = Scale }, "layout")
				Tween(Window.Canvas, { GroupTransparency = Transparency }, "fade")
			else
				Motion.Halt(Entry.Scale, "Scale")
				Motion.Halt(Window.Canvas, "GroupTransparency")
				Entry.Scale.Scale = Scale
				Window.Canvas.GroupTransparency = Transparency
			end
			for _, Child in Window:Children() do
				Child.Root.Visible = Centre and Child:IsOpen()
				if Animate then
					Tween(Child.Canvas, { GroupTransparency = Transparency }, "fade")
				else
					Motion.Halt(Child.Canvas, "GroupTransparency")
					Child.Canvas.GroupTransparency = Transparency
				end
			end
		end
		local Focused = Windows[Focus]
		if Focused and Focused.Window:IsAlive() then
			local Half = Focused.Window.Root.AbsoluteSize.X / 2 + 34
			Offsets[-1] = -Half
			Offsets[1] = Half
			Tween(Previous, { Position = UDim2.new(0.5, -Half, 0.5, 0) },
				Animate and "layout" or "instant")
			Tween(Next, { Position = UDim2.new(0.5, Half, 0.5, 0) },
				Animate and "layout" or "instant")
			local Height = Focused.Window.Root.AbsoluteSize.Y / 2 + 26
			Counter.Position = UDim2.new(0.5, 0, 0.5, Height)
			SwapText(Counter, string.format("%d / %d", Focus, #Windows))
		end
		Previous.Visible = Focus > 1
		Next.Visible = Focus < math.min(#Windows, Reach)
		Counter.Visible = #Windows > 1
	end
	local function Shade(Entry, On, Animate)
		local Guard = Entry.Guard
		if not Guard then
			return
		end
		if On then
			Guard.Visible = true
			Tween(Guard, { BackgroundTransparency = Grey },
				Animate ~= false and "fade" or "instant")
			return
		end
		if Animate == false then
			Motion.Halt(Guard, "BackgroundTransparency")
			Guard.BackgroundTransparency = 1
			Guard.Visible = false
			return
		end
		Tween(Guard, { BackgroundTransparency = 1 }, "fade")
		task.delay(MotionTime("fade"), function()
			if Guard.Parent and Guard.BackgroundTransparency > 0.98 then
				Guard.Visible = false
			end
		end)
	end
	function Deck:Refresh(Animate)
		for Index, Entry in Windows do
			Shade(Entry, Index ~= Focus, Animate)
		end
		return Deck
	end
	function Deck:Add(Window)
		Window:SetParallax(0)
		local Scale = Window.Root:FindFirstChildOfClass("UIScale")
			or New("UIScale", { Parent = Window.Root, Scale = 1 })
		local Entry = { Window = Window, Scale = Scale }
		table.insert(Windows, Entry)
		if Options.Manual ~= true and not Window:IsOpen() then
			local Wait = (#Windows - 1) * (Options.Stagger or 0.05)
			if Wait > 0 then
				task.delay(Wait, function()
					if Window:IsAlive() and not Window:IsOpen() then
						Window:Open()
					end
				end)
			else
				Window:Open()
			end
		end
		local Guard = New("TextButton", {
			Name                   = "CardGuard",
			Parent                 = Window.Root,
			BackgroundColor3       = Options.GreyColor or Theme.Scrim,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			Visible                = false,
			ZIndex                 = 50,
		}, {
			Corner(Util.Radius(Options, Metrics.CardRadius)),
		})
		Entry.Guard = Guard
		Guard.Activated:Connect(function()
			local At = table.find(Windows, Entry)
			if At and At <= Reach then
				Deck:Focus(At)
			end
		end)
		Window:OnDestroy(function()
			Deck:Forget(Window)
		end)
		Layout(#Windows > 1, #Windows)
		Deck:Refresh(#Windows > 1)
		task.defer(function()
			if #Windows > 0 then
				Layout(false)
			end
		end)
		Entry.Sizing = Window.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if #Windows > 0 then
				Layout(false)
			end
		end)
		return Window, #Windows
	end
	function Deck:Forget(Window)
		if Dead then
			return Deck
		end
		for Index, Entry in Windows do
			if Entry.Window == Window then
				if Entry.Guard then
					Entry.Guard:Destroy()
				end
				if Entry.Sizing then
					Entry.Sizing:Disconnect()
				end
				table.remove(Windows, Index)
				break
			end
		end
		Focus = Clamp(Focus, 1, math.max(1, #Windows))
		Layout(true)
		Deck:Refresh()
		return Deck
	end
	function Deck:Remove(Index)
		local Entry = Windows[Index]
		if Entry then
			table.remove(Windows, Index)
			if Entry.Guard then
				Entry.Guard:Destroy()
			end
			Entry.Window:Destroy()
		end
		Focus = Clamp(Focus, 1, math.max(1, #Windows))
		Layout(true)
		Deck:Refresh()
		return Deck
	end
	function Deck:Focus(Index)
		Focus = Clamp(Index, 1, math.max(1, math.min(#Windows, Reach)))
		Layout(true)
		Deck:Refresh()
		if Options.Callback then
			task.spawn(Options.Callback, Focus, Windows[Focus] and Windows[Focus].Window)
		end
		return Deck
	end
	function Deck:Next()
		return Deck:Focus(Focus + 1)
	end
	function Deck:Previous()
		return Deck:Focus(Focus - 1)
	end
	function Deck:Focused()
		return Focus, Windows[Focus] and Windows[Focus].Window
	end
	function Deck:Count()
		return #Windows
	end
	function Deck:SetReach(Index)
		Reach = Index or math.huge
		if Focus > Reach then
			return Deck:Focus(Reach)
		end
		Layout(true)
		Deck:Refresh()
		return Deck
	end
	function Deck:Reach()
		return Reach
	end
	function Deck:Windows()
		local Out = {}
		for Index, Entry in Windows do
			Out[Index] = Entry.Window
		end
		return Out
	end
	local Camera = workspace.CurrentCamera
	local Resize = Camera and Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if #Windows > 0 then
			Layout(false)
		end
	end)
	Previous.Activated:Connect(function() Deck:Previous() end)
	Next.Activated:Connect(function() Deck:Next() end)
	local Keys = UserInputService.InputBegan:Connect(function(Input, Processed)
		if Processed or #Windows < 2 or Screen.Blocked() then
			return
		end
		if Input.KeyCode == Enum.KeyCode.Left or Input.KeyCode == Enum.KeyCode.Q then
			Deck:Previous()
		elseif Input.KeyCode == Enum.KeyCode.Right or Input.KeyCode == Enum.KeyCode.E then
			Deck:Next()
		end
	end)
	function Deck:Destroy(Keep, Animate)
		if Dead then
			return
		end
		Dead = true
		if Resize then
			Resize:Disconnect()
		end
		Keys:Disconnect()
		Previous:Destroy()
		Next:Destroy()
		Counter:Destroy()
		local Leaving = table.clone(Windows)
		table.clear(Windows)
		for _, Entry in Leaving do
			if Entry.Guard then
				Entry.Guard:Destroy()
			end
			if Entry.Sizing then
				Entry.Sizing:Disconnect()
			end
			if not Keep and Entry.Window.Destroy then
				Entry.Window:Destroy(Animate == true)
			end
		end
	end
	return Deck
end
local function Panel(Options, Build)
	local Layer = Options.Parent or Screen.Get()
	local Frame = New("Frame", {
		Name                   = Options.Name or "Panel",
		Parent                 = Layer,
		BorderSizePixel        = 0,
		Visible                = false,
		ZIndex                 = Options.ZIndex or 65,
	})
	local Inner = New("CanvasGroup", {
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		GroupTransparency      = 1,
		ZIndex                 = (Options.ZIndex or 65) + 1,
	}, {
		Padding(Options.Inset or 12),
		List(Options.Gap or Metrics.RowGap),
	})
	Shell(Frame, Inner, Util.Merge(Options, {
		FillTransparency = Options.FillTransparency,
		EdgeTransparency = Options.Stroke == false and 1 or nil,
	}), "Card")
	local Order = 0
	local Handle = { Frame = Frame, Body = Inner }
	function Handle:_Mount()
		return Inner
	end
	function Handle:_Order()
		Order += 1
		return Order
	end
	function Handle:_Overlay()
		return Layer
	end
	function Handle:_Register() end
	function Handle:_Window()
		return Options.Window
	end
	Build(Handle, Frame, Inner)
	return Attach(Handle)
end
function Layers.Popover(Options)
	Options = Options or {}
	local Width = Options.Width or 220
	local Open = false
	local Anchor = Options.Anchor
	local Handle
	Handle = Panel(Util.Merge(Options, { Name = "Popover", ZIndex = 65 }), function(Self, Frame, Inner)
		Frame.Size = UDim2.new(0, Width, 0, 0)
		Frame.AutomaticSize = Enum.AutomaticSize.Y
		Inner.Size = UDim2.new(1, 0, 0, 0)
		Inner.AutomaticSize = Enum.AutomaticSize.Y
		local Beak = New("Frame", {
			Name             = "Beak",
			Parent           = Frame,
			BackgroundColor3 = Options.Fill or Theme.Scrim,
			BorderSizePixel  = 0,
			AnchorPoint      = Vector2.new(0.5, 0.5),
			Size             = UDim2.new(0, 8, 0, 8),
			Rotation         = 45,
			ZIndex           = (Options.ZIndex or 65) - 1,
		})
		function Self:SetAnchor(Object)
			Anchor = Object
			return Self
		end
		local function Place()
			if not Anchor then
				Frame.Position = Options.Position or UDim2.new(0.5, 0, 0.5, 0)
				Beak.Visible = false
				return
			end
			local Origin = Frame.Parent.AbsolutePosition
			local Point = Anchor.AbsolutePosition
			local Size = Anchor.AbsoluteSize
			local Viewport = Screen.Get().AbsoluteSize
			local Below = Point.Y + Size.Y + 10
			local Height = Frame.AbsoluteSize.Y
            local Above = Viewport.Y > 0 and Below + Height > Viewport.Y - 10
			local Left = Util.Clamp(
				Point.X + Size.X / 2 - Width / 2,
				10,
				math.max(10, Viewport.X - Width - 10))
			Frame.AnchorPoint = Vector2.new(0, Above and 1 or 0)
			Frame.Position = UDim2.fromOffset(
				Left - Origin.X,
				(Above and (Point.Y - 10) or Below) - Origin.Y)
			Beak.Visible = true
			Beak.Position = UDim2.new(
				0, Point.X + Size.X / 2 - Left,
				Above and 1 or 0, Above and -1 or 1)
		end
		local Following = nil
		local Arriving = nil
		function Self:Show(NewAnchor)
			Anchor = NewAnchor or Anchor
			Open = true
			Frame.Visible = true
			Inner.GroupTransparency = 1
			task.defer(function()
				Place()
				if Options.Reveal then
					if Arriving then
						Arriving.Cancel()
					end
					Arriving = Reveal.Plate(Inner, {
						Parent = Frame,
						Now    = true,
						To     = 0,
						From   = Anchor,
						Radius = Util.Radius(Options, Metrics.CardRadius),
					})
				end
				if not Arriving or not Arriving.Face then
					Tween(Inner, { GroupTransparency = 0 }, "fade")
				end
			end)
			if Following then
				Following:Disconnect()
			end
			Following = RunService.RenderStepped:Connect(function()
				if Open then
					Place()
				end
			end)
			return Self
		end
		function Self:Close()
			if not Open then
				return Self
			end
			Open = false
			if Arriving then
				Arriving.Cancel()
				Arriving = nil
			end
			if Following then
				Following:Disconnect()
				Following = nil
			end
			Tween(Inner, { GroupTransparency = 1 }, "exit")
			task.delay(MotionTime("exit"), function()
				if not Open then
					Frame.Visible = false
				end
			end)
			return Self
		end
		function Self:IsOpen()
			return Open
		end
		function Self:Destroy()
			if Following then
				Following:Disconnect()
			end
			Frame:Destroy()
		end
		local Armed = 0
		local Outside = UserInputService.InputBegan:Connect(function(Input)
			if not Open or os.clock() < Armed then
				return
			end
			if Input.UserInputType ~= Enum.UserInputType.MouseButton1
				and Input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local Point = Input.Position
			local function Within(Object)
				if not Object then
					return false
				end
				local Top, Size = Object.AbsolutePosition, Object.AbsoluteSize
				return Point.X >= Top.X and Point.X <= Top.X + Size.X
					and Point.Y >= Top.Y and Point.Y <= Top.Y + Size.Y
			end
			if not Within(Frame) and not Within(Anchor) and Options.Dismissable ~= false then
				Self:Close()
			end
		end)
		local Opening = Self.Show
		function Self:Show(NewAnchor)
			Armed = os.clock() + 0.15
			return Opening(Self, NewAnchor)
		end
		local Base = Self.Destroy
		function Self:Destroy()
			Outside:Disconnect()
			Base(Self)
		end
	end)
	return Handle
end
function Layers.Sheet(Options)
	Options = Options or {}
	local Height = Options.Height or 260
	local Open = false
	local Backdrop = nil
	return Panel(Util.Merge(Options, { Name = "Sheet", ZIndex = 66 }), function(Self, Frame, Inner)
		Frame.AnchorPoint = Vector2.new(0.5, 0)
		Frame.Position = UDim2.new(0.5, 0, 1, 0)
		Frame.Size = UDim2.new(Options.Width and 0 or 1, Options.Width or -24, 0, Height)
		New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0),
			Position               = UDim2.new(0.5, 0, 0, 6),
			Size                   = UDim2.new(0, 34, 0, 2),
			ZIndex                 = (Options.ZIndex or 66) + 2,
		}, {
			Corner(1),
		})
		Inner.Position = UDim2.new(0, 0, 0, 8)
		Inner.Size = UDim2.new(1, 0, 1, -8)
		if Options.Backdrop ~= false then
			Backdrop = New("TextButton", {
				Name                   = "SheetBackdrop",
				Parent                 = Frame.Parent,
				BackgroundColor3       = Theme.Scrim,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 1, 0),
				Visible                = false,
				ZIndex                 = (Options.ZIndex or 66) - 1,
			})
			Screen.Cover(Backdrop)
			Backdrop.Activated:Connect(function()
				if Options.Dismissable ~= false then
					Self:Close()
				end
			end)
		end
		function Self:Show()
			Open = true
			Frame.Visible = true
			Inner.GroupTransparency = 1
			if Backdrop then
				Backdrop.Visible = true
				Tween(Backdrop, { BackgroundTransparency = Options.Wash or 0.5 }, "enter")
			end
			Tween(Frame, { Position = UDim2.new(0.5, 0, 1, -(Height + (Options.Inset or 12))) }, "reveal")
			Tween(Inner, { GroupTransparency = 0 }, "fade")
			return Self
		end
		function Self:Close()
			if not Open then
				return Self
			end
			Open = false
			if Backdrop then
				Tween(Backdrop, { BackgroundTransparency = 1 }, "exit")
			end
			Tween(Frame, { Position = UDim2.new(0.5, 0, 1, 0) }, "exit")
			Tween(Inner, { GroupTransparency = 1 }, "exit")
			task.delay(MotionTime("exit") * 1.4, function()
				if not Open then
					Frame.Visible = false
					if Backdrop then
						Backdrop.Visible = false
					end
				end
			end)
			return Self
		end
		function Self:IsOpen()
			return Open
		end
		function Self:Destroy()
			Frame:Destroy()
			if Backdrop then
				Backdrop:Destroy()
			end
		end
	end)
end
function Layers.Drawer(Options)
	Options = Options or {}
	local Width = Options.Width or 240
	local Side = Options.Side or "Left"
	local Open = false
	local Backdrop = nil
	local Hidden = Side == "Right" and UDim2.new(1, Width, 0, 0) or UDim2.new(0, -Width, 0, 0)
	local Shown = Side == "Right" and UDim2.new(1, -Width, 0, 0) or UDim2.new(0, 0, 0, 0)
	return Panel(Util.Merge(Options, { Name = "Drawer", ZIndex = 64 }), function(Self, Frame, Inner)
		local Top = Screen.Inset()
		Frame.Position = UDim2.new(Hidden.X.Scale, Hidden.X.Offset, 0, Top)
		Frame.Size = UDim2.new(0, Width, 1, -Top)
		Hidden = UDim2.new(Hidden.X.Scale, Hidden.X.Offset, 0, Top)
		Shown = UDim2.new(Shown.X.Scale, Shown.X.Offset, 0, Top)
		New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(Side == "Right" and 0 or 1, 0),
			Position               = UDim2.new(Side == "Right" and 0 or 1, 0, 0, 0),
			Size                   = UDim2.new(0, 1, 1, 0),
			ZIndex                 = (Options.ZIndex or 64) + 2,
		})
		if Options.Backdrop ~= false then
			Backdrop = New("TextButton", {
				Name                   = "DrawerBackdrop",
				Parent                 = Frame.Parent,
				BackgroundColor3       = Theme.Scrim,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 1, 0),
				Visible                = false,
				ZIndex                 = (Options.ZIndex or 64) - 1,
			})
			Screen.Cover(Backdrop)
			Backdrop.Activated:Connect(function()
				if Options.Dismissable ~= false then
					Self:Close()
				end
			end)
		end
		function Self:Show()
			Open = true
			Frame.Visible = true
			Inner.GroupTransparency = 1
			if Backdrop then
				Backdrop.Visible = true
				Tween(Backdrop, { BackgroundTransparency = Options.Wash or 0.55 }, "enter")
			end
			Tween(Frame, { Position = Shown }, "reveal")
			Tween(Inner, { GroupTransparency = 0 }, "fade")
			return Self
		end
		function Self:Close()
			if not Open then
				return Self
			end
			Open = false
			if Backdrop then
				Tween(Backdrop, { BackgroundTransparency = 1 }, "exit")
			end
			Tween(Frame, { Position = Hidden }, "exit")
			Tween(Inner, { GroupTransparency = 1 }, "exit")
			task.delay(MotionTime("exit") * 1.4, function()
				if not Open then
					Frame.Visible = false
					if Backdrop then
						Backdrop.Visible = false
					end
				end
			end)
			return Self
		end
		function Self:SetOpen(Wanted)
			if Wanted then
				return Self:Show()
			end
			return Self:Close()
		end
		function Self:Flip()
			return Self:SetOpen(not Open)
		end
		function Self:IsOpen()
			return Open
		end
		function Self:Destroy()
			Frame:Destroy()
			if Backdrop then
				Backdrop:Destroy()
			end
		end
	end)
end
function Layers.Coach(Options)
	Options = Options or {}
	local Steps = Options.Steps or {}
	local At = 0
	local Layer = Options.Parent or Screen.Get()
	local Handle = {}
	local Wash = New("Frame", {
		Name                   = "CoachWash",
		Parent                 = Layer,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		Visible                = false,
		ZIndex                 = 80,
	})
	local Ring = New("Frame", {
		Name                   = "CoachRing",
		Parent                 = Layer,
		BackgroundTransparency = 1,
		Visible                = false,
		ZIndex                 = 82,
	}, {
		Corner(Metrics.CardRadius),
	})
	local Glow = Stroke(Theme.Accent, 0.1, 2)
	Glow.Parent = Ring
	local Card = New("Frame", {
		Name                   = "CoachCard",
		Parent                 = Layer,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.06,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Options.Width or 260, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		Visible                = false,
		ZIndex                 = 83,
	}, {
		Corner(Metrics.CardRadius),
		Padding(14),
		List(8),
		Stroke(Theme.White, 0.82, 1),
	})
	local Count = Text({
		Parent           = Card,
		Text             = "",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		LayoutOrder      = 1,
		ZIndex           = 84,
	})
	local Title = Text({
		Parent      = Card,
		Text        = "",
		FontFace    = Theme.FontMedium,
		TextSize    = Metrics.SubheadSize,
		TextWrapped = true,
		LayoutOrder = 2,
		ZIndex      = 84,
	})
	local Body = Text({
		Parent           = Card,
		Text             = "",
		TextSize         = Metrics.ValueSize,
		TextTransparency = Theme.TextSecondary,
		TextWrapped      = true,
		LayoutOrder      = 3,
		ZIndex           = 84,
	})
	local Buttons = New("Frame", {
		Parent                 = Card,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 26),
		LayoutOrder            = 4,
		ZIndex                 = 84,
	}, {
		Strip(8, Enum.HorizontalAlignment.Right),
	})
	local function Pill(Label, Primary, OnPress)
		local Frame = New("Frame", {
			Parent                 = Buttons,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Primary and 0 or 0.88,
			BorderSizePixel        = 0,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			ZIndex                 = 84,
		}, {
			Corner(Round(Options, 13)),
			Padding(0, 12),
		})
		New("TextLabel", {
			Parent                 = Frame,
			BackgroundTransparency = 1,
			Text                   = Label,
			TextColor3             = Primary and Theme.Black or Theme.White,
			FontFace               = Theme.FontMedium,
			TextSize               = Metrics.CaptionSize,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			ZIndex                 = 85,
		})
		local Hit = New("TextButton", {
			Parent                 = Frame,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 86,
		})
		Hit.Activated:Connect(OnPress)
		return Frame
	end
	local Skip = Pill(Options.SkipLabel or "Skip", false, function()
		Handle:Finish()
	end)
	local Next = Pill(Options.NextLabel or "Next", true, function()
		Handle:Next()
	end)
	local function Aim(Step)
		local Target = type(Step.Target) == "table" and Step.Target.Frame or Step.Target
		Count.Text = string.format("%d of %d", At, #Steps)
		Title.Text = Step.Label or ""
		Body.Text = Step.Text or ""
		Next.Visible = true
		if not Target or not Target.Parent then
			Ring.Visible = false
			Card.Position = UDim2.new(0.5, -(Options.Width or 260) / 2, 0.5, -60)
			return
		end
		local Origin = Layer.AbsolutePosition
		local Point = Target.AbsolutePosition
		local Size = Target.AbsoluteSize
		local Pad = Options.Pad or 6
		Ring.Visible = true
		Tween(Ring, {
			Position = UDim2.fromOffset(Point.X - Origin.X - Pad, Point.Y - Origin.Y - Pad),
			Size = UDim2.fromOffset(Size.X + Pad * 2, Size.Y + Pad * 2),
		}, "layout")
		local Viewport = Screen.Get().AbsoluteSize
		local Below = Point.Y + Size.Y + 14
		local Above = Viewport.Y > 0 and Below + Card.AbsoluteSize.Y > Viewport.Y - 14
		local Height = math.max(Card.AbsoluteSize.Y, 90)
		local Wanted = Above and (Point.Y - Height - 14) or Below
		local Top = Screen.Inset()
		Tween(Card, {
			Position = UDim2.fromOffset(
				Util.Clamp(Point.X - Origin.X, 12,
					math.max(12, Viewport.X - (Options.Width or 260) - 12)),
				Util.Clamp(Wanted - Origin.Y, Top + 12,
					math.max(Top + 12, Top + Viewport.Y - Height - 12))),
		}, "layout")
	end
	function Handle:Start()
		At = 0
		Wash.Visible = true
		Card.Visible = true
		Tween(Wash, { BackgroundTransparency = Options.Wash or 0.45 }, "enter")
		return Handle:Next()
	end
	function Handle:Next()
		At += 1
		if At > #Steps then
			return Handle:Finish()
		end
		local Step = Steps[At]
		if Step.Before then
			task.spawn(Step.Before)
		end
		task.defer(function()
			Aim(Step)
		end)
		if At == #Steps then
			local Label = Next:FindFirstChildOfClass("TextLabel")
			if Label then
				Label.Text = Options.DoneLabel or "Done"
			end
		end
		return Handle
	end
	function Handle:Finish()
		Tween(Wash, { BackgroundTransparency = 1 }, "exit")
		Card.Visible = false
		Ring.Visible = false
		task.delay(MotionTime("exit"), function()
			Wash.Visible = false
		end)
		if Options.Callback then
			task.spawn(Options.Callback, At > #Steps)
		end
		return Handle
	end
	function Handle:Destroy()
		Wash:Destroy()
		Ring:Destroy()
		Card:Destroy()
	end
	Handle.Frame = Card
	return Handle
end
return Layers
end
KuikModules["Layout"] = function()
local Palette  = KuikRequire("Theme")
local Util     = KuikRequire("Util")
local Motion   = KuikRequire("Motion")
local Reveal   = KuikRequire("Reveal")
local Parts    = KuikRequire("Parts")
local Scroll   = KuikRequire("Scroll")
local Controls = KuikRequire("Controls")
local Shared   = KuikRequire("Shared")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Clamp   = Util.Clamp
local Round   = Util.Round
local Tween = Motion.Tween
local Layout = {}
local function Attach(Object)
	for Name, Constructor in Controls do
		if rawget(Object, Name) ~= nil then
			error(string.format(
				"Kuik: a container already has %q, and the control of that name "
					.. "would replace it. Rename the field or method.", Name), 2)
		end
		Object[Name] = function(Self, Options)
			Options = Options or {}
			if Options.LayoutOrder == nil then
				Options.LayoutOrder = Self:_Order()
			end
			return Constructor(Self:_Mount(), Options, Self)
		end
	end
	function Object:Add(Kind, Options)
		local Constructor = Controls[Kind]
		if not Constructor then
			return nil
		end
		return Object[Kind](Object, Options)
	end
	function Object:Mount(Instance_, Options)
		Options = Options or {}
		Instance_.Parent = Object:_Mount()
		Instance_.LayoutOrder = Options.LayoutOrder or Object:_Order()
		if Options.Height then
			Instance_.Size = UDim2.new(1, 0, 0, Options.Height)
		end
		return Instance_
	end
	function Object:Clear()
		for _, Child in Object:_Mount():GetChildren() do
			if Child:IsA("GuiObject") then
				Child:Destroy()
			end
		end
		return Object
	end
	return Object
end
Shared.Attach = Attach
local function MakeSection(Window, Title, Description, Options)
	Options = Options or {}
	local Section = {}
	local Frame = New("Frame", {
		Name                   = "Section",
		Parent                 = Window:_Mount(),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Window:_Order(),
	}, {
		Padding(Options.Top or 18, Metrics.RowPadding, 4, Metrics.RowPadding),
		List(3),
	})
	Text({
		Parent      = Frame,
		Text        = Title or "",
		TextSize    = Options.TitleSize or Metrics.SectionTitleSize,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	if Description and Description ~= "" then
		Text({
			Parent           = Frame,
			Text             = Description,
			TextSize         = Options.DescriptionSize or Metrics.SectionDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	if Options.Rule then
		New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 1),
			LayoutOrder            = 3,
		})
	end
	function Section:_Mount()
		return Window:_Mount()
	end
	function Section:_Order()
		return Window:_Order()
	end
	function Section:_Overlay()
		return Window:_Overlay()
	end
	function Section:_Register(Close)
		Window:_Register(Close)
	end
	function Section:_Window()
		return Window._Window and Window:_Window() or Window
	end
	function Section:Tabs(TabOptions)
		return Layout.Tabs(Window, TabOptions)
	end
	function Section:Section(NextTitle, NextDescription, NextOptions)
		return MakeSection(Window, NextTitle, NextDescription, NextOptions)
	end
	function Section:Destroy()
		Frame:Destroy()
	end
	Section.Frame = Frame
	return Attach(Section)
end
local function Stagger(Page, Count)
	local At = 0
	for _, Child in Page:GetChildren() do
		if Child:IsA("GuiObject") and Child.Visible then
			At += 1
			if At > (Count or 9) then
				break
			end
			Motion.FadeIn(Child, (At - 1) * 0.035, "enter")
		end
	end
end
local function MakeTabs(Window, Options)
	Options = Options or {}
	local Tabs = {}
	local Pages = {}
	local Active = nil
	local Pending = true
	local Variant = Options.Variant or "Pill"
	local Accent = Util.Colour(Options, Theme.White)
	local Bar = New("Frame", {
		Name                   = "Tabs",
		Parent                 = Window:_Mount(),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Metrics.TabHeight + 14),
		LayoutOrder            = Options.LayoutOrder or Window:_Order(),
	}, {
		Padding(7, Metrics.RowPadding, 7, Metrics.RowPadding),
	})
	local Viewport = New("ScrollingFrame", {
		Name                   = "Viewport",
		Parent                 = Bar,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.X,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.X,
		ClipsDescendants       = true,
	})
	local Strip = New("Frame", {
		Name                   = "Strip",
		Parent                 = Viewport,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 2,
	}, {
		List(Options.Gap or Metrics.TabGap, Enum.FillDirection.Horizontal,
			Options.Align == "Center" and Enum.HorizontalAlignment.Center
			or Options.Align == "Right" and Enum.HorizontalAlignment.Right
			or Enum.HorizontalAlignment.Left),
	})
	local Highlight = New("Frame", {
		Name             = "Highlight",
		Parent           = Viewport,
		BackgroundColor3 = Accent,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 0, Metrics.TabHeight),
		Position         = UDim2.new(0, 0, 0, 0),
		Visible          = false,
		ZIndex           = 1,
	}, {
		Corner(Round(Options, math.floor(Metrics.TabHeight / 2))),
	})
	if Variant == "Underline" then
		Highlight.Size = UDim2.new(0, 0, 0, 2)
		Highlight.AnchorPoint = Vector2.new(0, 1)
		Highlight.Position = UDim2.new(0, 0, 1, 0)
	elseif Variant == "Rule" then
		Highlight.BackgroundTransparency = 1
	end
	local Smear = nil
	if Variant ~= "Rule" and Options.Ghost ~= false then
		Smear = Reveal.Follow(Highlight, {
			Parent = Viewport,
			Radius = Round(Options, math.floor(Metrics.TabHeight / 2)),
			ZIndex = 0,
			Reach  = Options.GhostReach or 0.5,
			Span   = Options.GhostSpan or 52,
		})
	end
	local Brackets = nil
	if Variant == "Rule" then
		Brackets = {}
		for Index = 1, 2 do
			Brackets[Index] = New("Frame", {
				Parent                 = Viewport,
				BackgroundColor3       = Accent,
				BackgroundTransparency = Theme.RuleTransparency,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(Index - 1, 0),
				Size                   = UDim2.new(0, 1, 0, Metrics.TabHeight),
				Visible                = false,
				ZIndex                 = 3,
			})
		end
	end
	local Scroller = Scroll.Attach(Viewport, "X")
	Bar.MouseEnter:Connect(function()
		if Window.Scroll then
			Window.Scroll:SetEnabled(false)
		end
	end)
	Bar.MouseLeave:Connect(function()
		if Window.Scroll then
			Window.Scroll:SetEnabled(true)
		end
	end)
	local function Reveal(Button)
		local Span = Viewport.AbsoluteCanvasSize.X - Viewport.AbsoluteSize.X
		if Span <= 0 then
			return
		end
		local Left = Button.AbsolutePosition.X - Strip.AbsolutePosition.X
		local Right = Left + Button.AbsoluteSize.X
		local Start = Viewport.CanvasPosition.X
		local Finish = Start + Viewport.AbsoluteSize.X
		local Target = Start
		if Left < Start + 12 then
			Target = Left - 12
		elseif Right > Finish - 12 then
			Target = Right - Viewport.AbsoluteSize.X + 12
		end
		Target = Clamp(Target, 0, Span)
		if math.abs(Target - Start) > 0.5 then
			Scroller:To(Vector2.new(Target, 0))
		end
	end
	local function MoveHighlight(Button, Animate)
		local X = Button.AbsolutePosition.X - Strip.AbsolutePosition.X
		local Width = Button.AbsoluteSize.X
		Highlight.Visible = Variant ~= "Rule"
		local Target = Variant == "Underline"
			and UDim2.new(0, X, 1, 0)
			or UDim2.new(0, X, 0, 0)
		local Size = Variant == "Underline"
			and UDim2.new(0, Width, 0, 2)
			or UDim2.new(0, Width, 0, Metrics.TabHeight)
		if Animate then
			Tween(Highlight, { Position = Target, Size = Size }, "morph")
		else
			Highlight.Position = Target
			Highlight.Size = Size
		end
		if Brackets then
			for Index, Bracket in Brackets do
				Bracket.Visible = true
				local Where = UDim2.new(0, X + (Index == 1 and 0 or Width), 0, 0)
				if Animate then
					Tween(Bracket, { Position = Where }, "morph")
				else
					Bracket.Position = Where
				end
			end
		end
	end
	function Tabs:Select(Name, Silent)
		local Entry = Pages[Name]
		if not Entry then
			return false
		end
		Pending = false
		if Active == Name then
			return true
		end
		for OtherName, Other in Pages do
			local Selected = OtherName == Name
			if Selected then
				Other.Page.Visible = true
				Other.Slide.PaddingTop = UDim.new(0, 14)
				Tween(Other.Slide, { PaddingTop = UDim.new(0, 0) }, "reveal")
				Stagger(Other.Page)
			else
				Other.Page.Visible = false
			end
			local OnLight = Variant == "Pill"
			Other.Label.TextColor3 = Selected and OnLight and Theme.Black or Theme.White
			Other.Label.TextTransparency = Selected and 0 or Theme.TextSecondary
			if Other.Icon then
				Other.Icon.ImageColor3 = Selected and OnLight and Theme.Black or Theme.White
				Other.Icon.ImageTransparency = Selected and 0 or Theme.TextSecondary
			end
		end
		MoveHighlight(Entry.Button, Active ~= nil)
		Reveal(Entry.Button)
		Active = Name
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Name)
		end
		return true
	end
	function Tabs:Active()
		return Active
	end
	function Tabs:Pages()
		return Pages
	end
	function Tabs:Names()
		local Out = {}
		for _, Child in Strip:GetChildren() do
			if Child:IsA("TextButton") then
				table.insert(Out, Child.Name)
			end
		end
		return Out
	end
	function Tabs:Page(Name, Icon)
		local Button = New("TextButton", {
			Name                   = Name,
			Parent                 = Strip,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, Metrics.TabHeight),
			LayoutOrder            = #Strip:GetChildren(),
			ZIndex                 = 3,
		}, {
			Padding(0, Options.TabPadding or Metrics.TabPadding),
			List(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center),
		})
		Button:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Center
		local IconLabel = nil
		if Icon then
			IconLabel = New("ImageLabel", {
				Parent                 = Button,
				BackgroundTransparency = 1,
				Image                  = Util.Asset(Icon),
				ImageColor3            = Theme.White,
				ImageTransparency      = Theme.TextSecondary,
				Size                   = UDim2.new(0, Metrics.TabIcon, 0, Metrics.TabIcon),
				LayoutOrder            = 1,
				ZIndex                 = 4,
			})
		end
		local Label = New("TextLabel", {
			Parent                 = Button,
			BackgroundTransparency = 1,
			Text                   = Name,
			TextColor3             = Theme.White,
			TextTransparency       = Theme.TextSecondary,
			FontFace               = Theme.Font,
			TextSize               = Options.TextSize or (Metrics.RowDescSize),
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			LayoutOrder            = 2,
			ZIndex                 = 4,
		})
		local Page = New("Frame", {
			Name                   = "Page_" .. Name,
			Parent                 = Window:_Mount(),
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			Visible                = false,
			LayoutOrder            = Window:_Order(),
		}, {
			List(Metrics.RowGap),
		})
		local Slide = New("UIPadding", {
			Parent     = Page,
			PaddingTop = UDim.new(0, 0),
		})
		local Order = 0
		local Handle = {
			Frame = Page,
			Tab   = Button,
			Label = Label,
			Name  = Name,
		}
		function Handle:_Mount()
			return Page
		end
		function Handle:_Order()
			Order += 1
			return Order
		end
		function Handle:_Overlay()
			return Window:_Overlay()
		end
		function Handle:_Register(Close)
			Window:_Register(Close)
		end
		function Handle:_Window()
			return Window._Window and Window:_Window() or Window
		end
		function Handle:Section(Title, Description, SectionOptions)
			return MakeSection(Handle, Title, Description, SectionOptions)
		end
		function Handle:Tabs(TabOptions)
			return MakeTabs(Handle, TabOptions)
		end
		function Handle:Select()
			return Tabs:Select(Name)
		end
		function Handle:SetLabel(NewText)
			Label.Text = NewText
			return Handle
		end
		function Handle:SetVisible(Value)
			Button.Visible = Value ~= false
			if not Button.Visible and Active == Name then
				for _, Other in Tabs:Names() do
					if Pages[Other] and Pages[Other].Button.Visible then
						Tabs:Select(Other)
						break
					end
				end
			end
			return Handle
		end
		function Handle:Destroy()
			Page:Destroy()
			Button:Destroy()
			Pages[Name] = nil
		end
		Pages[Name] = {
			Page   = Page,
			Slide  = Slide,
			Button = Button,
			Label  = Label,
			Icon   = IconLabel,
		}
		Button.Activated:Connect(function()
			Tabs:Select(Name)
		end)
		Button.MouseEnter:Connect(function()
			if Active ~= Name then
				Label.TextTransparency = Theme.TextPrimary
			end
		end)
		Button.MouseLeave:Connect(function()
			if Active ~= Name then
				Label.TextTransparency = Theme.TextSecondary
			end
		end)
		if Active == nil and Pending then
			task.defer(function()
				if Active == nil and Pending then
					Tabs:Select(Name)
				end
			end)
		end
		return Attach(Handle)
	end
	function Tabs:Destroy()
		if Smear then
			Smear:Destroy()
			Smear = nil
		end
		Scroller:Destroy()
		Bar:Destroy()
		for _, Entry in Pages do
			Entry.Page:Destroy()
		end
		table.clear(Pages)
		local At = table.find(Window.TabBars or {}, Tabs)
		if At then
			table.remove(Window.TabBars, At)
		end
	end
	Tabs.Frame = Bar
	Tabs.Viewport = Viewport
	local Root = Window._Window and Window:_Window() or Window
	if Root and Root.TabBars then
		table.insert(Root.TabBars, Tabs)
	end
	return Tabs
end
Layout.Attach  = Attach
Layout.Section = MakeSection
Layout.Tabs    = MakeTabs
Shared.Tabs    = MakeTabs
Shared.Section = MakeSection
return Layout
end
KuikModules["Motion"] = function()
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local Palette = KuikRequire("Theme")
local Theme = Palette.Tokens
local Motion = {}
local EASING_STYLES = {
	linear = Enum.EasingStyle.Linear,
	sine = Enum.EasingStyle.Sine,
	quad = Enum.EasingStyle.Quad,
	cubic = Enum.EasingStyle.Cubic,
	quart = Enum.EasingStyle.Quart,
	quint = Enum.EasingStyle.Quint,
	expo = Enum.EasingStyle.Exponential,
	exponential = Enum.EasingStyle.Exponential,
	circ = Enum.EasingStyle.Circular,
	circular = Enum.EasingStyle.Circular,
	back = Enum.EasingStyle.Back,
	elastic = Enum.EasingStyle.Elastic,
	bounce = Enum.EasingStyle.Bounce,
}
local EASING_DIRECTIONS = {
	["in"] = Enum.EasingDirection.In,
	out = Enum.EasingDirection.Out,
	inout = Enum.EasingDirection.InOut,
}
local function ResolveEasing(Name)
	if not Name or Name == "" then
		return Enum.EasingStyle.Quad, Enum.EasingDirection.Out
	end
	local Lowered = string.lower(Name)
	if Lowered == "linear" then
		return Enum.EasingStyle.Linear, Enum.EasingDirection.Out
	end
	local Direction, Style = "out", Lowered
	if string.sub(Lowered, 1, 5) == "inout" then
		Direction, Style = "inout", string.sub(Lowered, 6)
	elseif string.sub(Lowered, 1, 3) == "out" then
		Direction, Style = "out", string.sub(Lowered, 4)
	elseif string.sub(Lowered, 1, 2) == "in" then
		Direction, Style = "in", string.sub(Lowered, 3)
	end
	return EASING_STYLES[Style] or Enum.EasingStyle.Quad,
		EASING_DIRECTIONS[Direction] or Enum.EasingDirection.Out
end
local EPSILON_POSITION = 0.0005
local EPSILON_VELOCITY = 0.0005
local SpringClass = {}
SpringClass.__index = SpringClass
local function NewSpring(Position, Stiffness, Damping)
	local Frequency = math.sqrt(math.max(Stiffness, 0.0001))
	return setmetatable({
		Position  = Position,
		Velocity  = 0,
		Target    = Position,
		Frequency = Frequency,
		Ratio     = Damping / (2 * Frequency),
	}, SpringClass)
end
function SpringClass:Retune(Stiffness, Damping)
	local Frequency = math.sqrt(math.max(Stiffness, 0.0001))
	self.Frequency = Frequency
	self.Ratio = Damping / (2 * Frequency)
end
function SpringClass:Step(Delta)
	if Delta <= 0 then
		return self.Position
	end
	local Step = math.min(Delta, 1 / 20)
	local Offset = self.Position - self.Target
	local Velocity = self.Velocity
	local Frequency = self.Frequency
	local Ratio = self.Ratio
	local Position, NextVelocity
	if Ratio < 1 then
		local Damped = Frequency * math.sqrt(1 - Ratio * Ratio)
		local Decay = math.exp(-Ratio * Frequency * Step)
		local Cosine = math.cos(Damped * Step)
		local Sine = math.sin(Damped * Step)
		local First = Offset
		local Second = (Velocity + Ratio * Frequency * Offset) / Damped
		Position = Decay * (First * Cosine + Second * Sine)
		NextVelocity = Decay * (
			-Ratio * Frequency * (First * Cosine + Second * Sine)
				+ Damped * (Second * Cosine - First * Sine)
		)
	elseif Ratio == 1 then
		local Decay = math.exp(-Frequency * Step)
		local First = Offset
		local Second = Velocity + Frequency * Offset
		Position = (First + Second * Step) * Decay
		NextVelocity = Decay * (Second - Frequency * (First + Second * Step))
	else
		local Root = Frequency * math.sqrt(Ratio * Ratio - 1)
		local Slow = -Frequency * Ratio + Root
		local Fast = -Frequency * Ratio - Root
		local Second = (Velocity - Slow * Offset) / (Fast - Slow)
		local First = Offset - Second
		local SlowDecay = math.exp(Slow * Step)
		local FastDecay = math.exp(Fast * Step)
		Position = First * SlowDecay + Second * FastDecay
		NextVelocity = First * Slow * SlowDecay + Second * Fast * FastDecay
	end
	self.Position = Position + self.Target
	self.Velocity = NextVelocity
	return self.Position
end
function SpringClass:Settled()
	return math.abs(self.Position - self.Target) < EPSILON_POSITION
		and math.abs(self.Velocity) < EPSILON_VELOCITY
end
local Parts = {
	number = {
		Split = function(Value) return { Value } end,
		Build = function(P) return P[1] end,
	},
	UDim = {
		Split = function(Value) return { Value.Scale, Value.Offset } end,
		Build = function(P) return UDim.new(P[1], P[2]) end,
	},
	UDim2 = {
		Split = function(Value)
			return { Value.X.Scale, Value.X.Offset, Value.Y.Scale, Value.Y.Offset }
		end,
		Build = function(P) return UDim2.new(P[1], P[2], P[3], P[4]) end,
	},
	Vector2 = {
		Split = function(Value) return { Value.X, Value.Y } end,
		Build = function(P) return Vector2.new(P[1], P[2]) end,
	},
	Color3 = {
		Split = function(Value) return { Value.R, Value.G, Value.B } end,
		Build = function(P)
			return Color3.new(
				math.clamp(P[1], 0, 1),
				math.clamp(P[2], 0, 1),
				math.clamp(P[3], 0, 1)
			)
		end,
	},
}
local function KindOf(Value)
	local Named = Parts[typeof(Value)]
	if Named then
		return Named
	end
	if type(Value) ~= "table" then
		return nil
	end
	local X, Y = Value.X, Value.Y
	if X ~= nil and Y ~= nil then
		if type(X) == "table" and X.Scale ~= nil then
			return Parts.UDim2
		end
		if type(X) == "number" then
			return Parts.Vector2
		end
	end
	if Value.Scale ~= nil and Value.Offset ~= nil then
		return Parts.UDim
	end
	if Value.R ~= nil and Value.G ~= nil and Value.B ~= nil then
		return Parts.Color3
	end
	return nil
end
local Live = {}
local Driver = nil
local function StepAll(Delta)
	local Moving = false
	for Object, Channels in Live do
		if not Object.Parent then
			Live[Object] = nil
			continue
		end
		for Property, Channel in Channels do
			local Settled = true
			local Values = table.create(#Channel.Springs)
			for Index, Each in Channel.Springs do
				Each:Step(Delta)
				Values[Index] = Each.Position
				if not Each:Settled() then
					Settled = false
				end
			end
			if Settled then
				Object[Property] = Channel.Goal
				Channels[Property] = nil
				if Channel.Done then
					Channel.Done:Fire()
				end
			else
				Object[Property] = Channel.Kind.Build(Values)
				Moving = true
			end
		end
		if next(Channels) == nil then
			Live[Object] = nil
		end
	end
	if not Moving and next(Live) == nil and Driver then
		Driver:Disconnect()
		Driver = nil
	end
end
local function SpringTo(Object, Properties, Stiffness, Damping, Done)
	local Channels = Live[Object]
	if not Channels then
		Channels = {}
		Live[Object] = Channels
	end
	for Property, Goal in Properties do
		local Kind = KindOf(Goal)
		if Kind then
			local Wanted = Kind.Split(Goal)
			local Channel = Channels[Property]
			if Channel and #Channel.Springs == #Wanted and Channel.Kind == Kind then
				for Index, Each in Channel.Springs do
					Each:Retune(Stiffness, Damping)
					Each.Target = Wanted[Index]
				end
				Channel.Goal = Goal
				Channel.Done = Done
			else
				local Current = Kind.Split(Object[Property])
				local Springs = table.create(#Wanted)
				for Index, Value in Wanted do
					local Each = NewSpring(Current[Index] or Value, Stiffness, Damping)
					Each.Target = Value
					Springs[Index] = Each
				end
				Channels[Property] = {
					Springs = Springs,
					Kind    = Kind,
					Goal    = Goal,
					Done    = Done,
				}
			end
		else
			Object[Property] = Goal
		end
	end
	if not Driver then
		Driver = RunService.Heartbeat:Connect(StepAll)
	end
end
local function Spec(Role)
	if type(Role) == "table" then
		return Role
	end
	return Theme.Motion[Role or "item"] or Theme.Motion.item
end
local function MotionTime(Role)
	local Using = Spec(Role)
	if Using.Duration then
		return Using.Duration
	end
	return 6 / math.sqrt(math.max(Using.Stiffness or 200, 0.0001))
end
local function Finished()
	local Handlers = {}
	local Fired = false
	local Signal = {}
	function Signal:Connect(Handler)
		if Fired then
			task.spawn(Handler)
			return { Disconnect = function() end }
		end
		table.insert(Handlers, Handler)
		return {
			Disconnect = function()
				local At = table.find(Handlers, Handler)
				if At then
					table.remove(Handlers, At)
				end
			end,
		}
	end
	Signal.Once = Signal.Connect
	function Signal:Fire()
		if Fired then
			return
		end
		Fired = true
		for _, Handler in Handlers do
			task.spawn(Handler)
		end
		table.clear(Handlers)
	end
	return Signal
end
local function Tween(Object, Properties, Role)
	local Using = Spec(Role)
	if Using.Stiffness then
		local Signal = Finished()
		SpringTo(Object, Properties, Using.Stiffness, Using.Damping or 0, Signal)
		task.delay(MotionTime(Using) * 2, function()
			Signal:Fire()
		end)
		return {
			Completed = Signal,
			Cancel = function()
				for Property in Properties do
					Motion.Halt(Object, Property)
				end
			end,
		}
	end
	local Style, Direction = ResolveEasing(Using.Easing)
	local Handle = TweenService:Create(
		Object,
		TweenInfo.new(Using.Duration or 0, Style, Direction),
		Properties
	)
	Handle:Play()
	return Handle
end
local function Enter(Object, Property, Target, Role)
	local Original = Object[Property]
	Object[Property] = 1
	task.defer(function()
		if Object.Parent then
			Tween(Object, { [Property] = Target or Original }, Role or "fade")
		end
	end)
end
local RestingText = setmetatable({}, { __mode = "k" })
local function SwapText(Label, NewText)
	if Label.Text == NewText then
		return
	end
	local Rest = RestingText[Label]
	if not Rest then
		Rest = Label.TextTransparency
		RestingText[Label] = Rest
	end
	Tween(Label, { TextTransparency = 1 }, "press")
	task.delay(MotionTime("press"), function()
		if not Label.Parent then
			return
		end
		Label.Text = NewText
		Tween(Label, { TextTransparency = Rest }, "hover")
	end)
end
local function ScaleOf(Object)
	local Existing = Object:FindFirstChildOfClass("UIScale")
	if Existing then
		return Existing
	end
	local Scale = Instance.new("UIScale")
	Scale.Name = "Scale"
	Scale.Parent = Object
	return Scale
end
local Fade
local function Scale(Object, Value, Role)
	return Tween(ScaleOf(Object), { Scale = Value }, Role or "pop")
end
local function Pop(Object, Role, From)
	local Scaler = ScaleOf(Object)
	Scaler.Scale = From or 0.94
	task.defer(function()
		if Object.Parent then
			Tween(Scaler, { Scale = 1 }, Role or "pop")
		end
	end)
	return Scaler
end
local function Out(Object, Done, Role)
	if not Object or not Object.Parent then
		if Done then
			Done()
		end
		return
	end
	local Using = Role or "shrink"
	local Scaler = ScaleOf(Object)
	Tween(Scaler, { Scale = 0.92 }, Using)
	if Object:IsA("CanvasGroup") then
		Tween(Object, { GroupTransparency = 1 }, "fade")
	else
		Fade(Object, 1)
	end
	task.delay(MotionTime(Using), function()
		if Done then
			Done()
		end
	end)
end
function Fade(Object, To, Role)
	local Properties = {}
	if Object:IsA("GuiObject") and (Object.BackgroundTransparency or 1) < 1 then
		Properties.BackgroundTransparency = To
	end
	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		Properties.TextTransparency = To
	end
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		Properties.ImageTransparency = To
	end
	if Object:IsA("CanvasGroup") then
		Properties.GroupTransparency = To
	end
	if next(Properties) then
		Tween(Object, Properties, Role or "fade")
	end
	for _, Child in Object:GetChildren() do
		if Child:IsA("GuiObject") then
			Fade(Child, To, Role)
		elseif Child:IsA("UIStroke") then
			Tween(Child, { Transparency = To }, Role or "fade")
		end
	end
end
local function Resting(Object, Into)
	Into = Into or {}
	local Bits = {}
	if Object:IsA("GuiObject") and (Object.BackgroundTransparency or 1) < 1 then
		Bits.BackgroundTransparency = Object.BackgroundTransparency
	end
	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		Bits.TextTransparency = Object.TextTransparency
	end
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		Bits.ImageTransparency = Object.ImageTransparency
	end
	if Object:IsA("CanvasGroup") then
		Bits.GroupTransparency = Object.GroupTransparency
	end
	if next(Bits) then
		table.insert(Into, { Object = Object, Bits = Bits })
	end
	for _, Child in Object:GetChildren() do
		if Child:IsA("GuiObject") then
			Resting(Child, Into)
		elseif Child:IsA("UIStroke") then
			table.insert(Into, { Object = Child, Bits = { Transparency = Child.Transparency } })
		end
	end
	return Into
end
local function FadeIn(Object, Delay, Role)
	local Marks = Resting(Object)
	for _, Mark in Marks do
		for Property in Mark.Bits do
			Mark.Object[Property] = 1
		end
	end
	local function Play()
		for _, Mark in Marks do
			if Mark.Object.Parent then
				Tween(Mark.Object, Mark.Bits, Role or "fade")
			end
		end
	end
	if Delay and Delay > 0 then
		task.delay(Delay, function()
			if Object.Parent then
				Play()
			end
		end)
	else
		task.defer(function()
			if Object.Parent then
				Play()
			end
		end)
	end
	return Marks
end
local function Halt(Object, Property)
	local Channels = Live[Object]
	if not Channels then
		return
	end
	if Property then
		Channels[Property] = nil
	else
		Live[Object] = nil
	end
end
local function Paint(Object, Properties, Animate, Role)
	if Animate then
		return Tween(Object, Properties, Role or "tint")
	end
	for Property, Value in Properties do
		Halt(Object, Property)
		Object[Property] = Value
	end
	return nil
end
Motion.Spec       = Spec
Motion.Paint      = Paint
Motion.Tween      = Tween
Motion.SpringTo   = SpringTo
Motion.MotionTime = MotionTime
Motion.Finished   = Finished
Motion.Enter      = Enter
Motion.SwapText   = SwapText
Motion.Halt       = Halt
Motion.KindOf     = KindOf
Motion.Easing     = ResolveEasing
Motion.ScaleOf    = ScaleOf
Motion.Scale      = Scale
Motion.Pop        = Pop
Motion.Out        = Out
Motion.Fade       = Fade
Motion.FadeIn     = FadeIn
Motion.Resting    = Resting
return Motion
end
KuikModules["Parts"] = function()
local GuiService       = game:GetService("GuiService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Screen  = KuikRequire("Screen")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Stroke  = Util.Stroke
local Clamp   = Util.Clamp
local Tween      = Motion.Tween
local Enter      = Motion.Enter
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime
local Parts = {}
local function Layered(Parent, Gap)
	local Canvas = New("Frame", {
		Name                   = "Canvas",
		Parent                 = Parent,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	})
	local Items = New("Frame", {
		Name                   = "Items",
		Parent                 = Canvas,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		List(Gap or 1),
	})
	return Canvas, Items
end
local function SlidingMark(Parent, Options)
	Options = Options or {}
	local Mark = New("Frame", {
		Name                   = "Mark",
		Parent                 = Parent,
		BackgroundColor3       = Options.Color or Theme.White,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, 0, 0, 0),
		Size                   = UDim2.new(0, Options.Width or 1, 0, 0),
		ZIndex                 = 6,
	}, Options.Radius and { Corner(Options.Radius) } or nil)
	local Handle = { Frame = Mark }
	local Placed = false
	function Handle:To(Entry, Container)
		if not Entry then
			Tween(Mark, { BackgroundTransparency = 1 }, "fade")
			Placed = false
			return
		end
		local Offset = Entry.AbsolutePosition.Y - Container.AbsolutePosition.Y
		if Container:IsA("ScrollingFrame") then
			Offset += Container.CanvasPosition.Y
		end
		local Position = UDim2.new(0, Options.Inset or 0, 0, Offset)
		local Size = UDim2.new(0, Options.Width or 1, 0, Entry.AbsoluteSize.Y)
		if Placed then
			Tween(Mark, { Position = Position, Size = Size }, "morph")
		else
			Mark.Position = Position
			Mark.Size = Size
			Placed = true
		end
		Tween(Mark, { BackgroundTransparency = Options.Transparency or Theme.RuleTransparency }, "fade")
	end
	function Handle:Destroy()
		Mark:Destroy()
	end
	return Handle
end
local function Span(Child, Against, Vertical, Inset)
	if Against == Child.Parent then
		local Mode = Against.AutomaticSize
		local Name = Mode and tostring(Mode) or "None"
		if (Vertical and (Name == "Y" or Name == "XY"))
			or (not Vertical and (Name == "X" or Name == "XY")) then
			error("Kuik: Span cannot measure a child against a parent that "
				.. "sizes itself on the same axis; measure against the sibling "
				.. "that sets the parent's size instead", 2)
		end
	end
	local function Fit()
		local Size = Against.AbsoluteSize
		if Vertical then
			Child.Size = UDim2.new(
				Child.Size.X.Scale, Child.Size.X.Offset,
				0, math.max(0, Size.Y - (Inset or 0)))
		else
			Child.Size = UDim2.new(
				0, math.max(0, Size.X - (Inset or 0)),
				Child.Size.Y.Scale, Child.Size.Y.Offset)
		end
	end
	local Connection = Against:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
	task.defer(Fit)
	return Connection
end
local Offsets = {}
local function Learn(Space, Point, Object)
	if Offsets[Space] then
		return
	end
	local Origin = Object.AbsolutePosition
	local Size = Object.AbsoluteSize
	if Size.X <= 0 or Size.Y <= 0 then
		return
	end
	local Gap = GuiService:GetGuiInset()
	local function Inside(Shift)
		local X, Y = Point.X + Shift.X, Point.Y + Shift.Y
		return X >= Origin.X and X <= Origin.X + Size.X
			and Y >= Origin.Y and Y <= Origin.Y + Size.Y
	end
	for _, Candidate in { Vector2.new(0, 0), Gap, Vector2.new(-Gap.X, -Gap.Y) } do
		if Inside(Candidate) then
			Offsets[Space] = Candidate
			return
		end
	end
end
local function Shift(Space)
	return Offsets[Space] or Vector2.new(0, 0)
end
local function Locate(Space, Point, Object)
	local Origin = Object.AbsolutePosition
	local Size = Object.AbsoluteSize
	if Size.X <= 0 or Size.Y <= 0 then
		return nil
	end
	local Correction = Shift(Space)
	local X = (Point.X + Correction.X - Origin.X) / Size.X
	local Y = (Point.Y + Correction.Y - Origin.Y) / Size.Y
	if X < 0 or X > 1 or Y < 0 or Y > 1 then
		return nil
	end
	return X, Y
end
local function Draggable(Target, Surface, OnMove, OnEnd)
	local Connections = {}
	local Dragging = false
	local function Report(Point)
		local Origin = Surface.AbsolutePosition
		local Size = Surface.AbsoluteSize
		local Correction = Shift("Input")
		OnMove(
			Size.X > 0 and Clamp((Point.X + Correction.X - Origin.X) / Size.X, 0, 1) or 0,
			Size.Y > 0 and Clamp((Point.Y + Correction.Y - Origin.Y) / Size.Y, 0, 1) or 0
		)
	end
	table.insert(Connections, Target.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			Learn("Input", Input.Position, Target)
			Report(Input.Position)
		end
	end))
	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch) then
			Report(Input.Position)
		end
	end))
	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch) then
			Dragging = false
			if OnEnd then
				OnEnd()
			end
		end
	end))
	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
	end
end
local Tip = nil
local TipTrack = nil
local function Tooltip(Object, Content)
	local function Ensure()
		if Tip and Tip.Parent then
			return Tip
		end
		Tip = New("Frame", {
			Name                   = "Tooltip",
			Parent                 = Screen.Get(),
			BackgroundColor3       = Theme.Scrim,
			BackgroundTransparency = 0.08,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 1),
			AutomaticSize          = Enum.AutomaticSize.XY,
			Size                   = UDim2.new(0, 0, 0, 0),
			Visible                = false,
			ZIndex                 = 90,
		}, {
			Corner(Metrics.ChipRadius),
			Padding(5, 9),
			Stroke(Theme.White, 0.82, 1),
		})
		Text({
			Parent           = Tip,
			Name             = "Label",
			Text             = "",
			TextSize         = Metrics.ValueSize,
			TextTransparency = Theme.TextSecondary,
			AutomaticSize    = Enum.AutomaticSize.XY,
			Size             = UDim2.new(0, 0, 0, 0),
			ZIndex           = 91,
		})
		return Tip
	end
	local Connections = {}
	table.insert(Connections, Object.MouseEnter:Connect(function()
		local Frame = Ensure()
		Frame.Label.Text = Content
		Frame.Visible = true
		Frame.BackgroundTransparency = 1
		Frame.Label.TextTransparency = 1
		TipTrack = Object
		Tween(Frame, { BackgroundTransparency = 0.08 }, "hint")
		Tween(Frame.Label, { TextTransparency = Theme.TextSecondary }, "hint")
		local Point = Object.AbsolutePosition
		Frame.Position = UDim2.fromOffset(Point.X, Point.Y - 4)
	end))
	table.insert(Connections, Object.MouseLeave:Connect(function()
		if Tip and TipTrack == Object then
			Tip.Visible = false
			TipTrack = nil
		end
	end))
	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
	end
end
local function Common(Handle, Frame, Options, Bits)
	Bits = Bits or {}
	Options = Options or {}
	local Disabled = Options.Disabled == true
	local Cleanup = {}
	Handle.Frame = Frame
	Handle.Options = Options
	function Handle:IsVisible()
		return Frame.Visible
	end
	function Handle:SetVisible(Value, Animate)
		if Animate and Value then
			Frame.Visible = true
			Enter(Frame, "BackgroundTransparency", Frame.BackgroundTransparency, "fade")
		else
			Frame.Visible = Value ~= false
		end
		return Handle
	end
	function Handle:IsDisabled()
		return Disabled
	end
	function Handle:SetDisabled(Value)
		Disabled = Value ~= false
		Tween(Frame, { BackgroundTransparency = Disabled
			and 1
			or (Options.Flat and 1 or Theme.RowTransparency) }, "fade")
		for _, Object in Bits.Inputs or {} do
			Object.Active = not Disabled
			Object.Selectable = not Disabled
			Object.AutoButtonColor = false
		end
		for _, Object in Bits.Dim or {} do
			if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
				Tween(Object, { TextTransparency = Disabled and Theme.TextDisabled or Theme.TextSecondary }, "fade")
			elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
				Tween(Object, { ImageTransparency = Disabled and Theme.TextDisabled or 0 }, "fade")
			end
		end
		return Handle
	end
	if Bits.Label then
		function Handle:SetLabel(NewText)
			SwapText(Bits.Label, NewText)
			return Handle
		end
	end
	if Bits.Description then
		function Handle:SetDescription(NewText)
			SwapText(Bits.Description, NewText)
			return Handle
		end
	end
	local function Teardown()
		for _, Stop in Cleanup do
			Stop()
		end
		table.clear(Cleanup)
		if Bits.Destroy then
			Bits.Destroy()
		end
		Frame:Destroy()
	end
	function Handle:Destroy(Animate)
		if not Animate or not Frame.Parent then
			Teardown()
			return
		end
		Frame.Active = false
		Motion.Out(Frame, Teardown)
	end
	function Handle:OnDestroy(Stop)
		table.insert(Cleanup, Stop)
		return Handle
	end
	if Options.Tooltip then
		table.insert(Cleanup, Tooltip(Frame, Options.Tooltip))
	end
	if Options.Visible == false then
		Frame.Visible = false
	end
	if Options.Enter then
		Motion.Pop(Frame, type(Options.Enter) == "string" and Options.Enter or "pop")
		Enter(Frame, "BackgroundTransparency", Frame.BackgroundTransparency, "fade")
	end
	if Options.Reveal then
		task.defer(function()
			if Frame.Parent then
				KuikRequire("Reveal").Plate(Frame, {
					From   = type(Options.Reveal) == "table" and Options.Reveal.From or nil,
					Radius = Util.Radius(Options, Metrics.RowRadius),
				})
			end
		end)
	end
	if Disabled then
		task.defer(function()
			Handle:SetDisabled(true)
		end)
	end
	return Handle
end
local function Dress(Frame, Options, Fallback, Against)
	local Variant = Options.Variant or (Options.Flat and "Flat") or Fallback or "Filled"
	local Colour = Options.Color
	if Variant == "Flat" or Variant == "Ghost" then
		Frame.BackgroundTransparency = 1
	elseif Variant == "Outline" then
		Frame.BackgroundTransparency = 1
		Stroke(Colour or Theme.White, 0.7, 1).Parent = Frame
	elseif Variant == "Solid" then
		Frame.BackgroundColor3 = Colour or Theme.White
		Frame.BackgroundTransparency = 0.86
	elseif Variant == "Rule" then
		Frame.BackgroundTransparency = 1
		local Accent = New("Frame", {
			Name             = "Accent",
			Parent           = Frame,
			BackgroundColor3 = Colour or Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel  = 0,
			Size             = UDim2.new(0, 1, Against and 0 or 1, 0),
			ZIndex           = 3,
		})
		if Against then
			Span(Accent, Against, true)
		end
	else
		Frame.BackgroundColor3 = Theme.White
		Frame.BackgroundTransparency = Theme.RowTransparency
	end
	return Variant
end
local function Reactive(Variant)
	return Variant ~= "Flat" and Variant ~= "Ghost" and Variant ~= "Outline"
end
local function Row(Parent, Options)
	Options = Options or {}
	local HasDescription = Options.Description ~= nil and Options.Description ~= ""
	local Reserve = Options.Reserve or Metrics.ToggleWidth
	local Pad = Options.Padding or Metrics.RowPadding
	local Frame = New("TextButton", {
		Name                   = Options.Name or "Row",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RowTransparency,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Util.Radius(Options, Metrics.RowRadius)),
		Padding(10, Pad, 10, Pad),
	})
	New("UISizeConstraint", {
		Parent  = Frame,
		MinSize = Vector2.new(0, Options.Height
			or (HasDescription and Metrics.RowHeightTall or Metrics.RowHeight)),
	})
	local Stack = New("Frame", {
		Name                   = "Stack",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		List(Options.Gap or 8),
	})
	local Variant = Dress(Frame, Options, nil, Stack)
	local MountHeight = Options.MountHeight or 26
	local Head = New("Frame", {
		Name                   = "Head",
		Parent                 = Stack,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = 1,
	}, {
		New("UIListLayout", {
			Padding             = UDim.new(0, 8),
			FillDirection       = Enum.FillDirection.Horizontal,
			SortOrder           = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
		}),
	})
	local Icon = nil
	if Options.Icon then
		Icon = New("ImageLabel", {
			Name                   = "Icon",
			Parent                 = Head,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Options.Icon),
			ImageColor3            = Options.IconColor or Theme.White,
			ImageTransparency      = Theme.TextSecondary,
			Size                   = UDim2.new(0, 16, 0, 16),
			LayoutOrder            = 1,
		})
	end
	local TextColumn = New("Frame", {
		Name                   = "Text",
		Parent                 = Head,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -(Reserve + (Icon and 34 or 8)), 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = 2,
	}, {
		List(2),
	})
	New("UISizeConstraint", {
		Parent  = TextColumn,
		MinSize = Vector2.new(0, MountHeight),
	})
	local Label = Text({
		Parent           = TextColumn,
		Text             = Options.Label or "",
		TextSize         = Options.LabelSize or Metrics.RowLabelSize,
		TextTransparency = Theme.TextPrimary,
		TextWrapped      = Options.Wrap ~= false,
		LayoutOrder      = 1,
	})
	local Description = nil
	if HasDescription then
		Description = Text({
			Parent           = TextColumn,
			Text             = Options.Description,
			TextSize         = Options.DescriptionSize or Metrics.RowDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	local Mount = New("Frame", {
		Name                   = "Mount",
		Parent                 = Head,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, Reserve, 0, MountHeight),
		LayoutOrder            = 3,
		ZIndex                 = 2,
	})
	local Built = {
		Frame       = Frame,
		Stack       = Stack,
		Head        = Head,
		Mount       = Mount,
		Label       = Label,
		Description = Description,
		TextColumn  = TextColumn,
		Icon        = Icon,
		Variant     = Variant,
	}
	function Built:Reserve(Width, Height)
		local Gap = Icon and 34 or 8
		local function Share()
			local Room = Head.AbsoluteSize.X
			local Taken = Width
			if Room > 0 then
				Taken = math.min(Width, math.max(0, Room * 0.6 - Gap))
			end
			Mount.Size = UDim2.new(0, Taken, 0, Height or MountHeight)
			TextColumn.Size = UDim2.new(1, -(Taken + Gap), 0, 0)
		end
		Built.Share = Share
		if not Built.Sharing then
			Built.Sharing = Head:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				Built.Share()
			end)
		end
		Share()
		return Mount
	end
	function Built:Foot(Height)
		local Foot = New("Frame", {
			Name                   = "Foot",
			Parent                 = Stack,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, Height or 18),
			LayoutOrder            = 2,
		})
		return Foot
	end
	if Reactive(Variant) and Options.Static ~= true then
		Frame.MouseEnter:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowHoverTransparency }, "hover")
		end)
		Frame.MouseLeave:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowTransparency }, "hover")
		end)
		Enter(Frame, "BackgroundTransparency", Theme.RowTransparency, "fade")
	end
	return Built
end
local function Block(Parent, Options, Height)
	Options = Options or {}
	local Pad = Options.Padding or Metrics.RowPadding
	local Frame = New("Frame", {
		Name                   = Options.Name or "Block",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RowTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Util.Radius(Options, Metrics.RowRadius)),
		Padding(12, Pad, 12, Pad),
		List(Options.Gap or 8),
	})
	local Variant = Dress(Frame, Options)
	local Head, Aside = nil, nil
	if Options.Label then
		Head = New("Frame", {
			Name                   = "Head",
			Parent                 = Frame,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			LayoutOrder            = 1,
		})
		local Column = New("Frame", {
			Name                   = "Column",
			Parent                 = Head,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, -(Options.AsideWidth or 100), 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
		}, {
			List(2),
		})
		Text({
			Parent      = Column,
			Text        = Options.Label,
			TextSize    = Options.LabelSize or Metrics.RowLabelSize,
			TextWrapped = true,
			LayoutOrder = 1,
		})
		if Options.Description and Options.Description ~= "" then
			Text({
				Parent           = Column,
				Text             = Options.Description,
				TextSize         = Options.DescriptionSize or Metrics.RowDescSize,
				TextTransparency = Theme.TextSecondary,
				TextWrapped      = true,
				LayoutOrder      = 2,
			})
		end
		Aside = New("Frame", {
			Name                   = "Aside",
			Parent                 = Head,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(1, 0),
			Position               = UDim2.new(1, 0, 0, 1),
			Size                   = UDim2.new(0, (Options.AsideWidth or 100) - 12, 0, 20),
		})
		local Wanted = Options.AsideWidth or 100
		local function Share()
			local Room = Head.AbsoluteSize.X
			local Reserve = Wanted
			if Room > 0 then
				Reserve = math.min(Wanted, math.max(0, Room * (Options.AsideShare or 0.45)))
			end
			Column.Size = UDim2.new(1, -Reserve, 0, 0)
			Aside.Size = UDim2.new(0, math.max(0, Reserve - 12), 0, Options.AsideHeight or 20)
		end
		Head:GetPropertyChangedSignal("AbsoluteSize"):Connect(Share)
		Share()
	end
	local Content = New("Frame", {
		Name                   = "Content",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Height or 0),
		AutomaticSize          = Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		LayoutOrder            = 2,
	})
	if Reactive(Variant) and Options.Static ~= true then
		Frame.MouseEnter:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowHoverTransparency }, "hover")
		end)
		Frame.MouseLeave:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowTransparency }, "hover")
		end)
		Enter(Frame, "BackgroundTransparency", Theme.RowTransparency, "fade")
	end
	return {
		Frame   = Frame,
		Content = Content,
		Head    = Head,
		Aside   = Aside,
		Variant = Variant,
	}
end
local function Polyline(Parent, Pool, Points, Colour, Alpha, Thickness)
	local Chase = Pool.Chase or 16
	if not Pool.Current then
		Pool.Current = {}
		for Index, Point in Points do
			Pool.Current[Index] = Point
		end
	end
	for Index = #Pool.Current + 1, #Points do
		Pool.Current[Index] = Points[Index]
	end
	for Index = #Points + 1, #Pool.Current do
		Pool.Current[Index] = nil
	end
	Pool.Target = Points
	Pool.Colour = Colour
	Pool.Alpha = Alpha
	Pool.Thickness = Thickness
	local function Draw()
		local Current = Pool.Current
		local Wanted = math.max(0, #Current - 1)
		for Index = 1, Wanted do
			local From, To = Current[Index], Current[Index + 1]
			local Delta = To - From
			local Length = Delta.Magnitude
			local Segment = Pool[Index]
			if not Segment or not Segment.Parent then
				Segment = New("Frame", {
					Name                   = "Segment",
					Parent                 = Parent,
					BackgroundColor3       = Pool.Colour,
					BackgroundTransparency = 1,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(0.5, 0.5),
				})
				Pool[Index] = Segment
				Tween(Segment, { BackgroundTransparency = Pool.Alpha }, "fade")
			else
				Segment.BackgroundColor3 = Pool.Colour
			end
			Segment.Position = UDim2.fromOffset((From.X + To.X) / 2, (From.Y + To.Y) / 2)
			Segment.Size = UDim2.fromOffset(Length + 1, Pool.Thickness or 1)
			Segment.Rotation = math.deg(math.atan2(Delta.Y, Delta.X))
		end
		for Index = Wanted + 1, #Pool do
			local Segment = Pool[Index]
			if Segment then
				Tween(Segment, { BackgroundTransparency = 1 }, "exit")
				task.delay(MotionTime("exit"), function()
					Segment:Destroy()
				end)
				Pool[Index] = nil
			end
		end
	end
	local function Settled()
		for Index, Point in Pool.Current do
			local Want = Pool.Target[Index]
			if Want and (Want - Point).Magnitude > 0.25 then
				return false
			end
		end
		return true
	end
	local function Sleep()
		if Pool.Driver then
			Pool.Driver:Disconnect()
			Pool.Driver = nil
		end
	end
	if Settled() then
		Pool.Current = Pool.Target
		Draw()
		Sleep()
		return Pool
	end
	if not Pool.Driver then
		Pool.Driver = RunService.Heartbeat:Connect(function(Delta)
			if not Parent.Parent then
				Sleep()
				return
			end
			local Step = 1 - math.exp(-Chase * math.min(Delta, 1 / 20))
			for Index, Point in Pool.Current do
				local Want = Pool.Target[Index]
				if Want then
					Pool.Current[Index] = Point + (Want - Point) * Step
				end
			end
			Draw()
			if Settled() then
				for Index, Want in Pool.Target do
					Pool.Current[Index] = Want
				end
				Draw()
				Sleep()
			end
		end)
	end
	Draw()
	return Pool
end
local function ChartPoints(Values, Width, Height, Minimum, Maximum)
	local Span = Maximum - Minimum
	local Points = {}
	for Index, Value in Values do
		local X = #Values > 1 and (Index - 1) / (#Values - 1) * Width or 0
		local Y = Height - (Span > 0 and (Value - Minimum) / Span or 0.5) * Height
		Points[Index] = Vector2.new(X, Y)
	end
	return Points
end
local function Extent(Values, Options)
	local Minimum = Options.Min
	local Maximum = Options.Max
	if not Minimum or not Maximum then
		local Low, High = math.huge, -math.huge
		for _, Value in Values do
			Low = math.min(Low, Value)
			High = math.max(High, Value)
		end
		if Low == math.huge then
			Low, High = 0, 1
		end
		if Low == High then
			Low, High = Low - 1, High + 1
		end
		Minimum = Minimum or Low
		Maximum = Maximum or High
	end
	return Minimum, Maximum
end
local function BlockHandle(Built, Extra, Options)
	local Handle = Extra or {}
	return Common(Handle, Built.Frame, Options or {}, {})
end
Parts.Span        = Span
Parts.Layered     = Layered
Parts.SlidingMark = SlidingMark
Parts.Draggable   = Draggable
Parts.Learn       = Learn
Parts.Locate      = Locate
Parts.Tooltip     = Tooltip
Parts.Common      = Common
Parts.Dress       = Dress
Parts.Row         = Row
Parts.Block       = Block
Parts.BlockHandle = BlockHandle
Parts.Polyline    = Polyline
Parts.ChartPoints = ChartPoints
Parts.Extent      = Extent
return Parts
end
KuikModules["Reveal"] = function()
local RunService = game:GetService("RunService")
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Theme   = Palette.Tokens
local New   = Util.New
local Clamp = Util.Clamp
local Tween      = Motion.Tween
local MotionTime = Motion.MotionTime
local Reveal = {}
local function Inset(Within)
	local Pad = Within:FindFirstChildWhichIsA("UIPadding")
	if not Pad then
		return 0, 0
	end
	local Size = Within.AbsoluteSize
	return Pad.PaddingLeft.Scale * Size.X + Pad.PaddingLeft.Offset,
		Pad.PaddingTop.Scale * Size.Y + Pad.PaddingTop.Offset
end
local function Rect(Object, Within)
	local Origin = Within.AbsolutePosition
	local Point = Object.AbsolutePosition
	local Size = Object.AbsoluteSize
	local PadX, PadY = Inset(Within)
	return Point.X - Origin.X - PadX, Point.Y - Origin.Y - PadY, Size.X, Size.Y
end
local function Plate(Parent, Options)
	Options = Options or {}
	local Face = New("Frame", {
		Name                   = Options.Name or "Plate",
		Parent                 = Parent,
		BackgroundColor3       = Options.Color or Theme.White,
		BackgroundTransparency = Options.Transparency or 0,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		ZIndex                 = Options.ZIndex or 50,
		Active                 = false,
		Selectable             = false,
	})
	if Options.Radius and Options.Radius > 0 then
		Util.Corner(Options.Radius).Parent = Face
	end
	return Face
end
local function Ready(Object, Run)
	if not Object or not Object.Parent then
		return function() end
	end
	if Object.AbsoluteSize.X >= 2 and Object.AbsoluteSize.Y >= 1 then
		Run()
		return function() end
	end
	local Watch = nil
	local Done = false
	local function Go()
		if Done or not Object.Parent then
			return
		end
		if Object.AbsoluteSize.X < 2 or Object.AbsoluteSize.Y < 1 then
			return
		end
		Done = true
		if Watch then
			Watch:Disconnect()
			Watch = nil
		end
		Run()
	end
	Watch = Object:GetPropertyChangedSignal("AbsoluteSize"):Connect(Go)
	task.defer(Go)
	return function()
		Done = true
		if Watch then
			Watch:Disconnect()
			Watch = nil
		end
	end
end
Reveal.Ready = Ready
function Reveal.Plate(Object, Options)
	Options = Options or {}
	local Parent = Options.Parent or Util.Loose(Object)
	if not Parent then
		return { Cancel = function() end }
	end
	if Options.Now ~= true and not Options.Rect
		and (Object.AbsoluteSize.X < 2 or Object.AbsoluteSize.Y < 2) then
		local Handle = {}
		local Give = Ready(Object, function()
			local Run = Reveal.Plate(Object, Util.Merge(Options, { Now = true }))
			Handle.Face = Run.Face
			Handle.Cancel = Run.Cancel
		end)
		Handle.Cancel = Give
		return Handle
	end
	local X, Y, Width, Height = Rect(Object, Parent)
	if Options.Rect then
		X, Y, Width, Height = Options.Rect[1], Options.Rect[2], Options.Rect[3], Options.Rect[4]
	end
	if Width < 2 or Height < 2 then
		return { Cancel = function() end }
	end
	local Seed = Options.Seed or 0.56
	local Open = Options.Open or 0.31
	local Face = Plate(Parent, {
		Name      = "Reveal",
		Color     = Options.Color,
		Radius    = Options.Radius,
		ZIndex    = Options.ZIndex or (Object.ZIndex + 40),
	})
	local MiddleX, MiddleY = X + Width / 2, Y + Height / 2
	local FromX, FromY = MiddleX, MiddleY
	if Options.From then
		local Source = Options.From
		local PointX, PointY = nil, nil
		if Source.AbsolutePosition then
			local Origin = Parent.AbsolutePosition
			local At = Source.AbsolutePosition
			local Span = Source.AbsoluteSize
			local PadX, PadY = Inset(Parent)
			PointX = At.X + Span.X / 2 - Origin.X - PadX
			PointY = At.Y + Span.Y / 2 - Origin.Y - PadY
		elseif Source.X and Source.Y then
			PointX, PointY = Source.X, Source.Y
		end
		if PointX then
			local AwayX = PointX - MiddleX
			local AwayY = PointY - MiddleY
			local Away = math.sqrt(AwayX * AwayX + AwayY * AwayY)
			local Cap = Options.Drift or 48
			if Away > 1 then
				local Take = math.min(Away, Cap) / Away
				FromX = MiddleX + AwayX * Take
				FromY = MiddleY + AwayY * Take
			end
		end
	end
	Face.Position = UDim2.new(0, FromX, 0, FromY)
	Face.Size = UDim2.new(0, Width * Seed, 0, Height * Open)
	Face.BackgroundTransparency = Options.Ghosted or 0.4
	local Fade = Options.Fade
	local Resting = nil
	if Fade ~= false then
		if Object:IsA("CanvasGroup") then
			Resting = Options.To or (Object.GroupTransparency < 1 and Object.GroupTransparency) or 0
			Object.GroupTransparency = 1
		else
			Resting = Motion.Resting(Object)
			for _, Mark in Resting do
				for Property in Mark.Bits do
					Mark.Object[Property] = 1
				end
			end
		end
	end
	local Wide = Options.Wide or "plate"
	local Tall = Options.Tall or "open"
	local Burn = Options.Burn or "burn"
	local Cancelled = false
	local function Stop()
		Cancelled = true
		Motion.Halt(Face)
		Face:Destroy()
	end
	Tween(Face, {
		Size = UDim2.new(0, Width, 0, Height * Open),
		Position = UDim2.new(0, MiddleX, 0, MiddleY),
		BackgroundTransparency = 0,
	}, Wide)
	task.delay(MotionTime(Wide) * (Options.OpenAt or 1.1), function()
		if Cancelled or not Face.Parent then
			return
		end
		Tween(Face, { Size = UDim2.new(0, Width, 0, Height) }, Tall)
		task.delay(MotionTime(Tall) * (Options.BurnAt or 0), function()
			if Cancelled or not Face.Parent then
				return
			end
			Tween(Face, { BackgroundTransparency = 1 }, Burn)
			if Fade ~= false then
				if Object:IsA("CanvasGroup") then
					Tween(Object, { GroupTransparency = Resting }, Burn)
				else
					for _, Mark in Resting do
						Tween(Mark.Object, Mark.Bits, Burn)
					end
				end
			end
			task.delay(MotionTime(Burn) * 1.2, function()
				if not Cancelled and Face.Parent then
					Face:Destroy()
				end
				if Options.Done then
					task.spawn(Options.Done)
				end
			end)
		end)
	end)
	return { Cancel = Stop, Face = Face }
end
function Reveal.Cover(Object, Options)
	Options = Options or {}
	local Parent = Options.Parent or Util.Loose(Object)
	if not Parent then
		if Options.Done then
			task.spawn(Options.Done)
		end
		return { Cancel = function() end }
	end
	local X, Y, Width, Height = Rect(Object, Parent)
	if Options.Rect then
		X, Y, Width, Height = Options.Rect[1], Options.Rect[2], Options.Rect[3], Options.Rect[4]
	end
	if Width < 2 or Height < 2 then
		if Options.Done then
			task.spawn(Options.Done)
		end
		return { Cancel = function() end }
	end
	local Seed = Options.Seed or 0.56
	local Open = Options.Open or 0.31
	local Face = Plate(Parent, {
		Name         = "Covering",
		Color        = Options.Color,
		Transparency = 1,
		Radius       = Options.Radius,
		ZIndex       = Options.ZIndex or (Object.ZIndex + 40),
	})
	Face.Position = UDim2.new(0, X + Width / 2, 0, Y + Height / 2)
	Face.Size = UDim2.new(0, Width, 0, Height)
	local Burn = Options.Burn or "plate"
	local Tall = Options.Tall or "open"
	local Wide = Options.Wide or "close"
	local Cancelled = false
	local function Stop()
		Cancelled = true
		Motion.Halt(Face)
		Face:Destroy()
	end
	Tween(Face, { BackgroundTransparency = 0 }, Burn)
	if Options.Fade ~= false then
		if Object:IsA("CanvasGroup") then
			Tween(Object, { GroupTransparency = 1 }, Burn)
		else
			Motion.Fade(Object, 1, Burn)
		end
	end
	task.delay(MotionTime(Burn) * 1.1, function()
		if Cancelled or not Face.Parent then
			return
		end
		Tween(Face, { Size = UDim2.new(0, Width, 0, Height * Open) }, Tall)
		task.delay(MotionTime(Tall) * 0.8, function()
			if Cancelled or not Face.Parent then
				return
			end
			Tween(Face, { Size = UDim2.new(0, Width * Seed * 0.2, 0, Height * Open) }, Wide)
			Tween(Face, { BackgroundTransparency = 1 }, Wide)
			task.delay(MotionTime(Wide) * 1.1, function()
				if Face.Parent then
					Face:Destroy()
				end
				if Options.Done then
					task.spawn(Options.Done)
				end
			end)
		end)
	end)
	return { Cancel = Stop, Face = Face }
end
function Reveal.Follow(Object, Options)
	Options = Options or {}
	local Parent = Options.Parent or Util.Loose(Object)
	if not Parent then
		return { Destroy = function() end }
	end
	local Face = Plate(Parent, {
		Name         = Options.Name or "Ghost",
		Color        = Options.Color,
		Transparency = 1,
		Radius       = Options.Radius,
		ZIndex       = Options.ZIndex or math.max(1, Object.ZIndex - 1),
	})
	local Stiffness = Options.Stiffness or 90
	local Damping = Options.Damping or (2 * math.sqrt(Options.Stiffness or 90))
	local Reach = Options.Reach or 0.55
	local Span = Options.Span or 44
	local Stretch = Options.Stretch ~= false
	local AtX, AtY = nil, nil
	local Handle = { Face = Face }
	local Connection = nil
	local Watchers = {}
	local function Step(Delta)
		if not Object.Parent or not Face.Parent then
			return
		end
		local X, Y, Width, Height = Rect(Object, Parent)
		local MiddleX, MiddleY = X + Width / 2, Y + Height / 2
		if AtX == nil then
			AtX, AtY = MiddleX, MiddleY
		end
		local Step = 1 - math.exp(-Stiffness * math.min(Delta, 1 / 20) / Damping * 2)
		AtX += (MiddleX - AtX) * Step
		AtY += (MiddleY - AtY) * Step
		local AwayX, AwayY = MiddleX - AtX, MiddleY - AtY
		local Away = math.sqrt(AwayX * AwayX + AwayY * AwayY)
		local Strength = Clamp(Away / Span, 0, 1) * Reach
		Face.BackgroundTransparency = 1 - Strength
		if Strength <= 0.002 then
			return
		end
		if Stretch then
			local Left = math.min(AtX - Width / 2, MiddleX - Width / 2)
			local Right = math.max(AtX + Width / 2, MiddleX + Width / 2)
			local Top = math.min(AtY - Height / 2, MiddleY - Height / 2)
			local Bottom = math.max(AtY + Height / 2, MiddleY + Height / 2)
			Face.Position = UDim2.new(0, (Left + Right) / 2, 0, (Top + Bottom) / 2)
			Face.Size = UDim2.new(0, Right - Left, 0, Bottom - Top)
		else
			Face.Position = UDim2.new(0, AtX, 0, AtY)
			Face.Size = UDim2.new(0, Width, 0, Height)
		end
	end
	local function Sleep()
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
	end
	local function Wake()
		if not Connection and Face.Parent then
			Connection = RunService.Heartbeat:Connect(function(Delta)
				Step(Delta)
				if Face.BackgroundTransparency > 0.998 then
					Sleep()
				end
			end)
		end
	end
	Handle.Wake = Wake
	for _, Property in { "AbsolutePosition", "AbsoluteSize" } do
		table.insert(Watchers, Object:GetPropertyChangedSignal(Property):Connect(Wake))
	end
	function Handle:Destroy()
		Sleep()
		for _, Watcher in Watchers do
			Watcher:Disconnect()
		end
		table.clear(Watchers)
		Face:Destroy()
	end
	function Handle:Settle()
		local X, Y, Width, Height = Rect(Object, Parent)
		AtX, AtY = X + Width / 2, Y + Height / 2
		Face.BackgroundTransparency = 1
		Sleep()
		return Handle
	end
	return Handle
end
function Reveal.Ghost(Object, Options)
	Options = Options or {}
	local Parent = Options.Parent or Util.Loose(Object)
	if not Parent then
		return nil
	end
	local X, Y, Width, Height = Rect(Object, Parent)
	if Width < 1 or Height < 1 then
		return nil
	end
	local Face = Plate(Parent, {
		Name         = "Afterimage",
		Color        = Options.Color,
		Transparency = Options.Transparency or 0.55,
		Radius       = Options.Radius,
		ZIndex       = Options.ZIndex or math.max(1, Object.ZIndex - 1),
	})
	Face.Position = UDim2.new(0, X + Width / 2, 0, Y + Height / 2)
	Face.Size = UDim2.new(0, Width, 0, Height)
	local Role = Options.Role or "smear"
	Tween(Face, {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, Width * (Options.Spread or 1), 0, Height * (Options.Spread or 1)),
	}, Role)
	task.delay(MotionTime(Role) * 1.3, function()
		if Face.Parent then
			Face:Destroy()
		end
	end)
	return Face
end
function Reveal.Trail(Object, Options)
	Options = Options or {}
	local Parent = Options.Parent or Util.Loose(Object)
	local Every = Options.Every or 1 / 30
	local Least = Options.Least or 3
	local Since = 0
	local LastX, LastY = nil, nil
	local Connection = RunService.Heartbeat:Connect(function(Delta)
		if not Object.Parent then
			return
		end
		local Point = Object.AbsolutePosition
		if LastX then
			local Moved = math.abs(Point.X - LastX) + math.abs(Point.Y - LastY)
			Since += Delta
			if Moved > Least and Since >= Every then
				Since = 0
				Reveal.Ghost(Object, {
					Parent       = Parent,
					Color        = Options.Color,
					Transparency = Options.Transparency,
					Radius       = Options.Radius,
					Role         = Options.Role,
					Spread       = Options.Spread,
				})
			end
		end
		LastX, LastY = Point.X, Point.Y
	end)
	return {
		Destroy = function()
			Connection:Disconnect()
		end,
	}
end
function Reveal.Wipe(Object, Options)
	Options = Options or {}
	local Parent = Options.Parent or Util.Loose(Object)
	if not Parent then
		return { Cancel = function() end }
	end
	if Options.Now ~= true and (Object.AbsoluteSize.X < 2 or Object.AbsoluteSize.Y < 2) then
		local Handle = {}
		local Give = Ready(Object, function()
			local Run = Reveal.Wipe(Object, Util.Merge(Options, { Now = true }))
			Handle.Face = Run.Face
			Handle.Cancel = Run.Cancel
		end)
		Handle.Cancel = Give
		return Handle
	end
	local X, Y, Width, Height = Rect(Object, Parent)
	if Width < 2 or Height < 2 then
		return { Cancel = function() end }
	end
	local Down = Options.Axis == "Y"
	local Thickness = Options.Thickness or (Down and math.max(2, Height * 0.18) or math.max(2, Width * 0.12))
	local Bar = Plate(Parent, {
		Name   = "Wipe",
		Color  = Options.Color,
		ZIndex = Options.ZIndex or (Object.ZIndex + 40),
	})
	Bar.Size = Down and UDim2.new(0, Width, 0, Thickness) or UDim2.new(0, Thickness, 0, Height)
	Bar.Position = Down
		and UDim2.new(0, X + Width / 2, 0, Y)
		or UDim2.new(0, X, 0, Y + Height / 2)
	local Resting = Motion.Resting(Object)
	for _, Mark in Resting do
		for Property in Mark.Bits do
			Mark.Object[Property] = 1
		end
	end
	local Role = Options.Role or "sweep"
	local Landed = false
	Tween(Bar, {
		Position = Down
			and UDim2.new(0, X + Width / 2, 0, Y + Height)
			or UDim2.new(0, X + Width, 0, Y + Height / 2),
	}, Role)
	task.delay(MotionTime(Role) * 0.35, function()
		if Landed then
			return
		end
		for _, Mark in Resting do
			if Mark.Object.Parent then
				Tween(Mark.Object, Mark.Bits, "enter")
			end
		end
	end)
	task.delay(MotionTime(Role), function()
		if not Landed and Bar.Parent then
			Tween(Bar, { BackgroundTransparency = 1 }, "burn")
			task.delay(MotionTime("burn") * 1.2, function()
				if Bar.Parent then
					Bar:Destroy()
				end
			end)
		end
	end)
	return {
		Face = Bar,
		Cancel = function()
			Landed = true
			Motion.Halt(Bar)
			Bar:Destroy()
			for _, Mark in Resting do
				if Mark.Object.Parent then
					for Property, Value in Mark.Bits do
						Mark.Object[Property] = Value
					end
				end
			end
		end,
	}
end
function Reveal.Close(Object, Options)
	Options = Options or {}
	local Parent = Options.Parent or (Object and Util.Loose(Object))
	if not Parent then
		return { Cancel = function() end }
	end
	local X, Y, Width, Height = 0, 0, 0, 0
	if Options.Rect then
		X, Y, Width, Height = Options.Rect[1], Options.Rect[2], Options.Rect[3], Options.Rect[4]
	elseif Object then
		X, Y, Width, Height = Rect(Object, Parent)
	end
	if Width < 2 or Height < 1 then
		return { Cancel = function() end }
	end
	local Over = Options.Over or 1.1
	local Face = Plate(Parent, {
		Name   = "Closing",
		Color  = Options.Color,
		Radius = Options.Radius,
		ZIndex = Options.ZIndex or ((Object and Object.ZIndex or 1) + 40),
	})
	Face.Position = UDim2.new(0, X + Width / 2, 0, Y + Height / 2)
	Face.Size = UDim2.new(0, Width * Over, 0, Height)
	local Role = Options.Role or "close"
	local Gone = false
	Tween(Face, { Size = UDim2.new(0, 0, 0, Height) }, Role)
	task.delay(MotionTime(Role) * 1.2, function()
		if not Gone and Face.Parent then
			Face:Destroy()
		end
		if Options.Done then
			task.spawn(Options.Done)
		end
	end)
	return {
		Face = Face,
		Cancel = function()
			Gone = true
			Motion.Halt(Face)
			Face:Destroy()
		end,
	}
end
function Reveal.Flash(Options)
	Options = Options or {}
	local Screen = KuikRequire("Screen")
	local Face = New("Frame", {
		Name                   = "Flash",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundColor3       = Options.Color or Theme.White,
		BackgroundTransparency = 1 - (Options.Peak or 0.9),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = Options.ZIndex or 4000,
		Active                 = false,
		Selectable             = false,
	})
	Screen.Cover(Face)
	local Role = Options.Role or "burn"
	local Hold = Options.Hold or 0
	local function Decay()
		if not Face.Parent then
			return
		end
		Tween(Face, { BackgroundTransparency = 1 }, Role)
		task.delay(MotionTime(Role) * 1.4, function()
			if Face.Parent then
				Face:Destroy()
			end
		end)
	end
	if Hold > 0 then
		task.delay(Hold, function()
			if Options.Covered then
				task.spawn(Options.Covered)
			end
			Decay()
		end)
	else
		if Options.Covered then
			task.spawn(Options.Covered)
		end
		Decay()
	end
	return Face
end
return Reveal
end
KuikModules["Screen"] = function()
local Players    = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Util = KuikRequire("Util")
local New = Util.New
local Screen = {}
local LocalPlayer = Players.LocalPlayer
local Host = nil
function Screen.Get()
	if Host and Host.Parent then
		return Host
	end
	local Parent = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
	Host = New("ScreenGui", {
		Name             = "Kuik",
		Parent           = Parent,
		ResetOnSpawn     = false,
		IgnoreGuiInset   = true,
		ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
		DisplayOrder     = 50,
	})
	return Host
end
function Screen.Inset()
	local Ok, Top = pcall(function()
		return GuiService:GetGuiInset()
	end)
	return Ok and Top and Top.Y or 0
end
function Screen.Safe(Fraction, Height)
	local Top = Screen.Inset()
	local Tall = Height or math.max(0, Screen.Get().AbsoluteSize.Y)
	return Top + Tall * (Fraction or 0)
end
function Screen.Cover(Object)
	local Top = Screen.Inset()
	Object.Position = UDim2.new(0, 0, 0, 0)
	Object.Size = UDim2.new(1, 0, 1, Top)
	return Object
end
function Screen.Destroy()
	if Host then
		Host:Destroy()
		Host = nil
	end
end
local Modals = 0
local Watchers = {}
function Screen.Blocked()
	return Modals > 0
end
function Screen.Depth()
	return Modals
end
function Screen.Enter()
	Modals += 1
	for _, Handler in Watchers do
		task.spawn(Handler, Modals)
	end
end
function Screen.Exit()
	Modals = math.max(0, Modals - 1)
	for _, Handler in Watchers do
		task.spawn(Handler, Modals)
	end
end
function Screen.OnModal(Handler)
	table.insert(Watchers, Handler)
	return function()
		local At = table.find(Watchers, Handler)
		if At then
			table.remove(Watchers, At)
		end
	end
end
Screen.Player = LocalPlayer
return Screen
end
KuikModules["Scroll"] = function()
local UserInputService = game:GetService("UserInputService")
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Screen  = KuikRequire("Screen")
local Theme = Palette.Tokens
local New   = Util.New
local Clamp = Util.Clamp
local Tween      = Motion.Tween
local MotionTime = Motion.MotionTime
local Scroll = {}
local function Gleam(Frame, Vertical, Depth, Options)
	local Parent = Util.Loose(Frame)
	if not Parent then
		return function() end
	end
	Options = Options or {}
	Depth = Depth or 22
	local Base = Options.Strength or 0.86
	local Colour = Options.Color or Theme.White
	local function Edge(Head)
		local Group = New("CanvasGroup", {
			Name                   = Head and "GleamHead" or "GleamTail",
			Parent                 = Parent,
			BackgroundTransparency = 1,
			GroupTransparency      = 1,
			BorderSizePixel        = 0,
			ZIndex                 = 30,
			Active                 = false,
		}, {
			New("UIGradient", {
				Rotation = Vertical and 0 or 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.16, 0),
					NumberSequenceKeypoint.new(0.84, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
		New("Frame", {
			Name                   = "Light",
			Parent                 = Group,
			BackgroundColor3       = Colour,
			BackgroundTransparency = Base,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 1, 0),
			Active                 = false,
		}, {
			New("UIGradient", {
				Rotation = Vertical and 90 or 0,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, Head and 0 or 1),
					NumberSequenceKeypoint.new(1, Head and 1 or 0),
				}),
			}),
		})
		return Group
	end
	local Head, Tail = Edge(true), Edge(false)
	local function Layout()
		local Origin = Parent.AbsolutePosition
		local At = Frame.AbsolutePosition
		local Size = Frame.AbsoluteSize
		if Size.X <= 0 or Size.Y <= 0 then
			return
		end
		local X, Y = At.X - Origin.X, At.Y - Origin.Y
		if Vertical then
			Head.AnchorPoint = Vector2.new(0, 0)
			Head.Position = UDim2.new(0, X, 0, Y)
			Head.Size = UDim2.new(0, Size.X, 0, Depth)
			Tail.AnchorPoint = Vector2.new(0, 1)
			Tail.Position = UDim2.new(0, X, 0, Y + Size.Y)
			Tail.Size = UDim2.new(0, Size.X, 0, Depth)
		else
			Head.AnchorPoint = Vector2.new(0, 0)
			Head.Position = UDim2.new(0, X, 0, Y)
			Head.Size = UDim2.new(0, Depth, 0, Size.Y)
			Tail.AnchorPoint = Vector2.new(1, 0)
			Tail.Position = UDim2.new(0, X + Size.X, 0, Y)
			Tail.Size = UDim2.new(0, Depth, 0, Size.Y)
		end
	end
	local Motion_ = 0
	local Before, After = false, false
	local function Update()
		local Span = Vertical
			and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
			or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X
		local At = Vertical and Frame.CanvasPosition.Y or Frame.CanvasPosition.X
		Before = Span > 2 and At > 2
		After = Span > 2 and (Span - At) > 2
		Tween(Head, { GroupTransparency = Before and Motion_ or 1 }, "fade")
		Tween(Tail, { GroupTransparency = After and Motion_ or 1 }, "fade")
	end
	local Settle = 0
	local function Nudge()
		Motion_ = 0.55
		Settle += 1
		local Mine = Settle
		Tween(Head, { GroupTransparency = Before and Motion_ or 1 }, "hover")
		Tween(Tail, { GroupTransparency = After and Motion_ or 1 }, "hover")
		task.delay(MotionTime("scroll") * 0.9, function()
			if Settle == Mine then
				Motion_ = 0
				Update()
			end
		end)
	end
	local Connections = {
		Frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(Layout),
		Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(Layout),
		Parent:GetPropertyChangedSignal("AbsolutePosition"):Connect(Layout),
		Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(Update),
		Frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(Update),
		Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(Update),
	}
	Layout()
	task.defer(Update)
	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		Head:Destroy()
		Tail:Destroy()
	end, Nudge
end
local function Edges(Frame, Options)
	Options = Options or {}
	local Depth = Options.Depth or 26
	local Base = Options.Strength or 0.72
	local Colour = Options.Color or Theme.White
	local Sides = {}
	local function Edge(Name, Anchor, Position, Size, Rotation)
		local Group = New("CanvasGroup", {
			Name                   = Name,
			Parent                 = Frame,
			BackgroundTransparency = 1,
			GroupTransparency      = 1,
			BorderSizePixel        = 0,
			AnchorPoint            = Anchor,
			Position               = Position,
			Size                   = Size,
			ZIndex                 = Options.ZIndex or 20,
			Active                 = false,
		})
		New("Frame", {
			Name                   = "Light",
			Parent                 = Group,
			BackgroundColor3       = Colour,
			BackgroundTransparency = Base,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 1, 0),
			Active                 = false,
		}, {
			New("UIGradient", {
				Rotation = Rotation,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
		Sides[Name] = Group
		return Group
	end
	Edge("Left", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, Depth, 1, 0), 0)
	Edge("Right", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, Depth, 1, 0), 180)
	Edge("Top", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, Depth), 90)
	Edge("Bottom", Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(1, 0, 0, Depth), 270)
	local Handle = { Sides = Sides }
	function Handle:Set(Room, Role)
		for Name, Group in Sides do
			local Amount = math.clamp((Room[Name] or 0) * 8, 0, 1)
			Tween(Group, { GroupTransparency = 1 - Amount }, Role or "fade")
		end
		return Handle
	end
	function Handle:Destroy()
		for _, Group in Sides do
			Group:Destroy()
		end
		table.clear(Sides)
	end
	return Handle
end
local Hovered = nil
local function SmoothScroll(Frame, Axis, Options)
	local Handle = { Frame = Frame, Enabled = true }
	local Vertical = Axis ~= "X"
	if not (Options and Options.Gleam == false) then
		Handle.StopGleam, Handle.Nudge = Gleam(Frame, Vertical,
			Options and Options.Depth, Options)
	end
	if not UserInputService.MouseEnabled then
		function Handle:SetEnabled() end
		function Handle:Sync() end
		function Handle:To(Position)
			Frame.CanvasPosition = Position
		end
		function Handle:Top()
			Frame.CanvasPosition = Vector2.zero
		end
		function Handle:Span()
			return math.max(0, Vertical
				and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
				or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X)
		end
		function Handle:Destroy()
			if Handle.StopGleam then
				Handle.StopGleam()
			end
		end
		return Handle
	end
	Frame.ScrollingEnabled = false
	local Target = Frame.CanvasPosition
	local Connections = {}
	local Touched = false
	function Handle:SetEnabled(Value)
		Handle.Enabled = Value
	end
	function Handle:To(Position, Role)
		Touched = true
		Target = Position
		Tween(Frame, { CanvasPosition = Target }, Role or "scroll")
	end
	function Handle:Sync()
		Target = Frame.CanvasPosition
	end
	function Handle:Top()
		Touched = false
		Target = Vector2.zero
		Frame.CanvasPosition = Vector2.zero
		Motion.Halt(Frame, "CanvasPosition")
	end
	function Handle:Span()
		return math.max(0, Vertical
			and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
			or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X)
	end
	local Holding = false
	local function Pin()
		if Touched or Holding then
			return
		end
		if Frame.CanvasPosition.Magnitude > 0.5 then
			Holding = true
			Target = Vector2.zero
			Frame.CanvasPosition = Vector2.zero
			Holding = false
		end
	end
	table.insert(Connections, Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(Pin))
	table.insert(Connections, Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(Pin))
	table.insert(Connections, Frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		if not Touched then
			Pin()
			return
		end
		local Span = Handle:Span()
		if Vertical and Target.Y > Span then
			Handle:To(Vector2.new(0, Span))
		elseif not Vertical and Target.X > Span then
			Handle:To(Vector2.new(Span, 0))
		end
	end))
	local Driving = false
	local Token = 0
	table.insert(Connections, Frame.MouseEnter:Connect(function()
		Hovered = Frame
	end))
	table.insert(Connections, Frame.MouseLeave:Connect(function()
		if Hovered == Frame then
			Hovered = nil
		end
	end))
	table.insert(Connections, Frame.InputChanged:Connect(function(Input)
		if not Handle.Enabled or Input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end
		if Screen.Blocked() and not (Options and Options.Modal) then
			return
		end
		if Hovered and Hovered ~= Frame then
			return
		end
		local Span = Handle:Span()
		if Span <= 0 then
			return
		end
		Touched = true
		if not Driving then
			Target = Frame.CanvasPosition
		end
		local Step = Input.Position.Z * (Options and Options.Step or (Vertical and 92 or 56))
		Target = Vertical
			and Vector2.new(0, Clamp(Target.Y - Step, 0, Span))
			or Vector2.new(Clamp(Target.X - Step, 0, Span), 0)
		Driving = true
		Token += 1
		local Mine = Token
		if Handle.Nudge then
			Handle.Nudge()
		end
		Tween(Frame, { CanvasPosition = Target }, "scroll")
		task.delay(MotionTime("scroll") * 1.2, function()
			if Token == Mine then
				Driving = false
			end
		end)
	end))
	function Handle:Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		if Handle.StopGleam then
			Handle.StopGleam()
		end
		if Hovered == Frame then
			Hovered = nil
		end
	end
	return Handle
end
Scroll.Gleam  = Gleam
Scroll.Edges  = Edges
Scroll.Attach = SmoothScroll
function Scroll.Hovered()
	return Hovered
end
return Scroll
end
KuikModules["Shared"] = function()
local Shared = {}
return Shared
end
KuikModules["Showcase"] = function()
local Players = game:GetService("Players")
local Palette  = KuikRequire("Theme")
local Util     = KuikRequire("Util")
local Controls = KuikRequire("Controls")
local Theme = Palette.Tokens
local LocalPlayer = Players.LocalPlayer
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
	Tabs:Select("Input")
	if #Broken > 0 then
		Window:SetTitle(Options.Title or "Kuik",
			string.format("%d control(s) failed: %s", #Broken, table.concat(Broken, ", ")))
	end
	Window.Broken = Broken
	Window.Held = Held
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
end
KuikModules["Theme"] = function()
local Palette = {}
local Theme = {
	Font       = Font.fromName("Montserrat", Enum.FontWeight.Regular),
	FontMedium = Font.fromName("Montserrat", Enum.FontWeight.Medium),
	FontBold   = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
	FontMono   = Font.fromEnum(Enum.Font.Code),
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(20, 20, 20),
	Scrim = Color3.fromRGB(8, 8, 10),
	TextPrimary   = 0.00,
	TextSecondary = 0.42,
	TextTertiary  = 0.58,
	TextDisabled  = 0.72,
	RuleTransparency = 0.45,
	RowTransparency      = 0.94,
	RowHoverTransparency = 0.88,
	RowPressTransparency = 0.82,
	ChipTransparency = 0.45,
	EmbedColor        = Color3.fromRGB(20, 20, 20),
	EmbedTransparency = 0.65,
	Danger  = Color3.fromRGB(255, 72, 72),
	Warn    = Color3.fromRGB(255, 176, 46),
	Info    = Color3.fromRGB(96, 156, 255),
	Good    = Color3.fromRGB(96, 210, 128),
	Neutral = Color3.fromRGB(255, 255, 255),
	Accent  = Color3.fromRGB(255, 255, 255),
	Motion = {
		instant = { Duration = 0 },
		enter  = { Stiffness = 170,  Damping = 24 },
		exit   = { Stiffness = 250,  Damping = 32 },
		expand = { Stiffness = 310,  Damping = 34 },
		hint   = { Stiffness = 740,  Damping = 56 },
		item   = { Stiffness = 400,  Damping = 40 },
		list   = { Stiffness = 460,  Damping = 43 },
		drop   = { Stiffness = 170,  Damping = 19 },
		hover  = { Stiffness = 2500, Damping = 100 },
		press  = { Stiffness = 7300, Damping = 171 },
		fade   = { Stiffness = 310,  Damping = 36 },
		tint   = { Stiffness = 420,  Damping = 42 },
		plate  = { Stiffness = 5000, Damping = 142 },
		open   = { Stiffness = 1500, Damping = 78 },
		burn   = { Stiffness = 200,  Damping = 29 },
		smear  = { Stiffness = 400,  Damping = 40 },
		sweep  = { Stiffness = 294,  Damping = 34 },
		close  = { Stiffness = 144,  Damping = 24 },
		layout = { Stiffness = 190, Damping = 24 },
		morph  = { Stiffness = 210, Damping = 26 },
		drag   = { Stiffness = 620, Damping = 42 },
		toss   = { Stiffness = 340, Damping = 22 },
		reveal = { Stiffness = 150, Damping = 20 },
		snap   = { Stiffness = 600, Damping = 40 },
		pop    = { Stiffness = 420, Damping = 28 },
		shrink = { Stiffness = 520, Damping = 46 },
		scroll = { Stiffness = 300, Damping = 38 },
	},
}
local Metrics = {
	Reveal        = true,
	OverlayVariant = "Card",
	WindowWidth   = 460,
	WindowHeight  = 500,
	WindowPadding = 26,
	TitleSize    = 27,
	SubtitleSize = 14,
	SectionTitleSize = 18,
	SectionDescSize  = 12,
	RowLabelSize = 16,
	RowDescSize  = 16,
	SubheadSize  = 14,
	BodySize     = 15,
	ValueSize    = 14,
	CaptionSize  = 13,
	TinySize     = 11,
	RowHeight    = 46,
	RowHeightTall = 62,
	RowGap       = 16,
	RowPadding   = 14,
	RowRadius    = 0,
	CardRadius   = 0,
	PillRadius   = 0,
	TabHeight  = 30,
	TabPadding = 14,
	TabGap     = 6,
	TabIcon    = 14,
	ToggleWidth  = 50,
	ToggleHeight = 25,
	KnobInset    = 3,
	CheckSize    = 18,
	SliderTrack = 3,
	SliderThumbWidth  = 4,
	SliderThumbHeight = 15,
	ChipWidth  = 52,
	ChipHeight = 23,
	ChipRadius = 5,
	MonoSize      = 10,
	MonoBoldSize  = 11,
	MonoLargeSize = 12,
	CountSize = 22,
	StrokeThickness = 1,
}
Palette.Tokens  = Theme
Palette.Metrics = Metrics
local COLOUR_PROPERTIES = {
	"BackgroundColor3",
	"TextColor3",
	"ImageColor3",
	"PlaceholderColor3",
	"BorderColor3",
	"Color",
}
local ALPHA_PROPERTIES = {
	"BackgroundTransparency",
	"TextTransparency",
	"ImageTransparency",
	"Transparency",
}
local COLOUR_TOKENS = {
	"White", "Black", "Scrim", "EmbedColor",
	"Danger", "Warn", "Info", "Good", "Neutral", "Accent",
}
local ALPHA_TOKENS = {
	"TextSecondary", "TextTertiary", "TextDisabled",
	"RuleTransparency",
	"RowTransparency", "RowHoverTransparency", "RowPressTransparency",
	"ChipTransparency",
	"EmbedTransparency",
}
local Painted = setmetatable({}, { __mode = "k" })
function Palette.Track(Object, Properties)
	local Record = nil
	for _, Property in COLOUR_PROPERTIES do
		local Value = Properties[Property]
		if Value ~= nil then
			for _, Token in COLOUR_TOKENS do
				if Theme[Token] == Value then
					Record = Record or {}
					Record[Property] = Token
					break
				end
			end
		end
	end
	for _, Property in ALPHA_PROPERTIES do
		local Value = Properties[Property]
		if type(Value) == "number" then
			for _, Token in ALPHA_TOKENS do
				if Theme[Token] == Value then
					Record = Record or {}
					Record[Property] = Token
					break
				end
			end
		end
	end
	if Record then
		Painted[Object] = Record
	end
end
function Palette.Paint(Object, Map)
	local Record = Painted[Object] or {}
	for Property, Token in Map do
		Record[Property] = Token
		Object[Property] = Theme[Token]
	end
	Painted[Object] = Record
end
function Palette.Release(Object)
	Painted[Object] = nil
end
Palette.Themes = {
	Remorse = {},
	Redliner = {
		Accent = Color3.fromRGB(255, 62, 62),
		Info   = Color3.fromRGB(255, 62, 62),
		Scrim  = Color3.fromRGB(10, 6, 6),
		Black  = Color3.fromRGB(24, 16, 16),
	},
	Ember = {
		Accent = Color3.fromRGB(255, 138, 46),
		Info   = Color3.fromRGB(255, 138, 46),
		Scrim  = Color3.fromRGB(14, 9, 5),
		Black  = Color3.fromRGB(28, 20, 14),
	},
	Terminal = {
		White  = Color3.fromRGB(198, 255, 208),
		Accent = Color3.fromRGB(96, 255, 140),
		Info   = Color3.fromRGB(96, 255, 140),
		Scrim  = Color3.fromRGB(2, 10, 4),
		Black  = Color3.fromRGB(8, 22, 12),
		Font       = Font.fromEnum(Enum.Font.Code),
		FontMedium = Font.fromEnum(Enum.Font.Code),
		FontBold   = Font.fromEnum(Enum.Font.Code),
	},
	Midnight = {
		White  = Color3.fromRGB(226, 232, 255),
		Accent = Color3.fromRGB(122, 162, 255),
		Info   = Color3.fromRGB(122, 162, 255),
		Scrim  = Color3.fromRGB(6, 8, 18),
		Black  = Color3.fromRGB(18, 22, 40),
	},
	Paper = {
		White = Color3.fromRGB(24, 24, 26),
		Black = Color3.fromRGB(248, 248, 250),
		Scrim = Color3.fromRGB(244, 244, 246),
		EmbedColor        = Color3.fromRGB(228, 228, 232),
		EmbedTransparency = 0.15,
		RowTransparency      = 0.92,
		RowHoverTransparency = 0.86,
		RowPressTransparency = 0.80,
		ChipTransparency     = 0.88,
		RuleTransparency     = 0.78,
		Accent = Color3.fromRGB(24, 24, 26),
		Info   = Color3.fromRGB(40, 90, 200),
		Good   = Color3.fromRGB(28, 140, 70),
		Warn   = Color3.fromRGB(180, 110, 0),
		Danger = Color3.fromRGB(200, 40, 40),
	},
}
local Defaults = {}
for Key, Value in Theme do
	if Key ~= "Motion" then
		Defaults[Key] = Value
	end
end
local Listeners = {}
local Current = "Remorse"
function Palette.OnChange(Handler)
	table.insert(Listeners, Handler)
	return function()
		local At = table.find(Listeners, Handler)
		if At then
			table.remove(Listeners, At)
		end
	end
end
function Palette.Name()
	return Current
end
function Palette.Set(Theme_, Repaint)
	local Overlay = Theme_
	if type(Theme_) == "string" then
		Overlay = Palette.Themes[Theme_]
		if not Overlay then
			return false
		end
		Current = Theme_
	else
		Current = "Custom"
	end
	for Key, Value in Defaults do
		Theme[Key] = Value
	end
	for Key, Value in Overlay do
		if Key == "Motion" then
			for Role, Spec in Value do
				Theme.Motion[Role] = Spec
			end
		elseif Key == "Metrics" then
			for Name, Number in Value do
				Metrics[Name] = Number
			end
		else
			Theme[Key] = Value
		end
	end
	if Repaint ~= false then
		for Object, Record in Painted do
			if Object.Parent then
				for Property, Token in Record do
					local Value = Theme[Token]
					local Ok = pcall(function()
						Object[Property] = Value
					end)
					if not Ok then
						Record[Property] = nil
					end
				end
			else
				Painted[Object] = nil
			end
		end
	end
	for _, Handler in Listeners do
		task.spawn(Handler, Theme)
	end
	return true
end
function Palette.Register(Name, Overlay)
	Palette.Themes[Name] = Overlay
end
return Palette
end
KuikModules["Util"] = function()
local Palette = KuikRequire("Theme")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local Util = {}
local function New(ClassName, Properties, Children)
	local Object = Instance.new(ClassName)
	for Key, Value in Properties or {} do
		if Key ~= "Parent" then
			Object[Key] = Value
		end
	end
	for _, Child in Children or {} do
		Child.Parent = Object
	end
	if Properties then
		Palette.Track(Object, Properties)
		if Properties.Parent then
			Object.Parent = Properties.Parent
		end
	end
	return Object
end
local function Clamp(Value, Minimum, Maximum)
	return math.max(Minimum, math.min(Maximum, Value))
end
local function Quantise(Value, Step)
	if not Step or Step <= 0 then
		return Value
	end
	return math.floor(Value / Step + 0.5) * Step
end
local function FormatNumber(Value, Step)
	if Step and Step < 1 then
		local Decimals = math.max(0, math.ceil(-math.log(Step, 10)))
		local Text = string.format("%." .. Decimals .. "f", Value)
		Text = string.gsub(Text, "%.?0+$", "")
		return Text == "" and "0" or Text
	end
	return tostring(math.floor(Value + 0.5))
end
local function Hex(Colour)
	return string.format("#%02x%02x%02x",
		math.floor(Colour.R * 255 + 0.5),
		math.floor(Colour.G * 255 + 0.5),
		math.floor(Colour.B * 255 + 0.5))
end
local function Shade(Colour, Amount)
	local Toward = Amount > 0 and 1 or 0
	local Alpha = math.abs(Amount)
	return Color3.new(
		Colour.R + (Toward - Colour.R) * Alpha,
		Colour.G + (Toward - Colour.G) * Alpha,
		Colour.B + (Toward - Colour.B) * Alpha
	)
end
local function Corner(Radius)
	return New("UICorner", { CornerRadius = UDim.new(0, Radius or 0) })
end
local function Padding(Top, Right, Bottom, Left)
	return New("UIPadding", {
		PaddingTop    = UDim.new(0, Top),
		PaddingRight  = UDim.new(0, Right or Top),
		PaddingBottom = UDim.new(0, Bottom or Top),
		PaddingLeft   = UDim.new(0, Left or Right or Top),
	})
end
local function List(Gap, Direction, Alignment)
	return New("UIListLayout", {
		Padding              = UDim.new(0, Gap or 0),
		FillDirection        = Direction or Enum.FillDirection.Vertical,
		SortOrder            = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment  = Alignment or Enum.HorizontalAlignment.Left,
	})
end
local function Strip(Gap, Alignment, Cross)
	return New("UIListLayout", {
		Padding             = UDim.new(0, Gap or 0),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Alignment or Enum.HorizontalAlignment.Left,
		VerticalAlignment   = Cross or Enum.VerticalAlignment.Center,
	})
end
local function Stroke(Colour, Transparency, Thickness)
	return New("UIStroke", {
		Color        = Colour or Theme.White,
		Transparency = Transparency == nil and 0.7 or Transparency,
		Thickness    = Thickness or Metrics.StrokeThickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end
local function Rule(Parent, Anchor, LayoutOrder)
	return New("Frame", {
		Name                   = "Rule",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Anchor or Vector2.new(0, 0),
		Size                   = UDim2.new(0, 1, 1, 0),
		LayoutOrder            = LayoutOrder or 0,
		ZIndex                 = 2,
	})
end
local function Text(Properties)
	local Label = New("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		TextColor3             = Theme.White,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Top,
		FontFace               = Theme.Font,
		TextSize               = Metrics.RowLabelSize,
		RichText               = true,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	})
	for Key, Value in Properties or {} do
		if Key ~= "Parent" then
			Label[Key] = Value
		end
	end
	if Properties then
		Palette.Track(Label, Properties)
		if Properties.Parent then
			Label.Parent = Properties.Parent
		end
	end
	return Label
end
local function Glyph(Parent, Size, Alpha)
	local Holder = New("Frame", {
		Name                   = "Glyph",
		Parent                 = Parent,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, Size, 0, Size),
	})
	local Widths = { 1.0, 0.7, 0.85 }
	for Index, Fraction in Widths do
		New("Frame", {
			Name                   = "Bar" .. Index,
			Parent                 = Holder,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Alpha or Theme.TextTertiary,
			BorderSizePixel        = 0,
			Position               = UDim2.new(0, 0, 0, math.floor(Size * 0.28) + (Index - 1) * 3),
			Size                   = UDim2.new(Fraction, 0, 0, 1),
		})
	end
	return Holder
end
local function Keycap(Parent, Size)
	local Cap = New("Frame", {
		Name                   = "Keycap",
		Parent                 = Parent,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, Size, 0, math.floor(Size * 0.72)),
	}, {
		Corner(2),
		Stroke(Theme.White, Theme.TextTertiary, 1),
	})
	for Index = 1, 2 do
		New("Frame", {
			Parent                 = Cap,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.TextTertiary,
			BorderSizePixel        = 0,
			Position               = UDim2.new(0.22, 0, 0.28 + (Index - 1) * 0.28, 0),
			Size                   = UDim2.new(0.56, 0, 0, 1),
		})
	end
	return Cap
end
local function Chevron(Parent, Size, Direction, Alpha)
	local Holder = New("Frame", {
		Name                   = "Chevron",
		Parent                 = Parent,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, Size, 0, Size),
	})
	local Arms = {}
	local Vertical = Direction == "Down" or Direction == "Up"
	local Sign = (Direction == "Up" or Direction == "Left") and -1 or 1
	for Index = 1, 2 do
		Arms[Index] = New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Alpha or Theme.TextSecondary,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = Vertical
				and UDim2.new(Index == 1 and 0.28 or 0.72, 0, 0.5, 0)
				or UDim2.new(0.5, 0, Index == 1 and 0.3 or 0.7, 0),
			Size                   = UDim2.new(0, math.max(4, Size - 3), 0, 1),
			Rotation               = Sign * (Index == 1 and 45 or -45),
		})
	end
	if not (Parent:FindFirstChildOfClass("UIListLayout")
		or Parent:FindFirstChildOfClass("UIGridLayout")) then
		Holder.AnchorPoint = Vector2.new(0.5, 0.5)
		Holder.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
	return Holder, Arms
end
local function Radius(Options, Fallback)
	local Wanted = Options and Options.Radius
	if Wanted == nil then
		return Fallback or 0
	end
	return Wanted
end
local function Round(Options, Fallback, Cap)
	return math.min(Radius(Options, Metrics.PillRadius), Cap or Fallback or 999)
end
local function Colour(Options, Fallback)
	return (Options and Options.Color) or Fallback or Theme.Accent
end
local function Surface(Options, Fallback, FallbackAlpha)
	Options = Options or {}
	local Wanted = Options.Background
	local Alpha = Options.BackgroundTransparency
	if Wanted == false or Wanted == "None" then
		return Theme.EmbedColor, 1
	end
	if typeof(Wanted) == "Color3" then
		return Wanted, Alpha == nil and 0 or Alpha
	end
	return Fallback or Theme.EmbedColor,
		Alpha == nil and (FallbackAlpha == nil and Theme.EmbedTransparency or FallbackAlpha) or Alpha
end
local SCALE_TYPES = {
	Fit     = Enum.ScaleType.Fit,
	Cover   = Enum.ScaleType.Crop,
	Crop    = Enum.ScaleType.Crop,
	Stretch = Enum.ScaleType.Stretch,
	Tile    = Enum.ScaleType.Tile,
	Slice   = Enum.ScaleType.Slice,
}
local function ScaleType(Value, Fallback)
	if typeof(Value) == "EnumItem" then
		return Value
	end
	return SCALE_TYPES[Value] or Fallback or Enum.ScaleType.Fit
end
local function Asset(Value)
	if type(Value) == "number" then
		return "rbxassetid://" .. Value
	end
	return Value or ""
end
local function Headshot(UserId, Size)
	return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d",
		UserId, Size or 60, Size or 60)
end
local function Portrait(UserId, Size)
	return string.format("rbxthumb://type=AvatarBust&id=%d&w=%d&h=%d",
		UserId, Size or 100, Size or 100)
end
local function Loose(Object)
	local Host = Object and Object.Parent
	while Host do
		local Arranged = false
		for _, Child in Host:GetChildren() do
			if Child:IsA("UIListLayout") or Child:IsA("UIGridLayout") then
				Arranged = true
				break
			end
		end
		if not Arranged then
			return Host
		end
		Host = Host.Parent
	end
	return Object and Object.Parent
end
local function Merge(Base, Extra)
	local Out = {}
	for Key, Value in Base or {} do
		Out[Key] = Value
	end
	for Key, Value in Extra or {} do
		Out[Key] = Value
	end
	return Out
end
Util.New          = New
Util.Clamp        = Clamp
Util.Quantise     = Quantise
Util.FormatNumber = FormatNumber
Util.Hex          = Hex
Util.Shade        = Shade
Util.Corner       = Corner
Util.Padding      = Padding
Util.List         = List
Util.Strip        = Strip
Util.Stroke       = Stroke
Util.Rule         = Rule
Util.Text         = Text
Util.Glyph        = Glyph
Util.Keycap       = Keycap
Util.Chevron      = Chevron
Util.Radius       = Radius
Util.Round        = Round
Util.Colour       = Colour
Util.Surface      = Surface
Util.ScaleType    = ScaleType
Util.Asset        = Asset
Util.Headshot     = Headshot
Util.Portrait     = Portrait
Util.Loose        = Loose
Util.Merge        = Merge
return Util
end
KuikModules["Window"] = function()
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Palette = KuikRequire("Theme")
local Util    = KuikRequire("Util")
local Motion  = KuikRequire("Motion")
local Parts   = KuikRequire("Parts")
local Scroll  = KuikRequire("Scroll")
local Screen  = KuikRequire("Screen")
local Reveal  = KuikRequire("Reveal")
local Layout  = KuikRequire("Layout")
local Shared  = KuikRequire("Shared")
local Theme   = Palette.Tokens
local Metrics = Palette.Metrics
local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Stroke  = Util.Stroke
local Clamp   = Util.Clamp
local Tween      = Motion.Tween
local MotionTime = Motion.MotionTime
local SwapText   = Motion.SwapText
local Attach = Layout.Attach
local DOCKS = {
	Center      = { Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0) },
	Top         = { Vector2.new(0.5, 0),   UDim2.new(0.5, 0, 0, 0) },
	Bottom      = { Vector2.new(0.5, 1),   UDim2.new(0.5, 0, 1, 0) },
	Left        = { Vector2.new(0, 0.5),   UDim2.new(0, 0, 0.5, 0) },
	Right       = { Vector2.new(1, 0.5),   UDim2.new(1, 0, 0.5, 0) },
	TopLeft     = { Vector2.new(0, 0),     UDim2.new(0, 0, 0, 0) },
	TopRight    = { Vector2.new(1, 0),     UDim2.new(1, 0, 0, 0) },
	BottomLeft  = { Vector2.new(0, 1),     UDim2.new(0, 0, 1, 0) },
	BottomRight = { Vector2.new(1, 1),     UDim2.new(1, 0, 1, 0) },
}
local function MakeWindow(Options)
	Options = Options or {}
	local Window = {}
	local Order = 0
	local Shown = false
	local Destroyed = false
	local Opening = nil
	local Leaving_ = nil
	local Plated = false
	local Blur = nil
	local ParallaxConnection = nil
	local KeyConnection = nil
	local FitConnection = nil
	local Width  = Options.Width or Metrics.WindowWidth
	local Height = Options.Height or Metrics.WindowHeight
	local Variant = Options.Variant or (Options.Chrome == false and "Bare") or "Rules"
	local Bare = Variant == "Bare" or Variant == "Panel"
	local Scrolls = Options.Scroll ~= false and not Bare or Options.Scroll == true
	local Wash = Options.Wash == nil and (Bare and 1 or 0.55) or Options.Wash
	local BlurSize = Options.Blur == nil and (Bare and 0 or 22) or Options.Blur
	local Padded = Options.Padding == nil and (Bare and 0 or Metrics.WindowPadding - 14) or Options.Padding
	local Dock = DOCKS[Options.Dock or "Center"] or DOCKS.Center
	local Anchor = Options.AnchorPoint or Dock[1]
	local Base = Options.Position or Dock[2]
	local Drift = Vector2.zero
	local Backdrop = New("Frame", {
		Name                   = "Backdrop",
		Parent                 = Screen.Get(),
		BackgroundColor3       = Options.WashColor or Theme.Scrim,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		Visible                = false,
		ZIndex                 = 1,
	})
	Screen.Cover(Backdrop)
	if Options.Backdrop == false or Wash >= 1 then
		Backdrop:Destroy()
		Backdrop = nil
	end
	local Root = New("Frame", {
		Name                   = Options.Name or "Window",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundTransparency = 1,
		AnchorPoint            = Anchor,
		Position               = Base,
		Size                   = UDim2.new(0, Width, 0, Height),
		Visible                = false,
		ZIndex                 = Options.ZIndex or 2,
	})
	local Group = New("CanvasGroup", {
		Name                   = "Group",
		Parent                 = Root,
		BackgroundColor3       = Options.Fill or Theme.Scrim,
		BackgroundTransparency = Options.FillTransparency == nil and 1 or Options.FillTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		GroupTransparency      = 1,
	}, Options.Radius and { Corner(Options.Radius) } or nil)
	if Variant == "Card" then
		Group.BackgroundTransparency = Options.FillTransparency or 0.08
		Corner(Util.Radius(Options, Metrics.CardRadius)).Parent = Group
		Stroke(Theme.White, 0.85, 1).Parent = Group
	end
	local Shield = nil
	if Options.Shield ~= false then
		Shield = New("TextButton", {
			Name                   = "Shield",
			Parent                 = Group,
			Text                   = "",
			AutoButtonColor        = false,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 0,
			Modal                  = false,
		})
	end
	local LeftRule, RightRule = nil, nil
	if Variant == "Rules" then
		local function Side(Side_)
			return New("Frame", {
				Name                   = Side_ == 0 and "LeftRule" or "RightRule",
				Parent                 = Group,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.RuleTransparency,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(Side_, 0.5),
				Position               = UDim2.new(Side_, 0, 0.5, 0),
				Size                   = UDim2.new(0, 1, 0, 0),
				ZIndex                 = 3,
			})
		end
		LeftRule, RightRule = Side(0), Side(1)
	end
	local Content = New("Frame", {
		Name                   = "Content",
		Parent                 = Group,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ClipsDescendants       = Options.Clip ~= false,
	}, {
		Padding(Options.PaddingTop or (Bare and 0 or 20), Padded,
			Options.PaddingBottom or (Bare and 0 or 14), Padded),
	})
	local Header, Title, Subtitle = nil, nil, nil
	if Options.Title or Options.Subtitle then
		Header = New("Frame", {
			Name                   = "Header",
			Parent                 = Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
		}, {
			Padding(0, Metrics.RowPadding),
			List(1),
		})
		Title = Text({
			Parent      = Header,
			Text        = Options.Title or "",
			TextSize    = Options.TitleSize or Metrics.TitleSize,
			TextWrapped = true,
			LayoutOrder = 1,
		})
		if Options.Subtitle then
			Subtitle = Text({
				Parent           = Header,
				Text             = Options.Subtitle,
				TextSize         = Options.SubtitleSize or Metrics.SubtitleSize,
				TextTransparency = Theme.TextSecondary,
				TextWrapped      = true,
				LayoutOrder      = 2,
			})
		end
	end
	local TitleBar, Controls_ = nil, {}
	if Options.TitleBar then
		TitleBar = New("Frame", {
			Name                   = "TitleBar",
			Parent                 = Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 22),
			ZIndex                 = 6,
		}, {
			Padding(0, Metrics.RowPadding),
		})
		Text({
			Parent           = TitleBar,
			Text             = Options.Title or Options.Name or "Window",
			FontFace         = Theme.FontMono,
			TextSize          = Metrics.MonoBoldSize,
			TextTransparency = Theme.TextTertiary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			Size             = UDim2.new(1, -70, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		New("Frame", {
			Parent                 = TitleBar,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 1),
			Position               = UDim2.new(0, 0, 1, 0),
			Size                   = UDim2.new(1, 0, 0, 1),
		})
		local Buttons = New("Frame", {
			Parent                 = TitleBar,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(1, 0, 0.5, 0),
			Size                   = UDim2.new(0, 60, 1, 0),
			ZIndex                 = 7,
		}, {
			New("UIListLayout", {
				Padding             = UDim.new(0, 6),
				FillDirection       = Enum.FillDirection.Horizontal,
				SortOrder           = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment   = Enum.VerticalAlignment.Center,
			}),
		})
		local function Control(Order, Kind, OnPress)
			local Button = New("TextButton", {
				Name                   = Kind,
				Parent                 = Buttons,
				BackgroundTransparency = 1,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(0, 14, 0, 14),
				LayoutOrder            = Order,
				ZIndex                 = 8,
			})
			if Kind == "Minimise" then
				New("Frame", {
					Parent                 = Button,
					BackgroundColor3       = Theme.White,
					BackgroundTransparency = Theme.TextSecondary,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(0.5, 1),
					Position               = UDim2.new(0.5, 0, 1, -3),
					Size                   = UDim2.new(0, 10, 0, 1),
				})
			elseif Kind == "Maximise" then
				New("Frame", {
					Parent                 = Button,
					BackgroundTransparency = 1,
					AnchorPoint            = Vector2.new(0.5, 0.5),
					Position               = UDim2.new(0.5, 0, 0.5, 0),
					Size                   = UDim2.new(0, 10, 0, 10),
				}, {
					Stroke(Theme.White, Theme.TextSecondary, 1),
				})
			else
				for Arm = 1, 2 do
					New("Frame", {
						Parent                 = Button,
						BackgroundColor3       = Theme.White,
						BackgroundTransparency = Theme.TextSecondary,
						BorderSizePixel        = 0,
						AnchorPoint            = Vector2.new(0.5, 0.5),
						Position               = UDim2.new(0.5, 0, 0.5, 0),
						Size                   = UDim2.new(0, 11, 0, 1),
						Rotation               = Arm == 1 and 45 or -45,
					})
				end
			end
			Button.Activated:Connect(OnPress)
			Controls_[Kind] = Button
			return Button
		end
		if Options.Minimise ~= false then
			Control(1, "Minimise", function()
				Window:Minimise()
			end)
		end
		if Options.Maximise ~= false then
			Control(2, "Maximise", function()
				Window:Maximise()
			end)
		end
		if Options.Closable ~= false then
			Control(3, "Close", function()
				Window:Close()
			end)
		end
	end
	local Body = nil
	if Scrolls then
		Body = New("ScrollingFrame", {
			Name                   = "Body",
			Parent                 = Content,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Position               = UDim2.new(0, 0, 0, 0),
			Size                   = UDim2.new(1, 0, 1, 0),
			CanvasSize             = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize    = Enum.AutomaticSize.Y,
			ScrollBarThickness     = 0,
			ScrollingDirection     = Enum.ScrollingDirection.Y,
			ClipsDescendants       = true,
		}, {
			List(Options.Gap or Metrics.RowGap),
		})
		Window.Scroll = Scroll.Attach(Body, "Y", { Gleam = Options.Gleam })
	else
		Body = New("Frame", {
			Name                   = "Body",
			Parent                 = Content,
			BackgroundTransparency = 1,
			Position               = UDim2.new(0, 0, 0, 0),
			Size                   = UDim2.new(1, 0, 1, 0),
			AutomaticSize          = Options.AutoSize and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		}, {
			List(Options.Gap or Metrics.RowGap),
		})
	end
	local StatusBar = nil
	if Options.StatusBar then
		StatusBar = New("Frame", {
			Name                   = "StatusBar",
			Parent                 = Content,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(0, 1),
			Position               = UDim2.new(0, 0, 1, 0),
			Size                   = UDim2.new(1, 0, 0, 18),
			ZIndex                 = 6,
		}, {
			Padding(0, Metrics.RowPadding),
		})
		New("Frame", {
			Parent                 = StatusBar,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 1),
		})
		Window.StatusLabel = Text({
			Parent           = StatusBar,
			Text             = type(Options.StatusBar) == "string" and Options.StatusBar or "",
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			Position         = UDim2.new(0, 0, 0, 2),
			Size             = UDim2.new(1, 0, 1, -2),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
	end
	local function Reflow()
		local Top = TitleBar and 28 or 0
		local Bottom = StatusBar and 22 or 0
		if Header then
			Header.Position = UDim2.new(0, 0, 0, Top)
			Top += Header.AbsoluteSize.Y + 18
		end
		Body.Position = UDim2.new(0, 0, 0, Top)
		Body.Size = UDim2.new(1, 0, 1, -(Top + Bottom))
	end
	if Header then
		Header:GetPropertyChangedSignal("AbsoluteSize"):Connect(Reflow)
	end
	task.defer(Reflow)
	local Unlock = Options.UnlockMouse
	if Unlock == nil then
		Unlock = not Bare
	end
	local Modal = New("TextButton", {
		Name                   = "Modal",
		Parent                 = Root,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 0, 0, 0),
		Modal                  = Unlock,
		Visible                = false,
	})
	local Overlay = New("Frame", {
		Name                   = "Overlay",
		Parent                 = Root,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 40,
	})
	Window.Root     = Root
	Window.Overlay  = Overlay
	Window.Body     = Body
	Window.Backdrop = Backdrop
	Window.Canvas   = Group
	Window.Content  = Content
	Window.HeaderFrame = Header
	Window.TitleBar = TitleBar
	Window.TabBars  = {}
	Window.Options  = Options
	local Poppers = {}
	local Children = {}
	function Window:_Order()
		Order += 1
		return Order
	end
	function Window:_Mount()
		return Body
	end
	function Window:_Overlay()
		return Overlay
	end
	function Window:_Window()
		return Window
	end
	function Window:_Register(Close)
		table.insert(Poppers, Close)
	end
	function Window:_ClosePopovers()
		for _, Close in Poppers do
			Close()
		end
	end
	function Window:Section(Title_, Description, SectionOptions)
		return Layout.Section(Window, Title_, Description, SectionOptions)
	end
	function Window:Tabs(TabOptions)
		return Layout.Tabs(Window, TabOptions)
	end
	Window._MakeTabs = Window.Tabs
	function Window:IsOpen()
		return Shown
	end
	function Window:Open()
		if Shown or Destroyed then
			return Window
		end
		Shown = true
		Root.Visible = true
		Modal.Visible = true
		if Window.Scroll then
			Window.Scroll:Top()
		elseif Body:IsA("ScrollingFrame") then
			Body.CanvasPosition = Vector2.zero
		end
		if Backdrop then
			Backdrop.Visible = true
			Tween(Backdrop, { BackgroundTransparency = Wash }, "enter")
		end
		if BlurSize > 0 then
			if not Blur then
				Blur = New("BlurEffect", { Parent = Lighting, Size = 0, Name = "KuikBlur" })
			end
			Tween(Blur, { Size = BlurSize }, "enter")
		end
		local Wants = Options.Reveal
		if Wants == nil then
			Wants = Metrics.Reveal and not Bare
		end
		if Wants then
			local Setting = type(Wants) == "table" and Wants or {}
			local function Try()
				if Opening then
					Opening.Cancel()
				end
				Opening = Reveal.Plate(Group, {
					Parent = Root,
					Now    = true,
					To     = 0,
					Radius = Options.Radius or (Variant == "Card" and Metrics.CardRadius or 0),
					Color  = Setting.Color,
					From   = Setting.From or Options.RevealFrom,
					Drift  = Setting.Drift,
				})
				Plated = Opening ~= nil and Opening.Face ~= nil
				if not Plated then
					Tween(Group, { GroupTransparency = 0 }, "enter")
				end
			end
			if Root.AbsoluteSize.X > 2 then
				Try()
			else
				task.defer(function()
					if Shown and not Destroyed then
						Try()
					end
				end)
			end
		else
			Tween(Group, { GroupTransparency = 0 }, "enter")
		end
		if LeftRule then
			Tween(LeftRule, { Size = UDim2.new(0, 1, 1, 0) }, "reveal")
			Tween(RightRule, { Size = UDim2.new(0, 1, 1, 0) }, "reveal")
		end
		if Options.Opened then
			task.spawn(Options.Opened, Window)
		end
		return Window
	end
	function Window:Close()
		if not Shown or Destroyed then
			return Window
		end
		if Leaving_ then
			Leaving_.Cancel()
			Leaving_ = nil
		end
		Window:_ClosePopovers()
		for _, Child in Children do
			Child:Close()
		end
		Shown = false
		Modal.Visible = false
		if Blur then
			Tween(Blur, { Size = 0 }, "exit")
		end
		if Backdrop then
			Tween(Backdrop, { BackgroundTransparency = 1 }, "exit")
		end
		local Handle = nil
		if Opening or Plated then
			if Opening then
				Opening.Cancel()
				Opening = nil
			end
			Plated = false
			local Setting = type(Options.Reveal) == "table" and Options.Reveal or {}
			Leaving_ = Reveal.Cover(Group, {
				Parent = Root,
				Radius = Options.Radius or (Variant == "Card" and Metrics.CardRadius or 0),
				Color  = Setting.Color,
			})
		end
		if not Leaving_ or not Leaving_.Face then
			Handle = Tween(Group, { GroupTransparency = 1 }, "exit")
		end
		if LeftRule then
			Tween(LeftRule, { Size = UDim2.new(0, 1, 0, 0) }, "exit")
			Handle = Tween(RightRule, { Size = UDim2.new(0, 1, 0, 0) }, "exit")
		end
		Handle.Completed:Once(function()
			if not Shown then
				Root.Visible = false
				if Backdrop then
					Backdrop.Visible = false
				end
			end
		end)
		if Options.Closed then
			task.spawn(Options.Closed, Window)
		end
		return Window
	end
	function Window:SetOpen(Open)
		if Open then
			return Window:Open()
		end
		return Window:Close()
	end
	Window.Show = Window.Open
	Window.Hide = Window.Close
	local function Clear(Target)
		if Options.Safe == false or Root.AnchorPoint.Y > 0.5 then
			return Target
		end
		local Top = Screen.Inset()
		if Top <= 0 or Target.Y.Scale > 0.5 then
			return Target
		end
		local Tall = Screen.Get().AbsoluteSize.Y
		local At = Target.Y.Scale * Tall + Target.Y.Offset
		local Above = At - Root.AnchorPoint.Y * Root.AbsoluteSize.Y
		if Above >= Top then
			return Target
		end
		return UDim2.new(
			Target.X.Scale, Target.X.Offset,
			Target.Y.Scale, Target.Y.Offset + (Top - Above))
	end
	local function Land(Animate)
		local Target = Clear(UDim2.new(
			Base.X.Scale, Base.X.Offset + Drift.X,
			Base.Y.Scale, Base.Y.Offset + Drift.Y))
		if Animate == false then
			Motion.Halt(Root, "Position")
			Root.Position = Target
		else
			Tween(Root, { Position = Target }, Animate == true and "layout" or Animate)
		end
	end
	function Window:SetPosition(Position, Animate)
		Base = Position
		Land(Animate)
		return Window
	end
	function Window:GetPosition()
		return Base
	end
	function Window:SetAnchor(Point)
		Root.AnchorPoint = Point
		return Window
	end
	function Window:SetSize(NewWidth, NewHeight, Animate)
		Width = NewWidth or Width
		Height = NewHeight or Height
		local Target = UDim2.new(0, Width, 0, Height)
		if Animate == false then
			Motion.Halt(Root, "Size")
			Root.Size = Target
		else
			Tween(Root, { Size = Target }, Animate == true and "layout" or Animate)
		end
		return Window
	end
	function Window:GetSize()
		return Width, Height
	end
	function Window:Dock(Where, Inset, Animate)
		local Spot = DOCKS[Where]
		if not Spot then
			return Window
		end
		local Pad = Inset or 0
		local Anchor_ = Spot[1]
		Root.AnchorPoint = Anchor_
		Base = UDim2.new(
			Spot[2].X.Scale,
			Spot[2].X.Offset + (Anchor_.X == 0 and Pad or Anchor_.X == 1 and -Pad or 0),
			Spot[2].Y.Scale,
			Spot[2].Y.Offset + (Anchor_.Y == 0 and Pad or Anchor_.Y == 1 and -Pad or 0))
		Land(Animate)
		return Window
	end
	function Window:Nudge(X, Y, Animate)
		Base = UDim2.new(Base.X.Scale, Base.X.Offset + X, Base.Y.Scale, Base.Y.Offset + Y)
		Land(Animate)
		return Window
	end
	function Window:SetScale(Scale, Animate)
		local Handle = Root:FindFirstChildOfClass("UIScale")
			or New("UIScale", { Parent = Root, Scale = 1 })
		if Animate == false then
			Motion.Halt(Handle, "Scale")
			Handle.Scale = Scale
		else
			Tween(Handle, { Scale = Scale }, "toss")
		end
		return Window
	end
	function Window:SetOpacity(Alpha, Animate)
		if Animate == false then
			Motion.Halt(Group, "GroupTransparency")
			Group.GroupTransparency = 1 - Alpha
		else
			Tween(Group, { GroupTransparency = 1 - Alpha }, "fade")
		end
		return Window
	end
	function Window:SetZIndex(Value)
		Root.ZIndex = Value
		return Window
	end
	function Window:BringToFront()
		local Highest = 0
		for _, Sibling in Root.Parent:GetChildren() do
			if Sibling:IsA("GuiObject") and Sibling ~= Root then
				Highest = math.max(Highest, Sibling.ZIndex)
			end
		end
		Root.ZIndex = Highest + 1
		return Window
	end
	local Restored = nil
	function Window:Minimise()
		if Restored then
			return Window:Restore()
		end
		Restored = { Width = Width, Height = Height }
		Window:SetSize(Width, TitleBar and 28 or 34)
		return Window
	end
	function Window:Maximise()
		local Viewport = Screen.Get().AbsoluteSize
		if Restored then
			return Window:Restore()
		end
		Restored = { Width = Width, Height = Height }
		Window:SetSize(math.max(200, Viewport.X - 60), math.max(160, Viewport.Y - 80))
		return Window
	end
	function Window:Restore()
		if not Restored then
			return Window
		end
		Window:SetSize(Restored.Width, Restored.Height)
		Restored = nil
		return Window
	end
	function Window:IsRestored()
		return Restored == nil
	end
	function Window:SetStatus(Text_)
		if Window.StatusLabel then
			Window.StatusLabel.Text = Text_
		end
		return Window
	end
	function Window:SetTitle(NewTitle, NewSubtitle)
		if Title and NewTitle then
			SwapText(Title, NewTitle)
		end
		if Subtitle and NewSubtitle then
			SwapText(Subtitle, NewSubtitle)
		end
		return Window
	end
	function Window:SetFill(Colour, Alpha, Animate)
		if Colour then
			Motion.Paint(Group, { BackgroundColor3 = Colour }, Animate)
		end
		if Alpha ~= nil then
			Tween(Group, { BackgroundTransparency = Alpha }, "fade")
		end
		return Window
	end
	local Dragging = nil
	local DragConnections = {}
	function Window:SetDraggable(Enabled, Grip)
		for _, Connection in DragConnections do
			Connection:Disconnect()
		end
		table.clear(DragConnections)
		if not Enabled then
			return Window
		end
		local Handle = Grip or TitleBar or Header or Group
		table.insert(DragConnections, Handle.InputBegan:Connect(function(Input)
			if Input.UserInputType ~= Enum.UserInputType.MouseButton1
				and Input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			Dragging = {
				Start = Input.Position,
				Origin = Base,
			}
			Window:BringToFront()
		end))
		table.insert(DragConnections, UserInputService.InputChanged:Connect(function(Input)
			if not Dragging then
				return
			end
			if Input.UserInputType ~= Enum.UserInputType.MouseMovement
				and Input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local Delta = Input.Position - Dragging.Start
			Base = UDim2.new(
				Dragging.Origin.X.Scale, Dragging.Origin.X.Offset + Delta.X,
				Dragging.Origin.Y.Scale, Dragging.Origin.Y.Offset + Delta.Y)
			Land("drag")
		end))
		table.insert(DragConnections, UserInputService.InputEnded:Connect(function(Input)
			if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch) then
				Dragging = nil
				if Options.Moved then
					task.spawn(Options.Moved, Base)
				end
			end
		end))
		return Window
	end
	local Grip = nil
	function Window:SetResizable(Enabled)
		if not Enabled then
			if Grip then
				Grip:Destroy()
				Grip = nil
			end
			return Window
		end
		if Grip then
			return Window
		end
		Grip = New("TextButton", {
			Name                   = "Grip",
			Parent                 = Root,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			AnchorPoint            = Vector2.new(1, 1),
			Position               = UDim2.new(1, 0, 1, 0),
			Size                   = UDim2.new(0, 16, 0, 16),
			ZIndex                 = 45,
		})
		for Index = 1, 2 do
			New("Frame", {
				Parent                 = Grip,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.RuleTransparency,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(1, 1),
				Position               = UDim2.new(1, -2, 1, -2),
				Size                   = Index == 1
					and UDim2.new(0, 10, 0, 1)
					or UDim2.new(0, 1, 0, 10),
			})
		end
		local Sizing = nil
		Grip.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
				Sizing = { Start = Input.Position, Width = Width, Height = Height }
			end
		end)
		table.insert(DragConnections, UserInputService.InputChanged:Connect(function(Input)
			if not Sizing then
				return
			end
			if Input.UserInputType ~= Enum.UserInputType.MouseMovement
				and Input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local Delta = Input.Position - Sizing.Start
			Window:SetSize(
				math.max(Options.MinWidth or 160, Sizing.Width + Delta.X),
				math.max(Options.MinHeight or 120, Sizing.Height + Delta.Y),
				"drag")
		end))
		table.insert(DragConnections, UserInputService.InputEnded:Connect(function(Input)
			if Sizing and (Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch) then
				Sizing = nil
				if Options.Resized then
					task.spawn(Options.Resized, Width, Height)
				end
			end
		end))
		return Window
	end
	function Window:SetParallax(Amount)
		if ParallaxConnection then
			ParallaxConnection:Disconnect()
			ParallaxConnection = nil
		end
		if not Amount or Amount <= 0 then
			Drift = Vector2.zero
			Land("layout")
			return Window
		end
		local Offset = Vector2.zero
		local LastYaw, LastPitch = nil, nil
		ParallaxConnection = RunService.RenderStepped:Connect(function(Delta)
			local Camera = workspace.CurrentCamera
			if not Camera then
				return
			end
			local Look = Camera.CFrame.LookVector
			local Yaw = math.atan2(-Look.X, -Look.Z)
			local Pitch = math.asin(Clamp(Look.Y, -1, 1))
			if LastYaw then
				local YawDelta = Yaw - LastYaw
				if YawDelta > math.pi then
					YawDelta -= math.pi * 2
				elseif YawDelta < -math.pi then
					YawDelta += math.pi * 2
				end
				Offset += Vector2.new(YawDelta, Pitch - LastPitch) * Amount * 30
			end
			LastYaw, LastPitch = Yaw, Pitch
			Offset = Offset:Lerp(Vector2.zero, math.min(1, Delta * 7))
			Drift = Vector2.new(
				Clamp(Offset.X, -Amount, Amount),
				Clamp(Offset.Y, -Amount, Amount))
			Land("drag")
		end)
		return Window
	end
	function Window:GoTo(Name)
		for _, Bar in Window.TabBars do
			if Bar:Pages()[Name] then
				Bar:Select(Name)
				return true
			end
		end
		return false
	end
	function Window:Reveal(Target)
		local Frame = typeof(Target) == "Instance" and Target
			or (type(Target) == "table" and Target.Frame)
		if not Frame then
			return false
		end
		local Node = Frame
		while Node and Node ~= Body do
			if string.sub(Node.Name, 1, 5) == "Page_" then
				Window:GoTo(string.sub(Node.Name, 6))
				break
			end
			Node = Node.Parent
		end
		task.defer(function()
			if not Body:IsA("ScrollingFrame") then
				return
			end
			local Offset = Frame.AbsolutePosition.Y - Body.AbsolutePosition.Y + Body.CanvasPosition.Y
			local Span = math.max(0, Body.AbsoluteCanvasSize.Y - Body.AbsoluteSize.Y)
			local To = Clamp(Offset - Body.AbsoluteSize.Y / 3, 0, Span)
			if Window.Scroll then
				Window.Scroll:To(Vector2.new(0, To))
			else
				Body.CanvasPosition = Vector2.new(0, To)
			end
			if Frame:IsA("GuiObject") then
				for Index = 1, 2 do
					task.delay(MotionTime("scroll") + (Index - 1) * 0.24, function()
						Tween(Frame, { BackgroundTransparency = 0.7 }, "hover")
						task.delay(0.12, function()
							Tween(Frame, { BackgroundTransparency = Theme.RowTransparency }, "fade")
						end)
					end)
				end
			end
		end)
		return true
	end
	function Window:Child(ChildOptions)
		ChildOptions = ChildOptions or {}
		local Child = MakeWindow(Util.Merge(ChildOptions, {
			Width       = ChildOptions.Width or 300,
			Height      = ChildOptions.Height or 320,
			Blur        = ChildOptions.Blur or 0,
			Wash        = ChildOptions.Wash or 1,
			UnlockMouse = false,
			Parent      = Root,
		}))
		Child.Root.AnchorPoint = ChildOptions.AnchorPoint or Vector2.new(0, 0.5)
		Child:SetPosition(ChildOptions.Position
			or UDim2.new(1, ChildOptions.Offset or 34, 0.5, 0), false)
		if Child.Backdrop then
			Child.Backdrop:Destroy()
			Child.Backdrop = nil
		end
		Child.Owner = Window
		table.insert(Children, Child)
		Child:OnDestroy(function()
			local At = table.find(Children, Child)
			if At then
				table.remove(Children, At)
			end
		end)
		if ChildOptions.Open then
			Child:Open()
		end
		return Child
	end
	function Window:Children()
		return Children
	end
	local Closing = {}
	function Window:OnDestroy(Handler)
		table.insert(Closing, Handler)
		return Window
	end
	local Leaving = false
	function Window:Destroy(Animate)
		if Destroyed then
			return
		end
		if Animate then
			if Leaving then
				return
			end
			Leaving = true
			Modal.Visible = false
			if Backdrop then
				Tween(Backdrop, { BackgroundTransparency = 1 }, "exit")
			end
			if Blur then
				Tween(Blur, { Size = 0 }, "exit")
			end
			Motion.Out(Root, function()
				Leaving = false
				Window:Destroy()
			end, "shrink")
			return
		end
		Destroyed = true
		for _, Handler in Closing do
			task.spawn(Handler, Window)
		end
		for _, Child in table.clone(Children) do
			Child:Destroy()
		end
		table.clear(Children)
		for _, Connection in DragConnections do
			Connection:Disconnect()
		end
		table.clear(DragConnections)
		if Window.Scroll then
			Window.Scroll:Destroy()
		end
		if ParallaxConnection then
			ParallaxConnection:Disconnect()
		end
		if KeyConnection then
			KeyConnection:Disconnect()
		end
		if FitConnection then
			FitConnection:Disconnect()
		end
		if Blur then
			Blur:Destroy()
		end
		Root:Destroy()
		if Backdrop then
			Backdrop:Destroy()
		end
	end
	function Window:IsAlive()
		return not Destroyed
	end
	if Options.Fit ~= false and not Bare then
		local function Fit()
			local Viewport = Screen.Get().AbsoluteSize
			if Viewport.X > 0 then
				Root.Size = UDim2.new(
					0, math.min(Width, Viewport.X - 40),
					0, math.min(Height, Viewport.Y - 80))
			end
			Land(false)
		end
		FitConnection = Screen.Get():GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
		task.defer(Fit)
	else
		task.defer(function()
			if not Destroyed then
				Land(false)
			end
		end)
	end
	if Options.Key then
		KeyConnection = UserInputService.InputBegan:Connect(function(Input, Processed)
			if not Processed and not Screen.Blocked() and Input.KeyCode == Options.Key then
				Window:SetOpen(not Shown)
			end
		end)
	end
	if Options.Draggable then
		Window:SetDraggable(true, Options.Grip)
	end
	if Options.Resizable then
		Window:SetResizable(true)
	end
	if Options.Parallax then
		Window:SetParallax(Options.Parallax)
	end
	if Options.Open then
		task.defer(function()
			Window:Open()
		end)
	end
	return Attach(Window)
end
Shared.Window = MakeWindow
return MakeWindow
end
return KuikRequire("")
