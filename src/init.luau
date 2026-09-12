--!nonstrict
--- Kuik — a Roblox UI library in the NO REMORSE house style.
---
--- Rules and type, almost no fill, square by default, and everything moving on
--- springs. Built out of small modules: Theme is the tokens, Motion is the
--- spring solver, Parts is the two shells every control is made of, and
--- Controls is the registry that gets mixed into every container.
---
---   local Kuik = require(path.to.Kuik)
---
---   local Window = Kuik.Window({ Title = "Settings", Key = Enum.KeyCode.RightShift })
---   local Page = Window:Tabs():Page("Audio")
---
---   Page:Slider({ Label = "Master", Min = 0, Max = 100, Default = 80 })

local Palette  = require(script.Theme)
local Util     = require(script.Util)
local Motion   = require(script.Motion)
local Parts    = require(script.Parts)
local Scroll   = require(script.Scroll)
local Screen   = require(script.Screen)
local Controls = require(script.Controls)
local Layout   = require(script.Layout)
local Window   = require(script.Window)
local Hud      = require(script.Hud)
local Layers   = require(script.Layers)
local Reveal   = require(script.Reveal)

local Kuik = {}

Kuik.Version = {
	Name    = "Kuik",
	Version = "2.0.0",
}

--- Live token tables. Mutated in place by SetTheme, so anything holding a
--- reference keeps seeing the current values.
Kuik.Theme   = Palette.Tokens
Kuik.Metrics = Palette.Metrics
Kuik.Themes  = Palette.Themes

--- Windows and panels ------------------------------------------------------

Kuik.Window = Window

--- A window with the chrome stripped: no header, no side rules, no backdrop,
--- no blur, no scroller, and it does not unlock the mouse. This is the one to
--- build a health bar or an ammo counter out of.
function Kuik.Panel(Options)
	return Window(Util.Merge({
		Variant     = "Bare",
		Wash        = 1,
		Blur        = 0,
		Backdrop    = false,
		UnlockMouse = false,
		Scroll      = false,
		Fit         = false,
		Open        = true,
		Width       = 220,
		Height      = 80,
	}, Options))
end

--- A window that looks like a card: filled, rounded, stroked.
function Kuik.Card(Options)
	return Window(Util.Merge({ Variant = "Card" }, Options))
end

--- Layers ------------------------------------------------------------------

Kuik.Menu    = Layers.Menu
Kuik.Prompt  = Layers.Prompt
Kuik.Cards   = Layers.Cards
Kuik.Popover = Layers.Popover
Kuik.Sheet   = Layers.Sheet
Kuik.Drawer  = Layers.Drawer
Kuik.Coach   = Layers.Coach

--- HUD ---------------------------------------------------------------------

Kuik.Toast     = Hud.Toast
Kuik.Notify    = Hud.Notify
Kuik.Hints     = Hud.Hints
Kuik.Log       = Hud.Log
Kuik.Arrival   = Hud.Arrival
Kuik.Feed      = Hud.Feed
Kuik.Console   = Hud.Console
Kuik.Watermark = Hud.Watermark
Kuik.Bar       = Hud.Bar
Kuik.Timer     = Hud.Timer
Kuik.Ammo      = Hud.Ammo
Kuik.Crosshair = Hud.Crosshair
Kuik.Killfeed  = Hud.Killfeed
Kuik.Objective = Hud.Objective
Kuik.Vignette  = Hud.Vignette
Kuik.Compass   = Hud.Compass
Kuik.Fab       = Hud.Fab
Kuik.Viewfinder = Hud.Viewfinder

--- Reticle is the same thing a Crosshair is, under the name a 3D UI uses.
Kuik.Reticle   = Hud.Crosshair

--- Theming -----------------------------------------------------------------

--- Applies a theme by name or by table, repainting whatever is already on
--- screen. Pass Repaint = false to change the tokens only.
function Kuik.SetTheme(Theme, Repaint)
	return Palette.Set(Theme, Repaint)
end

function Kuik.GetTheme()
	return Palette.Name()
end

--- Registers a theme of your own under a name.
function Kuik.RegisterTheme(Name, Overlay)
	Palette.Register(Name, Overlay)
	return Kuik
end

--- Called after any theme change, for anything built from a colour rather than
--- painted in one.
function Kuik.OnTheme(Handler)
	return Palette.OnChange(Handler)
end

--- Extension ---------------------------------------------------------------

--- The control registry. Every name in here is a method on every container.
Kuik.Controls = Controls

--- Adds a control of your own. It becomes a method on every container built
--- after this call, so register before you build.
---
---   Kuik.Register("Sticker", function(Container, Options, Owner)
---       ... return Handle
---   end)
---
---   Page:Sticker({ Label = "Mine" })
function Kuik.Register(Name, Constructor)
	Controls[Name] = Constructor
	return Kuik
end

--- The building blocks, for anyone writing one.
Kuik.New       = Util.New
Kuik.Text      = Util.Text
Kuik.Tween     = Motion.Tween
Kuik.Spring    = Motion.SpringTo
Kuik.Motion    = Motion
Kuik.Util      = Util
Kuik.Parts     = Parts
Kuik.Scroll    = Scroll.Attach
Kuik.Gleam     = Scroll.Gleam
Kuik.Edges     = Scroll.Edges

--- The white layer: a plate that becomes the thing, a ghost that trails it.
Kuik.Reveal    = Reveal
Kuik.Plate     = Reveal.Plate
Kuik.Follow    = Reveal.Follow
Kuik.Ghost     = Reveal.Ghost
Kuik.Trail     = Reveal.Trail
Kuik.Wipe      = Reveal.Wipe
Kuik.Close     = Reveal.Close
Kuik.Cover     = Reveal.Cover
Kuik.Flash     = Reveal.Flash
Kuik.Row       = Parts.Row
Kuik.Block     = Parts.Block
Kuik.Attach    = Layout.Attach
Kuik.Tooltip   = Parts.Tooltip

--- Showcase ----------------------------------------------------------------

--- Every control the library has, in one window. Built for looking at: if
--- something is broken it is broken here, and anything that fails to build
--- says so in place rather than in the output.
---
---   Kuik.Showcase({ Key = Enum.KeyCode.F8 })
function Kuik.Showcase(Options)
	return require(script.Showcase)(Kuik, Options)
end

--- Screen ------------------------------------------------------------------

function Kuik.Screen()
	return Screen.Get()
end

--- The layer itself, for the two things about it that callers need: how much of
--- the top the platform has taken, and how to cover the whole window in spite
--- of it.
Kuik.Inset = Screen.Inset
Kuik.Cover = Screen.Cover
Kuik.Safe  = Screen.Safe

--- True while a prompt is up.
function Kuik.Blocked()
	return Screen.Blocked()
end

--- Tears down every window, panel and HUD piece this library made, and the
--- blur effects it parked in Lighting.
function Kuik.Reset()
	Screen.Destroy()

	for _, Effect in game:GetService("Lighting"):GetChildren() do
		if Effect.Name == "KuikBlur" then
			Effect:Destroy()
		end
	end
end

return Kuik
