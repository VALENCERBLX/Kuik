# Kuik

A Roblox UI library in the style of NO REMORSE / the `MAR_*` engine.

The premise: **there is no panel.** A window is two 1px vertical hairline rules
with nothing between them, floating over the game. No fill, no border, no corner
radius, no accent colour. Hierarchy is carried entirely by typography and
negative space, and the only bright objects on screen are the controls.

Colour is reserved for meaning — red is a warning, amber is a log level, blue
is a role. It is never decoration.

```
 │  Settings                                  │
 │  Manage your preferences                   │
 │                                            │
 │  Categories                                │
 │  Choose a category to configure.           │
 │                                            │
 │   ◉ Camera  (Visual)  ✛ State   ♪ Audio    │
 │                                            │
 │  Show UI/UX                       ▄▄▄██    │
 │  Show and configure interface elements.    │
 │                                            │
 │  Watermark Side                       L    │
 │  Choose which side displays the watermark. │
 │  ▌─────────────────────────────────────    │
 │                                            │
```

## Install

Drop `init.luau` into `ReplicatedStorage` as a ModuleScript named `Kuik`.
Everything is client-side; require it from a `LocalScript`.

```lua
local Kuik = require(game.ReplicatedStorage.Kuik)
```

Single file, no dependencies, no assets — the keycap and log glyphs are drawn
from primitives rather than imported.

## Quick start

```lua
local Window = Kuik.Window({
    Title    = "Settings",
    Subtitle = "Manage your preferences",
    Key      = Enum.KeyCode.Tab,
})

local Categories = Window:Section("Categories", "Choose a category to configure.")
local Tabs       = Categories:Tabs()

local Visual = Tabs:Page("Visual")

Visual:Toggle({
    Label       = "Show UI/UX",
    Description = "Show and configure interface elements.",
    Default     = true,
    Callback    = function(On) print("interface:", On) end,
})

Visual:Slider({
    Label       = "Field of View",
    Description = "Camera field of view.",
    Min = 60, Max = 120, Step = 1, Default = 100,
    Callback = function(Value) workspace.CurrentCamera.FieldOfView = Value end,
})
```

`demo/Demo.client.luau` rebuilds the reference settings panel.
`demo/Showcase.client.luau` exercises every option, method and handle in the
library across twelve tabs.

## Window

```lua
Kuik.Window({
    Title       = "Settings",
    Subtitle    = "Manage your preferences",
    Key         = Enum.KeyCode.Tab,  -- bind to open/close
    Open        = false,             -- open on construction
    Width       = 460,
    Height      = 500,
    Blur        = 22,                -- backdrop BlurEffect size, 0 to disable
    Wash        = 0.88,              -- backdrop white wash transparency
    Parallax    = 5,                 -- max drift in px, 0 to disable
    UnlockMouse = true,
})
```

| Method | Does |
| --- | --- |
| `:Open()` / `:Close()` | Show or hide, with the hairline rules drawing out from the centre |
| `:SetOpen(Boolean)` | Either, from a value |
| `:IsOpen()` | Current state |
| `:Section(Title, Description)` | A header block; returns a Section |
| `:Tabs(Options)` | A pill tab row; returns a Tabs |
| `:SetParallax(Amount)` | Drift the interface against camera motion, in px |
| `:Destroy()` | Tears down the window, its backdrop and its blur |

`:Show()` and `:Hide()` are aliases for `:Open()` and `:Close()`.

> **Why not `Window:Toggle()`?** Every container in this library gets a
> `:Toggle()` **row constructor** mixed in, and a window is a container. Using
> that name for open/close silently shadows the control — pressing the bind key
> would build a toggle row instead of opening the menu. Hence `:Open()`.

## Sections, tabs and pages

Sections are headers, not boxes. Rows added to a section land in the window
body directly beneath it, in declaration order.

```lua
local Section = Window:Section("Categories", "Choose a category to configure.")
local Tabs    = Section:Tabs({ Align = "Left", Callback = function(Name) end })

local Camera = Tabs:Page("Camera", "rbxassetid://0")  -- icon optional
local Visual = Tabs:Page("Visual")

Tabs:Select("Visual")
Tabs:Active()  --> "Visual"
```

The first page added becomes active. Selection moves one shared white pill
between tabs rather than filling each button — the movement is most of the
character of the control.

## Controls

Available on a Window, a Section or a Page. Every one takes `Label` and
optional `Description`, and returns a handle with `:Get()`, `:Set(Value,
Silent)` and `:Destroy()`. `:Set(Value, true)` updates the visual without
firing the callback, which is what you want when restoring saved settings.

| Control | Extra options |
| --- | --- |
| **Input** | |
| `:Toggle` | `Default` |
| `:Checkbox` | `Default` — for when a switch would overstate the change |
| `:Slider` | `Min`, `Max`, `Step`, `Default`, `Format` |
| `:Range` | `Min`, `Max`, `Step`, `Low`, `High`, `Format` — two thumbs on one track |
| `:Stepper` | `Min`, `Max`, `Step`, `Default` — click the chip's left or right half |
| `:Dropdown` | `Items`, `Default`, `Width`, `Visible` — unrolls on the Y axis, on the window overlay |
| `:Segmented` | `Items`, `Default` — the tab bar shrunk into a row |
| `:Radio` | `Items`, `Default` — exclusive, hairline ring with a filled centre |
| `:Chips` | `Items`, `Default` (a table) — multi-select, `:Get()` returns a table |
| `:List` | `Items`, `Default`, `Height` — scrollable; selection is a left hairline |
| `:Keybind` | `Default` (a `KeyCode`); Escape cancels rebinding |
| `:Input` | `Default`, `Placeholder` |
| `:Vector` | `Axes`, `Default` (a table), `Step` — X/Y/Z fields on one row |
| `:Color` | `Default` (a `Color3`) — swatch plus three channel tracks |
| `:ColorPicker` | `Default`, `Height` — saturation/value field over a hue strip |
| `:Rating` | `Count`, `Default` — clicking the current value clears it |
| `:Pagination` | `Pages`, `Default`; also `:SetPages(N)` |
| `:Button` | `Action` (pill text), `Callback` |
| **Readout** | |
| `:Badge` | `Text`, `Color` — a semantic tag |
| `:Status` | `Value` — monospace key/value, the watermark's voice |
| `:Progress` | `Default`, `Max`, `Color`, `Format` |
| `:Meter` | `Default`, `Max`, `Segments`, `Warn`, `Danger` — picks its own colour past a threshold |
| `:Ring` | `Default`, `Max`, `Ticks`, `Radius`, `Format` — circular progress as ticks |
| `:Alert` | `Label`, `Text`, `Color` — a message with a semantic left rule |
| `:Spinner` | indeterminate; eight dots chasing |
| `:Sparkline` | `Values`, `Min`, `Max`, `Width`, `Height`, `Limit`; also `:Push(v)` |
| `:Graph` | `Values`, `Height`, `Limit`, `Color`; also `:Push(v)` |
| `:Bars` | `Values`, `Height`, `Limit`, `Color`; also `:Push(v)` |
| `:Table` | `Columns` (`{ Label, Width, Align }`), `Rows` |
| `:Avatar` | `UserId` or `Image`, `Label`, `Description` |
| **Structure** | |
| `:Divider` | `Label` — a horizontal hairline, optionally interrupted |
| `:Accordion` | `Label`, `Open` — returns a **container**, so it nests |
| `:Tree` | `Nodes` (`{ Label, Open, Children }`), `Callback` |
| `:Breadcrumb` | `Path`, `Callback` |
| `:Paragraph` | `Text` — prose, no control |
| `:Gap` | `Height` |

Charts are drawn from rotated 1px frames — the same hairline the window is
built from, just at an angle. No canvas, no assets, no library. Segments are
pooled and **retargeted** rather than rebuilt, so pushing new data springs the
line into its new shape instead of blinking.

`:Accordion` returns a full container: anything that can go on a page can go
inside one, including another accordion.

```lua
local Advanced = Page:Accordion({ Label = "Advanced", Open = false })
Advanced:Toggle({ Label = "Nested", Default = true })
Advanced:Accordion({ Label = "Deeper" }):Checkbox({ Label = "All the way down" })
```

`Step` on a slider also drives the readout's precision: `Step = 0.05` prints
`0.25`, `Step = 1` prints `25`. Pass `Format = function(Value) return "..." end`
to override entirely.

## HUD

The second half of the language, and the half that makes it recognisable.
None of it has a background.

```lua
-- | bracketed announcement |   top centre, no fill
local Toast = Kuik.Toast("Waiting for players.", { Duration = 0 })
Toast:Set("3 players.")   -- Duration 0 means it stays until :Destroy()

-- the one component with a fill: a card that drops from the top edge
Kuik.Notify({ Title = "You've joined <b>loll</b>", Image = "rbxassetid://0" })

-- right-edge keycap hints
local Hints = Kuik.Hints()
Hints:Add("SHIFT", "Sprint")
Hints:Add("TAB", "Open Settings")

-- bottom-left bracketed feed; RichText is on, so colour role names inline
local Log = Kuik.Log({ Limit = 8 })
Log:Push('Your role is <font color="#5c9cff">CONSERVATOR</font>.')

-- top-right monospace severity feed
local Console = Kuik.Console()
Console:Push("WARN", "helsinki VOTE-1001 reason=Removed by server votekick.")
-- INFO · SUCCESS · WARN · ERROR · DEBUG

-- the monospace status line welded to the bottom edge
local Watermark = Kuik.Watermark({
    Side   = "Left",
    Tag    = { Text = "PROTOTYPING", Color = Kuik.Theme.Danger },
    Fields = { "HL_v1", "HL-260829-…", "Washington, United States" },
})
Watermark:SetSide("Right")
```

## Motion

Motion is ported from Lume — the same role names, the same durations, the same
easings, and the same spring solver — so anything built with both moves
identically.

There are two paths, and the split is Lume's: **tweens** for anything with a
fixed duration (opacity, colour, text swaps), **springs** for anything whose
target can change mid-flight (positions, sizes, drags). Retargeting a spring
keeps its current position *and velocity*, so the motion bends toward the new
destination instead of restarting from a standstill — which is why dragging a
slider trails the cursor instead of teleporting to it.

```lua
Kuik.Theme.Motion = {
    instant = { Duration = 0 },
    enter   = { Duration = 0.46, Easing = "outQuint" },   -- window open
    exit    = { Duration = 0.38, Easing = "outQuad"  },   -- window close
    expand  = { Duration = 0.34, Easing = "outQuint" },
    hover   = { Duration = 0.12, Easing = "outQuad"  },
    press   = { Duration = 0.07, Easing = "outQuad"  },
    fade    = { Duration = 0.34, Easing = "outQuad"  },
    hint    = { Duration = 0.22, Easing = "outQuad"  },
    item    = { Duration = 0.30, Easing = "outQuad"  },
    list    = { Duration = 0.28, Easing = "outQuad"  },
    drop    = { Duration = 0.46, Easing = "outBack"  },

    layout  = { Stiffness = 190, Damping = 24 },
    morph   = { Stiffness = 210, Damping = 26 },   -- the tab pill sliding
    drag    = { Stiffness = 620, Damping = 42 },   -- follows a pointer
    toss    = { Stiffness = 340, Damping = 22 },   -- settles with a bounce
    reveal  = { Stiffness = 150, Damping = 20 },   -- accordions, window rules
    snap    = { Stiffness = 600, Damping = 40 },
}
```

`Damping` is the coefficient, not the ratio — critical for a given stiffness is
`2 * sqrt(Stiffness)`. Every shipped spring sits a little under critical, so
they all overshoot slightly and come back; that small bounce is what reads as
weight. `toss` is the most obvious, at a ratio of 0.60.

The solver is stepped analytically, so it lands identically at 30fps and
240fps, and a long frame is capped at 1/20s so a hitch reads as motion rather
than a teleport. One `Heartbeat` connection drives every live spring and
disconnects itself when nothing is moving.

`Kuik.Tween(Object, Properties, Role)` takes a role name or a literal spec
table, and dispatches to the right path automatically:

```lua
Kuik.Tween(Frame, { Position = Target }, "toss")                     -- spring
Kuik.Tween(Label, { TextTransparency = 0 }, "fade")                  -- tween
Kuik.Tween(Frame, { Size = Big }, { Stiffness = 400, Damping = 30 }) -- literal
```

## Theme

`Kuik.Theme` and `Kuik.Metrics` are live tables — assign to them before
constructing anything and the whole library follows. Motion durations and
spring constants are read at animation time, so those take effect immediately;
colour, font and size are read at construction, so they need a rebuild.

```lua
Kuik.Theme.Font = Font.fromEnum(Enum.Font.Gotham)  -- default is Montserrat
Kuik.Theme.RuleTransparency = 0.3                  -- brighter rules
Kuik.Theme.Motion.toss.Damping = 37                -- kill the bounce
Kuik.Metrics.WindowWidth = 520
Kuik.Metrics.PillRadius = 0                        -- square every pill
```

Dim text is expressed as a **transparency of white**, not a grey, because the
library is designed to sit over arbitrary game footage. `TextPrimary`,
`TextSecondary`, `TextTertiary` and `TextDisabled` are the four steps.

`Theme.Scrim` is the backdrop colour, and it **darkens** — a light wash erases
white rules and white type over a bright scene.

The semantic colours — `Danger`, `Warn`, `Info`, `Good`, `Neutral` — are the
only chromatic values in the library, and nothing uses them decoratively.

## Scrolling

Roblox scrolls a `ScrollingFrame` in hard jumps. On desktop the library takes
the wheel over and springs `CanvasPosition` instead, which is the difference
between a panel that lurches and one that glides. Touch is left alone — its
drag is already smooth and momentum-driven, and disabling `ScrollingEnabled`
would break it.

The window body, the tab bar, `:List` and an overflowing `:Dropdown` all scroll
this way. While the pointer is over the tab bar the wheel belongs to the tab
bar: without that, running the tabs to their end hands the wheel to the page
underneath and the whole panel lurches.

`Window.Scroll` is the body's scroller — `:To(Vector2)` to move it, and
`:SetEnabled(false)` to hand the wheel to something else.

## Escape hatches

```lua
Kuik.Screen()   -- the shared ScreenGui, if you want to add your own things
Kuik.Reset()    -- tear down every Kuik element and its blur
Kuik.New        -- the Instance constructor helper
Kuik.Tween      -- the shared tween helper, on the library's one curve
```

## Tests

```
lune run tests/build    # builds every component headlessly, 134 checks
lune run tests/parse    # syntax-checks the demo scripts
```

`tests/shim.luau` fakes enough of the Roblox environment to construct the whole
library under lune. It is **not** a renderer — `AbsoluteSize` and
`AbsolutePosition` are always zero — so it catches syntax errors, bad property
names, nil indexing and broken control flow, but never layout or appearance.
Anything visual still has to be checked in Studio.

## Known limits

- **Tabs scroll, they do not wrap.** Past about five tabs the bar overflows and
  becomes horizontally scrollable — the wheel is mapped onto X, and selecting a
  tab from code scrolls it into view. The reference never has more than four.
- **The tab bar scrolls with the body.** Sections, tabs and pages are all rows
  in the same scrolling body, which is what the reference does. Scroll far
  enough down and the tabs leave the screen.
- **The backdrop blur is global.** It is a `BlurEffect` in `Lighting`, owned by
  the window and destroyed with it, but while open it blurs the whole scene.
  Pass `Blur = 0` if the game already manages `Lighting`.
- **Parallax reads `workspace.CurrentCamera` every frame.** Cheap, but it is a
  `RenderStepped` connection per window.
- **Montserrat is assumed.** It is a built-in Roblox font family; if you would
  rather not depend on it, set `Theme.Font` to a `Enum.Font` variant.
