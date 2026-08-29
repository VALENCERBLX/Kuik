--!nonstrict
--[[
	Enough of the Roblox environment to construct the whole library headlessly
	under lune. It is not a renderer — AbsoluteSize/AbsolutePosition are
	always zero — so it catches syntax errors, bad property names on our side,
	nil indexing and broken control flow, not layout.
]]

local Shim = {}

--------------------------------------------------------------------------
-- Datatypes
--------------------------------------------------------------------------

local Color3Lib = {}
Color3Lib.__index = Color3Lib

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

local UDimLib = {}

function UDimLib.new(Scale, Offset)
	return { Scale = Scale or 0, Offset = Offset or 0 }
end

local UDim2Lib = {}

function UDim2Lib.new(XS, XO, YS, YO)
	return { X = UDimLib.new(XS, XO), Y = UDimLib.new(YS, YO) }
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

		return {
			Disconnect = function() end,
			Connected = true,
		}
	end

	function Self:Once(Handler)
		return Self:Connect(Handler)
	end

	function Self:Fire(...)
		for _, Handler in Handlers do
			Handler(...)
		end
	end

	Self.Handlers = Handlers

	return Self
end

Shim.Signal = Signal

local SignalNames = {
	MouseEnter = true, MouseLeave = true, Activated = true,
	InputBegan = true, InputChanged = true, InputEnded = true,
	FocusLost = true, Focused = true, Changed = true, MouseButton1Click = true,
	RenderStepped = true, Heartbeat = true,
}

--------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------

local InstanceMeta = {}

local function GetChildren(Self)
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
			for Index, Child in GetChildren(Old) do
				if Child == Self then
					table.remove(GetChildren(Old), Index)
					break
				end
			end
		end

		if Value then
			table.insert(GetChildren(Value), Self)
		end
	end

	Properties[Key] = Value
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
	})

	rawset(Self, "Methods", {
		Destroy = function()
			local Properties = rawget(Self, "Properties")
			local Parent = Properties.Parent

			if Parent then
				for Index, Child in GetChildren(Parent) do
					if Child == Self then
						table.remove(GetChildren(Parent), Index)
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

		FindFirstChild = function(_, Query)
			for _, Child in GetChildren(Self) do
				if rawget(Child, "Properties").Name == Query then
					return Child
				end
			end

			return nil
		end,

		GetPropertyChangedSignal = function()
			return Signal()
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

--------------------------------------------------------------------------
-- Install
--------------------------------------------------------------------------

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

	game = {
		GetService = function(_, Name)
			if not Services[Name] then
				Services[Name] = InstanceLib.new(Name)
			end

			return Services[Name]
		end,
	}

	local Camera = InstanceLib.new("Camera")

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

		delay = function(_, Callback, ...)
			if Callback then
				local Thread = coroutine.create(Callback)
				local Ok, Err = coroutine.resume(Thread, ...)

				if not Ok then
					error(Err, 0)
				end
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
