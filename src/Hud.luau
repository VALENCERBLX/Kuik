--!nonstrict
--- Hud.luau — the pieces that live on the screen rather than in a window.

local Palette = require(script.Parent.Theme)
local Util    = require(script.Parent.Util)
local Motion  = require(script.Parent.Motion)
local Screen  = require(script.Parent.Screen)
local Reveal  = require(script.Parent.Reveal)
local Parts   = require(script.Parent.Parts)

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

--- One column for every toast, so a second one sits under the first rather
--- than exactly on top of it. Rebuilt on demand, because Kuik.Reset throws the
--- whole layer away.
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
		--- Below where a compass sits, because both of them want the top middle
		--- and a toast landing on the heading strip is nobody's intent.
		Position               = UDim2.new(0.5, 0, 0, Screen.Safe(0) + (Y or 52)),
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 5,
	}, {
		List(8, nil, Enum.HorizontalAlignment.Center),
	})

	return Column
end

--- Toast. A line of type between two rules, at the top of the screen.
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

	--- Only when it is on its own: inside the column the layout centres it, and
	--- an anchor point would shift it half its own width out of its slot.
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

--- Notify. A card that slides down from the top edge.
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

--- Hints. The rail of "press this to do that" prompts.
---
--- Not only keybinds. A hint is a badge and a line of text, and the badge can
--- be a key, a chord of keys, a mouse button, an icon, or nothing at all — a
--- hint with no badge is just a line telling you something, which is what half
--- of them are in practice.
---
---   Hints:Add("E", "interact")
---   Hints:Add({ Keys = { "Ctrl", "S" }, Action = "save" })
---   Hints:Add({ Mouse = "Left", Action = "fire" })
---   Hints:Add({ Icon = Id, Action = "equip" })
---   Hints:Add({ Hold = "E", Action = "pick up" })      -- fills as you hold
---   Hints:Add({ Action = "the door is locked" })       -- no badge
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

	--- The badge on the left of a hint. Whatever it is, it ends up the same
	--- height, so a rail of mixed badges still lines up.
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
			--- A mouse is a rounded body with the pressed button filled in.
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

		--- A chord is several caps with a thin plus between them.
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

	--- Add takes either a key and an action, or a table describing the hint.
	function Hints:Add(First, Second)
		local Spec = type(First) == "table" and First or { Key = First, Action = Second }

		Order += 1

		--- Two frames, not one. The row lays the badge and the label out; the
		--- hint around it holds anything that has to sit under or behind them,
		--- because a hairline dropped into the row becomes another badge in it.
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

		--- A hold hint fills a hairline under itself as the key is held, which
		--- is the one piece of state a hint ever has.
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

			--- Measured against the row, which is the sibling that sets the
			--- hint's width. Measuring against the hint itself would be asking
			--- a question its own answer decides, and Span refuses it.
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

			--- A badge can change shape entirely, so it is rebuilt rather than
			--- edited: a key can become a mouse button.
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

	--- Replaces the whole rail in one call, which is what a context change
	--- wants: walk up to a door and the rail becomes the door's hints.
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

--- Log. A bracketed column of lines, bottom left.
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

	--- Measured against the stack, not against the holder: the holder's height
	--- comes from the stack, so a rule that asked the holder would be asking a
	--- question its own answer decides.
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

--- Feed. A centred column of one line notices that stack upward and expire.
---
--- Also taken from a screenshot: a glyph, then a line of type, the pair centred
--- as a group rather than aligned to a margin, and a hairline running out from
--- behind the newest line and fading at both ends. Nothing has a background.
---
--- Where Toast is one message at a time and Killfeed is a fixed corner, this is
--- the middle of the screen: earnings, pickups, "you did the thing" — the sort
--- of notice that arrives three at once and has to stay readable.
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

	--- Newest at the bottom, so the column grows upward off its own anchor and
	--- the line you just earned is always in the same place.
	function Feed:Push(Message, Extra)
		Extra = Extra or {}
		Order += 1

		local Tall = Options.Height or 22

		--- The row does not size itself. Its contents do, and the row follows
		--- them — because the hairline below has to be able to run PAST the
		--- text, and a decoration that is a layout item pushes the layout out
		--- instead. That is a real bug this had: every notice grew by the width
		--- of its own hairline.
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

		--- The hairline sits behind the line and runs past it at both ends,
		--- fading out. It belongs to the newest notice only, which is what
		--- makes the newest one read as the one that just happened.
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

		--- The row is exactly as wide as its contents, measured rather than
		--- inherited, so the hairline can overrun without moving anything.
		local function Fit()
			Row.Size = UDim2.new(0, Line.AbsoluteSize.X, 0, Tall)
		end

		table.insert(Widths, Line:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit))
		task.defer(Fit)

		table.insert(Entries, Row)

		--- Only the newest wears the wire, and it draws itself out from nothing
		--- rather than appearing at length.
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

		--- Every notice under the holder, not only the tracked ones: a row that
		--- has already expired is on its way out but still on screen, and
		--- clearing has to mean clearing.
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

--- Arrival. The screen a loading transition puts up, in the house style.
---
--- Measured off the reference at 1920 x 1080: a bracketed status chip at 9%
--- down, the title dead centre at 50%, a subtitle 35 px under it, fine print
--- along the bottom, and nothing else. Everything is centred and everything is
--- type — no panel, no fill, no border.
---
--- The entrance is the reason it exists. The screen goes black in a single
--- frame, and a white bar over the status chip's position closes to nothing, so
--- the chip is uncovered rather than faded up. That is the same handover the
--- plate makes, played the other way round.
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

	--- The whole window, top bar included: a loading screen with a strip of the
	--- game showing along the bottom edge is not a loading screen.
	Screen.Cover(Sheet)

	--- Swallows everything behind it while it is up. A loading screen that can
	--- be clicked through is not a loading screen.
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

	--- The bracketed chip, at 9% down. Two hairlines and a word, which is how
	--- this house writes a status anywhere.
	--- 9.4% down in the reference, which is measured against a screen with no
	--- top bar on it. The sheet ignores the inset so that it really does cover
	--- everything, so the chip has to put the inset back or it lands underneath
	--- the platform's own bar.
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

	--- The text sits in its own frame, and the two rules hang off the chip
	--- outside it. A rule that is a sibling of the label inside a laid out
	--- frame is not a bracket — it is a third item in the row, which is exactly
	--- what happened: both rules ended up side by side in front of the text.
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

	--- Title and subtitle, dead centre.
	--- Anchored by its top, not its middle. In the reference it is the TITLE
	--- that sits on the centre line, with the subtitle and the progress hairline
	--- hanging below it — centring the whole block instead pushes the title up
	--- by however much is under it.
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

	--- A hairline that fills, if there is something to report progress on.
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

	--- Fine print along the bottom.
	local Footer = nil

	if Options.Footer then
		Footer = New("Frame", {
			Name                   = "Footer",
			Parent                 = Sheet,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(0.5, 1),
			Position               = UDim2.new(0.5, 0, 1, -(Options.FooterAt or 26)),
			--- Anchored to the bottom, which the inset does not touch.
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

	--- The handover: a white bar over the chip, closing to nothing. Deferred
	--- because the chip sizes itself and has no width on the frame it is built.
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

	--- Positions are pixels, so they have to be recomputed when the viewport
	--- changes. An arrival screen outlives at least one resize on a phone that
	--- is rotated while it loads.
	local function Fit()
		Chip.Position = UDim2.new(0.5, 0, 0, Screen.Safe(Options.StatusAt or 0.094))

		--- Also measured against what the player can see rather than against the
		--- layer, which starts one inset above it. Lifted by half the title's
		--- own height so it is the TITLE that lands on the centre line rather
		--- than the block hanging under it.
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

	--- Leaves the way it came: the chip is covered again, then the whole sheet
	--- goes. Done runs once it is off screen, which is where a scene change
	--- belongs.
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

--- Console. Levelled lines, top right, each fading on its own timer.
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

--- Watermark. A monospaced strip along the bottom edge.
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

--- Bar. A standalone HUD meter — health, stamina, whatever the game has.
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

	--- A ghost that drains behind the fill, so a hit reads as damage taken
	--- rather than the bar simply being shorter.
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

		--- The ghost lags: fast to catch up when healing, slow when hurt.
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

--- Timer. A dial and a clock between two rules.
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

--- Ammo. A weapon name and a magazine over reserve count, set at an angle.
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

--- Crosshair. Four ticks that spread and snap back.
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

--- Killfeed. Lines that fade themselves out.
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

--- Objective. A labelled block, top left, with an optional progress rule.
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

	--- The content lays itself out; the rule hangs off the holder outside it.
	--- A rule that is a child of the laid out frame becomes another item in the
	--- column, and one sized in scale against a parent that sizes itself to its
	--- children is a loop.
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

--- Vignette. Four gradient edges that darken the frame.
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

	--- The whole window: a vignette whose bottom edge stops an inset short of
	--- the screen draws a visible line across the picture.
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

--- Compass. A scrolling heading strip, driven by the camera.
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
		--- Screen.Safe, not a raw offset: the layer ignores the top bar inset,
		--- so 22 from the layer's top is above the visible screen entirely.
		--- The compass was drawing at y = -36 and nobody could see it.
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

			--- Fade out toward the edges rather than clipping hard.
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

--- Fab. A floating action button, parked in a corner.
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

	--- A cross by default, which is what a FAB almost always means.
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

--- Viewfinder. Four corner brackets and an optional recording tally: the frame
--- a camera draws over the world.
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
