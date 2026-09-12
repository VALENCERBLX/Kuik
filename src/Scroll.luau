--!nonstrict
--- Scroll.luau — smooth wheel scrolling and the edge gleams that tell you
--- there is more.
---
--- Roblox's own wheel handling snaps. The fix is to turn ScrollingEnabled off
--- on desktop and drive CanvasPosition with a spring instead, which also means
--- a scroll can be retargeted mid flight by another wheel tick.

local UserInputService = game:GetService("UserInputService")

local Palette = require(script.Parent.Theme)
local Util    = require(script.Parent.Util)
local Motion  = require(script.Parent.Motion)
local Screen  = require(script.Parent.Screen)

local Theme = Palette.Tokens

local New   = Util.New
local Clamp = Util.Clamp

local Tween      = Motion.Tween
local MotionTime = Motion.MotionTime

local Scroll = {}

--- A soft light at each end of a scroller, fading off along its own edges so
--- it reads as a gradient rather than a stripe. Built from a CanvasGroup with
--- a cross axis gradient wrapping a frame with a main axis one, because a
--- UIGradient only has the one axis.
local function Gleam(Frame, Vertical, Depth, Options)
	local Parent = Util.Loose(Frame)

	if not Parent then
		return function() end
	end

	Options = Options or {}
	Depth = Depth or 22

	local Base = Options.Strength or 0.86
	local Colour = Options.Color or Theme.White

	local function Edge(Head)
		local Group = New("CanvasGroup", {
			Name                   = Head and "GleamHead" or "GleamTail",
			Parent                 = Parent,
			BackgroundTransparency = 1,
			GroupTransparency      = 1,
			BorderSizePixel        = 0,
			ZIndex                 = 30,
			Active                 = false,
		}, {
			New("UIGradient", {
				Rotation = Vertical and 0 or 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.16, 0),
					NumberSequenceKeypoint.new(0.84, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})

		New("Frame", {
			Name                   = "Light",
			Parent                 = Group,
			BackgroundColor3       = Colour,
			BackgroundTransparency = Base,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 1, 0),
			Active                 = false,
		}, {
			New("UIGradient", {
				Rotation = Vertical and 90 or 0,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, Head and 0 or 1),
					NumberSequenceKeypoint.new(1, Head and 1 or 0),
				}),
			}),
		})

		return Group
	end

	local Head, Tail = Edge(true), Edge(false)

	--- The gleams are not children of the scroller, so they never take part in
	--- its layout or get clipped by it — which means tracking its geometry by
	--- hand. Measured in absolutes rather than copied from Position and Size,
	--- because the host they hang off is no longer always the scroller's own
	--- parent: it is the first ancestor that is not arranging its children.
	local function Layout()
		local Origin = Parent.AbsolutePosition
		local At = Frame.AbsolutePosition
		local Size = Frame.AbsoluteSize

		if Size.X <= 0 or Size.Y <= 0 then
			return
		end

		local X, Y = At.X - Origin.X, At.Y - Origin.Y

		if Vertical then
			Head.AnchorPoint = Vector2.new(0, 0)
			Head.Position = UDim2.new(0, X, 0, Y)
			Head.Size = UDim2.new(0, Size.X, 0, Depth)

			Tail.AnchorPoint = Vector2.new(0, 1)
			Tail.Position = UDim2.new(0, X, 0, Y + Size.Y)
			Tail.Size = UDim2.new(0, Size.X, 0, Depth)
		else
			Head.AnchorPoint = Vector2.new(0, 0)
			Head.Position = UDim2.new(0, X, 0, Y)
			Head.Size = UDim2.new(0, Depth, 0, Size.Y)

			Tail.AnchorPoint = Vector2.new(1, 0)
			Tail.Position = UDim2.new(0, X + Size.X, 0, Y)
			Tail.Size = UDim2.new(0, Depth, 0, Size.Y)
		end
	end

	local Motion_ = 0
	local Before, After = false, false

	local function Update()
		local Span = Vertical
			and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
			or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X

		local At = Vertical and Frame.CanvasPosition.Y or Frame.CanvasPosition.X

		Before = Span > 2 and At > 2
		After = Span > 2 and (Span - At) > 2

		Tween(Head, { GroupTransparency = Before and Motion_ or 1 }, "fade")
		Tween(Tail, { GroupTransparency = After and Motion_ or 1 }, "fade")
	end

	--- While the wheel is moving the gleams dim, then settle back once it
	--- stops. It reads as the light reacting to the motion.
	local Settle = 0

	local function Nudge()
		Motion_ = 0.55
		Settle += 1

		local Mine = Settle

		Tween(Head, { GroupTransparency = Before and Motion_ or 1 }, "hover")
		Tween(Tail, { GroupTransparency = After and Motion_ or 1 }, "hover")

		task.delay(MotionTime("scroll") * 0.9, function()
			if Settle == Mine then
				Motion_ = 0
				Update()
			end
		end)
	end

	local Connections = {
		Frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(Layout),
		Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(Layout),
		Parent:GetPropertyChangedSignal("AbsolutePosition"):Connect(Layout),
		Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(Update),
		Frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(Update),
		Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(Update),
	}

	Layout()
	task.defer(Update)

	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end

		Head:Destroy()
		Tail:Destroy()
	end, Nudge
end

--- Gleams on the inside edges of something that can be moved further than it
--- shows: the four faces of a panned image, the two ends of a carousel. Unlike
--- the scroller gleams above these are children of the frame itself, because
--- the frame clips and the light should be clipped with it.
---
--- Each edge is lit in proportion to how far there is left to go that way, so
--- the light is a readout of the room remaining rather than a decoration.
local function Edges(Frame, Options)
	Options = Options or {}

	local Depth = Options.Depth or 26
	local Base = Options.Strength or 0.72
	local Colour = Options.Color or Theme.White

	local Sides = {}

	local function Edge(Name, Anchor, Position, Size, Rotation)
		local Group = New("CanvasGroup", {
			Name                   = Name,
			Parent                 = Frame,
			BackgroundTransparency = 1,
			GroupTransparency      = 1,
			BorderSizePixel        = 0,
			AnchorPoint            = Anchor,
			Position               = Position,
			Size                   = Size,
			ZIndex                 = Options.ZIndex or 20,
			Active                 = false,
		})

		New("Frame", {
			Name                   = "Light",
			Parent                 = Group,
			BackgroundColor3       = Colour,
			BackgroundTransparency = Base,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 1, 0),
			Active                 = false,
		}, {
			New("UIGradient", {
				Rotation = Rotation,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})

		Sides[Name] = Group

		return Group
	end

	--- Rotation points each gradient away from its own edge, so the light is
	--- strongest against the frame and gone by the time it reaches the middle.
	Edge("Left", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, Depth, 1, 0), 0)
	Edge("Right", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, Depth, 1, 0), 180)
	Edge("Top", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, Depth), 90)
	Edge("Bottom", Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(1, 0, 0, Depth), 270)

	local Handle = { Sides = Sides }

	--- Room is a 0..1 per side. Anything past a tenth of the depth is treated
	--- as fully lit, so a small amount of travel still reads clearly.
	function Handle:Set(Room, Role)
		for Name, Group in Sides do
			local Amount = math.clamp((Room[Name] or 0) * 8, 0, 1)

			Tween(Group, { GroupTransparency = 1 - Amount }, Role or "fade")
		end

		return Handle
	end

	function Handle:Destroy()
		for _, Group in Sides do
			Group:Destroy()
		end

		table.clear(Sides)
	end

	return Handle
end

--- Which scroller the pointer is over. Module wide so the innermost one wins:
--- scrolling a dropdown should not also scroll the page behind it.
local Hovered = nil

local function SmoothScroll(Frame, Axis, Options)
	local Handle = { Frame = Frame, Enabled = true }
	local Vertical = Axis ~= "X"

	if not (Options and Options.Gleam == false) then
		Handle.StopGleam, Handle.Nudge = Gleam(Frame, Vertical,
			Options and Options.Depth, Options)
	end

	--- Touch and gamepad keep Roblox's own scrolling: it is already right for
	--- them, and taking it over would break momentum.
	if not UserInputService.MouseEnabled then
		function Handle:SetEnabled() end
		function Handle:Sync() end

		function Handle:To(Position)
			Frame.CanvasPosition = Position
		end

		function Handle:Top()
			Frame.CanvasPosition = Vector2.zero
		end

		function Handle:Span()
			return math.max(0, Vertical
				and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
				or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X)
		end

		function Handle:Destroy()
			if Handle.StopGleam then
				Handle.StopGleam()
			end
		end

		return Handle
	end

	Frame.ScrollingEnabled = false

	local Target = Frame.CanvasPosition
	local Connections = {}

	--- Whether the viewer has ever scrolled this frame themselves. Until they
	--- have, a canvas that grows must not drag the view: content is still
	--- being built, and a window that opens already scrolled to the bottom is
	--- the single most confusing thing a UI can do.
	local Touched = false

	function Handle:SetEnabled(Value)
		Handle.Enabled = Value
	end

	function Handle:To(Position, Role)
		Touched = true
		Target = Position
		Tween(Frame, { CanvasPosition = Target }, Role or "scroll")
	end

	function Handle:Sync()
		Target = Frame.CanvasPosition
	end

	--- Back to the start, and forget that anyone had scrolled.
	function Handle:Top()
		Touched = false
		Target = Vector2.zero
		Frame.CanvasPosition = Vector2.zero
		Motion.Halt(Frame, "CanvasPosition")
	end

	function Handle:Span()
		return math.max(0, Vertical
			and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
			or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X)
	end

	--- Content shrinking underneath a scrolled view would otherwise leave the
	--- canvas parked past its own end.
	--- Until the viewer has scrolled this frame themselves, it is pinned to the
	--- start. Content arriving, the frame being resized, the window being
	--- fitted to a viewport that was not measured yet — any of them can leave
	--- a freshly built scroller parked at the bottom of its own content, which
	--- is the single most confusing thing a panel can do. Rather than chase
	--- each cause, the invariant is enforced directly.
	local Holding = false

	local function Pin()
		if Touched or Holding then
			return
		end

		if Frame.CanvasPosition.Magnitude > 0.5 then
			Holding = true
			Target = Vector2.zero
			Frame.CanvasPosition = Vector2.zero
			Holding = false
		end
	end

	table.insert(Connections, Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(Pin))
	table.insert(Connections, Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(Pin))

	table.insert(Connections, Frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		if not Touched then
			Pin()
			return
		end

		local Span = Handle:Span()

		if Vertical and Target.Y > Span then
			Handle:To(Vector2.new(0, Span))
		elseif not Vertical and Target.X > Span then
			Handle:To(Vector2.new(Span, 0))
		end
	end))

	local Driving = false
	local Token = 0

	table.insert(Connections, Frame.MouseEnter:Connect(function()
		Hovered = Frame
	end))

	table.insert(Connections, Frame.MouseLeave:Connect(function()
		if Hovered == Frame then
			Hovered = nil
		end
	end))

	table.insert(Connections, Frame.InputChanged:Connect(function(Input)
		if not Handle.Enabled or Input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end

		--- A prompt is up: the wheel belongs to it, or to nothing.
		if Screen.Blocked() and not (Options and Options.Modal) then
			return
		end

		--- Someone nested inside us owns this tick.
		if Hovered and Hovered ~= Frame then
			return
		end

		local Span = Handle:Span()

		if Span <= 0 then
			return
		end

		Touched = true

		--- Resync from the real position when the previous scroll has settled,
		--- so a drag or a jump elsewhere does not get undone by the next tick.
		if not Driving then
			Target = Frame.CanvasPosition
		end

		local Step = Input.Position.Z * (Options and Options.Step or (Vertical and 92 or 56))

		Target = Vertical
			and Vector2.new(0, Clamp(Target.Y - Step, 0, Span))
			or Vector2.new(Clamp(Target.X - Step, 0, Span), 0)

		Driving = true
		Token += 1

		local Mine = Token

		if Handle.Nudge then
			Handle.Nudge()
		end

		Tween(Frame, { CanvasPosition = Target }, "scroll")

		task.delay(MotionTime("scroll") * 1.2, function()
			if Token == Mine then
				Driving = false
			end
		end)
	end))

	function Handle:Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end

		table.clear(Connections)

		if Handle.StopGleam then
			Handle.StopGleam()
		end

		if Hovered == Frame then
			Hovered = nil
		end
	end

	return Handle
end

Scroll.Gleam  = Gleam
Scroll.Edges  = Edges
Scroll.Attach = SmoothScroll

function Scroll.Hovered()
	return Hovered
end

return Scroll
