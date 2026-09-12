--!nonstrict
--- Play.luau — the controls a game needs and an application does not.
---
--- Everything else in the library is a settings panel's worth of widget. These
--- five are the ones a round of something wants: who is winning, what you are
--- carrying, what you have, which way you are choosing, and how the two sides
--- compare. Same house style — rules and type, almost no fill.

local Palette = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local Motion  = require(script.Parent.Parent.Motion)
local Parts   = require(script.Parent.Parent.Parts)
local Scroll  = require(script.Parent.Parent.Scroll)
local Screen  = require(script.Parent.Parent.Screen)

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

--------------------------------------------------------------------------
-- Leaderboard
--------------------------------------------------------------------------

--- Leaderboard. Rank, face, name, value — and your own row kept in sight.
---
--- The one thing a leaderboard has to do that a table does not is never lose
--- you. However far down you are, your row is pinned to the bottom of the
--- board with a rule above it, so you can always see where you stand without
--- scrolling for it.
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

	--- One row of the board. Also used for the pinned row at the bottom, which
	--- is why it takes its parent rather than assuming the sheet.
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

	--- Fills a row in. Separate from building one so the same code paints the
	--- pinned row and every row in the board.
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

	--- Your own row, under a rule, always there.
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

		--- Sorted here rather than trusted, because a board that arrives out of
		--- order is a board that renders wrong.
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

--------------------------------------------------------------------------
-- Slots
--------------------------------------------------------------------------

--- Slots. A grid of item cells: what you are carrying.
---
--- Empty cells are drawn, not skipped — an inventory with three things in it
--- and nine spaces is telling you something an inventory with three things is
--- not. A cell carries a rarity edge, a count, and a selected state.
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

		--- Two letters of the name, for an item with no picture. Better than an
		--- empty box, and it keeps the grid legible while art is missing.
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

--------------------------------------------------------------------------
-- Wallet
--------------------------------------------------------------------------

--- Wallet. A currency readout whose number rolls to its new value.
---
--- Rolling rather than swapping is the whole point: money that changes by 250
--- should look like it changed by 250, and a number that simply becomes another
--- number tells you nothing about the size of what just happened.
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

	--- What just changed, flashed beside the total and then gone.
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

		--- Held locally as well as in the upvalue: the handler is what clears
		--- the upvalue, so by the time it runs again there is nothing there to
		--- disconnect through.
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

			--- Close enough to be the number: land on it exactly rather than
			--- creeping the last fraction for another second.
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

--------------------------------------------------------------------------
-- Radial
--------------------------------------------------------------------------

--- Radial. A wheel you pick from by direction rather than by position.
---
--- The one control in here that is not a rectangle. Segments are laid around a
--- centre and the one nearest the pointer's ANGLE is chosen — so picking is a
--- flick in a direction rather than a click on a target, which is why emote and
--- weapon wheels work at speed.
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

	--- The ring the labels sit on, drawn as a stroke rather than an image so it
	--- follows the theme like everything else.
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

	--- A needle from the centre toward whatever is chosen.
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
		--- Straight up is the first item, and they run clockwise, which is what
		--- every wheel anyone has used does.
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

	--- Picking by angle. The pointer's direction from the centre decides, so
	--- the further out you flick the more forgiving it gets.
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

		--- Rounded rather than floored, so the boundary between two items is
		--- half way between them rather than at one of them.
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

	--- Choosing is separate from hovering: the wheel highlights as you move and
	--- commits when you let go, which is what a hold to open wheel needs.
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

--------------------------------------------------------------------------
-- Versus
--------------------------------------------------------------------------

--- Versus. One bar shared by two sides.
---
--- A meter says how full something is. This says who has more of it, which is a
--- different question and wants a different shape: both totals on the outside,
--- the split in the middle, and the bar growing from the centre rather than
--- from an end.
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

	--- The middle, marked, because a bar that grows both ways needs somewhere
	--- to grow from that you can see.
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
