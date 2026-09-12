--!nonstrict
--[[
	The animation surface: the helpers that make things arrive, leave, scale,
	fade and repaint. Springs are stepped by hand through the shim, so these
	are real settle checks rather than "it did not throw".

	Run with:  lune run tests/motion
]]

local Shim = require("./shim")
Shim.Install()

local Kuik = require("./Kuik")
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
	return math.abs(A - B) < (Slack or 0.01)
end

--- The shim runs defer and delay eagerly and task.wait yields forever, so a
--- test can only ever check where a spring lands, never how long it took. Any
--- check below that would need real time is written as a check on the value
--- instead, and says so.
local function Settle(Steps)
	Shim.Step(Steps or 600)
end

print("\nmotion\n")

--------------------------------------------------------------------------
print("roles")
--------------------------------------------------------------------------

Check("Every role but instant is a spring", (function()
	for Name, Spec in Kuik.Theme.Motion do
		if Name ~= "instant" and not Spec.Stiffness then
			return false
		end
	end

	return true
end)())

Check("A spring role has a settle time under a second", (function()
	for _, Spec in Kuik.Theme.Motion do
		if Spec.Stiffness and Kuik.Motion.MotionTime(Spec) > 1 then
			return false
		end
	end

	return true
end)())

--------------------------------------------------------------------------
print("\nscale")
--------------------------------------------------------------------------

local Screen = Kuik.Screen()

local Box = Kuik.New("Frame", { BackgroundTransparency = 0.5 })
Box.Parent = Screen

Check("Scaling an object makes one UIScale and reuses it", (function()
	Motion.Scale(Box, 1.4)
	Motion.Scale(Box, 0.8)

	local Count = 0

	for _, Child in Box:GetChildren() do
		if Child:IsA("UIScale") then
			Count += 1
		end
	end

	return Count == 1
end)())

Settle()

Check("A scale spring lands on its goal",
	Near(Motion.ScaleOf(Box).Scale, 0.8), tostring(Motion.ScaleOf(Box).Scale))

Motion.Scale(Box, 1)
Settle()

--------------------------------------------------------------------------
print("\narriving and leaving")
--------------------------------------------------------------------------

local Popped = Kuik.New("Frame", { BackgroundTransparency = 0.2 })
Popped.Parent = Screen

Motion.Pop(Popped)

Check("Pop starts small", Motion.ScaleOf(Popped).Scale < 1)

Settle()

Check("Pop finishes at full size", Near(Motion.ScaleOf(Popped).Scale, 1))

local Leaving = Kuik.New("Frame", { BackgroundTransparency = 0.2 })
Leaving.Parent = Screen

local Gone = false

Motion.Out(Leaving, function()
	Gone = true
end)

Shim.Step(3)

Check("Out shrinks the thing on its way out", Motion.ScaleOf(Leaving).Scale < 1,
	tostring(Motion.ScaleOf(Leaving).Scale))

Check("Out fades it too", Leaving.BackgroundTransparency > 0.2,
	tostring(Leaving.BackgroundTransparency))

Check("Out calls back when it is done", Gone == true)

Leaving:Destroy()

Check("Out on something already gone still calls back", (function()
	local Called = false
	Motion.Out(nil, function() Called = true end)
	return Called
end)())

--------------------------------------------------------------------------
print("\nfading in")
--------------------------------------------------------------------------

local Row = Kuik.New("Frame", { BackgroundTransparency = 0.4 })
Row.Parent = Screen

local Inner = Kuik.New("TextLabel", { BackgroundTransparency = 1, TextTransparency = 0.25 })
Inner.Parent = Row

Motion.FadeIn(Row)

Check("FadeIn hides the row and its contents",
	Row.BackgroundTransparency == 1 and Inner.TextTransparency == 1)

Settle()

Check("FadeIn returns the row to its resting values",
	Near(Row.BackgroundTransparency, 0.4) and Near(Inner.TextTransparency, 0.25),
	string.format("%.2f / %.2f", Row.BackgroundTransparency, Inner.TextTransparency))

--------------------------------------------------------------------------
print("\npainting")
--------------------------------------------------------------------------

local Patch = Kuik.New("Frame", { BackgroundTransparency = 0 })
Patch.BackgroundColor3 = Color3.new(0, 0, 0)
Patch.Parent = Screen

Motion.Paint(Patch, { BackgroundColor3 = Color3.new(1, 1, 1) }, false)

Check("An unanimated paint lands at once", Patch.BackgroundColor3 == Color3.new(1, 1, 1))

--- The bug this guards: a direct set that does not cancel a running spring is
--- overwritten by that spring on the next frame.
Motion.Paint(Patch, { BackgroundColor3 = Color3.new(0, 0, 0) }, true)
Shim.Step(2)
Motion.Paint(Patch, { BackgroundColor3 = Color3.new(1, 0, 0) }, false)
Shim.Step(30)

Check("A direct paint cancels the spring under it",
	Patch.BackgroundColor3 == Color3.new(1, 0, 0), tostring(Patch.BackgroundColor3))

--------------------------------------------------------------------------
print("\nhandles")
--------------------------------------------------------------------------

local Window = Kuik.Window({ Title = "Motion", Open = true })
local Page = Window:Tabs():Page("Test")

local Toggle = Page:Toggle({ Label = "Animated in", Enter = true })

Check("A control built with Enter starts small", Motion.ScaleOf(Toggle.Frame).Scale < 1)

Settle()

Check("A control built with Enter settles at full size",
	Near(Motion.ScaleOf(Toggle.Frame).Scale, 1))

local Going = Page:Toggle({ Label = "Animated out" })
local Frame = Going.Frame

Going:Destroy(true)

--- Headlessly the wait collapses, so this proves the animated path still ends
--- in a real teardown rather than leaving the row behind.
Check("An animated destroy removes the control", Frame.Parent == nil)

local Fast = Page:Toggle({ Label = "Immediate" })
local FastFrame = Fast.Frame
Fast:Destroy()

Check("A plain destroy is immediate", FastFrame.Parent == nil)

--------------------------------------------------------------------------
print("\nwindows")
--------------------------------------------------------------------------

local Leaver = Kuik.Window({ Title = "Leaving", Open = true })
local Root = Leaver.Root

Leaver:Destroy(true)

Check("A window asked to animate out tears down once it has gone",
	Root.Parent == nil and not Leaver:IsAlive())

--- A second call while one is already leaving must not start another.
local Twice = Kuik.Window({ Title = "Twice", Open = true })
Twice:Destroy(true)
Twice:Destroy(true)

Check("Destroying a leaving window twice is harmless", not Twice:IsAlive())

Window:Destroy()

print(string.format("\n%s\n", Failures == 0 and "no failures" or (Failures .. " failures")))

if Failures > 0 then
	process.exit(1)
end
