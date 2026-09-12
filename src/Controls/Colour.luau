--!nonstrict
--- Colour.luau — the colour controls.

local Palette = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local Motion  = require(script.Parent.Parent.Motion)
local Parts   = require(script.Parent.Parent.Parts)

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

--- The swatch and hex readout every colour control carries in its top right.
--- Lives in the block's Aside, which is hand positioned and therefore safe
--- from the list layout that would otherwise stretch it down the card.
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

	--- Roblox owns these colours, not the theme, so they must not be repainted
	--- when the theme changes.
	Palette.Release(Swatch)

	return Swatch, Label
end

--- Color. Three channel sliders, RGB.
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

--- ColorPicker. A saturation and brightness field over a hue strip.
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

	--- White across, black down: the standard two gradient stack that turns a
	--- flat hue into a saturation and brightness field.
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

--- Swatches. A fixed set of colours to pick from, which is usually what a game
--- actually wants rather than the whole spectrum.
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

--- Gradient. Two colours and a rotation, previewed live.
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
