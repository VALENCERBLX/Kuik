--!nonstrict
--- Motion.luau — the animation layer, ported from Lume.
---
--- Two paths behind one call. A motion spec with a Duration goes to
--- TweenService; a spec with a Stiffness goes to an analytic damped harmonic
--- oscillator stepped on Heartbeat. Springs are what give the library its
--- feel: they retarget mid flight without a restart, which tweens cannot do.

local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

local Palette = require(script.Parent.Theme)

local Theme = Palette.Tokens

local Motion = {}

local EASING_STYLES = {
	linear = Enum.EasingStyle.Linear,
	sine = Enum.EasingStyle.Sine,
	quad = Enum.EasingStyle.Quad,
	cubic = Enum.EasingStyle.Cubic,
	quart = Enum.EasingStyle.Quart,
	quint = Enum.EasingStyle.Quint,
	expo = Enum.EasingStyle.Exponential,
	exponential = Enum.EasingStyle.Exponential,
	circ = Enum.EasingStyle.Circular,
	circular = Enum.EasingStyle.Circular,
	back = Enum.EasingStyle.Back,
	elastic = Enum.EasingStyle.Elastic,
	bounce = Enum.EasingStyle.Bounce,
}

local EASING_DIRECTIONS = {
	["in"] = Enum.EasingDirection.In,
	out = Enum.EasingDirection.Out,
	inout = Enum.EasingDirection.InOut,
}

--- Names read as one word: outQuint, inBack, inoutSine.
local function ResolveEasing(Name)
	if not Name or Name == "" then
		return Enum.EasingStyle.Quad, Enum.EasingDirection.Out
	end

	local Lowered = string.lower(Name)

	if Lowered == "linear" then
		return Enum.EasingStyle.Linear, Enum.EasingDirection.Out
	end

	local Direction, Style = "out", Lowered

	if string.sub(Lowered, 1, 5) == "inout" then
		Direction, Style = "inout", string.sub(Lowered, 6)
	elseif string.sub(Lowered, 1, 3) == "out" then
		Direction, Style = "out", string.sub(Lowered, 4)
	elseif string.sub(Lowered, 1, 2) == "in" then
		Direction, Style = "in", string.sub(Lowered, 3)
	end

	return EASING_STYLES[Style] or Enum.EasingStyle.Quad,
		EASING_DIRECTIONS[Direction] or Enum.EasingDirection.Out
end

local EPSILON_POSITION = 0.0005
local EPSILON_VELOCITY = 0.0005

local SpringClass = {}
SpringClass.__index = SpringClass

local function NewSpring(Position, Stiffness, Damping)
	local Frequency = math.sqrt(math.max(Stiffness, 0.0001))

	return setmetatable({
		Position  = Position,
		Velocity  = 0,
		Target    = Position,
		Frequency = Frequency,
		Ratio     = Damping / (2 * Frequency),
	}, SpringClass)
end

function SpringClass:Retune(Stiffness, Damping)
	local Frequency = math.sqrt(math.max(Stiffness, 0.0001))

	self.Frequency = Frequency
	self.Ratio = Damping / (2 * Frequency)
end

--- Closed form solution for the three damping regimes. Solving analytically
--- rather than integrating means a long frame cannot blow the spring up.
function SpringClass:Step(Delta)
	if Delta <= 0 then
		return self.Position
	end

	local Step = math.min(Delta, 1 / 20)
	local Offset = self.Position - self.Target
	local Velocity = self.Velocity
	local Frequency = self.Frequency
	local Ratio = self.Ratio

	local Position, NextVelocity

	if Ratio < 1 then
		local Damped = Frequency * math.sqrt(1 - Ratio * Ratio)
		local Decay = math.exp(-Ratio * Frequency * Step)
		local Cosine = math.cos(Damped * Step)
		local Sine = math.sin(Damped * Step)
		local First = Offset
		local Second = (Velocity + Ratio * Frequency * Offset) / Damped

		Position = Decay * (First * Cosine + Second * Sine)
		NextVelocity = Decay * (
			-Ratio * Frequency * (First * Cosine + Second * Sine)
				+ Damped * (Second * Cosine - First * Sine)
		)
	elseif Ratio == 1 then
		local Decay = math.exp(-Frequency * Step)
		local First = Offset
		local Second = Velocity + Frequency * Offset

		Position = (First + Second * Step) * Decay
		NextVelocity = Decay * (Second - Frequency * (First + Second * Step))
	else
		local Root = Frequency * math.sqrt(Ratio * Ratio - 1)
		local Slow = -Frequency * Ratio + Root
		local Fast = -Frequency * Ratio - Root
		local Second = (Velocity - Slow * Offset) / (Fast - Slow)
		local First = Offset - Second
		local SlowDecay = math.exp(Slow * Step)
		local FastDecay = math.exp(Fast * Step)

		Position = First * SlowDecay + Second * FastDecay
		NextVelocity = First * Slow * SlowDecay + Second * Fast * FastDecay
	end

	self.Position = Position + self.Target
	self.Velocity = NextVelocity

	return self.Position
end

function SpringClass:Settled()
	return math.abs(self.Position - self.Target) < EPSILON_POSITION
		and math.abs(self.Velocity) < EPSILON_VELOCITY
end

--- Roblox types decomposed into scalars, since a spring only knows numbers.
local Parts = {
	number = {
		Split = function(Value) return { Value } end,
		Build = function(P) return P[1] end,
	},
	UDim = {
		Split = function(Value) return { Value.Scale, Value.Offset } end,
		Build = function(P) return UDim.new(P[1], P[2]) end,
	},
	UDim2 = {
		Split = function(Value)
			return { Value.X.Scale, Value.X.Offset, Value.Y.Scale, Value.Y.Offset }
		end,
		Build = function(P) return UDim2.new(P[1], P[2], P[3], P[4]) end,
	},
	Vector2 = {
		Split = function(Value) return { Value.X, Value.Y } end,
		Build = function(P) return Vector2.new(P[1], P[2]) end,
	},
	Color3 = {
		Split = function(Value) return { Value.R, Value.G, Value.B } end,
		Build = function(P)
			return Color3.new(
				math.clamp(P[1], 0, 1),
				math.clamp(P[2], 0, 1),
				math.clamp(P[3], 0, 1)
			)
		end,
	},
}

--- Which decomposition a value wants.
---
--- typeof answers this in a real client. It cannot answer it anywhere else:
--- Luau treats typeof as a builtin and inlines the call, so a headless harness
--- that replaces the global has no effect and every stand in value comes back
--- as "table". Falling back to the value's shape is what lets a position, a
--- size or a colour be animated under a test at all — in a real client the
--- fallback is never reached, because typeof has already answered.
local function KindOf(Value)
	local Named = Parts[typeof(Value)]

	if Named then
		return Named
	end

	if type(Value) ~= "table" then
		return nil
	end

	local X, Y = Value.X, Value.Y

	if X ~= nil and Y ~= nil then
		if type(X) == "table" and X.Scale ~= nil then
			return Parts.UDim2
		end

		if type(X) == "number" then
			return Parts.Vector2
		end
	end

	if Value.Scale ~= nil and Value.Offset ~= nil then
		return Parts.UDim
	end

	if Value.R ~= nil and Value.G ~= nil and Value.B ~= nil then
		return Parts.Color3
	end

	return nil
end

--- Object -> Property -> channel. One driver for the whole library; it
--- disconnects itself when nothing is moving.
local Live = {}
local Driver = nil

local function StepAll(Delta)
	local Moving = false

	for Object, Channels in Live do
		if not Object.Parent then
			Live[Object] = nil
			continue
		end

		for Property, Channel in Channels do
			local Settled = true
			local Values = table.create(#Channel.Springs)

			for Index, Each in Channel.Springs do
				Each:Step(Delta)
				Values[Index] = Each.Position

				if not Each:Settled() then
					Settled = false
				end
			end

			if Settled then
				--- Land on the exact goal, not on the epsilon near it.
				Object[Property] = Channel.Goal
				Channels[Property] = nil

				if Channel.Done then
					Channel.Done:Fire()
				end
			else
				Object[Property] = Channel.Kind.Build(Values)
				Moving = true
			end
		end

		if next(Channels) == nil then
			Live[Object] = nil
		end
	end

	if not Moving and next(Live) == nil and Driver then
		Driver:Disconnect()
		Driver = nil
	end
end

local function SpringTo(Object, Properties, Stiffness, Damping, Done)
	local Channels = Live[Object]

	if not Channels then
		Channels = {}
		Live[Object] = Channels
	end

	for Property, Goal in Properties do
		local Kind = KindOf(Goal)

		if Kind then
			local Wanted = Kind.Split(Goal)
			local Channel = Channels[Property]

			--- Retarget in place when the shape matches, so a spring already
			--- in flight bends toward the new goal instead of restarting.
			--- Compared by decomposition rather than by type name, for the same
			--- reason KindOf exists.
			if Channel and #Channel.Springs == #Wanted and Channel.Kind == Kind then
				for Index, Each in Channel.Springs do
					Each:Retune(Stiffness, Damping)
					Each.Target = Wanted[Index]
				end

				Channel.Goal = Goal
				Channel.Done = Done
			else
				local Current = Kind.Split(Object[Property])
				local Springs = table.create(#Wanted)

				for Index, Value in Wanted do
					local Each = NewSpring(Current[Index] or Value, Stiffness, Damping)
					Each.Target = Value
					Springs[Index] = Each
				end

				Channels[Property] = {
					Springs = Springs,
					Kind    = Kind,
					Goal    = Goal,
					Done    = Done,
				}
			end
		else
			Object[Property] = Goal
		end
	end

	if not Driver then
		Driver = RunService.Heartbeat:Connect(StepAll)
	end
end

local function Spec(Role)
	if type(Role) == "table" then
		return Role
	end

	return Theme.Motion[Role or "item"] or Theme.Motion.item
end

--- How long a role takes, in seconds. A spring has no duration, so this is the
--- settle estimate the library uses to schedule follow up work.
local function MotionTime(Role)
	local Using = Spec(Role)

	if Using.Duration then
		return Using.Duration
	end

	return 6 / math.sqrt(math.max(Using.Stiffness or 200, 0.0001))
end

--- A one shot signal shaped like RBXScriptSignal, so spring and tween handles
--- can be used interchangeably.
local function Finished()
	local Handlers = {}
	local Fired = false
	local Signal = {}

	function Signal:Connect(Handler)
		if Fired then
			task.spawn(Handler)
			return { Disconnect = function() end }
		end

		table.insert(Handlers, Handler)

		return {
			Disconnect = function()
				local At = table.find(Handlers, Handler)

				if At then
					table.remove(Handlers, At)
				end
			end,
		}
	end

	Signal.Once = Signal.Connect

	function Signal:Fire()
		if Fired then
			return
		end

		Fired = true

		for _, Handler in Handlers do
			task.spawn(Handler)
		end

		table.clear(Handlers)
	end

	return Signal
end

--- The one call the rest of the library animates through.
local function Tween(Object, Properties, Role)
	local Using = Spec(Role)

	if Using.Stiffness then
		local Signal = Finished()

		SpringTo(Object, Properties, Using.Stiffness, Using.Damping or 0, Signal)

		--- Belt and braces: a spring on an object that gets destroyed mid
		--- flight would otherwise never fire.
		task.delay(MotionTime(Using) * 2, function()
			Signal:Fire()
		end)

		return {
			Completed = Signal,

			--- Cancelling a spring means letting go of it where it stands.
			--- This used to be a no-op, which quietly made every cancel a lie.
			Cancel = function()
				for Property in Properties do
					Motion.Halt(Object, Property)
				end
			end,
		}
	end

	local Style, Direction = ResolveEasing(Using.Easing)

	local Handle = TweenService:Create(
		Object,
		TweenInfo.new(Using.Duration or 0, Style, Direction),
		Properties
	)

	Handle:Play()

	return Handle
end

--- Fades a property in from invisible on the next frame, so a thing built
--- during a burst of layout does not pop.
local function Enter(Object, Property, Target, Role)
	local Original = Object[Property]

	Object[Property] = 1

	task.defer(function()
		if Object.Parent then
			Tween(Object, { [Property] = Target or Original }, Role or "fade")
		end
	end)
end

--- Text swapped through a dip rather than snapping. The resting transparency
--- is remembered per label, weakly, because reading it back mid fade would
--- capture the wrong value.
local RestingText = setmetatable({}, { __mode = "k" })

local function SwapText(Label, NewText)
	if Label.Text == NewText then
		return
	end

	local Rest = RestingText[Label]

	if not Rest then
		Rest = Label.TextTransparency
		RestingText[Label] = Rest
	end

	Tween(Label, { TextTransparency = 1 }, "press")

	task.delay(MotionTime("press"), function()
		if not Label.Parent then
			return
		end

		Label.Text = NewText
		Tween(Label, { TextTransparency = Rest }, "hover")
	end)
end

--- The UIScale a whole object is scaled by, made on demand. One per object,
--- so two callers asking to scale the same thing drive the same scale rather
--- than fighting over two.
local function ScaleOf(Object)
	local Existing = Object:FindFirstChildOfClass("UIScale")

	if Existing then
		return Existing
	end

	local Scale = Instance.new("UIScale")
	Scale.Name = "Scale"
	Scale.Parent = Object

	return Scale
end

--- Declared ahead of Out, which fades before it is defined.
local Fade

--- Springs an object's overall scale. Scaling through a UIScale rather than a
--- Size keeps the layout underneath it untouched, so nothing reflows.
local function Scale(Object, Value, Role)
	return Tween(ScaleOf(Object), { Scale = Value }, Role or "pop")
end

--- Grows an object into place from slightly small and slightly faded. Called
--- on anything built while the interface is already on screen, so new things
--- arrive rather than appear.
local function Pop(Object, Role, From)
	local Scaler = ScaleOf(Object)

	Scaler.Scale = From or 0.94

	task.defer(function()
		if Object.Parent then
			Tween(Scaler, { Scale = 1 }, Role or "pop")
		end
	end)

	return Scaler
end

--- The mirror of Pop: shrink and fade out, then do the thing that was waiting
--- on it. Everything that removes something visible goes through here so a
--- thing never simply blinks out of existence.
local function Out(Object, Done, Role)
	if not Object or not Object.Parent then
		if Done then
			Done()
		end

		return
	end

	local Using = Role or "shrink"
	local Scaler = ScaleOf(Object)

	Tween(Scaler, { Scale = 0.92 }, Using)

	if Object:IsA("CanvasGroup") then
		Tween(Object, { GroupTransparency = 1 }, "fade")
	else
		Fade(Object, 1)
	end

	task.delay(MotionTime(Using), function()
		if Done then
			Done()
		end
	end)
end

--- Springs everything on an object that carries transparency toward one value,
--- so a fade does not need the caller to know what kind of thing it is.
function Fade(Object, To, Role)
	local Properties = {}

	if Object:IsA("GuiObject") and (Object.BackgroundTransparency or 1) < 1 then
		Properties.BackgroundTransparency = To
	end

	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		Properties.TextTransparency = To
	end

	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		Properties.ImageTransparency = To
	end

	if Object:IsA("CanvasGroup") then
		Properties.GroupTransparency = To
	end

	if next(Properties) then
		Tween(Object, Properties, Role or "fade")
	end

	for _, Child in Object:GetChildren() do
		if Child:IsA("GuiObject") then
			Fade(Child, To, Role)
		elseif Child:IsA("UIStroke") then
			Tween(Child, { Transparency = To }, Role or "fade")
		end
	end
end

--- Everything on an object and inside it that carries transparency, with the
--- value it is meant to rest at. Read before anything is touched, because once
--- the fade starts the resting values are gone.
local function Resting(Object, Into)
	Into = Into or {}

	local Bits = {}

	--- Guarded rather than assumed: a class can be a GuiObject and still not
	--- hand back the property, and a nil compared against a number throws.
	if Object:IsA("GuiObject") and (Object.BackgroundTransparency or 1) < 1 then
		Bits.BackgroundTransparency = Object.BackgroundTransparency
	end

	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		Bits.TextTransparency = Object.TextTransparency
	end

	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		Bits.ImageTransparency = Object.ImageTransparency
	end

	if Object:IsA("CanvasGroup") then
		Bits.GroupTransparency = Object.GroupTransparency
	end

	if next(Bits) then
		table.insert(Into, { Object = Object, Bits = Bits })
	end

	for _, Child in Object:GetChildren() do
		if Child:IsA("GuiObject") then
			Resting(Child, Into)
		elseif Child:IsA("UIStroke") then
			table.insert(Into, { Object = Child, Bits = { Transparency = Child.Transparency } })
		end
	end

	return Into
end

--- Fades a whole thing in from nothing, contents and all, optionally after a
--- wait. This is what a list of rows arriving is made of: the row's resting
--- transparencies are remembered, everything is pushed to invisible, and each
--- springs back to where it belongs.
local function FadeIn(Object, Delay, Role)
	local Marks = Resting(Object)

	for _, Mark in Marks do
		for Property in Mark.Bits do
			Mark.Object[Property] = 1
		end
	end

	local function Play()
		for _, Mark in Marks do
			if Mark.Object.Parent then
				Tween(Mark.Object, Mark.Bits, Role or "fade")
			end
		end
	end

	if Delay and Delay > 0 then
		task.delay(Delay, function()
			if Object.Parent then
				Play()
			end
		end)
	else
		task.defer(function()
			if Object.Parent then
				Play()
			end
		end)
	end

	return Marks
end

--- Stops whatever is animating an object, leaving it where it stands.
local function Halt(Object, Property)
	local Channels = Live[Object]

	if not Channels then
		return
	end

	if Property then
		Channels[Property] = nil
	else
		Live[Object] = nil
	end
end

--- A colour (or anything else) set that springs only when the caller asks for
--- it. A direct set has to stop any spring already running on that property,
--- or the spring lands on top of it a frame later and the set looks ignored.
local function Paint(Object, Properties, Animate, Role)
	if Animate then
		return Tween(Object, Properties, Role or "tint")
	end

	for Property, Value in Properties do
		Halt(Object, Property)
		Object[Property] = Value
	end

	return nil
end

Motion.Spec       = Spec
Motion.Paint      = Paint
Motion.Tween      = Tween
Motion.SpringTo   = SpringTo
Motion.MotionTime = MotionTime
Motion.Finished   = Finished
Motion.Enter      = Enter
Motion.SwapText   = SwapText
Motion.Halt       = Halt
Motion.KindOf     = KindOf
Motion.Easing     = ResolveEasing
Motion.ScaleOf    = ScaleOf
Motion.Scale      = Scale
Motion.Pop        = Pop
Motion.Out        = Out
Motion.Fade       = Fade
Motion.FadeIn     = FadeIn
Motion.Resting    = Resting

return Motion
