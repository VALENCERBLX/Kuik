--!nonstrict
--- Layout.luau — Attach, sections and tab bars.
---
--- Attach is the seam that makes every container the same: whatever you can
--- put in a window you can put in a page, a section or an accordion, because
--- all of them get the same set of methods mixed in from the control registry.

local Palette  = require(script.Parent.Theme)
local Util     = require(script.Parent.Util)
local Motion   = require(script.Parent.Motion)
local Reveal   = require(script.Parent.Reveal)
local Parts    = require(script.Parent.Parts)
local Scroll   = require(script.Parent.Scroll)
local Controls = require(script.Parent.Controls)
local Shared   = require(script.Parent.Shared)

local Theme   = Palette.Tokens
local Metrics = Palette.Metrics

local New     = Util.New
local Text    = Util.Text
local Corner  = Util.Corner
local Padding = Util.Padding
local List    = Util.List
local Clamp   = Util.Clamp
local Round   = Util.Round

local Tween = Motion.Tween

local Layout = {}

--- Mixes every control into a container. Each method fills in the LayoutOrder
--- from the container's own counter, so things land in the order they were
--- declared without anyone having to number them.
local function Attach(Object)
	for Name, Constructor in Controls do
		--- Controls win every name they claim, so a container must never carry
		--- anything of the same name. That has bitten five times — Window.Group,
		--- Window.Header, Window.Status, Page.Button, Drawer:Toggle — a field
		--- or a method that silently became a control constructor. Methods
		--- count: Drawer:Toggle looked like it worked and quietly built a
		--- toggle row instead of opening the drawer.
		if rawget(Object, Name) ~= nil then
			error(string.format(
				"Kuik: a container already has %q, and the control of that name "
					.. "would replace it. Rename the field or method.", Name), 2)
		end

		Object[Name] = function(Self, Options)
			Options = Options or {}

			if Options.LayoutOrder == nil then
				Options.LayoutOrder = Self:_Order()
			end

			return Constructor(Self:_Mount(), Options, Self)
		end
	end

	--- Adding several at once, which reads better for a long form.
	function Object:Add(Kind, Options)
		local Constructor = Controls[Kind]

		if not Constructor then
			return nil
		end

		return Object[Kind](Object, Options)
	end

	--- A raw instance dropped into the flow, for anything the library does not
	--- have a widget for.
	function Object:Mount(Instance_, Options)
		Options = Options or {}

		Instance_.Parent = Object:_Mount()
		Instance_.LayoutOrder = Options.LayoutOrder or Object:_Order()

		if Options.Height then
			Instance_.Size = UDim2.new(1, 0, 0, Options.Height)
		end

		return Instance_
	end

	--- Wipes a container without destroying it, for anything rebuilt from live
	--- data. Layout instances stay: they are the container, not its contents.
	function Object:Clear()
		for _, Child in Object:_Mount():GetChildren() do
			if Child:IsA("GuiObject") then
				Child:Destroy()
			end
		end

		return Object
	end

	return Object
end

Shared.Attach = Attach

--- A section: a heading in the flow, and a handle you can hang controls off.
--- Its controls land in the window body, not inside the section frame, so a
--- section is a marker rather than a box.
local function MakeSection(Window, Title, Description, Options)
	Options = Options or {}

	local Section = {}

	local Frame = New("Frame", {
		Name                   = "Section",
		Parent                 = Window:_Mount(),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		LayoutOrder            = Window:_Order(),
	}, {
		Padding(Options.Top or 18, Metrics.RowPadding, 4, Metrics.RowPadding),
		List(3),
	})

	Text({
		Parent      = Frame,
		Text        = Title or "",
		TextSize    = Options.TitleSize or Metrics.SectionTitleSize,
		TextWrapped = true,
		LayoutOrder = 1,
	})

	if Description and Description ~= "" then
		Text({
			Parent           = Frame,
			Text             = Description,
			TextSize         = Options.DescriptionSize or Metrics.SectionDescSize,
			TextTransparency = Theme.TextSecondary,
			TextWrapped      = true,
			LayoutOrder      = 2,
		})
	end

	if Options.Rule then
		New("Frame", {
			Parent                 = Frame,
			BackgroundColor3       = Theme.White,
			BackgroundTransparency = Theme.RuleTransparency,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 1),
			LayoutOrder            = 3,
		})
	end

	function Section:_Mount()
		return Window:_Mount()
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

	function Section:_Window()
		return Window._Window and Window:_Window() or Window
	end

	function Section:Tabs(TabOptions)
		return Layout.Tabs(Window, TabOptions)
	end

	function Section:Section(NextTitle, NextDescription, NextOptions)
		return MakeSection(Window, NextTitle, NextDescription, NextOptions)
	end

	function Section:Destroy()
		Frame:Destroy()
	end

	Section.Frame = Frame

	return Attach(Section)
end

--- Fades the top of a page in, one row after another.
---
--- Only the first handful: past that the rows are below the fold, and a page
--- of forty controls should not schedule forty tweens to animate things
--- nobody is looking at.
local function Stagger(Page, Count)
	local At = 0

	for _, Child in Page:GetChildren() do
		if Child:IsA("GuiObject") and Child.Visible then
			At += 1

			if At > (Count or 9) then
				break
			end

			--- The whole row, not only its plate: the label, the description,
			--- the icon and the control all arrive together, one row behind
			--- the one above it.
			Motion.FadeIn(Child, (At - 1) * 0.035, "enter")
		end
	end
end

--- A tab bar and the pages behind it.
---
---   Variant = "Pill"       a sliding highlight behind the label
---   Variant = "Underline"  a rule that slides under it
---   Variant = "Rule"       brackets either side of the selected tab
local function MakeTabs(Window, Options)
	Options = Options or {}

	local Tabs = {}
	local Pages = {}
	local Active = nil
	local Pending = true

	local Variant = Options.Variant or "Pill"
	local Accent = Util.Colour(Options, Theme.White)

	local Bar = New("Frame", {
		Name                   = "Tabs",
		Parent                 = Window:_Mount(),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, Metrics.TabHeight + 14),
		LayoutOrder            = Options.LayoutOrder or Window:_Order(),
	}, {
		Padding(7, Metrics.RowPadding, 7, Metrics.RowPadding),
	})

	--- The bar scrolls: a window with nine tabs should not squeeze them.
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
		List(Options.Gap or Metrics.TabGap, Enum.FillDirection.Horizontal,
			Options.Align == "Center" and Enum.HorizontalAlignment.Center
			or Options.Align == "Right" and Enum.HorizontalAlignment.Right
			or Enum.HorizontalAlignment.Left),
	})

	local Highlight = New("Frame", {
		Name             = "Highlight",
		Parent           = Viewport,
		BackgroundColor3 = Accent,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 0, Metrics.TabHeight),
		Position         = UDim2.new(0, 0, 0, 0),
		Visible          = false,
		ZIndex           = 1,
	}, {
		Corner(Round(Options, math.floor(Metrics.TabHeight / 2))),
	})

	if Variant == "Underline" then
		Highlight.Size = UDim2.new(0, 0, 0, 2)
		Highlight.AnchorPoint = Vector2.new(0, 1)
		Highlight.Position = UDim2.new(0, 0, 1, 0)
	elseif Variant == "Rule" then
		Highlight.BackgroundTransparency = 1
	end

	--- The highlight drags a white smear behind it as it moves between tabs.
	--- It costs nothing while nobody is changing tab: the ghost lets go of the
	--- frame loop as soon as it has caught up.
	local Smear = nil

	if Variant ~= "Rule" and Options.Ghost ~= false then
		Smear = Reveal.Follow(Highlight, {
			Parent = Viewport,
			--- Round, not Radius: the highlight itself is rounded through Round,
			--- which clamps against PillRadius — so a theme that squares its
			--- pills squares the highlight. Asking for the raw radius here gave
			--- the smear rounded corners behind a square highlight.
			Radius = Round(Options, math.floor(Metrics.TabHeight / 2)),
			ZIndex = 0,
			Reach  = Options.GhostReach or 0.5,
			Span   = Options.GhostSpan or 52,
		})
	end

	local Brackets = nil

	if Variant == "Rule" then
		Brackets = {}

		for Index = 1, 2 do
			Brackets[Index] = New("Frame", {
				Parent                 = Viewport,
				BackgroundColor3       = Accent,
				BackgroundTransparency = Theme.RuleTransparency,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(Index - 1, 0),
				Size                   = UDim2.new(0, 1, 0, Metrics.TabHeight),
				Visible                = false,
				ZIndex                 = 3,
			})
		end
	end

	local Scroller = Scroll.Attach(Viewport, "X")

	--- The tab bar owns the wheel while the pointer is over it, so scrolling
	--- the tabs does not also scroll the page.
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
		local X = Button.AbsolutePosition.X - Strip.AbsolutePosition.X
		local Width = Button.AbsoluteSize.X

		Highlight.Visible = Variant ~= "Rule"

		local Target = Variant == "Underline"
			and UDim2.new(0, X, 1, 0)
			or UDim2.new(0, X, 0, 0)

		local Size = Variant == "Underline"
			and UDim2.new(0, Width, 0, 2)
			or UDim2.new(0, Width, 0, Metrics.TabHeight)

		if Animate then
			Tween(Highlight, { Position = Target, Size = Size }, "morph")
		else
			Highlight.Position = Target
			Highlight.Size = Size
		end

		if Brackets then
			for Index, Bracket in Brackets do
				Bracket.Visible = true

				local Where = UDim2.new(0, X + (Index == 1 and 0 or Width), 0, 0)

				if Animate then
					Tween(Bracket, { Position = Where }, "morph")
				else
					Bracket.Position = Where
				end
			end
		end
	end

	function Tabs:Select(Name, Silent)
		local Entry = Pages[Name]

		if not Entry then
			return false
		end

		Pending = false

		if Active == Name then
			return true
		end

		for OtherName, Other in Pages do
			local Selected = OtherName == Name

			if Selected then
				Other.Page.Visible = true
				Other.Slide.PaddingTop = UDim.new(0, 14)

				Tween(Other.Slide, { PaddingTop = UDim.new(0, 0) }, "reveal")
				Stagger(Other.Page)
			else
				Other.Page.Visible = false
			end

			--- The pill puts dark type on a light ground; the other variants
			--- leave the type white and only change its weight.
			local OnLight = Variant == "Pill"

			--- Assigned rather than tweened. A 0.12s fade on a tab label is
			--- not worth the race: two selects in the same frame used to leave
			--- the winner dimmed, because the loser's tween landed last.
			Other.Label.TextColor3 = Selected and OnLight and Theme.Black or Theme.White
			Other.Label.TextTransparency = Selected and 0 or Theme.TextSecondary

			if Other.Icon then
				Other.Icon.ImageColor3 = Selected and OnLight and Theme.Black or Theme.White
				Other.Icon.ImageTransparency = Selected and 0 or Theme.TextSecondary
			end
		end

		MoveHighlight(Entry.Button, Active ~= nil)
		Reveal(Entry.Button)

		Active = Name

		if not Silent and Options.Callback then
			task.spawn(Options.Callback, Name)
		end

		return true
	end

	function Tabs:Active()
		return Active
	end

	function Tabs:Pages()
		return Pages
	end

	function Tabs:Names()
		local Out = {}

		for _, Child in Strip:GetChildren() do
			if Child:IsA("TextButton") then
				table.insert(Out, Child.Name)
			end
		end

		return Out
	end

	function Tabs:Page(Name, Icon)
		local Button = New("TextButton", {
			Name                   = Name,
			Parent                 = Strip,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 0, Metrics.TabHeight),
			LayoutOrder            = #Strip:GetChildren(),
			ZIndex                 = 3,
		}, {
			Padding(0, Options.TabPadding or Metrics.TabPadding),
			List(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center),
		})

		Button:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Center

		local IconLabel = nil

		if Icon then
			IconLabel = New("ImageLabel", {
				Parent                 = Button,
				BackgroundTransparency = 1,
				Image                  = Util.Asset(Icon),
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
			TextSize               = Options.TextSize or (Metrics.RowDescSize),
			AutomaticSize          = Enum.AutomaticSize.X,
			Size                   = UDim2.new(0, 0, 1, 0),
			LayoutOrder            = 2,
			ZIndex                 = 4,
		})

		--- A Frame, not a CanvasGroup.
		---
		--- A CanvasGroup would give the page a single transparency to fade,
		--- which is tidier, but it rasterises to a texture sized to its own
		--- content. A page taller than a couple of thousand pixels is silently
		--- downscaled and renders as a grey blur. The slide below carries the
		--- transition on its own.
		local Page = New("Frame", {
			Name                   = "Page_" .. Name,
			Parent                 = Window:_Mount(),
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			Visible                = false,
			LayoutOrder            = Window:_Order(),
		}, {
			List(Metrics.RowGap),
		})

		--- Slid down and faded in on select, which is the whole page change
		--- animation.
		local Slide = New("UIPadding", {
			Parent     = Page,
			PaddingTop = UDim.new(0, 0),
		})

		local Order = 0

		--- Tab, not Button: Button is a control, and Attach would overwrite
		--- a field of that name with the constructor.
		local Handle = {
			Frame = Page,
			Tab   = Button,
			Label = Label,
			Name  = Name,
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

		function Handle:_Window()
			return Window._Window and Window:_Window() or Window
		end

		function Handle:Section(Title, Description, SectionOptions)
			return MakeSection(Handle, Title, Description, SectionOptions)
		end

		function Handle:Tabs(TabOptions)
			return MakeTabs(Handle, TabOptions)
		end

		function Handle:Select()
			return Tabs:Select(Name)
		end

		function Handle:SetLabel(NewText)
			Label.Text = NewText
			return Handle
		end

		function Handle:SetVisible(Value)
			Button.Visible = Value ~= false

			if not Button.Visible and Active == Name then
				for _, Other in Tabs:Names() do
					if Pages[Other] and Pages[Other].Button.Visible then
						Tabs:Select(Other)
						break
					end
				end
			end

			return Handle
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

		Button.MouseEnter:Connect(function()
			if Active ~= Name then
				Label.TextTransparency = Theme.TextPrimary
			end
		end)

		Button.MouseLeave:Connect(function()
			if Active ~= Name then
				Label.TextTransparency = Theme.TextSecondary
			end
		end)

		--- The first page added selects itself, unless something has already
		--- chosen one by then. Deferred so the strip has been laid out and the
		--- highlight lands in the right place.
		if Active == nil and Pending then
			task.defer(function()
				if Active == nil and Pending then
					Tabs:Select(Name)
				end
			end)
		end

		return Attach(Handle)
	end

	function Tabs:Destroy()
		if Smear then
			Smear:Destroy()
			Smear = nil
		end

		Scroller:Destroy()
		Bar:Destroy()

		for _, Entry in Pages do
			Entry.Page:Destroy()
		end

		table.clear(Pages)

		local At = table.find(Window.TabBars or {}, Tabs)

		if At then
			table.remove(Window.TabBars, At)
		end
	end

	Tabs.Frame = Bar
	Tabs.Viewport = Viewport

	--- Registered on the owning window so Window:GoTo can find a page by name
	--- without the caller holding on to the bar.
	local Root = Window._Window and Window:_Window() or Window

	if Root and Root.TabBars then
		table.insert(Root.TabBars, Tabs)
	end

	return Tabs
end

Layout.Attach  = Attach
Layout.Section = MakeSection
Layout.Tabs    = MakeTabs

Shared.Tabs    = MakeTabs
Shared.Section = MakeSection

return Layout
