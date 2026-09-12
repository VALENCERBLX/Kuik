--!nonstrict
--- Window.luau — the panel everything lives in.
---
--- A window is deliberately not just a dialog. Strip the chrome, turn off the
--- backdrop and the scroller, park it in a corner, and the same object is a
--- health bar or an ammo counter. Everything that used to be assumed — that it
--- is centred, that it dims the world, that it scrolls — is an option.

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")

local Palette = require(script.Parent.Theme)
local Util    = require(script.Parent.Util)
local Motion  = require(script.Parent.Motion)
local Parts   = require(script.Parent.Parts)
local Scroll  = require(script.Parent.Scroll)
local Screen  = require(script.Parent.Screen)
local Reveal  = require(script.Parent.Reveal)
local Layout  = require(script.Parent.Layout)
local Shared  = require(script.Parent.Shared)

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

--- Where a window parks. Each entry is an anchor point and the position that
--- goes with it, so docking is one lookup rather than nine branches.
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

	--- Chrome is the frame: the side rules, the header, the inner padding.
	--- A HUD panel has none of it.
	local Variant = Options.Variant or (Options.Chrome == false and "Bare") or "Rules"
	local Bare = Variant == "Bare" or Variant == "Panel"
	local Scrolls = Options.Scroll ~= false and not Bare or Options.Scroll == true
	local Wash = Options.Wash == nil and (Bare and 1 or 0.55) or Options.Wash
	local BlurSize = Options.Blur == nil and (Bare and 0 or 22) or Options.Blur
	local Padded = Options.Padding == nil and (Bare and 0 or Metrics.WindowPadding - 14) or Options.Padding

	local Dock = DOCKS[Options.Dock or "Center"] or DOCKS.Center
	local Anchor = Options.AnchorPoint or Dock[1]

	--- The resting position, before parallax or a drag moves it. Everything
	--- that repositions the window goes through here so the two never fight.
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

	--- The whole window. The layer ignores the top bar inset, which leaves a
	--- strip of exactly that height uncovered along the bottom unless a full
	--- bleed thing is made a bar taller than it looks.
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

	--- A CanvasGroup so the whole panel can fade as one. It rasterises to its
	--- own bounds, so anything that has to escape the window — a dropdown
	--- menu, a child card — is parented to Root or the overlay, never here.
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

	--- A window is mostly transparent frames, and a plain Frame does not take
	--- input — so a click on the empty part of one used to sail straight
	--- through to whatever window was underneath, and so did hover. This is a
	--- button filling the panel, below everything else in it, whose only job is
	--- to swallow what lands on this window. Windows stop leaking into each
	--- other, and a covered control stops answering the pointer.
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

	--- A title bar: a rule, a name, and the three controls a desktop window
	--- has. Off by default, because most of what this library draws is not a
	--- desktop window.
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

		--- Each control is a glyph drawn from rules, in the house style: a
		--- bar, a box, a cross.
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

	--- The header is auto sized, so the body's top has to follow it rather
	--- than being a constant.
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

		--- StatusLabel, not Status: Status is a control, and Attach refuses to
		--- shadow a field with one.
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

	--- The header is auto sized and the bars are not, so the body's top and
	--- bottom both have to follow rather than being constants.
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

	--- Modal only unlocks the cursor; it never blocks input. A HUD panel wants
	--- neither, which is why it defaults off for bare windows.
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

	--- Popovers land here: a plain frame on top of the group, outside its
	--- rasterisation, so a dropdown can hang past the window's edge.
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
	--- Canvas, not Group: Group is a control, and the registry mixed into
	--- every container would overwrite a field of that name.
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

		--- A window always opens at the top of its content, whatever was built
		--- into it or scrolled to last time.
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

		--- A window can arrive as a white plate that becomes it, rather than by
		--- fading up. The plate is measured against Root, so it is exactly the
		--- window's rectangle however the window is sized.
		---
		--- On by default for anything that is a panel, off for anything that is
		--- not: a HUD element stripped of its chrome should open without
		--- ceremony, and flashing white every time a health bar appears would be
		--- ridiculous. Reveal = false turns it off anywhere.
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

				--- A plate refuses anything it cannot measure. Without the
				--- fallback the window would simply never appear.
				Plated = Opening ~= nil and Opening.Face ~= nil

				if not Plated then
					Tween(Group, { GroupTransparency = 0 }, "enter")
				end
			end

			if Root.AbsoluteSize.X > 2 then
				Try()
			else
				--- Built and opened in the same breath, which is what
				--- Open = true does and what a deck of cards does. Nothing has
				--- been laid out yet, so wait a frame for a size rather than
				--- giving up on the reveal entirely.
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

		--- A window that arrived as a plate leaves under one: the same white
		--- comes back over it and shuts. Anything that opened by fading up
		--- fades back down, so the two halves always match.
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

	--- No Window:Toggle: Toggle is a control, and the registry mixed into
	--- every container owns that name. SetOpen is the verb.
	Window.Show = Window.Open
	Window.Hide = Window.Close

	--- Position, size and anchor, all live and all animated by default. This
	--- is what makes a window usable as a HUD element rather than a dialog.
	--- Never above the top of the screen.
	---
	--- The layer ignores the top bar inset, so it starts one inset ABOVE what
	--- the player can see — and a window placed at "24 from the top" therefore
	--- lands at -34 and loses its title bar off the edge. That is what made a
	--- window with chrome open looking like an empty rectangle.
	---
	--- Only the top is guarded, and only for a window anchored near it: a HUD
	--- element deliberately hung off the bottom or bled off an edge is doing
	--- that on purpose.
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
			--- A spring already running on this property would keep writing to
			--- it every frame and quietly undo the assignment. Setting a value
			--- outright has to stop whatever was moving it.
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

	--- Parks the window against an edge or a corner, optionally inset.
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

	--- Nudges the window by a pixel offset from wherever it is.
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

	--- Raises the window above its siblings, for a stack of loose panels.
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

	--- Collapsed to its title bar, and back. Remembers the size it had, so
	--- restoring lands where it started rather than at the default.
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

	--- The line along the bottom, when there is one.
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

	--- Dragging. By the header when there is one, by the whole panel when
	--- there is not, which is what a loose HUD element wants.
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

			--- Sprung rather than assigned, so the panel has weight instead of
			--- sticking to the cursor.
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

	--- A grip in the bottom right corner. Two rules, because that is what
	--- everything else in the library is made of.
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

	--- Parallax: the panel lags behind the camera and settles back.
	---
	--- The offset is sprung to rather than assigned, so a fast flick reads as
	--- the window being dragged along rather than teleporting.
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

				--- Wrap the short way, or spinning past due south throws the
				--- panel across the screen.
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

	--- Selects the named page on whichever tab bar owns it.
	function Window:GoTo(Name)
		for _, Bar in Window.TabBars do
			if Bar:Pages()[Name] then
				Bar:Select(Name)
				return true
			end
		end

		return false
	end

	--- Scrolls something into view and flashes it, so a link that points at a
	--- setting three pages down actually lands you on it.
	function Window:Reveal(Target)
		local Frame = typeof(Target) == "Instance" and Target
			or (type(Target) == "table" and Target.Frame)

		if not Frame then
			return false
		end

		--- Walk up to whichever page holds it and select that first.
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

			--- A double pulse of the row fill: enough to find it, not enough
			--- to be a strobe.
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

	--- A sub window, parked beside this one. Parented to Root rather than the
	--- group, because the group rasterises to its own bounds and would clip it.
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

		--- Detach on destroy, or a window that outlives several editors ends
		--- up iterating a list of dead ones.
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

	--- Idempotent: destroying a window twice, or destroying a deck that holds
	--- windows the caller has already destroyed, must not throw.
	local Leaving = false

	--- Destroy is immediate. Pass true and the window shrinks and fades out
	--- first, then tears itself down — explicit, because a window that is still
	--- on screen after the code that closed it has moved on is a bug every
	--- other time.
	function Window:Destroy(Animate)
		if Destroyed then
			return
		end

		if Animate then
			--- Still alive while it leaves — the teardown below is what makes
			--- it dead — but flagged, so a second call during the animation
			--- does not start a second one.
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

	--- Keeps a window inside the viewport. Off for anything docked or bare,
	--- since a HUD element sized to its content should be left alone.
	if Options.Fit ~= false and not Bare then
		local function Fit()
			local Viewport = Screen.Get().AbsoluteSize

			if Viewport.X > 0 then
				Root.Size = UDim2.new(
					0, math.min(Width, Viewport.X - 40),
					0, math.min(Height, Viewport.Y - 80))
			end

			--- And put it back where it belongs, which is what applies the top
			--- guard. The initial position is written straight onto Root when
			--- the window is built, before there is a size to guard against —
			--- so without this a window docked to the top keeps the placement
			--- that hid its own title bar above the screen.
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
			--- A prompt owns the keyboard while it is up.
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
