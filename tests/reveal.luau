--!nonstrict
--[[
	The white layer, checked against numbers rather than against a screenshot.

	The shim has no layout engine, so absolutes are set by hand — which is fine,
	because everything in Reveal works from AbsolutePosition and AbsoluteSize and
	nothing in it cares how those got their values. Springs are stepped by hand.

	Run with:  lune run tests/reveal
]]

local Shim = require("./shim")
Shim.Install()

local Kuik = require("./Kuik")
local Reveal = Kuik.Reveal
local Motion = Kuik.Motion

local Failures = 0

local function Check(Name, Condition, Detail)
	if Condition then
		print(string.format("  ok    %s", Name))
	else
		Failures += 1
		print(string.format("  FAIL  %s%s", Name, Detail and (" - " .. Detail) or ""))
	end
end

local function Near(A, B, Slack)
	return math.abs(A - B) < (Slack or 0.5)
end

local function Place(Object, X, Y, Wide, Tall)
	Object.AbsolutePosition = Vector2.new(X, Y)
	Object.AbsoluteSize = Vector2.new(Wide, Tall)
end

--- Delays queue against a clock rather than firing on the spot, so the ORDER of
--- a choreography is testable: that the width finishes before the height starts,
--- that the plate is still there while the panel is still hidden.
Shim.Clocked = true

--- Runs time forward by whole frames at the rate the reference was shot.
local function Frame(Count)
	Shim.Advance((Count or 1) / 24, 24)
end

local Screen = Kuik.Screen()

print("\nreveal\n")

--------------------------------------------------------------------------
print("plate")
--------------------------------------------------------------------------

local Host = Kuik.New("Frame", { BackgroundTransparency = 1 })
Host.Parent = Screen
Place(Host, 0, 0, 800, 600)

local Panel = Kuik.New("CanvasGroup", { BackgroundTransparency = 0.1 })
Panel.Parent = Host
Panel.GroupTransparency = 1
Place(Panel, 200, 60, 393, 479)

--- A plate is parented to a loose ancestor, and a child's offset inside that
--- ancestor is measured from the inside of its padding. Before this was taken
--- off, every plate on a padded container drew one padding down and to the
--- right of the row it was standing in for.
do
	local Padded = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Padded.Parent = Screen
	Place(Padded, 0, 0, 800, 600)

	local Pad = Kuik.New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingTop  = UDim.new(0, 20),
	})
	Pad.Parent = Padded

	local Inside = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Inside.Parent = Padded
	Place(Inside, 112, 220, 396, 82)

	local Try = Reveal.Plate(Inside, { Parent = Padded, To = 0 })

	Check("A plate on a padded parent sits on the row, not one padding off it",
		Near(Try.Face.Position.X.Offset, 112 - 12 + 396 / 2)
			and Near(Try.Face.Position.Y.Offset, 220 - 20 + 82 / 2),
		string.format("%d,%d wanted %d,%d",
			Try.Face.Position.X.Offset, Try.Face.Position.Y.Offset,
			112 - 12 + 396 / 2, 220 - 20 + 82 / 2))

	Try.Cancel()
	Padded:Destroy()
end

local Run = Reveal.Plate(Panel, { Parent = Host, To = 0 })
local Face = Run.Face

Check("The plate is made", Face ~= nil and Face.Parent == Host)

Check("It is white", Face.BackgroundColor3 == Kuik.Theme.White)

Check("It is centred on what it stands in for",
	Near(Face.Position.X.Offset, 200 + 393 / 2) and Near(Face.Position.Y.Offset, 60 + 479 / 2),
	string.format("%d,%d", Face.Position.X.Offset, Face.Position.Y.Offset))

Check("What it stands in for is hidden while it stands in for it",
	Panel.GroupTransparency == 1)

--- The reference. Every row was measured off a frame of the source footage at
--- 24fps: the plate's width and height in pixels against a 393 x 479 panel, and
--- how white it is. This is the whole point of the module, so it is checked
--- frame against frame rather than "it ended up visible".
---
--- The tolerance is generous on purpose. The source is a compressed 24fps
--- capture measured by thresholding pixels, so a few percent is noise; what the
--- test is really holding is the SHAPE — that the width lands before the height
--- starts, that the plate is not opaque when it appears, and that the burn
--- overlaps the opening rather than following it.
local REFERENCE = {
	{ 221, 149, 0.60 },
	{ 349, 149, 0.89 },
	{ 391, 164, 0.96 },
	{ 393, 267, 0.91 },
	{ 393, 438, 0.73 },
	{ 393, 470, 0.60 },
	{ 393, 479, 0.48 },
	{ 393, 479, 0.41 },
	{ 393, 479, 0.20 },
	{ 393, 479, 0.08 },
	{ 393, 479, 0.00 },
}

local Worst, WorstAt = 0, 0
local Table_ = {}

for Index, Row in REFERENCE do
	local Wide = Face.Size.X.Offset
	local Tall = Face.Size.Y.Offset
	local White = 1 - Face.BackgroundTransparency

	local Off = math.max(
		math.abs(Wide - Row[1]) / 393,
		math.abs(Tall - Row[2]) / 479,
		math.abs(White - Row[3]))

	if Off > Worst then
		Worst, WorstAt = Off, Index
	end

	table.insert(Table_, string.format("  f%-2d  %4.0f x %-4.0f  %.2f   want %4d x %-4d %.2f   %4.1f%%",
		Index, Wide, Tall, White, Row[1], Row[2], Row[3], Off * 100))

	Frame(1)
end

Check("The plate follows the reference frame table", Worst < 0.2,
	string.format("worst %.0f%% at frame %d\n%s", Worst * 100, WorstAt, table.concat(Table_, "\n")))

--- The three things the frame table is really holding, stated on their own so a
--- failure says which of them broke.
Check("It appears already wide and already open, never as a dot", (function()
	local Fresh = Kuik.New("CanvasGroup", { BackgroundTransparency = 0 })
	Fresh.Parent = Host
	Fresh.GroupTransparency = 1
	Place(Fresh, 0, 0, 400, 400)

	local Try = Reveal.Plate(Fresh, { Parent = Host, To = 0 })
	local Wide = Try.Face.Size.X.Offset / 400
	local Tall = Try.Face.Size.Y.Offset / 400

	Try.Cancel()
	Fresh:Destroy()

	return Wide > 0.4 and Wide < 0.75 and Tall > 0.15 and Tall < 0.5
end)())

Check("It is not opaque on the frame it appears", (function()
	local Fresh = Kuik.New("CanvasGroup", { BackgroundTransparency = 0 })
	Fresh.Parent = Host
	Fresh.GroupTransparency = 1
	Place(Fresh, 0, 0, 400, 400)

	local Try = Reveal.Plate(Fresh, { Parent = Host, To = 0 })
	local White = 1 - Try.Face.BackgroundTransparency

	Try.Cancel()
	Fresh:Destroy()

	return White > 0.35 and White < 0.85
end)())

Frame(60)

Check("The white burns off", Face.BackgroundTransparency > 0.9,
	string.format("%.3f", Face.BackgroundTransparency))

Check("and the panel is left behind at the transparency it was asked for",
	Near(Panel.GroupTransparency, 0, 0.05), tostring(Panel.GroupTransparency))

--------------------------------------------------------------------------
print("\nplate, coming from somewhere")
--------------------------------------------------------------------------

--- The third reference sample shows the seed bar starting about 37px off the
--- panel's centre and drifting onto it. That is the "it came from the thing you
--- clicked" half of the effect.
local Source = Kuik.New("Frame", { BackgroundTransparency = 1 })
Source.Parent = Host
Place(Source, 0, 500, 40, 20)

local Travelled = Kuik.New("CanvasGroup", { BackgroundTransparency = 0 })
Travelled.Parent = Host
Travelled.GroupTransparency = 1
Place(Travelled, 400, 100, 300, 300)

local Journey = Reveal.Plate(Travelled, { Parent = Host, To = 0, From = Source, Drift = 48 })

local StartX = Journey.Face.Position.X.Offset
local StartY = Journey.Face.Position.Y.Offset

Check("It starts off the middle, toward where it came from",
	StartX < 550 and StartY > 250,
	string.format("%d,%d", StartX, StartY))

Check("but never further off than it was allowed", (function()
	local AwayX = StartX - 550
	local AwayY = StartY - 250
	return math.sqrt(AwayX * AwayX + AwayY * AwayY) <= 48.5
end)(), string.format("%d,%d", StartX, StartY))

Frame(20)

Check("and it arrives on the middle",
	Near(Journey.Face.Position.X.Offset, 550, 3) and Near(Journey.Face.Position.Y.Offset, 250, 3),
	string.format("%d,%d", Journey.Face.Position.X.Offset, Journey.Face.Position.Y.Offset))

Journey.Cancel()

Check("A plate told to come from far away still only drifts", (function()
	local Far = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Far.Parent = Host
	Place(Far, 5000, 5000, 10, 10)

	local Panel_ = Kuik.New("CanvasGroup", { BackgroundTransparency = 0 })
	Panel_.Parent = Host
	Panel_.GroupTransparency = 1
	Place(Panel_, 0, 0, 200, 200)

	local Try = Reveal.Plate(Panel_, { Parent = Host, To = 0, From = Far })
	local AwayX = Try.Face.Position.X.Offset - 100
	local AwayY = Try.Face.Position.Y.Offset - 100
	local Away = math.sqrt(AwayX * AwayX + AwayY * AwayY)

	Try.Cancel()
	Panel_:Destroy()
	Far:Destroy()

	return Away <= 49
end)())

--------------------------------------------------------------------------
print("\nplate, past a layout")
--------------------------------------------------------------------------

--- The bug this guards: a row asked to reveal itself put its plate straight
--- into the column it lives in, where the layout treated it as another row —
--- so the reveal never appeared and the column grew a gap instead.
Check("A plate climbs past a laid out parent", (function()
	local Column = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Column.Parent = Host
	Kuik.Util.List(6).Parent = Column
	Place(Column, 0, 0, 300, 400)

	local Row = Kuik.New("Frame", { BackgroundTransparency = 0.4 })
	Row.Parent = Column
	Place(Row, 0, 0, 300, 40)

	local Try = Reveal.Plate(Row, { Fade = false })
	local Landed = Try.Face and Try.Face.Parent

	Try.Cancel()
	Column:Destroy()

	return Landed ~= nil and Landed ~= Column, Landed and Landed.Name or "nowhere"
end)())

Check("and so does a wipe", (function()
	local Column = Kuik.New("Frame", { BackgroundTransparency = 1 })
	Column.Parent = Host
	Kuik.Util.List(6).Parent = Column
	Place(Column, 0, 0, 300, 400)

	local Line = Kuik.New("TextLabel", { BackgroundTransparency = 1, TextTransparency = 0.2 })
	Line.Parent = Column
	Place(Line, 0, 0, 300, 24)

	local Try = Reveal.Wipe(Line)
	local Landed = Try.Face and Try.Face.Parent

	Try.Cancel()
	Column:Destroy()

	return Landed ~= nil and Landed ~= Column, Landed and Landed.Name or "nowhere"
end)())

--------------------------------------------------------------------------
print("\nplate, before there is anything to measure")
--------------------------------------------------------------------------

--- The bug this guards: a row built this frame has not been laid out, so it has
--- no size, so the plate refused it — and revealing a row you had just added
--- did nothing at all, silently. It waits for a size now.
Check("A plate waits for a size rather than giving up", (function()
	local Late = Kuik.New("Frame", { BackgroundTransparency = 0.4 })
	Late.Parent = Host
	Place(Late, 0, 0, 0, 0)

	local Run = Reveal.Plate(Late, { Fade = false })

	if Run.Face ~= nil then
		return false, "it should have nothing to show yet"
	end

	--- Roblox lays it out a moment later.
	Place(Late, 10, 10, 300, 80)
	Frame(2)

	local Landed = Run.Face ~= nil and Run.Face.Parent ~= nil

	Run.Cancel()
	Late:Destroy()

	return Landed, "no plate after it was measured"
end)())

Check("and so does a wipe", (function()
	local Late = Kuik.New("TextLabel", { BackgroundTransparency = 1, TextTransparency = 0.2 })
	Late.Parent = Host
	Place(Late, 0, 0, 0, 0)

	local Run = Reveal.Wipe(Late)

	Place(Late, 10, 10, 300, 24)
	Frame(2)

	local Landed = Run.Face ~= nil

	Run.Cancel()
	Late:Destroy()

	return Landed
end)())

Check("A caller that needs an answer now still gets one", (function()
	local Late = Kuik.New("Frame", { BackgroundTransparency = 0.4 })
	Late.Parent = Host
	Place(Late, 0, 0, 0, 0)

	local Run = Reveal.Plate(Late, { Now = true, Fade = false })
	local Refused = Run.Face == nil

	Late:Destroy()

	return Refused
end)())

--------------------------------------------------------------------------
print("\nplate, refusing")
--------------------------------------------------------------------------

local Unmeasured = Kuik.New("Frame", { BackgroundTransparency = 0 })
Unmeasured.Parent = Host
Place(Unmeasured, 0, 0, 0, 0)

Check("A plate over something with no size does nothing", (function()
	local Try = Reveal.Plate(Unmeasured, { Parent = Host })
	return Try.Face == nil
end)())

Check("A plate over something with no parent does nothing", (function()
	local Orphan = Kuik.New("Frame", {})
	local Try = Reveal.Plate(Orphan, {})
	return Try.Face == nil
end)())

--------------------------------------------------------------------------
print("\nplate, cancelled")
--------------------------------------------------------------------------

local Second = Kuik.New("CanvasGroup", { BackgroundTransparency = 0.1 })
Second.Parent = Host
Place(Second, 10, 10, 200, 100)

local Cancelled = Reveal.Plate(Second, { Parent = Host, To = 0 })
local CancelledFace = Cancelled.Face

Cancelled.Cancel()

Check("Cancelling takes the plate away", CancelledFace.Parent == nil)

--------------------------------------------------------------------------
print("\nfollow")
--------------------------------------------------------------------------

local Mark = Kuik.New("Frame", { BackgroundTransparency = 0 })
Mark.Parent = Host
Place(Mark, 40, 500, 90, 30)

local Ghost = Reveal.Follow(Mark, { Parent = Host, Span = 60, Reach = 0.6 })

Ghost.Wake()
Frame(2)

Check("A ghost that has nothing to chase is invisible",
	Ghost.Face.BackgroundTransparency > 0.99,
	string.format("%.3f", Ghost.Face.BackgroundTransparency))

--- The highlight jumps to another tab. The ghost must not be there yet.
Place(Mark, 400, 500, 90, 30)
Ghost.Wake()
Frame(1)

Check("The ghost is behind after a jump", Ghost.Face.BackgroundTransparency < 0.9,
	string.format("%.3f", Ghost.Face.BackgroundTransparency))

Check("and it is stretched across the gap it has not covered yet",
	Ghost.Face.Size.X.Offset > 90 * 1.5,
	tostring(Ghost.Face.Size.X.Offset))

Check("and it never runs ahead of the thing it follows",
	Ghost.Face.Position.X.Offset <= 400 + 45 + 1,
	tostring(Ghost.Face.Position.X.Offset))

Frame(120)

Check("It catches up and disappears", Ghost.Face.BackgroundTransparency > 0.99,
	string.format("%.3f", Ghost.Face.BackgroundTransparency))

Check("and it lets go of the frame loop once it has", (function()
	--- Stepping with nothing to chase must not bring it back.
	Frame(4)
	return Ghost.Face.BackgroundTransparency > 0.99
end)())

Ghost:Destroy()

Check("Destroying it takes the ghost away", Ghost.Face.Parent == nil)

--------------------------------------------------------------------------
print("\nafterimage")
--------------------------------------------------------------------------

local Moving = Kuik.New("Frame", { BackgroundTransparency = 0 })
Moving.Parent = Host
Place(Moving, 100, 200, 60, 20)

local Stamp = Reveal.Ghost(Moving, { Parent = Host })

Check("An afterimage is stamped where the thing was",
	Stamp ~= nil and Near(Stamp.Position.X.Offset, 130) and Near(Stamp.Position.Y.Offset, 210),
	Stamp and tostring(Stamp.Position) or "none")

Check("It starts partly there", Stamp.BackgroundTransparency < 0.9)

Frame(100)

Check("and fades to nothing", Stamp.BackgroundTransparency > 0.98,
	string.format("%.3f", Stamp.BackgroundTransparency))

Check("An afterimage of something with no size is not stamped",
	Reveal.Ghost(Unmeasured, { Parent = Host }) == nil)

--------------------------------------------------------------------------
print("\nwipe")
--------------------------------------------------------------------------

local Line = Kuik.New("TextLabel", { BackgroundTransparency = 1, TextTransparency = 0.2 })
Line.Parent = Host
Place(Line, 0, 300, 400, 24)

local Sweep = Reveal.Wipe(Line, { Parent = Host })

Check("The wipe bar is made and is narrow", Sweep.Face ~= nil
	and Sweep.Face.Size.X.Offset < 400 / 2, tostring(Sweep.Face.Size))

Check("The text is hidden behind it", Line.TextTransparency == 1)

Frame(120)

Check("The text is left behind, at what it was",
	Near(Line.TextTransparency, 0.2, 0.02), tostring(Line.TextTransparency))

Check("and the bar goes", Sweep.Face.Parent == nil
	or Sweep.Face.BackgroundTransparency > 0.98)

local Second_ = Kuik.New("TextLabel", { BackgroundTransparency = 1, TextTransparency = 0.3 })
Second_.Parent = Host
Place(Second_, 0, 340, 400, 24)

local Aborted = Reveal.Wipe(Second_, { Parent = Host })
Aborted.Cancel()

Check("Cancelling a wipe puts the text back", Near(Second_.TextTransparency, 0.3, 0.001),
	tostring(Second_.TextTransparency))

Check("and takes the bar away", Aborted.Face.Parent == nil)

--------------------------------------------------------------------------
print("\nflash")
--------------------------------------------------------------------------

local Blink = Reveal.Flash({ Peak = 0.8 })

Check("The flash covers everything",
	Blink.Size.X.Scale == 1 and Blink.Size.Y.Scale == 1)

Check("It starts at the peak it was asked for",
	Near(Blink.BackgroundTransparency, 0.2, 0.001),
	tostring(Blink.BackgroundTransparency))

Frame(100)

Check("and decays to nothing", Blink.BackgroundTransparency > 0.98,
	string.format("%.3f", Blink.BackgroundTransparency))

--- The reference holds the flash solid for five frames at 30fps before it lets
--- go. Without the hold there is nothing to hide a cut behind.
local Covered = false
local Held = Reveal.Flash({ Peak = 1, Hold = 0.17, Covered = function() Covered = true end })

Frame(2)

Check("A held flash is still solid part way through the hold",
	Held.BackgroundTransparency < 0.02 and not Covered,
	string.format("%.3f", Held.BackgroundTransparency))

Frame(4)

Check("and it does the covered work at the top of the hold", Covered)

Frame(60)

Check("and only then decays", Held.BackgroundTransparency > 0.98,
	string.format("%.3f", Held.BackgroundTransparency))

--------------------------------------------------------------------------
print("\nwindows and tabs")
--------------------------------------------------------------------------

local Window = Kuik.Window({ Title = "Revealed", Reveal = true })

Check("A window can be asked to arrive as a plate", Window ~= nil)

--- On by default for a panel, off for a HUD element, and off for anything that
--- says so — because a health bar that flashes white every time it appears is
--- ridiculous, and a settings panel that does is the whole point.
Check("A panel reveals by default", (function()
	local Default = Kuik.Window({ Title = "Default" })
	local Wants = Default.Options.Reveal

	Default:Destroy()

	return Wants == nil and Kuik.Metrics.Reveal == true
end)())

Check("A bare panel does not", (function()
	local Hud = Kuik.Panel({ Width = 200, Height = 60 })

	Hud.Root.AbsoluteSize = Vector2.new(200, 60)
	Hud.Root.AbsolutePosition = Vector2.new(0, 0)
	Hud.Canvas.AbsoluteSize = Vector2.new(200, 60)
	Hud.Canvas.AbsolutePosition = Vector2.new(0, 0)

	Hud:Open()

	local Plated = Hud.Root:FindFirstChild("Reveal") ~= nil

	Hud:Destroy()

	return not Plated
end)())

Check("and Reveal = false turns it off on a panel too", (function()
	local Plain = Kuik.Window({ Title = "Plain", Reveal = false })

	Plain.Root.AbsoluteSize = Vector2.new(460, 500)
	Plain.Root.AbsolutePosition = Vector2.new(0, 0)
	Plain.Canvas.AbsoluteSize = Vector2.new(460, 500)
	Plain.Canvas.AbsolutePosition = Vector2.new(0, 0)

	Plain:Open()

	local Plated = Plain.Root:FindFirstChild("Reveal") ~= nil

	Shim.Advance(0.6, 24)

	local Shown = Plain.Canvas.GroupTransparency < 0.5

	Plain:Destroy()

	return not Plated and Shown
end)())

Window.Root.AbsoluteSize = Vector2.new(460, 500)
Window.Root.AbsolutePosition = Vector2.new(0, 0)
Window.Canvas.AbsoluteSize = Vector2.new(460, 500)
Window.Canvas.AbsolutePosition = Vector2.new(0, 0)

Window:Open()

Check("Opening it makes a plate over the window",
	Window.Root:FindFirstChild("Reveal") ~= nil)

Frame(200)

Check("and the window is left visible", Near(Window.Canvas.GroupTransparency, 0, 0.02),
	tostring(Window.Canvas.GroupTransparency))

local Bar = Window:Tabs()
Bar:Page("One")
Bar:Page("Two")

Check("A tab bar carries a smear", (function()
	for _, Child in Bar.Viewport:GetChildren() do
		if Child.Name == "Ghost" then
			return true
		end
	end

	return false
end)())

Bar:Destroy()

Check("and drops it when the bar goes", (function()
	for _, Child in Bar.Viewport:GetChildren() do
		if Child.Name == "Ghost" then
			return false
		end
	end

	return true
end)())

--- The other half of the gesture: a window that arrived under a plate leaves
--- under one, so pressing the close button is not a different interface to
--- opening it.
Check("A window that arrived as a plate leaves under one", (function()
	local Leaves = Kuik.Window({ Title = "Both ways", Reveal = true })

	Leaves.Root.AbsoluteSize = Vector2.new(400, 300)
	Leaves.Root.AbsolutePosition = Vector2.new(0, 0)
	Leaves.Canvas.AbsoluteSize = Vector2.new(400, 300)
	Leaves.Canvas.AbsolutePosition = Vector2.new(0, 0)

	Leaves:Open()
	Shim.Advance(0.02, 24)

	local Arrived = Leaves.Root:FindFirstChild("Reveal") ~= nil

	Shim.Advance(1.2, 24)
	Leaves:Close()
	Shim.Advance(0.05, 24)

	local Covered = Leaves.Root:FindFirstChild("Covering") ~= nil

	Leaves:Destroy()

	return Arrived and Covered,
		string.format("arrived %s, covered %s", tostring(Arrived), tostring(Covered))
end)())

Check("and one that faded in fades back out", (function()
	local Quiet = Kuik.Window({ Title = "Quiet", Reveal = false })

	Quiet.Root.AbsoluteSize = Vector2.new(400, 300)
	Quiet.Canvas.AbsoluteSize = Vector2.new(400, 300)

	Quiet:Open()
	Shim.Advance(0.6, 24)
	Quiet:Close()
	Shim.Advance(0.05, 24)

	local Covered = Quiet.Root:FindFirstChild("Covering") ~= nil

	Quiet:Destroy()

	return not Covered
end)())

--- Every overlay that can arrive as a plate, checked that it does.
--- A card opens the way any other window does, but the deck deals them rather
--- than firing every plate on the same frame.
Check("A deck opens its cards one after another, not all at once", (function()
	local Deck = Kuik.Cards({ Gap = 60, Stagger = 0.05 })
	local Cards = {}

	for Index = 1, 5 do
		Cards[Index] = Kuik.Window({ Title = "Card " .. Index, Variant = "Card" })
		Deck:Add(Cards[Index])
	end

	--- The first is opened on the spot; the rest are still waiting their turn.
	local Open = 0

	for _, Card in Cards do
		if Card:IsOpen() then
			Open += 1
		end
	end

	local Dealt = Open

	Shim.Advance(1, 60)

	local Everyone = 0

	for _, Card in Cards do
		if Card:IsOpen() then
			Everyone += 1
		end
	end

	Deck:Destroy()

	return Dealt == 1 and Everyone == 5,
		string.format("%d opened at once, %d in the end", Dealt, Everyone)
end)())

Check("A menu can arrive as a plate", (function()
	local Menu = Kuik.Menu({ Items = { "One", "Two" }, Reveal = true })
	Menu:Show(100, 100)

	local Found = false

	for _, Child in Menu.Frame:GetChildren() do
		if Child.Name == "Reveal" then
			Found = true
		end
	end

	Menu:Destroy()

	return Found
end)())

--- The bug this guards: when a plate refuses something it cannot measure — and
--- headlessly it refuses everything, because nothing is ever laid out — the
--- caller has to fall back to a plain fade. Without that, a prompt asked to
--- arrive as a plate never appears at all.
Check("A prompt asked for a plate still appears when the plate refuses", (function()
	local Asked = Kuik.Prompt({ Title = "Sure?", Reveal = true, Actions = {} })

	Shim.Advance(0.5, 24)

	local Shown = false

	for _, Item in Kuik.Screen():GetDescendants() do
		if Item:IsA("CanvasGroup") and Item.GroupTransparency < 0.5 then
			Shown = true
		end
	end

	if Asked and Asked.Destroy then
		Asked:Destroy()
	end

	return Shown
end)())

Check("A window asked for a plate still opens when the plate refuses", (function()
	local Fresh = Kuik.Window({ Title = "Refused", Reveal = true })
	Fresh:Open()

	Shim.Advance(0.5, 24)

	local Shown = Fresh.Canvas.GroupTransparency < 0.5

	Fresh:Destroy()

	return Shown
end)())

Window:Destroy()

print(string.format("\n%s\n", Failures == 0 and "no failures" or (Failures .. " failures")))

if Failures > 0 then
	process.exit(1)
end
