--!nonstrict
--- Util.luau — instance building and the small helpers everything shares.

local Palette = require(script.Parent.Theme)

local Theme   = Palette.Tokens
local Metrics = Palette.Metrics

local Util = {}

--- Builds an instance from a property table and a child list. Parent is
--- applied last so a tree lands in one insertion rather than reflowing per
--- child, and every object passes through the theme tracker on the way out.
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

--- Formats to the precision the step implies, with trailing zeroes trimmed, so
--- a 0.05 step reads "1.25" and a 1 step reads "1".
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

--- Mixes toward white or black, for hover and pressed states that have to work
--- against whatever colour the caller passed.
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

--- A horizontal strip layout, since it is the second most common thing built.
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

--- One pixel of rule. The bracket that frames half the library.
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

--- A TextLabel with the library defaults already on it.
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

--- Three stacked bars: the log bullet and the menu mark.
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

--- A drawn key, for the hint rail.
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

--- A chevron built from two bars, which is how every arrow in the library is
--- drawn. Returns the holder and the arms so callers can rotate them.
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

	--- A chevron dropped into a button sits in the middle of it. One dropped
	--- into something that lays its children out is left alone, because a
	--- layout ignores the position but not the anchor, and moving the anchor
	--- would shift it out of its own slot. Anything that wants it somewhere
	--- else sets the anchor and position afterwards, and wins.
	if not (Parent:FindFirstChildOfClass("UIListLayout")
		or Parent:FindFirstChildOfClass("UIGridLayout")) then
		Holder.AnchorPoint = Vector2.new(0.5, 0.5)
		Holder.Position = UDim2.new(0.5, 0, 0.5, 0)
	end

	return Holder, Arms
end

--- Options resolution. Every control runs its radius, colour and gap through
--- these so a caller can override any of them per widget without the control
--- needing to know about it.
local function Radius(Options, Fallback)
	local Wanted = Options and Options.Radius

	if Wanted == nil then
		return Fallback or 0
	end

	return Wanted
end

local function Round(Options, Fallback, Cap)
	--- Fully round elements clamp against PillRadius, so squaring the theme
	--- squares them too.
	return math.min(Radius(Options, Metrics.PillRadius), Cap or Fallback or 999)
end

local function Colour(Options, Fallback)
	return (Options and Options.Color) or Fallback or Theme.Accent
end

--- Resolves a caller supplied surface into a colour and a transparency, which
--- is how every embed decides whether it has a plate behind it.
---
---   Background = false          no plate at all
---   Background = Color3         that colour, opaque unless told otherwise
---   BackgroundTransparency = n  overrides the transparency either way
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

--- Turns a user id, an asset id or a bare number into something an ImageLabel
--- will actually load.
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

--- The nearest ancestor that is not laying its children out.
---
--- A UIListLayout arranges EVERY visible GuiObject child, so anything dropped
--- into one to sit over, behind or beside its content stops being a decoration
--- and becomes another item in the column. Everything that hangs a shape off
--- something else — an edge light, a reveal plate, a wipe bar, an afterimage —
--- climbs past the layout first, and positions itself in the host's own pixels.
---
--- This has cost real bugs three times: gleams turning into rows inside a
--- dropdown, a notice growing by the width of its own underline, and a status
--- chip's two bracket rules ending up side by side in front of the text.
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

--- Copies Extra over a clone of Base. Used everywhere a caller's options need
--- merging with a preset without mutating either.
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
