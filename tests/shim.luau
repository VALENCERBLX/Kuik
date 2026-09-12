--!nonstrict
--[[
	Enough of the Roblox environment to construct the whole library headlessly
	under lune. It is not a renderer — AbsoluteSize/AbsolutePosition are
	always zero — so it catches syntax errors, bad property names on our side,
	nil indexing and broken control flow, not layout.
]]

local Shim = {}

--- Keys a test wants to pretend are held down. Declared up here because the
--- input service closure below reads it.
Shim.Held = {}

--- The clock. Off by default so task.delay stays eager for the tests that were
--- written against that; on, delays queue here and Shim.Advance runs them.
Shim.Clocked = false
Shim.Now = 0
Shim.Timers = {}

--------------------------------------------------------------------------
-- Datatypes
--------------------------------------------------------------------------

local Color3Lib = {}
Color3Lib.__index = Color3Lib

Color3Lib.__eq = function(A, B)
	return A.R == B.R and A.G == B.G and A.B == B.B
end

function Color3Lib.new(R, G, B)
	return setmetatable({ R = R or 0, G = G or 0, B = B or 0 }, Color3Lib)
end

function Color3Lib.fromRGB(R, G, B)
	return Color3Lib.new((R or 0) / 255, (G or 0) / 255, (B or 0) / 255)
end

function Color3Lib.fromHSV(H, S, V)
	local I = math.floor((H or 0) * 6)
	local F = (H or 0) * 6 - I
	local P = V * (1 - S)
	local Q = V * (1 - F * S)
	local T = V * (1 - (1 - F) * S)
	local Mod = I % 6

	if Mod == 0 then return Color3Lib.new(V, T, P)
	elseif Mod == 1 then return Color3Lib.new(Q, V, P)
	elseif Mod == 2 then return Color3Lib.new(P, V, T)
	elseif Mod == 3 then return Color3Lib.new(P, Q, V)
	elseif Mod == 4 then return Color3Lib.new(T, P, V)
	end

	return Color3Lib.new(V, P, Q)
end

function Color3Lib:ToHSV()
	local R, G, B = self.R, self.G, self.B
	local High = math.max(R, G, B)
	local Low = math.min(R, G, B)
	local Delta = High - Low

	local H = 0

	if Delta > 0 then
		if High == R then
			H = ((G - B) / Delta) % 6
		elseif High == G then
			H = (B - R) / Delta + 2
		else
			H = (R - G) / Delta + 4
		end

		H /= 6
	end

	return H, High > 0 and Delta / High or 0, High
end

local ColorSequenceKeypointLib = {}

function ColorSequenceKeypointLib.new(Time, Value)
	return { Time = Time, Value = Value }
end

local ColorSequenceLib = {}

function ColorSequenceLib.new(Keys)
	if type(Keys) == "table" and Keys.R then
		return { Keypoints = { { Time = 0, Value = Keys }, { Time = 1, Value = Keys } } }
	end

	return { Keypoints = Keys }
end

local NumberSequenceKeypointLib = {}

function NumberSequenceKeypointLib.new(Time, Value)
	return { Time = Time, Value = Value }
end

local NumberSequenceLib = {}

function NumberSequenceLib.new(Keys)
	if type(Keys) == "number" then
		return { Keypoints = { { Time = 0, Value = Keys }, { Time = 1, Value = Keys } } }
	end

	return { Keypoints = Keys }
end

local Vector2Lib = {}
Vector2Lib.__index = Vector2Lib

function Vector2Lib.new(X, Y)
	X, Y = X or 0, Y or 0

	return setmetatable({
		X = X,
		Y = Y,
		Magnitude = math.sqrt(X * X + Y * Y),
	}, Vector2Lib)
end

function Vector2Lib.__add(A, B)
	return Vector2Lib.new(A.X + B.X, A.Y + B.Y)
end

function Vector2Lib.__sub(A, B)
	return Vector2Lib.new(A.X - B.X, A.Y - B.Y)
end

function Vector2Lib.__mul(A, B)
	if type(B) == "number" then
		return Vector2Lib.new(A.X * B, A.Y * B)
	end

	return Vector2Lib.new(A.X * B.X, A.Y * B.Y)
end

function Vector2Lib:Lerp(Other, Alpha)
	return Vector2Lib.new(
		self.X + (Other.X - self.X) * Alpha,
		self.Y + (Other.Y - self.Y) * Alpha
	)
end

Vector2Lib.zero = Vector2Lib.new(0, 0)

local Vector3Lib = {}
Vector3Lib.__index = Vector3Lib

function Vector3Lib.new(X, Y, Z)
	X, Y, Z = X or 0, Y or 0, Z or 0

	return setmetatable({
		X = X, Y = Y, Z = Z,
		Magnitude = math.sqrt(X * X + Y * Y + Z * Z),
	}, Vector3Lib)
end

Vector3Lib.zero = Vector3Lib.new(0, 0, 0)

local CFrameLib = {}
CFrameLib.__index = CFrameLib

function CFrameLib.new(X, Y, Z)
	return setmetatable({
		Position = type(X) == "table" and X or Vector3Lib.new(X, Y, Z),
		LookVector = Vector3Lib.new(0, 0, -1),
	}, CFrameLib)
end

function CFrameLib.fromEulerAnglesYXZ()
	return CFrameLib.new()
end

function CFrameLib.lookAt(From)
	return CFrameLib.new(From)
end

CFrameLib.__mul = function()
	return CFrameLib.new()
end

local UDimLib = {}
UDimLib.__index = UDimLib

function UDimLib.new(Scale, Offset)
	return setmetatable({ Scale = Scale or 0, Offset = Offset or 0 }, UDimLib)
end

local UDim2Lib = {}
UDim2Lib.__index = UDim2Lib

function UDim2Lib.new(XS, XO, YS, YO)
	return setmetatable({ X = UDimLib.new(XS, XO), Y = UDimLib.new(YS, YO) }, UDim2Lib)
end

function UDim2Lib.fromOffset(X, Y)
	return UDim2Lib.new(0, X, 0, Y)
end

local TweenInfoLib = {}

function TweenInfoLib.new(...)
	return { Arguments = { ... } }
end

--- Enum.Anything.Anything resolves to a stub carrying its own name.
local EnumItemMeta = { __tostring = function(Self) return Self.Name end }

local EnumCategoryMeta = {
	__index = function(Self, Key)
		local Item = setmetatable({ Name = Key, Value = 0 }, EnumItemMeta)
		rawset(Self, Key, Item)
		return Item
	end,
}

local EnumLib = setmetatable({}, {
	__index = function(Self, Key)
		local Category = setmetatable({}, EnumCategoryMeta)
		rawset(Self, Key, Category)
		return Category
	end,
})

local FontLib = {}

function FontLib.fromName(Name, Weight)
	return { Family = Name, Weight = Weight }
end

function FontLib.fromEnum(Item)
	return { Family = tostring(Item) }
end

--------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------

local function Signal()
	local Handlers = {}

	local Self = {}

	function Self:Connect(Handler)
		table.insert(Handlers, Handler)

		local Link = { Connected = true }

		--- A real disconnect, not a stub. Leaving it a no-op meant a handler
		--- that let go of its own connection kept being called afterwards, and
		--- anything that leaked a connection looked fine here.
		function Link.Disconnect()
			local At = table.find(Handlers, Handler)

			if At then
				table.remove(Handlers, At)
			end

			Link.Connected = false
		end

		return Link
	end

	function Self:Once(Handler)
		return Self:Connect(Handler)
	end

	function Self:Fire(...)
		--- Over a copy: a handler is allowed to disconnect itself, and removing
		--- from the list being walked would skip the one after it.
		for _, Handler in table.clone(Handlers) do
			Handler(...)
		end
	end

	Self.Handlers = Handlers

	return Self
end

Shim.Signal = Signal

local SignalNames = {
	MouseEnter = true, MouseLeave = true, MouseMoved = true, Activated = true,
	InputBegan = true, InputChanged = true, InputEnded = true,
	FocusLost = true, Focused = true, Changed = true, MouseButton1Click = true,
	Ended = true, Loaded = true, DidLoop = true, Paused = true, Played = true,
	RenderStepped = true, Heartbeat = true,
}

--------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------

local InstanceMeta = {}

--- A copy, the way Roblox returns one. Handing back the live list let a loop
--- that destroys as it goes skip every child that shuffled down — which is a
--- real bug shape the library has hit before, and one the shim was hiding
--- rather than reproducing.
local function GetChildren(Self)
	return table.clone(rawget(Self, "Children"))
end

--- The live list, for the shim's own bookkeeping.
local function LiveChildren(Self)
	return rawget(Self, "Children")
end

InstanceMeta.__index = function(Self, Key)
	local Properties = rawget(Self, "Properties")

	if Properties[Key] ~= nil then
		return Properties[Key]
	end

	if SignalNames[Key] then
		local Event = Signal()
		Properties[Key] = Event
		return Event
	end

	local Methods = rawget(Self, "Methods")

	return Methods[Key]
end

InstanceMeta.__newindex = function(Self, Key, Value)
	local Properties = rawget(Self, "Properties")

	if Key == "Parent" then
		local Old = Properties.Parent

		if Old then
			for Index, Child in LiveChildren(Old) do
				if Child == Self then
					table.remove(LiveChildren(Old), Index)
					break
				end
			end
		end

		if Value then
			table.insert(LiveChildren(Value), Self)
		end
	end

	local Was = Properties[Key]

	Properties[Key] = Value

	--- Anyone watching this property hears about it, the way Roblox does it.
	--- Compared first so a write of the same value is not an event: a driver
	--- that reacts by writing back would otherwise never stop.
	if Was ~= Value then
		local Watchers = rawget(Self, "Watchers")
		local Signal_ = Watchers and Watchers[Key]

		if Signal_ then
			Signal_:Fire()
		end
	end
end

InstanceMeta.__tostring = function(Self)
	return rawget(Self, "Properties").ClassName
end

local InstanceLib = {}

function InstanceLib.new(ClassName)
	local Self = setmetatable({}, InstanceMeta)

	rawset(Self, "Children", {})
	rawset(Self, "Properties", {
		ClassName        = ClassName,
		Name             = ClassName,
		Parent           = nil,
		Visible          = true,
		Enabled          = true,
		Text             = "",
		Position           = UDim2Lib.new(0, 0, 0, 0),
		Size               = UDim2Lib.new(0, 0, 0, 0),
		AnchorPoint        = Vector2Lib.new(0, 0),
		AbsoluteSize       = Vector2Lib.new(0, 0),
		AbsolutePosition   = Vector2Lib.new(0, 0),
		AbsoluteCanvasSize = Vector2Lib.new(0, 0),
		CanvasPosition     = Vector2Lib.new(0, 0),
		GroupTransparency  = 0,

		--- Every transparency Roblox defaults to zero, defaulted to zero here
		--- too. Leaving them nil made "is this visible" checks compare nil
		--- against a number, which throws rather than failing — so a real bug
		--- and a missing default looked the same.
		BackgroundTransparency = 1,
		TextTransparency       = 0,
		TextStrokeTransparency = 1,
		ImageTransparency      = 0,
		Transparency           = 0,

		TimeLength         = 0,
		TimePosition       = 0,
		Rotation           = 0,
		ZIndex             = 1,
		LayoutOrder        = 0,
		IsLoaded           = true,
		Scale              = 1,
	})

	rawset(Self, "Methods", {
		Destroy = function()
			local Properties = rawget(Self, "Properties")
			local Parent = Properties.Parent

			if Parent then
				for Index, Child in LiveChildren(Parent) do
					if Child == Self then
						table.remove(LiveChildren(Parent), Index)
						break
					end
				end
			end

			rawset(Self, "Children", {})
			Properties.Parent = nil
		end,

		GetChildren = function()
			return GetChildren(Self)
		end,

		ClearAllChildren = function()
			for _, Child in table.clone(GetChildren(Self)) do
				Child:Destroy()
			end

			rawset(Self, "Children", {})
		end,

		GetDescendants = function()
			local Out = {}

			local function Walk(Node)
				for _, Child in GetChildren(Node) do
					table.insert(Out, Child)
					Walk(Child)
				end
			end

			Walk(Self)

			return Out
		end,

		IsA = function(_, Query)
			local Class = rawget(Self, "Properties").ClassName

			if Class == Query then
				return true
			end

			--- Just enough of the hierarchy for what the library asks about.
			if Query == "Frame" then
				return Class == "Frame" or Class == "CanvasGroup"
			end

			if Query == "GuiObject" then
				return string.find(Class, "Frame") ~= nil
					or string.find(Class, "Label") ~= nil
					or string.find(Class, "Button") ~= nil
					or Class == "CanvasGroup"
					or Class == "TextBox"
					or Class == "ScrollingFrame"
			end

			return false
		end,

		FindFirstChildOfClass = function(_, Query)
			for _, Child in GetChildren(Self) do
				if rawget(Child, "Properties").ClassName == Query then
					return Child
				end
			end

			return nil
		end,

		FindFirstChildWhichIsA = function(_, Query)
			for _, Child in GetChildren(Self) do
				if Child:IsA(Query) then
					return Child
				end
			end

			return nil
		end,

		FindFirstChild = function(_, Query, Deep)
			for _, Child in GetChildren(Self) do
				if rawget(Child, "Properties").Name == Query then
					return Child
				end
			end

			if Deep then
				for _, Child in GetChildren(Self) do
					local Found = Child:FindFirstChild(Query, true)

					if Found then
						return Found
					end
				end
			end

			return nil
		end,

		--- A real one, cached per property and fired on assignment.
		---
		--- Returning a fresh dead signal each call meant nothing that watches
		--- geometry could be tested at all — and a great deal of this library
		--- watches geometry: rules driven off a sibling's height, edge lights
		--- tracking a scroller, a reveal waiting for its first layout.
		GetPropertyChangedSignal = function(_, Property)
			local Watchers = rawget(Self, "Watchers")

			if not Watchers then
				Watchers = {}
				rawset(Self, "Watchers", Watchers)
			end

			if not Watchers[Property] then
				Watchers[Property] = Signal()
			end

			return Watchers[Property]
		end,

		--- Sound and VideoFrame transport, enough to build and drive them.
		Play = function() end,
		Pause = function() end,
		Resume = function() end,
		Stop = function() end,
		Clone = function()
			return InstanceLib.new(rawget(Self, "Properties").ClassName)
		end,
		GetBoundingBox = function()
			return CFrameLib.new(), Vector3Lib.new(1, 1, 1)
		end,
	})

	return Self
end

Shim.InstanceLib = InstanceLib

--------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------

local PlayerGui = InstanceLib.new("PlayerGui")

local Services = {}

Services.TweenService = {
	Create = function(_, Object, Info, Properties)
		--- Apply instantly. Tests care about the end state, not the curve.
		return {
			Play = function()
				for Key, Value in Properties do
					Object[Key] = Value
				end
			end,
			Completed = Signal(),
		}
	end,
}

Services.UserInputService = {
	InputBegan   = Signal(),
	InputChanged = Signal(),
	InputEnded   = Signal(),
	GetMouseLocation = function()
		return Vector2Lib.new(0, 0)
	end,

	--- Held keys are a test fixture: set Shim.Held[Enum.KeyCode.X] = true.
	IsKeyDown = function(_, Key)
		return Shim.Held[Key] == true
	end,
}

Services.GuiService = {
	GetGuiInset = function()
		return Vector2Lib.new(0, 36), Vector2Lib.new(0, 0)
	end,
}

Services.RunService = {
	RenderStepped = Signal(),
	Heartbeat     = Signal(),
}

Services.Lighting = InstanceLib.new("Lighting")

Services.Players = {
	LocalPlayer = (function()
		local Player = InstanceLib.new("Player")
		PlayerGui.Parent = Player
		return Player
	end)(),
}

Shim.Services = Services
Shim.PlayerGui = PlayerGui

--- Drives the library's Heartbeat spring loop by hand, since a headless test
--- has no frames. Enough steps and every spring in flight settles on its goal,
--- which is what makes the motion layer testable at all.
function Shim.Step(Count, Delta)
	for _ = 1, Count or 240 do
		Services.RunService.Heartbeat:Fire(Delta or 1 / 30)
	end
end

--- Runs time forward: steps the spring driver a frame at a time and fires every
--- queued callback as its moment arrives, in the order the moments come. This is
--- what makes a choreography testable — that the width finishes before the
--- height starts, that the plate is still there while the panel is still hidden.
function Shim.Advance(Seconds, Rate)
	local Step = 1 / (Rate or 24)
	local Until = Shim.Now + Seconds

	while Shim.Now < Until - 1e-9 do
		Shim.Now += Step

		--- Due first, then the frame: a callback that starts a spring should
		--- have that spring stepped on the same frame it started.
		local Due = {}

		for Index = #Shim.Timers, 1, -1 do
			local Timer = Shim.Timers[Index]

			if Timer.At <= Shim.Now then
				table.insert(Due, Timer)
				table.remove(Shim.Timers, Index)
			end
		end

		table.sort(Due, function(A, B) return A.At < B.At end)

		for _, Timer in Due do
			local Thread = coroutine.create(Timer.Callback)
			local Ok, Err = coroutine.resume(Thread, table.unpack(Timer.Arguments, 1, Timer.Arguments.n))

			if not Ok then
				error(Err, 0)
			end
		end

		Services.RunService.Heartbeat:Fire(Step)
	end
end

--- Back to nothing pending, for a suite that runs several scenarios.
function Shim.Reset()
	Shim.Now = 0
	table.clear(Shim.Timers)
end

--------------------------------------------------------------------------
-- Install
--------------------------------------------------------------------------

--- Note: typeof cannot be shimmed. Luau treats it as a builtin and inlines
--- the call, so assigning the global has no effect and every shim value still
--- answers "table". Anything in the library that has to work headlessly must
--- therefore not depend on typeof to recognise a value.
function Shim.Install()
	Color3    = Color3Lib
	Vector2   = Vector2Lib
	UDim      = UDimLib
	UDim2     = UDim2Lib
	TweenInfo = TweenInfoLib
	Enum      = EnumLib
	Font      = FontLib
	Instance  = InstanceLib
	ColorSequence = ColorSequenceLib
	ColorSequenceKeypoint = ColorSequenceKeypointLib
	NumberSequence = NumberSequenceLib
	NumberSequenceKeypoint = NumberSequenceKeypointLib
	Vector3   = Vector3Lib
	CFrame    = CFrameLib

	game = {
		GetService = function(_, Name)
			if not Services[Name] then
				Services[Name] = InstanceLib.new(Name)
			end

			return Services[Name]
		end,
	}

	local Camera = InstanceLib.new("Camera")
	Camera.CFrame = CFrameLib.new()
	Camera.ViewportSize = Vector2Lib.new(1280, 720)

	workspace = {
		CurrentCamera = Camera,
	}

	--- lune exposes task as a module rather than a global. delay/defer are
	--- run eagerly so the test sees their effects without yielding.
	--- spawn/defer run on a real coroutine so a callback that loops on
	--- task.wait (the Spinner's animation) suspends after one pass instead of
	--- hanging the test. Everything that does not yield still runs
	--- synchronously, so callback assertions stay valid.
	task = {
		spawn = function(Callback, ...)
			local Thread = coroutine.create(Callback)
			local Ok, Err = coroutine.resume(Thread, ...)

			if not Ok then
				error(Err, 0)
			end

			return Thread
		end,

		defer = function(Callback, ...)
			local Thread = coroutine.create(Callback)
			local Ok, Err = coroutine.resume(Thread, ...)

			if not Ok then
				error(Err, 0)
			end

			return Thread
		end,

		--- Eager by default, which is what most of the suite expects: a delayed
		--- callback happens now and the assertion after it can see the result.
		--- Turn Shim.Clocked on and delays are queued against a clock instead,
		--- which is the only way to test an animation whose whole point is that
		--- one thing happens before another.
		delay = function(Seconds, Callback, ...)
			if not Callback then
				return
			end

			if Shim.Clocked then
				table.insert(Shim.Timers, {
					At       = Shim.Now + math.max(0, Seconds or 0),
					Callback = Callback,
					Arguments = table.pack(...),
				})

				return
			end

			local Thread = coroutine.create(Callback)
			local Ok, Err = coroutine.resume(Thread, ...)

			if not Ok then
				error(Err, 0)
			end
		end,

		--- Yields forever: a headless test has no frames to wait for.
		wait = function()
			coroutine.yield()
		end,
	}

	return Shim
end

--- Counts every instance created under the shared ScreenGui.
function Shim.Count(Root)
	local Total = 0

	local function Walk(Node)
		for _, Child in GetChildren(Node) do
			Total += 1
			Walk(Child)
		end
	end

	Walk(Root)

	return Total
end

return Shim
