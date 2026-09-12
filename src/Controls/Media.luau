--!nonstrict
--- Media.luau — pictures, models, video, sound.
---
--- Every embed here resolves its plate through Util.Surface, so the dark
--- background behind an image is a per widget choice: a colour, a
--- transparency, or nothing at all.

local Palette = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local Motion  = require(script.Parent.Parent.Motion)
local Parts   = require(script.Parent.Parent.Parts)
local Scroll  = require(script.Parent.Parent.Scroll)
local Screen  = require(script.Parent.Parent.Screen)

local Theme   = Palette.Tokens
local Metrics = Palette.Metrics

local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Clamp   = Util.Clamp
local Round   = Util.Round
local Colour  = Util.Colour

local Tween      = Motion.Tween
local SwapText   = Motion.SwapText
local MotionTime = Motion.MotionTime

local Row         = Parts.Row
local Block       = Parts.Block
local Common      = Parts.Common
local BlockHandle = Parts.BlockHandle
local Draggable   = Parts.Draggable

local Controls = {}

--- The well an embed sits in: a plate, a clip, and a corner.
local function Well(Parent, Options, Height)
	local Fill, Alpha = Util.Surface(Options, Theme.EmbedColor, Theme.EmbedTransparency)

	local Frame = New("Frame", {
		Name                   = "Well",
		Parent                 = Parent,
		BackgroundColor3       = Fill,
		BackgroundTransparency = Alpha,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, Height and 0 or 1, Height or 0),
		ClipsDescendants       = Options.Clip ~= false,
	}, {
		Corner(Util.Radius(Options, Metrics.CardRadius)),
	})

	if Options.Inset then
		Padding(Options.Inset).Parent = Frame
	end

	return Frame
end

--- Fades an image in once it has actually loaded, with a timeout so a broken
--- asset does not leave a permanent blank.
local function Reveal(Picture, Target)
	local function Show()
		Tween(Picture, { ImageTransparency = Target or 0 }, "fade")
	end

	if Picture.IsLoaded then
		task.defer(Show)
	else
		Picture:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if Picture.IsLoaded then
				Show()
			end
		end)

		task.delay(3, Show)
	end
end

--- Image. A picture in a card, with an optional caption.
function Controls.Image(Container, Options)
	local Handle = {}
	local Height = Options.Height or 140

	local Built = Block(Container, Options, Height + (Options.Caption and 18 or 0))
	local Holder = Well(Built.Content, Options, Height)

	local Picture = New("ImageLabel", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		Image                  = Util.Asset(Options.Image),
		ImageTransparency      = 1,
		ImageColor3            = Options.ImageColor or Theme.White,
		ScaleType              = Util.ScaleType(Options.Fit),
		Size                   = UDim2.new(1, 0, 1, 0),
	})

	Reveal(Picture, Options.Transparency)

	local Caption = nil

	if Options.Caption then
		Caption = Text({
			Parent           = Built.Content,
			Text             = Options.Caption,
			TextSize         = Metrics.CaptionSize,
			TextTransparency = Theme.TextTertiary,
			TextWrapped      = true,
			Position         = UDim2.new(0, 0, 0, Height + 4),
			Size             = UDim2.new(1, 0, 0, 0),
		})
	end

	function Handle:Set(NewImage)
		Picture.ImageTransparency = 1
		Picture.Image = Util.Asset(NewImage)
		Reveal(Picture, Options.Transparency)
		return Handle
	end

	function Handle:SetCaption(NewCaption)
		if Caption then
			SwapText(Caption, NewCaption)
		end

		return Handle
	end

	--- The plate behind the picture, changed after the fact.
	function Handle:SetBackground(Fill, Alpha)
		if Fill == false then
			Tween(Holder, { BackgroundTransparency = 1 }, "fade")
		else
			Holder.BackgroundColor3 = Fill or Theme.EmbedColor
			Tween(Holder, { BackgroundTransparency = Alpha or 0 }, "fade")
		end

		return Handle
	end

	Handle.Picture = Picture
	Handle.Well = Holder

	return BlockHandle(Built, Handle, Options)
end

--- Icon. A small picture on the right of a row.
function Controls.Icon(Container, Options)
	local Handle = {}
	local Size = Options.Size or 24

	local Built = Row(Container, Util.Merge(Options, { Reserve = Size }))
	Built:Reserve(Size)

	local Fill, Alpha = Util.Surface(Options, Theme.EmbedColor, 1)

	local Picture = New("ImageLabel", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Fill,
		BackgroundTransparency = Alpha,
		BorderSizePixel        = 0,
		Image                  = Util.Asset(Options.Image),
		ImageColor3            = Options.ImageColor or Theme.White,
		ImageTransparency      = 1,
		ScaleType              = Util.ScaleType(Options.Fit),
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Size, 0, Size),
	}, {
		Corner(Util.Radius(Options, 0)),
	})

	Reveal(Picture, Options.Transparency)

	function Handle:Set(NewImage)
		Picture.Image = Util.Asset(NewImage)
		return Handle
	end

	Handle.Picture = Picture

	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
	})
end

--- Gallery. A horizontal strip of pictures with a smooth scroll and gleams at
--- both ends, plus an optional selection.
function Controls.Gallery(Container, Options)
	local Handle = {}
	local Items = Options.Items or {}
	local Height = Options.Height or 96
	local Width = Options.Width or 140
	local Value = Options.Default
	local Cells = {}

	local Built = Block(Container, Options, Height)

	local Sheet = New("ScrollingFrame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.X,
		ScrollBarThickness     = 0,
		ScrollingDirection     = Enum.ScrollingDirection.X,
		ClipsDescendants       = true,
	}, {
		Strip(Options.Gap or 8),
	})

	local Scroller = Scroll.Attach(Sheet, "X", { Depth = 26 })

	local function Render()
		for _, Cell in Cells do
			local On = Cell.Item == Value

			Tween(Cell.Ring, { Transparency = On and 0.2 or 1 }, "hover")
			Tween(Cell.Picture, { ImageTransparency = On and 0 or (Options.Dim or 0.25) }, "fade")
		end
	end

	for Index, Item in Items do
		local Image = type(Item) == "table" and Item.Image or Item

		local Cell = New("Frame", {
			Parent                 = Sheet,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(0, Width, 1, 0),
			LayoutOrder            = Index,
		})

		local Holder = Well(Cell, Options)

		local Picture = New("ImageLabel", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			Image                  = Util.Asset(Image),
			ImageTransparency      = 1,
			--- Fit, not Crop: a gallery that crops its thumbnails is not
			--- showing you the pictures, it is showing you the middles of them.
			ScaleType              = Util.ScaleType(Options.Fit, Enum.ScaleType.Fit),
			Size                   = UDim2.new(1, 0, 1, 0),
		})

		Reveal(Picture, Options.Dim or 0.25)

		local Ring = Util.Stroke(Colour(Options, Theme.White), 1, 1)
		Ring.Parent = Holder

		if type(Item) == "table" and Item.Label then
			Text({
				Parent           = Holder,
				Text             = Item.Label,
				TextSize         = Metrics.CaptionSize,
				TextTransparency = 0,
				TextYAlignment   = Enum.TextYAlignment.Bottom,
				AnchorPoint      = Vector2.new(0, 1),
				Position         = UDim2.new(0, 6, 1, -4),
				Size             = UDim2.new(1, -12, 0, 14),
				AutomaticSize    = Enum.AutomaticSize.None,
				ZIndex           = 3,
			})
		end

		local Button = New("TextButton", {
			Parent                 = Holder,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 4,
		})

		Cells[Index] = { Item = Item, Picture = Picture, Ring = Ring, Cell = Holder }

		Button.Activated:Connect(function()
			Handle:Set(Item)

			if Options.Expand ~= false then
				Handle:Expand(Index)
			end
		end)
	end

	--- A picture opened out of its own thumbnail.
	---
	--- It starts at exactly the rectangle of the cell you pressed and springs
	--- out to the middle of the screen, so it reads as that picture getting
	--- bigger rather than a new window appearing. Closing runs it back into the
	--- cell it came from.
	local Open = nil

	function Handle:Expand(Index)
		local Cell = Cells[Index]

		if not Cell or Open then
			return Handle
		end

		local Layer = Screen.Get()
		local From = Cell.Cell

		if From.AbsoluteSize.X < 2 then
			return Handle
		end

		local Scrim = New("TextButton", {
			Name                   = "GalleryBackdrop",
			Parent                 = Layer,
			BackgroundColor3       = Theme.Scrim,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Text                   = "",
			AutoButtonColor        = false,
			Size                   = UDim2.new(1, 0, 1, 0),
			ZIndex                 = 400,
		})

		Screen.Cover(Scrim)

		local Start = From.AbsolutePosition - Layer.AbsolutePosition
		local Span = From.AbsoluteSize

		local Big = New("ImageLabel", {
			Name                   = "Expanded",
			Parent                 = Layer,
			BackgroundColor3       = Theme.EmbedColor,
			BackgroundTransparency = Theme.EmbedTransparency,
			BorderSizePixel        = 0,
			Image                  = Cell.Picture.Image,
			ScaleType              = Enum.ScaleType.Fit,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0, Start.X + Span.X / 2, 0, Start.Y + Span.Y / 2),
			Size                   = UDim2.new(0, Span.X, 0, Span.Y),
			ZIndex                 = 401,
		}, {
			Corner(Util.Radius(Options, Metrics.CardRadius)),
		})

		--- As big as it can be without touching the edges, and never bigger
		--- than the screen it is being shown on.
		local Room = Layer.AbsoluteSize
		local Wide = math.max(120, Room.X - 120)
		local Tall = math.max(120, Room.Y - 120)

		Tween(Scrim, { BackgroundTransparency = Options.Wash or 0.35 }, "enter")
		Tween(Big, {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, Wide, 0, Tall),
		}, "expand")

		local function Shut()
			if not Open then
				return
			end

			Open = nil

			Tween(Scrim, { BackgroundTransparency = 1 }, "exit")
			Tween(Big, {
				Position = UDim2.new(0, Start.X + Span.X / 2, 0, Start.Y + Span.Y / 2),
				Size = UDim2.new(0, Span.X, 0, Span.Y),
			}, "exit")

			task.delay(MotionTime("exit") * 1.2, function()
				Scrim:Destroy()
				Big:Destroy()
			end)
		end

		Open = { Close = Shut }
		Scrim.Activated:Connect(Shut)

		return Handle
	end

	function Handle:Collapse()
		if Open then
			Open.Close()
		end

		return Handle
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

		return Handle
	end

	Render()

	local Result = BlockHandle(Built, Handle, Options)

	Result:OnDestroy(function()
		Scroller:Destroy()
		Handle:Collapse()
	end)

	return Result
end

--- Viewport. A 3D model in a card, optionally spinning, and draggable to turn.
function Controls.Viewport(Container, Options)
	local Handle = {}
	local Height = Options.Height or 160

	local Built = Block(Container, Options, Height)
	local Holder = Well(Built.Content, Options, Height)

	local Frame = New("ViewportFrame", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		Ambient                = Options.Ambient or Color3.fromRGB(160, 160, 160),
		LightColor             = Options.LightColor or Color3.fromRGB(255, 255, 255),
		LightDirection         = Options.LightDirection or Vector3.new(-1, -1, -1),
	})

	local Camera = New("Camera", { Parent = Frame })
	Frame.CurrentCamera = Camera

	local Model = nil
	local Yaw = Options.Yaw or 0
	local Pitch = Options.Pitch or math.rad(-12)
	local Distance = Options.Distance or 0

	local function Aim()
		if not Model then
			return
		end

		local Centre, Size = nil, Vector3.zero

		if Model:IsA("Model") then
			local Ok, Box = pcall(function()
				return Model:GetBoundingBox()
			end)

			if Ok then
				Centre, Size = Box.Position, select(2, Model:GetBoundingBox())
			end
		elseif Model:IsA("BasePart") then
			Centre, Size = Model.Position, Model.Size
		end

		if not Centre then
			return
		end

		local Reach = Distance > 0 and Distance or math.max(Size.Magnitude, 1) * 1.1

		local Offset = CFrame.fromEulerAnglesYXZ(Pitch, Yaw, 0) * CFrame.new(0, 0, Reach)
		Camera.CFrame = CFrame.new(Centre) * Offset
		Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Centre)
	end

	function Handle:SetModel(Instance_)
		if Model then
			Model:Destroy()
		end

		Model = Instance_ and Instance_:Clone() or nil

		if Model then
			Model.Parent = Frame
			task.defer(Aim)
		end

		return Handle
	end

	function Handle:SetAngle(NewYaw, NewPitch)
		Yaw = NewYaw or Yaw
		Pitch = NewPitch or Pitch
		Aim()
		return Handle
	end

	function Handle:SetDistance(NewDistance)
		Distance = NewDistance
		Aim()
		return Handle
	end

	--- With nothing to show, a viewport is a black rectangle and you cannot
	--- tell whether it is working. A wireframe cube, drawn from thin bars in
	--- the same style as everything else, says that it is.
	local function Placeholder()
		local Model = Instance.new("Model")
		Model.Name = "Placeholder"

		local Reach = 2
		local Thin = 0.06

		--- Twelve edges: four along each axis, at every corner of the other
		--- two.
		for Axis = 1, 3 do
			for First = -1, 1, 2 do
				for Second = -1, 1, 2 do
					local Size, Offset

					if Axis == 1 then
						Size = Vector3.new(Reach * 2, Thin, Thin)
						Offset = Vector3.new(0, First * Reach, Second * Reach)
					elseif Axis == 2 then
						Size = Vector3.new(Thin, Reach * 2, Thin)
						Offset = Vector3.new(First * Reach, 0, Second * Reach)
					else
						Size = Vector3.new(Thin, Thin, Reach * 2)
						Offset = Vector3.new(First * Reach, Second * Reach, 0)
					end

					local Bar = Instance.new("Part")
					Bar.Anchored = true
					Bar.CanCollide = false
					Bar.CastShadow = false
					Bar.Material = Enum.Material.SmoothPlastic
					Bar.Color = Options.PlaceholderColor or Theme.White
					Bar.Size = Size
					Bar.CFrame = CFrame.new(Offset)
					Bar.Parent = Model
				end
			end
		end

		--- A solid core, so the cube reads as an object rather than a diagram.
		local Core = Instance.new("Part")
		Core.Anchored = true
		Core.CanCollide = false
		Core.CastShadow = false
		Core.Material = Enum.Material.SmoothPlastic
		Core.Color = Options.PlaceholderColor or Theme.White
		Core.Transparency = 0.75
		Core.Size = Vector3.new(Reach, Reach, Reach)
		Core.CFrame = CFrame.new()
		Core.Parent = Model

		Model.PrimaryPart = Core

		return Model
	end

	if Options.Model then
		Handle:SetModel(Options.Model)
	elseif Options.Placeholder ~= false then
		local Stand = Placeholder()
		Handle:SetModel(Stand)
		Stand:Destroy()
	end

	--- Drag to turn. Reported as a fraction of the frame, so a full sweep is
	--- one turn whatever size the card is.
	local Stop = nil

	if Options.Drag ~= false then
		local Last = nil

		Stop = Draggable(Frame, Frame, function(X, Y)
			if Last then
				Yaw -= (X - Last.X) * math.pi * 2
				Pitch = Clamp(Pitch + (Y - Last.Y) * math.pi, -1.4, 1.4)
				Aim()
			end

			Last = Vector2.new(X, Y)
		end, function()
			Last = nil
		end)
	end

	local Spinning = Options.Spin == true

	if Spinning then
		task.spawn(function()
			while Spinning and Frame.Parent do
				Yaw += (Options.Speed or 0.6) * 0.03
				Aim()
				task.wait(0.03)
			end
		end)
	end

	function Handle:SetSpin(On)
		if On and not Spinning then
			Spinning = true

			task.spawn(function()
				while Spinning and Frame.Parent do
					Yaw += (Options.Speed or 0.6) * 0.03
					Aim()
					task.wait(0.03)
				end
			end)
		else
			Spinning = On == true
		end

		return Handle
	end

	Handle.Viewport = Frame
	Handle.Camera = Camera

	local Result = BlockHandle(Built, Handle, Options)

	Result:OnDestroy(function()
		Spinning = false

		if Stop then
			Stop()
		end
	end)

	return Result
end

--- Video. A VideoFrame with a play control and a progress rule under it.
function Controls.Video(Container, Options)
	local Handle = {}
	local Height = Options.Height or 160

	local Built = Block(Container, Options, Height + 16)
	local Holder = Well(Built.Content, Options, Height)

	local Frame = New("VideoFrame", {
		Parent                 = Holder,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		Video                  = Util.Asset(Options.Video),
		Looped                 = Options.Loop == true,
		Volume                 = Options.Volume or 1,
	})

	local Track = New("Frame", {
		Parent                 = Built.Content,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.85,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, 0, 0, Height + 8),
		Size                   = UDim2.new(1, 0, 0, 2),
	})

	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
	})

	--- A play triangle drawn from two rotated bars, so there is no asset to
	--- ship and it inherits the theme colour like everything else.
	local Play = New("TextButton", {
		Parent                 = Holder,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.4,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0, 34, 0, 34),
		ZIndex                 = 4,
	}, {
		Corner(17),
	})

	for Index = 1, 2 do
		New("Frame", {
			Parent                 = Play,
			BackgroundColor3       = Theme.White,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 1, 0.5, Index == 1 and -3 or 3),
			Size                   = UDim2.new(0, 12, 0, 2),
			Rotation               = Index == 1 and 32 or -32,
			ZIndex                 = 5,
		})
	end

	local Playing = false

	local function Sync()
		Play.Visible = not Playing

		local Length = Frame.TimeLength

		if Length > 0 then
			Tween(Fill, { Size = UDim2.new(Clamp(Frame.TimePosition / Length, 0, 1), 0, 1, 0) }, "hover")
		end
	end

	Play.Activated:Connect(function()
		Playing = true
		Frame:Play()
		Sync()
	end)

	Frame.Ended:Connect(function()
		Playing = false
		Sync()
	end)

	local Ticking = true

	task.spawn(function()
		while Ticking and Frame.Parent do
			if Playing then
				Sync()
			end

			task.wait(0.2)
		end
	end)

	function Handle:Play()
		Playing = true
		Frame:Play()
		Sync()
		return Handle
	end

	function Handle:Pause()
		Playing = false
		Frame:Pause()
		Sync()
		return Handle
	end

	function Handle:Set(NewVideo)
		Frame.Video = Util.Asset(NewVideo)
		return Handle
	end

	Handle.Video = Frame

	local Result = BlockHandle(Built, Handle, Options)

	Result:OnDestroy(function()
		Ticking = false
	end)

	return Result
end

--- Audio. A sound with a play control, a scrubber and a time readout.
function Controls.Audio(Container, Options)
	local Handle = {}

	local Built = Block(Container, Options, 34)

	local Sound = New("Sound", {
		Parent   = Built.Frame,
		SoundId  = Util.Asset(Options.Sound),
		Volume   = Options.Volume or 0.5,
		Looped   = Options.Loop == true,
	})

	Strip(10).Parent = Built.Content

	local Play = New("TextButton", {
		Parent                 = Built.Content,
		BackgroundColor3       = Colour(Options, Theme.White),
		BackgroundTransparency = 0.86,
		BorderSizePixel        = 0,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 24, 0, 24),
		LayoutOrder            = 1,
	}, {
		Corner(Round(Options, 12)),
	})

	local Arms = {}

	for Index = 1, 2 do
		Arms[Index] = New("Frame", {
			Parent                 = Play,
			BackgroundColor3       = Theme.White,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.new(0.5, 1, 0.5, Index == 1 and -2 or 2),
			Size                   = UDim2.new(0, 9, 0, 2),
			Rotation               = Index == 1 and 32 or -32,
			ZIndex                 = 2,
		})
	end

	local Bar = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -100, 1, 0),
		LayoutOrder            = 2,
	})

	local Track = New("Frame", {
		Parent                 = Bar,
		BackgroundColor3       = Theme.White,
		BackgroundTransparency = 0.85,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, 0),
		Size                   = UDim2.new(1, 0, 0, 2),
	})

	local Fill = New("Frame", {
		Parent           = Track,
		BackgroundColor3 = Colour(Options, Theme.White),
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
	})

	local Clock = Text({
		Parent           = Built.Content,
		Text             = "0:00",
		FontFace         = Theme.FontMono,
		TextSize         = Metrics.MonoSize,
		TextTransparency = Theme.TextTertiary,
		TextXAlignment   = Enum.TextXAlignment.Right,
		TextYAlignment   = Enum.TextYAlignment.Center,
		Size             = UDim2.new(0, 44, 1, 0),
		AutomaticSize    = Enum.AutomaticSize.None,
		LayoutOrder      = 3,
	})

	local function Stamp(Seconds)
		local Whole = math.max(0, math.floor(Seconds))
		return string.format("%d:%02d", Whole // 60, Whole % 60)
	end

	local Playing = false

	local function Sync()
		local Length = Sound.TimeLength

		if Length > 0 then
			Tween(Fill, { Size = UDim2.new(Clamp(Sound.TimePosition / Length, 0, 1), 0, 1, 0) }, "hover")
		end

		Clock.Text = Stamp(Sound.TimePosition)

		--- Two bars at an angle is a play arrow; two upright is a pause.
		for Index, Arm in Arms do
			Arm.Rotation = Playing and 0 or (Index == 1 and 32 or -32)
			Arm.Position = Playing
				and UDim2.new(0.5, Index == 1 and -3 or 3, 0.5, 0)
				or UDim2.new(0.5, 1, 0.5, Index == 1 and -2 or 2)
			Arm.Size = Playing and UDim2.new(0, 2, 0, 10) or UDim2.new(0, 9, 0, 2)
		end
	end

	Play.Activated:Connect(function()
		Playing = not Playing

		if Playing then
			Sound:Resume()
		else
			Sound:Pause()
		end

		Sync()
	end)

	local Stop = Draggable(Bar, Track, function(X)
		if Sound.TimeLength > 0 then
			Sound.TimePosition = X * Sound.TimeLength
			Sync()
		end
	end)

	local Ticking = true

	task.spawn(function()
		while Ticking and Built.Frame.Parent do
			if Playing then
				Sync()
			end

			task.wait(0.25)
		end
	end)

	function Handle:Play()
		Playing = true
		Sound:Play()
		Sync()
		return Handle
	end

	function Handle:Pause()
		Playing = false
		Sound:Pause()
		Sync()
		return Handle
	end

	function Handle:Set(NewSound)
		Sound.SoundId = Util.Asset(NewSound)
		return Handle
	end

	Handle.Sound = Sound

	Sync()

	local Result = BlockHandle(Built, Handle, Options)

	Result:OnDestroy(function()
		Ticking = false
		Stop()
		Sound:Stop()
	end)

	return Result
end

--- Marquee. Text that scrolls sideways forever, for a ticker.
function Controls.Marquee(Container, Options)
	local Handle = {}

	local Frame = New("Frame", {
		Name                   = "Marquee",
		Parent                 = Container,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.Height or 18),
		ClipsDescendants       = true,
		LayoutOrder            = Options.LayoutOrder or 0,
	}, {
		Padding(0, Metrics.RowPadding),
	})

	local Label = Text({
		Parent           = Frame,
		Text             = Options.Text or "",
		FontFace         = Options.Mono and Theme.FontMono or Theme.Font,
		TextSize         = Options.TextSize or (Metrics.ValueSize),
		TextTransparency = Theme.TextSecondary,
		TextYAlignment   = Enum.TextYAlignment.Center,
		AutomaticSize    = Enum.AutomaticSize.X,
		Size             = UDim2.new(0, 0, 1, 0),
	})

	local Running = true

	task.spawn(function()
		while Running and Frame.Parent do
			local Span = Label.AbsoluteSize.X
			local View = Frame.AbsoluteSize.X

			if Span > View and View > 0 then
				Label.Position = UDim2.new(0, View, 0, 0)

				local Distance = View + Span
				local Time = Distance / (Options.Speed or 40)

				Tween(Label, { Position = UDim2.new(0, -Span, 0, 0) },
					{ Duration = Time, Easing = "linear" })

				task.wait(Time + 0.2)
			else
				Label.Position = UDim2.new(0, 0, 0, 0)
				task.wait(1)
			end
		end
	end)

	function Handle:Set(NewText)
		Label.Text = NewText
		return Handle
	end

	return Common(Handle, Frame, Options, {
		Destroy = function()
			Running = false
		end,
	})
end

return Controls
