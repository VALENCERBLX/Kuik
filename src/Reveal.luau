--!nonstrict
--- Reveal.luau — the white layer.
---
--- Everything in here is one idea: a plain white shape stands in for something
--- for a moment, and then hands over to it. A panel opens as a white plate that
--- grows and dissolves into the real panel. A moving highlight drags a white
--- smear behind it. A line of type is uncovered by a white bar sweeping across
--- it. The white is never decoration — it is always the thing that is about to
--- be there, or the thing that just was.
---
--- The timings are measured, not invented. See MOTION.md for the frame tables
--- they came from; the short version is that the plate grows on one axis, then
--- the other, then dissolves, and the whole gesture is under half a second.

local RunService = game:GetService("RunService")

local Palette = require(script.Parent.Theme)
local Util    = require(script.Parent.Util)
local Motion  = require(script.Parent.Motion)

local Theme   = Palette.Tokens

local New   = Util.New
local Clamp = Util.Clamp

local Tween      = Motion.Tween
local MotionTime = Motion.MotionTime

local Reveal = {}

--------------------------------------------------------------------------
-- Shared
--------------------------------------------------------------------------

--- The rectangle an object occupies inside a given parent, in offset pixels.
--- Everything here works in offset rather than scale, because a white stand in
--- has to sit exactly on top of a thing whose own size may be in either.
--- A child's offset is measured from the inside of its parent's padding, not
--- from the parent's own corner, so a rectangle worked out from AbsolutePosition
--- alone lands one padding down and to the right of the thing it stands for.
local function Inset(Within)
	local Pad = Within:FindFirstChildWhichIsA("UIPadding")

	if not Pad then
		return 0, 0
	end

	local Size = Within.AbsoluteSize

	return Pad.PaddingLeft.Scale * Size.X + Pad.PaddingLeft.Offset,
		Pad.PaddingTop.Scale * Size.Y + Pad.PaddingTop.Offset
end

local function Rect(Object, Within)
	local Origin = Within.AbsolutePosition
	local Point = Object.AbsolutePosition
	local Size = Object.AbsoluteSize
	local PadX, PadY = Inset(Within)

	return Point.X - Origin.X - PadX, Point.Y - Origin.Y - PadY, Size.X, Size.Y
end

--- A white shape, with the corner and the stroke of whatever it is standing in
--- for, so the stand in does not have a different silhouette to the real thing.
local function Plate(Parent, Options)
	Options = Options or {}

	local Face = New("Frame", {
		Name                   = Options.Name or "Plate",
		Parent                 = Parent,
		BackgroundColor3       = Options.Color or Theme.White,
		BackgroundTransparency = Options.Transparency or 0,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		ZIndex                 = Options.ZIndex or 50,
		Active                 = false,
		Selectable             = false,
	})

	if Options.Radius and Options.Radius > 0 then
		Util.Corner(Options.Radius).Parent = Face
	end

	return Face
end

--- Runs something once an object actually has a size.
---
--- Nothing built this frame has been laid out yet, so anything that measures a
--- thing it has only just made measures zero. Every reveal in here refuses a
--- rectangle it cannot measure — which is right, but it meant that revealing a
--- row you had just added did nothing at all, silently.
---
--- So: try now, and if there is nothing to measure yet, wait for the first size
--- the object is given and try again. Callers that need a synchronous answer —
--- a window deciding whether to fall back to a plain fade — pass Now and get
--- the old behaviour.
local function Ready(Object, Run)
	if not Object or not Object.Parent then
		return function() end
	end

	if Object.AbsoluteSize.X >= 2 and Object.AbsoluteSize.Y >= 1 then
		Run()
		return function() end
	end

	local Watch = nil
	local Done = false

	local function Go()
		if Done or not Object.Parent then
			return
		end

		if Object.AbsoluteSize.X < 2 or Object.AbsoluteSize.Y < 1 then
			return
		end

		Done = true

		if Watch then
			Watch:Disconnect()
			Watch = nil
		end

		Run()
	end

	Watch = Object:GetPropertyChangedSignal("AbsoluteSize"):Connect(Go)

	task.defer(Go)

	return function()
		Done = true

		if Watch then
			Watch:Disconnect()
			Watch = nil
		end
	end
end

Reveal.Ready = Ready

--------------------------------------------------------------------------
-- The plate reveal
--------------------------------------------------------------------------

--- A panel arriving as a white plate.
---
--- The choreography, measured off the reference footage frame by frame at 24fps
--- and then fitted. Reference on the left, what this produces on the right:
---
---   frame   width  height  alpha      width  height  alpha
---     1      221     149    0.60       220     148    0.60
---     2      349     149    0.89       357     148    0.92
---     3      391     164    0.96       390     148    0.99
---     4      393     267    0.91       393     307    1.00
---     5      393     438    0.73       393     424    0.88
---     6      393     470    0.60       393     464    0.67
---     7      393     479    0.48       393     475    0.47
---     9      393     479    0.20       393     479    0.21
---    11      393     479    0.00       393     479    0.08
---
--- Mean deviation 2.5%, worst single frame 15%, which is inside the noise of
--- measuring a compressed 24fps capture. tests/reveal holds this table.
---
--- So the plate reads as a bar that snaps wide, opens down, and burns off. The
--- object itself is hidden for the first half of that and fades up under the
--- dissolve, which is what makes it feel like the plate became the panel rather
--- than sat in front of it. Three details carry it, and all three came out of
--- the frame table rather than out of taste:
---
---   it starts already wide and already open, never from a dot
---   it is only about 60% white when it appears, and reaches full as it lands
---   the burn starts as the height starts, so the panel is showing through
---   before the plate has finished moving
---
--- Object is what is being revealed; it must be a GuiObject with a size worth
--- standing in for. Returns a handle you can Cancel.
function Reveal.Plate(Object, Options)
	Options = Options or {}

	--- Loose, not the immediate parent: a plate dropped into a laid out frame
	--- becomes another item in the column instead of a shape over it, which is
	--- what stopped a row ever revealing itself.
	local Parent = Options.Parent or Util.Loose(Object)

	if not Parent then
		return { Cancel = function() end }
	end

	--- Nothing to measure yet, and the caller can wait: run it when there is.
	if Options.Now ~= true and not Options.Rect
		and (Object.AbsoluteSize.X < 2 or Object.AbsoluteSize.Y < 2) then
		local Handle = {}
		local Give = Ready(Object, function()
			local Run = Reveal.Plate(Object, Util.Merge(Options, { Now = true }))

			Handle.Face = Run.Face
			Handle.Cancel = Run.Cancel
		end)

		Handle.Cancel = Give

		return Handle
	end

	local X, Y, Width, Height = Rect(Object, Parent)

	--- A caller that already knows the rectangle can say so, which is the only
	--- way to reveal something on the frame it was built: a thing has no
	--- AbsoluteSize until Roblox has laid it out.
	if Options.Rect then
		X, Y, Width, Height = Options.Rect[1], Options.Rect[2], Options.Rect[3], Options.Rect[4]
	end

	--- Nothing has been laid out yet. Revealing a zero sized rectangle would
	--- draw a dot and dissolve it, which is worse than not trying.
	if Width < 2 or Height < 2 then
		return { Cancel = function() end }
	end

	local Seed = Options.Seed or 0.56
	local Open = Options.Open or 0.31

	local Face = Plate(Parent, {
		Name      = "Reveal",
		Color     = Options.Color,
		Radius    = Options.Radius,
		ZIndex    = Options.ZIndex or (Object.ZIndex + 40),
	})

	local MiddleX, MiddleY = X + Width / 2, Y + Height / 2

	--- The plate can come from somewhere. In the reference the seed bar starts
	--- a few dozen pixels off the panel's centre and drifts onto it while it
	--- grows, which is what makes it read as having come from the thing that
	--- was clicked rather than having been there all along.
	---
	--- The drift is deliberately small and capped. A plate that flies in from
	--- across the screen is a different effect, and a worse one: it draws the
	--- eye away from where the panel is about to be.
	local FromX, FromY = MiddleX, MiddleY

	if Options.From then
		local Source = Options.From
		local PointX, PointY = nil, nil

		--- Either a GuiObject to come from, or a plain point in the parent's
		--- own pixels. Read a component at a time rather than with vector
		--- arithmetic, so this works wherever the library is being run.
		if Source.AbsolutePosition then
			local Origin = Parent.AbsolutePosition
			local At = Source.AbsolutePosition
			local Span = Source.AbsoluteSize
			local PadX, PadY = Inset(Parent)

			PointX = At.X + Span.X / 2 - Origin.X - PadX
			PointY = At.Y + Span.Y / 2 - Origin.Y - PadY
		elseif Source.X and Source.Y then
			PointX, PointY = Source.X, Source.Y
		end

		if PointX then
			local AwayX = PointX - MiddleX
			local AwayY = PointY - MiddleY
			local Away = math.sqrt(AwayX * AwayX + AwayY * AwayY)
			local Cap = Options.Drift or 48

			if Away > 1 then
				local Take = math.min(Away, Cap) / Away

				FromX = MiddleX + AwayX * Take
				FromY = MiddleY + AwayY * Take
			end
		end
	end

	Face.Position = UDim2.new(0, FromX, 0, FromY)
	Face.Size = UDim2.new(0, Width * Seed, 0, Height * Open)

	--- The plate is not fully white on the frame it appears — it comes in at
	--- about 60% and reaches full as the width finishes. Starting it opaque
	--- makes the whole gesture read as a flash rather than as something being
	--- drawn.
	Face.BackgroundTransparency = Options.Ghosted or 0.4

	--- Hidden rather than transparent: a CanvasGroup fades as one, anything
	--- else has to be taken down to nothing and brought back.
	local Fade = Options.Fade
	local Resting = nil

	if Fade ~= false then
		if Object:IsA("CanvasGroup") then
			--- To is what it should end up at, which is not always what it is
			--- now: a window is revealed from closed, and closed means already
			--- transparent, so reading the current value would fade it back to
			--- nothing.
			Resting = Options.To or (Object.GroupTransparency < 1 and Object.GroupTransparency) or 0
			Object.GroupTransparency = 1
		else
			Resting = Motion.Resting(Object)

			for _, Mark in Resting do
				for Property in Mark.Bits do
					Mark.Object[Property] = 1
				end
			end
		end
	end

	local Wide = Options.Wide or "plate"
	local Tall = Options.Tall or "open"
	local Burn = Options.Burn or "burn"

	local Cancelled = false

	local function Stop()
		Cancelled = true

		Motion.Halt(Face)
		Face:Destroy()
	end

	--- Width first, then height once the width is nearly there. The overlap is
	--- deliberate: waiting for the width to settle makes it read as two moves,
	--- and starting both together makes it read as a box scaling up.
	Tween(Face, {
		Size = UDim2.new(0, Width, 0, Height * Open),
		Position = UDim2.new(0, MiddleX, 0, MiddleY),
		BackgroundTransparency = 0,
	}, Wide)

	task.delay(MotionTime(Wide) * (Options.OpenAt or 1.1), function()
		if Cancelled or not Face.Parent then
			return
		end

		Tween(Face, { Size = UDim2.new(0, Width, 0, Height) }, Tall)

		--- The dissolve starts while the height is still opening, so the panel
		--- is already showing through by the time the plate finishes moving.
		task.delay(MotionTime(Tall) * (Options.BurnAt or 0), function()
			if Cancelled or not Face.Parent then
				return
			end

			Tween(Face, { BackgroundTransparency = 1 }, Burn)

			if Fade ~= false then
				if Object:IsA("CanvasGroup") then
					Tween(Object, { GroupTransparency = Resting }, Burn)
				else
					for _, Mark in Resting do
						Tween(Mark.Object, Mark.Bits, Burn)
					end
				end
			end

			task.delay(MotionTime(Burn) * 1.2, function()
				if not Cancelled and Face.Parent then
					Face:Destroy()
				end

				if Options.Done then
					task.spawn(Options.Done)
				end
			end)
		end)
	end)

	return { Cancel = Stop, Face = Face }
end

--- The plate coming back for it.
---
--- The mirror of Plate: the white comes up over the thing, the thing goes out
--- underneath it, and then the plate shuts — height back down to a bar, width
--- to nothing. A panel that arrives as a plate and then simply vanishes when
--- you press the close button feels like two different interfaces; this is the
--- other half of the gesture.
function Reveal.Cover(Object, Options)
	Options = Options or {}

	local Parent = Options.Parent or Util.Loose(Object)

	if not Parent then
		if Options.Done then
			task.spawn(Options.Done)
		end

		return { Cancel = function() end }
	end

	local X, Y, Width, Height = Rect(Object, Parent)

	if Options.Rect then
		X, Y, Width, Height = Options.Rect[1], Options.Rect[2], Options.Rect[3], Options.Rect[4]
	end

	if Width < 2 or Height < 2 then
		if Options.Done then
			task.spawn(Options.Done)
		end

		return { Cancel = function() end }
	end

	local Seed = Options.Seed or 0.56
	local Open = Options.Open or 0.31

	local Face = Plate(Parent, {
		Name         = "Covering",
		Color        = Options.Color,
		Transparency = 1,
		Radius       = Options.Radius,
		ZIndex       = Options.ZIndex or (Object.ZIndex + 40),
	})

	Face.Position = UDim2.new(0, X + Width / 2, 0, Y + Height / 2)
	Face.Size = UDim2.new(0, Width, 0, Height)

	local Burn = Options.Burn or "plate"
	local Tall = Options.Tall or "open"
	local Wide = Options.Wide or "close"

	local Cancelled = false

	local function Stop()
		Cancelled = true

		Motion.Halt(Face)
		Face:Destroy()
	end

	--- White comes up fast, and whatever is underneath goes out with it.
	Tween(Face, { BackgroundTransparency = 0 }, Burn)

	if Options.Fade ~= false then
		if Object:IsA("CanvasGroup") then
			Tween(Object, { GroupTransparency = 1 }, Burn)
		else
			Motion.Fade(Object, 1, Burn)
		end
	end

	task.delay(MotionTime(Burn) * 1.1, function()
		if Cancelled or not Face.Parent then
			return
		end

		--- Then it shuts: down to a bar, then away to nothing.
		Tween(Face, { Size = UDim2.new(0, Width, 0, Height * Open) }, Tall)

		task.delay(MotionTime(Tall) * 0.8, function()
			if Cancelled or not Face.Parent then
				return
			end

			Tween(Face, { Size = UDim2.new(0, Width * Seed * 0.2, 0, Height * Open) }, Wide)
			Tween(Face, { BackgroundTransparency = 1 }, Wide)

			task.delay(MotionTime(Wide) * 1.1, function()
				if Face.Parent then
					Face:Destroy()
				end

				if Options.Done then
					task.spawn(Options.Done)
				end
			end)
		end)
	end)

	return { Cancel = Stop, Face = Face }
end

--------------------------------------------------------------------------
-- The follow ghost
--------------------------------------------------------------------------

--- A white plate that chases something, and is only visible while it is behind.
---
--- This is the afterimage. The plate springs toward the object's rectangle on a
--- softer spring than the object itself uses, so a move leaves it trailing; its
--- transparency is driven by how far behind it is, so at rest it is not there at
--- all and mid move it is a smear between where the thing was and where it is
--- going.
---
--- Stretch makes the trailing plate span from its own position to the object's
--- rather than merely lagging, which is what turns a lagging copy into a smear.
function Reveal.Follow(Object, Options)
	Options = Options or {}

	local Parent = Options.Parent or Util.Loose(Object)

	if not Parent then
		return { Destroy = function() end }
	end

	local Face = Plate(Parent, {
		Name         = Options.Name or "Ghost",
		Color        = Options.Color,
		Transparency = 1,
		Radius       = Options.Radius,
		ZIndex       = Options.ZIndex or math.max(1, Object.ZIndex - 1),
	})

	local Stiffness = Options.Stiffness or 90
	local Damping = Options.Damping or (2 * math.sqrt(Options.Stiffness or 90))
	local Reach = Options.Reach or 0.55
	local Span = Options.Span or 44
	local Stretch = Options.Stretch ~= false

	local AtX, AtY = nil, nil
	local Handle = { Face = Face }

	--- The ghost costs a frame connection only while it has somewhere to be.
	--- Once it has caught up it lets go of Heartbeat, and the object's own
	--- geometry changing is what wakes it again — so a tab bar nobody is
	--- touching is not paying for a chase that is not happening.
	local Connection = nil
	local Watchers = {}

	local function Step(Delta)
		if not Object.Parent or not Face.Parent then
			return
		end

		local X, Y, Width, Height = Rect(Object, Parent)
		local MiddleX, MiddleY = X + Width / 2, Y + Height / 2

		if AtX == nil then
			AtX, AtY = MiddleX, MiddleY
		end

		--- A plain exponential chase rather than a spring: the ghost must never
		--- overshoot the thing it is trailing, or it arrives ahead of it.
		local Step = 1 - math.exp(-Stiffness * math.min(Delta, 1 / 20) / Damping * 2)

		AtX += (MiddleX - AtX) * Step
		AtY += (MiddleY - AtY) * Step

		local AwayX, AwayY = MiddleX - AtX, MiddleY - AtY
		local Away = math.sqrt(AwayX * AwayX + AwayY * AwayY)

		--- Behind by nothing means invisible. Behind by Span pixels or more
		--- means as visible as it is ever allowed to get.
		local Strength = Clamp(Away / Span, 0, 1) * Reach

		Face.BackgroundTransparency = 1 - Strength

		if Strength <= 0.002 then
			return
		end

		if Stretch then
			--- The plate covers both where the thing is and where the ghost has
			--- got to, so the gap between them is filled rather than skipped.
			local Left = math.min(AtX - Width / 2, MiddleX - Width / 2)
			local Right = math.max(AtX + Width / 2, MiddleX + Width / 2)
			local Top = math.min(AtY - Height / 2, MiddleY - Height / 2)
			local Bottom = math.max(AtY + Height / 2, MiddleY + Height / 2)

			Face.Position = UDim2.new(0, (Left + Right) / 2, 0, (Top + Bottom) / 2)
			Face.Size = UDim2.new(0, Right - Left, 0, Bottom - Top)
		else
			Face.Position = UDim2.new(0, AtX, 0, AtY)
			Face.Size = UDim2.new(0, Width, 0, Height)
		end
	end

	local function Sleep()
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
	end

	local function Wake()
		if not Connection and Face.Parent then
			Connection = RunService.Heartbeat:Connect(function(Delta)
				Step(Delta)

				if Face.BackgroundTransparency > 0.998 then
					Sleep()
				end
			end)
		end
	end

	Handle.Wake = Wake

	for _, Property in { "AbsolutePosition", "AbsoluteSize" } do
		table.insert(Watchers, Object:GetPropertyChangedSignal(Property):Connect(Wake))
	end

	function Handle:Destroy()
		Sleep()

		for _, Watcher in Watchers do
			Watcher:Disconnect()
		end

		table.clear(Watchers)
		Face:Destroy()
	end

	--- Puts the ghost exactly where the object is, so a jump that should not
	--- smear does not.
	function Handle:Settle()
		local X, Y, Width, Height = Rect(Object, Parent)

		AtX, AtY = X + Width / 2, Y + Height / 2
		Face.BackgroundTransparency = 1
		Sleep()

		return Handle
	end

	return Handle
end

--------------------------------------------------------------------------
-- One shot afterimages
--------------------------------------------------------------------------

--- A single white copy of where something was, left behind to fade.
---
--- Unlike Follow, this does not track anything: it is stamped at a moment and
--- then it dies. Stamp one per frame while something moves and you have a trail
--- you can control precisely; stamp one when something is removed and it reads
--- as the thing leaving a hole behind it.
function Reveal.Ghost(Object, Options)
	Options = Options or {}

	local Parent = Options.Parent or Util.Loose(Object)

	if not Parent then
		return nil
	end

	local X, Y, Width, Height = Rect(Object, Parent)

	if Width < 1 or Height < 1 then
		return nil
	end

	local Face = Plate(Parent, {
		Name         = "Afterimage",
		Color        = Options.Color,
		Transparency = Options.Transparency or 0.55,
		Radius       = Options.Radius,
		ZIndex       = Options.ZIndex or math.max(1, Object.ZIndex - 1),
	})

	Face.Position = UDim2.new(0, X + Width / 2, 0, Y + Height / 2)
	Face.Size = UDim2.new(0, Width, 0, Height)

	local Role = Options.Role or "smear"

	Tween(Face, {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, Width * (Options.Spread or 1), 0, Height * (Options.Spread or 1)),
	}, Role)

	task.delay(MotionTime(Role) * 1.3, function()
		if Face.Parent then
			Face:Destroy()
		end
	end)

	return Face
end

--- A trail of them. Stamps a ghost every Every seconds for as long as the
--- object keeps moving, and stops on its own once it settles.
function Reveal.Trail(Object, Options)
	Options = Options or {}

	local Parent = Options.Parent or Util.Loose(Object)
	local Every = Options.Every or 1 / 30
	local Least = Options.Least or 3

	local Since = 0
	local LastX, LastY = nil, nil

	local Connection = RunService.Heartbeat:Connect(function(Delta)
		if not Object.Parent then
			return
		end

		local Point = Object.AbsolutePosition

		if LastX then
			local Moved = math.abs(Point.X - LastX) + math.abs(Point.Y - LastY)

			Since += Delta

			if Moved > Least and Since >= Every then
				Since = 0
				Reveal.Ghost(Object, {
					Parent       = Parent,
					Color        = Options.Color,
					Transparency = Options.Transparency,
					Radius       = Options.Radius,
					Role         = Options.Role,
					Spread       = Options.Spread,
				})
			end
		end

		LastX, LastY = Point.X, Point.Y
	end)

	return {
		Destroy = function()
			Connection:Disconnect()
		end,
	}
end

--------------------------------------------------------------------------
-- Wipes
--------------------------------------------------------------------------

--- A white bar that sweeps across something and leaves it behind, uncovered.
---
--- The bar is the width of the object and travels its length; the object is
--- clipped to the part the bar has already passed, so the content is not there
--- until the white has been over it.
function Reveal.Wipe(Object, Options)
	Options = Options or {}

	local Parent = Options.Parent or Util.Loose(Object)

	if not Parent then
		return { Cancel = function() end }
	end

	if Options.Now ~= true and (Object.AbsoluteSize.X < 2 or Object.AbsoluteSize.Y < 2) then
		local Handle = {}
		local Give = Ready(Object, function()
			local Run = Reveal.Wipe(Object, Util.Merge(Options, { Now = true }))

			Handle.Face = Run.Face
			Handle.Cancel = Run.Cancel
		end)

		Handle.Cancel = Give

		return Handle
	end

	local X, Y, Width, Height = Rect(Object, Parent)

	if Width < 2 or Height < 2 then
		return { Cancel = function() end }
	end

	local Down = Options.Axis == "Y"
	local Thickness = Options.Thickness or (Down and math.max(2, Height * 0.18) or math.max(2, Width * 0.12))

	local Bar = Plate(Parent, {
		Name   = "Wipe",
		Color  = Options.Color,
		ZIndex = Options.ZIndex or (Object.ZIndex + 40),
	})

	Bar.Size = Down and UDim2.new(0, Width, 0, Thickness) or UDim2.new(0, Thickness, 0, Height)
	Bar.Position = Down
		and UDim2.new(0, X + Width / 2, 0, Y)
		or UDim2.new(0, X, 0, Y + Height / 2)

	local Resting = Motion.Resting(Object)

	for _, Mark in Resting do
		for Property in Mark.Bits do
			Mark.Object[Property] = 1
		end
	end

	local Role = Options.Role or "sweep"
	local Landed = false

	Tween(Bar, {
		Position = Down
			and UDim2.new(0, X + Width / 2, 0, Y + Height)
			or UDim2.new(0, X + Width, 0, Y + Height / 2),
	}, Role)

	--- The content comes up behind the bar rather than after it, so the bar is
	--- always ahead of what it has revealed.
	task.delay(MotionTime(Role) * 0.35, function()
		if Landed then
			return
		end

		for _, Mark in Resting do
			if Mark.Object.Parent then
				Tween(Mark.Object, Mark.Bits, "enter")
			end
		end
	end)

	task.delay(MotionTime(Role), function()
		if not Landed and Bar.Parent then
			Tween(Bar, { BackgroundTransparency = 1 }, "burn")

			task.delay(MotionTime("burn") * 1.2, function()
				if Bar.Parent then
					Bar:Destroy()
				end
			end)
		end
	end)

	return {
		Face = Bar,
		Cancel = function()
			Landed = true
			Motion.Halt(Bar)
			Bar:Destroy()

			for _, Mark in Resting do
				if Mark.Object.Parent then
					for Property, Value in Mark.Bits do
						Mark.Object[Property] = Value
					end
				end
			end
		end,
	}
end

--------------------------------------------------------------------------
-- Closing
--------------------------------------------------------------------------

--- A white bar that contracts to nothing about its own centre, handing over to
--- whatever was underneath it.
---
--- The opposite gesture to a plate: a plate arrives by growing, this leaves by
--- closing. It is what covers a cut in the reference — the screen goes black in
--- a single frame and a bar over the label's position closes away, so the label
--- is uncovered rather than faded up.
---
--- Measured at 24fps over a 215 px bar: 215, 191, 159, 129, 81, 61, 47, 35, 18,
--- 13, 9. A critically damped spring at a stiffness of 144 lands within a pixel
--- or two of every one of those.
function Reveal.Close(Object, Options)
	Options = Options or {}

	local Parent = Options.Parent or (Object and Util.Loose(Object))

	if not Parent then
		return { Cancel = function() end }
	end

	local X, Y, Width, Height = 0, 0, 0, 0

	if Options.Rect then
		X, Y, Width, Height = Options.Rect[1], Options.Rect[2], Options.Rect[3], Options.Rect[4]
	elseif Object then
		X, Y, Width, Height = Rect(Object, Parent)
	end

	if Width < 2 or Height < 1 then
		return { Cancel = function() end }
	end

	--- Wider than what it covers, because the bar in the reference overhangs
	--- the label it hands over to rather than matching it.
	local Over = Options.Over or 1.1

	local Face = Plate(Parent, {
		Name   = "Closing",
		Color  = Options.Color,
		Radius = Options.Radius,
		ZIndex = Options.ZIndex or ((Object and Object.ZIndex or 1) + 40),
	})

	Face.Position = UDim2.new(0, X + Width / 2, 0, Y + Height / 2)
	Face.Size = UDim2.new(0, Width * Over, 0, Height)

	local Role = Options.Role or "close"
	local Gone = false

	--- Height held, width taken to nothing: it closes like a shutter rather
	--- than shrinking like a box.
	Tween(Face, { Size = UDim2.new(0, 0, 0, Height) }, Role)

	task.delay(MotionTime(Role) * 1.2, function()
		if not Gone and Face.Parent then
			Face:Destroy()
		end

		if Options.Done then
			task.spawn(Options.Done)
		end
	end)

	return {
		Face = Face,
		Cancel = function()
			Gone = true
			Motion.Halt(Face)
			Face:Destroy()
		end,
	}
end

--------------------------------------------------------------------------
-- Screen level
--------------------------------------------------------------------------

--- A white flash over everything.
---
--- Measured off the reference at 30fps: it snaps to full white in one frame,
--- HOLDS there for five (0.17 s), and only then decays over about seven more.
--- The hold is the part that is easy to leave out and the part that makes it
--- read as a cut being covered rather than as a light being flicked — without
--- it the flash is a blink, and a blink cannot hide a scene change behind it.
function Reveal.Flash(Options)
	Options = Options or {}

	local Screen = require(script.Parent.Screen)

	local Face = New("Frame", {
		Name                   = "Flash",
		Parent                 = Options.Parent or Screen.Get(),
		BackgroundColor3       = Options.Color or Theme.White,
		BackgroundTransparency = 1 - (Options.Peak or 0.9),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = Options.ZIndex or 4000,
		Active                 = false,
		Selectable             = false,
	})

	--- Every pixel, top bar included. A flash that misses a strip at the bottom
	--- of the screen is not a flash.
	Screen.Cover(Face)

	local Role = Options.Role or "burn"
	local Hold = Options.Hold or 0

	local function Decay()
		if not Face.Parent then
			return
		end

		Tween(Face, { BackgroundTransparency = 1 }, Role)

		task.delay(MotionTime(Role) * 1.4, function()
			if Face.Parent then
				Face:Destroy()
			end
		end)
	end

	--- Anything covered by the flash happens at the top of the hold, while the
	--- screen is solid, which is the whole reason to hold at all.
	if Hold > 0 then
		task.delay(Hold, function()
			if Options.Covered then
				task.spawn(Options.Covered)
			end

			Decay()
		end)
	else
		if Options.Covered then
			task.spawn(Options.Covered)
		end

		Decay()
	end

	return Face
end

return Reveal
