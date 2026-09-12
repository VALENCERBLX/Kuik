--!nonstrict
--- Pickers.luau — dates and times.
---
--- Everything here works in whole days as a Unix timestamp at midnight UTC, so
--- a date is one number and comparing two of them is subtraction.

local Palette = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local Motion  = require(script.Parent.Parent.Motion)
local Parts   = require(script.Parent.Parent.Parts)
local Screen  = require(script.Parent.Parent.Screen)

local Theme   = Palette.Tokens
local Metrics = Palette.Metrics

local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Strip   = Util.Strip
local Stroke  = Util.Stroke
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

local Controls = {}

local DAY = 86400

local MONTHS = {
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
}

local WEEKDAYS = { "S", "M", "T", "W", "T", "F", "S" }

--- Midnight UTC on the day a timestamp falls in.
local function Midnight(When)
	local Parts_ = os.date("!*t", When or os.time())

	return os.time({
		year = Parts_.year,
		month = Parts_.month,
		day = Parts_.day,
		hour = 0,
		min = 0,
		sec = 0,
	})
end

local function Stamp(When, Format)
	return os.date(Format or "!%d %b %Y", When)
end

--- The first day of the month a timestamp falls in, and how many days it has.
local function Month(When)
	local Parts_ = os.date("!*t", When)

	local First = os.time({ year = Parts_.year, month = Parts_.month, day = 1, hour = 0 })
	local Next = os.time({
		year = Parts_.month == 12 and Parts_.year + 1 or Parts_.year,
		month = Parts_.month == 12 and 1 or Parts_.month + 1,
		day = 1,
		hour = 0,
	})

	return First, math.floor((Next - First) / DAY), Parts_
end

local function Shift(When, By)
	local Parts_ = os.date("!*t", When)
	local Total = (Parts_.year * 12 + Parts_.month - 1) + By

	return os.time({
		year = math.floor(Total / 12),
		month = Total % 12 + 1,
		day = 1,
		hour = 0,
	})
end

--- Calendar. A month grid you can page through and pick from.
---
--- Used on its own, or as the body of a Date or DateRange picker.
function Controls.Calendar(Container, Options)
	local Handle = {}
	local Accent = Colour(Options, Theme.Accent)

	local Today = Midnight()
	local Cursor = Midnight(Options.Default or Today)

	--- Range mode keeps two ends; single mode keeps one.
	local Range = Options.Range == true
	local From = Options.From and Midnight(Options.From) or (not Range and Cursor or nil)
	local To = Options.To and Midnight(Options.To) or nil

	local Built = Block(Container, Options)

	local Head = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 22),
		LayoutOrder            = 1,
	})

	local function Arrow(Direction)
		local Button = New("TextButton", {
			Parent                 = Head,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			AnchorPoint            = Vector2.new(Direction < 0 and 0 or 1, 0.5),
			Position               = UDim2.new(Direction < 0 and 0 or 1, 0, 0.5, 0),
			Size                   = UDim2.new(0, 20, 0, 20),
			ZIndex                 = 3,
		})

		Util.Chevron(Button, 12, Direction < 0 and "Left" or "Right")

		return Button
	end

	local Back = Arrow(-1)
	local Forward = Arrow(1)

	local Title = Text({
		Parent         = Head,
		Text           = "",
		FontFace       = Theme.FontMedium,
		TextSize       = Metrics.BodySize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, -48, 1, 0),
		Position       = UDim2.new(0, 24, 0, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})

	local Week = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 14),
		LayoutOrder            = 2,
	}, {
		Strip(0),
	})

	for _, Letter in WEEKDAYS do
		Text({
			Parent           = Week,
			Text             = Letter,
			FontFace         = Theme.FontMono,
			TextSize         = Metrics.MonoSize,
			TextTransparency = Theme.TextDisabled,
			TextXAlignment   = Enum.TextXAlignment.Center,
			TextYAlignment   = Enum.TextYAlignment.Center,
			Size             = UDim2.new(1 / 7, 0, 1, 0),
			AutomaticSize    = Enum.AutomaticSize.None,
		})
	end

	local Grid = New("Frame", {
		Parent                 = Built.Content,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Options.CellHeight and Options.CellHeight * 6 or 132),
		LayoutOrder            = 3,
	}, {
		New("UIGridLayout", {
			CellSize    = UDim2.new(1 / 7, -2, 0, Options.CellHeight or 20),
			CellPadding = UDim2.new(0, 2, 0, 2),
			SortOrder   = Enum.SortOrder.LayoutOrder,
			FillDirectionMaxCells = 7,
		}),
	})

	List(6).Parent = Built.Content

	local Cells = {}

	local function Paint()
		for _, Cell in Cells do
			local Day = Cell.Day
			local Selected = false
			local Inside = false

			if Range then
				Selected = Day == From or Day == To
				Inside = From and To and Day > From and Day < To
			else
				Selected = Day == From
			end

			Tween(Cell.Frame, {
				BackgroundColor3 = Selected and Accent or Theme.White,
				BackgroundTransparency = Selected and 0 or (Inside and 0.82 or 1),
			}, "hover")

			Cell.Label.TextColor3 = Selected and Theme.Black or Theme.White
			Cell.Label.TextTransparency = Selected and 0
				or (Cell.Outside and Theme.TextDisabled or Theme.TextSecondary)

			--- Today is marked whether or not it is chosen, so the grid always
			--- has an anchor in it.
			Cell.Mark.Visible = Day == Today
			Cell.Mark.BackgroundColor3 = Selected and Theme.Black or Accent
		end
	end

	local function Fire()
		if not Options.Callback then
			return
		end

		if Range then
			task.spawn(Options.Callback, From, To)
		else
			task.spawn(Options.Callback, From)
		end
	end

	local function Draw()
		for _, Cell in Cells do
			Cell.Frame:Destroy()
		end

		table.clear(Cells)

		local First, Days, Parts_ = Month(Cursor)

		SwapText(Title, string.format("%s %d", MONTHS[Parts_.month], Parts_.year))

		--- os.date's wday is 1 for Sunday, which is the column order used here.
		local Lead = os.date("!*t", First).wday - 1
		local Start = First - Lead * DAY

		for Index = 0, 41 do
			local Day = Start + Index * DAY
			local Outside = Day < First or Day >= First + Days * DAY

			local Cell = New("Frame", {
				Parent                 = Grid,
				BackgroundColor3       = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				LayoutOrder            = Index,
			}, {
				Corner(Util.Radius(Options, 3)),
			})

			local Label = Text({
				Parent           = Cell,
				Text             = os.date("!%d", Day),
				FontFace         = Theme.FontMono,
				TextSize         = Metrics.MonoBoldSize,
				TextTransparency = Outside and Theme.TextDisabled or Theme.TextSecondary,
				TextXAlignment   = Enum.TextXAlignment.Center,
				TextYAlignment   = Enum.TextYAlignment.Center,
				Size             = UDim2.new(1, 0, 1, 0),
				AutomaticSize    = Enum.AutomaticSize.None,
			})

			local Mark = New("Frame", {
				Parent                 = Cell,
				BackgroundColor3       = Accent,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0.5, 1),
				Position               = UDim2.new(0.5, 0, 1, -2),
				Size                   = UDim2.new(0, 3, 0, 1),
				Visible                = false,
				ZIndex                 = 3,
			})

			local Button = New("TextButton", {
				Parent                 = Cell,
				BackgroundTransparency = 1,
				Text                   = "",
				AutoButtonColor        = false,
				Size                   = UDim2.new(1, 0, 1, 0),
				ZIndex                 = 4,
			})

			table.insert(Cells, {
				Frame = Cell,
				Label = Label,
				Mark = Mark,
				Day = Day,
				Outside = Outside,
			})

			Button.MouseEnter:Connect(function()
				if Day ~= From and Day ~= To then
					Tween(Cell, { BackgroundTransparency = 0.9 }, "hover")
				end
			end)

			Button.MouseLeave:Connect(function()
				Paint()
			end)

			Button.Activated:Connect(function()
				if Handle:IsDisabled() then
					return
				end

				if not Range then
					From = Day
				elseif From == nil or (From and To) then
					--- A fresh range starts from this day.
					From, To = Day, nil
				elseif Day < From then
					From = Day
				else
					To = Day
				end

				Paint()
				Fire()
			end)
		end

		Paint()
	end

	Back.Activated:Connect(function()
		Cursor = Shift(Cursor, -1)
		Draw()
	end)

	Forward.Activated:Connect(function()
		Cursor = Shift(Cursor, 1)
		Draw()
	end)

	function Handle:Get()
		if Range then
			return From, To
		end

		return From
	end

	function Handle:Set(A, B, Silent)
		From = A and Midnight(A) or nil
		To = B and Midnight(B) or nil
		Cursor = From or Cursor

		Draw()

		if not Silent then
			Fire()
		end

		return Handle
	end

	function Handle:Show(When)
		Cursor = Midnight(When)
		Draw()
		return Handle
	end

	Draw()

	return BlockHandle(Built, Handle, Options)
end

--- The shared body of a picker row: a chip that opens a panel on the overlay.
local function Popped(Built, Options, Owner, Width, Build)
	local Layer = Owner and Owner._Overlay and Owner:_Overlay() or Screen.Get()
	local Open = false

	local Panel = New("Frame", {
		Name                   = "Picker",
		Parent                 = Layer,
		BackgroundColor3       = Theme.Scrim,
		BackgroundTransparency = 0.1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, Width, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		Visible                = false,
		ZIndex                 = 45,
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Stroke(Theme.White, 0.78, 1),
		Padding(6),
	})

	local Inner = New("CanvasGroup", {
		Parent                 = Panel,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		GroupTransparency      = 1,
		ZIndex                 = 46,
	}, {
		List(6),
	})

	local Order = 0

	--- The panel is a container, so a picker's body is built with the same
	--- controls as anything else.
	local Host = {
		_Mount = function()
			return Inner
		end,
		_Order = function()
			Order += 1
			return Order
		end,
		_Overlay = function()
			return Layer
		end,
		_Register = function() end,
		_Window = function()
			return Owner and Owner._Window and Owner:_Window() or nil
		end,
	}

	require(script.Parent.Parent.Shared).Attach(Host)

	Build(Host)

	local function Place()
		local Origin = Layer.AbsolutePosition
		local Anchor = Built.Mount

		Panel.Position = UDim2.fromOffset(
			Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X - Width - Origin.X,
			Anchor.AbsolutePosition.Y + Anchor.AbsoluteSize.Y + 4 - Origin.Y)
	end

	local function Close()
		if not Open then
			return
		end

		Open = false
		Tween(Inner, { GroupTransparency = 1 }, "exit")

		task.delay(MotionTime("exit"), function()
			if not Open then
				Panel.Visible = false
			end
		end)
	end

	local function Show()
		Open = true
		Place()
		Panel.Visible = true
		Inner.GroupTransparency = 1
		Tween(Inner, { GroupTransparency = 0 }, "fade")
	end

	if Owner and Owner._Register then
		Owner:_Register(Close)
	end

	return {
		Panel = Panel,
		Show = Show,
		Close = Close,
		Toggle = function()
			if Open then
				Close()
			else
				Show()
			end
		end,
		IsOpen = function()
			return Open
		end,
	}
end

--- Date. A row showing one date, with a calendar behind it.
function Controls.Date(Container, Options, Owner)
	local Handle = {}
	local Value = Midnight(Options.Default or os.time())
	local Width = Options.Width or 120

	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)

	local Chip = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.ChipHeight + 2),
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(0, 8),
	})

	local Readout = Text({
		Parent         = Chip,
		Text           = Stamp(Value, Options.Format),
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoBoldSize,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})

	local Sheet = nil

	local Pop = Popped(Built, Options, Owner, Options.PanelWidth or 220, function(Host)
		Sheet = Host:Calendar({
			Default = Value,
			Color = Options.Color,
			Flat = true,
			Callback = function(Picked)
				Value = Picked
				SwapText(Readout, Stamp(Value, Options.Format))

				if Options.Callback then
					task.spawn(Options.Callback, Value)
				end

				if Options.StayOpen ~= true then
					Pop.Close()
				end
			end,
		})
	end)

	local Button = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})

	Button.Activated:Connect(function()
		if not Handle:IsDisabled() then
			Pop.Toggle()
		end
	end)

	function Handle:Get()
		return Value
	end

	function Handle:Set(When, Silent)
		Value = Midnight(When)
		Readout.Text = Stamp(Value, Options.Format)

		if Sheet then
			Sheet:Set(Value, nil, true)
		end

		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Value)
		end

		return Handle
	end

	function Handle:Text()
		return Readout.Text
	end

	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
		Destroy = function()
			Pop.Panel:Destroy()
		end,
	})
end

--- DateRange. Two dates, one calendar.
function Controls.DateRange(Container, Options, Owner)
	local Handle = {}
	local Width = Options.Width or 170

	local From = Options.From and Midnight(Options.From) or Midnight(os.time())
	local To = Options.To and Midnight(Options.To) or nil

	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)

	local Chip = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.ChipHeight + 2),
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(0, 8),
	})

	local Readout = Text({
		Parent         = Chip,
		Text           = "",
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoBoldSize,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		Size           = UDim2.new(1, 0, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
	})

	local function Render()
		Readout.Text = string.format("%s - %s",
			Stamp(From, Options.Format or "!%d %b"),
			To and Stamp(To, Options.Format or "!%d %b") or "...")
	end

	local Sheet = nil

	local Pop = Popped(Built, Options, Owner, Options.PanelWidth or 220, function(Host)
		Sheet = Host:Calendar({
			Range = true,
			From = From,
			To = To,
			Color = Options.Color,
			Flat = true,
			Callback = function(A, B)
				From, To = A, B
				Render()

				if Options.Callback then
					task.spawn(Options.Callback, From, To)
				end
			end,
		})
	end)

	local Button = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 3,
	})

	Button.Activated:Connect(function()
		if not Handle:IsDisabled() then
			Pop.Toggle()
		end
	end)

	function Handle:Get()
		return From, To
	end

	function Handle:Set(A, B, Silent)
		From = A and Midnight(A) or From
		To = B and Midnight(B) or nil
		Render()

		if Sheet then
			Sheet:Set(From, To, true)
		end

		if not Silent and Options.Callback then
			task.spawn(Options.Callback, From, To)
		end

		return Handle
	end

	Render()

	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Button },
		Destroy = function()
			Pop.Panel:Destroy()
		end,
	})
end

--- Time. Hours and minutes on two steppers, in 24 hour or 12 hour.
function Controls.Time(Container, Options)
	local Handle = {}

	local Minutes = Clamp(Options.Default or 0, 0, 24 * 60 - 1)
	local Step = Options.Step or 5
	local Twelve = Options.Hours == 12

	local Width = Options.Width or 110

	local Built = Row(Container, Util.Merge(Options, { Reserve = Width }))
	Built:Reserve(Width)

	local Chip = New("Frame", {
		Parent                 = Built.Mount,
		BackgroundColor3       = Theme.Black,
		BackgroundTransparency = Theme.ChipTransparency,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, 0, 0.5, 0),
		Size                   = UDim2.new(0, Width, 0, Metrics.ChipHeight + 2),
	}, {
		Corner(Util.Radius(Options, Metrics.ChipRadius)),
		Padding(0, 4),
		Strip(2, Enum.HorizontalAlignment.Center),
	})

	local function Nudge(By)
		return function()
			if Handle:IsDisabled() then
				return
			end

			Minutes = (Minutes + By) % (24 * 60)
			Handle:Set(Minutes)
		end
	end

	local Down = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 16, 1, 0),
		LayoutOrder            = 1,
		ZIndex                 = 3,
	})

	Util.Chevron(Down, 10, "Left")

	local Readout = Text({
		Parent         = Chip,
		Text           = "",
		FontFace       = Theme.FontMono,
		TextSize       = Metrics.MonoLargeSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size           = UDim2.new(1, -40, 1, 0),
		AutomaticSize  = Enum.AutomaticSize.None,
		LayoutOrder    = 2,
	})

	local Up = New("TextButton", {
		Parent                 = Chip,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(0, 16, 1, 0),
		LayoutOrder            = 3,
		ZIndex                 = 3,
	})

	Util.Chevron(Up, 10, "Right")

	local function Render()
		local Hour = math.floor(Minutes / 60)
		local Minute = Minutes % 60

		if Twelve then
			local Suffix = Hour < 12 and "am" or "pm"
			local Shown = Hour % 12

			Readout.Text = string.format("%d:%02d %s", Shown == 0 and 12 or Shown, Minute, Suffix)
		else
			Readout.Text = string.format("%02d:%02d", Hour, Minute)
		end
	end

	Down.Activated:Connect(Nudge(-Step))
	Up.Activated:Connect(Nudge(Step))

	function Handle:Get()
		return Minutes
	end

	function Handle:Set(Value, Silent)
		Minutes = Clamp(Value, 0, 24 * 60 - 1)
		Render()

		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Minutes)
		end

		return Handle
	end

	function Handle:Text()
		return Readout.Text
	end

	Render()

	return Common(Handle, Built.Frame, Options, {
		Label = Built.Label,
		Description = Built.Description,
		Inputs = { Down, Up },
	})
end

return Controls
