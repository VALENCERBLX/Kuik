--!nonstrict
--- Content.luau — buttons, type, and the containers that hold other things.

local GuiService = game:GetService("GuiService")

local Palette = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local Motion  = require(script.Parent.Parent.Motion)
local Parts   = require(script.Parent.Parent.Parts)
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

--- The look of a button, independent of where it sits. Returns the frame, its
--- label, and a function that paints the resting, hover and pressed states.
---
---   Pill     a solid lozenge, the default
---   Solid    the same but in the caller's colour
---   Outline  a stroke and nothing else
---   Ghost    fill only on hover
---   Text     an underlined word
---   Rule     a bracket: a vertical rule either side of the label
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

	--- Resting, hover and pressed transparencies per variant, so the paint
	--- function below is one table lookup rather than a chain of branches.
	local Levels = {
		Pill    = { 0, 0.18, 0.42 },
		Solid   = { 0.12, 0, 0.35 },
		Outline = { 1, 0.9, 0.82 },
		Ghost   = { 1, 0.92, 0.86 },
		Text    = { 1, 1, 1 },
		Rule    = { 1, 0.94, 0.88 },
	}

	local Level = Levels[Variant] or Levels.Pill

	--- Only the filled variants put dark type on light ground.
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

--- Button. A row with an action on the right, or — with Full — an action bar
--- spanning the whole row.
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

--- Rule. A full width bracketed action, with no label column at all — the bar
--- you put at the bottom of a card to commit.
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

--- Divider. A hairline, optionally labelled, and optionally something you can
--- click — which is the cheapest rule button there is.
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

		--- Flex fills whatever is left, so the right hand rule always runs to
		--- the edge whatever the label is.
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

--- Empty space, so a caller can push things apart without a spacer widget of
--- their own.
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

--- Paragraph. Body copy, with an optional heading and an optional image under
--- it. The image plate is fully configurable, including having none at all.
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

	--- Only built when there is copy: an image only paragraph should not carry
	--- an empty label's worth of gap.
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

	--- Repainting the plate after the fact, since "does this embed have a dark
	--- background" is exactly the kind of thing a settings screen toggles.
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

--- A pull quote: an indented rule with type beside it.
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

--- A monospaced block with line numbers down the side.
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

--- Alert. A coloured notice with an accent down its left edge.
---
--- The accent is a hand positioned child of the frame, never a member of the
--- list layout, because a full height accent inside a layout feeds its own
--- height back into the parent and stretches down the page.
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

	--- Declared before the column so the accent can be measured against it
	--- once the column exists: a rule measured against the frame it is inside
	--- would grow that frame, which is what used to stretch an alert down the
	--- whole page.
	local Accented = nil

	if Variant ~= "Subtle" and Variant ~= "Outline" then
		--- Driven rather than scaled: a full height accent inside a frame that
		--- sizes itself on Y feeds its own height back and stretches the alert
		--- down the page.
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

	--- Flashes the alert, for the case where it is already on screen and the
	--- same problem has just happened again.
	function Handle:Pulse()
		local Rest = Frame.BackgroundTransparency

		Frame.BackgroundTransparency = math.max(0, Rest - 0.2)
		Tween(Frame, { BackgroundTransparency = Rest }, "fade")

		return Handle
	end

	return Common(Handle, Frame, Options, { Label = Title, Description = Body })
end

--- Callout is an Alert with no title, for one line of guidance.
function Controls.Callout(Container, Options)
	return Controls.Alert(Container, Util.Merge(Options, {
		Label = Options.Label or Options.Text,
		Text = Options.Label and Options.Text or nil,
		Variant = Options.Variant or "Subtle",
	}))
end

--- Accordion. A header that expands a body underneath it, and a container in
--- its own right: everything you can put in a window, you can put in here.
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

	--- The header is the button, for the same reason a row is: a full size
	--- cover inside a frame that sizes itself on Y measures against itself.
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

	--- Shell is the animated height; Body is what is actually in it. Measuring
	--- Body while Shell is clipped is what makes the open animation possible.
	local Shell = New("Frame", {
		Name                   = "Shell",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		ClipsDescendants       = true,
		LayoutOrder            = 2,
	})

	--- A Frame for the same reason a page is: a CanvasGroup holding a tall
	--- accordion body is rasterised to a texture and blurs. The height
	--- animation on Shell is what the open reads as anyway.
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

			--- Nothing measured yet: snap open and let AutomaticSize take it
			--- from there, rather than animating to zero.
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

--- Breadcrumb. A clickable path.
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

--- Steps. A numbered progress rail, for a flow that runs across several cards.
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

--- Avatar. A portrait, a name and a line under it.
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

--- Link. Goes somewhere — and "somewhere" is deliberately broad.
---
---   Target = "Audio"       the page of that name, selected
---   Target = SomeWindow    opened
---   Target = SomeControl   revealed: its page selected, scrolled to, flashed
---   Target = function()    called
---   Url    = "https://..." offered through Roblox's own browser prompt
function Controls.Link(Container, Options, Owner)
	local Handle = {}
	local Target = Options.Target
	local Url = Options.Url
	local Accent = Colour(Options, Theme.Info)

	local Built = Row(Container, Util.Merge(Options, { Reserve = 84 }))
	Built:Reserve(84)

	--- The label carries the link styling, so it reads as one before you get
	--- anywhere near the button.
	Built.Label.Text = string.format('<font color="%s"><u>%s</u></font>',
		Hex(Accent), Options.Label or Url or "Link")

	--- What kind of thing this points at, said plainly under the label.
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

	--- The row is the button.
	local Button = Built.Frame

	Button.MouseEnter:Connect(function()
		Tween(Pill, { BackgroundTransparency = 0.66 }, "hover")
	end)

	Button.MouseLeave:Connect(function()
		Tween(Pill, { BackgroundTransparency = 0.82 }, "hover")
	end)

	local function Follow()
		local Window = Owner and Owner._Window and Owner:_Window()

		--- A function is an event: it decides for itself.
		if type(Target) == "function" then
			task.spawn(Target)
			return "action"
		end

		--- A string names a page.
		if type(Target) == "string" then
			if Window and Window:GoTo(Target) then
				return "page"
			end

			return "missing"
		end

		if type(Target) == "table" then
			--- A window opens.
			if Target.Root and Target.Open then
				Target:Open()
				return "window"
			end

			--- Anything else with a Frame gets revealed in place.
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

--- Toolbar. A strip of small actions, for the top of a card.
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

--- Header. A title and a rule, for breaking a long page up without the weight
--- of a whole section.
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

--- Group. A container in its own right: everything you can put in a window
--- you can put in here, and Clear wipes it without touching what surrounds it.
---
--- Useful for a block of a form you rebuild from live data, and for scoping a
--- variant or a colour to a run of controls rather than setting it on each.
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

--- Columns. Side by side containers, each one a container in its own right.
---
---   local Split = Page:Columns({ Count = 2 })
---   Split:Column(1):Toggle({ Label = "Left" })
---   Split:Column(2):Toggle({ Label = "Right" })
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
		--- Top aligned, so two columns of different length line up at the top
		--- rather than floating against each other.
		New("UIListLayout", {
			Padding           = UDim.new(0, Gap),
			FillDirection     = Enum.FillDirection.Horizontal,
			SortOrder         = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
	})

	local Columns = {}

	--- Weights let a caller make one column wider: { 2, 1 } is two thirds and
	--- one third, rather than an even split.
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
