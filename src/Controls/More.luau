--!nonstrict
--- More.luau — the rest of the widget set.
---
--- Boards, terminals, media transport, and the placeholders and containers
--- that go around them.

local UserInputService = game:GetService("UserInputService")

local Palette = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local Motion  = require(script.Parent.Parent.Motion)
local Parts   = require(script.Parent.Parent.Parts)
local Scroll  = require(script.Parent.Parent.Scroll)
local Screen  = require(script.Parent.Parent.Screen)
local Shared  = require(script.Parent.Parent.Shared)

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

--------------------------------------------------------------------------
-- Placeholders and containers
--------------------------------------------------------------------------

--- Skeleton. Grey bars where content will be, pulsing while you wait.
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

	--- Widths taper so the block reads as a paragraph rather than a barcode.
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

--- Well. A bare framed canvas you can put anything in, including raw
--- instances. The plainest container there is.
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

--- LoadMore. The end of an infinite list: a rule that fetches the next page
--- and says when there is nothing left.
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

	--- No more pages: the rule stays, the invitation does not.
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

--------------------------------------------------------------------------
-- Boards
--------------------------------------------------------------------------

--- Kanban. Columns of cards, each column a container of its own.
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

--- Compare. A matrix: one row per feature, one column per thing, with a
--- highlighted column for the one you want people to pick.
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

			--- Booleans get a mark rather than the word, which is what a
			--- comparison table is actually for.
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

--- Treemap. Nested rectangles sized by value, laid out by slice and dice.
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

		--- Slice and dice: alternate the split axis at each step, which keeps
		--- the tiles closer to square than a plain column layout.
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

--- Motd. A framed banner, the thing a server prints when you connect.
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

--- AsciiBar. A progress bar drawn in characters, for a terminal look.
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

--- Kbd. A row of drawn keycaps, for telling someone which keys to press.
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

--------------------------------------------------------------------------
-- Media transport
--------------------------------------------------------------------------

--- Scrubber. A track you drag through, with elapsed and total either side.
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

	--- Buffered runs behind played, so a stream shows what it has ahead of
	--- where you are.
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

--- Volume. A slider with a drawn speaker and a mute toggle on it.
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

	--- A cone and two arcs, drawn rather than shipped as an image.
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

--- Knob. A rotary control: drag up and down to turn it.
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

	--- Vertical drag, not rotation: turning a knob by circling it is fiddly
	--- with a mouse and impossible on a touchscreen.
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

--- VU. A level meter with a peak that falls back slowly.
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
			--- The top of the scale is where clipping lives, so it is coloured
			--- before it is lit rather than after.
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

--- Waveform. A symmetrical bar display of a sample series.
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

	--- How far through the clip the playhead is, 0 to 1.
	function Handle:SetPlayed(Alpha)
		Played = Clamp(Alpha, 0, 1)
		Render()
		return Handle
	end

	Render()

	return BlockHandle(Built, Handle, Options)
end

--- Zoom. An image you can actually inspect: a magnifier that tracks the
--- pointer, or a pannable picture the wheel scales about the cursor.
---
--- Both modes share one rule — the magnified copy is sized in pixels against
--- the well, never in scale against its own parent, so a point at fraction
--- (X, Y) of the picture lands exactly under the pointer.
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
		--- Pan. The picture itself grows, and dragging slides it under a
		--- fixed window. Offsets are pixels from the well's top left.
		local OffsetX, OffsetY = 0, 0

		Picture.Size = UDim2.new(0, 0, 0, 0)

		local function Bound()
			local Size = Well.AbsoluteSize
			local Span = Vector2.new(Size.X * Factor, Size.Y * Factor)

			OffsetX = Clamp(OffsetX, math.min(0, Size.X - Span.X), 0)
			OffsetY = Clamp(OffsetY, math.min(0, Size.Y - Span.Y), 0)
		end

		--- Light the four inside faces in proportion to the travel left that
		--- way, so the picture says which directions it can still be dragged.
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

		--- Zoom about the pointer: the image point under it must not move.
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
		--- Loupe. A second copy of the picture, sized against the well so the
		--- magnification is honest, slid so the pointed at spot is centred.
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

	--- The well only has a size after a layout pass, so the first sizing has
	--- to wait for it, and every resize has to redo the maths.
	table.insert(Connections, Well:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		Apply(false)
	end))

	--- Two different things, kept apart on purpose.
	---
	--- Whether the pointer is over the well is answered by MouseEnter and
	--- MouseLeave, because Roblox already resolves what is on top: a window
	--- covering this one takes the hover and this control hears nothing.
	---
	--- Where the pointer is comes from InputObject.Position, which is measured
	--- from the same corner as AbsolutePosition. MouseMoved is not — it reports
	--- the whole screen including the top bar, so using it put the loupe a top
	--- bar's height below the cursor.
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

	--- The wheel is the page's before it is ours. A zoom sitting in a scrolling
	--- page that ate the wheel would silently stop the page scrolling whenever
	--- the pointer crossed it — and the picture would quietly rescale while
	--- someone was only trying to read further down. So by default it takes the
	--- wheel only while a control key is held. Wheel = true claims it outright,
	--- Wheel = false never takes it.
	local Claim = Options.Wheel == nil and "Ctrl" or Options.Wheel

	if Claim ~= false then
		table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
			--- Without the hover gate a wheel anywhere on screen moved every
			--- zoom in the interface at once.
			if Input.UserInputType ~= Enum.UserInputType.MouseWheel or not Over or not AtX then
				return
			end

			if Claim == "Ctrl" and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.LeftSuper)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightSuper)) then
				return
			end

			--- Steps grow with the factor so the zoom feels even rather than
			--- crawling at the top of the range.
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

--- Carousel. Paged cards with dots underneath, in one of two shapes.
---
---   Variant = "Strip"  a rail that slides, one pane at a time   (the default)
---   Variant = "Deck"   the current pane centred and full size, the ones
---                      either side of it behind it, smaller and dimmer
---
--- The deck is a card deck kept inside a control. It reads as depth without any
--- 3D at all, out of scale, overlap and dimming — the same three things that
--- make the window deck work. A tilt is available and off by default, because
--- it stops being tasteful quickly.
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

	--- A strip is one window wide per item, so a pane is exactly a window and a
	--- step is one whole unit of the window's scale. A deck has no rail at all:
	--- every pane is placed by hand over the middle of the window.
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

	--- Light on the two ends the strip can still travel toward, clipped by the
	--- window so it reads as the edge of the strip rather than a border.
	local Lights = Scroll.Edges(Window_, { Depth = 34, ZIndex = 4 })

	--- One arrow either side, inside the window, over the strip. Hidden at the
	--- ends rather than left dead, so the control never offers a move it will
	--- not make.
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

			--- Leans the way it would move the strip.
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

		--- Its own scale, so a pane can be pushed back without its contents
		--- reflowing at a different size.
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
			--- Every pane placed against the one in focus: pushed aside, scaled
			--- back and dimmed by how far from it it is.
			--- Wide enough apart that the one in focus is clear of its
			--- neighbours, close enough that they still overlap behind it.
			--- At a spread of 0.56 the focused pane spans 0.22 to 0.78, and a
			--- neighbour at 0.42 away starts at 0.64 — so it tucks under the
			--- focused pane's edge rather than across its middle.
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
			--- The rail is #Items windows wide and each pane is one window
			--- wide, so one step is one whole unit of the window's scale.
			--- Dividing by the count moved it by a fraction of a pane and never
			--- reached the next image.
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

			--- The mark for the pane you are on is wider, not only brighter.
			Tween(Dot, { Size = UDim2.new(0, Index == At and 12 or 5, 0, 5) }, "morph")
		end

		--- Both the arrows and the edge light say the same thing: how much
		--- there is left in each direction. A deck shows its neighbours already,
		--- so it does not need the light as well.
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

	--- One pane either way, stopping at the ends: what the arrows do. Next and
	--- Previous wrap, because that is what an auto playing carousel needs.
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

--- SplitButton. A main action, and a caret that opens the rest.
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

	--- The name of an item, however it was written: a string, or a table with
	--- a Label, or something with a name of its own.
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

	--- What the button does right now: the chosen item's own callback if it
	--- brought one, otherwise the control's, told which item it is running.
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

	--- Choosing from the menu changes the button itself — that is the whole
	--- point of a split button, and it used to do neither that nor run the
	--- thing that was chosen. Running on choice can be turned off; the label
	--- still changes, because otherwise the button is lying about what it does.
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
			--- Built on first use: a split button whose menu is never opened
			--- should not have paid for one. Every entry is wrapped so that
			--- choosing it goes through Select, whether or not the item
			--- brought a callback of its own.
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

			Menu = require(script.Parent.Parent.Layers).Menu({
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

--- Split. Two panes and a divider you can drag, each pane a container.
---
---   local Pane = Page:Split({ Height = 200, At = 0.4 })
---   Pane:Left():Toggle({ Label = "Options" })
---   Pane:Right():Paragraph({ Text = "Detail" })
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

--------------------------------------------------------------------------
-- Empty, Confirm, Sortable
--------------------------------------------------------------------------

--- Empty. The state a list is in before there is anything in it.
---
--- Worth a control of its own because the alternative is a blank space, and a
--- blank space is indistinguishable from something that failed to load. A mark,
--- a line saying what would be here, and optionally the thing that would put
--- something here.
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

	--- A small square turned on its corner: the library's own "nothing".
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

--- Confirm. A button that will not do it until you say so twice.
---
--- The alternative to a modal for anything destructive but small. The first
--- press arms it and it says what it is about to do; a second press inside a
--- few seconds does it, and it disarms itself if you walk away.
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

	--- The window you have to act inside, drawn as a line that runs out.
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

		--- Full, then run out over the window: the bar IS the countdown.
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

--- Sortable. A list whose rows you can drag into a different order.
---
--- Reordering is one of the few things a list can do that genuinely needs the
--- pointer. The row you are holding follows it; everything else springs out of
--- the way, so the order you are going to get is the order you can see.
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

	--- Where a row belongs, in pixels from the top.
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

		--- The grip: three short bars, which is what a thing you can pick up
		--- looks like everywhere.
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

	--- Dragging. The held row follows the pointer and the list closes around it
	--- as it passes, so what you see is what you will get when you let go.
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

		--- Which slot the held row is over now, and move it there in the list
		--- so everything else can spring aside.
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
