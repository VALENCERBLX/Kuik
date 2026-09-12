--!nonstrict
--[[
	The zoom maths, checked against numbers rather than screenshots. The shim
	never measures anything, so the well's absolutes are set by hand and the
	pointer is driven through UserInputService.

	Run with:  lune run tests/zoom
]]

local Shim = require("./shim")
Shim.Install()

local Kuik = require("./Kuik")

local UserInputService = game:GetService("UserInputService")

local Failures = 0

local function Check(Name, Condition, Detail)
	if Condition then
		print(string.format("  ok    %s", Name))
	else
		Failures += 1
		print(string.format("  FAIL  %s%s", Name, Detail and (" - " .. Detail) or ""))
	end
end

local function Near(A, B)
	return math.abs(A - B) < 0.01
end

--- Hover is a state the well reports; the position comes through the input
--- service, in the space AbsolutePosition is measured in.
local Hover = nil

local function Enter()
	Hover.MouseEnter:Fire()
end

local function Move(X, Y)
	UserInputService.InputChanged:Fire({
		UserInputType = Enum.UserInputType.MouseMovement,
		Position      = Vector3.new(X, Y, 0),
	})
end

local function Leave()
	Hover.MouseLeave:Fire()
end

local function Wheel(Delta)
	UserInputService.InputChanged:Fire({
		UserInputType = Enum.UserInputType.MouseWheel,
		Position      = Vector3.new(0, 0, Delta),
	})
end

--- The wheel belongs to the page unless a control key is held, so every wheel
--- check below holds one.
Shim.Held[Enum.KeyCode.LeftControl] = true

local function Size(Object, Wide, Tall)
	Object.AbsoluteSize = Vector2.new(Wide, Tall)
	Object.AbsolutePosition = Vector2.new(0, 0)
end

print("\nzoom\n")

--------------------------------------------------------------------------
print("loupe")
--------------------------------------------------------------------------

local Window = Kuik.Window({ Title = "Zoom" })
local Page = Window:Tabs():Page("Test")

local Lens = 90
local Factor = 2.5

local Loupe = Page:Zoom({ Label = "Loupe", Image = "rbxassetid://1", Lens = Lens, Factor = Factor })

Size(Loupe.Well, 400, 130)
Hover = Loupe.Well

Enter()
Move(100, 65)

Check("the loupe shows on a pointer inside the well", Loupe.Loupe.Visible == true)

--- The bug this guards: a zoom in a scrolling page used to eat the wheel, so
--- the page stopped scrolling and the picture quietly rescaled instead.
Check("a plain wheel is left to the page", (function()
	Shim.Held[Enum.KeyCode.LeftControl] = false

	local Before = Loupe:GetFactor()
	Wheel(1)
	local After = Loupe:GetFactor()

	Shim.Held[Enum.KeyCode.LeftControl] = true

	return Before == After
end)())

Check("the magnified copy is sized against the well, not its own parent",
	Near(Loupe.Magnified.Size.X.Offset, 400 * Factor)
	and Near(Loupe.Magnified.Size.Y.Offset, 130 * Factor)
	and Loupe.Magnified.Size.X.Scale == 0,
	string.format("got %s", tostring(Loupe.Magnified.Size)))

--- Quarter across, halfway down: that spot must sit at the lens centre.
Check("the pointed at spot lands under the pointer",
	Near(Loupe.Magnified.Position.X.Offset, Lens / 2 - 0.25 * 400 * Factor)
	and Near(Loupe.Magnified.Position.Y.Offset, Lens / 2 - 0.5 * 130 * Factor),
	string.format("got %s", tostring(Loupe.Magnified.Position)))

Check("the lens follows the pointer",
	Near(Loupe.Loupe.Position.X.Scale, 0.25) and Near(Loupe.Loupe.Position.Y.Scale, 0.5),
	tostring(Loupe.Loupe.Position))

Move(300, 26)

Check("a second move re-aims it",
	Near(Loupe.Magnified.Position.X.Offset, Lens / 2 - 0.75 * 400 * Factor)
	and Near(Loupe.Loupe.Position.Y.Scale, 0.2),
	tostring(Loupe.Magnified.Position))

Wheel(1)

Check("the wheel zooms in", Loupe:GetFactor() > Factor,
	string.format("%.2f", Loupe:GetFactor()))

Check("zooming keeps the spot under the pointer",
	Near(Loupe.Magnified.Position.X.Offset, Lens / 2 - 0.75 * 400 * Loupe:GetFactor()),
	tostring(Loupe.Magnified.Position))

for _ = 1, 60 do
	Wheel(1)
end

Check("the wheel stops at the ceiling", Loupe:GetFactor() == 8,
	string.format("%.2f", Loupe:GetFactor()))

for _ = 1, 200 do
	Wheel(-1)
end

Check("the wheel stops at the floor", Loupe:GetFactor() == 1,
	string.format("%.2f", Loupe:GetFactor()))

Leave()

Check("the loupe hides when the pointer leaves", Loupe.Loupe.Visible == false)

--- The bug this guards: the wheel used to move every zoom on screen at once,
--- whether or not the pointer was anywhere near one.
local Resting = Loupe:GetFactor()

Wheel(1)
Wheel(1)

Check("the wheel does nothing once the pointer has left",
	Loupe:GetFactor() == Resting, string.format("%.2f", Loupe:GetFactor()))

Enter()
Move(100, 65)

Loupe:SetFactor(3)
Check("SetFactor takes", Loupe:GetFactor() == 3)

Loupe:Reset()
Check("Reset returns to the option", Near(Loupe:GetFactor(), Factor))

--------------------------------------------------------------------------
print("\npan")
--------------------------------------------------------------------------

Leave()

local Pan = Page:Zoom({ Label = "Pan", Image = "rbxassetid://1", Mode = "Pan", Factor = 2 })

Size(Pan.Well, 400, 130)
Pan:SetFactor(2, false)

Check("the pan well is lit on all four inside edges", (function()
	for _, Name in { "Left", "Right", "Top", "Bottom" } do
		if not Pan.Well:FindFirstChild(Name) then
			return false
		end
	end

	return true
end)())

Check("the picture grows in pixels",
	Near(Pan.Picture.Size.X.Offset, 800) and Near(Pan.Picture.Size.Y.Offset, 260)
	and Pan.Picture.Size.X.Scale == 0,
	tostring(Pan.Picture.Size))

Pan:Pan(-1000, -1000)

Check("panning is clamped to the picture",
	Pan.Picture.Position.X.Offset >= -400 and Pan.Picture.Position.Y.Offset >= -130,
	tostring(Pan.Picture.Position))

Pan:SetFactor(1, false)

Check("at one to one there is nothing to pan to",
	Near(Pan.Picture.Position.X.Offset, 0) and Near(Pan.Picture.Position.Y.Offset, 0),
	tostring(Pan.Picture.Position))

Window:Destroy()

print(string.format("\n%s\n", Failures == 0 and "no failures" or (Failures .. " failures")))

if Failures > 0 then
	process.exit(1)
end
