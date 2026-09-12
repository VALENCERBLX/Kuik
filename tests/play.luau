--!nonstrict
--[[
	The controls added for games, and the general ones that came with them.

	Run with:  lune run tests/play
]]

local Shim = require("./shim")
Shim.Install()

local Kuik = require("./Kuik")

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

local function Count(Node, Name)
	local Total = 0

	for _, Child in Node:GetDescendants() do
		if Child.Name == Name and Child.Visible ~= false then
			Total += 1
		end
	end

	return Total
end

local Window = Kuik.Window({ Title = "Play", Open = true, Reveal = false })
local Page = Window:Tabs():Page("New")

print("\nplay\n")

--------------------------------------------------------------------------
print("leaderboard")
--------------------------------------------------------------------------

local Board = Page:Leaderboard({
	Label = "Round",
	Me = "you",
	Entries = {
		{ Name = "someone", Value = 12 },
		{ Name = "you", Value = 40 },
		{ Name = "another", Value = 25 },
	},
})

Check("A leaderboard is built", Board ~= nil)

Check("It sorts by value", (function()
	local Places = {}

	for _, Item in Board.Frame:GetDescendants() do
		if Item.Name == "Place" and Item.Visible then
			table.insert(Places, Item)
		end
	end

	table.sort(Places, function(A, B) return A.LayoutOrder < B.LayoutOrder end)

	--- The pinned row has no layout order of its own, so read the ranks.
	local Ranks = {}

	for _, Place in Places do
		for _, Item in Place:GetChildren() do
			if Item:IsA("TextLabel") and tonumber(Item.Text) then
				table.insert(Ranks, tonumber(Item.Text))
				break
			end
		end
	end

	return #Ranks >= 3 and Ranks[1] == 1, table.concat(Ranks, ",")
end)())

--- Names are swapped through a dip, which the clock now honours, so let the
--- swap land before reading any of them.
Advance(0.4)

--- The one thing a leaderboard must do that a table need not.
Check("Your own row is pinned where you can see it", (function()
	local Mine = Board.Frame:FindFirstChild("Mine", true)

	if not Mine then
		return false, "no pinned row"
	end

	for _, Item in Mine:GetDescendants() do
		if Item:IsA("TextLabel") and Item.Text == "you" then
			return true
		end
	end

	return false, "pinned row is not yours"
end)())

Board:Set({ { Name = "you", Value = 5 } })
Advance(0.4)

Check("Setting again reuses the rows it has",
	Count(Board.Frame, "Place") <= 4, tostring(Count(Board.Frame, "Place")))

--------------------------------------------------------------------------
print("\nslots")
--------------------------------------------------------------------------

local Bag = Page:Slots({ Label = "Bag", Count = 8, Across = 4 })

Check("Every slot is drawn, empty ones included",
	Count(Bag.Frame, "Slot") == 8, tostring(Count(Bag.Frame, "Slot")))

Bag:Set(2, { Label = "Medkit", Count = 3 })
Advance(0.4)

Check("An item lands in its slot", (function()
	local Item = Bag:Get(2)
	return Item ~= nil and Item.Label == "Medkit"
end)())

Check("and a count over one is shown", (function()
	for _, Child in Bag.Frame:GetDescendants() do
		if Child:IsA("TextLabel") and Child.Text == "3" and Child.Visible then
			return true
		end
	end

	return false
end)())

local Picked = nil
Bag.Options.Callback = function(Index) Picked = Index end

Bag:Select(2)

Check("Selecting reports which slot", Picked == 2)
Check("and Get with no index gives the selection", (function()
	local Index, Item = Bag:Get()
	return Index == 2 and Item.Label == "Medkit"
end)())

Bag:Clear()
Check("Clearing empties every slot", Bag:Get(2) == nil)

--------------------------------------------------------------------------
print("\nwallet")
--------------------------------------------------------------------------

local Purse = Page:Wallet({ Label = "Kions", Default = 1000 })

Check("A wallet starts at what it was given", Purse:Get() == 1000)

Purse:Add(250)

Check("Adding changes the number it is heading for", Purse:Get() == 1250)

--- The point of a wallet: it rolls rather than swapping, so a change of 250
--- looks like a change of 250.
Check("and it rolls there rather than jumping", (function()
	local Part = Purse.Readout.Text

	Advance(0.03)

	local Moving = Purse.Readout.Text

	Advance(2)

	local Landed = Purse.Readout.Text

	return Moving ~= Part and Landed:gsub("[^%d]", "") == "1250",
		string.format("%s -> %s -> %s", Part, Moving, Landed)
end)())

--------------------------------------------------------------------------
print("\nradial")
--------------------------------------------------------------------------

local Wheel = Page:Radial({
	Label = "Emote",
	Items = { { Label = "wave" }, { Label = "point" }, { Label = "sit" }, { Label = "dance" } },
})

Check("A radial draws a dot per item",
	Count(Wheel.Frame, "Dot") == 4, tostring(Count(Wheel.Frame, "Dot")))

local Chosen = nil
Wheel.Options.Callback = function(Index) Chosen = Index end

Wheel:Choose(3)
Advance(0.4)

Check("Choosing reports it", Chosen == 3)
Check("and the middle names what is chosen", (function()
	local Middle = nil

	for _, Item in Wheel.Frame:GetDescendants() do
		if Item:IsA("TextLabel") and Item.Text == "sit" then
			Middle = Item
		end
	end

	return Middle ~= nil
end)())

--------------------------------------------------------------------------
print("\nversus")
--------------------------------------------------------------------------

local Match = Page:Versus({
	Label = "Score",
	LeftLabel = "Home",
	RightLabel = "Away",
	Left = 3,
	Right = 1,
})

Check("A versus takes two totals", (function()
	local L, R = Match:Get()
	return L == 3 and R == 1
end)())

Advance(0.6)

Check("and the bar splits by share", (function()
	local Track = Match.Frame:FindFirstChild("Track", true)
	local Home = Track:FindFirstChild("Home")
	local Away = Track:FindFirstChild("Away")

	--- Three to one is 75/25 of the whole, so half of each side's own half.
	return math.abs(Home.Size.X.Scale - 0.375) < 0.02
		and math.abs(Away.Size.X.Scale - 0.125) < 0.02,
		string.format("%.3f / %.3f", Home.Size.X.Scale, Away.Size.X.Scale)
end)())

Match:Add(0, 3)
Advance(0.6)

Check("Adding moves it", (function()
	local L, R = Match:Get()
	return L == 3 and R == 4
end)())

--------------------------------------------------------------------------
print("\nempty, confirm, sortable")
--------------------------------------------------------------------------

local Nothing = Page:Empty({ Text = "No rounds yet", Detail = "Play one" })

Check("An empty state says what is missing", (function()
	for _, Item in Nothing.Frame:GetDescendants() do
		if Item:IsA("TextLabel") and Item.Text == "No rounds yet" then
			return true
		end
	end

	return false
end)())

local Fired = 0
local Danger = Page:Confirm({
	Label = "Delete save",
	Action = "Delete",
	Window = 3,
	Callback = function() Fired += 1 end,
})

Check("A confirm does not fire on the first press", (function()
	local Button = Danger.Frame:FindFirstChild("Confirm", true)

	Button.Activated:Fire()
	Advance(0.3)

	return Fired == 0 and Danger:IsArmed()
end)())

Check("and does on the second", (function()
	local Button = Danger.Frame:FindFirstChild("Confirm", true)

	Button.Activated:Fire()
	Advance(0.3)

	return Fired == 1 and not Danger:IsArmed()
end)())

Check("It disarms itself if you walk away", (function()
	local Button = Danger.Frame:FindFirstChild("Confirm", true)

	Button.Activated:Fire()
	Advance(0.2)

	local Was = Danger:IsArmed()

	Advance(4)

	return Was and not Danger:IsArmed()
end)())

local Order = Page:Sortable({
	Label = "Order",
	Items = { "one", "two", "three" },
})

Check("A sortable keeps its order", (function()
	local Now = Order:Get()
	return Now[1] == "one" and Now[3] == "three"
end)())

Order:Move(1, 3)
Advance(0.5)

Check("and moving a row reorders it", (function()
	local Now = Order:Get()
	return Now[3] == "one" and Now[1] == "two",
		table.concat(Now, ",")
end)())

--------------------------------------------------------------------------
print("\ndonut and scatter")
--------------------------------------------------------------------------

local Split = Page:Donut({
	Label = "Where it went",
	Items = {
		{ Label = "rent", Value = 60 },
		{ Label = "food", Value = 30 },
		{ Label = "rest", Value = 10 },
	},
})

Check("A donut names every wedge", (function()
	local Named = 0

	for _, Item in Split.Frame:GetDescendants() do
		if Item:IsA("TextLabel") then
			for _, Name in { "rent", "food", "rest" } do
				if Item.Text == Name then
					Named += 1
				end
			end
		end
	end

	return Named == 3, tostring(Named)
end)())

Check("and draws an arc for each", Count(Split.Frame, "Arc") > 6,
	tostring(Count(Split.Frame, "Arc")))

local Cloud = Page:Scatter({
	Label = "Two numbers",
	Points = { { 1, 2 }, { 4, 8 }, { 7, 3 } },
})

Check("A scatter plots a point each",
	Count(Cloud.Frame, "Point") == 3, tostring(Count(Cloud.Frame, "Point")))

Cloud:Add(10, 10)
Advance(0.5)

Check("and takes another", Count(Cloud.Frame, "Point") == 4)

Check("Its points land inside the field", (function()
	Advance(1)

	for _, Item in Cloud.Frame:GetDescendants() do
		if Item.Name == "Point" and Item.Visible then
			local X, Y = Item.Position.X.Scale, Item.Position.Y.Scale

			if X < -0.01 or X > 1.01 or Y < -0.01 or Y > 1.01 then
				return false, string.format("%.2f,%.2f", X, Y)
			end
		end
	end

	return true
end)())

Window:Destroy()

print(string.format("\n%s\n", Failures == 0 and "no failures" or (Failures .. " failures")))

if Failures > 0 then
	process.exit(1)
end
