--!nonstrict
--- Parts.luau — the shells every control is built out of.
---
--- Two shapes carry the whole library. A Row is a line with a label on the
--- left and a control on the right; a Block is a card with a heading and a
--- content area underneath. Everything else is one of those two with something
--- different mounted in it.

local GuiService       = game:GetService("GuiService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Palette = require(script.Parent.Theme)
local Util    = require(script.Parent.Util)
local Motion  = require(script.Parent.Motion)
local Screen  = require(script.Parent.Screen)

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
local Enter      = Motion.Enter
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime

local Parts = {}

--- A frame that is laid out, plus a sibling that is not.
---
--- A UIListLayout positions every visible child it has, so anything placed by
--- hand — a sliding accent, a marker — has to live outside it. This pairs the
--- two: Items is laid out, Canvas is where hand placed things go.
local function Layered(Parent, Gap)
	local Canvas = New("Frame", {
		Name                   = "Canvas",
		Parent                 = Parent,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	})

	local Items = New("Frame", {
		Name                   = "Items",
		Parent                 = Canvas,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		List(Gap or 1),
	})

	return Canvas, Items
end

--- The accent that slides between the rows of a list, a dropdown or a tree.
--- Lives on a Layered canvas so the list layout never touches it.
local function SlidingMark(Parent, Options)
	Options = Options or {}

	local Mark = New("Frame", {
		Name                   = "Mark",
		Parent                 = Parent,
		BackgroundColor3       = Options.Color or Theme.White,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, 0, 0, 0),
		Size                   = UDim2.new(0, Options.Width or 1, 0, 0),
		ZIndex                 = 6,
	}, Options.Radius and { Corner(Options.Radius) } or nil)

	local Handle = { Frame = Mark }
	local Placed = false

	function Handle:To(Entry, Container)
		if not Entry then
			Tween(Mark, { BackgroundTransparency = 1 }, "fade")
			Placed = false
			return
		end

		local Offset = Entry.AbsolutePosition.Y - Container.AbsolutePosition.Y

		--- Absolute positions are viewport space; the canvas has been scrolled
		--- out from under them, so add that back to land in canvas space.
		if Container:IsA("ScrollingFrame") then
			Offset += Container.CanvasPosition.Y
		end

		local Position = UDim2.new(0, Options.Inset or 0, 0, Offset)
		local Size = UDim2.new(0, Options.Width or 1, 0, Entry.AbsoluteSize.Y)

		--- The first placement snaps; every one after springs, so the accent
		--- does not fly in from the corner on build.
		if Placed then
			Tween(Mark, { Position = Position, Size = Size }, "morph")
		else
			Mark.Position = Position
			Mark.Size = Size
			Placed = true
		end

		Tween(Mark, { BackgroundTransparency = Options.Transparency or Theme.RuleTransparency }, "fade")
	end

	function Handle:Destroy()
		Mark:Destroy()
	end

	return Handle
end

--- Keeps a child as tall (or as wide) as its parent, in offset rather than
--- scale.
---
--- A scale size in the axis a parent sizes itself on makes the parent measure
--- against its own height: it grows, the child grows, and a row ends up
--- hundreds of pixels tall.
---
--- Measure against a sibling that already sets the parent's height, never
--- against the parent, or this is the same loop written by hand.
local function Span(Child, Against, Vertical, Inset)
	--- The loop this helper exists to avoid is easy to write with the helper
	--- itself, so it refuses it outright.
	if Against == Child.Parent then
		local Mode = Against.AutomaticSize
		local Name = Mode and tostring(Mode) or "None"

		if (Vertical and (Name == "Y" or Name == "XY"))
			or (not Vertical and (Name == "X" or Name == "XY")) then
			error("Kuik: Span cannot measure a child against a parent that "
				.. "sizes itself on the same axis; measure against the sibling "
				.. "that sets the parent's size instead", 2)
		end
	end

	local function Fit()
		local Size = Against.AbsoluteSize

		if Vertical then
			Child.Size = UDim2.new(
				Child.Size.X.Scale, Child.Size.X.Offset,
				0, math.max(0, Size.Y - (Inset or 0)))
		else
			Child.Size = UDim2.new(
				0, math.max(0, Size.X - (Inset or 0)),
				Child.Size.Y.Scale, Child.Size.Y.Offset)
		end
	end

	local Connection = Against:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)

	task.defer(Fit)

	return Connection
end

--- Pointer positions and AbsolutePosition are not always measured from the
--- same corner — the top bar inset can sit between them, and which side of it
--- a number is on depends on the signal it came from and on whether the
--- ScreenGui ignores the inset. Rather than guess, each space learns its own
--- correction from a report that is known to have landed inside something:
--- a press fires on the object it hit, and MouseMoved only fires while the
--- pointer is over one.
local Offsets = {}

local function Learn(Space, Point, Object)
	if Offsets[Space] then
		return
	end

	local Origin = Object.AbsolutePosition
	local Size = Object.AbsoluteSize

	if Size.X <= 0 or Size.Y <= 0 then
		return
	end

	local Gap = GuiService:GetGuiInset()

	local function Inside(Shift)
		local X, Y = Point.X + Shift.X, Point.Y + Shift.Y

		return X >= Origin.X and X <= Origin.X + Size.X
			and Y >= Origin.Y and Y <= Origin.Y + Size.Y
	end

	for _, Candidate in { Vector2.new(0, 0), Gap, Vector2.new(-Gap.X, -Gap.Y) } do
		if Inside(Candidate) then
			Offsets[Space] = Candidate
			return
		end
	end
end

local function Shift(Space)
	return Offsets[Space] or Vector2.new(0, 0)
end

--- Where a point sits inside an object, as a 0..1 pair, corrected for the
--- space it was reported in. Returns nil when the point is outside it.
local function Locate(Space, Point, Object)
	local Origin = Object.AbsolutePosition
	local Size = Object.AbsoluteSize

	if Size.X <= 0 or Size.Y <= 0 then
		return nil
	end

	local Correction = Shift(Space)

	local X = (Point.X + Correction.X - Origin.X) / Size.X
	local Y = (Point.Y + Correction.Y - Origin.Y) / Size.Y

	if X < 0 or X > 1 or Y < 0 or Y > 1 then
		return nil
	end

	return X, Y
end

--- Pointer dragging over a surface, reported as a 0..1 fraction of it. The
--- move and end handlers are global so a drag survives leaving the target.
local function Draggable(Target, Surface, OnMove, OnEnd)
	local Connections = {}
	local Dragging = false

	local function Report(Point)
		local Origin = Surface.AbsolutePosition
		local Size = Surface.AbsoluteSize
		local Correction = Shift("Input")

		OnMove(
			Size.X > 0 and Clamp((Point.X + Correction.X - Origin.X) / Size.X, 0, 1) or 0,
			Size.Y > 0 and Clamp((Point.Y + Correction.Y - Origin.Y) / Size.Y, 0, 1) or 0
		)
	end

	table.insert(Connections, Target.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true

			--- The press fired on this object, so it landed inside it. That is
			--- the one free measurement of the gap we ever get.
			Learn("Input", Input.Position, Target)

			Report(Input.Position)
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch) then
			Report(Input.Position)
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch) then
			Dragging = false

			if OnEnd then
				OnEnd()
			end
		end
	end))

	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end

		table.clear(Connections)
	end
end

--- One tooltip for the whole library, moved and refilled rather than rebuilt.
local Tip = nil
local TipTrack = nil

local function Tooltip(Object, Content)
	local function Ensure()
		if Tip and Tip.Parent then
			return Tip
		end

		Tip = New("Frame", {
			Name                   = "Tooltip",
			Parent                 = Screen.Get(),
			BackgroundColor3       = Theme.Scrim,
			BackgroundTransparency = 0.08,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 1),
			AutomaticSize          = Enum.AutomaticSize.XY,
			Size                   = UDim2.new(0, 0, 0, 0),
			Visible                = false,
			ZIndex                 = 90,
		}, {
			Corner(Metrics.ChipRadius),
			Padding(5, 9),
			Stroke(Theme.White, 0.82, 1),
		})

		Text({
			Parent           = Tip,
			Name             = "Label",
			Text             = "",
			TextSize         = Metrics.ValueSize,
			TextTransparency = Theme.TextSecondary,
			AutomaticSize    = Enum.AutomaticSize.XY,
			Size             = UDim2.new(0, 0, 0, 0),
			ZIndex           = 91,
		})

		return Tip
	end

	local Connections = {}

	table.insert(Connections, Object.MouseEnter:Connect(function()
		local Frame = Ensure()

		Frame.Label.Text = Content
		Frame.Visible = true
		Frame.BackgroundTransparency = 1
		Frame.Label.TextTransparency = 1

		TipTrack = Object

		Tween(Frame, { BackgroundTransparency = 0.08 }, "hint")
		Tween(Frame.Label, { TextTransparency = Theme.TextSecondary }, "hint")

		local Point = Object.AbsolutePosition
		Frame.Position = UDim2.fromOffset(Point.X, Point.Y - 4)
	end))

	table.insert(Connections, Object.MouseLeave:Connect(function()
		if Tip and TipTrack == Object then
			Tip.Visible = false
			TipTrack = nil
		end
	end))

	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
	end
end

--- Everything every handle can do, mixed in once rather than written forty
--- times. Controls add their own Get/Set on top.
local function Common(Handle, Frame, Options, Bits)
	Bits = Bits or {}
	Options = Options or {}

	local Disabled = Options.Disabled == true
	local Cleanup = {}

	Handle.Frame = Frame
	Handle.Options = Options

	function Handle:IsVisible()
		return Frame.Visible
	end

	--- Hiding a row also has to take it out of the layout, which Visible
	--- already does, so this is genuinely just the property — but it belongs
	--- on the handle so callers never reach through to the instance.
	function Handle:SetVisible(Value, Animate)
		if Animate and Value then
			Frame.Visible = true
			Enter(Frame, "BackgroundTransparency", Frame.BackgroundTransparency, "fade")
		else
			Frame.Visible = Value ~= false
		end

		return Handle
	end

	function Handle:IsDisabled()
		return Disabled
	end

	--- Disabled dims the whole row and stops it taking input. Controls that
	--- own extra buttons pass them in Bits.Inputs.
	function Handle:SetDisabled(Value)
		Disabled = Value ~= false

		Tween(Frame, { BackgroundTransparency = Disabled
			and 1
			or (Options.Flat and 1 or Theme.RowTransparency) }, "fade")

		for _, Object in Bits.Inputs or {} do
			Object.Active = not Disabled
			Object.Selectable = not Disabled
			Object.AutoButtonColor = false
		end

		for _, Object in Bits.Dim or {} do
			if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
				Tween(Object, { TextTransparency = Disabled and Theme.TextDisabled or Theme.TextSecondary }, "fade")
			elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
				Tween(Object, { ImageTransparency = Disabled and Theme.TextDisabled or 0 }, "fade")
			end
		end

		return Handle
	end

	if Bits.Label then
		function Handle:SetLabel(NewText)
			SwapText(Bits.Label, NewText)
			return Handle
		end
	end

	if Bits.Description then
		function Handle:SetDescription(NewText)
			SwapText(Bits.Description, NewText)
			return Handle
		end
	end

	local function Teardown()
		for _, Stop in Cleanup do
			Stop()
		end

		table.clear(Cleanup)

		if Bits.Destroy then
			Bits.Destroy()
		end

		Frame:Destroy()
	end

	--- Destroy is immediate, because most of the time something is being torn
	--- down and nobody is watching. Pass true and it shrinks and fades out
	--- first — asked for explicitly, since a control that lingers after the
	--- code that removed it has moved on is a bug in every other case.
	function Handle:Destroy(Animate)
		if not Animate or not Frame.Parent then
			Teardown()
			return
		end

		--- Taken out of the layout the instant it starts leaving, so the rows
		--- underneath close the gap while it goes rather than after.
		Frame.Active = false
		Motion.Out(Frame, Teardown)
	end

	function Handle:OnDestroy(Stop)
		table.insert(Cleanup, Stop)
		return Handle
	end

	if Options.Tooltip then
		table.insert(Cleanup, Tooltip(Frame, Options.Tooltip))
	end

	if Options.Visible == false then
		Frame.Visible = false
	end

	--- Anything built while the interface is already up can arrive rather than
	--- appear. Off by default: a page of forty rows should not each spring in
	--- on their own, which is what Stagger is for.
	if Options.Enter then
		Motion.Pop(Frame, type(Options.Enter) == "string" and Options.Enter or "pop")
		Enter(Frame, "BackgroundTransparency", Frame.BackgroundTransparency, "fade")
	end

	--- Or it can arrive as a white plate that becomes it. The measurement has
	--- to wait for a layout pass, because a control has no size on the frame it
	--- is built.
	if Options.Reveal then
		task.defer(function()
			if Frame.Parent then
				require(script.Parent.Reveal).Plate(Frame, {
					From   = type(Options.Reveal) == "table" and Options.Reveal.From or nil,
					Radius = Util.Radius(Options, Metrics.RowRadius),
				})
			end
		end)
	end

	if Disabled then
		task.defer(function()
			Handle:SetDisabled(true)
		end)
	end

	return Handle
end

--- Surface variants. Every shell resolves through here, so "Outline" means the
--- same thing on a row, a block and an alert.
local function Dress(Frame, Options, Fallback, Against)
	local Variant = Options.Variant or (Options.Flat and "Flat") or Fallback or "Filled"
	local Colour = Options.Color

	if Variant == "Flat" or Variant == "Ghost" then
		Frame.BackgroundTransparency = 1
	elseif Variant == "Outline" then
		Frame.BackgroundTransparency = 1
		Stroke(Colour or Theme.White, 0.7, 1).Parent = Frame
	elseif Variant == "Solid" then
		Frame.BackgroundColor3 = Colour or Theme.White
		Frame.BackgroundTransparency = 0.86
	elseif Variant == "Rule" then
		Frame.BackgroundTransparency = 1

		local Accent = New("Frame", {
			Name             = "Accent",
			Parent           = Frame,
			BackgroundColor3 = Colour or Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel  = 0,
			Size             = UDim2.new(0, 1, Against and 0 or 1, 0),
			ZIndex           = 3,
		})

		if Against then
			Span(Accent, Against, true)
		end
	else
		Frame.BackgroundColor3 = Theme.White
		Frame.BackgroundTransparency = Theme.RowTransparency
	end

	return Variant
end

--- Whether a variant reacts to the pointer at all.
local function Reactive(Variant)
	return Variant ~= "Flat" and Variant ~= "Ghost" and Variant ~= "Outline"
end

--- A line: label and description on the left, a mount on the right.
---
--- The whole thing is AutomaticSize.Y with a minimum, so a long description
--- grows the row rather than spilling out of it — which is what happens as
--- soon as anyone raises RowDescSize.
local function Row(Parent, Options)
	Options = Options or {}

	local HasDescription = Options.Description ~= nil and Options.Description ~= ""
	local Reserve = Options.Reserve or Metrics.ToggleWidth
	local Pad = Options.Padding or Metrics.RowPadding

	--- The row's root is a button, not a frame.
	---
	--- Almost every control wants the whole row to be clickable, and the
	--- obvious way — a full size TextButton on top — cannot work here: the row
	--- is laid out by a UIListLayout, which lays out every visible child it
	--- has, so the cover became a list item as tall as the row it was covering.
	--- Making the root itself the button removes the extra child entirely.
	local Frame = New("TextButton", {
		Name                   = Options.Name or "Row",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RowTransparency,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Util.Radius(Options, Metrics.RowRadius)),
		Padding(10, Pad, 10, Pad),
	})

	--- The minimum keeps short rows the height they have always been, so
	--- nothing in a list of toggles jumps around.
	New("UISizeConstraint", {
		Parent  = Frame,
		MinSize = Vector2.new(0, Options.Height
			or (HasDescription and Metrics.RowHeightTall or Metrics.RowHeight)),
	})

	--- The stack carries the layout; the row carries the decoration. Keeping
	--- them apart is what lets a full height accent exist at all: a child of
	--- the row's own layout would be laid out as a list item, and a child
	--- measured against the row would grow it.
	local Stack = New("Frame", {
		Name                   = "Stack",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		List(Options.Gap or 8),
	})

	local Variant = Dress(Frame, Options, nil, Stack)

	--- The head is a horizontal layout, not a set of anchored children.
	---
	--- Anchoring a child at 0.5 scale inside an AutomaticSize parent, or giving
	--- one a scale height there, makes the parent's measured height depend on
	--- its own height. Roblox resolves that by growing: rows built that way
	--- came out hundreds of pixels tall. A layout has no such loop.
	local MountHeight = Options.MountHeight or 26

	local Head = New("Frame", {
		Name                   = "Head",
		Parent                 = Stack,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = 1,
	}, {
		New("UIListLayout", {
			Padding             = UDim.new(0, 8),
			FillDirection       = Enum.FillDirection.Horizontal,
			SortOrder           = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
		}),
	})

	local Icon = nil

	if Options.Icon then
		Icon = New("ImageLabel", {
			Name                   = "Icon",
			Parent                 = Head,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Options.Icon),
			ImageColor3            = Options.IconColor or Theme.White,
			ImageTransparency      = Theme.TextSecondary,
			Size                   = UDim2.new(0, 16, 0, 16),
			LayoutOrder            = 1,
		})
	end

	local TextColumn = New("Frame", {
		Name                   = "Text",
		Parent                 = Head,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -(Reserve + (Icon and 34 or 8)), 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = 2,
	}, {
		List(2),
	})

	--- A minimum on the column, not on the head: the head is exactly as tall
	--- as the taller of the column and the mount, which is what centres them.
	New("UISizeConstraint", {
		Parent  = TextColumn,
		MinSize = Vector2.new(0, MountHeight),
	})

	local Label = Text({
		Parent           = TextColumn,
		Text             = Options.Label or "",
		TextSize         = Options.LabelSize or Metrics.RowLabelSize,
		TextTransparency = Theme.TextPrimary,
		TextWrapped      = Options.Wrap ~= false,
		LayoutOrder      = 1,
	})

	local Description = nil

	if HasDescription then
		Description = Text({
			Parent           = TextColumn,
			Text             = Options.Description,
			TextSize         = Options.DescriptionSize or Metrics.RowDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end

	--- Fixed height, never scale: the mount is a child of an AutomaticSize
	--- head, and a scale height there is the loop described above.
	local Mount = New("Frame", {
		Name                   = "Mount",
		Parent                 = Head,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, Reserve, 0, MountHeight),
		LayoutOrder            = 3,
		ZIndex                 = 2,
	})

	local Built = {
		Frame       = Frame,
		Stack       = Stack,
		Head        = Head,
		Mount       = Mount,
		Label       = Label,
		Description = Description,
		TextColumn  = TextColumn,
		Icon        = Icon,
		Variant     = Variant,
	}

	--- Widens the mount and narrows the text column to match, which is the
	--- first thing almost every control does.
	function Built:Reserve(Width, Height)
		local Gap = Icon and 34 or 8

		--- Same rule as a Block's aside: in a narrow row the mount takes what
		--- is there rather than what it asked for, so the label keeps a line.
		local function Share()
			local Room = Head.AbsoluteSize.X
			local Taken = Width

			if Room > 0 then
				Taken = math.min(Width, math.max(0, Room * 0.6 - Gap))
			end

			Mount.Size = UDim2.new(0, Taken, 0, Height or MountHeight)
			TextColumn.Size = UDim2.new(1, -(Taken + Gap), 0, 0)
		end

		Built.Share = Share

		--- One connection, however many times a control re-reserves: it always
		--- calls the latest share.
		if not Built.Sharing then
			Built.Sharing = Head:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				Built.Share()
			end)
		end

		Share()

		return Mount
	end

	--- A full width strip under the head, for sliders and anything else that
	--- needs the whole row rather than a corner of it.
	function Built:Foot(Height)
		local Foot = New("Frame", {
			Name                   = "Foot",
			Parent                 = Stack,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, Height or 18),
			LayoutOrder            = 2,
		})

		return Foot
	end

	if Reactive(Variant) and Options.Static ~= true then
		Frame.MouseEnter:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowHoverTransparency }, "hover")
		end)

		Frame.MouseLeave:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowTransparency }, "hover")
		end)

		Enter(Frame, "BackgroundTransparency", Theme.RowTransparency, "fade")
	end

	return Built
end

--- A card: optional heading and description, an aside in the top right, and a
--- content area that grows with whatever is put in it.
local function Block(Parent, Options, Height)
	Options = Options or {}

	local Pad = Options.Padding or Metrics.RowPadding

	local Frame = New("Frame", {
		Name                   = Options.Name or "Block",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RowTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Util.Radius(Options, Metrics.RowRadius)),
		Padding(12, Pad, 12, Pad),
		List(Options.Gap or 8),
	})

	local Variant = Dress(Frame, Options)

	local Head, Aside = nil, nil

	if Options.Label then
		Head = New("Frame", {
			Name                   = "Head",
			Parent                 = Frame,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			LayoutOrder            = 1,
		})

		local Column = New("Frame", {
			Name                   = "Column",
			Parent                 = Head,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, -(Options.AsideWidth or 100), 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
		}, {
			List(2),
		})

		Text({
			Parent      = Column,
			Text        = Options.Label,
			TextSize    = Options.LabelSize or Metrics.RowLabelSize,
			TextWrapped = true,
			LayoutOrder = 1,
		})

		if Options.Description and Options.Description ~= "" then
			Text({
				Parent           = Column,
				Text             = Options.Description,
				TextSize         = Options.DescriptionSize or Metrics.RowDescSize,
				TextTransparency = Theme.TextSecondary,
				TextWrapped      = true,
				LayoutOrder      = 2,
			})
		end

		--- Hand positioned, so it never joins the list layout and never grows
		--- the head.
		Aside = New("Frame", {
			Name                   = "Aside",
			Parent                 = Head,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(1, 0),
			Position               = UDim2.new(1, 0, 0, 1),
			Size                   = UDim2.new(0, (Options.AsideWidth or 100) - 12, 0, 20),
		})

		--- In a narrow container a fixed aside leaves the label a few pixels to
		--- live in, and a wrapped label turns into one letter per line. The
		--- aside gives ground instead: it never takes more than its share of
		--- the room actually available.
		local Wanted = Options.AsideWidth or 100

		local function Share()
			local Room = Head.AbsoluteSize.X
			local Reserve = Wanted

			if Room > 0 then
				Reserve = math.min(Wanted, math.max(0, Room * (Options.AsideShare or 0.45)))
			end

			Column.Size = UDim2.new(1, -Reserve, 0, 0)
			Aside.Size = UDim2.new(0, math.max(0, Reserve - 12), 0, Options.AsideHeight or 20)
		end

		Head:GetPropertyChangedSignal("AbsoluteSize"):Connect(Share)
		Share()
	end

	local Content = New("Frame", {
		Name                   = "Content",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Height or 0),
		AutomaticSize          = Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		LayoutOrder            = 2,
	})

	if Reactive(Variant) and Options.Static ~= true then
		Frame.MouseEnter:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowHoverTransparency }, "hover")
		end)

		Frame.MouseLeave:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowTransparency }, "hover")
		end)

		Enter(Frame, "BackgroundTransparency", Theme.RowTransparency, "fade")
	end

	return {
		Frame   = Frame,
		Content = Content,
		Head    = Head,
		Aside   = Aside,
		Variant = Variant,
	}
end

--- Charts. A line is drawn as rotated one pixel frames, because Roblox has no
--- primitive for one and this is the cheapest thing that animates.
--- A line drawn as a run of rotated bars, redrawn in place when the data moves.
---
--- The obvious way to animate this is to spring each bar's position, length and
--- angle toward its new value. It looks wrong, and it took seeing it to know
--- why: those three numbers are not independent. A bar is defined by its two
--- endpoints, and springing the derived values separately lets the line come
--- apart in flight — bars detach from their neighbours, swing, and rejoin.
---
--- So the POINTS are what moves. They chase their targets on a plain
--- exponential, every bar is rebuilt from them on each frame, and the line is
--- therefore joined at every instant it is drawn. One frame connection per
--- line, which lets go as soon as it has arrived.
local function Polyline(Parent, Pool, Points, Colour, Alpha, Thickness)
	local Chase = Pool.Chase or 16

	--- The first draw is not an animation: there is nothing to move from.
	if not Pool.Current then
		Pool.Current = {}

		for Index, Point in Points do
			Pool.Current[Index] = Point
		end
	end

	--- A line that has just gained or lost points has nowhere sensible to move
	--- those from, so they start where they belong.
	for Index = #Pool.Current + 1, #Points do
		Pool.Current[Index] = Points[Index]
	end

	for Index = #Points + 1, #Pool.Current do
		Pool.Current[Index] = nil
	end

	Pool.Target = Points
	Pool.Colour = Colour
	Pool.Alpha = Alpha
	Pool.Thickness = Thickness

	local function Draw()
		local Current = Pool.Current
		local Wanted = math.max(0, #Current - 1)

		for Index = 1, Wanted do
			local From, To = Current[Index], Current[Index + 1]
			local Delta = To - From
			local Length = Delta.Magnitude

			local Segment = Pool[Index]

			if not Segment or not Segment.Parent then
				Segment = New("Frame", {
					Name                   = "Segment",
					Parent                 = Parent,
					BackgroundColor3       = Pool.Colour,
					BackgroundTransparency = 1,
					BorderSizePixel        = 0,
					AnchorPoint            = Vector2.new(0.5, 0.5),
				})

				Pool[Index] = Segment
				Tween(Segment, { BackgroundTransparency = Pool.Alpha }, "fade")
			else
				Segment.BackgroundColor3 = Pool.Colour
			end

			--- Assigned, not tweened. The motion is in the points; the bars
			--- only ever report where the points currently are.
			Segment.Position = UDim2.fromOffset((From.X + To.X) / 2, (From.Y + To.Y) / 2)
			Segment.Size = UDim2.fromOffset(Length + 1, Pool.Thickness or 1)
			Segment.Rotation = math.deg(math.atan2(Delta.Y, Delta.X))
		end

		for Index = Wanted + 1, #Pool do
			local Segment = Pool[Index]

			if Segment then
				Tween(Segment, { BackgroundTransparency = 1 }, "exit")

				task.delay(MotionTime("exit"), function()
					Segment:Destroy()
				end)

				Pool[Index] = nil
			end
		end
	end

	local function Settled()
		for Index, Point in Pool.Current do
			local Want = Pool.Target[Index]

			if Want and (Want - Point).Magnitude > 0.25 then
				return false
			end
		end

		return true
	end

	local function Sleep()
		if Pool.Driver then
			Pool.Driver:Disconnect()
			Pool.Driver = nil
		end
	end

	if Settled() then
		Pool.Current = Pool.Target
		Draw()
		Sleep()

		return Pool
	end

	if not Pool.Driver then
		Pool.Driver = RunService.Heartbeat:Connect(function(Delta)
			if not Parent.Parent then
				Sleep()
				return
			end

			local Step = 1 - math.exp(-Chase * math.min(Delta, 1 / 20))

			for Index, Point in Pool.Current do
				local Want = Pool.Target[Index]

				if Want then
					Pool.Current[Index] = Point + (Want - Point) * Step
				end
			end

			Draw()

			if Settled() then
				for Index, Want in Pool.Target do
					Pool.Current[Index] = Want
				end

				Draw()
				Sleep()
			end
		end)
	end

	Draw()

	return Pool
end

local function ChartPoints(Values, Width, Height, Minimum, Maximum)
	local Span = Maximum - Minimum
	local Points = {}

	for Index, Value in Values do
		local X = #Values > 1 and (Index - 1) / (#Values - 1) * Width or 0
		local Y = Height - (Span > 0 and (Value - Minimum) / Span or 0.5) * Height

		Points[Index] = Vector2.new(X, Y)
	end

	return Points
end

--- The range a chart is drawn against, honouring explicit bounds and falling
--- back to the data. A flat series is padded so it does not divide by zero.
local function Extent(Values, Options)
	local Minimum = Options.Min
	local Maximum = Options.Max

	if not Minimum or not Maximum then
		local Low, High = math.huge, -math.huge

		for _, Value in Values do
			Low = math.min(Low, Value)
			High = math.max(High, Value)
		end

		if Low == math.huge then
			Low, High = 0, 1
		end

		if Low == High then
			Low, High = Low - 1, High + 1
		end

		Minimum = Minimum or Low
		Maximum = Maximum or High
	end

	return Minimum, Maximum
end

--- The finisher for Block based controls.
local function BlockHandle(Built, Extra, Options)
	local Handle = Extra or {}

	return Common(Handle, Built.Frame, Options or {}, {})
end

Parts.Span        = Span
Parts.Layered     = Layered
Parts.SlidingMark = SlidingMark
Parts.Draggable   = Draggable
Parts.Learn       = Learn
Parts.Locate      = Locate
Parts.Tooltip     = Tooltip
Parts.Common      = Common
Parts.Dress       = Dress
Parts.Row         = Row
Parts.Block       = Block
Parts.BlockHandle = BlockHandle
Parts.Polyline    = Polyline
Parts.ChartPoints = ChartPoints
Parts.Extent      = Extent

return Parts
