--!nonstrict
--- Data.luau — the controls that show you something rather than take input.

local Palette = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local Motion  = require(script.Parent.Parent.Motion)
local Parts   = require(script.Parent.Parent.Parts)
local Scroll  = require(script.Parent.Parent.Scroll)

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

--- Status. A label with a monospaced value on the right — the readout row.
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

	--- Animate springs the colour across instead of cutting to it, for a value
	--- that changes meaning as well as reading — good to bad, say.
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

--- Stat. A big number with a caption under it, laid out across a grid.
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

		--- Truncated, not wrapped: a stat is one line, and a long value has to
		--- give way rather than run into the cell beside it.
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

		--- A rule under each cell keeps the row reading as a set rather than
		--- three unrelated numbers.
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

--- Badge. A coloured lozenge on the right of a row.
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

--- Progress. A percentage and a bar.
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

	--- Indeterminate: a shuttle rather than a fill, for work with no known end.
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

--- Meter. Segmented rather than continuous, and it changes colour as it fills.
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

--- Ring. A dial of ticks with a readout in the middle.
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

--- Spinner. Eight dots chasing each other.
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

--- Sparkline. A tiny line chart on the right of a row.
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

--- Graph. A full width line chart with a labelled axis.
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

	--- Gridlines behind the trace, drawn once.
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

		--- Nothing to draw into yet; the size listener will call us back.
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

--- Bars. A histogram that grows from the bottom.
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

--- Heatmap. A grid of cells shaded by value, for anything two dimensional.
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

--- Rating. Bars rather than stars, because stars are not the house style.
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

			--- Clicking the current value clears it, which is the only way to
			--- get back to nothing.
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

--- Pagination. Two arrows and a counter.
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

--- List. A scrolling column of choices with an accent that slides between them.
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

--- Table. Fixed columns, monospaced cells, a rule under the header.
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

--- Tree. A nested list with twist arrows.
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

					--- Collapsing hides the whole subtree, not just the level
					--- below, and reopening only restores what was open.
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

--- Timeline. Dated entries down a rule.
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

			--- The rule runs the full height of every entry but the last, so
			--- the chain reads as continuous.
			--- Declared here, measured against the column below once it
			--- exists. Measuring it against the entry would grow the entry,
			--- which would grow the line.
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

--------------------------------------------------------------------------
-- Donut, Scatter
--------------------------------------------------------------------------

--- Donut. A ring split by weight, with the parts named beside it.
---
--- A Ring says how far along one thing is. This says how a whole divides, which
--- needs a legend — a wedge nobody can name is decoration. Drawn out of arcs
--- rather than an image, so it takes the theme like everything else.
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

	--- The ring the wedges sit on, so a donut that adds up to less than the
	--- whole still reads as a donut.
	New("Frame", {
		Name                   = "Track",
		Parent                 = Face,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
	}, {
		Corner(math.floor(Size / 2)),
		Stroke(Theme.White, 0.9, Thickness),
	})

	--- One wedge is a quarter-disc mask rotated into place. Roblox has no arc
	--- primitive, so an arc is drawn as a run of short segments around the
	--- circle — the same trick the line chart uses, and cheap enough at this
	--- size.
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

		--- Cleared and redrawn from the top, clockwise.
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

--- Scatter. Two numbers per point, plotted against each other.
---
--- The Graph draws a series against its own index; this draws one thing against
--- another, which is the only way to see whether they are related at all.
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

	--- Two axes, drawn as hairlines along the bottom and the left.
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
