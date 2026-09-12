--!nonstrict
--- Layers.luau — the things that draw over everything else.

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")

local Palette = require(script.Parent.Theme)
local Shared  = require(script.Parent.Shared)
local Util    = require(script.Parent.Util)
local Motion  = require(script.Parent.Motion)
local Screen  = require(script.Parent.Screen)
local Reveal  = require(script.Parent.Reveal)

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

--- Required late: Parts pulls in Screen and Util, and Layers is required from
--- places that Parts itself reaches. Asking for it on first use rather than at
--- the top keeps the graph a tree.
local function Bits()
	if not Parts then
		Parts = require(script.Parent.Parts)
	end

	return Parts
end

local Layers = {}

--- How an overlay is dressed.
---
--- Every overlay in here used to be one look: a dark plate, rounded, stroked.
--- That is the "Card" a game usually wants over its world, but it is not the
--- house style — Kuik's own is two hairlines down the sides and nothing in
--- between. Both are here now, and either can be the default for the whole
--- library through Metrics.OverlayVariant.
---
---   Variant = "Card"   a dark plate, rounded and stroked   (the default)
---   Variant = "Rules"  two hairlines, almost no fill
---   Variant = "Bare"   nothing at all
---
--- Inner is the frame whose height the rules should match — the content, not
--- the shell, because the shell's height is what the content decides.
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

--- Attach is written into Shared by Layout, which loads after this module, so
--- it is read at call time rather than captured here.
local function Attach(Object)
	return Shared.Attach(Object)
end

--- Menu. A context list, shown at a point.
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

		--- Flip rather than run off the edge.
		if Viewport.X > 0 and X + Width > Viewport.X - 8 then
			Left -= Width
		end

		if Viewport.Y > 0 and Y + Height > Viewport.Y - 8 then
			Top -= Height
		end

		Menu.Position = UDim2.fromOffset(Left, Top)
		Menu.Visible = true
		Inner.GroupTransparency = 1

		--- A menu can arrive as a white plate that becomes it, rather than by
		--- unrolling. The rectangle is handed over rather than measured,
		--- because the menu has only just been positioned and Roblox has not
		--- laid it out yet.
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

	--- Shows at the pointer, which is what a right click menu always wants.
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

	--- Processed is not checked here either: see the dropdown. A menu shown at
	--- the pointer is armed a moment later so the click that opened it does
	--- not immediately close it again.
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

--- Prompt. A modal question.
---
--- Modal here means genuinely modal: the count in Screen is raised for as long
--- as it is up, and a full screen button swallows everything behind it, so no
--- scroller, keybind or row underneath can be reached.
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

	--- A prompt is the house style by default — two hairlines and nothing in
	--- between — but it can be a dark card like the other overlays.
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

	--- The rules are as tall as the column, in pixels.
	---
	--- Sized 1 scale tall against a group that sizes itself to its children is
	--- the loop this library keeps rediscovering, so the height is driven from
	--- the column instead. Driven rather than Spanned, because these two also
	--- have to draw themselves in when the prompt opens, and Span would own the
	--- property the animation needs.
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

		--- A spring retargets, so a column that grows while the rules are still
		--- drawing in bends them toward the new height rather than restarting.
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

	--- Anything extra the caller wants inside the prompt, above the buttons.
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

		--- Released immediately, not after the close animation: the world must
		--- be usable the instant the answer is given.
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

		--- The pill IS the button. A full size hit area inside a pill that
		--- sizes itself to its own label is the oldest loop in this library:
		--- the button asks the pill how wide it is, and the pill is asking the
		--- label the same question.
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

	--- The slot, exposed so a prompt can hold a field or a list.
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

	--- A prompt can arrive as a white plate too. Deferred, because it has only
	--- just been built and has no size yet.
	if Options.Reveal then
		task.defer(function()
			local Arrived = Group.Parent and Reveal.Plate(Group, {
				Parent = Group.Parent,
				Now    = true,
				To     = 0,
				From   = Options.From,
				Radius = Util.Radius(Options, Metrics.CardRadius),
			})

			--- A plate refuses anything it cannot measure. Falling back is not
			--- optional: without it the prompt never appears at all.
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

--- Cards. A horizontal deck of windows: one focused in the middle, the rest
--- shrunk and dimmed either side, with chevrons and a counter.
function Layers.Cards(Options)
	Options = Options or {}

	local Deck = {}
	local Windows = {}
	local Focus = 1

	--- How far forward the deck may be moved. A wizard raises this as each
	--- step is satisfied; left alone it is every card, which is a plain
	--- carousel.
	local Reach = math.huge

	--- Set once the deck has been torn down. Destroying a card calls back into
	--- the deck, and there is nothing left for those calls to arrange.
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

			--- Leans toward the card it would bring in.
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

	--- Fresh is the index of a card that has only just been added: it is
	--- placed rather than animated, so building a five card deck up front does
	--- not read as the deck sliding backwards through every card.
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

			--- A high ceiling rather than a small stack, so a deck of twenty
			--- still layers correctly against everything else on screen.
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

			--- Sub windows hang outside their parent's bounds, so they have to
			--- be hidden on the cards either side or they overlap the focus.
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

	--- The wash over a card that is not the one being read. It greys the card
	--- down rather than only fading it, so the focus is unmistakable, and it is
	--- the same object that stops a shrunk card being clicked through — so a
	--- card is exactly as interactive as it looks.
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

		--- Hidden only once it has finished clearing, or the wash would vanish
		--- on the frame the card takes focus.
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

		--- The deck shows a card by forcing Root.Visible, but only Open fades
		--- the group in and draws the side rules. A card added closed would
		--- otherwise be a blank rectangle when you scrolled to it.
		---
		--- A card opens the way any other window does — under a white plate —
		--- because a deck of cards that fades in while a window next to it
		--- arrives properly reads as two different libraries.
		---
		--- Staggered, though. Five plates going off on the same frame is
		--- confetti; a beat between them reads as a hand dealing.
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

		--- Clicking a card either side of the focus brings it to the middle,
		--- rather than letting you interact with a shrunk card.
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

		--- Looked up rather than captured: removing a card ahead of this one
		--- would otherwise leave the guard pointing at the wrong index.
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

		--- Sizes are zero until Roblox has laid the card out, and the deck's
		--- spacing is computed from them. Without this second pass the whole
		--- deck sits wrong until something else moves it.
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

	--- Drops a card without destroying its window.
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

	--- Gates the deck at a card. Everything past it is unreachable by chevron,
	--- by key and by clicking a card, which is what makes a deck a wizard.
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

	--- A resize changes every card's width, and the offsets are computed from
	--- it, so the deck has to be laid out again.
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

	--- Destroys the deck and, unless told to keep them, the windows in it.
	--- Windows are idempotent about being destroyed, so a caller that has
	--- already torn its own cards down is fine.
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

		--- Taken as a copy, and the real list emptied first. Destroying a card
		--- fires its own OnDestroy, which calls Forget, which removes it from
		--- this very list — and removing entries from a list while walking it
		--- skips the ones that shuffle down. That is how closing a deck used to
		--- leave two cards behind on screen.
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

--------------------------------------------------------------------------
-- Anchored and edge panels
--------------------------------------------------------------------------

--- The shared body of Popover, Sheet and Drawer: a panel on the screen that is
--- a container in its own right.
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

	--- One dresser for the popover, the sheet and the drawer, so all three
	--- follow the same Variant.
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

--- Popover. A panel anchored to something else on screen.
---
--- Flips to the other side of its anchor rather than running off the edge,
--- which is the entire difference between a popover and a floating frame.
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

		--- Kept on its anchor for as long as it is open: a scroll, a drag or a
		--- window resize all move the thing it points at.
		local Following = nil
		local Arriving = nil

		function Self:Show(NewAnchor)
			Anchor = NewAnchor or Anchor
			Open = true

			Frame.Visible = true
			Inner.GroupTransparency = 1

			--- Placed after a frame, so AutomaticSize has measured the body
			--- and the flip decision is made against a real height.
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

		--- Clicking anywhere outside closes it.
		---
		--- Processed is deliberately not checked: a click on any part of the
		--- interface is processed, which is exactly the click that ought to
		--- dismiss a popover. The rectangle test is what decides.
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

		--- The click that opened it must not also close it.
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

--- Sheet. A panel that rises from the bottom edge.
function Layers.Sheet(Options)
	Options = Options or {}

	local Height = Options.Height or 260
	local Open = false
	local Backdrop = nil

	return Panel(Util.Merge(Options, { Name = "Sheet", ZIndex = 66 }), function(Self, Frame, Inner)
		Frame.AnchorPoint = Vector2.new(0.5, 0)
		Frame.Position = UDim2.new(0.5, 0, 1, 0)
		Frame.Size = UDim2.new(Options.Width and 0 or 1, Options.Width or -24, 0, Height)

		--- A handle bar at the top, because a sheet reads as something you
		--- could pull even when you cannot.
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

			--- The whole window: the layer ignores the top bar inset, which
			--- leaves a strip of exactly that height uncovered at the bottom.
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

--- Drawer. A panel that slides in from a side edge, and a container for a
--- navigation list or anything else.
function Layers.Drawer(Options)
	Options = Options or {}

	local Width = Options.Width or 240
	local Side = Options.Side or "Left"
	local Open = false
	local Backdrop = nil

	local Hidden = Side == "Right" and UDim2.new(1, Width, 0, 0) or UDim2.new(0, -Width, 0, 0)
	local Shown = Side == "Right" and UDim2.new(1, -Width, 0, 0) or UDim2.new(0, 0, 0, 0)

	return Panel(Util.Merge(Options, { Name = "Drawer", ZIndex = 64 }), function(Self, Frame, Inner)
		--- Down to the bottom of the screen, not the bottom of the layer: the
		--- layer starts one inset above what the player can see, so a drawer
		--- sized 1 scale tall stops one inset short of the bottom edge.
		local Top = Screen.Inset()

		Frame.Position = UDim2.new(Hidden.X.Scale, Hidden.X.Offset, 0, Top)
		--- One scale of the layer is one inset taller than the screen, and the
		--- drawer already starts one inset down, so the height has to come off
		--- again or the bottom of the list falls off the screen.
		Frame.Size = UDim2.new(0, Width, 1, -Top)

		Hidden = UDim2.new(Hidden.X.Scale, Hidden.X.Offset, 0, Top)
		Shown = UDim2.new(Shown.X.Scale, Shown.X.Offset, 0, Top)

		--- A rule down the inner edge rather than a shadow.
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

			--- The whole window: the layer ignores the top bar inset, which
			--- leaves a strip of exactly that height uncovered at the bottom.
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

		--- Not Toggle: a drawer is a container, and Toggle is a control. Calling
		--- it built a toggle row inside the drawer instead of opening it.
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

--- Coach. A guided tour: a ring around each target in turn, and a card beside
--- it saying what it is.
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

	--- A ring rather than a cut out: Roblox has no mask, and four frames
	--- around the target would fight every layout change.
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
			--- No target: centre the card and drop the ring.
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

		--- The card goes below the target, or above it when there is no room.
		local Viewport = Screen.Get().AbsoluteSize
		local Below = Point.Y + Size.Y + 14
		local Above = Viewport.Y > 0 and Below + Card.AbsoluteSize.Y > Viewport.Y - 14

		--- Clamped on both axes: a target near an edge used to push the card
		--- off the screen entirely.
		local Height = math.max(Card.AbsoluteSize.Y, 90)
		local Wanted = Above and (Point.Y - Height - 14) or Below

		--- Clamped against what the player can SEE, not against the layer. The
		--- layer starts one inset above the screen, so clamping to 12 from its
		--- top put the card 46 pixels above the top edge.
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

		--- Deferred so anything the step opened has been laid out before the
		--- ring is measured against it.
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
