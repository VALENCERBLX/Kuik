--!nonstrict
-- Kuik 1.0.0 — built from init.luau by tools/build.py.
-- Comments are stripped so the source fits Roblox's 200,000 character
-- limit for a ModuleScript Source assignment. Read init.luau instead.
local TweenService     = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VERSION = {
	Name    = "Kuik",
	Version = "1.0.0",
}
local Theme = {
	Font       = Font.fromName("Montserrat", Enum.FontWeight.Regular),
	FontMedium = Font.fromName("Montserrat", Enum.FontWeight.Medium),
	FontBold   = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
	FontMono   = Font.fromEnum(Enum.Font.Code),
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(20, 20, 20),
	Scrim = Color3.fromRGB(8, 8, 10),
	TextPrimary   = 0.00,
	TextSecondary = 0.42,
	TextTertiary  = 0.58,
	TextDisabled  = 0.72,
	RuleTransparency = 0.45,
	RowTransparency      = 0.94,
	RowHoverTransparency = 0.88,
	ChipTransparency = 0.45,
	Danger  = Color3.fromRGB(255, 72, 72),
	Warn    = Color3.fromRGB(255, 176, 46),
	Info    = Color3.fromRGB(96, 156, 255),
	Good    = Color3.fromRGB(96, 210, 128),
	Neutral = Color3.fromRGB(255, 255, 255),
	Motion = {
		instant = { Duration = 0 },
		enter  = { Duration = 0.46, Easing = "outQuint" },
		exit   = { Duration = 0.38, Easing = "outQuad" },
		expand = { Duration = 0.34, Easing = "outQuint" },
		hover  = { Duration = 0.12, Easing = "outQuad" },
		press  = { Duration = 0.07, Easing = "outQuad" },
		fade   = { Duration = 0.34, Easing = "outQuad" },
		hint   = { Duration = 0.22, Easing = "outQuad" },
		item   = { Duration = 0.30, Easing = "outQuad" },
		list   = { Duration = 0.28, Easing = "outQuad" },
		drop   = { Duration = 0.46, Easing = "outBack" },
		layout = { Stiffness = 190, Damping = 24 },
		morph  = { Stiffness = 210, Damping = 26 },
		drag   = { Stiffness = 620, Damping = 42 },
		toss   = { Stiffness = 340, Damping = 22 },
		reveal = { Stiffness = 150, Damping = 20 },
		snap   = { Stiffness = 600, Damping = 40 },
		scroll = { Stiffness = 300, Damping = 38 },
	},
}
local Metrics = {
	WindowWidth   = 460,
	WindowHeight  = 500,
	WindowPadding = 26,
	TitleSize    = 27,
	SubtitleSize = 14,
	SectionTitleSize = 18,
	SectionDescSize  = 12,
	RowLabelSize = 16,
	RowDescSize  = 11,
	RowHeight    = 46,
	RowHeightTall = 62,
	RowGap       = 8,
	RowRadius    = 4,
	CardRadius   = 8,
	PillRadius   = 999,
	TabHeight  = 30,
	TabPadding = 14,
	TabGap     = 6,
	TabIcon    = 14,
	ToggleWidth  = 50,
	ToggleHeight = 25,
	KnobInset    = 3,
	SliderTrack = 3,
	SliderThumbWidth  = 4,
	SliderThumbHeight = 15,
	ChipWidth  = 52,
	ChipHeight = 23,
	ChipRadius = 5,
	MonoSize = 10,
}
local function New(ClassName, Properties, Children)
	local Object = Instance.new(ClassName)
	for Key, Value in Properties or {} do
		if Key ~= "Parent" then
			Object[Key] = Value
		end
	end
	for _, Child in Children or {} do
		Child.Parent = Object
	end
	if Properties and Properties.Parent then
		Object.Parent = Properties.Parent
	end
	return Object
end
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
				Object[Property] = Channel.Goal
				Channels[Property] = nil
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
local function SpringTo(Object, Properties, Stiffness, Damping)
	local Channels = Live[Object]
	if not Channels then
		Channels = {}
		Live[Object] = Channels
	end
	for Property, Goal in Properties do
		local Kind = Parts[typeof(Goal)]
		if Kind then
			local Wanted = Kind.Split(Goal)
			local Channel = Channels[Property]
			if Channel and #Channel.Springs == #Wanted and Channel.Type == typeof(Goal) then
				for Index, Each in Channel.Springs do
					Each:Retune(Stiffness, Damping)
					Each.Target = Wanted[Index]
				end
				Channel.Goal = Goal
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
					Type    = typeof(Goal),
					Goal    = Goal,
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
local function MotionTime(Role)
	local Using = Spec(Role)
	if Using.Duration then
		return Using.Duration
	end
	return 6 / math.sqrt(math.max(Using.Stiffness or 200, 0.0001))
end
local function Finished()
	local Handlers = {}
	local Signal = {}
	function Signal:Connect(Handler)
		table.insert(Handlers, Handler)
		return { Disconnect = function() end }
	end
	Signal.Once = Signal.Connect
	function Signal:Fire()
		for _, Handler in Handlers do
			task.spawn(Handler)
		end
	end
	return Signal
end
local function Tween(Object, Properties, Role)
	local Using = Spec(Role)
	if Using.Stiffness then
		SpringTo(Object, Properties, Using.Stiffness, Using.Damping or 0)
		local Signal = Finished()
		task.delay(2 / math.sqrt(math.max(Using.Stiffness, 0.0001)) * 3, function()
			Signal:Fire()
		end)
		return { Completed = Signal, Cancel = function() end }
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
local function Clamp(Value, Minimum, Maximum)
	return math.max(Minimum, math.min(Maximum, Value))
end
local function Quantise(Value, Step)
	if not Step or Step <= 0 then
		return Value
	end
	return math.floor(Value / Step + 0.5) * Step
end
local function FormatNumber(Value, Step)
	if Step and Step < 1 then
		local Decimals = math.max(0, math.ceil(-math.log(Step, 10)))
		local Text = string.format("%." .. Decimals .. "f", Value)
		Text = string.gsub(Text, "%.?0+$", "")
		return Text == "" and "0" or Text
	end
	return tostring(math.floor(Value + 0.5))
end
local function Corner(Radius)
	return New("UICorner", { CornerRadius = UDim.new(0, Radius) })
end
local function Padding(Top, Right, Bottom, Left)
	return New("UIPadding", {
		PaddingTop    = UDim.new(0, Top),
		PaddingRight  = UDim.new(0, Right or Top),
		PaddingBottom = UDim.new(0, Bottom or Top),
		PaddingLeft   = UDim.new(0, Left or Right or Top),
	})
end
local function List(Gap, Direction, Alignment)
	return New("UIListLayout", {
		Padding              = UDim.new(0, Gap or 0),
		FillDirection        = Direction or Enum.FillDirection.Vertical,
		SortOrder            = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment  = Alignment or Enum.HorizontalAlignment.Left,
	})
end
local function Enter(Object, Property, Target, Role)
	local Original = Object[Property]
	Object[Property] = 1
	task.defer(function()
		if Object.Parent then
			Tween(Object, { [Property] = Target or Original }, Role or "fade")
		end
	end)
end
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
local function Rule(Parent, Anchor, LayoutOrder)
	return New("Frame", {
		Name                   = "Rule",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Anchor or Vector2.new(0, 0),
		Size                   = UDim2.new(0, 1, 1, 0),
		LayoutOrder            = LayoutOrder or 0,
		ZIndex                 = 2,
	})
end
local function Text(Properties)
	local Label = New("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		TextColor3             = Theme.White,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Top,
		FontFace               = Theme.Font,
		TextSize               = Metrics.RowLabelSize,
		RichText               = true,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	})
	for Key, Value in Properties or {} do
		if Key ~= "Parent" then
			Label[Key] = Value
		end
	end
	if Properties and Properties.Parent then
		Label.Parent = Properties.Parent
	end
	return Label
end
local function Glyph(Parent, Size, Alpha)
	local Holder = New("Frame", {
		Name                   = "Glyph",
		Parent                 = Parent,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, Size, 0, Size),
	})
	local Widths = { 1.0, 0.7, 0.85 }
	for Index, Fraction in Widths do
		New("Frame", {
			Name                   = "Bar" .. Index,
			Parent                 = Holder,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Alpha or Theme.TextTertiary,
			BorderSizePixel        = 0,
			Position               = UDim2.new(0, 0, 0, math.floor(Size * 0.28) + (Index - 1) * 3),
			Size                   = UDim2.new(Fraction, 0, 0, 1),
		})
	end
	return Holder
end
local function Keycap(Parent, Size)
	local Cap = New("Frame", {
		Name                   = "Keycap",
		Parent                 = Parent,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, Size, 0, math.floor(Size * 0.72)),
	}, {
		Corner(2),
		New("UIStroke", {
			Color        = Theme.White,
			Transparency = Theme.TextTertiary,
			Thickness    = 1,
		}),
	})
	for Index = 1, 2 do
		New("Frame", {
			Parent                 = Cap,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.TextTertiary,
			BorderSizePixel        = 0,
			Position               = UDim2.new(0.22, 0, 0.28 + (Index - 1) * 0.28, 0),
			Size                   = UDim2.new(0.56, 0, 0, 1),
		})
	end
	return Cap
end
local function Gleam(Frame, Vertical, Depth)
	local Parent = Frame.Parent
	if not Parent then
		return function() end
	end
	Depth = Depth or 22
	local Base = 0.86
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
			BackgroundColor3       = Theme.White,
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
	local function Layout()
		local Position, Size = Frame.Position, Frame.Size
		if Vertical then
			Head.Position = Position
			Head.Size = UDim2.new(Size.X.Scale, Size.X.Offset, 0, Depth)
			Tail.AnchorPoint = Vector2.new(0, 1)
			Tail.Position = UDim2.new(
				Position.X.Scale, Position.X.Offset,
				Position.Y.Scale + Size.Y.Scale, Position.Y.Offset + Size.Y.Offset)
			Tail.Size = UDim2.new(Size.X.Scale, Size.X.Offset, 0, Depth)
		else
			Head.Position = Position
			Head.Size = UDim2.new(0, Depth, Size.Y.Scale, Size.Y.Offset)
			Tail.AnchorPoint = Vector2.new(1, 0)
			Tail.Position = UDim2.new(
				Position.X.Scale + Size.X.Scale, Position.X.Offset + Size.X.Offset,
				Position.Y.Scale, Position.Y.Offset)
			Tail.Size = UDim2.new(0, Depth, Size.Y.Scale, Size.Y.Offset)
		end
	end
	local Motion = 0
	local Before, After = false, false
	local function Update()
		local Span = Vertical
			and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
			or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X
		local At = Vertical and Frame.CanvasPosition.Y or Frame.CanvasPosition.X
		Before = Span > 2 and At > 2
		After = Span > 2 and (Span - At) > 2
		Tween(Head, { GroupTransparency = Before and Motion or 1 }, "fade")
		Tween(Tail, { GroupTransparency = After and Motion or 1 }, "fade")
	end
	local Settle = 0
	local function Nudge()
		Motion = 0.55
		Settle += 1
		local Mine = Settle
		Tween(Head, { GroupTransparency = Before and Motion or 1 }, "hover")
		Tween(Tail, { GroupTransparency = After and Motion or 1 }, "hover")
		task.delay(MotionTime("scroll") * 0.9, function()
			if Settle == Mine then
				Motion = 0
				Update()
			end
		end)
	end
	local Connections = {
		Frame:GetPropertyChangedSignal("Position"):Connect(Layout),
		Frame:GetPropertyChangedSignal("Size"):Connect(Layout),
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
local Hovered = nil
local function SmoothScroll(Frame, Axis, Options)
	local Handle = { Frame = Frame, Enabled = true }
	local Vertical = Axis ~= "X"
	if not (Options and Options.Gleam == false) then
		Handle.StopGleam, Handle.Nudge = Gleam(Frame, Vertical, Options and Options.Depth)
	end
	if not UserInputService.MouseEnabled then
		function Handle:SetEnabled() end
		function Handle:To() end
		function Handle:Sync() end
		return Handle
	end
	Frame.ScrollingEnabled = false
	local Target = Frame.CanvasPosition
	function Handle:SetEnabled(Value)
		Handle.Enabled = Value
	end
	function Handle:To(Position)
		Target = Position
		Tween(Frame, { CanvasPosition = Target }, "scroll")
	end
	function Handle:Sync()
		Target = Frame.CanvasPosition
	end
	Frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		local Span = Vertical
			and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
			or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X
		Span = math.max(0, Span)
		if Vertical and Target.Y > Span then
			Handle:To(Vector2.new(0, Span))
		elseif not Vertical and Target.X > Span then
			Handle:To(Vector2.new(Span, 0))
		end
	end)
	local Driving = false
	local Token = 0
	Frame.MouseEnter:Connect(function()
		Hovered = Frame
	end)
	Frame.MouseLeave:Connect(function()
		if Hovered == Frame then
			Hovered = nil
		end
	end)
	Frame.InputChanged:Connect(function(Input)
		if not Handle.Enabled or Input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end
		if Hovered and Hovered ~= Frame then
			return
		end
		local Span = Vertical
			and Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteSize.Y
			or Frame.AbsoluteCanvasSize.X - Frame.AbsoluteSize.X
		if Span <= 0 then
			return
		end
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
	end)
	return Handle
end
local ScreenGui = nil
local function Screen()
	if ScreenGui and ScreenGui.Parent then
		return ScreenGui
	end
	local Parent = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
	ScreenGui = New("ScreenGui", {
		Name             = "Kuik",
		Parent           = Parent,
		ResetOnSpawn     = false,
		IgnoreGuiInset   = true,
		ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
		DisplayOrder     = 50,
	})
	return ScreenGui
end
local function Row(Parent, Options)
	local HasDescription = Options.Description ~= nil and Options.Description ~= ""
	local Frame = New("Frame", {
		Name                   = "Row",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Options.Flat and 1 or Theme.RowTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, HasDescription and Metrics.RowHeightTall or Metrics.RowHeight),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Metrics.RowRadius),
		Padding(0, 14, 0, 14),
	})
	local TextColumn = New("Frame", {
		Name                   = "Text",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(1, -Metrics.ToggleWidth - 18, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		List(2),
	})
	local Label = Text({
		Parent         = TextColumn,
		Text           = Options.Label or "",
		TextSize       = Metrics.RowLabelSize,
		TextTransparency = Theme.TextPrimary,
		LayoutOrder    = 1,
	})
	local Description = nil
	if HasDescription then
		Description = Text({
			Parent           = TextColumn,
			Text             = Options.Description,
			TextSize         = Metrics.RowDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	local Mount = New("Frame", {
		Name                   = "Mount",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Metrics.ToggleWidth, 1, 0),
		ZIndex                 = 2,
	})
	if not Options.Flat then
		Frame.MouseEnter:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowHoverTransparency }, "hover")
		end)
		Frame.MouseLeave:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowTransparency }, "hover")
		end)
		Enter(Frame, "BackgroundTransparency", Theme.RowTransparency, "fade")
	end
	return {
		Frame       = Frame,
		Mount       = Mount,
		Label       = Label,
		Description = Description,
		TextColumn  = TextColumn,
	}
end
local Controls = {}
local Attach
local SlidingMark
local Layered
function Controls.Toggle(Container, Options)
	local Handle = {}
	local Value = Options.Default == true
	local Built = Row(Container, Options)
	local Track = New("Frame", {
		Name             = "Track",
		Parent           = Built.Mount,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, 0, 0.5, 0),
		Size             = UDim2.new(0, Metrics.ToggleWidth, 0, Metrics.ToggleHeight),
	}, {
		Corner(math.min(Metrics.PillRadius, math.floor(Metrics.ToggleHeight / 2))),
	})
	local KnobSize = Metrics.ToggleHeight - Metrics.KnobInset * 2
	local Knob = New("Frame", {
		Name             = "Knob",
		Parent           = Track,
		BackgroundColor3 = Theme.Black,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.new(0, Metrics.KnobInset, 0.5, 0),
		Size             = UDim2.new(0, KnobSize, 0, KnobSize),
	}, {
		Corner(math.min(Metrics.PillRadius, math.floor(KnobSize / 2))),
	})
	local Button = New("TextButton", {
		Parent                 = Built.Frame,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	local function Render(Animate)
		local Target = Value
			and UDim2.new(1, -Metrics.KnobInset - KnobSize, 0.5, 0)
			or UDim2.new(0, Metrics.KnobInset, 0.5, 0)
		local Transparency = Value and 0 or 0.55
		if Animate then
			Tween(Knob, { Position = Target }, "toss")
			Tween(Track, { BackgroundTransparency = Transparency }, "item")
		else
			Knob.Position = Target
			Track.BackgroundTransparency = Transparency
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue == true
		Render(true)
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Button.Activated:Connect(function()
		Handle:Set(not Value)
	end)
	Render(false)
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Slider(Container, Options)
	local Handle = {}
	local Minimum = Options.Min or 0
	local Maximum = Options.Max or 100
	local Step    = Options.Step or 0
	local Value   = Clamp(Options.Default or Minimum, Minimum, Maximum)
	local Built = Row(Container, Options)
	Built.Frame.Size = UDim2.new(1, 0, 0, Metrics.RowHeightTall + 14)
	Built.TextColumn.AnchorPoint = Vector2.new(0, 0)
	Built.TextColumn.Position = UDim2.new(0, 0, 0, 10)
	Built.TextColumn.Size = UDim2.new(1, -70, 0, 0)
	local Readout = Text({
		Parent           = Built.Mount,
		Text             = Options.Format and Options.Format(Value) or FormatNumber(Value, Step),
		TextSize         = Metrics.RowDescSize + 1,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		AnchorPoint      = Vector2.new(1, 0),
		Position         = UDim2.new(1, 0, 0, 10),
		Size             = UDim2.new(1, 0, 0, 14),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Track = New("Frame", {
		Name                   = "Track",
		Parent                 = Built.Frame,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.75,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, -12),
		Size                   = UDim2.new(1, 0, 0, Metrics.SliderTrack),
		ZIndex                 = 2,
	}, {
		Corner(2),
	})
	local Fill = New("Frame", {
		Name             = "Fill",
		Parent           = Track,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
		ZIndex           = 2,
	}, {
		Corner(2),
	})
	local Thumb = New("Frame", {
		Name             = "Thumb",
		Parent           = Track,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0, 0, 0.5, 0),
		Size             = UDim2.new(0, Metrics.SliderThumbWidth, 0, Metrics.SliderThumbHeight),
		ZIndex           = 3,
	}, {
		Corner(1),
	})
	local function Render(Animate)
		local Span = Maximum - Minimum
		local Alpha = Span > 0 and (Value - Minimum) / Span or 0
		Readout.Text = Options.Format and Options.Format(Value) or FormatNumber(Value, Step)
		if Animate then
			Tween(Fill, { Size = UDim2.new(Alpha, 0, 1, 0) }, "snap")
			Tween(Thumb, { Position = UDim2.new(Alpha, 0, 0.5, 0) }, "snap")
		else
			Fill.Size = UDim2.new(Alpha, 0, 1, 0)
			Thumb.Position = UDim2.new(Alpha, 0, 0.5, 0)
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = Clamp(Quantise(NewValue, Step), Minimum, Maximum)
		Render(true)
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	local Connections = {}
	function Handle:Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Built.Frame:Destroy()
	end
	local Grab = New("TextButton", {
		Parent                 = Built.Frame,
		BackgroundTransparency = 1,
		Text                   = "",
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, -4),
		Size                   = UDim2.new(1, 0, 0, 22),
		ZIndex                 = 4,
	})
	local Dragging = false
	local function UpdateFromX(X)
		local Origin = Track.AbsolutePosition.X
		local Width  = Track.AbsoluteSize.X
		local Alpha  = Width > 0 and Clamp((X - Origin) / Width, 0, 1) or 0
		local Raw = Minimum + Alpha * (Maximum - Minimum)
		local Next = Clamp(Quantise(Raw, Step), Minimum, Maximum)
		local Changed = Next ~= Value
		Value = Next
		local Fraction = Maximum > Minimum and (Value - Minimum) / (Maximum - Minimum) or 0
		Readout.Text = Options.Format and Options.Format(Value) or FormatNumber(Value, Step)
		Tween(Fill, { Size = UDim2.new(Fraction, 0, 1, 0) }, "drag")
		Tween(Thumb, { Position = UDim2.new(Fraction, 0, 0.5, 0) }, "drag")
		if Changed and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	Grab.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			Tween(Thumb, { Size = UDim2.new(0, Metrics.SliderThumbWidth + 2, 0, Metrics.SliderThumbHeight + 3) }, "snap")
			UpdateFromX(Input.Position.X)
		end
	end)
	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
		if not Dragging then
			return
		end
		if Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch then
			UpdateFromX(Input.Position.X)
		end
	end))
	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch) then
			Dragging = false
			Tween(Thumb, { Size = UDim2.new(0, Metrics.SliderThumbWidth, 0, Metrics.SliderThumbHeight) }, "toss")
		end
	end))
	Render(false)
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Stepper(Container, Options)
	local Handle = {}
	local Minimum = Options.Min or 0
	local Maximum = Options.Max or 100
	local Step    = Options.Step or 1
	local Value   = Clamp(Options.Default or Minimum, Minimum, Maximum)
	local Built = Row(Container, Options)
	local Chip = New("Frame", {
		Name                   = "Chip",
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Metrics.ChipWidth, 0, Metrics.ChipHeight),
	}, {
		Corner(Metrics.ChipRadius),
	})
	local Readout = Text({
		Parent           = Chip,
		Text             = FormatNumber(Value, Step),
		TextSize         = Metrics.RowDescSize + 2,
		TextXAlignment   = Enum.TextXAlignment.Center,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Button = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	local function Render()
		Readout.Text = FormatNumber(Value, Step)
		Tween(Chip, { BackgroundTransparency = math.max(0, Theme.ChipTransparency - 0.3) }, "press")
		task.delay(MotionTime("press"), function()
			Tween(Chip, { BackgroundTransparency = Theme.ChipTransparency }, "hover")
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = Clamp(Quantise(NewValue, Step), Minimum, Maximum)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Button.Activated:Connect(function(Input)
		local Middle = Chip.AbsolutePosition.X + Chip.AbsoluteSize.X / 2
		local X = Input and Input.Position and Input.Position.X
			or UserInputService:GetMouseLocation().X
		Handle:Set(Value + (X < Middle and -Step or Step))
	end)
	Render()
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Button(Container, Options)
	local Handle = {}
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 80, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -98, 0, 0)
	local Pill = New("Frame", {
		Name             = "Pill",
		Parent           = Built.Mount,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, 0, 0.5, 0),
		Size             = UDim2.new(0, 80, 0, Metrics.TabHeight),
	}, {
		Corner(math.min(Metrics.PillRadius, math.floor(Metrics.TabHeight / 2))),
	})
	Text({
		Parent         = Pill,
		Text           = Options.Action or "Run",
		TextColor3     = Theme.Black,
		FontFace       = Theme.FontMedium,
		TextSize       = Metrics.RowDescSize + 2,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Button = New("TextButton", {
		Parent                 = Pill,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	Button.Activated:Connect(function()
		Tween(Pill, { BackgroundTransparency = 0.4 }, "press")
		task.delay(MotionTime("press"), function()
			Tween(Pill, { BackgroundTransparency = 0 }, "press")
		end)
		if Options.Callback then
			task.spawn(Options.Callback)
		end
	end)
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Keybind(Container, Options)
	local Handle = {}
	local Value = Options.Default or Enum.KeyCode.Unknown
	local Listening = false
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 90, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -108, 0, 0)
	local Chip = New("Frame", {
		Name                   = "Chip",
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 90, 0, Metrics.ChipHeight + 2),
	}, {
		Corner(Metrics.ChipRadius),
	})
	local Readout = Text({
		Parent         = Chip,
		Text           = Value.Name,
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoSize + 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Button = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	function Handle:Get()
		return Value
	end
	function Handle:Set(KeyCode, Silent)
		Value = KeyCode
		Readout.Text = KeyCode.Name
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Button.Activated:Connect(function()
		if Listening then
			return
		end
		Listening = true
		Readout.Text = "..."
		Tween(Chip, { BackgroundTransparency = math.max(0, Theme.ChipTransparency - 0.25) }, "hover")
		local Connection
		Connection = UserInputService.InputBegan:Connect(function(Input, Processed)
			if Processed or Input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			Connection:Disconnect()
			Listening = false
			Tween(Chip, { BackgroundTransparency = Theme.ChipTransparency }, "hover")
			if Input.KeyCode == Enum.KeyCode.Escape then
				Readout.Text = Value.Name
				return
			end
			Handle:Set(Input.KeyCode)
		end)
	end)
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Dropdown(Container, Options, Owner)
	local Handle = {}
	local Items = Options.Items or {}
	local Value = Options.Default or Items[1]
	local Open = false
	local Width = Options.Width or 110
	local EntryHeight = 24
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, Width, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -(Width + 18), 0, 0)
	local Chip = New("Frame", {
		Name                   = "Chip",
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.ChipHeight + 2),
	}, {
		Corner(Metrics.ChipRadius),
		Padding(0, 8),
	})
	local Readout = Text({
		Parent         = Chip,
		Text           = tostring(Value),
		TextSize       = Metrics.RowDescSize + 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		Size           = UDim2.new(1, -12, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local Chevron = New("Frame", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 10, 0, 10),
	})
	local Arms = {}
	for Index = 1, 2 do
		Arms[Index] = New("Frame", {
			Parent                 = Chevron,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.TextSecondary,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(Index == 1 and 0.28 or 0.72, 0, 0.5, 0),
			Size                   = UDim2.new(0, 7, 0, 1),
			Rotation               = Index == 1 and 45 or -45,
		})
	end
	local Layer = Owner and Owner._Overlay and Owner:_Overlay() or Screen()
	local Menu = New("Frame", {
		Name                   = "DropdownMenu",
		Parent                 = Layer,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.12,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Width, 0, 0),
		Visible                = false,
		ClipsDescendants       = true,
		ZIndex                 = 41,
	}, {
		Corner(Metrics.ChipRadius),
		New("UIStroke", {
			Color        = Theme.White,
			Transparency = 0.78,
			Thickness    = 1,
		}),
	})
	local Inner = New("CanvasGroup", {
		Name                   = "Inner",
		Parent                 = Menu,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		GroupTransparency      = 1,
		ZIndex                 = 42,
	}, {
		Padding(4),
	})
	local Scroll = New("ScrollingFrame", {
		Name                   = "Scroll",
		Parent                 = Inner,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.Y,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.Y,
		ClipsDescendants       = true,
		ZIndex                 = 42,
	})
	local Canvas, Rows = Layered(Scroll, 1)
	SmoothScroll(Scroll, "Y", { Depth = 14 })
	local Entries = {}
	local Mark = nil
	local function Render()
		Readout.Text = tostring(Value)
		local Chosen = nil
		for Item, Parts in Entries do
			local On = Item == Value
			if On then
				Chosen = Parts.Entry
			end
			Tween(Parts.Label, { TextTransparency = On and Theme.TextPrimary or Theme.TextSecondary }, "hover")
		end
		if Mark then
			Mark:To(Chosen, Canvas)
		end
	end
	local function Height()
		return math.min(#Items, Options.Visible or 6) * (EntryHeight + 1) + 8
	end
	local Upward = false
	local function Place()
		local Origin = Layer.AbsolutePosition
		local Full = Height()
		local Below = Chip.AbsolutePosition.Y + Chip.AbsoluteSize.Y + 5
		local Viewport = Screen().AbsoluteSize.Y
		Upward = Viewport > 0 and Below + Full > Viewport - 8
		Menu.Position = UDim2.fromOffset(
			Chip.AbsolutePosition.X - Origin.X,
			Upward and (Chip.AbsolutePosition.Y - Origin.Y - 5) or (Below - Origin.Y)
		)
		Menu.AnchorPoint = Vector2.new(0, Upward and 1 or 0)
	end
	local function Close()
		if not Open then
			return
		end
		Open = false
		for Index, Arm in Arms do
			Tween(Arm, { Rotation = Index == 1 and 45 or -45 }, "morph")
		end
		Tween(Menu, { Size = UDim2.new(0, Width, 0, 0) }, "snap")
		Tween(Inner, { GroupTransparency = 1 }, "exit")
		task.delay(MotionTime("snap"), function()
			if not Open then
				Menu.Visible = false
			end
		end)
	end
	local function Show()
		Open = true
		Place()
		Menu.Size = UDim2.new(0, Width, 0, 0)
		Menu.Visible = true
		Inner.GroupTransparency = 1
		for Index, Arm in Arms do
			Tween(Arm, { Rotation = Index == 1 and -45 or 45 }, "morph")
		end
		Tween(Menu, { Size = UDim2.new(0, Width, 0, Height()) }, "reveal")
		Tween(Inner, { GroupTransparency = 0 }, "fade")
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Open()
		Show()
	end
	function Handle:Close()
		Close()
	end
	for Index, Item in Items do
		local Entry = New("TextButton", {
			Parent                 = Rows,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Text                   = "",
			Size                   = UDim2.new(1, 0, 0, EntryHeight),
			LayoutOrder            = Index,
			ZIndex                 = 43,
		}, {
			Corner(Metrics.RowRadius),
		})
		local Label = Text({
			Parent           = Entry,
			Text             = tostring(Item),
			TextSize         = Metrics.RowDescSize + 1,
			TextTransparency = Theme.TextSecondary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			Position         = UDim2.new(0, 9, 0, 0),
			Size             = UDim2.new(1, -13, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
			ZIndex           = 44,
		})
		Entries[Item] = { Entry = Entry, Label = Label }
		Entry.MouseEnter:Connect(function()
			Tween(Entry, { BackgroundTransparency = 0.9 }, "hover")
		end)
		Entry.MouseLeave:Connect(function()
			Tween(Entry, { BackgroundTransparency = 1 }, "hover")
		end)
		Entry.Activated:Connect(function()
			Handle:Set(Item)
			Close()
		end)
	end
	Mark = SlidingMark(Canvas)
	local Button = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	Button.Activated:Connect(function()
		if Open then
			Close()
		else
			Show()
		end
	end)
	Chip.MouseEnter:Connect(function()
		Tween(Chip, { BackgroundTransparency = math.max(0, Theme.ChipTransparency - 0.18) }, "hover")
	end)
	Chip.MouseLeave:Connect(function()
		Tween(Chip, { BackgroundTransparency = Theme.ChipTransparency }, "hover")
	end)
	local Outside = UserInputService.InputBegan:Connect(function(Input, Processed)
		if not Open or Processed then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local Point = Input.Position
		local Top, Size = Menu.AbsolutePosition, Menu.AbsoluteSize
		local Inside = Point.X >= Top.X and Point.X <= Top.X + Size.X
			and Point.Y >= Top.Y and Point.Y <= Top.Y + Size.Y
		if not Inside then
			Close()
		end
	end)
	if Owner and Owner._Register then
		Owner:_Register(Close)
	end
	function Handle:Destroy()
		Outside:Disconnect()
		Menu:Destroy()
		Built.Frame:Destroy()
	end
	Render()
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Input(Container, Options)
	local Handle = {}
	local Value = Options.Default or ""
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 140, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -158, 0, 0)
	local Field = New("TextBox", {
		Name                   = "Field",
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 140, 0, Metrics.ChipHeight + 3),
		Text                   = Value,
		PlaceholderText        = Options.Placeholder or "",
		PlaceholderColor3      = Theme.White,
		TextColor3             = Theme.White,
		FontFace               = Theme.Font,
		TextSize               = Metrics.RowDescSize + 2,
		TextXAlignment         = Enum.TextXAlignment.Center,
		ClearTextOnFocus       = false,
		ZIndex                 = 3,
	}, {
		Corner(Metrics.ChipRadius),
		Padding(0, 8),
	})
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Field.Text = NewValue
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Field.Focused:Connect(function()
		Tween(Field, { BackgroundTransparency = math.max(0, Theme.ChipTransparency - 0.25) }, "hover")
	end)
	Field.FocusLost:Connect(function(Entered)
		Tween(Field, { BackgroundTransparency = Theme.ChipTransparency }, "hover")
		Value = Field.Text
		if Options.Callback then
			task.spawn(Options.Callback, Value, Entered)
		end
	end)
	Handle.Frame = Built.Frame
	return Handle
end
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
		Padding(2, 14, 6, 14),
		List(5),
	})
	if Options.Label then
		Text({
			Parent      = Frame,
			Text        = Options.Label,
			FontFace    = Theme.FontMedium,
			TextSize    = Metrics.RowLabelSize - 2,
			LayoutOrder = 1,
		})
	end
	local Body = Text({
		Parent           = Frame,
		Text             = Options.Text or "",
		TextSize         = Metrics.RowDescSize + 1,
		TextTransparency = Theme.TextSecondary,
		TextWrapped      = true,
		LayoutOrder      = 2,
	})
	if Options.Image then
		local Picture = New("ImageLabel", {
			Parent                 = Frame,
			BackgroundColor3       = Theme.Black,
			BackgroundTransparency = 0.65,
			BorderSizePixel        = 0,
			Image                  = Options.Image,
			ImageTransparency      = 1,
			ScaleType              = Enum.ScaleType.Fit,
			Size                   = UDim2.new(1, 0, 0, Options.ImageHeight or 110),
			LayoutOrder            = 3,
		}, {
			Corner(Metrics.ChipRadius),
		})
		Tween(Picture, { ImageTransparency = 0 }, "fade")
		Handle.Picture = Picture
	end
	function Handle:Set(NewText)
		SwapText(Body, NewText)
	end
	function Handle:Destroy()
		Frame:Destroy()
	end
	Handle.Frame = Frame
	return Handle
end
function Controls.Gap(Container, Options)
	local Frame = New("Frame", {
		Name                   = "Gap",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, (Options and Options.Height) or 12),
		LayoutOrder            = (Options and Options.LayoutOrder) or 0,
	})
	return { Frame = Frame, Destroy = function() Frame:Destroy() end }
end
local function Block(Parent, Options, Height)
	local Frame = New("Frame", {
		Name                   = "Block",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Options.Flat and 1 or Theme.RowTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Metrics.RowRadius),
		Padding(12, 14, 12, 14),
		List(8),
	})
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
			TextSize    = Metrics.RowLabelSize,
			LayoutOrder = 1,
		})
		if Options.Description and Options.Description ~= "" then
			Text({
				Parent           = Column,
				Text             = Options.Description,
				TextSize         = Metrics.RowDescSize,
				TextTransparency = Theme.TextSecondary,
				TextWrapped      = true,
				LayoutOrder      = 2,
			})
		end
		Aside = New("Frame", {
			Name                   = "Aside",
			Parent                 = Head,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(1, 0),
			Position               = UDim2.new(1, 0, 0, 1),
			Size                   = UDim2.new(0, (Options.AsideWidth or 100) - 12, 0, 20),
		})
	end
	local Content = New("Frame", {
		Name                   = "Content",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Height or 0),
		AutomaticSize          = Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		LayoutOrder            = 2,
	})
	if not Options.Flat then
		Frame.MouseEnter:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowHoverTransparency }, "hover")
		end)
		Frame.MouseLeave:Connect(function()
			Tween(Frame, { BackgroundTransparency = Theme.RowTransparency }, "hover")
		end)
		Enter(Frame, "BackgroundTransparency", Theme.RowTransparency, "fade")
	end
	return { Frame = Frame, Content = Content, Head = Head, Aside = Aside }
end
function Layered(Parent, Gap)
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
function SlidingMark(Parent)
	local Mark = New("Frame", {
		Name                   = "Mark",
		Parent                 = Parent,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, 0, 0, 0),
		Size                   = UDim2.new(0, 1, 0, 0),
		ZIndex                 = 6,
	})
	local Handle = { Frame = Mark }
	local Placed = false
	function Handle:To(Entry, Container)
		if not Entry then
			Tween(Mark, { BackgroundTransparency = 1 }, "fade")
			Placed = false
			return
		end
		local Offset = Entry.AbsolutePosition.Y - Container.AbsolutePosition.Y
		if Container:IsA("ScrollingFrame") then
			Offset += Container.CanvasPosition.Y
		end
		local Position = UDim2.new(0, 0, 0, Offset)
		local Size = UDim2.new(0, 1, 0, Entry.AbsoluteSize.Y)
		if Placed then
			Tween(Mark, { Position = Position, Size = Size }, "morph")
		else
			Mark.Position = Position
			Mark.Size = Size
			Placed = true
		end
		Tween(Mark, { BackgroundTransparency = Theme.RuleTransparency }, "fade")
	end
	return Handle
end
local function BlockHandle(Built, Extra)
	local Handle = Extra or {}
	Handle.Frame = Built.Frame
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	return Handle
end
local function Hex(Colour)
	return string.format("#%02x%02x%02x",
		math.floor(Colour.R * 255 + 0.5),
		math.floor(Colour.G * 255 + 0.5),
		math.floor(Colour.B * 255 + 0.5))
end
function Controls.Divider(Container, Options)
	local Frame = New("Frame", {
		Name                   = "Divider",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Label and 22 or 13),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, 14),
	})
	local function Line(Order)
		return New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 1),
			LayoutOrder            = Order,
		})
	end
	if not Options.Label then
		local Rule = Line(1)
		Rule.AnchorPoint = Vector2.new(0, 0.5)
		Rule.Position = UDim2.new(0, 0, 0.5, 0)
	else
		New("UIListLayout", {
			Parent              = Frame,
			Padding             = UDim.new(0, 10),
			FillDirection       = Enum.FillDirection.Horizontal,
			SortOrder           = Enum.SortOrder.LayoutOrder,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
		})
		local Left = Line(1)
		Left.Size = UDim2.new(0, 12, 0, 1)
		Text({
			Parent           = Frame,
			Text             = Options.Label,
			TextSize         = Metrics.RowDescSize,
			TextTransparency = Theme.TextTertiary,
			AutomaticSize    = Enum.AutomaticSize.X,
			Size             = UDim2.new(0, 0, 0, 14),
			LayoutOrder      = 2,
		})
		local Right = Line(3)
		Right.Size = UDim2.new(0, 0, 0, 1)
		New("UIFlexItem", {
			Parent   = Right,
			FlexMode = Enum.UIFlexMode.Fill,
		})
	end
	return {
		Frame = Frame,
		Destroy = function()
			Frame:Destroy()
		end,
	}
end
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
	local Header = New("Frame", {
		Name                   = "Header",
		Parent                 = Frame,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RowTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, Options.Description and Metrics.RowHeightTall or Metrics.RowHeight),
		LayoutOrder            = 1,
	}, {
		Corner(Metrics.RowRadius),
		Padding(0, 14),
	})
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
	Text({
		Parent      = Column,
		Text        = Options.Label or "",
		TextSize    = Metrics.RowLabelSize,
		LayoutOrder = 1,
	})
	if Options.Description then
		Text({
			Parent           = Column,
			Text             = Options.Description,
			TextSize         = Metrics.RowDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	local Chevron = New("Frame", {
		Name                   = "Chevron",
		Parent                 = Header,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 12, 0, 12),
	})
	local Arms = {}
	for Index = 1, 2 do
		Arms[Index] = New("Frame", {
			Parent                 = Chevron,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.TextSecondary,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(Index == 1 and 0.28 or 0.72, 0, 0.5, 0),
			Size                   = UDim2.new(0, 8, 0, 1),
			Rotation               = Index == 1 and 45 or -45,
		})
	end
	local Shell = New("Frame", {
		Name                   = "Shell",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		ClipsDescendants       = true,
		LayoutOrder            = 2,
	})
	local Body = New("CanvasGroup", {
		Name                   = "Body",
		Parent                 = Shell,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		GroupTransparency      = Open and 0 or 1,
	}, {
		Padding(0, 0, 0, 12),
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
			if not Animate or Height <= 0 then
				Shell.AutomaticSize = Enum.AutomaticSize.Y
				Body.GroupTransparency = 0
				return
			end
			Shell.Size = UDim2.new(1, 0, 0, 0)
			Tween(Shell, { Size = UDim2.new(1, 0, 0, Height) }, "reveal")
			Tween(Body, { GroupTransparency = 0 }, "expand")
			task.delay(MotionTime("expand"), function()
				if Open then
					Shell.AutomaticSize = Enum.AutomaticSize.Y
				end
			end)
		else
			Shell.AutomaticSize = Enum.AutomaticSize.None
			if Animate then
				Tween(Shell, { Size = UDim2.new(1, 0, 0, 0) }, "snap")
				Tween(Body, { GroupTransparency = 1 }, "exit")
			else
				Shell.Size = UDim2.new(1, 0, 0, 0)
				Body.GroupTransparency = 1
			end
		end
	end
	local Button = New("TextButton", {
		Parent                 = Header,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	Button.Activated:Connect(function()
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
		return Owner and Owner._Overlay and Owner:_Overlay() or Screen()
	end
	function Handle:_Register(Close)
		if Owner and Owner._Register then
			Owner:_Register(Close)
		end
	end
	function Handle:IsOpen()
		return Open
	end
	function Handle:SetOpen(Value, Animate)
		Open = Value == true
		Render(Animate ~= false)
	end
	function Handle:Destroy()
		Frame:Destroy()
	end
	Handle.Frame = Frame
	Render(false)
	return Attach(Handle)
end
function Controls.Radio(Container, Options)
	local Handle = {}
	local Value = Options.Default or (Options.Items or {})[1]
	local Buttons = {}
	local Built = Block(Container, Options)
	New("UIListLayout", {
		Parent    = Built.Content,
		Padding   = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local function Render()
		for Item, Parts in Buttons do
			local Selected = Item == Value
			Tween(Parts.Dot, { Size = Selected and UDim2.new(0, 6, 0, 6) or UDim2.new(0, 0, 0, 0) }, "toss")
			Tween(Parts.Dot, { BackgroundTransparency = Selected and 0 or 1 }, "hover")
			Tween(Parts.Ring, {
				Transparency = Selected and 0 or Theme.TextTertiary,
			}, "hover")
			Tween(Parts.Label, {
				TextTransparency = Selected and Theme.TextPrimary or Theme.TextSecondary,
			}, "hover")
		end
	end
	for Index, Item in Options.Items or {} do
		local Entry = New("TextButton", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Text                   = "",
			Size                   = UDim2.new(1, 0, 0, 24),
			LayoutOrder            = Index,
		})
		New("UIListLayout", {
			Parent            = Entry,
			Padding           = UDim.new(0, 9),
			FillDirection     = Enum.FillDirection.Horizontal,
			SortOrder         = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		})
		local Circle = New("Frame", {
			Parent                 = Entry,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(0, 13, 0, 13),
			LayoutOrder            = 1,
		}, {
			Corner(7),
		})
		local Ring = New("UIStroke", {
			Parent       = Circle,
			Color        = Theme.White,
			Transparency = Theme.TextTertiary,
			Thickness    = 1,
		})
		local Dot = New("Frame", {
			Parent                 = Circle,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, 0, 0, 0),
		}, {
			Corner(4),
		})
		local Label = Text({
			Parent           = Entry,
			Text             = tostring(Item),
			TextSize         = Metrics.RowDescSize + 2,
			TextTransparency = Theme.TextSecondary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			AutomaticSize    = Enum.AutomaticSize.X,
			Size             = UDim2.new(0, 0, 1, 0),
			LayoutOrder      = 2,
		})
		Buttons[Item] = { Ring = Ring, Dot = Dot, Label = Label }
		Entry.Activated:Connect(function()
			Handle:Set(Item)
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	Render()
	return BlockHandle(Built, Handle)
end
function Controls.Checkbox(Container, Options)
	local Handle = {}
	local Value = Options.Default == true
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 18, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -36, 0, 0)
	local Box = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 16, 0, 16),
	}, {
		Corner(3),
		New("UIStroke", {
			Color        = Theme.White,
			Transparency = Theme.TextTertiary,
			Thickness    = 1,
		}),
	})
	local Arms = {}
	for Index = 1, 2 do
		Arms[Index] = New("Frame", {
			Parent                 = Box,
			BackgroundColor3       = Theme.Black,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(Index == 1 and 0.34 or 0.58, 0, Index == 1 and 0.62 or 0.45, 0),
			Size                   = UDim2.new(0, Index == 1 and 5 or 9, 0, 1.5),
			Rotation               = Index == 1 and 45 or -45,
		})
	end
	local function Render()
		Tween(Box, { BackgroundTransparency = Value and 0 or 1 }, "item")
		for _, Arm in Arms do
			Tween(Arm, { BackgroundTransparency = Value and 0 or 1 }, "item")
		end
	end
	local Button = New("TextButton", {
		Parent                 = Built.Frame,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue == true
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Button.Activated:Connect(function()
		Handle:Set(not Value)
	end)
	Render()
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Chips(Container, Options)
	local Handle = {}
	local Selected = {}
	local Pills = {}
	for _, Item in Options.Default or {} do
		Selected[Item] = true
	end
	local Built = Block(Container, Options)
	New("UIListLayout", {
		Parent              = Built.Content,
		Padding             = UDim.new(0, 6),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Wraps               = true,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
	})
	local function Render()
		for Item, Parts in Pills do
			local On = Selected[Item] == true
			Tween(Parts.Pill, { BackgroundTransparency = On and 0 or 1 }, "hover")
			Tween(Parts.Label, {
				TextColor3       = On and Theme.Black or Theme.White,
				TextTransparency = On and 0 or Theme.TextSecondary,
			}, "hover")
			Parts.Stroke.Transparency = On and 1 or 0.65
		end
	end
	for Index, Item in Options.Items or {} do
		local Pill = New("Frame", {
			Parent                 = Built.Content,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, 24),
			LayoutOrder            = Index,
		}, {
			Corner(math.min(Metrics.PillRadius, 12)),
			Padding(0, 11),
		})
		local Stroke = New("UIStroke", {
			Parent       = Pill,
			Color        = Theme.White,
			Transparency = 0.65,
			Thickness    = 1,
		})
		local Label = New("TextLabel", {
			Parent                 = Pill,
			BackgroundTransparency = 1,
			Text                   = tostring(Item),
			TextColor3             = Theme.White,
			TextTransparency       = Theme.TextSecondary,
			FontFace               = Theme.Font,
			TextSize               = Metrics.RowDescSize + 1,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			ZIndex                 = 2,
		})
		local Button = New("TextButton", {
			Parent                 = Pill,
			BackgroundTransparency = 1,
			Text                   = "",
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 3,
		})
		Pills[Item] = { Pill = Pill, Label = Label, Stroke = Stroke }
		Button.Activated:Connect(function()
			Selected[Item] = not Selected[Item] or nil
			Render()
			if Options.Callback then
				task.spawn(Options.Callback, Handle:Get())
			end
		end)
	end
	function Handle:Get()
		local Out = {}
		for _, Item in Options.Items or {} do
			if Selected[Item] then
				table.insert(Out, Item)
			end
		end
		return Out
	end
	function Handle:Set(Values, Silent)
		table.clear(Selected)
		for _, Item in Values or {} do
			Selected[Item] = true
		end
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Handle:Get())
		end
	end
	Render()
	return BlockHandle(Built, Handle)
end
function Controls.List(Container, Options)
	local Handle = {}
	local Value = Options.Default
	local Entries = {}
	local Built = Block(Container, Options, Options.Height or 132)
	local Scroll = New("ScrollingFrame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.Y,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.Y,
		ClipsDescendants       = true,
	})
	local Canvas, Rows = Layered(Scroll, 1)
	SmoothScroll(Scroll, "Y")
	local Mark = SlidingMark(Canvas)
	local function Render()
		local Chosen = nil
		for Item, Parts in Entries do
			local On = Item == Value
			if On then
				Chosen = Parts.Entry
			end
			Tween(Parts.Label, {
				TextTransparency = On and Theme.TextPrimary or Theme.TextSecondary,
			}, "hover")
		end
		Mark:To(Chosen, Canvas)
	end
	for Index, Item in Options.Items or {} do
		local Entry = New("TextButton", {
			Parent                 = Rows,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Text                   = "",
			Size                   = UDim2.new(1, 0, 0, 24),
			LayoutOrder            = Index,
		})
		local Label = Text({
			Parent           = Entry,
			Text             = tostring(Item),
			TextSize         = Metrics.RowDescSize + 2,
			TextTransparency = Theme.TextSecondary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Position         = UDim2.new(0, 10, 0, 0),
			Size             = UDim2.new(1, -10, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		Entries[Item] = { Entry = Entry, Label = Label }
		Entry.MouseEnter:Connect(function()
			Tween(Entry, { BackgroundTransparency = 0.94 }, "hover")
		end)
		Entry.MouseLeave:Connect(function()
			Tween(Entry, { BackgroundTransparency = 1 }, "hover")
		end)
		Entry.Activated:Connect(function()
			Handle:Set(Item)
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	Render()
	return BlockHandle(Built, Handle)
end
function Controls.Badge(Container, Options)
	local Handle = {}
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 92, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -110, 0, 0)
	local Colour = Options.Color or Theme.Neutral
	local Pill = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Colour,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 0, 20),
	}, {
		Corner(math.min(Metrics.PillRadius, 10)),
		Padding(0, 9),
	})
	local Label = New("TextLabel", {
		Parent                 = Pill,
		BackgroundTransparency = 1,
		Text                   = Options.Text or "",
		TextColor3             = Colour,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.RowDescSize,
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 1, 0),
	})
	function Handle:Set(NewText, NewColour)
		SwapText(Label, NewText)
		if NewColour then
			Label.TextColor3 = NewColour
			Pill.BackgroundColor3 = NewColour
		end
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Status(Container, Options)
	local Handle = {}
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 170, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -188, 0, 0)
	local Value = Text({
		Parent           = Built.Mount,
		Text             = tostring(Options.Value or ""),
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize + 1,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(1, 0, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	function Handle:Get()
		return Value.Text
	end
	function Handle:Set(NewValue)
		SwapText(Value, tostring(NewValue))
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Progress(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0
	local Maximum = Options.Max or 1
	local Built = Row(Container, Options)
	Built.Frame.Size = UDim2.new(1, 0, 0, Metrics.RowHeightTall + 14)
	Built.TextColumn.AnchorPoint = Vector2.new(0, 0)
	Built.TextColumn.Position = UDim2.new(0, 0, 0, 10)
	Built.TextColumn.Size = UDim2.new(1, -70, 0, 0)
	local Readout = Text({
		Parent           = Built.Mount,
		Text             = "",
		TextSize         = Metrics.RowDescSize + 1,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		AnchorPoint      = Vector2.new(1, 0),
		Position         = UDim2.new(1, 0, 0, 10),
		Size             = UDim2.new(1, 0, 0, 14),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Track = New("Frame", {
		Parent                 = Built.Frame,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, -14),
		Size                   = UDim2.new(1, 0, 0, Metrics.SliderTrack),
	}, {
		Corner(2),
	})
	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Options.Color or Theme.White,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
	}, {
		Corner(2),
	})
	local function Render(Animate)
		local Alpha = Maximum > 0 and Clamp(Value / Maximum, 0, 1) or 0
		Readout.Text = Options.Format and Options.Format(Value, Maximum)
			or string.format("%d%%", math.floor(Alpha * 100 + 0.5))
		if Animate then
			Tween(Fill, { Size = UDim2.new(Alpha, 0, 1, 0) }, "snap")
		else
			Fill.Size = UDim2.new(Alpha, 0, 1, 0)
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render(true)
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Render(false)
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Meter(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0
	local Maximum = Options.Max or 100
	local Segments = Options.Segments or 24
	local Built = Block(Container, Options, 18)
	local Bars = {}
	New("UIListLayout", {
		Parent              = Built.Content,
		Padding             = UDim.new(0, 3),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
	})
	for Index = 1, Segments do
		Bars[Index] = New("Frame", {
			Parent                 = Built.Content,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.85,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1 / Segments, -3, 1, 0),
			LayoutOrder            = Index,
		})
	end
	local function Render()
		local Alpha = Maximum > 0 and Clamp(Value / Maximum, 0, 1) or 0
		local Lit = math.floor(Alpha * Segments + 0.5)
		local Colour = Theme.White
		if Options.Danger and Alpha >= Options.Danger then
			Colour = Theme.Danger
		elseif Options.Warn and Alpha >= Options.Warn then
			Colour = Theme.Warn
		end
		for Index, Bar in Bars do
			local On = Index <= Lit
			Tween(Bar, {
				BackgroundColor3       = On and Colour or Theme.White,
				BackgroundTransparency = On and 0.05 or 0.85,
			}, "hover")
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue)
		Value = NewValue
		Render()
	end
	Render()
	return BlockHandle(Built, Handle)
end
function Controls.Spinner(Container, Options)
	local Handle = {}
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 18, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -36, 0, 0)
	local Ring = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 16, 0, 16),
	})
	local Dots = {}
	for Index = 1, 8 do
		local Angle = (Index - 1) / 8 * math.pi * 2
		Dots[Index] = New("Frame", {
			Parent                 = Ring,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.9,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, math.cos(Angle) * 7, 0.5, math.sin(Angle) * 7),
			Size                   = UDim2.new(0, 2, 0, 2),
		}, {
			Corner(1),
		})
	end
	local Running = true
	task.spawn(function()
		local Head = 0
		while Running and Ring.Parent do
			Head = Head % 8 + 1
			for Index, Dot in Dots do
				local Distance = (Index - Head) % 8
				Dot.BackgroundTransparency = math.min(0.9, Distance / 8 + 0.1)
			end
			task.wait(0.08)
		end
	end)
	function Handle:Destroy()
		Running = false
		Built.Frame:Destroy()
	end
	Handle.Frame = Built.Frame
	return Handle
end
local function Polyline(Parent, Pool, Points, Colour, Alpha, Thickness)
	local Wanted = math.max(0, #Points - 1)
	for Index = 1, Wanted do
		local From, To = Points[Index], Points[Index + 1]
		local Delta = To - From
		local Length = Delta.Magnitude
		local Position = UDim2.fromOffset((From.X + To.X) / 2, (From.Y + To.Y) / 2)
		local Size = UDim2.fromOffset(Length + 1, Thickness or 1)
		local Angle = math.deg(math.atan2(Delta.Y, Delta.X))
		local Segment = Pool[Index]
		if not Segment or not Segment.Parent then
			Segment = New("Frame", {
				Parent                 = Parent,
				BackgroundColor3       = Colour,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = Position,
				Size                   = Size,
				Rotation               = Angle,
			})
			Pool[Index] = Segment
			Tween(Segment, { BackgroundTransparency = Alpha }, "fade")
		else
			Segment.BackgroundColor3 = Colour
			local Current = Segment.Rotation
			local Target = Angle
			while Target - Current > 180 do
				Target -= 360
			end
			while Current - Target > 180 do
				Target += 360
			end
			Tween(Segment, { Position = Position, Size = Size, Rotation = Target }, "layout")
			Tween(Segment, { BackgroundTransparency = Alpha }, "fade")
		end
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
function Controls.Sparkline(Container, Options)
	local Handle = {}
	local Values = Options.Values or {}
	local Width = Options.Width or 120
	local Height = Options.Height or 22
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, Width, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -(Width + 18), 0, 0)
	local Canvas = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Height),
		ClipsDescendants       = true,
	})
	local Pool = {}
	local function Render()
		if #Values < 2 then
			Polyline(Canvas, Pool, {}, Theme.White, 1, 1)
			return
		end
		local Minimum, Maximum = Extent(Values, Options)
		Polyline(Canvas, Pool, ChartPoints(Values, Width, Height, Minimum, Maximum),
			Options.Color or Theme.White, 0.15, 1)
	end
	function Handle:Get()
		return Values
	end
	function Handle:Set(NewValues)
		Values = NewValues
		Render()
	end
	function Handle:Push(Value, Limit)
		table.insert(Values, Value)
		while #Values > (Limit or Options.Limit or 40) do
			table.remove(Values, 1)
		end
		Render()
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Render()
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Graph(Container, Options)
	local Handle = {}
	local Values = Options.Values or {}
	local Height = Options.Height or 96
	local Built = Block(Container, Options, Height)
	local Canvas = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -34, 1, 0),
		ClipsDescendants       = true,
	})
	local Axis = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.new(1, 0, 0, 0),
		Size                   = UDim2.new(0, 30, 1, 0),
	})
	local High = Text({
		Parent           = Axis,
		Text             = "",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		Size             = UDim2.new(1, 0, 0, 10),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Low = Text({
		Parent           = Axis,
		Text             = "",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		AnchorPoint      = Vector2.new(0, 1),
		Position         = UDim2.new(0, 0, 1, 0),
		Size             = UDim2.new(1, 0, 0, 10),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	New("Frame", {
		Parent                 = Canvas,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, 0),
		Size                   = UDim2.new(1, 0, 0, 1),
		ZIndex                 = 0,
	})
	local Line = New("Frame", {
		Parent                 = Canvas,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	local Pool = {}
	local function Render()
		if #Values < 2 then
			Polyline(Line, Pool, {}, Theme.White, 1, 1)
			return
		end
		local Minimum, Maximum = Extent(Values, Options)
		SwapText(High, FormatNumber(Maximum, Options.Step or 1))
		SwapText(Low, FormatNumber(Minimum, Options.Step or 1))
		local Width = Canvas.AbsoluteSize.X
		if Width <= 0 then
			return
		end
		Polyline(Line, Pool, ChartPoints(Values, Width, Height, Minimum, Maximum),
			Options.Color or Theme.White, 0.1, 1)
	end
	Canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(Render)
	function Handle:Get()
		return Values
	end
	function Handle:Set(NewValues)
		Values = NewValues
		Render()
	end
	function Handle:Push(Value, Limit)
		table.insert(Values, Value)
		while #Values > (Limit or Options.Limit or 60) do
			table.remove(Values, 1)
		end
		Render()
	end
	task.defer(Render)
	return BlockHandle(Built, Handle)
end
function Controls.Rating(Container, Options)
	local Handle = {}
	local Count = Options.Count or 5
	local Value = Options.Default or 0
	local Bars = {}
	local Built = Row(Container, Options)
	local Width = Count * 16
	Built.Mount.Size = UDim2.new(0, Width, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -(Width + 18), 0, 0)
	local Strip = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, 16),
	})
	New("UIListLayout", {
		Parent            = Strip,
		Padding           = UDim.new(0, 4),
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local function Render()
		for Index, Bar in Bars do
			Tween(Bar, { Size = UDim2.new(0, 12, 0, Index <= Value and 14 or 8) }, "toss")
			Tween(Bar, { BackgroundTransparency = Index <= Value and 0 or 0.82 }, "hover")
		end
	end
	for Index = 1, Count do
		local Bar = New("Frame", {
			Parent                 = Strip,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.82,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(0, 12, 0, 8),
			LayoutOrder            = Index,
		}, {
			Corner(1),
		})
		local Button = New("TextButton", {
			Parent                 = Bar,
			BackgroundTransparency = 1,
			Text                   = "",
			Size                   = UDim2.new(1, 4, 1, 6),
			Position               = UDim2.new(0, -2, 0, -3),
			ZIndex                 = 3,
		})
		Bars[Index] = Bar
		Button.Activated:Connect(function()
			Handle:Set(Index == Value and 0 or Index)
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = Clamp(NewValue, 0, Count)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Render()
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Avatar(Container, Options)
	local Handle = {}
	local Frame = New("Frame", {
		Name                   = "Avatar",
		Parent                 = Container,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Options.Flat and 1 or Theme.RowTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 52),
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Metrics.RowRadius),
		Padding(0, 14),
	})
	New("UIListLayout", {
		Parent            = Frame,
		Padding           = UDim.new(0, 11),
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local Image = Options.Image
	if not Image and Options.UserId then
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60", Options.UserId)
	end
	local Portrait = New("ImageLabel", {
		Parent                 = Frame,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = 0.6,
		BorderSizePixel        = 0,
		Image                  = Image or "",
		Size                   = UDim2.new(0, 30, 0, 30),
		LayoutOrder            = 1,
	}, {
		Corner(math.min(Metrics.PillRadius, 15)),
	})
	local Column = New("Frame", {
		Parent                 = Frame,
		BackgroundTransparency = 1,
		AutomaticSize          = Enum.AutomaticSize.Y,
		Size                   = UDim2.new(1, -60, 0, 0),
		LayoutOrder            = 2,
	}, {
		List(1),
	})
	local Name = Text({
		Parent      = Column,
		Text        = Options.Label or "",
		TextSize    = Metrics.RowLabelSize - 1,
		LayoutOrder = 1,
	})
	local Detail = Text({
		Parent           = Column,
		Text             = Options.Description or "",
		TextSize         = Metrics.RowDescSize,
		TextTransparency = Theme.TextSecondary,
		LayoutOrder      = 2,
	})
	function Handle:Set(NewName, NewDetail)
		Name.Text = NewName or Name.Text
		Detail.Text = NewDetail or Detail.Text
	end
	function Handle:SetImage(NewImage)
		Portrait.Image = NewImage
	end
	function Handle:Destroy()
		Frame:Destroy()
	end
	Handle.Frame = Frame
	return Handle
end
function Controls.Table(Container, Options)
	local Handle = {}
	local Columns = Options.Columns or {}
	local Rows = Options.Rows or {}
	local Built = Block(Container, Options)
	local function MakeRow(Cells, Header, Order)
		local Line = New("Frame", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, Header and 18 or 20),
			LayoutOrder            = Order,
		})
		New("UIListLayout", {
			Parent            = Line,
			FillDirection     = Enum.FillDirection.Horizontal,
			SortOrder         = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		})
		for Index, Column in Columns do
			local Content = Cells[Index]
			Text({
				Parent           = Line,
				Text             = Content == nil and "" or tostring(Content),
				FontFace         = Header and Theme.Font or Theme.FontMono,
				TextSize         = Header and Metrics.RowDescSize or (Metrics.MonoSize + 1),
				TextTransparency = Header and Theme.TextTertiary or Theme.TextSecondary,
				TextXAlignment   = Column.Align == "Right" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
				TextYAlignment   = Enum.TextYAlignment.Center,
				TextTruncate     = Enum.TextTruncate.AtEnd,
				Size             = UDim2.new(Column.Width or (1 / #Columns), -6, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
				LayoutOrder      = Index,
			})
		end
		return Line
	end
	New("UIListLayout", {
		Parent    = Built.Content,
		Padding   = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local Body = {}
	local function Render()
		for _, Line in Body do
			Line:Destroy()
		end
		table.clear(Body)
		for Index, Row in Rows do
			table.insert(Body, MakeRow(Row, false, Index + 2))
		end
	end
	local Names = {}
	for Index, Column in Columns do
		Names[Index] = Column.Label or Column[1] or ""
	end
	MakeRow(Names, true, 1)
	New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 1),
		LayoutOrder            = 2,
	})
	function Handle:Get()
		return Rows
	end
	function Handle:Set(NewRows)
		Rows = NewRows
		Render()
	end
	Render()
	return BlockHandle(Built, Handle)
end
function Controls.Vector(Container, Options)
	local Handle = {}
	local Axes = Options.Axes or { "X", "Y", "Z" }
	local Values = {}
	local Fields = {}
	for Index in Axes do
		Values[Index] = (Options.Default and Options.Default[Index]) or 0
	end
	local Built = Block(Container, Options, 26)
	New("UIListLayout", {
		Parent            = Built.Content,
		Padding           = UDim.new(0, 6),
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local function Fire()
		if Options.Callback then
			task.spawn(Options.Callback, table.clone(Values))
		end
	end
	for Index, Axis in Axes do
		local Cell = New("Frame", {
			Parent                 = Built.Content,
			BackgroundColor3       = Theme.Black,
			BackgroundTransparency = Theme.ChipTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1 / #Axes, -6, 1, 0),
			LayoutOrder            = Index,
		}, {
			Corner(Metrics.ChipRadius),
			Padding(0, 8),
		})
		Text({
			Parent           = Cell,
			Text             = Axis,
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Size             = UDim2.new(0, 10, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		local Field = New("TextBox", {
			Parent                 = Cell,
			BackgroundTransparency = 1,
			Text                   = FormatNumber(Values[Index], Options.Step or 0.01),
			TextColor3             = Theme.White,
			FontFace               = Theme.FontMono,
			TextSize               = Metrics.MonoSize + 1,
			TextXAlignment         = Enum.TextXAlignment.Right,
			ClearTextOnFocus       = false,
			Position               = UDim2.new(0, 12, 0, 0),
			Size                   = UDim2.new(1, -12, 1, 0),
		})
		Fields[Index] = Field
		Field.FocusLost:Connect(function()
			local Parsed = tonumber(Field.Text)
			if Parsed then
				Values[Index] = Parsed
				Fire()
			end
			Field.Text = FormatNumber(Values[Index], Options.Step or 0.01)
		end)
	end
	function Handle:Get()
		return table.clone(Values)
	end
	function Handle:Set(NewValues, Silent)
		for Index in Axes do
			Values[Index] = NewValues[Index] or Values[Index]
			Fields[Index].Text = FormatNumber(Values[Index], Options.Step or 0.01)
		end
		if not Silent then
			Fire()
		end
	end
	return BlockHandle(Built, Handle)
end
function Controls.Color(Container, Options)
	local Handle = {}
	local Value = Options.Default or Color3.fromRGB(255, 255, 255)
	local Built = Block(Container, Options)
	local Slot = Built.Aside or Built.Frame
	local Swatch = New("Frame", {
		Parent           = Slot,
		BackgroundColor3 = Value,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0),
		Position         = UDim2.new(1, 0, 0, 0),
		Size             = UDim2.new(0, 34, 0, 20),
		ZIndex           = 2,
	}, {
		Corner(Metrics.ChipRadius),
		New("UIStroke", {
			Color        = Theme.White,
			Transparency = 0.7,
			Thickness    = 1,
		}),
	})
	local Readout = Text({
		Parent           = Slot,
		Text             = Hex(Value),
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -40, 0.5, 0),
		Size             = UDim2.new(0, 60, 0, 12),
		AutomaticSize    = Enum.AutomaticSize.None,
		ZIndex           = 2,
	})
	New("UIListLayout", {
		Parent    = Built.Content,
		Padding   = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local Channels = { { "R", Value.R }, { "G", Value.G }, { "B", Value.B } }
	local Fills = {}
	local function Compose()
		Value = Color3.new(Channels[1][2], Channels[2][2], Channels[3][2])
		Swatch.BackgroundColor3 = Value
		Readout.Text = Hex(Value)
	end
	for Index, Channel in Channels do
		local Line = New("Frame", {
			Parent                 = Built.Content,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 14),
			LayoutOrder            = Index,
		})
		Text({
			Parent           = Line,
			Text             = Channel[1],
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextTertiary,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Size             = UDim2.new(0, 12, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
		local Track = New("Frame", {
			Parent                 = Line,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.82,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, 16, 0.5, 0),
			Size                   = UDim2.new(1, -16, 0, Metrics.SliderTrack),
		}, {
			Corner(2),
		})
		local Fill = New("Frame", {
			Parent           = Track,
			BackgroundColor3 = Index == 1 and Color3.fromRGB(255, 96, 96)
				or Index == 2 and Color3.fromRGB(96, 210, 128)
				or Color3.fromRGB(96, 156, 255),
			BorderSizePixel  = 0,
			Size             = UDim2.new(Channel[2], 0, 1, 0),
		}, {
			Corner(2),
		})
		Fills[Index] = Fill
		local Grab = New("TextButton", {
			Parent                 = Line,
			BackgroundTransparency = 1,
			Text                   = "",
			Position               = UDim2.new(0, 16, 0, 0),
			Size                   = UDim2.new(1, -16, 1, 0),
			ZIndex                 = 3,
		})
		local Dragging = false
		local function Apply(X)
			local Origin, Width = Track.AbsolutePosition.X, Track.AbsoluteSize.X
			if Width <= 0 then
				return
			end
			Channel[2] = Clamp((X - Origin) / Width, 0, 1)
			Fill.Size = UDim2.new(Channel[2], 0, 1, 0)
			Compose()
			if Options.Callback then
				task.spawn(Options.Callback, Value)
			end
		end
		Grab.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
				Apply(Input.Position.X)
			end
		end)
		Grab.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = false
			end
		end)
		Grab.InputChanged:Connect(function(Input)
			if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
				or Input.UserInputType == Enum.UserInputType.Touch) then
				Apply(Input.Position.X)
			end
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Channels[1][2], Channels[2][2], Channels[3][2] = NewValue.R, NewValue.G, NewValue.B
		for Index, Fill in Fills do
			Fill.Size = UDim2.new(Channels[Index][2], 0, 1, 0)
		end
		Compose()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	Compose()
	return BlockHandle(Built, Handle)
end
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
		Padding(0, 14),
	})
	New("UIListLayout", {
		Parent            = Frame,
		Padding           = UDim.new(0, 7),
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
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
				TextSize               = Metrics.RowDescSize + 1,
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
					Text                   = "/",
					TextColor3             = Theme.White,
					TextTransparency       = Theme.TextDisabled,
					FontFace               = Theme.FontMono,
					TextSize               = Metrics.MonoSize + 1,
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
	end
	function Handle:Destroy()
		Frame:Destroy()
	end
	Render()
	Handle.Frame = Frame
	return Handle
end
function Controls.Pagination(Container, Options)
	local Handle = {}
	local Page = Options.Default or 1
	local Pages = Options.Pages or 1
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 110, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -128, 0, 0)
	New("UIListLayout", {
		Parent              = Built.Mount,
		Padding             = UDim.new(0, 8),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
	})
	local Readout
	local function Arrow(Order, Direction)
		local Button = New("TextButton", {
			Parent                 = Built.Mount,
			BackgroundTransparency = 1,
			Text                   = "",
			Size                   = UDim2.new(0, 18, 0, 18),
			LayoutOrder            = Order,
		})
		for Index = 1, 2 do
			New("Frame", {
				Parent                 = Button,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = Theme.TextSecondary,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, Index == 1 and 0.32 or 0.68, 0),
				Size                   = UDim2.new(0, 7, 0, 1),
				Rotation               = Direction * (Index == 1 and 45 or -45),
			})
		end
		return Button
	end
	local Previous = Arrow(1, 1)
	Readout = New("TextLabel", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		Text                   = "",
		TextColor3             = Theme.White,
		FontFace               = Theme.FontMono,
		TextSize               = Metrics.MonoSize + 1,
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 1, 0),
		LayoutOrder            = 2,
	})
	local Next = Arrow(3, -1)
	local function Render()
		SwapText(Readout, string.format("%d / %d", Page, Pages))
	end
	function Handle:Get()
		return Page
	end
	function Handle:Set(NewPage, Silent)
		Page = Clamp(math.floor(NewPage), 1, math.max(1, Pages))
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Page)
		end
	end
	function Handle:SetPages(Count)
		Pages = math.max(1, Count)
		Page = Clamp(Page, 1, Pages)
		Render()
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Previous.Activated:Connect(function() Handle:Set(Page - 1) end)
	Next.Activated:Connect(function() Handle:Set(Page + 1) end)
	Render()
	Handle.Frame = Built.Frame
	return Handle
end
local function Draggable(Target, Surface, OnMove)
	local Connections = {}
	local Dragging = false
	local function Report(Point)
		local Origin = Surface.AbsolutePosition
		local Size = Surface.AbsoluteSize
		OnMove(
			Size.X > 0 and Clamp((Point.X - Origin.X) / Size.X, 0, 1) or 0,
			Size.Y > 0 and Clamp((Point.Y - Origin.Y) / Size.Y, 0, 1) or 0
		)
	end
	table.insert(Connections, Target.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
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
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end))
	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
	end
end
function Controls.ColorPicker(Container, Options)
	local Handle = {}
	local Value = Options.Default or Color3.fromRGB(255, 255, 255)
	local Hue, Saturation, Brightness = Value:ToHSV()
	local Built = Block(Container, Options)
	local Slot = Built.Aside or Built.Frame
	local Swatch = New("Frame", {
		Parent           = Slot,
		BackgroundColor3 = Value,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0),
		Position         = UDim2.new(1, 0, 0, 0),
		Size             = UDim2.new(0, 34, 0, 20),
		ZIndex           = 3,
	}, {
		Corner(Metrics.ChipRadius),
		New("UIStroke", { Color = Theme.White, Transparency = 0.7, Thickness = 1 }),
	})
	local Readout = Text({
		Parent           = Slot,
		Text             = Hex(Value),
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -40, 0.5, 0),
		Size             = UDim2.new(0, 60, 0, 12),
		AutomaticSize    = Enum.AutomaticSize.None,
		ZIndex           = 3,
	})
	New("UIListLayout", {
		Parent    = Built.Content,
		Padding   = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local Field = New("Frame", {
		Parent           = Built.Content,
		BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, Options.Height or 96),
		LayoutOrder      = 1,
		ClipsDescendants = true,
	}, {
		Corner(Metrics.ChipRadius),
	})
	New("Frame", {
		Parent                 = Field,
		BackgroundColor3       = Color3.new(1, 1, 1),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 2,
	}, {
		New("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	New("Frame", {
		Parent                 = Field,
		BackgroundColor3       = Color3.new(0, 0, 0),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	}, {
		New("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(0, 0, 0)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}),
	})
	local Marker = New("Frame", {
		Parent                 = Field,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Size                   = UDim2.new(0, 13, 0, 13),
		ZIndex                 = 5,
	})
	for Index = 1, 2 do
		New("Frame", {
			Parent           = Marker,
			BackgroundColor3 = Theme.White,
			BorderSizePixel  = 0,
			AnchorPoint      = Vector2.new(0.5, 0.5),
			Position         = UDim2.new(0.5, 0, 0.5, 0),
			Size             = Index == 1 and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 1, 1, 0),
			ZIndex           = 5,
		})
	end
	local Strip = New("Frame", {
		Parent           = Built.Content,
		BorderSizePixel  = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size             = UDim2.new(1, 0, 0, 12),
		LayoutOrder      = 2,
		ClipsDescendants = true,
	}, {
		Corner(Metrics.ChipRadius),
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0.000, 1, 1)),
				ColorSequenceKeypoint.new(0.166, Color3.fromHSV(0.166, 1, 1)),
				ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
				ColorSequenceKeypoint.new(0.500, Color3.fromHSV(0.500, 1, 1)),
				ColorSequenceKeypoint.new(0.666, Color3.fromHSV(0.666, 1, 1)),
				ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
				ColorSequenceKeypoint.new(1.000, Color3.fromHSV(1.000, 1, 1)),
			}),
		}),
	})
	local HueMarker = New("Frame", {
		Parent           = Strip,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 0),
		Size             = UDim2.new(0, 2, 1, 0),
		ZIndex           = 3,
	})
	local function Compose(Notify)
		Value = Color3.fromHSV(Hue, Saturation, Brightness)
		Field.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
		Swatch.BackgroundColor3 = Value
		Readout.Text = Hex(Value)
		Tween(Marker, { Position = UDim2.new(Saturation, 0, 1 - Brightness, 0) }, "drag")
		Tween(HueMarker, { Position = UDim2.new(Hue, 0, 0, 0) }, "drag")
		if Notify and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	local StopField = Draggable(Field, Field, function(X, Y)
		Saturation, Brightness = X, 1 - Y
		Compose(true)
	end)
	local StopStrip = Draggable(Strip, Strip, function(X)
		Hue = X
		Compose(true)
	end)
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Hue, Saturation, Brightness = NewValue:ToHSV()
		Compose(not Silent)
	end
	Compose(false)
	local Result = BlockHandle(Built, Handle)
	local BaseDestroy = Result.Destroy
	function Result:Destroy()
		StopField()
		StopStrip()
		BaseDestroy(self)
	end
	return Result
end
function Controls.Segmented(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Value = Options.Default or Items[1]
	local Buttons = {}
	local Built = Block(Container, Options, 28)
	local Track = New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = 0.65,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
	}, {
		Corner(math.min(Metrics.PillRadius, 14)),
		Padding(3),
	})
	local Highlight = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1 / math.max(#Items, 1), 0, 1, 0),
		ZIndex           = 1,
	}, {
		Corner(math.min(Metrics.PillRadius, 11)),
	})
	local Strip = New("Frame", {
		Parent                 = Track,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 2,
	})
	New("UIListLayout", {
		Parent            = Strip,
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local function Render()
		for Index, Item in Items do
			local On = Item == Value
			if On then
				Tween(Highlight, {
					Position = UDim2.new((Index - 1) / #Items, 0, 0, 0),
				}, "morph")
			end
			Tween(Buttons[Item], {
				TextColor3       = On and Theme.Black or Theme.White,
				TextTransparency = On and 0 or Theme.TextSecondary,
			}, "hover")
		end
	end
	for Index, Item in Items do
		local Button = New("TextButton", {
			Parent                 = Strip,
			BackgroundTransparency = 1,
			Text                   = tostring(Item),
			TextColor3             = Theme.White,
			TextTransparency       = Theme.TextSecondary,
			FontFace               = Theme.Font,
			TextSize               = Metrics.RowDescSize + 1,
			Size                   = UDim2.new(1 / #Items, 0, 1, 0),
			LayoutOrder            = Index,
			ZIndex                 = 3,
		})
		Buttons[Item] = Button
		Button.Activated:Connect(function()
			Handle:Set(Item)
		end)
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue, Silent)
		Value = NewValue
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end
	end
	Render()
	return BlockHandle(Built, Handle)
end
function Controls.Range(Container, Options)
	local Handle = {}
	local Minimum = Options.Min or 0
	local Maximum = Options.Max or 100
	local Step = Options.Step or 1
	local Low = Clamp(Options.Low or Minimum, Minimum, Maximum)
	local High = Clamp(Options.High or Maximum, Minimum, Maximum)
	local Built = Row(Container, Options)
	Built.Frame.Size = UDim2.new(1, 0, 0, Metrics.RowHeightTall + 14)
	Built.TextColumn.AnchorPoint = Vector2.new(0, 0)
	Built.TextColumn.Position = UDim2.new(0, 0, 0, 10)
	Built.TextColumn.Size = UDim2.new(1, -100, 0, 0)
	local Readout = Text({
		Parent           = Built.Mount,
		Text             = "",
		TextSize         = Metrics.RowDescSize + 1,
		TextTransparency = Theme.TextSecondary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		AnchorPoint      = Vector2.new(1, 0),
		Position         = UDim2.new(1, 0, 0, 10),
		Size             = UDim2.new(0, 90, 0, 14),
		AutomaticSize    = Enum.AutomaticSize.None,
	})
	local Track = New("Frame", {
		Parent                 = Built.Frame,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.82,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, -14),
		Size                   = UDim2.new(1, 0, 0, Metrics.SliderTrack),
		ZIndex                 = 2,
	}, {
		Corner(2),
	})
	local Span = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
		ZIndex           = 2,
	}, {
		Corner(2),
	})
	local function Thumb()
		return New("Frame", {
			Parent           = Track,
			BackgroundColor3 = Theme.White,
			BorderSizePixel  = 0,
			AnchorPoint      = Vector2.new(0.5, 0.5),
			Position         = UDim2.new(0, 0, 0.5, 0),
			Size             = UDim2.new(0, Metrics.SliderThumbWidth, 0, Metrics.SliderThumbHeight),
			ZIndex           = 3,
		}, {
			Corner(1),
		})
	end
	local LowThumb, HighThumb = Thumb(), Thumb()
	local function Fraction(Value)
		return Maximum > Minimum and (Value - Minimum) / (Maximum - Minimum) or 0
	end
	local function Render(Role)
		local A, B = Fraction(Low), Fraction(High)
		Readout.Text = Options.Format and Options.Format(Low, High)
			or string.format("%s – %s", FormatNumber(Low, Step), FormatNumber(High, Step))
		Tween(Span, { Position = UDim2.new(A, 0, 0, 0), Size = UDim2.new(B - A, 0, 1, 0) }, Role or "snap")
		Tween(LowThumb, { Position = UDim2.new(A, 0, 0.5, 0) }, Role or "snap")
		Tween(HighThumb, { Position = UDim2.new(B, 0, 0.5, 0) }, Role or "snap")
	end
	local Grab = New("TextButton", {
		Parent                 = Built.Frame,
		BackgroundTransparency = 1,
		Text                   = "",
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 0, 1, -4),
		Size                   = UDim2.new(1, 0, 0, 22),
		ZIndex                 = 4,
	})
	local Stop = Draggable(Grab, Track, function(X)
		local Value = Clamp(Quantise(Minimum + X * (Maximum - Minimum), Step), Minimum, Maximum)
		if math.abs(Value - Low) <= math.abs(Value - High) then
			Low = math.min(Value, High)
		else
			High = math.max(Value, Low)
		end
		Render("drag")
		if Options.Callback then
			task.spawn(Options.Callback, Low, High)
		end
	end)
	function Handle:Get()
		return Low, High
	end
	function Handle:Set(NewLow, NewHigh, Silent)
		Low = Clamp(Quantise(NewLow, Step), Minimum, Maximum)
		High = Clamp(Quantise(NewHigh, Step), Low, Maximum)
		Render()
		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Low, High)
		end
	end
	function Handle:Destroy()
		Stop()
		Built.Frame:Destroy()
	end
	Render()
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Bars(Container, Options)
	local Handle = {}
	local Values = Options.Values or {}
	local Height = Options.Height or 64
	local Bars = {}
	local Built = Block(Container, Options, Height)
	New("UIListLayout", {
		Parent              = Built.Content,
		Padding             = UDim.new(0, 3),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		VerticalAlignment   = Enum.VerticalAlignment.Bottom,
	})
	local function Render()
		local Minimum, Maximum = Extent(Values, Options)
		local Range = Maximum - Minimum
		for Index, Value in Values do
			local Alpha = Range > 0 and (Value - Minimum) / Range or 0.5
			local Bar = Bars[Index]
			if not Bar then
				Bar = New("Frame", {
					Parent                 = Built.Content,
					BackgroundColor3       = Options.Color or Theme.White,
					BackgroundTransparency = 1,
					BorderSizePixel        = 0,
					Size                   = UDim2.new(1 / #Values, -3, 0, 0),
					LayoutOrder            = Index,
				}, {
					Corner(1),
				})
				Bars[Index] = Bar
				Tween(Bar, { BackgroundTransparency = 0.15 }, "fade")
			end
			Tween(Bar, {
				Size = UDim2.new(1 / #Values, -3, 0, math.max(1, Alpha * Height)),
			}, "toss")
		end
		for Index = #Values + 1, #Bars do
			local Bar = Bars[Index]
			if Bar then
				Tween(Bar, { BackgroundTransparency = 1 }, "exit")
				task.delay(MotionTime("exit"), function() Bar:Destroy() end)
				Bars[Index] = nil
			end
		end
	end
	function Handle:Get()
		return Values
	end
	function Handle:Set(NewValues)
		Values = NewValues
		Render()
	end
	function Handle:Push(Value, Limit)
		table.insert(Values, Value)
		while #Values > (Limit or Options.Limit or 24) do
			table.remove(Values, 1)
		end
		Render()
	end
	Render()
	return BlockHandle(Built, Handle)
end
function Controls.Ring(Container, Options)
	local Handle = {}
	local Value = Options.Default or 0
	local Maximum = Options.Max or 1
	local Count = Options.Ticks or 36
	local Radius = Options.Radius or 26
	local Built = Row(Container, Options)
	local Box = Radius * 2 + 6
	Built.Mount.Size = UDim2.new(0, Box, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -(Box + 18), 0, 0)
	Built.Frame.Size = UDim2.new(1, 0, 0, math.max(Metrics.RowHeightTall, Box + 14))
	local Dial = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Box, 0, Box),
	})
	local Ticks = {}
	for Index = 1, Count do
		local Angle = (Index - 1) / Count * math.pi * 2 - math.pi / 2
		Ticks[Index] = New("Frame", {
			Parent                 = Dial,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.85,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, math.cos(Angle) * Radius, 0.5, math.sin(Angle) * Radius),
			Size                   = UDim2.new(0, 5, 0, 1),
			Rotation               = math.deg(Angle),
		})
	end
	local Readout = Text({
		Parent         = Dial,
		Text           = "",
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoSize + 2,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})
	local function Render()
		local Alpha = Maximum > 0 and Clamp(Value / Maximum, 0, 1) or 0
		local Lit = math.floor(Alpha * Count + 0.5)
		SwapText(Readout, Options.Format and Options.Format(Value, Maximum)
			or string.format("%d%%", math.floor(Alpha * 100 + 0.5)))
		for Index, Tick in Ticks do
			Tween(Tick, {
				BackgroundTransparency = Index <= Lit and 0.05 or 0.85,
			}, "hover")
		end
	end
	function Handle:Get()
		return Value
	end
	function Handle:Set(NewValue)
		Value = NewValue
		Render()
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Render()
	Handle.Frame = Built.Frame
	return Handle
end
function Controls.Alert(Container, Options)
	local Handle = {}
	local Colour = Options.Color or Theme.Info
	local Frame = New("Frame", {
		Name                   = "Alert",
		Parent                 = Container,
		BackgroundColor3       = Colour,
		BackgroundTransparency = 0.94,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Corner(Metrics.RowRadius),
	})
	New("Frame", {
		Name             = "Accent",
		Parent           = Frame,
		BackgroundColor3 = Colour,
		BorderSizePixel  = 0,
		Position         = UDim2.new(0, 0, 0, 0),
		Size             = UDim2.new(0, 2, 1, 0),
		ZIndex           = 2,
	})
	local Column = New("Frame", {
		Name                   = "Column",
		Parent                 = Frame,
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 14, 0, 0),
		Size                   = UDim2.new(1, -28, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Padding(11, 0, 11, 0),
		List(3),
	})
	local Title = Text({
		Parent      = Column,
		Text        = Options.Label or "",
		FontFace    = Theme.FontMedium,
		TextSize    = Metrics.RowLabelSize - 2,
		TextColor3  = Colour,
		LayoutOrder = 1,
	})
	local Body = Text({
		Parent           = Column,
		Text             = Options.Text or "",
		TextSize         = Metrics.RowDescSize + 1,
		TextTransparency = Theme.TextSecondary,
		TextWrapped      = true,
		LayoutOrder      = 2,
	})
	Enter(Frame, "BackgroundTransparency", 0.94, "fade")
	function Handle:Set(NewTitle, NewText)
		if NewTitle then SwapText(Title, NewTitle) end
		if NewText then SwapText(Body, NewText) end
	end
	function Handle:Destroy()
		Frame:Destroy()
	end
	Handle.Frame = Frame
	return Handle
end
function Controls.Tree(Container, Options)
	local Handle = {}
	local Selected = nil
	local Rows = {}
	local Built = Block(Container, Options)
	local Canvas, Lines = Layered(Built.Content, 1)
	local Order = 0
	local Mark = SlidingMark(Canvas)
	local function Render()
		local Chosen = nil
		for _, Row in Rows do
			local On = Row.Node == Selected
			if On and Row.Entry.Visible then
				Chosen = Row.Entry
			end
			Tween(Row.Label, { TextTransparency = On and Theme.TextPrimary or Theme.TextSecondary }, "hover")
		end
		Mark:To(Chosen, Canvas)
	end
	local function Build(Nodes, Depth, Parent)
		for _, Node in Nodes do
			Order += 1
			local Children = Node.Children or {}
			local Open = Node.Open == true
			local Entry = New("TextButton", {
				Parent                 = Lines,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Text                   = "",
				Size                   = UDim2.new(1, 0, 0, 22),
				LayoutOrder            = Order,
				Visible                = Parent == nil or Parent.Expanded,
			})
			local Indent = 10 + Depth * 14
			local Twist = nil
			if #Children > 0 then
				Twist = New("Frame", {
					Parent                 = Entry,
					BackgroundTransparency = 1,
					AnchorPoint            = Vector2.new(0, 0.5),
					Position               = UDim2.new(0, Indent - 9, 0.5, 0),
					Size                   = UDim2.new(0, 9, 0, 9),
				})
				for Index = 1, 2 do
					New("Frame", {
						Parent                 = Twist,
						BackgroundColor3       = Theme.White,
						BackgroundTransparency = Theme.TextTertiary,
						BorderSizePixel        = 0,
						AnchorPoint            = Vector2.new(0.5, 0.5),
						Position               = UDim2.new(0.5, 0, Index == 1 and 0.3 or 0.7, 0),
						Size                   = UDim2.new(0, 6, 0, 1),
						Rotation               = Open
							and (Index == 1 and -40 or 40)
							or (Index == 1 and 40 or -40),
					})
				end
			end
			local Label = Text({
				Parent           = Entry,
				Text             = tostring(Node.Label or ""),
				TextSize         = Metrics.RowDescSize + 1,
				TextTransparency = Theme.TextSecondary,
				TextYAlignment   = Enum.TextYAlignment.Center,
				Position         = UDim2.new(0, Indent + 4, 0, 0),
				Size             = UDim2.new(1, -(Indent + 8), 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
			})
			local Record = {
				Node     = Node,
				Entry    = Entry,
				Label    = Label,
				Twist    = Twist,
				Expanded = Open,
				Kids     = {},
				Parent   = Parent,
			}
			table.insert(Rows, Record)
			if Parent then
				table.insert(Parent.Kids, Record)
			end
			Entry.MouseEnter:Connect(function()
				Tween(Entry, { BackgroundTransparency = 0.94 }, "hover")
			end)
			Entry.MouseLeave:Connect(function()
				Tween(Entry, { BackgroundTransparency = 1 }, "hover")
			end)
			Entry.Activated:Connect(function()
				if #Children > 0 then
					Record.Expanded = not Record.Expanded
					if Twist then
						for Index, Arm in Twist:GetChildren() do
							if Arm:IsA("Frame") then
								Tween(Arm, {
									Rotation = Record.Expanded
										and (Index == 1 and -40 or 40)
										or (Index == 1 and 40 or -40),
								}, "morph")
							end
						end
					end
					local function Apply(Row, Visible)
						for _, Kid in Row.Kids do
							Kid.Entry.Visible = Visible
							Apply(Kid, Visible and Kid.Expanded)
						end
					end
					Apply(Record, Record.Expanded)
				end
				Selected = Node
				Render()
				if Options.Callback then
					task.spawn(Options.Callback, Node)
				end
			end)
			Build(Children, Depth + 1, Record)
		end
	end
	Build(Options.Nodes or {}, 0, nil)
	function Handle:Get()
		return Selected
	end
	function Handle:Set(Node)
		Selected = Node
		Render()
	end
	Render()
	return BlockHandle(Built, Handle)
end
function Controls.Image(Container, Options)
	local Handle = {}
	local Built = Block(Container, Options, Options.Height or 140)
	local Fit = Options.Fit == "Cover" and Enum.ScaleType.Crop
		or Options.Fit == "Stretch" and Enum.ScaleType.Stretch
		or Enum.ScaleType.Fit
	local Holder = New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = 0.65,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ClipsDescendants       = true,
	}, {
		Corner(Metrics.ChipRadius),
	})
	local Picture = New("ImageLabel", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Image                  = Options.Image or "",
		ImageTransparency      = 1,
		ScaleType              = Fit,
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	local function Reveal()
		Tween(Picture, { ImageTransparency = Options.Transparency or 0 }, "fade")
	end
	if Picture.IsLoaded then
		task.defer(Reveal)
	else
		Picture:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if Picture.IsLoaded then
				Reveal()
			end
		end)
		task.delay(3, Reveal)
	end
	local Caption = nil
	if Options.Caption then
		Caption = Text({
			Parent           = Built.Content,
			Text             = Options.Caption,
			TextSize         = Metrics.RowDescSize,
			TextTransparency = Theme.TextTertiary,
			TextWrapped      = true,
			Position         = UDim2.new(0, 0, 1, 4),
			Size             = UDim2.new(1, 0, 0, 0),
		})
		Built.Content.Size = UDim2.new(1, 0, 0, (Options.Height or 140) + 18)
	end
	function Handle:Set(NewImage)
		Picture.ImageTransparency = 1
		Picture.Image = NewImage
		Reveal()
	end
	function Handle:SetCaption(NewCaption)
		if Caption then
			SwapText(Caption, NewCaption)
		end
	end
	Handle.Picture = Picture
	return BlockHandle(Built, Handle)
end
function Controls.Link(Container, Options)
	local Handle = {}
	local Url = Options.Url or ""
	local Built = Row(Container, Options)
	Built.Mount.Size = UDim2.new(0, 74, 1, 0)
	Built.TextColumn.Size = UDim2.new(1, -92, 0, 0)
	Built.Label.Text = string.format(
		'<font color="%s"><u>%s</u></font>',
		Hex(Options.Color or Theme.Info),
		Options.Label or Url
	)
	local Pill = New("Frame", {
		Parent           = Built.Mount,
		BackgroundColor3 = Options.Color or Theme.Info,
		BackgroundTransparency = 0.82,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, 0, 0.5, 0),
		Size             = UDim2.new(0, 74, 0, Metrics.TabHeight - 4),
	}, {
		Corner(math.min(Metrics.PillRadius, 13)),
	})
	New("TextLabel", {
		Parent                 = Pill,
		BackgroundTransparency = 1,
		Text                   = Options.Action or "Open",
		TextColor3             = Options.Color or Theme.Info,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.RowDescSize + 1,
		Size                   = UDim2.new(1, 0, 1, 0),
	})
	local Button = New("TextButton", {
		Parent                 = Built.Frame,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})
	Button.MouseEnter:Connect(function()
		Tween(Pill, { BackgroundTransparency = 0.68 }, "hover")
	end)
	Button.MouseLeave:Connect(function()
		Tween(Pill, { BackgroundTransparency = 0.82 }, "hover")
	end)
	function Handle:Get()
		return Url
	end
	function Handle:Set(NewUrl)
		Url = NewUrl
	end
	function Handle:Destroy()
		Built.Frame:Destroy()
	end
	Button.Activated:Connect(function()
		Tween(Pill, { BackgroundTransparency = 0.5 }, "press")
		task.delay(MotionTime("press"), function()
			Tween(Pill, { BackgroundTransparency = 0.82 }, "hover")
		end)
		local Opened = pcall(function()
			game:GetService("GuiService"):OpenBrowserWindow(Url)
		end)
		if Options.Callback then
			task.spawn(Options.Callback, Url, Opened)
		end
	end)
	Handle.Frame = Built.Frame
	return Handle
end
function Attach(Object)
	for Name, Constructor in Controls do
		Object[Name] = function(Self, Options)
			Options = Options or {}
			Options.LayoutOrder = Options.LayoutOrder or Self:_Order()
			return Constructor(Self:_Mount(), Options, Self)
		end
	end
	return Object
end
local function MakeSection(Window, Title, Description)
	local Section = {}
	local Frame = New("Frame", {
		Name                   = "Section",
		Parent                 = Window.Body,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Window:_Order(),
	}, {
		Padding(18, 14, 4, 14),
		List(3),
	})
	Text({
		Parent      = Frame,
		Text        = Title or "",
		TextSize    = Metrics.SectionTitleSize,
		LayoutOrder = 1,
	})
	if Description and Description ~= "" then
		Text({
			Parent           = Frame,
			Text             = Description,
			TextSize         = Metrics.SectionDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	function Section:_Mount()
		return Window.Body
	end
	function Section:_Order()
		return Window:_Order()
	end
	function Section:_Overlay()
		return Window:_Overlay()
	end
	function Section:_Register(Close)
		Window:_Register(Close)
	end
	function Section:Tabs(Options)
		return Window:_MakeTabs(Options)
	end
	function Section:Destroy()
		Frame:Destroy()
	end
	Section.Frame = Frame
	return Attach(Section)
end
local function MakeTabs(Window, Options)
	Options = Options or {}
	local Tabs = {}
	local Pages = {}
	local Active = nil
	local Bar = New("Frame", {
		Name                   = "Tabs",
		Parent                 = Window.Body,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Metrics.TabHeight + 14),
		LayoutOrder            = Window:_Order(),
	}, {
		Padding(7, 14, 7, 14),
	})
	local Viewport = New("ScrollingFrame", {
		Name                   = "Viewport",
		Parent                 = Bar,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.X,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.X,
		ClipsDescendants       = true,
	})
	local Strip = New("Frame", {
		Name                   = "Strip",
		Parent                 = Viewport,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 2,
	}, {
		List(Metrics.TabGap, Enum.FillDirection.Horizontal,
			Options.Align == "Center" and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left),
	})
	local Highlight = New("Frame", {
		Name             = "Highlight",
		Parent           = Viewport,
		BackgroundColor3 = Theme.White,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 0, Metrics.TabHeight),
		Position         = UDim2.new(0, 0, 0, 0),
		Visible          = false,
		ZIndex           = 1,
	}, {
		Corner(math.min(Metrics.PillRadius, math.floor(Metrics.TabHeight / 2))),
	})
	local Scroller = SmoothScroll(Viewport, "X")
	Bar.MouseEnter:Connect(function()
		if Window.Scroll then
			Window.Scroll:SetEnabled(false)
		end
	end)
	Bar.MouseLeave:Connect(function()
		if Window.Scroll then
			Window.Scroll:SetEnabled(true)
		end
	end)
	local function Reveal(Button)
		local Span = Viewport.AbsoluteCanvasSize.X - Viewport.AbsoluteSize.X
		if Span <= 0 then
			return
		end
		local Left = Button.AbsolutePosition.X - Strip.AbsolutePosition.X
		local Right = Left + Button.AbsoluteSize.X
		local Start = Viewport.CanvasPosition.X
		local Finish = Start + Viewport.AbsoluteSize.X
		local Target = Start
		if Left < Start + 12 then
			Target = Left - 12
		elseif Right > Finish - 12 then
			Target = Right - Viewport.AbsoluteSize.X + 12
		end
		Target = Clamp(Target, 0, Span)
		if math.abs(Target - Start) > 0.5 then
			Scroller:To(Vector2.new(Target, 0))
		end
	end
	local function MoveHighlight(Button, Animate)
		local Target = UDim2.new(0, Button.AbsolutePosition.X - Strip.AbsolutePosition.X, 0, 0)
		local Size = UDim2.new(0, Button.AbsoluteSize.X, 0, Metrics.TabHeight)
		Highlight.Visible = true
		if Animate then
			Tween(Highlight, { Position = Target, Size = Size }, "morph")
		else
			Highlight.Position = Target
			Highlight.Size = Size
		end
	end
	function Tabs:Select(Name)
		local Entry = Pages[Name]
		if not Entry or Active == Name then
			return
		end
		for OtherName, Other in Pages do
			local Selected = OtherName == Name
			if Selected then
				Other.Page.Visible = true
				Other.Page.GroupTransparency = 1
				Other.Slide.PaddingTop = UDim.new(0, 12)
				Tween(Other.Page, { GroupTransparency = 0 }, "expand")
				Tween(Other.Slide, { PaddingTop = UDim.new(0, 0) }, "reveal")
			else
				Other.Page.Visible = false
			end
			Tween(Other.Label, {
				TextColor3       = Selected and Theme.Black or Theme.White,
				TextTransparency = Selected and 0 or Theme.TextSecondary,
			}, "hover")
			if Other.Icon then
				Tween(Other.Icon, {
					ImageColor3       = Selected and Theme.Black or Theme.White,
					ImageTransparency = Selected and 0 or Theme.TextSecondary,
				}, "hover")
			end
		end
		Entry.Label.TextColor3 = Theme.Black
		Entry.Label.TextTransparency = 0
		if Entry.Icon then
			Entry.Icon.ImageColor3 = Theme.Black
			Entry.Icon.ImageTransparency = 0
		end
		MoveHighlight(Entry.Button, Active ~= nil)
		Reveal(Entry.Button)
		Active = Name
		if Options.Callback then
			task.spawn(Options.Callback, Name)
		end
	end
	function Tabs:Active()
		return Active
	end
	function Tabs:Page(Name, Icon)
		local Button = New("TextButton", {
			Name                   = Name,
			Parent                 = Strip,
			BackgroundTransparency = 1,
			Text                   = "",
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, Metrics.TabHeight),
			LayoutOrder            = #Strip:GetChildren(),
			ZIndex                 = 3,
		}, {
			Padding(0, Metrics.TabPadding),
		})
		New("UIListLayout", {
			Parent              = Button,
			Padding             = UDim.new(0, 8),
			FillDirection       = Enum.FillDirection.Horizontal,
			SortOrder           = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
		})
		local IconLabel = nil
		if Icon then
			IconLabel = New("ImageLabel", {
				Parent                 = Button,
				BackgroundTransparency = 1,
				Image                  = Icon,
				ImageColor3            = Theme.White,
				ImageTransparency      = Theme.TextSecondary,
				Size                   = UDim2.new(0, Metrics.TabIcon, 0, Metrics.TabIcon),
				LayoutOrder            = 1,
				ZIndex                 = 4,
			})
		end
		local Label = New("TextLabel", {
			Parent                 = Button,
			BackgroundTransparency = 1,
			Text                   = Name,
			TextColor3             = Theme.White,
			TextTransparency       = Theme.TextSecondary,
			FontFace               = Theme.Font,
			TextSize               = Metrics.RowDescSize + 3,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			LayoutOrder            = 2,
			ZIndex                 = 4,
		})
		local Page = New("CanvasGroup", {
			Name                   = "Page_" .. Name,
			Parent                 = Window.Body,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			GroupTransparency      = 1,
			Visible                = false,
			LayoutOrder            = Window:_Order(),
		}, {
			List(Metrics.RowGap),
		})
		local Slide = New("UIPadding", {
			Parent     = Page,
			PaddingTop = UDim.new(0, 0),
		})
		local Order = 0
		local Handle = {
			Frame  = Page,
			Button = Button,
		}
		function Handle:_Mount()
			return Page
		end
		function Handle:_Order()
			Order += 1
			return Order
		end
		function Handle:_Overlay()
			return Window:_Overlay()
		end
		function Handle:_Register(Close)
			Window:_Register(Close)
		end
		function Handle:Destroy()
			Page:Destroy()
			Button:Destroy()
			Pages[Name] = nil
		end
		Pages[Name] = {
			Page   = Page,
			Slide  = Slide,
			Button = Button,
			Label  = Label,
			Icon   = IconLabel,
		}
		Button.Activated:Connect(function()
			Tabs:Select(Name)
		end)
		if Active == nil then
			task.defer(function()
				if Active == nil then
					Tabs:Select(Name)
				end
			end)
		end
		return Attach(Handle)
	end
	function Tabs:Destroy()
		Bar:Destroy()
		for _, Entry in Pages do
			Entry.Page:Destroy()
		end
	end
	Tabs.Frame = Bar
	return Tabs
end
local Kuik = {}
Kuik.Theme   = Theme
Kuik.Metrics = Metrics
Kuik.Version = VERSION
function Kuik.Window(Options)
	Options = Options or {}
	local Window = {}
	local Order = 0
	local Shown = false
	local Blur = nil
	local ParallaxConnection = nil
	local KeyConnection = nil
	local Width  = Options.Width or Metrics.WindowWidth
	local Height = Options.Height or Metrics.WindowHeight
	local Backdrop = New("Frame", {
		Name                   = "Backdrop",
		Parent                 = Screen(),
		BackgroundColor3       = Options.WashColor or Theme.Scrim,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		Visible                = false,
		ZIndex                 = 1,
	})
	local Wash = Options.Wash == nil and 0.55 or Options.Wash
	local BlurSize = Options.Blur == nil and 22 or Options.Blur
	local Root = New("Frame", {
		Name                   = "Window",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Height),
		Visible                = false,
		ZIndex                 = 2,
	})
	local Group = New("CanvasGroup", {
		Name                   = "Group",
		Parent                 = Root,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		GroupTransparency      = 1,
	})
	local LeftRule = New("Frame", {
		Name                   = "LeftRule",
		Parent                 = Group,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(0, 1, 0, 0),
		ZIndex                 = 3,
	})
	local RightRule = New("Frame", {
		Name                   = "RightRule",
		Parent                 = Group,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = Theme.RuleTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, 1, 0, 0),
		ZIndex                 = 3,
	})
	local Content = New("Frame", {
		Name                   = "Content",
		Parent                 = Group,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ClipsDescendants       = true,
	}, {
		Padding(20, Metrics.WindowPadding - 14, 14, Metrics.WindowPadding - 14),
	})
	local Header = New("Frame", {
		Name                   = "Header",
		Parent                 = Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Padding(0, 14),
		List(1),
	})
	Text({
		Parent      = Header,
		Text        = Options.Title or "",
		TextSize    = Metrics.TitleSize,
		LayoutOrder = 1,
	})
	if Options.Subtitle then
		Text({
			Parent           = Header,
			Text             = Options.Subtitle,
			TextSize         = Metrics.SubtitleSize,
			TextTransparency = Theme.TextSecondary,
			LayoutOrder      = 2,
		})
	end
	local Body = New("ScrollingFrame", {
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
		List(Metrics.RowGap),
	})
	Window.Scroll = SmoothScroll(Body, "Y")
	local function Reflow()
		local Top = Header.AbsoluteSize.Y + 18
		Body.Position = UDim2.new(0, 0, 0, Top)
		Body.Size = UDim2.new(1, 0, 1, -Top)
	end
	Header:GetPropertyChangedSignal("AbsoluteSize"):Connect(Reflow)
	task.defer(Reflow)
	local Modal = New("TextButton", {
		Name                   = "Modal",
		Parent                 = Root,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(0, 0, 0, 0),
		Modal                  = Options.UnlockMouse ~= false,
		Visible                = false,
	})
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
	Window.Group    = Group
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
	local Poppers = {}
	local Children = {}
	function Window:_Register(Close)
		table.insert(Poppers, Close)
	end
	function Window:_ClosePopovers()
		for _, Close in Poppers do
			Close()
		end
	end
	function Window:Section(Title, Description)
		return MakeSection(self, Title, Description)
	end
	function Window:_MakeTabs(TabOptions)
		return MakeTabs(self, TabOptions)
	end
	function Window:Tabs(TabOptions)
		return MakeTabs(self, TabOptions)
	end
	function Window:IsOpen()
		return Shown
	end
	function Window:Open()
		if Shown then
			return
		end
		Shown = true
		Root.Visible = true
		Modal.Visible = true
		Backdrop.Visible = true
		if BlurSize > 0 then
			if not Blur then
				Blur = New("BlurEffect", { Parent = Lighting, Size = 0, Name = "KuikBlur" })
			end
			Tween(Blur, { Size = BlurSize }, "enter")
		end
		Tween(Backdrop, { BackgroundTransparency = Wash }, "enter")
		Tween(Group, { GroupTransparency = 0 }, "enter")
		Tween(LeftRule, { Size = UDim2.new(0, 1, 1, 0) }, "reveal")
		Tween(RightRule, { Size = UDim2.new(0, 1, 1, 0) }, "reveal")
	end
	function Window:Close()
		if not Shown then
			return
		end
		self:_ClosePopovers()
		for _, Child in Children do
			Child:Close()
		end
		Shown = false
		Modal.Visible = false
		if Blur then
			Tween(Blur, { Size = 0 }, "exit")
		end
		Tween(Backdrop, { BackgroundTransparency = 1 }, "exit")
		Tween(Group, { GroupTransparency = 1 }, "exit")
		Tween(LeftRule, { Size = UDim2.new(0, 1, 0, 0) }, "exit")
		local Handle = Tween(RightRule, { Size = UDim2.new(0, 1, 0, 0) }, "exit")
		Handle.Completed:Once(function()
			if not Shown then
				Root.Visible = false
				Backdrop.Visible = false
			end
		end)
	end
	function Window:SetOpen(Open)
		if Open then
			self:Open()
		else
			self:Close()
		end
	end
	Window.Show = Window.Open
	Window.Hide = Window.Close
	function Window:SetParallax(Amount)
		if ParallaxConnection then
			ParallaxConnection:Disconnect()
			ParallaxConnection = nil
		end
		if not Amount or Amount <= 0 then
			Root.Position = UDim2.new(0.5, 0, 0.5, 0)
			return
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
				if YawDelta > math.pi then
					YawDelta -= math.pi * 2
				elseif YawDelta < -math.pi then
					YawDelta += math.pi * 2
				end
				Offset += Vector2.new(YawDelta, Pitch - LastPitch) * Amount * 30
			end
			LastYaw, LastPitch = Yaw, Pitch
			Offset = Offset:Lerp(Vector2.zero, math.min(1, Delta * 7))
			Offset = Vector2.new(
				Clamp(Offset.X, -Amount, Amount),
				Clamp(Offset.Y, -Amount, Amount)
			)
			Root.Position = UDim2.new(0.5, Offset.X, 0.5, Offset.Y)
		end)
	end
	function Window:Child(ChildOptions)
		ChildOptions = ChildOptions or {}
		local Child = Kuik.Window({
			Title       = ChildOptions.Title,
			Subtitle    = ChildOptions.Subtitle,
			Width       = ChildOptions.Width or 300,
			Height      = ChildOptions.Height or 320,
			Blur        = ChildOptions.Blur or 0,
			Wash        = ChildOptions.Wash or 1,
			UnlockMouse = false,
		})
		Child.Root.Parent = Root
		Child.Root.AnchorPoint = Vector2.new(0, 0.5)
		Child.Root.Position = UDim2.new(1, ChildOptions.Offset or 34, 0.5, 0)
		if Child.Backdrop then
			Child.Backdrop:Destroy()
		end
		Child.Owner = Window
		table.insert(Children, Child)
		if ChildOptions.Open then
			Child:Open()
		end
		return Child
	end
	function Window:Children()
		return Children
	end
	function Window:Destroy()
		for _, Child in Children do
			Child:Destroy()
		end
		table.clear(Children)
		if ParallaxConnection then
			ParallaxConnection:Disconnect()
		end
		if KeyConnection then
			KeyConnection:Disconnect()
		end
		if Blur then
			Blur:Destroy()
		end
		Root:Destroy()
		Backdrop:Destroy()
	end
	local function Fit()
		local Viewport = Screen().AbsoluteSize
		if Viewport.X > 0 then
			Root.Size = UDim2.new(
				0, math.min(Width, Viewport.X - 40),
				0, math.min(Height, Viewport.Y - 80)
			)
		end
	end
	Screen():GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
	task.defer(Fit)
	if Options.Key then
		KeyConnection = UserInputService.InputBegan:Connect(function(Input, Processed)
			if not Processed and Input.KeyCode == Options.Key then
				Window:SetOpen(not Shown)
			end
		end)
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
function Kuik.Toast(Message, Options)
	Options = Options or {}
	local Holder = New("Frame", {
		Name                   = "Toast",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, Options.Y or 58),
		Size                   = UDim2.new(0, 0, 0, 18),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 5,
	})
	New("UIListLayout", {
		Parent              = Holder,
		Padding             = UDim.new(0, 10),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
	})
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
		TextSize               = Metrics.RowDescSize + 2,
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
		Label.Text = NewText
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	if Options.Duration and Options.Duration > 0 then
		task.delay(Options.Duration, function()
			if Holder.Parent then
				Tween(Label, { TextTransparency = 1 }, "fade")
				for _, Child in Holder:GetChildren() do
					if Child:IsA("Frame") then
						Tween(Child, { BackgroundTransparency = 1 }, "fade")
					end
				end
				task.delay(MotionTime("fade"), function()
					Holder:Destroy()
				end)
			end
		end)
	end
	return Handle
end
function Kuik.Notify(Options)
	Options = Options or {}
	local Card = New("Frame", {
		Name                   = "Notify",
		Parent                 = Screen(),
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = 0.25,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 1),
		Position               = UDim2.new(0.5, 0, 0, 0),
		Size                   = UDim2.new(0, Options.Width or 260, 0, 46),
		ZIndex                 = 6,
	}, {
		Corner(Metrics.CardRadius),
		Padding(0, 14),
	})
	New("UIListLayout", {
		Parent              = Card,
		Padding             = UDim.new(0, 10),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
	})
	if Options.Image then
		New("ImageLabel", {
			Parent                 = Card,
			BackgroundTransparency = 1,
			Image                  = Options.Image,
			Size                   = UDim2.new(0, 24, 0, 24),
			LayoutOrder            = 1,
		}, {
			Corner(math.min(Metrics.PillRadius, 12)),
		})
	end
	New("TextLabel", {
		Parent                 = Card,
		BackgroundTransparency = 1,
		Text                   = Options.Title or "",
		TextColor3             = Theme.White,
		FontFace               = Theme.FontMedium,
		TextSize               = Metrics.RowLabelSize - 2,
		TextXAlignment         = Enum.TextXAlignment.Left,
		RichText               = true,
		AutomaticSize          = Enum.AutomaticSize.X,
		Size                   = UDim2.new(0, 0, 1, 0),
		LayoutOrder            = 2,
	})
	Tween(Card, { Position = UDim2.new(0.5, 0, 0, 62) }, "toss")
	local Handle = { Frame = Card }
	function Handle:Destroy()
		Tween(Card, { Position = UDim2.new(0.5, 0, 0, 0) }, "exit")
		task.delay(MotionTime("exit"), function()
			Card:Destroy()
		end)
	end
	task.delay(Options.Duration or 4, function()
		if Card.Parent then
			Handle:Destroy()
		end
	end)
	return Handle
end
function Kuik.Hints(Options)
	Options = Options or {}
	local Holder = New("Frame", {
		Name                   = "Hints",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -14, 0.5, Options.Y or 0),
		Size                   = UDim2.new(0, 240, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 4,
	}, {
		List(9, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right),
	})
	local Hints = { Frame = Holder }
	local Order = 0
	function Hints:Add(Key, Action)
		Order += 1
		local Line = New("Frame", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, 14),
			LayoutOrder            = Order,
		})
		New("UIListLayout", {
			Parent              = Line,
			Padding             = UDim.new(0, 7),
			FillDirection       = Enum.FillDirection.Horizontal,
			SortOrder           = Enum.SortOrder.LayoutOrder,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
		})
		Keycap(Line, 12).LayoutOrder = 1
		local Label = New("TextLabel", {
			Parent                 = Line,
			BackgroundTransparency = 1,
			RichText               = true,
			Text                   = string.format(
				'<font color="#ffffff">%s</font>  <font transparency="0.45">%s</font>',
				Key, Action
			),
			TextColor3             = Theme.White,
			FontFace               = Theme.FontMedium,
			TextSize               = Metrics.RowDescSize + 1,
			TextXAlignment         = Enum.TextXAlignment.Left,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			LayoutOrder            = 2,
		})
		return {
			Frame = Line,
			Destroy = function()
				Line:Destroy()
			end,
			Set = function(_, NewKey, NewAction)
				Label.Text = string.format(
					'<font color="#ffffff">%s</font>  <font transparency="0.45">%s</font>',
					NewKey, NewAction
				)
			end,
		}
	end
	function Hints:Destroy()
		Holder:Destroy()
	end
	return Hints
end
function Kuik.Log(Options)
	Options = Options or {}
	local Limit = Options.Limit or 8
	local Holder = New("Frame", {
		Name                   = "Log",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.new(0, 14, 1, -(Options.Bottom or 34)),
		Size                   = UDim2.new(0, Options.Width or 262, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 4,
	})
	Rule(Holder, Vector2.new(0, 0)).Position = UDim2.new(0, 0, 0, 0)
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
	local Log = { Frame = Holder }
	local Entries = {}
	local Order = 0
	function Log:Push(Message)
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
			TextSize    = Metrics.RowDescSize + 1,
			TextWrapped = true,
			Position    = UDim2.new(0, 18, 0, 0),
			Size        = UDim2.new(1, -18, 0, 0),
		})
		table.insert(Entries, Line)
		while #Entries > Limit do
			local Oldest = table.remove(Entries, 1)
			Oldest:Destroy()
		end
		Line.BackgroundTransparency = 1
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
function Kuik.Console(Options)
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
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.new(1, -14, 0, Options.Y or 36),
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
		local Colour = Levels[string.upper(Level or "INFO")] or Theme.Neutral
		local Hex = string.format("#%02x%02x%02x",
			math.floor(Colour.R * 255 + 0.5),
			math.floor(Colour.G * 255 + 0.5),
			math.floor(Colour.B * 255 + 0.5)
		)
		local Label = New("TextLabel", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			RichText               = true,
			Text                   = string.format(
				'<font color="%s">%s</font> %s',
				Hex, string.upper(Level or "INFO"), Message
			),
			TextColor3             = Theme.White,
			FontFace               = Theme.FontMono,
			TextSize               = Metrics.MonoSize + 1,
			TextXAlignment         = Enum.TextXAlignment.Right,
			AutomaticSize          = Enum.AutomaticSize.XY,
			Size                   = UDim2.new(0, 0, 0, 0),
			LayoutOrder            = Order,
		})
		task.delay(Duration or Options.Duration or 6, function()
			if Label.Parent then
				Tween(Label, { TextTransparency = 1 }, "fade")
				task.delay(MotionTime("fade"), function()
					Label:Destroy()
				end)
			end
		end)
		return Label
	end
	function Console:Destroy()
		Holder:Destroy()
	end
	return Console
end
function Kuik.Watermark(Options)
	Options = Options or {}
	local Side = Options.Side or "Left"
	local Holder = New("Frame", {
		Name                   = "Watermark",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(Side == "Right" and 1 or 0, 1),
		Position               = UDim2.new(Side == "Right" and 1 or 0, Side == "Right" and -14 or 14, 1, -6),
		Size                   = UDim2.new(0, 0, 0, 12),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 4,
	})
	New("UIListLayout", {
		Parent              = Holder,
		Padding             = UDim.new(0, 22),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
	})
	local Watermark = { Frame = Holder }
	local Labels = {}
	local function Field(Index, Content, Colour)
		local Label = Labels[Index]
		if not Label then
			Label = New("TextLabel", {
				Parent                 = Holder,
				BackgroundTransparency = 1,
				RichText               = true,
				TextColor3             = Colour or Theme.White,
				TextTransparency       = Colour and 0 or Theme.TextSecondary,
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
		if Colour then
			Label.TextColor3 = Colour
			Label.TextTransparency = 0
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
	end
	function Watermark:SetSide(NewSide)
		Side = NewSide
		Holder.AnchorPoint = Vector2.new(NewSide == "Right" and 1 or 0, 1)
		Holder.Position = UDim2.new(NewSide == "Right" and 1 or 0, NewSide == "Right" and -14 or 14, 1, -6)
	end
	function Watermark:Destroy()
		Holder:Destroy()
	end
	if Options.Fields then
		Watermark:Set(Options.Fields)
	end
	return Watermark
end
function Kuik.Timer(Options)
	Options = Options or {}
	local Handle = {}
	local Value = Options.Seconds or 0
	local Running = false
	local Holder = New("Frame", {
		Name                   = "Timer",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, Options.Y or 56),
		Size                   = UDim2.new(0, 0, 0, 20),
		AutomaticSize          = Enum.AutomaticSize.X,
		ZIndex                 = 5,
	})
	New("UIListLayout", {
		Parent              = Holder,
		Padding             = UDim.new(0, 9),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
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
		New("UIStroke", { Color = Theme.White, Transparency = 0.3, Thickness = 1 }),
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
		TextSize               = Metrics.RowDescSize + 3,
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
	end
	function Handle:Start()
		if Running then
			return
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
	end
	function Handle:Stop()
		Running = false
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
function Kuik.Ammo(Options)
	Options = Options or {}
	local Handle = {}
	local Magazine = Options.Magazine or 0
	local Reserve = Options.Reserve or 0
	local Holder = New("Frame", {
		Name                   = "Ammo",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 1),
		Position               = UDim2.new(1, -(Options.X or 240), 1, -(Options.Y or 90)),
		Size                   = UDim2.new(0, 130, 0, 44),
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
		TextSize               = Metrics.RowDescSize,
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
		TextSize               = Metrics.RowLabelSize + 6,
		TextXAlignment         = Enum.TextXAlignment.Center,
		AnchorPoint            = Vector2.new(0.5, 1),
		Position               = UDim2.new(0.5, 0, 1, 0),
		Size                   = UDim2.new(1, -20, 0, 26),
		RichText               = true,
		Rotation               = Options.Rotation or -8,
	})
	local function Render()
		local Colour = Magazine == 0 and Theme.Danger
			or Magazine <= math.max(1, math.floor((Options.Capacity or Magazine) * 0.25)) and Theme.Warn
			or Theme.White
		Count.Text = string.format('<font color="%s">%d</font><font transparency="0.55">/%d</font>',
			Hex(Colour), Magazine, Reserve)
	end
	function Handle:Get()
		return Magazine, Reserve
	end
	function Handle:Set(NewMagazine, NewReserve)
		Magazine = NewMagazine or Magazine
		Reserve = NewReserve or Reserve
		Render()
	end
	function Handle:SetWeapon(Weapon)
		SwapText(Name, Weapon)
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	Render()
	return Handle
end
function Kuik.Crosshair(Options)
	Options = Options or {}
	local Handle = {}
	local Gap = Options.Gap or 5
	local Length = Options.Length or 6
	local Holder = New("Frame", {
		Name                   = "Crosshair",
		Parent                 = Screen(),
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
	local function Render(Spread, Role)
		local Reach = Gap + (Spread or 0)
		Tween(Ticks[1], { Position = UDim2.new(0.5, 0, 0.5, -Reach) }, Role or "drag")
		Tween(Ticks[2], { Position = UDim2.new(0.5, 0, 0.5, Reach) }, Role or "drag")
		Tween(Ticks[3], { Position = UDim2.new(0.5, -Reach, 0.5, 0) }, Role or "drag")
		Tween(Ticks[4], { Position = UDim2.new(0.5, Reach, 0.5, 0) }, Role or "drag")
	end
	function Handle:SetSpread(Spread)
		Render(Spread)
	end
	function Handle:Hit(Colour)
		for _, Tick in Ticks do
			Tick.BackgroundColor3 = Colour or Theme.Danger
			Tween(Tick, { BackgroundColor3 = Options.Color or Theme.White }, "fade")
		end
		Render(6, "toss")
		task.delay(0.08, function() Render(0, "toss") end)
	end
	function Handle:SetVisible(Visible)
		Holder.Visible = Visible
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	Render(0, "instant")
	return Handle
end
function Kuik.Killfeed(Options)
	Options = Options or {}
	local Limit = Options.Limit or 5
	local Holder = New("Frame", {
		Name                   = "Killfeed",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.new(1, -14, 0, Options.Y or 74),
		Size                   = UDim2.new(0, Options.Width or 340, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 5,
	}, {
		List(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right),
	})
	local Feed = { Frame = Holder }
	local Lines = {}
	local Order = 0
	function Feed:Push(Actor, Verb, Target, Colour)
		Order += 1
		local Line = New("TextLabel", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			RichText               = true,
			Text                   = string.format(
				'<font color="%s">%s</font>  <font transparency="0.5">%s</font>  <font color="%s">%s</font>',
				Hex(Colour or Theme.White), Actor,
				Verb or "eliminated",
				Hex(Theme.Danger), Target),
			TextColor3             = Theme.White,
			TextTransparency       = 1,
			FontFace               = Theme.FontMedium,
			TextSize               = Metrics.RowDescSize + 1,
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
			if Line.Parent then
				Tween(Line, { TextTransparency = 1 }, "fade")
				task.delay(MotionTime("fade"), function()
					local At = table.find(Lines, Line)
					if At then
						table.remove(Lines, At)
					end
					Line:Destroy()
				end)
			end
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
function Kuik.Objective(Options)
	Options = Options or {}
	local Handle = {}
	local Holder = New("Frame", {
		Name                   = "Objective",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0, 0),
		Position               = UDim2.new(0, Options.X or 14, 0, Options.Y or 74),
		Size                   = UDim2.new(0, Options.Width or 260, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		ZIndex                 = 5,
	}, {
		Padding(0, 0, 0, 12),
		List(3),
	})
	Rule(Holder, Vector2.new(0, 0)).Position = UDim2.new(0, 0, 0, 0)
	local Label = Text({
		Parent           = Holder,
		Text             = Options.Label or "OBJECTIVE",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		LayoutOrder      = 1,
	})
	local Body = Text({
		Parent      = Holder,
		Text        = Options.Text or "",
		TextSize    = Metrics.RowDescSize + 2,
		TextWrapped = true,
		LayoutOrder = 2,
	})
	local Track, Fill = nil, nil
	if Options.Progress ~= nil then
		Track = New("Frame", {
			Parent                 = Holder,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = 0.85,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 2),
			LayoutOrder            = 3,
		})
		Fill = New("Frame", {
			Parent           = Track,
			BackgroundColor3 = Theme.White,
			BorderSizePixel  = 0,
			Size             = UDim2.new(Options.Progress, 0, 1, 0),
		})
	end
	function Handle:Set(Text, Progress)
		if Text then
			SwapText(Body, Text)
		end
		if Progress and Fill then
			Tween(Fill, { Size = UDim2.new(Clamp(Progress, 0, 1), 0, 1, 0) }, "snap")
		end
	end
	function Handle:SetLabel(NewLabel)
		SwapText(Label, NewLabel)
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	return Handle
end
function Kuik.Vignette(Options)
	Options = Options or {}
	local Handle = {}
	local Depth = Options.Depth or 120
	local Strength = Options.Strength or 0.55
	local Holder = New("Frame", {
		Name                   = "Vignette",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 1,
		Active                 = false,
	})
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
	function Handle:Set(NewStrength, Colour)
		Strength = NewStrength
		for _, Edge in Edges do
			if Colour then
				Edge.BackgroundColor3 = Colour
			end
			Tween(Edge, { BackgroundTransparency = NewStrength }, "fade")
		end
	end
	function Handle:Pulse(Colour, Peak)
		for _, Edge in Edges do
			Edge.BackgroundColor3 = Colour or Theme.Danger
			Edge.BackgroundTransparency = Peak or 0.25
			Tween(Edge, { BackgroundTransparency = Strength, BackgroundColor3 = Options.Color or Theme.Scrim }, "fade")
		end
	end
	function Handle:Destroy()
		Holder:Destroy()
	end
	Handle.Frame = Holder
	return Handle
end
function Kuik.Menu(Options)
	Options = Options or {}
	local Items = Options.Items or {}
	local Width = Options.Width or 150
	local EntryHeight = 24
	local Open = false
	local Layer = Options.Parent or Screen()
	local Menu = New("Frame", {
		Name                   = "Menu",
		Parent                 = Layer,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.12,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Width, 0, 0),
		Visible                = false,
		ClipsDescendants       = true,
		ZIndex                 = 60,
	}, {
		Corner(Metrics.ChipRadius),
		New("UIStroke", { Color = Theme.White, Transparency = 0.78, Thickness = 1 }),
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
	local Handle = { Frame = Menu }
	local Height = 8
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
				Size                   = UDim2.new(1, 0, 0, EntryHeight),
				LayoutOrder            = Index,
				ZIndex                 = 62,
			}, {
				Corner(Metrics.RowRadius),
			})
			Text({
				Parent           = Entry,
				Text             = tostring(Item.Label or Item),
				TextSize         = Metrics.RowDescSize + 1,
				TextTransparency = Item.Color and 0 or Theme.TextSecondary,
				TextColor3       = Item.Color or Theme.White,
				TextYAlignment   = Enum.TextYAlignment.Center,
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
		local Origin = Layer.AbsolutePosition
		local Viewport = Screen().AbsoluteSize
		local Left = X - Origin.X
		local Top = Y - Origin.Y
		if Viewport.X > 0 and X + Width > Viewport.X - 8 then
			Left -= Width
		end
		if Viewport.Y > 0 and Y + Height > Viewport.Y - 8 then
			Top -= Height
		end
		Menu.Position = UDim2.fromOffset(Left, Top)
		Menu.Size = UDim2.new(0, Width, 0, 0)
		Menu.Visible = true
		Inner.GroupTransparency = 1
		Tween(Menu, { Size = UDim2.new(0, Width, 0, Height) }, "reveal")
		Tween(Inner, { GroupTransparency = 0 }, "fade")
	end
	function Handle:Close()
		if not Open then
			return
		end
		Open = false
		Tween(Menu, { Size = UDim2.new(0, Width, 0, 0) }, "snap")
		Tween(Inner, { GroupTransparency = 1 }, "exit")
		task.delay(MotionTime("snap"), function()
			if not Open then
				Menu.Visible = false
			end
		end)
	end
	function Handle:IsOpen()
		return Open
	end
	function Handle:Destroy()
		Menu:Destroy()
	end
	local Outside = UserInputService.InputBegan:Connect(function(Input, Processed)
		if not Open or Processed then
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
	local BaseDestroy = Handle.Destroy
	function Handle:Destroy()
		Outside:Disconnect()
		BaseDestroy(self)
	end
	return Handle
end
function Kuik.Prompt(Options)
	Options = Options or {}
	local Handle = {}
	local Width = Options.Width or 340
	local Answered = false
	local Blur = nil
	local Backdrop = New("Frame", {
		Name                   = "PromptBackdrop",
		Parent                 = Screen(),
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 70,
	})
	local Modal = New("TextButton", {
		Parent                 = Backdrop,
		BackgroundTransparency = 1,
		Text                   = "",
		Size                   = UDim2.new(1, 0, 1, 0),
		Modal                  = true,
		ZIndex                 = 70,
	})
	local Root = New("Frame", {
		Name                   = "Prompt",
		Parent                 = Screen(),
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
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
	local function Side(Anchor)
		return New("Frame", {
			Parent                 = Group,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(Anchor, 0),
			Position               = UDim2.new(Anchor, 0, 0, 0),
			Size                   = UDim2.new(0, 1, 1, 0),
			ZIndex                 = 72,
		})
	end
	local LeftRule, RightRule = Side(0), Side(1)
	local Column = New("Frame", {
		Parent                 = Group,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
	}, {
		Padding(22, 26, 20, 26),
		List(8),
	})
	Text({
		Parent      = Column,
		Text        = Options.Title or "",
		TextSize    = Metrics.SectionTitleSize + 2,
		LayoutOrder = 1,
	})
	if Options.Text then
		Text({
			Parent           = Column,
			Text             = Options.Text,
			TextSize         = Metrics.RowDescSize + 2,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end
	local Buttons = New("Frame", {
		Parent                 = Column,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Metrics.TabHeight + 8),
		LayoutOrder            = 3,
	})
	New("UIListLayout", {
		Parent              = Buttons,
		Padding             = UDim.new(0, 8),
		FillDirection       = Enum.FillDirection.Horizontal,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment   = Enum.VerticalAlignment.Bottom,
	})
	local function Finish(Choice)
		if Answered then
			return
		end
		Answered = true
		if Blur then
			Tween(Blur, { Size = 0 }, "exit")
		end
		Tween(Backdrop, { BackgroundTransparency = 1 }, "exit")
		Tween(Group, { GroupTransparency = 1 }, "exit")
		Tween(LeftRule, { Size = UDim2.new(0, 1, 0, 0) }, "exit")
		Tween(RightRule, { Size = UDim2.new(0, 1, 0, 0) }, "exit")
		task.delay(MotionTime("exit") * 1.2, function()
			if Blur then Blur:Destroy() end
			Root:Destroy()
			Backdrop:Destroy()
		end)
		if Options.Callback then
			task.spawn(Options.Callback, Choice)
		end
	end
	for Index, Button in Options.Buttons or { { Label = "OK" } } do
		local Primary = Button.Primary == true
		local Pill = New("Frame", {
			Parent                 = Buttons,
			BackgroundColor3       = Primary and Theme.White or (Button.Color or Theme.White),
			BackgroundTransparency = Primary and 0 or 0.88,
			BorderSizePixel        = 0,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, Metrics.TabHeight),
			LayoutOrder            = Index,
		}, {
			Corner(math.min(Metrics.PillRadius, math.floor(Metrics.TabHeight / 2))),
			Padding(0, 16),
		})
		New("TextLabel", {
			Parent                 = Pill,
			BackgroundTransparency = 1,
			Text                   = Button.Label or "OK",
			TextColor3             = Primary and Theme.Black or (Button.Color or Theme.White),
			FontFace               = Theme.FontMedium,
			TextSize               = Metrics.RowDescSize + 2,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			ZIndex                 = 2,
		})
		local Hit = New("TextButton", {
			Parent                 = Pill,
			BackgroundTransparency = 1,
			Text                   = "",
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 3,
		})
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
	end
	Handle.Root = Root
	if (Options.Blur == nil and 18 or Options.Blur) > 0 then
		Blur = New("BlurEffect", {
			Parent = Lighting,
			Size   = 0,
			Name   = "KuikBlur",
		})
		Tween(Blur, { Size = Options.Blur == nil and 18 or Options.Blur }, "enter")
	end
	LeftRule.Size = UDim2.new(0, 1, 0, 0)
	RightRule.Size = UDim2.new(0, 1, 0, 0)
	Tween(Backdrop, { BackgroundTransparency = Options.Wash == nil and 0.45 or Options.Wash }, "enter")
	Tween(Group, { GroupTransparency = 0 }, "enter")
	Tween(LeftRule, { Size = UDim2.new(0, 1, 1, 0) }, "reveal")
	Tween(RightRule, { Size = UDim2.new(0, 1, 1, 0) }, "reveal")
	local Key = UserInputService.InputBegan:Connect(function(Input, Processed)
		if not Processed and Input.KeyCode == Enum.KeyCode.Escape and Options.Dismissable ~= false then
			Finish(nil)
		end
	end)
	task.delay(0.1, function()
		if Answered then
			Key:Disconnect()
		end
	end)
	return Handle
end
function Kuik.Cards(Options)
	Options = Options or {}
	local Deck = {}
	local Windows = {}
	local Focus = 1
	local Gap = Options.Gap or 110
	local Shrink = Options.Scale or 0.82
	local Dim = Options.Fade or 0.55
	local Layer = Screen()
	local Offsets = { [-1] = -300, [1] = 300 }
	local function Arrow(Direction)
		local Button = New("TextButton", {
			Name                   = Direction < 0 and "Previous" or "Next",
			Parent                 = Layer,
			BackgroundTransparency = 1,
			Text                   = "",
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 0, 0.5, 0),
			Size                   = UDim2.new(0, 46, 0, 92),
			Visible                = false,
			ZIndex                 = 20,
		})
		local Arms = {}
		for Index = 1, 2 do
			Arms[Index] = New("Frame", {
				Parent                 = Button,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 0.35,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 0.5),
				Position               = UDim2.new(0.5, 0, Index == 1 and 0.5 or 0.5, Index == 1 and -7 or 7),
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
			Tween(Button, { Position = UDim2.new(0.5, Offsets[Direction] + (On and Direction * 4 or 0), 0.5, 0) }, "toss")
		end
		Button.MouseEnter:Connect(function() Light(true) end)
		Button.MouseLeave:Connect(function() Light(false) end)
		Button.Arms = Arms
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
		TextSize               = Metrics.MonoSize + 1,
		AnchorPoint            = Vector2.new(0.5, 1),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, 80, 0, 14),
		Visible                = false,
		ZIndex                 = 20,
	})
	local function Layout(Animate)
		for Index, Entry in Windows do
			local Window = Entry.Window
			local Offset = Index - Focus
			local Centre = Offset == 0
			local Step = Window.Root.AbsoluteSize.X * Shrink + Gap
			local X = Offset * Step
			Window.Root.ZIndex = 2 + (10 - math.min(math.abs(Offset), 9))
			Window.Root.Visible = true
			local Target = UDim2.new(0.5, X, 0.5, 0)
			local Scale = Centre and 1 or Shrink
			local Transparency = Centre and 0 or Dim
			if Animate then
				Tween(Window.Root, { Position = Target }, "layout")
				Tween(Entry.Scale, { Scale = Scale }, "layout")
				Tween(Window.Group, { GroupTransparency = Transparency }, "fade")
			else
				Window.Root.Position = Target
				Entry.Scale.Scale = Scale
				Window.Group.GroupTransparency = Transparency
			end
			for _, Child in Window:Children() do
				Child.Root.Visible = Centre and Child:IsOpen()
				if Animate then
					Tween(Child.Group, { GroupTransparency = Transparency }, "fade")
				else
					Child.Group.GroupTransparency = Transparency
				end
			end
		end
		local Focused = Windows[Focus]
		if Focused then
			local Half = Focused.Window.Root.AbsoluteSize.X / 2 + 34
			Offsets[-1] = -Half
			Offsets[1] = Half
			Tween(Previous, { Position = UDim2.new(0.5, -Half, 0.5, 0) }, Animate and "layout" or "instant")
			Tween(Next, { Position = UDim2.new(0.5, Half, 0.5, 0) }, Animate and "layout" or "instant")
			local Height = Focused.Window.Root.AbsoluteSize.Y / 2 + 26
			Counter.Position = UDim2.new(0.5, 0, 0.5, Height)
			SwapText(Counter, string.format("%d / %d", Focus, #Windows))
		end
		Previous.Visible = Focus > 1
		Next.Visible = Focus < #Windows
		Counter.Visible = #Windows > 1
	end
	function Deck:Add(Window)
		Window:SetParallax(0)
		local Scale = Window.Root:FindFirstChildOfClass("UIScale")
			or New("UIScale", { Parent = Window.Root, Scale = 1 })
		table.insert(Windows, { Window = Window, Scale = Scale })
		local Guard = New("TextButton", {
			Name                   = "CardGuard",
			Parent                 = Window.Root,
			BackgroundTransparency = 1,
			Text                   = "",
			Size                   = UDim2.new(1, 0, 1, 0),
			Visible                = false,
			ZIndex                 = 50,
		})
		Windows[#Windows].Guard = Guard
		local Index = #Windows
		Guard.Activated:Connect(function()
			Deck:Focus(Index)
		end)
		Layout(#Windows > 1)
		Deck:Refresh()
		return Window
	end
	function Deck:Refresh()
		for Index, Entry in Windows do
			if Entry.Guard then
				Entry.Guard.Visible = Index ~= Focus
			end
		end
	end
	function Deck:Focus(Index)
		Focus = Clamp(Index, 1, math.max(1, #Windows))
		Layout(true)
		Deck:Refresh()
		if Options.Callback then
			task.spawn(Options.Callback, Focus, Windows[Focus] and Windows[Focus].Window)
		end
	end
	function Deck:Next()
		Deck:Focus(Focus + 1)
	end
	function Deck:Previous()
		Deck:Focus(Focus - 1)
	end
	function Deck:Focused()
		return Focus, Windows[Focus] and Windows[Focus].Window
	end
	function Deck:Count()
		return #Windows
	end
	function Deck:Destroy()
		Previous:Destroy()
		Next:Destroy()
		Counter:Destroy()
		for _, Entry in Windows do
			if Entry.Guard then
				Entry.Guard:Destroy()
			end
		end
		table.clear(Windows)
	end
	Previous.Activated:Connect(function() Deck:Previous() end)
	Next.Activated:Connect(function() Deck:Next() end)
	local Key = UserInputService.InputBegan:Connect(function(Input, Processed)
		if Processed or #Windows < 2 then
			return
		end
		if Input.KeyCode == Enum.KeyCode.Left or Input.KeyCode == Enum.KeyCode.Q then
			Deck:Previous()
		elseif Input.KeyCode == Enum.KeyCode.Right or Input.KeyCode == Enum.KeyCode.E then
			Deck:Next()
		end
	end)
	local BaseDestroy = Deck.Destroy
	function Deck:Destroy()
		Key:Disconnect()
		BaseDestroy(self)
	end
	return Deck
end
function Kuik.Screen()
	return Screen()
end
function Kuik.Reset()
	if ScreenGui then
		ScreenGui:Destroy()
		ScreenGui = nil
	end
	for _, Effect in Lighting:GetChildren() do
		if Effect.Name == "KuikBlur" then
			Effect:Destroy()
		end
	end
end
Kuik.New  = New
Kuik.Tween = Tween
return Kuik
