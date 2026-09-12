--!nonstrict
--- Inputs.luau — the controls you change a value with.

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Palette = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local Motion  = require(script.Parent.Parent.Motion)
local Parts   = require(script.Parent.Parent.Parts)
local Scroll  = require(script.Parent.Parent.Scroll)
local Screen  = require(script.Parent.Parent.Screen)

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

--- An invisible button covering a row, which is how every row wide hit target
--- is made without disturbing the layout.
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

--- A chip: the small dark plate a value sits in.
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

--- Toggle. Three looks, one behaviour.
---
---   Variant = "Switch"  a sliding knob, the default
---   Variant = "Check"   a box with a tick
---   Variant = "Pill"    a lozenge reading ON or OFF
function Controls.Toggle(Container, Options)
	local Handle = {}
	local Variant = Options.Variant or "Switch"
	local Accent = Colour(Options, Theme.White)

	--- Tri-state keeps nil as a real value — neither on nor off. That rules out
	--- the usual `a and b or c`, which cannot carry nil or false through, so
	--- both places that assign it are written out longhand.
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

		--- Square, and square by pixels rather than by scale: a box that takes
		--- its height from the row grows with the description and stops being
		--- a box at all.
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

		--- The tick is drawn to the box, not to a fixed pixel count, so
		--- changing Metrics.CheckSize keeps it centred and in proportion.
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

		--- The middle state of a tri-state box: neither on nor off, drawn as a
		--- bar rather than a tick.
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

		--- The knob is as round as the track is, never more and never less.
		--- Both clamp against PillRadius, so squaring the theme squares the
		--- head with the pill instead of leaving a round head in a square
		--- slot.
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

	--- The row itself is the button.
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

	--- Two states, or three. A tri-state runs off, on, mixed and back.
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

--- Checkbox is a Toggle wearing the box.
function Controls.Checkbox(Container, Options)
	return Controls.Toggle(Container, Util.Merge(Options, { Variant = "Check" }))
end

--- Switch, spelled out, for anyone who reaches for that name first.
function Controls.Switch(Container, Options)
	return Controls.Toggle(Container, Util.Merge(Options, { Variant = "Switch" }))
end

--- Slider. The readout sits top right, the track runs the width of the row
--- underneath, and the whole strip is draggable.
---
---   Variant = "Bar"    a plain fill, the default
---   Variant = "Ticks"  notches at every step
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

	--- Re-ranging a live slider, for settings whose bounds depend on
	--- something else the player just changed.
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

--- Range. Two thumbs on one track; whichever is nearer the pointer moves.
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

--- Stepper. Click the left half to go down, the right half to go up.
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

--- Text field. Multiline grows the row; Password masks; Numeric refuses
--- anything that is not a number when it loses focus.
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

	--- Masking has to keep the real text somewhere, so the box shows dots and
	--- the value lives in the closure.
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
			--- Only the newly typed tail is real; the rest is already dots.
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

--- A text area, spelled out.
function Controls.TextArea(Container, Options)
	return Controls.Input(Container, Util.Merge(Options, { Multiline = true }))
end

--- A search field: live by default, with a drawn magnifier.
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

--- Keybind. Click, press a key, done; Escape backs out and Backspace clears.
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

--- Vector. One numeric field per axis, side by side.
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

--- Dropdown. The menu is parented to the owning window's overlay, not to the
--- row, so it draws over everything and is never clipped by a scroller.
---
---   Multi = true    checkboxes instead of a single choice
---   Search = true   a filter field above the list
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

		--- Flip above when there is no room below, which is what happens to
		--- the last row of any list.
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

	--- While the menu is open it tracks its chip every frame. Anything can move
	--- the row underneath it — a scroll, a window drag, an accordion opening
	--- above it — and a menu left where it was opened is the most common
	--- overlay bug there is.
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

			--- Gone from the screen entirely: close rather than float.
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

	--- Rebuilding the list rather than the whole control, so a dropdown fed by
	--- live data does not have to be torn down and remade.
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

					--- A multi select stays open; picking three things should
					--- not mean opening it three times.
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

	--- Clicking anywhere outside closes it.
	---
	--- Processed is deliberately not checked: every click on the interface is
	--- processed, and those are exactly the clicks that should dismiss a menu.
	--- The chip counts as inside, or pressing it to close would close on the
	--- press and reopen on the release.
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

--- Radio. One choice out of a list, laid out down or across.
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

--- Chips. A wrapping row of lozenges you switch on and off.
---
---   Single = true   behaves like a radio
---   Max = n         refuses the n plus first
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
		--- The pill is the button. It grows on the X axis, so a full size
		--- child inside it would measure against the width it is setting.
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

		--- The pill is the button: it grows on the X axis, and a full size
		--- child inside an AutomaticSize parent measures against itself.
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
				--- At the cap: flash the pill rather than silently ignoring.
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

--- Segmented. A track with a highlight that slides between the segments.
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

--- Tags. Type a word, press enter, it becomes a removable lozenge.
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

--- Tristate. A checkbox with a middle state, for "some of the things below".
function Controls.Tristate(Container, Options)
	return Controls.Toggle(Container, Util.Merge(Options, { Variant = "Tri" }))
end

--- Autocomplete. A field that suggests as you type, from a fixed list or from
--- a function you supply.
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

		--- Deferred: clicking a suggestion also drops focus, and hiding the
		--- menu first would eat the click.
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
