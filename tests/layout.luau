--!nonstrict
--[[
	Layout audit.

	The shim has no layout engine, so nothing here measures anything. What it
	can do is read the geometry the library asked for, and catch the two
	mistakes that have cost the most time.

	  1. A child sized by scale in the same axis its parent sizes automatically.

	     Roblox resolves that by growing the parent, which grows the child,
	     which grows the parent. Rows built that way came out 436 pixels tall.

	  2. A decoration that is a sibling inside a laid out parent.

	     A UIListLayout lays out EVERY visible GuiObject child, so a hairline
	     meant to sit behind or beside its content becomes another item in the
	     row instead. A notice grew by the width of its own underline; a status
	     chip's two bracket rules ended up side by side in front of the text.
	     Decorations belong on a parent with no layout, with the laid out
	     content in a frame of its own.

	Run with:  lune run tests/layout
]]

local Shim = require("./shim")
Shim.Install()

local Kuik = require("./Kuik")

--- Which axes a parent sizes itself on.
local function Automatic(Object)
	local Mode = Object.AutomaticSize

	if Mode == nil then
		return false, false
	end

	local Name = tostring(Mode)

	return Name == "X" or Name == "XY", Name == "Y" or Name == "XY"
end

local Found = {}

local function Path(Object)
	local Parts = {}
	local Node = Object

	while Node do
		table.insert(Parts, 1, Node.Name)
		Node = Node.Parent
	end

	return table.concat(Parts, ".")
end

--- Names the library gives to things that are decoration rather than content:
--- a hairline, an underline, an accent stripe, a bracket. None of them should
--- ever be an item in a layout.
local DECORATION = {
	Rule = true,
	Wire = true,
	Accent = true,
	Underline = true,
	Closing = true,
}

--- Matched on the front of the name too, because the edge lights are called
--- GleamHead and GleamTail rather than Gleam — and they were the ones actually
--- caught behaving like list items, inside dropdown menus.
local DECORATION_PREFIX = { "Gleam", "Reveal", "Afterimage", "Ghost" }

local function Laid(Node)
	for _, Child in Node:GetChildren() do
		local Class = Child.ClassName

		if Class == "UIListLayout" or Class == "UIGridLayout" then
			return true
		end
	end

	return false
end

local function Walk(Node)
	local WideParent, TallParent = Automatic(Node)
	local Arranged = Laid(Node)

	for _, Child in Node:GetChildren() do
		local Size = Child.Size

		if Size then
			--- A layout instance has no size of its own; skip anything that is
			--- not really a rectangle.
			local Class = Child.ClassName
			local Laid = string.find(Class, "UI") == 1

			if not Laid then
				if TallParent and Size.Y.Scale > 0 then
					table.insert(Found, string.format(
						"%s (%s) is %g scale tall inside a parent that sizes itself on Y",
						Path(Child), Class, Size.Y.Scale))
				end

				if WideParent and Size.X.Scale > 0 then
					table.insert(Found, string.format(
						"%s (%s) is %g scale wide inside a parent that sizes itself on X",
						Path(Child), Class, Size.X.Scale))
				end

				local Decoration = DECORATION[Child.Name] or false

				for _, Front in DECORATION_PREFIX do
					if string.sub(Child.Name, 1, #Front) == Front then
						Decoration = true
					end
				end

				--- A decoration inside a layout is another item in the row.
				--- Visible ones only: something hidden is not being laid out.
				if Arranged and Decoration and Child.Visible ~= false then
					table.insert(Found, string.format(
						"%s (%s) is a decoration laid out as an item by its parent's layout",
						Path(Child), Class))
				end
			end
		end

		Walk(Child)
	end
end

print("\nlayout audit\n")

--- The showcase builds every control there is, which makes it the widest
--- possible surface to audit.
local Gallery = Kuik.Showcase({ Open = true })

--- The HUD pieces the showcase only builds when you press something. They are
--- exactly where the last two findings of this kind came from, so they are put
--- up by hand rather than left out of the sweep.
local Feed = Kuik.Feed({ Life = 0 })
Feed:Push("a notice")
Feed:Push("another")

local Arrival = Kuik.Arrival({
	Title = "a title",
	Subtitle = "a subtitle",
	Status = "a status",
	Footer = { "fine print" },
})

--- The overlays, which the showcase only builds when you press something —
--- and which is where the last scale-in-auto-size loop was hiding.
local Prompt = Kuik.Prompt({
	Title = "Sure?",
	Text = "a prompt in the house style",
	Actions = { { Label = "Yes" }, { Label = "No" } },
})

local Card = Kuik.Prompt({ Title = "Or a card", Variant = "Card", Actions = {} })

local Menu = Kuik.Menu({ Items = { "One", "Two" } })
Menu:Show(100, 100)

local Rails = Kuik.Menu({ Items = { "One", "Two" }, Variant = "Rules" })
Rails:Show(300, 100)

local Loose = {
	Feed, Arrival, Prompt, Card, Menu, Rails,
	Kuik.Watermark({ Fields = { { "one", "1" } } }),
	Kuik.Log(),
	Kuik.Killfeed(),
	Kuik.Objective({ Label = "OBJECTIVE", Text = "do the thing", Progress = 0.4 }),
	Kuik.Timer({ Seconds = 90 }),
	Kuik.Ammo({ Weapon = "SILENCED", Magazine = 7, Reserve = 21, Capacity = 7 }),
	Kuik.Compass(),
	Kuik.Viewfinder(),
	Kuik.Hints(),
}

Walk(Kuik.Screen())

if #Found == 0 then
	print("  ok    no scale sized child inside a parent that sizes itself on the same axis")
	print("  ok    no decoration laid out as an item")
	print("\n0 findings\n")
else
	for _, Line in Found do
		print("  FAIL  " .. Line)
	end

	print(string.format("\n%d findings\n", #Found))
end

Gallery:Destroy()

for _, Piece in Loose do
	if Piece and Piece.Destroy then
		Piece:Destroy()
	end
end

if #Found > 0 then
	error(string.format("%d layout findings", #Found), 0)
end
