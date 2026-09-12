--!nonstrict
--[[
	Smoke test: builds every control the library exposes and exercises its
	handle. Run with:  lune run tests/build

	This proves construction and logic, not appearance — the shim has no
	layout engine, so AbsoluteSize is always zero and nothing is ever really
	measured. Anything about how it looks has to be checked in Studio.
]]

local Shim = require("./shim")
Shim.Install()

local Kuik = require("./Kuik")

local Failures = 0
local Checks = 0

local function Check(Name, Condition, Detail)
	Checks += 1

	if Condition then
		print(string.format("  ok    %s", Name))
	else
		Failures += 1
		print(string.format("  FAIL  %s%s", Name, Detail and (" - " .. Detail) or ""))
	end
end

local function Try(Name, Body)
	local Ok, Result = pcall(Body)
	Check(Name, Ok, not Ok and tostring(Result) or nil)
	return Ok and Result or nil
end

print("\nKuik " .. Kuik.Version.Version .. "\n")

--------------------------------------------------------------------------
print("window")
--------------------------------------------------------------------------

local Window = Try("Window builds", function()
	return Kuik.Window({ Title = "Kuik", Subtitle = "test", Open = true })
end)

Check("Window has a root", Window and Window.Root ~= nil)
Check("Window opens", Window and Window:IsOpen() == true)
Check("Window closes", (function()
	Window:Close()
	return not Window:IsOpen()
end)())

Window:Open()

--- Toggle is a control, not a verb: the registry owns that name on every
--- container, so opening and closing goes through SetOpen.
Check("Toggle on a window builds a row, it does not close it", (function()
	local Row = Window:Toggle({ Label = "Not a verb" })
	local Built = Row ~= nil and Window:IsOpen()
	Row:Destroy()
	return Built
end)())

Window:SetOpen(false)
Check("SetOpen flips it", not Window:IsOpen())
Window:SetOpen(true)

--------------------------------------------------------------------------
print("\nwindow manipulation")
--------------------------------------------------------------------------

Try("SetPosition", function()
	Window:SetPosition(UDim2.new(0, 40, 0, 60), false)
end)

Check("SetPosition lands", Window:GetPosition().X.Offset == 40)

Try("SetSize", function()
	Window:SetSize(400, 300, false)
end)

Check("SetSize lands", select(1, Window:GetSize()) == 400)

Try("Dock", function()
	Window:Dock("BottomRight", 20, false)
end)

Check("Dock sets the anchor", Window.Root.AnchorPoint.X == 1 and Window.Root.AnchorPoint.Y == 1)
Check("Dock insets", Window:GetPosition().X.Offset == -20)

Try("Nudge", function()
	Window:Nudge(5, 5, false)
end)

Check("Nudge is relative", Window:GetPosition().X.Offset == -15)

Try("SetScale", function() Window:SetScale(0.9, false) end)
Try("SetOpacity", function() Window:SetOpacity(0.5, false) end)
Try("SetTitle", function() Window:SetTitle("Renamed", "still a test") end)
Try("SetFill", function() Window:SetFill(Kuik.Theme.Scrim, 0.2) end)
Try("BringToFront", function() Window:BringToFront() end)
Try("SetDraggable on", function() Window:SetDraggable(true) end)
Try("SetDraggable off", function() Window:SetDraggable(false) end)
Try("SetResizable on", function() Window:SetResizable(true) end)
Try("SetResizable off", function() Window:SetResizable(false) end)
Try("SetParallax on", function() Window:SetParallax(12) end)
Try("SetParallax off", function() Window:SetParallax(0) end)

Window:Dock("Center", 0, false)
Window:SetScale(1, false)
Window:SetOpacity(1, false)

--------------------------------------------------------------------------
print("\npanel")
--------------------------------------------------------------------------

local Panel = Try("Panel builds", function()
	return Kuik.Panel({ Width = 200, Height = 60, Dock = "TopLeft" })
end)

Check("Panel has no backdrop", Panel and Panel.Backdrop == nil)
Check("Panel body is not a scroller", Panel and Panel.Body.ClassName == "Frame")
Check("Panel takes controls", (function()
	local Ok = pcall(function()
		Panel:Progress({ Label = "Health", Default = 0.7 })
	end)

	return Ok
end)())

Try("Card window builds", function()
	local Card = Kuik.Card({ Title = "Card", Open = true })
	Card:Destroy()
end)

--------------------------------------------------------------------------
print("\ntabs and pages")
--------------------------------------------------------------------------

local Tabs = Try("Tabs build", function()
	return Window:Tabs()
end)

local Page = Try("Page builds", function()
	return Tabs:Page("General")
end)

local Second = Try("Second page builds", function()
	return Tabs:Page("Audio")
end)

Check("Tabs registered on the window", #Window.TabBars == 1)
Check("Pages are addressable", Tabs:Pages()["Audio"] ~= nil)

Try("Select", function() Tabs:Select("Audio") end)
Check("Select lands", Tabs:Active() == "Audio")
Check("Selecting again is a no-op", Tabs:Select("Audio") == true)
Check("Select of an unknown page fails cleanly", Tabs:Select("Nope") == false)

Check("Window:GoTo finds a page", Window:GoTo("General") == true)
Check("Window:GoTo misses cleanly", Window:GoTo("Nowhere") == false)

for _, Variant in { "Pill", "Underline", "Rule" } do
	Try("Tabs variant " .. Variant, function()
		local Bar = Window:Tabs({ Variant = Variant })
		Bar:Page("One")
		Bar:Page("Two")
		Bar:Destroy()
	end)
end

local Section = Try("Section builds", function()
	return Page:Section("Options", "Everything below is a control")
end)

--------------------------------------------------------------------------
print("\ninput controls")
--------------------------------------------------------------------------

local Toggle = Try("Toggle", function()
	return Section:Toggle({ Label = "Enabled", Default = true })
end)

Check("Toggle reads back", Toggle and Toggle:Get() == true)
Toggle:Set(false)
Check("Toggle writes", Toggle:Get() == false)
Toggle:Cycle()
Check("Toggle flips", Toggle:Get() == true)

for _, Variant in { "Switch", "Check", "Pill" } do
	Try("Toggle variant " .. Variant, function()
		Section:Toggle({ Label = Variant, Variant = Variant })
	end)
end

local Checkbox = Try("Checkbox", function()
	return Section:Checkbox({ Label = "Agree" })
end)

Check("Checkbox is a toggle", Checkbox and Checkbox:Get() == false)

local Tri = Try("Tristate", function()
	return Section:Tristate({ Label = "Some", Default = false })
end)

Check("Tristate runs off, on, mixed", (function()
	local Off = Tri:Get() == false
	Tri:Cycle()
	local On = Tri:Get() == true
	Tri:Cycle()
	local Mixed = Tri:Get() == nil
	Tri:Cycle()
	return Off and On and Mixed and Tri:Get() == false
end)())

Try("Autocomplete", function()
	local Suggest = Section:Autocomplete({
		Label = "City",
		Items = { "Halcyon", "Continental", "Freeport" },
	})

	Suggest:Set("Halcyon")
end)

local Slider = Try("Slider", function()
	return Section:Slider({ Label = "Volume", Min = 0, Max = 100, Step = 5, Default = 40 })
end)

Check("Slider reads back", Slider and Slider:Get() == 40)
Slider:Set(63)
Check("Slider quantises to the step", Slider:Get() == 65)
Slider:Set(1000)
Check("Slider clamps", Slider:Get() == 100)
Slider:SetRange(0, 10)
Check("Slider re-ranges", Slider:Get() == 10)

Try("Slider ticks variant", function()
	Section:Slider({ Label = "Ticks", Min = 0, Max = 10, Step = 1, Variant = "Ticks" })
end)

local Range = Try("Range", function()
	return Section:Range({ Label = "Window", Min = 0, Max = 100, Low = 20, High = 80 })
end)

Check("Range reads back", (function()
	local Low, High = Range:Get()
	return Low == 20 and High == 80
end)())

local Stepper = Try("Stepper", function()
	return Section:Stepper({ Label = "Count", Min = 0, Max = 5, Default = 2 })
end)

Check("Stepper reads back", Stepper and Stepper:Get() == 2)
Stepper:Set(9)
Check("Stepper clamps", Stepper:Get() == 5)

local Wrapping = Try("Stepper wrap", function()
	return Section:Stepper({ Label = "Wrap", Min = 1, Max = 3, Default = 3, Wrap = true })
end)

Wrapping:Set(4)
Check("Stepper wraps", Wrapping:Get() == 1)

local Input = Try("Input", function()
	return Section:Input({ Label = "Name", Default = "kr3ative" })
end)

Check("Input reads back", Input and Input:Get() == "kr3ative")
Input:Set("changed")
Check("Input writes", Input:Get() == "changed")

Try("TextArea", function()
	Section:TextArea({ Label = "Notes", Default = "line" })
end)

Try("Search", function()
	Section:Search({ Label = "Find" })
end)

local Numeric = Try("Numeric input", function()
	return Section:Input({ Label = "Rounds", Numeric = true, Default = 12, Min = 0, Max = 30 })
end)

Check("Numeric input reads a number", Numeric and Numeric:Get() == 12)

Try("Password input", function()
	Section:Input({ Label = "Key", Password = true, Default = "hunter2" })
end)

local Keybind = Try("Keybind", function()
	return Section:Keybind({ Label = "Menu", Default = Enum.KeyCode.RightShift })
end)

Check("Keybind reads back", Keybind and Keybind:Get() == Enum.KeyCode.RightShift)

local Dropdown = Try("Dropdown", function()
	return Section:Dropdown({ Label = "Quality", Items = { "Low", "High" }, Default = "Low" })
end)

Check("Dropdown reads back", Dropdown and Dropdown:Get() == "Low")
Dropdown:Set("High")
Check("Dropdown writes", Dropdown:Get() == "High")

Check("Dropdown builds one button per item", (function()
	local Total = 0

	local function Walk(Node)
		for _, Child in Node:GetChildren() do
			if Child.ClassName == "TextButton" and Child.Name ~= "Hit" then
				Total += 1
			end

			Walk(Child)
		end
	end

	Walk(Dropdown.Frame)

	--- The menu lives on the window overlay, not in the row, so count there.
	Total = 0
	Walk(Window.Overlay)

	return Total >= 2
end)())

Try("Dropdown SetItems", function()
	Dropdown:SetItems({ "A", "B", "C" }, true)
end)

Check("SetItems keeps a valid value", Dropdown:Get() == "A")

local Multi = Try("Multi dropdown", function()
	return Section:Dropdown({
		Label = "Filters",
		Items = { "One", "Two", "Three" },
		Multi = true,
		Default = { "One" },
		Search = true,
	})
end)

Check("Multi dropdown returns a list", (function()
	local Values = Multi:Get()
	return type(Values) == "table" and Values[1] == "One"
end)())

Multi:Set({ "Two", "Three" }, true)
Check("Multi dropdown writes", #Multi:Get() == 2)

local Radio = Try("Radio", function()
	return Section:Radio({ Label = "Mode", Items = { "A", "B" }, Default = "A" })
end)

Check("Radio reads back", Radio and Radio:Get() == "A")

Try("Radio columns", function()
	Section:Radio({ Label = "Grid", Items = { "1", "2", "3", "4" }, Columns = 2 })
end)

local Chips = Try("Chips", function()
	return Section:Chips({ Label = "Tags", Items = { "X", "Y", "Z" }, Default = { "X" } })
end)

Check("Chips read back", Chips and #Chips:Get() == 1)
Chips:Set({ "X", "Y" })
Check("Chips write", #Chips:Get() == 2)

local Segmented = Try("Segmented", function()
	return Section:Segmented({ Label = "View", Items = { "List", "Grid" }, Default = "List" })
end)

Check("Segmented reads back", Segmented and Segmented:Get() == "List")

local Tags = Try("Tags", function()
	return Section:Tags({ Label = "Words", Default = { "one" } })
end)

Check("Tags read back", Tags and Tags:Get()[1] == "one")
Tags:Set({ "a", "b" })
Check("Tags write", #Tags:Get() == 2)

local Vector = Try("Vector", function()
	return Section:Vector({ Label = "Offset", Default = { 1, 2, 3 } })
end)

Check("Vector reads back", Vector and Vector:Get()[2] == 2)

--------------------------------------------------------------------------
print("\ndata controls")
--------------------------------------------------------------------------

local Status = Try("Status", function()
	return Section:Status({ Label = "Ping", Value = "22ms" })
end)

Check("Status reads back", Status and Status:Get() == "22ms")

Try("Stat", function()
	Section:Stat({ Items = { { Label = "kills", Value = 4 }, { Label = "deaths", Value = 1 } } })
end)

local Badge = Try("Badge", function()
	return Section:Badge({ Label = "Build", Text = "beta", Color = Kuik.Theme.Warn })
end)

Try("Badge set", function() Badge:Set("stable", Kuik.Theme.Good) end)

local Progress = Try("Progress", function()
	return Section:Progress({ Label = "Loading", Default = 0.4 })
end)

Check("Progress reads back", Progress and Progress:Get() == 0.4)
Try("Progress indeterminate", function() Progress:Indeterminate(true) end)
Try("Progress determinate", function() Progress:Indeterminate(false) end)

local Meter = Try("Meter", function()
	return Section:Meter({ Label = "Heat", Default = 40, Warn = 0.6, Danger = 0.85 })
end)

Check("Meter reads back", Meter and Meter:Get() == 40)

local Ring = Try("Ring", function()
	return Section:Ring({ Label = "Charge", Default = 0.6 })
end)

Check("Ring reads back", Ring and Ring:Get() == 0.6)

Try("Spinner", function()
	local Spin = Section:Spinner({ Label = "Working" })
	Spin:Stop()
end)

local Sparkline = Try("Sparkline", function()
	return Section:Sparkline({ Label = "FPS", Values = { 1, 4, 2, 8 } })
end)

Try("Sparkline push", function() Sparkline:Push(6, 4) end)
Check("Sparkline keeps its limit", #Sparkline:Get() == 4)

local Graph = Try("Graph", function()
	return Section:Graph({ Label = "Frame time", Values = { 1, 2, 3 }, Grid = 3 })
end)

Try("Graph push", function() Graph:Push(4) end)

local Bars = Try("Bars", function()
	return Section:Bars({ Label = "Damage", Values = { 3, 6, 1 } })
end)

Try("Bars push", function() Bars:Push(9, 3) end)
Check("Bars keep their limit", #Bars:Get() == 3)

Try("Heatmap", function()
	Section:Heatmap({ Label = "Grid", Values = { { 1, 2 }, { 3, 4 } } })
end)

local Rating = Try("Rating", function()
	return Section:Rating({ Label = "Score", Default = 3 })
end)

Check("Rating reads back", Rating and Rating:Get() == 3)
Rating:Set(99)
Check("Rating clamps", Rating:Get() == 5)

local Pagination = Try("Pagination", function()
	return Section:Pagination({ Label = "Page", Pages = 4, Default = 1 })
end)

Pagination:Set(9)
Check("Pagination clamps", Pagination:Get() == 4)
Pagination:SetPages(2)
Check("Pagination re-clamps on fewer pages", Pagination:Get() == 2)

local List = Try("List", function()
	return Section:List({ Label = "Servers", Items = { "one", "two" }, Default = "one" })
end)

Check("List reads back", List and List:Get() == "one")
Try("List SetItems", function() List:SetItems({ "alpha" }) end)

local Table = Try("Table", function()
	return Section:Table({
		Label = "Scores",
		Columns = { { Label = "Name" }, { Label = "Score", Align = "Right" } },
		Rows = { { "kr3ative", 10 }, { "guest", 4 } },
		Sortable = true,
	})
end)

Try("Table push", function() Table:Push({ "third", 1 }, 3) end)
Check("Table holds its rows", #Table:Get() == 3)

local Tree = Try("Tree", function()
	return Section:Tree({
		Label = "Tree",
		Nodes = {
			{ Label = "Root", Open = true, Children = { { Label = "Leaf" } } },
		},
	})
end)

Try("Timeline", function()
	Section:Timeline({
		Label = "History",
		Items = { { Label = "Started", Time = "0:00" }, { Label = "Ended", Time = "1:00" } },
	})
end)

--------------------------------------------------------------------------
print("\ncolour controls")
--------------------------------------------------------------------------

local Colour = Try("Color", function()
	return Section:Color({ Label = "Tint", Default = Color3.fromRGB(255, 0, 0) })
end)

Check("Color reads back", Colour and Colour:Get().R == 1)

local Picker = Try("ColorPicker", function()
	return Section:ColorPicker({ Label = "Accent", Default = Color3.fromRGB(0, 255, 0) })
end)

Check("ColorPicker reads back", Picker and math.abs(Picker:Get().G - 1) < 0.01)

local Swatches = Try("Swatches", function()
	return Section:Swatches({
		Label = "Team",
		Items = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255) },
	})
end)

Check("Swatches read back", Swatches and Swatches:Get().R == 1)

Try("Gradient", function()
	local Ramp = Section:Gradient({ Label = "Ramp" })
	Ramp:Set(Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255), 45)
end)

--------------------------------------------------------------------------
print("\nmedia controls")
--------------------------------------------------------------------------

local Image = Try("Image", function()
	return Section:Image({ Label = "Poster", Image = 123456, Caption = "a caption" })
end)

Check("Image accepts a bare asset id", Image and Image.Picture.Image == "rbxassetid://123456")

Check("Image plate defaults to the embed surface",
	Image and Image.Well.BackgroundTransparency == Kuik.Theme.EmbedTransparency)

Try("Image background off", function() Image:SetBackground(false) end)
Try("Image background on", function() Image:SetBackground(Kuik.Theme.Black, 0.2) end)

Check("Background = false means no plate", (function()
	local Bare = Section:Image({ Label = "Bare", Image = 1, Background = false })
	return Bare.Well.BackgroundTransparency == 1
end)())

Try("Icon", function()
	Section:Icon({ Label = "Marker", Image = 1 })
end)

Try("Gallery", function()
	local Strip = Section:Gallery({
		Label = "Shots",
		Items = { 1, 2, { Image = 3, Label = "third" } },
	})

	Strip:Set(2)
end)

Try("Viewport", function()
	local View = Section:Viewport({ Label = "Model" })
	View:SetAngle(1, 0.2)
	View:SetDistance(20)
end)

Try("Video", function()
	local Clip = Section:Video({ Label = "Clip", Video = 1 })
	Clip:Play()
	Clip:Pause()
end)

Try("Audio", function()
	local Track = Section:Audio({ Label = "Track", Sound = 1 })
	Track:Play()
	Track:Pause()
end)

Try("Marquee", function()
	Section:Marquee({ Text = "scrolling" })
end)

--------------------------------------------------------------------------
print("\ncontent controls")
--------------------------------------------------------------------------

local Button = Try("Button", function()
	return Section:Button({ Label = "Apply", Action = "Run", Callback = function() end })
end)

Check("Button carries a face", Button and Button.Face ~= nil)

for _, Variant in { "Pill", "Solid", "Outline", "Ghost", "Text", "Rule" } do
	Try("Button variant " .. Variant, function()
		Section:Button({ Label = Variant, Variant = Variant, Callback = function() end })
	end)
end

Try("Button full width", function()
	Section:Button({ Label = "Wide", Full = true, Callback = function() end })
end)

local Pressed = false

local Rule = Try("Rule button", function()
	return Section:Rule({
		Action = "Continue",
		Callback = function()
			Pressed = true
		end,
	})
end)

Check("Rule button has a face", Rule and Rule.Face ~= nil)

local Clicked = false

Try("Clickable divider", function()
	Section:Divider({
		Label = "or",
		Callback = function()
			Clicked = true
		end,
	})
end)

Try("Plain divider", function() Section:Divider({}) end)
Try("Gap", function() Section:Gap({ Height = 20 }) end)

local Paragraph = Try("Paragraph", function()
	return Section:Paragraph({ Label = "About", Text = "Some copy." })
end)

Try("Paragraph set", function() Paragraph:Set("Other copy.") end)

local Embed = Try("Paragraph with an image", function()
	return Section:Paragraph({
		Text = "With a picture",
		Image = 99,
		ImageBackgroundTransparency = 1,
	})
end)

Check("Paragraph image honours a transparent plate",
	Embed and Embed.Picture.BackgroundTransparency == 1)

Check("Image only paragraph has no body label", (function()
	local Only = Section:Paragraph({ Image = 1 })
	return Only.Body == nil
end)())

Try("Paragraph SetBackground", function() Embed:SetBackground(false) end)

Try("Quote", function()
	Section:Quote({ Text = "Two rules, no panel.", Author = "kr3ative" })
end)

local Code = Try("Code", function()
	return Section:Code({ Label = "Snippet", Text = "local A = 1\nprint(A)" })
end)

Try("Code set", function() Code:Set("return true") end)

local Alert = Try("Alert", function()
	return Section:Alert({ Label = "Careful", Text = "Read this.", Color = Kuik.Theme.Warn })
end)

Try("Alert set", function() Alert:Set("Changed", "New text.") end)
Try("Alert colour", function() Alert:SetColor(Kuik.Theme.Danger) end)
Try("Alert pulse", function() Alert:Pulse() end)

Check("Alert hides through the handle", (function()
	Alert:SetVisible(false)
	return Alert:IsVisible() == false
end)())

Alert:SetVisible(true)

Check("Alert can start hidden", (function()
	local Hidden = Section:Alert({ Label = "Hidden", Visible = false })
	return Hidden:IsVisible() == false
end)())

for _, Variant in { "Accent", "Solid", "Outline", "Subtle" } do
	Try("Alert variant " .. Variant, function()
		Section:Alert({ Label = Variant, Text = "x", Variant = Variant })
	end)
end

Try("Callout", function()
	Section:Callout({ Label = "One line of guidance." })
end)

local Accordion = Try("Accordion", function()
	return Section:Accordion({ Label = "More", Open = true })
end)

Check("Accordion is a container", Accordion and type(Accordion.Slider) == "function")

Try("Accordion holds controls", function()
	Accordion:Toggle({ Label = "Nested toggle" })
	Accordion:Alert({ Label = "Nested alert" })
end)

Check("Accordion reports its state", Accordion:IsOpen() == true)
Accordion:SetOpen(false)
Check("Accordion closes", Accordion:IsOpen() == false)

local Breadcrumb = Try("Breadcrumb", function()
	return Section:Breadcrumb({ Path = { "Home", "Settings" } })
end)

Try("Breadcrumb push", function() Breadcrumb:Push("Audio") end)
Check("Breadcrumb holds its path", #Breadcrumb:Get() == 3)

local Steps = Try("Steps", function()
	return Section:Steps({ Label = "Setup", Items = { "One", "Two", "Three" }, Default = 1 })
end)

Steps:Next()
Check("Steps advance", Steps:Get() == 2)

Try("Avatar", function()
	local Face = Section:Avatar({ Label = "kr3ative", Description = "host", UserId = 1 })
	Face:SetUser(2)
end)

Try("Toolbar", function()
	Section:Toolbar({
		Items = { { Label = "Copy" }, { Label = "Paste" } },
		Callback = function() end,
	})
end)

Try("Header", function()
	Section:Header({ Label = "A heading", Description = "with a line" })
end)

--------------------------------------------------------------------------
print("\nlinks and navigation")
--------------------------------------------------------------------------

local Landed = nil

local PageLink = Try("Link to a page", function()
	return Page:Link({
		Label = "Go to Audio",
		Target = "Audio",
		Callback = function(Kind)
			Landed = Kind
		end,
	})
end)

Check("Link to a page navigates", PageLink and PageLink:Follow() == "page")

local Ran = false

local ActionLink = Try("Link to an action", function()
	return Page:Link({
		Label = "Run",
		Target = function()
			Ran = true
		end,
	})
end)

Check("Link to an action runs it", (function()
	ActionLink:Follow()
	return Ran
end)())

Check("Link to a missing page reports it", (function()
	local Missing = Page:Link({ Label = "Nowhere", Target = "Nope" })
	return Missing:Follow() == "missing"
end)())

Check("Link to an element reveals it", (function()
	local Jump = Page:Link({ Label = "Find", Target = Toggle })
	return Jump:Follow() == "element"
end)())

local Child = Try("Child window", function()
	return Window:Child({ Title = "Detail", Open = true })
end)

Check("Child registered on the parent", #Window:Children() == 1)

Check("Link to a window opens it", (function()
	Child:Close()
	local Open = Page:Link({ Label = "Detail", Target = Child })
	Open:Follow()
	return Child:IsOpen()
end)())

Check("Destroying a child unregisters it", (function()
	Child:Destroy()
	return #Window:Children() == 0
end)())

--------------------------------------------------------------------------
print("\nshared handle behaviour")
--------------------------------------------------------------------------

Check("Every control can be hidden", (function()
	Toggle:SetVisible(false)
	local Hidden = Toggle:IsVisible() == false
	Toggle:SetVisible(true)
	return Hidden
end)())

Check("Every control can be disabled", (function()
	Slider:SetDisabled(true)
	local Off = Slider:IsDisabled()
	Slider:SetDisabled(false)
	return Off
end)())

Check("A disabled control ignores its own setter path", (function()
	Toggle:SetDisabled(true)
	local Before = Toggle:Get()
	Toggle:SetDisabled(false)
	return Before == Toggle:Get()
end)())

Try("SetLabel", function() Toggle:SetLabel("Renamed") end)
Try("SetDescription", function()
	local Described = Section:Toggle({ Label = "L", Description = "D" })
	Described:SetDescription("New")
end)

Try("Tooltip option", function()
	Section:Toggle({ Label = "Hover me", Tooltip = "Explains itself" })
end)

Try("Disabled option", function()
	Section:Toggle({ Label = "Off", Disabled = true })
end)

Try("Radius option", function()
	Section:Toggle({ Label = "Round", Radius = 8 })
end)

Try("Colour option", function()
	Section:Slider({ Label = "Red", Color = Kuik.Theme.Danger, Max = 10 })
end)

--------------------------------------------------------------------------
print("\ncontainer helpers")
--------------------------------------------------------------------------

Try("Add by name", function()
	Section:Add("Toggle", { Label = "Added by name" })
end)

Try("Mount a raw instance", function()
	Section:Mount(Kuik.New("Frame", { BackgroundTransparency = 1 }), { Height = 10 })
end)

local Scratch = Try("Clear a container", function()
	local Bin = Window:Tabs():Page("Scratch")
	Bin:Toggle({ Label = "temporary" })
	Bin:Clear()
	return Bin
end)

Check("Clear leaves the layout alone", (function()
	local Layouts = 0

	for _, Child in Scratch.Frame:GetChildren() do
		if Child.ClassName == "UIListLayout" or Child.ClassName == "UIPadding" then
			Layouts += 1
		end
	end

	return Layouts >= 1
end)())

Try("Group container", function()
	local Bin = Section:Group({ Label = "A group", Variant = "Outline" })
	Bin:Toggle({ Label = "inside the group" })
	Bin:Clear()
end)

local Split = Try("Columns", function()
	return Section:Columns({ Count = 2, Weights = { 2, 1 } })
end)

Check("Columns hand back containers", (function()
	Split:Column(1):Toggle({ Label = "Left" })
	Split:Column(2):Toggle({ Label = "Right" })
	return #Split:Each() == 2
end)())

--------------------------------------------------------------------------
print("\nname collisions")
--------------------------------------------------------------------------

--- Attach mixes every control name onto every container, so a control called
--- Toggle would quietly replace a window method or field of that name. This
--- has bitten three times; the guard is cheaper than the fourth.
Check("Every control is callable on a window", (function()
	local Fresh = Kuik.Window({ Title = "Names" })

	for Name in Kuik.Controls do
		if type(Fresh[Name]) ~= "function" then
			Fresh:Destroy()
			print("        control lost its name: " .. Name)
			return false
		end
	end

	Fresh:Destroy()
	return true
end)())

Check("No control name shadows a window field", (function()
	local Fresh = Kuik.Window({ Title = "Fields", Open = true })

	local Fields = {
		"Root", "Canvas", "Body", "Overlay", "Content",
		"HeaderFrame", "TabBars", "Options",
	}

	for _, Field in Fields do
		if type(Fresh[Field]) == "function" or Fresh[Field] == nil then
			Fresh:Destroy()
			print("        window field lost: " .. Field)
			return false
		end
	end

	Fresh:Destroy()
	return true
end)())

Check("No control name shadows a page field", (function()
	local Bar = Window:Tabs()
	local Sheet = Bar:Page("Names")
	local Ok = Sheet.Tab ~= nil and typeof(Sheet.Tab) ~= "function"
		and Sheet.Frame ~= nil
	Bar:Destroy()
	return Ok
end)())

--------------------------------------------------------------------------
print("\nregistering a control")
--------------------------------------------------------------------------

Kuik.Register("Sticker", function(Container, Options)
	local Frame = Kuik.New("Frame", {
		Name = "Sticker",
		Parent = Container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 10),
		LayoutOrder = Options.LayoutOrder or 0,
	})

	return { Frame = Frame, Destroy = function() Frame:Destroy() end }
end)

Check("A registered control appears on new containers", (function()
	local Fresh = Kuik.Window({ Title = "Fresh" })
	local Ok = type(Fresh.Sticker) == "function"

	if Ok then
		Fresh:Sticker({})
	end

	Fresh:Destroy()

	return Ok
end)())

--------------------------------------------------------------------------
print("\npickers")
--------------------------------------------------------------------------

local Calendar = Try("Calendar", function()
	return Section:Calendar({ Label = "Month" })
end)

Check("Calendar reads back a day", Calendar and type(Calendar:Get()) == "number")

Try("Calendar paging", function()
	Calendar:Show(os.time() + 86400 * 40)
end)

local Date = Try("Date", function()
	return Section:Date({ Label = "Start", Default = os.time() })
end)

Check("Date reads back", Date and type(Date:Get()) == "number")

local Span = Try("DateRange", function()
	return Section:DateRange({ Label = "Window", From = os.time() })
end)

Check("DateRange reads back a start", (function()
	local From = Span:Get()
	return type(From) == "number"
end)())

local Clock = Try("Time", function()
	return Section:Time({ Label = "Curfew", Default = 22 * 60 + 30, Step = 15 })
end)

Check("Time reads back", Clock and Clock:Get() == 22 * 60 + 30)
Check("Time formats", Clock:Text() == "22:30")

Clock:Set(24 * 60 + 5)
Check("Time clamps to the day", Clock:Get() == 24 * 60 - 1)

Try("Twelve hour time", function()
	local Half = Section:Time({ Label = "Meet", Default = 13 * 60, Hours = 12 })
	Check("Twelve hour reads pm", Half:Text() == "1:00 pm")
end)

--------------------------------------------------------------------------
print("\nboards, terminals and media")
--------------------------------------------------------------------------

Try("Skeleton", function()
	local Bones = Section:Skeleton({ Lines = 4 })
	Bones:Stop()
end)

local Well = Try("Well", function()
	return Section:Well({ Height = 60 })
end)

Check("Well is a container", (function()
	Well:Toggle({ Label = "inside the well" })
	return type(Well.Slider) == "function"
end)())

local More = Try("LoadMore", function()
	return Section:LoadMore({ Label = "More", Callback = function() return false end })
end)

Try("LoadMore finishes", function() More:Finish() end)
Try("LoadMore resets", function() More:Reset() end)

local Board = Try("Kanban", function()
	return Section:Kanban({
		Label = "Work",
		Columns = {
			{ Label = "Todo", Cards = { "One", { Label = "Two", Text = "detail" } } },
			{ Label = "Done", Cards = { "Three" } },
		},
	})
end)

Try("Kanban push", function() Board:Push(1, "Four") end)

Try("Compare", function()
	Section:Compare({
		Label = "Plans",
		Items = { "Free", "Pro" },
		Best = 2,
		Rows = { { "Seats", 1, 10 }, { "Support", false, true } },
	})
end)

Try("Treemap", function()
	Section:Treemap({
		Label = "Spend",
		Items = {
			{ Label = "Gear", Value = 40 },
			{ Label = "Bribes", Value = 25 },
			{ Label = "Rent", Value = 35 },
		},
	})
end)

Try("Motd", function()
	Section:Motd({ Label = "NOTICE", Text = "Server restarts in 10 minutes." })
end)

local Ascii = Try("AsciiBar", function()
	return Section:AsciiBar({ Label = "Upload", Default = 0.5 })
end)

Check("AsciiBar reads back", Ascii and Ascii:Get() == 0.5)

Try("Kbd", function()
	Section:Kbd({ Label = "Sprint", Keys = { "Shift", "W" } })
end)

local Scrubber = Try("Scrubber", function()
	return Section:Scrubber({ Label = "Clip", Length = 120, Default = 30 })
end)

Check("Scrubber reads back", Scrubber and Scrubber:Get() == 30)
Try("Scrubber buffered", function() Scrubber:SetBuffered(0.6) end)

local Volume = Try("Volume", function()
	return Section:Volume({ Label = "Music", Default = 0.6 })
end)

Check("Volume reads back", Volume and select(1, Volume:Get()) == 0.6)

Volume:SetMuted(true)
Check("Volume mutes to zero", select(1, Volume:Get()) == 0)
Volume:SetMuted(false)

local Knob = Try("Knob", function()
	return Section:Knob({ Label = "Drive", Min = 0, Max = 11, Default = 5 })
end)

Check("Knob reads back", Knob and Knob:Get() == 5)
Knob:Set(99)
Check("Knob clamps", Knob:Get() == 11)

Try("VU", function()
	local Meter = Section:VU({ Label = "Output" })
	Meter:Set({ 0.7, 0.4 })
end)

Try("Waveform", function()
	local Wave = Section:Waveform({ Label = "Sample", Values = { 0.2, 0.8, 0.4, 1, 0.3 } })
	Wave:SetPlayed(0.5)
end)

Try("Zoom", function()
	Section:Zoom({ Label = "Map", Image = 1 })
end)

local Gallery = Try("Gallery", function()
	return Section:Gallery({
		Label = "Shots",
		Items = { { Image = 1, Label = "one" }, { Image = 2, Label = "two" } },
	})
end)

--- The bug this guards: gallery thumbnails cropped, so the pictures were only
--- ever shown from the middle out.
Check("Gallery thumbnails show the whole picture", (function()
	for _, Item in Gallery.Frame:GetDescendants() do
		if Item:IsA("ImageLabel") and Item.Image ~= "" then
			return tostring(Item.ScaleType) == "Fit", tostring(Item.ScaleType)
		end
	end

	return false, "no picture"
end)())

Check("Expanding does nothing until something has been measured",
	Gallery:Expand(1) ~= nil)

local Carousel = Try("Carousel", function()
	return Section:Carousel({
		Label = "Shots",
		Items = { { Image = 1, Label = "one" }, { Image = 2, Label = "two" } },
	})
end)

Carousel:Next()
Check("Carousel pages", Carousel:Get() == 2)

--- The bug this guards: the strip moved by a fraction of a pane rather than a
--- whole one, so it never actually reached the next image. A pane is one
--- window wide, so a step is one whole unit of the window's scale.
Check("Carousel moves a whole image at a time", (function()
	local Rail = Carousel.Frame:FindFirstChild("Rail", true)

	Shim.Step(400)

	return Rail ~= nil and math.abs(Rail.Position.X.Scale + 1) < 0.001, Rail and tostring(Rail.Position)
end)())

Carousel:Next()
Check("Carousel wraps", Carousel:Get() == 1)

Carousel:Step(-1)
Check("Stepping stops at the first image", Carousel:Get() == 1)

--- The other shape: every pane stacked over the middle of the window rather
--- than laid out along a rail, so the ones either side show behind the one in
--- focus.
local Stack = Try("Carousel, deck", function()
	return Section:Carousel({
		Label = "Deck",
		Variant = "Deck",
		Items = { { Image = 1 }, { Image = 2 }, { Image = 3 } },
	})
end)

Check("A deck has no rail", Stack.Frame:FindFirstChild("Rail", true) == nil)

Check("Its panes are all stacked on the middle", (function()
	local Panes = {}

	for _, Item in Stack.Frame:GetDescendants() do
		if Item.Name == "Pane" then
			table.insert(Panes, Item)
		end
	end

	if #Panes ~= 3 then
		return false, tostring(#Panes) .. " panes"
	end

	for _, Pane in Panes do
		if Pane.AnchorPoint.X ~= 0.5 or Pane.AnchorPoint.Y ~= 0.5 then
			return false, "not centred"
		end
	end

	return true
end)())

Check("The one in focus is in front and full size", (function()
	Stack:Show(2)
	Shim.Step(400)

	local Front, Behind = nil, nil

	for _, Item in Stack.Frame:GetDescendants() do
		if Item.Name == "Pane" then
			if Item.LayoutOrder == 2 then
				Front = Item
			elseif Item.LayoutOrder == 1 then
				Behind = Item
			end
		end
	end

	local Scale = Front:FindFirstChildOfClass("UIScale")
	local Back = Behind:FindFirstChildOfClass("UIScale")

	return Front.ZIndex > Behind.ZIndex
		and math.abs(Scale.Scale - 1) < 0.01
		and Back.Scale < 1,
		string.format("front z%d scale %.2f, behind z%d scale %.2f",
			Front.ZIndex, Scale.Scale, Behind.ZIndex, Back.Scale)
end)())
Carousel:Step(1)
Check("Stepping moves one on", Carousel:Get() == 2)
Carousel:Step(1)
Check("Stepping stops at the last image", Carousel:Get() == 2)
Carousel:Show(1)

local Ran, Chosen = 0, nil

local Split_ = Try("SplitButton", function()
	return Section:SplitButton({
		Label = "Deploy",
		Action = "Run",
		Items = { { Label = "Dry run" }, { Label = "Rollback" } },
		Callback = function(Item)
			Ran += 1
			Chosen = Item
		end,
		Chose = function(_, Index)
			Chosen = Index
		end,
	})
end)

Check("SplitButton starts on the action it was given",
	Split_.Frame:FindFirstChild("Action", true).Text == "Run")

--- The bug this guards: choosing from the menu changed neither the button nor
--- what it does, so the split button was a plain button with a dead caret.
Split_:Select(2)

Check("Choosing an item retitles the button",
	Split_.Frame:FindFirstChild("Action", true).Text == "Rollback",
	Split_.Frame:FindFirstChild("Action", true).Text)

Check("Choosing an item runs it", Ran == 1)
Check("and the running one is the one chosen", select(2, Split_:Get()).Label == "Rollback")

Split_:Run()
Check("The button runs the current item", Ran == 2)

Split_:Select(1, true)
Check("A silent select does not run", Ran == 2)
Check("but still retitles", Split_.Frame:FindFirstChild("Action", true).Text == "Dry run")

Split_:SetAction("Deploy")
Check("SetAction renames it", Split_.Frame:FindFirstChild("Action", true).Text == "Deploy")

local Pane = Try("Split", function()
	return Section:Split({ Height = 120, At = 0.4 })
end)

Check("Split hands back two containers", (function()
	Pane:Left():Toggle({ Label = "Left" })
	Pane:Right():Toggle({ Label = "Right" })
	return math.abs(Pane:Get() - 0.4) < 0.001
end)())

--------------------------------------------------------------------------
print("\noverlay layers")
--------------------------------------------------------------------------

local Popover = Try("Popover", function()
	return Kuik.Popover({ Width = 200 })
end)

Check("Popover is a container", type(Popover.Toggle) == "function")

Try("Popover content", function()
	Popover:Paragraph({ Text = "Anchored" })
	Popover:Show(Toggle.Frame)
	Popover:Close()
	Popover:Destroy()
end)

local Sheet = Try("Sheet", function()
	return Kuik.Sheet({ Height = 200 })
end)

Try("Sheet content", function()
	Sheet:Toggle({ Label = "In a sheet" })
	Sheet:Show()
	Sheet:Close()
	Sheet:Destroy()
end)

local Drawer = Try("Drawer", function()
	return Kuik.Drawer({ Width = 200, Side = "Left" })
end)

Check("Drawer is a container and opens with Flip", (function()
	--- Toggle is a control, so a drawer's open verb cannot be called that.
	Drawer:Toggle({ Label = "In a drawer" })

	Drawer:Flip()
	local Opened = Drawer:IsOpen()

	Drawer:Flip()
	local Closed = not Drawer:IsOpen()

	Drawer:Destroy()

	return Opened and Closed
end)())

local Toured = nil

local Coach = Try("Coach", function()
	return Kuik.Coach({
		Steps = {
			{ Label = "One", Text = "First", Target = Toggle },
			{ Label = "Two", Text = "Second" },
		},
		Callback = function(Completed)
			Toured = Completed
		end,
	})
end)

Try("Coach runs", function()
	Coach:Start()
	Coach:Next()
	Coach:Next()
end)

Check("Coach reports completion", Toured == true)
Try("Coach destroys", function() Coach:Destroy() end)

--------------------------------------------------------------------------
print("\nwindow chrome")
--------------------------------------------------------------------------

local Chrome = Try("Window with a title bar", function()
	return Kuik.Window({
		Title = "Chrome",
		TitleBar = true,
		StatusBar = "ready",
		Open = true,
		Draggable = true,
	})
end)

Check("Title bar exists", Chrome and Chrome.TitleBar ~= nil)

Try("Status line", function() Chrome:SetStatus("busy") end)

Check("Minimise then restore", (function()
	local Before = select(2, Chrome:GetSize())
	Chrome:Minimise()
	local Small = select(2, Chrome:GetSize())
	Chrome:Restore()
	return Small < Before and select(2, Chrome:GetSize()) == Before
end)())

Check("Maximise then restore", (function()
	local Before = select(1, Chrome:GetSize())
	Chrome:Maximise()
	Chrome:Restore()
	return select(1, Chrome:GetSize()) == Before
end)())

Try("Chrome destroys", function() Chrome:Destroy() end)

--------------------------------------------------------------------------
print("\nmotion")
--------------------------------------------------------------------------

--- Numbers are the one type the spring solver can still dispatch on
--- headlessly, so the solver itself is tested through one.
Check("A spring settles on its goal", (function()
	local Object = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Object.Parent = Kuik.Screen()

	Kuik.Tween(Object, { BackgroundTransparency = 0 }, "snap")
	Shim.Step(400)

	local Landed = math.abs(Object.BackgroundTransparency) < 0.001
	Object:Destroy()

	return Landed
end)())

Check("A spring retargets in flight without restarting", (function()
	local Object = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Object.Parent = Kuik.Screen()

	Kuik.Tween(Object, { BackgroundTransparency = 0 }, "reveal")
	Shim.Step(4)

	local Midway = Object.BackgroundTransparency

	Kuik.Tween(Object, { BackgroundTransparency = 0.5 }, "reveal")
	Shim.Step(400)

	local Landed = math.abs(Object.BackgroundTransparency - 0.5) < 0.001
	Object:Destroy()

	return Midway < 1 and Landed
end)())

--- The bug this guards: a line chart animated each bar's centre, length and
--- angle as three independent springs, so the line came apart in flight — bars
--- detached from their neighbours, swung, and rejoined. The points move now,
--- and every bar is rebuilt from them, so the line is joined at every instant.
Check("A line chart stays joined while it moves", (function()
	local Chart = Section:Sparkline({ Label = "Load", Values = { 0, 1, 0, 1, 0 } })

	Chart:Set({ 1, 0, 1, 0, 1 })

	local Worst = 0

	for _ = 1, 30 do
		Shim.Step(1)

		local Bars = {}

		for _, Item in Chart.Frame:GetDescendants() do
			if Item.Name == "Segment" then
				table.insert(Bars, Item)
			end
		end

		table.sort(Bars, function(A, B) return A.Position.X.Offset < B.Position.X.Offset end)

		--- Each bar's far end should be the next bar's near end. If the three
		--- properties were springing separately they would not be.
		for Index = 1, #Bars - 1 do
			local A, B = Bars[Index], Bars[Index + 1]

			local Angle = math.rad(A.Rotation)
			local Half = A.Size.X.Offset / 2
			local EndX = A.Position.X.Offset + math.cos(Angle) * Half
			local EndY = A.Position.Y.Offset + math.sin(Angle) * Half

			local Next = math.rad(B.Rotation)
			local Reach = B.Size.X.Offset / 2
			local StartX = B.Position.X.Offset - math.cos(Next) * Reach
			local StartY = B.Position.Y.Offset - math.sin(Next) * Reach

			local Gap = math.sqrt((EndX - StartX) ^ 2 + (EndY - StartY) ^ 2)

			Worst = math.max(Worst, Gap)
		end
	end

	Chart:Destroy()

	return Worst < 2, string.format("worst join %.2f px", Worst)
end)())

Check("A named motion role has a settle time", Kuik.Motion.MotionTime("snap") > 0)
Check("A duration role reports its duration", Kuik.Motion.MotionTime("instant") == 0)

--- Every named role but the instant one is a spring now, and a spring's settle
--- time is derived from its stiffness rather than declared.
Check("Every role is a spring", (function()
	for Name, Spec in Kuik.Theme.Motion do
		if Name ~= "instant" and not Spec.Stiffness then
			return false, Name
		end
	end

	return true
end)())

Check("A spring role settles in a sensible time", (function()
	for Name, Spec in Kuik.Theme.Motion do
		if Spec.Stiffness then
			local Settle = Kuik.Motion.MotionTime(Name)

			if Settle <= 0 or Settle > 1 then
				return false
			end
		end
	end

	return true
end)())

--- A spring that carries a transparency or a colour must not overshoot, or the
--- value clips at the end of its range and the fade flickers.
Check("Roles that carry transparency are at or above critical", (function()
	for _, Name in { "hover", "press", "fade", "tint", "scroll" } do
		local Spec = Kuik.Theme.Motion[Name]
		local Critical = 2 * math.sqrt(Spec.Stiffness)

		if Spec.Damping < Critical - 0.001 then
			return false
		end
	end

	return true
end)())

--------------------------------------------------------------------------
print("\nhud")
--------------------------------------------------------------------------

Try("Toast", function() Kuik.Toast("hello", { Duration = 0 }) end)
Try("Notify", function() Kuik.Notify({ Title = "Saved", Text = "All good" }) end)

Try("Hints", function()
	local Hints = Kuik.Hints()
	Hints:Add("E", "interact")
	Hints:Clear()
end)

Try("Log", function()
	local Log = Kuik.Log()
	Log:Push("a line")
	Log:Clear()
end)

Try("Console", function()
	local Console = Kuik.Console()
	Console:Push("WARN", "careful")
end)

Try("Watermark", function()
	local Mark = Kuik.Watermark({ Tag = { Text = "KUIK" } })
	Mark:Set({ "60 fps", "22 ms" })
	Mark:SetSide("Right")
end)

local Bar = Try("Bar", function()
	return Kuik.Bar({ Label = "HEALTH", Max = 100, Default = 100, Warn = 0.5, Danger = 0.2 })
end)

Bar:Set(30)
Check("Bar reads back", Bar:Get() == 30)

Try("Timer", function()
	local Clock = Kuik.Timer({ Seconds = 30, Autostart = false })
	Clock:Set(10)
	Clock:Start()
	Clock:Stop()
end)

Try("Ammo", function()
	local Ammo = Kuik.Ammo({ Weapon = "SILENCED", Magazine = 7, Reserve = 21, Capacity = 7 })
	Ammo:Set(0, 21)
	Ammo:SetWeapon("BLADE")
end)

Try("Crosshair", function()
	local Cross = Kuik.Crosshair({ Dot = true })
	Cross:SetSpread(4)
	Cross:Hit()
end)

Try("Killfeed", function()
	local Feed = Kuik.Killfeed()
	Feed:Push("kr3ative", "eliminated", "guest")
	Feed:Clear()
end)

Try("Objective", function()
	local Task = Kuik.Objective({ Text = "Reach the roof", Progress = 0.2 })
	Task:Set("Escape", 0.9)
end)

Try("Vignette", function()
	local Edge = Kuik.Vignette()
	Edge:Set(0.3)
	Edge:Pulse()
end)

Try("Compass", function()
	local Compass = Kuik.Compass()
	Compass:Destroy()
end)

--------------------------------------------------------------------------
print("\nlayers")
--------------------------------------------------------------------------

Try("Menu", function()
	local Menu = Kuik.Menu({
		Items = { { Label = "Copy" }, { Separator = true }, { Label = "Delete" } },
	})

	Menu:Show(10, 10)
	Menu:Close()
	Menu:Destroy()
end)

Check("A prompt blocks the world", (function()
	local Before = Kuik.Blocked()

	local Prompt = Kuik.Prompt({
		Title = "Sure?",
		Buttons = { { Label = "No" }, { Label = "Yes", Primary = true } },
	})

	local During = Kuik.Blocked()
	Prompt:Close("No")
	local After = Kuik.Blocked()

	return not Before and During and not After
end)())

Check("Prompt has a slot for extra content", (function()
	local Prompt = Kuik.Prompt({ Title = "Pick" })
	local Slot = Prompt:Slot()
	Prompt:Close()
	return Slot ~= nil
end)())

--------------------------------------------------------------------------
print("\ncards")
--------------------------------------------------------------------------

local Deck = Try("Cards", function()
	return Kuik.Cards({ Gap = 60 })
end)

local One = Kuik.Window({ Title = "One" })
local Two = Kuik.Window({ Title = "Two" })
local Three = Kuik.Window({ Title = "Three" })

Try("Add to the deck", function()
	Deck:Add(One)
	Deck:Add(Two)
	Deck:Add(Three)
end)

Check("Deck counts its cards", Deck:Count() == 3)
Check("Adding a closed card opens it", One:IsOpen() and Two:IsOpen())

Deck:Next()
Check("Deck advances", select(1, Deck:Focused()) == 2)

Deck:Previous()
Check("Deck goes back", select(1, Deck:Focused()) == 1)

Deck:Focus(99)
Check("Deck clamps the focus", select(1, Deck:Focused()) == 3)

Check("Setting a value outright cancels the spring moving it", (function()
	local Object = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Object.Parent = Kuik.Screen()

	Kuik.Tween(Object, { BackgroundTransparency = 0 }, "reveal")
	Shim.Step(3)

	Kuik.Motion.Halt(Object, "BackgroundTransparency")
	Object.BackgroundTransparency = 0.25

	Shim.Step(200)

	local Held = math.abs(Object.BackgroundTransparency - 0.25) < 0.001
	Object:Destroy()

	return Held
end)())

Check("Reach gates the deck", (function()
	Deck:SetReach(2)
	Deck:Focus(3)
	local Held = select(1, Deck:Focused()) == 2
	Deck:SetReach(nil)
	Deck:Focus(3)
	return Held and select(1, Deck:Focused()) == 3
end)())

Deck:Focus(1)

Try("Remove a card", function() Deck:Remove(2) end)
Check("Remove shrinks the deck", Deck:Count() == 2)
Check("Remove destroys the window it held", not Two:IsAlive())

Check("Destroying a card drops it from the deck", (function()
	Three:Destroy()
	return Deck:Count() == 1
end)())

Try("Destroy the deck", function() Deck:Destroy() end)
Check("Destroying the deck destroys its windows", not One:IsAlive())

--- The bug this guards: destroying a card calls back into the deck to forget
--- it, which removes it from the very list Destroy was walking — so the
--- entries that shuffled down were skipped and a full deck always left the
--- last couple of cards on screen. One card was never enough to show it.
Check("Destroying a full deck destroys every card", (function()
	local Full = Kuik.Cards({ Gap = 60 })
	local Cards = {}

	for Index = 1, 5 do
		Cards[Index] = Kuik.Window({ Title = "Card " .. Index })
		Full:Add(Cards[Index])
	end

	if Full:Count() ~= 5 then
		return false, "deck did not take five"
	end

	Full:Destroy()

	local Alive = 0

	for _, Card in Cards do
		if Card:IsAlive() then
			Alive += 1
		end
	end

	return Alive == 0, string.format("%d still alive", Alive)
end)())

Check("A deck asked to keep its cards keeps them", (function()
	local Kept = Kuik.Cards({ Gap = 60 })
	local Cards = {}

	for Index = 1, 4 do
		Cards[Index] = Kuik.Window({ Title = "Kept " .. Index })
		Kept:Add(Cards[Index])
	end

	Kept:Destroy(true)

	for _, Card in Cards do
		if not Card:IsAlive() then
			return false
		end

		Card:Destroy()
	end

	return true
end)())

Check("Destroying twice is safe", (function()
	local Ok = pcall(function()
		One:Destroy()
	end)

	return Ok
end)())

--------------------------------------------------------------------------
print("\nthemes")
--------------------------------------------------------------------------

local Started = Kuik.Theme.Scrim

Check("Every named theme applies", (function()
	for Name in Kuik.Themes do
		if not Kuik.SetTheme(Name) then
			return false
		end
	end

	return true
end)())

Kuik.SetTheme("Remorse")
Check("Themes restore what they did not set", Kuik.Theme.Scrim == Started)

Check("An unknown theme fails cleanly", Kuik.SetTheme("Nope") == false)

Kuik.RegisterTheme("Test", { Danger = Color3.fromRGB(1, 2, 3) })
Kuik.SetTheme("Test")
Check("A registered theme applies", Kuik.Theme.Danger.R * 255 < 2)

Kuik.SetTheme("Remorse")
Check("Switching back restores the token", Kuik.Theme.Danger.R * 255 > 250)

Check("Theme changes reach a listener", (function()
	local Heard = false
	local Stop = Kuik.OnTheme(function() Heard = true end)

	Kuik.SetTheme("Midnight")
	Stop()
	Kuik.SetTheme("Remorse")

	return Heard
end)())

Check("A live object follows the theme", (function()
	local Fresh = Kuik.Window({ Title = "Painted", Open = true })
	local Row = Fresh:Toggle({ Label = "Painted" })

	Kuik.SetTheme("Terminal")
	local Painted = Row.Frame.BackgroundColor3 == Kuik.Theme.White

	Kuik.SetTheme("Remorse")
	Fresh:Destroy()

	return Painted
end)())

--------------------------------------------------------------------------
print("\nshowcase")
--------------------------------------------------------------------------

--- The showcase builds every control there is, so it doubles as the widest
--- construction test in the suite.
local Gallery = Try("Showcase builds", function()
	return Kuik.Showcase({ Title = "Test", Open = true })
end)

Check("Showcase reports nothing broken", (function()
	if not Gallery then
		return false
	end

	if #Gallery.Broken > 0 then
		print("        broken: " .. table.concat(Gallery.Broken, ", "))
		return false
	end

	return true
end)())

Try("Showcase destroys", function()
	Gallery:Destroy()
end)

--------------------------------------------------------------------------
print("\nteardown")
--------------------------------------------------------------------------

Try("Controls destroy", function()
	Toggle:Destroy()
	Slider:Destroy()
	Dropdown:Destroy()
	Picker:Destroy()
end)

Try("Window destroys", function()
	Window:Destroy()
	Panel:Destroy()
end)

Try("Reset", function() Kuik.Reset() end)

print(string.format("\n%d checks, %d failures\n", Checks, Failures))

if Failures > 0 then
	error(string.format("%d failures", Failures), 0)
end
