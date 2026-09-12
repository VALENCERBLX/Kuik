--!nonstrict
--- Screen.luau — the one ScreenGui everything lands in, plus the modal count.
---
--- The modal count is global on purpose: a prompt has to be able to silence
--- the scroll wheel and the toggle keys of windows it knows nothing about.

local Players    = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local Util = require(script.Parent.Util)

local New = Util.New

local Screen = {}

local LocalPlayer = Players.LocalPlayer
local Host = nil

--- Rebuilds itself if something destroys the GUI out from under us, which is
--- what Kuik.Reset does.
function Screen.Get()
	if Host and Host.Parent then
		return Host
	end

	local Parent = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")

	Host = New("ScreenGui", {
		Name             = "Kuik",
		Parent           = Parent,
		ResetOnSpawn     = false,
		IgnoreGuiInset   = true,
		ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
		DisplayOrder     = 50,
	})

	return Host
end

--- How much of the top of the screen the platform has taken.
---
--- The one ScreenGui ignores the inset on purpose, so a full bleed thing — a
--- vignette, a flash, a loading sheet — really does cover the screen. The cost
--- is that anything measured as a fraction from the top can land underneath the
--- top bar, so anything that has to stay clear of it adds this back.
function Screen.Inset()
	local Ok, Top = pcall(function()
		return GuiService:GetGuiInset()
	end)

	return Ok and Top and Top.Y or 0
end

--- A y position given as a fraction of what the player can actually see,
--- returned as offset pixels from the top of the inset ignoring layer.
---
--- Measured rather than assumed. With IgnoreGuiInset, Roblox moves the layer up
--- by the inset and leaves its size alone: against a 1532 x 619 viewport with a
--- 58 px bar, the layer reports position (0, -58) and size 1532 x 619. So the
--- visible window is the layer's own height, starting one inset down from the
--- layer's top.
function Screen.Safe(Fraction, Height)
	local Top = Screen.Inset()
	local Tall = Height or math.max(0, Screen.Get().AbsoluteSize.Y)

	return Top + Tall * (Fraction or 0)
end

--- Makes something cover the whole window, top bar included.
---
--- The same measurement is why this exists: a child of the layer sized
--- (1, 0, 1, 0) covers the bar at the top and leaves exactly one inset of the
--- screen UNCOVERED at the bottom. Everything full bleed — a flash, a vignette,
--- a backdrop, a loading sheet — has to be a bar taller than it looks.
function Screen.Cover(Object)
	local Top = Screen.Inset()

	Object.Position = UDim2.new(0, 0, 0, 0)
	Object.Size = UDim2.new(1, 0, 1, Top)

	return Object
end

function Screen.Destroy()
	if Host then
		Host:Destroy()
		Host = nil
	end
end

local Modals = 0
local Watchers = {}

--- True while anything modal is up. Input handlers check this before acting so
--- the world behind a prompt stays inert.
function Screen.Blocked()
	return Modals > 0
end

function Screen.Depth()
	return Modals
end

function Screen.Enter()
	Modals += 1

	for _, Handler in Watchers do
		task.spawn(Handler, Modals)
	end
end

function Screen.Exit()
	Modals = math.max(0, Modals - 1)

	for _, Handler in Watchers do
		task.spawn(Handler, Modals)
	end
end

--- Lets a control react to the world going modal, rather than only poll it.
function Screen.OnModal(Handler)
	table.insert(Watchers, Handler)

	return function()
		local At = table.find(Watchers, Handler)

		if At then
			table.remove(Watchers, At)
		end
	end
end

Screen.Player = LocalPlayer

return Screen
