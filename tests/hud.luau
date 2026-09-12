--!nonstrict
--[[
	The two HUD pieces taken from the user's own screenshots: the bracketed chat
	and the centred feed.

	Run with:  lune run tests/hud
]]

local Shim = require("./shim")
Shim.Install()

local Kuik = require("./Kuik")

--- Delays queue against a clock rather than firing on the spot. Without it a
--- gesture that cleans itself up after a wait is torn down before a single
--- spring has been stepped, and nothing here would ever be seen to move.
Shim.Clocked = true

local function Advance(Seconds)
	Shim.Advance(Seconds or 1, 60)
end

local Failures = 0

local function Check(Name, Condition, Detail)
	if Condition then
		print(string.format("  ok    %s", Name))
	else
		Failures += 1
		print(string.format("  FAIL  %s%s", Name, Detail and (" - " .. Detail) or ""))
	end
end

local function Count(Node, Predicate)
	local Total = 0

	for _, Child in Node:GetDescendants() do
		if Predicate(Child) then
			Total += 1
		end
	end

	return Total
end

print("\nhud\n")

--------------------------------------------------------------------------
print("\nfeed")
--------------------------------------------------------------------------

local Feed = Kuik.Feed({ Limit = 3, Life = 0 })

Check("A feed is built", Feed ~= nil and Feed.Frame ~= nil)

Check("It is centred rather than aligned to a margin",
	Feed.Frame.AnchorPoint.X == 0.5)

local First = Feed:Push("You've earned: 7,000 Kions")
Check("A notice lands", First ~= nil and First.Text:match("7,000") ~= nil)

--- The label sits in a Line inside the Notice; the hairline is the Notice's,
--- so that it can overrun the text without pushing it about.
local function Notice(Label)
	return Label.Parent.Parent
end

Check("and it wears a hairline", Notice(First):FindFirstChild("Wire") ~= nil)

local Second = Feed:Push("After Tax: 5,250 Kions")

Check("Only the newest wears it at length", (function()
	Advance(1)

	local Old = Notice(First):FindFirstChild("Wire")
	local New_ = Notice(Second):FindFirstChild("Wire")

	return Old.Size.X.Offset < 1 and New_.Size.X.Offset > 1,
		string.format("old %d new %d", Old.Size.X.Offset, New_.Size.X.Offset)
end)())

Check("The newest is at the bottom of the stack",
	Notice(Second).LayoutOrder > Notice(First).LayoutOrder)

--- The bug this guards: the hairline was a child of the row's own layout, so
--- every notice grew by the width of its own hairline and the column drifted
--- wider with each one. The row is now sized from its contents, never from the
--- decoration that overruns them.
Check("A notice is as wide as its contents, not as wide as its hairline", (function()
	local Row = Notice(Second)
	local Line = Row:FindFirstChild("Line")
	local Wire = Row:FindFirstChild("Wire")

	--- Headlessly nothing is measured, so this checks the structure that makes
	--- the bug impossible rather than the pixels: the hairline is not a sibling
	--- of the label inside the laid out line.
	return Line ~= nil and Wire ~= nil and Wire.Parent ~= Line
		and Line:FindFirstChildOfClass("UIListLayout") ~= nil
		and Row:FindFirstChildOfClass("UIListLayout") == nil
end)())

Feed:Push("three")
Feed:Push("four")

Check("It keeps only as many as it was told to", (function()
	local Rows = Count(Feed.Frame, function(Item) return Item.Name == "Notice" end)
	return Rows <= 5, tostring(Rows)
end)())

Feed:Clear()
Check("Clearing empties it",
	Count(Feed.Frame, function(Item) return Item.Name == "Notice" end) == 0)

Feed:Destroy()
Check("Destroying takes it off screen", Feed.Frame.Parent == nil)

--------------------------------------------------------------------------
print("\narrival")
--------------------------------------------------------------------------

--- The reference was measured on a 1920 x 1080 screen, so give the shim one.
Kuik.Screen().AbsoluteSize = Vector2.new(1920, 1080)

local Arrival = Kuik.Arrival({
	Title = "You're arriving at \"West Haven Offices\"",
	Subtitle = "Loading the level and everything in it",
	Status = "Loaded West Haven Offices",
	Footer = { "a line of fine print", "and another" },
})

Check("An arrival screen is built", Arrival ~= nil and Arrival.Frame ~= nil)

Check("It covers everything", Arrival.Frame.Size.X.Scale == 1
	and Arrival.Frame.Size.Y.Scale == 1)

Check("and it cannot be clicked through",
	Arrival.Frame:FindFirstChild("Block") ~= nil)

Check("The status chip is bracketed by two rules", (function()
	local Chip = Arrival.Frame:FindFirstChild("Status")
	local Rules = 0

	for _, Child in Chip:GetChildren() do
		if Child.Name == "Rule" then
			Rules += 1
		end
	end

	return Rules == 2
end)())

--- The measured layout: the chip near the top, the title dead centre. Both are
--- positioned in offset rather than in scale, because the sheet ignores the
--- top bar inset and these two have to put it back.
Check("The chip sits near the top and the title in the middle", (function()
	local Chip = Arrival.Frame:FindFirstChild("Status")
	local Middle = Arrival.Frame:FindFirstChild("Middle")

	--- The layer is the size of the viewport and sits one inset above it, so a
	--- fraction of what the player sees is inset + viewport * fraction, counted
	--- from the layer's own top. Both of these are placed that way; the title is
	--- then lifted by half its own height, so the reading below allows for that.
	local Inset = 36

	return math.abs(Chip.Position.Y.Offset - (Inset + 1080 * 0.094)) < 2
		and math.abs(Middle.Position.Y.Offset - (Inset + 1080 * 0.5)) < 30
		and Middle.Position.Y.Scale == 0,
		string.format("chip %d, title %d", Chip.Position.Y.Offset, Middle.Position.Y.Offset)
end)())

--- The bug this guards: the safe area was computed as the screen height minus
--- the inset, which on a screen that has not been measured yet is negative —
--- and everything landed above the top of the screen instead of below the bar.
Check("An unmeasured screen never puts anything above the top", (function()
	local Was = Kuik.Screen().AbsoluteSize

	Kuik.Screen().AbsoluteSize = Vector2.new(0, 0)

	local Blind = Kuik.Arrival({ Title = "No size yet", Reveal = false, Progress = false })
	local Chip = Blind.Frame:FindFirstChild("Status")
	local Above = Chip.Position.Y.Offset < 0

	Blind:Destroy()
	Kuik.Screen().AbsoluteSize = Was

	return not Above, tostring(Chip.Position.Y.Offset)
end)())

Arrival:SetProgress(0.4, false)

Check("Progress fills the hairline", (function()
	local Fill = Arrival.Track and Arrival.Track:FindFirstChild("Fill")
	return Fill ~= nil and math.abs(Fill.Size.X.Scale - 0.4) < 0.001
end)())

Arrival:SetStatus("Placing you")
Arrival:SetTitle("Almost there", "hold on")
Advance(0.4)

Check("The status can be changed", Arrival.Status.Text == "Placing you",
	Arrival.Status.Text)

Check("and so can the title", Arrival.Title.Text == "Almost there"
	and Arrival.Subtitle.Text == "hold on", Arrival.Title.Text)

local Went = false
Arrival:Done(function() Went = true end)

Advance(1.5)

Check("Done takes it off screen and calls back",
	Arrival.Frame.Parent == nil and Went)

--- With the reveal off, the chip is simply there: nothing is hidden and no bar
--- is made to uncover it.
Check("An arrival screen can refuse the reveal", (function()
	local Plain = Kuik.Arrival({ Title = "No ceremony", Reveal = false, Progress = false })

	Advance(0.3)

	local Bare = Plain.Status.TextTransparency == 0
	local Uncovered = Plain.Frame:FindFirstChild("Closing") == nil
	local Reading = string.format("%.2f, bar %s", Plain.Status.TextTransparency,
		Uncovered and "none" or "made")

	Plain:Destroy()

	return Bare and Uncovered, Reading
end)())

--------------------------------------------------------------------------
print("\nclosing")
--------------------------------------------------------------------------

local Host = Kuik.New("Frame", { BackgroundTransparency = 1 })
Host.Parent = Kuik.Screen()
Host.AbsolutePosition = Vector2.new(0, 0)
Host.AbsoluteSize = Vector2.new(1920, 1080)

local Shutter = Kuik.Close(nil, {
	Parent = Host,
	Rect = { 852, 88, 215, 26 },
})

Check("A closing bar is made and starts at least as wide as what it covers",
	Shutter.Face ~= nil and Shutter.Face.Size.X.Offset >= 215,
	Shutter.Face and tostring(Shutter.Face.Size.X.Offset) or "none")

Check("and it keeps its height while it closes",
	Shutter.Face.Size.Y.Offset == 26)

Advance(1.5)

--- Under a pixel and a half, and then gone. It is taken away a moment before
--- the spring has finished the last fraction of a pixel, which is invisible and
--- is the point at which there is nothing left to watch.
Check("It closes to nothing and is taken away",
	Shutter.Face.Size.X.Offset < 3 and Shutter.Face.Parent == nil,
	string.format("%.2f px, parent %s", Shutter.Face.Size.X.Offset,
		tostring(Shutter.Face.Parent)))

Check("A closing bar over nothing measurable does nothing",
	Kuik.Close(nil, { Parent = Host, Rect = { 0, 0, 0, 0 } }).Face == nil)

--------------------------------------------------------------------------
print("\nhints")
--------------------------------------------------------------------------

local Hints = Kuik.Hints()

Check("A hint can be a key and an action", (function()
	local One = Hints:Add("E", "interact")
	return One.Badge ~= nil and One.Label.Text == "interact"
end)())

Check("A hint can be a chord", (function()
	local Chord = Hints:Add({ Keys = { "Ctrl", "S" }, Action = "save" })
	local Caps = 0

	for _, Child in Chord.Badge:GetChildren() do
		if Child.Name == "Cap" then
			Caps += 1
		end
	end

	return Caps == 2, tostring(Caps) .. " caps"
end)())

Check("A hint can be a mouse button", (function()
	local Click = Hints:Add({ Mouse = "Left", Action = "fire" })
	return Click.Badge ~= nil and Click.Badge.Name == "Mouse"
		and Click.Badge:FindFirstChild("Button") ~= nil
end)())

Check("A hint can be an icon", (function()
	local Picture = Hints:Add({ Icon = 1, Action = "equip" })
	return Picture.Badge ~= nil and Picture.Badge:IsA("ImageLabel")
end)())

Check("A hint can be no badge at all, just a line", (function()
	local Plain = Hints:Add({ Action = "the door is locked" })
	return Plain.Badge == nil and Plain.Label.Text == "the door is locked"
end)())

Check("A hold hint fills as it is held", (function()
	local Hold = Hints:Add({ Hold = "E", Action = "pick up" })

	Hold:SetProgress(0.5, false)

	return Hold.Fill ~= nil and math.abs(Hold.Fill.Size.X.Scale - 0.5) < 0.001
end)())

Check("A hint can change from a key into a mouse button", (function()
	local Shifting = Hints:Add("Q", "lean")

	Shifting:Set({ Mouse = "Right", Action = "aim" })
	Advance(0.4)

	return Shifting.Badge.Name == "Mouse" and Shifting.Label.Text == "aim"
end)())

Check("The whole rail can be replaced in one call", (function()
	Hints:Set({
		{ Key = "F", Action = "open" },
		{ Action = "it is locked" },
	})

	return Hints:Count() == 2, tostring(Hints:Count())
end)())

Check("The rail can sit on the left instead", (function()
	local Left = Kuik.Hints({ Side = "Left" })
	local Anchored = Left.Frame.AnchorPoint.X == 0
	Left:Destroy()
	return Anchored
end)())

Hints:Destroy()

--------------------------------------------------------------------------
print("\ntoasts")
--------------------------------------------------------------------------

--- The bug this guards: every toast was parented straight to the layer at the
--- same fixed Y, so a second one landed exactly on top of the first.
Check("Toasts stack in one column rather than on each other", (function()
	local One = Kuik.Toast("first")
	local Two = Kuik.Toast("second")
	local Three = Kuik.Toast("third")

	local Stack = One.Frame.Parent
	local Shared = Two.Frame.Parent == Stack and Three.Frame.Parent == Stack
	local Laid = Stack:FindFirstChildOfClass("UIListLayout") ~= nil

	One:Destroy()
	Two:Destroy()
	Three:Destroy()

	return Shared and Laid, Stack.Name
end)())

Check("and one given its own parent is still placed by hand", (function()
	local Somewhere = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Somewhere.Parent = Kuik.Screen()

	local Loose = Kuik.Toast("mine", { Parent = Somewhere, Y = 120 })
	local Placed = Loose.Frame.Position.Y.Offset == 120
		and Loose.Frame.AnchorPoint.X == 0.5

	Loose:Destroy()
	Somewhere:Destroy()

	return Placed
end)())

--------------------------------------------------------------------------
print("\nclearing the top bar")
--------------------------------------------------------------------------

--- The bug this guards: everything anchored to the top of the screen counted
--- from the layer's top, and the layer starts one inset ABOVE the visible
--- screen. Measured in a live client, the compass was drawing at y = -36 on a
--- 619 tall viewport: entirely off screen, which is why nobody could see it.
Check("Nothing anchored to the top starts above the screen", (function()
	Kuik.Screen().AbsoluteSize = Vector2.new(1920, 1080)

	local Pieces = {
		compass   = Kuik.Compass(),
		objective = Kuik.Objective({ Label = "OBJECTIVE", Text = "do it", Progress = 0.3 }),
		console   = Kuik.Console(),
		finder    = Kuik.Viewfinder(),
	}

	local Inset = 36
	local Bad = {}

	for Name, Piece in Pieces do
		local Top = Piece.Frame.Position.Y.Offset

		if Top < Inset then
			table.insert(Bad, string.format("%s at %d", Name, Top))
		end
	end

	for _, Piece in Pieces do
		Piece:Destroy()
	end

	return #Bad == 0, table.concat(Bad, ", ")
end)())

--------------------------------------------------------------------------
print("\ncovering the screen")
--------------------------------------------------------------------------

--- The bug this guards, measured in a live client: with IgnoreGuiInset, Roblox
--- moves the layer up by the inset and leaves its size alone. Against a
--- 1532 x 619 viewport with a 58 px bar the layer reported position (0, -58)
--- and size 1532 x 619 — so a child sized (1, 0, 1, 0) covers the bar at the
--- top and leaves exactly one inset UNCOVERED along the bottom. Every full
--- bleed thing in the library has to be a bar taller than it looks.
Check("Cover makes something taller than the layer by the inset", (function()
	local Box = Kuik.New("Frame", { BackgroundTransparency = 0 })
	Box.Parent = Kuik.Screen()

	Kuik.Cover(Box)

	return Box.Size.X.Scale == 1 and Box.Size.Y.Scale == 1
		and Box.Size.Y.Offset == 36 and Box.Position.Y.Offset == 0,
		tostring(Box.Size.Y.Offset)
end)())

Check("Everything full bleed uses it", (function()
	local Flash = Kuik.Flash({ Peak = 0.5 })
	local Vignette = Kuik.Vignette({ Strength = 0.3 })
	local Sheet = Kuik.Arrival({ Title = "covered", Reveal = false, Progress = false })

	local Covered = Flash.Size.Y.Offset == 36
		and Vignette.Frame.Size.Y.Offset == 36
		and Sheet.Frame.Size.Y.Offset == 36

	local Reading = string.format("flash %d, vignette %d, arrival %d",
		Flash.Size.Y.Offset, Vignette.Frame.Size.Y.Offset, Sheet.Frame.Size.Y.Offset)

	Flash:Destroy()
	Vignette:Destroy()
	Sheet:Destroy()

	return Covered, Reading
end)())

print(string.format("\n%s\n", Failures == 0 and "no failures" or (Failures .. " failures")))

if Failures > 0 then
	process.exit(1)
end
