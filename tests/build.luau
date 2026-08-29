--!nonstrict
--[[
	Smoke test: builds every component the library exposes and exercises the
	handles. Run with:  lune run tests/build

	This proves construction, not appearance — the shim has no layout engine.
]]

local Process = require("@lune/process")

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
		print(string.format("  FAIL  %s%s", Name, Detail and (" — " .. Detail) or ""))
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

local Window = Try("construct", function()
	return Kuik.Window({
		Title    = "Settings",
		Subtitle = "Manage your preferences",
		Key      = Enum.KeyCode.Tab,
	})
end)

Check("root exists", Window and Window.Root ~= nil)
Check("body is a ScrollingFrame", Window and Window.Body.ClassName == "ScrollingFrame")
Check("starts hidden", Window and Window:IsOpen() == false)

Try("open", function() Window:Open() end)
Check("open after :Open", Window:IsOpen() == true)

Try("close", function() Window:Close() end)
Check("closed after :Close", Window:IsOpen() == false)

Try("setopen", function() Window:SetOpen(true) end)
Check("open after SetOpen", Window:IsOpen() == true)

--- The collision that motivates the naming: every container gets a Toggle
--- row constructor, so the window must not use that name for open/close.
Check("Window:Toggle builds a row", (function()
	local Row = Window:Toggle({ Label = "Collision check", Default = true })
	return type(Row) == "table" and Row.Get ~= nil and Row:Get() == true
end)())

Check("Show/Hide aliases survive", Window.Show == Window.Open and Window.Hide == Window.Close)

--------------------------------------------------------------------------
print("\nsections and tabs")
--------------------------------------------------------------------------

local Section = Try("section", function()
	return Window:Section("Categories", "Choose a category to configure.")
end)

local Tabs = Try("tabs", function()
	return Section:Tabs()
end)

local Camera = Try("page camera", function() return Tabs:Page("Camera") end)
local Visual = Try("page visual", function() return Tabs:Page("Visual") end)
local Audio  = Try("page audio",  function() return Tabs:Page("Audio") end)

Try("select page", function() Tabs:Select("Visual") end)
Check("active page tracked", Tabs:Active() == "Visual")
Check("selected page visible", Visual.Frame.Visible == true)
Check("other page hidden", Camera.Frame.Visible == false)

--------------------------------------------------------------------------
print("\ncontrols")
--------------------------------------------------------------------------

local Fired = {}
local Hairline_Good = Kuik.Theme.Good

local Toggle = Try("toggle", function()
	return Visual:Toggle({
		Label       = "Show UI/UX",
		Description = "Show and configure interface elements.",
		Default     = true,
		Callback    = function(Value) Fired.Toggle = Value end,
	})
end)

Check("toggle default", Toggle:Get() == true)
Toggle:Set(false)
Check("toggle set fires", Fired.Toggle == false)
Toggle:Set(true, true)
Check("toggle silent set", Toggle:Get() == true and Fired.Toggle == false)

local Slider = Try("slider", function()
	return Visual:Slider({
		Label       = "Field of view",
		Description = "Camera field of view.",
		Min = 60, Max = 120, Step = 1, Default = 100,
		Callback = function(Value) Fired.Slider = Value end,
	})
end)

Check("slider default", Slider:Get() == 100)
Slider:Set(400)
Check("slider clamps high", Slider:Get() == 120)
Slider:Set(-5)
Check("slider clamps low", Slider:Get() == 60)
Slider:Set(77.4)
Check("slider quantises", Slider:Get() == 77)

local Fractional = Try("slider fractional", function()
	return Visual:Slider({ Label = "Strength", Min = 0, Max = 1, Step = 0.05, Default = 0.5 })
end)

Fractional:Set(0.27)
Check("fractional quantises", math.abs(Fractional:Get() - 0.25) < 1e-9,
	tostring(Fractional and Fractional:Get()))

local Stepper = Try("stepper", function()
	return Visual:Stepper({ Label = "Movement amount", Min = 0, Max = 10, Step = 1, Default = 5 })
end)

Check("stepper default", Stepper:Get() == 5)

local Dropdown = Try("dropdown", function()
	return Visual:Dropdown({
		Label = "Watermark side",
		Items = { "Left", "Right" },
		Default = "Left",
		Callback = function(Value) Fired.Dropdown = Value end,
	})
end)

Dropdown:Set("Right")
Check("dropdown set", Dropdown:Get() == "Right" and Fired.Dropdown == "Right")

local Keybind = Try("keybind", function()
	return Visual:Keybind({ Label = "Open settings", Default = Enum.KeyCode.Tab })
end)

Check("keybind default", Keybind:Get() == Enum.KeyCode.Tab)

local Input = Try("input", function()
	return Visual:Input({ Label = "Display name", Default = "kr3ative" })
end)

Check("input default", Input:Get() == "kr3ative")

Try("button", function()
	return Visual:Button({ Label = "Reset settings", Action = "Reset", Callback = function() end })
end)

Try("paragraph", function()
	return Audio:Paragraph({ Label = "Notice", Text = "Audio is mixed for headphones." })
end)

Try("gap", function() return Audio:Gap({ Height = 20 }) end)

--- Rows added straight to the window, with no section or tab in between.
Try("bare row on window", function()
	return Window:Toggle({ Label = "Bare", Default = false })
end)

--------------------------------------------------------------------------
print("\nwidgets")
--------------------------------------------------------------------------

Try("divider", function() return Audio:Divider({}) end)
Try("divider labelled", function() return Audio:Divider({ Label = "Advanced" }) end)

local Accordion = Try("accordion", function()
	return Audio:Accordion({ Label = "Advanced", Description = "Rarely needed.", Open = false })
end)

Check("accordion starts closed", Accordion:IsOpen() == false)
Try("accordion nests a control", function()
	return Accordion:Toggle({ Label = "Nested", Default = true })
end)
Try("accordion nests an accordion", function()
	return Accordion:Accordion({ Label = "Deeper" })
end)
Accordion:SetOpen(true)
Check("accordion opens", Accordion:IsOpen() == true)

local Radio = Try("radio", function()
	return Audio:Radio({ Label = "Output", Items = { "Stereo", "Mono" }, Default = "Stereo",
		Callback = function(V) Fired.Radio = V end })
end)
Check("radio default", Radio:Get() == "Stereo")
Radio:Set("Mono")
Check("radio set", Radio:Get() == "Mono" and Fired.Radio == "Mono")

local Checkbox = Try("checkbox", function()
	return Audio:Checkbox({ Label = "Subtitles", Default = false })
end)
Checkbox:Set(true)
Check("checkbox set", Checkbox:Get() == true)

local Chips = Try("chips", function()
	return Audio:Chips({ Label = "Filters", Items = { "A", "B", "C" }, Default = { "A", "C" } })
end)
Check("chips default", #Chips:Get() == 2)
Chips:Set({ "B" })
Check("chips set", #Chips:Get() == 1 and Chips:Get()[1] == "B")

local ListWidget = Try("list", function()
	return Audio:List({ Label = "Servers", Items = { "us-east", "eu-west" }, Default = "us-east" })
end)
ListWidget:Set("eu-west")
Check("list set", ListWidget:Get() == "eu-west")

Try("badge", function()
	return Audio:Badge({ Label = "Connection", Text = "STABLE", Color = Hairline_Good })
end)

local Status = Try("status", function()
	return Audio:Status({ Label = "Ping", Value = "34ms" })
end)
Status:Set("41ms")
Check("status set", Status:Get() == "41ms")

local Progress = Try("progress", function()
	return Audio:Progress({ Label = "Download", Default = 0.25, Max = 1 })
end)
Progress:Set(0.8)
Check("progress set", math.abs(Progress:Get() - 0.8) < 1e-9)

local Meter = Try("meter", function()
	return Audio:Meter({ Label = "Memory", Default = 40, Max = 100, Warn = 0.7, Danger = 0.9 })
end)
Meter:Set(95)
Check("meter set", Meter:Get() == 95)

Try("spinner", function() return Audio:Spinner({ Label = "Connecting" }) end)

local Spark = Try("sparkline", function()
	return Audio:Sparkline({ Label = "FPS", Values = { 60, 58, 61, 59, 62 } })
end)
Try("sparkline push", function() Spark:Push(57, 4) end)
Check("sparkline limit", #Spark:Get() == 4, tostring(#Spark:Get()))

local Graph = Try("graph", function()
	return Audio:Graph({ Label = "Latency", Values = { 30, 44, 38, 51, 29 } })
end)
Try("graph push", function() Graph:Push(60) end)
Check("graph grew", #Graph:Get() == 6)

Try("graph flat data", function()
	return Audio:Graph({ Label = "Flat", Values = { 5, 5, 5, 5 } })
end)
Try("graph single point", function()
	return Audio:Graph({ Label = "One", Values = { 5 } })
end)
Try("graph empty", function() return Audio:Graph({ Label = "None", Values = {} }) end)

local Rating = Try("rating", function()
	return Audio:Rating({ Label = "Difficulty", Count = 5, Default = 3 })
end)
Rating:Set(9)
Check("rating clamps", Rating:Get() == 5)

Try("avatar", function()
	return Audio:Avatar({ Label = "Chloe Mercier", Description = "CONSERVATOR", UserId = 1 })
end)

local TableWidget = Try("table", function()
	return Audio:Table({
		Label = "Scores",
		Columns = { { Label = "Player", Width = 0.6 }, { Label = "Score", Width = 0.4, Align = "Right" } },
		Rows = { { "kr3ative", 41 }, { "loll", 38 } },
	})
end)
Try("table set", function() TableWidget:Set({ { "kryptra", 12 } }) end)
Check("table rows replaced", #TableWidget:Get() == 1)

local VectorWidget = Try("vector", function()
	return Audio:Vector({ Label = "Offset", Default = { 1, 2, 3 } })
end)
Check("vector default", VectorWidget:Get()[2] == 2)
VectorWidget:Set({ 4, 5, 6 })
Check("vector set", VectorWidget:Get()[3] == 6)

Try("vector 2 axes", function()
	return Audio:Vector({ Label = "UV", Axes = { "U", "V" }, Default = { 0.5, 0.5 } })
end)

local ColorWidget = Try("color", function()
	return Audio:Color({ Label = "Accent", Default = Color3.new(1, 0, 0) })
end)
ColorWidget:Set(Color3.new(0, 0, 1))
Check("color set", ColorWidget:Get().B == 1)

local Crumb = Try("breadcrumb", function()
	return Audio:Breadcrumb({ Path = { "game", "Workspace", "Map" } })
end)
Try("breadcrumb set", function() Crumb:Set({ "game" }) end)
Check("breadcrumb replaced", #Crumb:Get() == 1)

local Pages = Try("pagination", function()
	return Audio:Pagination({ Label = "Results", Default = 1, Pages = 4 })
end)
Pages:Set(99)
Check("pagination clamps", Pages:Get() == 4)
Pages:SetPages(2)
Check("pagination reclamps on SetPages", Pages:Get() == 2)

local Picker = Try("colorpicker", function()
	return Audio:ColorPicker({ Label = "Accent", Default = Color3.fromRGB(255, 0, 0) })
end)
Picker:Set(Color3.fromRGB(0, 0, 255))
Check("colorpicker set", math.abs(Picker:Get().B - 1) < 0.02, tostring(Picker:Get().B))

local Segmented = Try("segmented", function()
	return Audio:Segmented({ Label = "Quality", Items = { "Low", "High" }, Default = "Low" })
end)
Segmented:Set("High")
Check("segmented set", Segmented:Get() == "High")

local Range = Try("range", function()
	return Audio:Range({ Label = "Band", Min = 0, Max = 100, Step = 1, Low = 20, High = 80 })
end)
local RangeLow, RangeHigh = Range:Get()
Check("range default", RangeLow == 20 and RangeHigh == 80)
Range:Set(90, 10)
local ClampedLow, ClampedHigh = Range:Get()
Check("range keeps high above low", ClampedHigh >= ClampedLow,
	string.format("%s..%s", tostring(ClampedLow), tostring(ClampedHigh)))

local Bars = Try("bars", function()
	return Audio:Bars({ Label = "Throughput", Values = { 3, 7, 2, 9, 5 } })
end)
Try("bars push", function() Bars:Push(11, 4) end)
Check("bars limit", #Bars:Get() == 4, tostring(#Bars:Get()))
Try("bars shrink", function() Bars:Set({ 1, 2 }) end)

local Ring = Try("ring", function()
	return Audio:Ring({ Label = "Load", Default = 0.4, Max = 1 })
end)
Ring:Set(0.9)
Check("ring set", math.abs(Ring:Get() - 0.9) < 1e-9)

Try("alert", function()
	return Audio:Alert({ Label = "Heads up", Text = "This is a warning.", Color = Kuik.Theme.Warn })
end)

local Tree = Try("tree", function()
	return Audio:Tree({
		Label = "Explorer",
		Nodes = {
			{ Label = "game", Open = true, Children = {
				{ Label = "Workspace", Children = { { Label = "Baseplate" } } },
				{ Label = "ReplicatedStorage" },
			} },
		},
	})
end)
Check("tree built", Tree ~= nil)

--------------------------------------------------------------------------
print("\nhud")
--------------------------------------------------------------------------

local Toast = Try("toast", function()
	return Kuik.Toast("The game cannot start until at least 5 players have joined.")
end)

Try("toast set", function() Toast:Set("2 players.") end)

Try("notify", function()
	return Kuik.Notify({ Title = "You've joined loll and kryptra", Duration = 1 })
end)

local Hints = Try("hints", function() return Kuik.Hints() end)
local Hint = Try("hint add", function() return Hints:Add("SHIFT", "Sprint") end)
Try("hint set", function() Hint:Set("CTRL", "Crouch") end)
Try("hint remove", function() Hint:Destroy() end)

local Log = Try("log", function() return Kuik.Log({ Limit = 3 }) end)

Try("log push", function()
	for Index = 1, 6 do
		Log:Push("Line " .. Index)
	end
end)

--- GetChildren includes the UIPadding and UIListLayout, so count lines only.
local function CountLines(Stack)
	local Total = 0

	for _, Child in Stack:GetChildren() do
		if Child.ClassName == "Frame" then
			Total += 1
		end
	end

	return Total
end

local LogStack = Log.Frame:FindFirstChild("Stack")
Check("log honours limit", LogStack and CountLines(LogStack) == 3,
	LogStack and tostring(CountLines(LogStack)) or "no stack")

Try("log clear", function() Log:Clear() end)

local Console = Try("console", function() return Kuik.Console() end)

Try("console levels", function()
	for _, Level in { "INFO", "SUCCESS", "WARN", "ERROR", "DEBUG", "NONSENSE" } do
		Console:Push(Level, "session v4715 -> v4716")
	end
end)

local Watermark = Try("watermark", function()
	return Kuik.Watermark({
		Tag = { Text = "PROTOTYPING", Color = Kuik.Theme.Danger },
		Fields = { "MAR_v11", "NR-260927-41AA61F5", "March 27, 2026", "Washington, United States" },
	})
end)

Try("watermark shrink", function()
	Watermark:Set({ "MAR_v11" })
end)

Try("watermark side", function() Watermark:SetSide("Right") end)

--------------------------------------------------------------------------
print("\nmedia")
--------------------------------------------------------------------------

Try("image", function()
	return Audio:Image({ Label = "Screenshot", Image = "rbxassetid://0", Caption = "A caption." })
end)

Try("image fit modes", function()
	for _, Fit in { "Contain", "Cover", "Stretch" } do
		Audio:Image({ Label = Fit, Image = "rbxassetid://0", Fit = Fit })
	end
end)

local Link = Try("link", function()
	return Audio:Link({ Label = "Devforum thread", Url = "https://devforum.roblox.com", Action = "Open" })
end)
Check("link default", Link:Get() == "https://devforum.roblox.com")
Link:Set("https://roblox.com")
Check("link set", Link:Get() == "https://roblox.com")

Try("paragraph with image", function()
	return Audio:Paragraph({ Label = "Diagram", Text = "With an embed.", Image = "rbxassetid://0" })
end)

--------------------------------------------------------------------------
print("\nwindows")
--------------------------------------------------------------------------

local Menu = Try("menu", function()
	return Kuik.Menu({
		Items = {
			{ Label = "Copy", Shortcut = "Ctrl+C" },
			{ Separator = true },
			{ Label = "Delete", Color = Kuik.Theme.Danger, Callback = function() Fired.Menu = true end },
		},
	})
end)

Check("menu starts closed", Menu:IsOpen() == false)
Try("menu show", function() Menu:Show(100, 100) end)
Check("menu open", Menu:IsOpen() == true)
Try("menu close", function() Menu:Close() end)
Check("menu closed", Menu:IsOpen() == false)

local Answer = nil

local Prompt = Try("prompt", function()
	return Kuik.Prompt({
		Title = "Reset preferences?",
		Text = "This cannot be undone.",
		Buttons = {
			{ Label = "Cancel", Value = "cancel" },
			{ Label = "Reset", Value = "reset", Primary = true },
		},
		Callback = function(Choice) Answer = Choice end,
	})
end)

Try("prompt close", function() Prompt:Close("reset") end)
Check("prompt answered", Answer == "reset", tostring(Answer))
Try("prompt double close is ignored", function() Prompt:Close("cancel") end)
Check("prompt answers once", Answer == "reset", tostring(Answer))

local Child = Try("child window", function()
	return Window:Child({ Title = "Detail", Subtitle = "Owned by its parent" })
end)
Check("child registered", #Window:Children() == 1)
Check("child is a window", Child ~= nil and Child.Root ~= nil and Child:IsOpen() == false)

local Deck = Try("cards deck", function()
	return Kuik.Cards({ Gap = 40 })
end)

local Second = Try("second window", function()
	return Kuik.Window({ Title = "Second" })
end)

Try("deck add", function()
	Deck:Add(Window)
	Deck:Add(Second)
end)

Check("deck counts", Deck:Count() == 2)
Deck:Focus(2)
local Index, Focused = Deck:Focused()
Check("deck focuses", Index == 2 and Focused == Second)
Deck:Next()
Check("deck clamps at the end", (Deck:Focused()) == 2)
Deck:Previous()
Check("deck steps back", (Deck:Focused()) == 1)
Try("deck destroy", function() Deck:Destroy() end)
Try("second window destroy", function() Second:Destroy() end)

--------------------------------------------------------------------------
print("\nteardown")
--------------------------------------------------------------------------

Try("parallax on", function() Window:SetParallax(6) end)
Try("parallax off", function() Window:SetParallax(0) end)
Try("control destroy", function() Toggle:Destroy() end)
Try("tabs destroy", function() Tabs:Destroy() end)
Try("window destroy", function() Window:Destroy() end)
Try("reset", function() Kuik.Reset() end)

--------------------------------------------------------------------------

print(string.format("\n%d checks, %d failures\n", Checks, Failures))

if Failures > 0 then
	Process.exit(1)
end
