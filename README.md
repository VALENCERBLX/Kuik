# Kuik

A Roblox UI library in the NO REMORSE house style: rules and type, almost no
fill, square by default, and everything moving on springs.

Two rules down the sides of a window, hairlines between things, white type at
four transparencies, and one accent colour you choose. No panels, no shadows,
no gradients except where a gradient is the point.

```lua
local Kuik = require(ReplicatedStorage.Kuik)

local Window = Kuik.Window({
    Title    = "Settings",
    Subtitle = "right shift to close",
    Key      = Enum.KeyCode.RightShift,
    Open     = true,
})

local Tabs = Window:Tabs()
local Audio = Tabs:Page("Audio")

Audio:Slider({
    Label    = "Master",
    Min      = 0,
    Max      = 100,
    Default  = 80,
    Callback = function(Value)
        SoundService.Volume = Value / 100
    end,
})
```

---

## Installing

Kuik is a folder of ModuleScripts. Put `src/` into your place as a
ModuleScript named `Kuik` with the rest of the modules inside it — Rojo does
this from the `default.project.json` in the repo:

```
Kuik/            (ModuleScript, from src/init.luau)
    Theme
    Motion
    Util
    Screen
    Scroll
    Shared
    Parts
    Layout
    Window
    Hud
    Layers
    Controls/    (ModuleScript, from src/Controls/init.luau)
        Inputs
        Data
        Colour
        Media
        Content
```

`tools/build.py` also emits two other shapes:

- `dist/Kuik.luau` — the whole library bundled into one file behind a tiny
  require shim, for dropping into a place by hand.
- `dist/modules.json` — every module keyed by its require path, for a script
  that builds the folder itself.

The bundle is past Roblox's 200,000 character limit for assigning `Source`
from a script, which is exactly why the library is a folder. Installing by
hand, through Rojo, or from `modules.json` all work; assigning the bundle to a
single `Source` from inside Studio does not.

---

## The shape of it

Everything is a **container**, and every container has the same methods. A
window, a page, a section, an accordion, a group, a column — you can put any
control in any of them:

```lua
local Page = Window:Tabs():Page("General")
local Section = Page:Section("Audio", "Anything that makes noise")
local Fold = Section:Accordion({ Label = "Advanced" })

Fold:Slider({ Label = "Reverb", Max = 1, Step = 0.05 })
```

Every control returns a **handle**. Handles have `Get`, `Set`, `Destroy`, and
the shared behaviour every one of them has:

```lua
local Toggle = Section:Toggle({ Label = "Enabled", Default = true })

Toggle:Get()                  --> true
Toggle:Set(false)             -- fires the callback
Toggle:Set(false, true)       -- silent
Toggle:SetVisible(false)
Toggle:SetDisabled(true)
Toggle:SetLabel("Renamed")
Toggle:SetDescription("...")
Toggle:Destroy()
```

---

## Windows are not only dialogs

A window is a rectangle you can put controls in. Strip the chrome and it is a
HUD element:

```lua
local Vitals = Kuik.Panel({
    Dock      = "BottomLeft",
    Position  = UDim2.new(0, 24, 1, -24),
    Width     = 240,
    Height    = 74,
    Draggable = true,
})

local Health = Vitals:Progress({ Label = "Health", Flat = true, Default = 1 })
```

`Kuik.Panel` is `Kuik.Window` with no header, no side rules, no backdrop, no
blur, no scroller, and no mouse unlock. Every one of those is an option on a
plain window too.

Windows can be moved, sized, docked, dragged, scaled, faded and stacked:

| Call | Does |
| --- | --- |
| `Window:SetPosition(UDim2, Animate)` | moves it; springs unless `Animate` is `false` |
| `Window:SetSize(W, H, Animate)` | resizes it |
| `Window:Dock("TopRight", 20)` | parks it against an edge or a corner |
| `Window:Nudge(X, Y)` | moves it relative to where it is |
| `Window:SetAnchor(Vector2)` | changes what the position means |
| `Window:SetScale(N)` / `SetOpacity(N)` | uniform scale, group fade |
| `Window:SetDraggable(true, Grip)` | drag by the header, or by a grip you pass |
| `Window:SetResizable(true)` | a grip in the bottom right corner |
| `Window:SetParallax(12)` | lags behind the camera and springs back |
| `Window:BringToFront()` | raises it above its siblings |
| `Window:SetTitle(Title, Subtitle)` | retitles it |
| `Window:SetFill(Colour, Alpha, Animate)` | gives it a ground |
| `Window:Destroy(Animate)` | immediate, or shrinks and fades out first |
| `Window:Child({ ... })` | a sub window parked beside it |
| `Window:GoTo("Audio")` | selects a page by name |
| `Window:Reveal(Handle)` | scrolls to a control and flashes it |

Docks are `Center`, `Top`, `Bottom`, `Left`, `Right`, `TopLeft`, `TopRight`,
`BottomLeft`, `BottomRight`.

Window variants: `Rules` (the default, two hairlines down the sides), `Card`
(filled, rounded, stroked), `Bare` / `Panel` (nothing at all).

**Overlays take a variant too.** A menu, popover, sheet, drawer or prompt is a
dark plate by default — that is what a game usually wants over its world — but
it can be the house style instead:

```lua
Kuik.Menu({ Items = …, Variant = "Rules" })   -- two hairlines, almost no fill
Kuik.Prompt({ Title = …, Variant = "Card" })  -- a prompt is Rules by default
Kuik.Metrics.OverlayVariant = "Rules"         -- or change all of them at once
```

A window does not leak input. Most of one is transparent frames, and a plain
`Frame` does not take input — so without help a click on the empty part of a
window sails straight through to whatever is underneath it, and so does hover.
Every window therefore carries a `Shield`: a button filling the panel, below
everything else in it, whose only job is to swallow what lands on the window.
Pass `Shield = false` if you genuinely want a window you can click through.

---

## Controls

Every name here is a method on every container.

**Input** — `Toggle` `Checkbox` `Switch` `Slider` `Range` `Stepper` `Input`
`TextArea` `Search` `Keybind` `Vector` `Dropdown` `Radio` `Chips` `Segmented`
`Tags`

**Data** — `Status` `Stat` `Badge` `Progress` `Meter` `Ring` `Spinner`
`Sparkline` `Graph` `Scatter` `Donut` `Bars` `Heatmap` `Rating` `Pagination`
`List` `Table` `Tree` `Timeline`

**Play** — the ones a game wants and an application does not:
`Leaderboard` `Slots` `Wallet` `Radial` `Versus`

```lua
-- A leaderboard never loses you: your row is pinned under a rule at the bottom,
-- however far down you actually are.
Page:Leaderboard({ Label = "Round", Me = Player.UserId, Entries = { … } })

-- An inventory grid. Empty cells are drawn, because three things and nine
-- spaces says something that three things does not.
Page:Slots({ Label = "Bag", Count = 12, Across = 6, Items = { … } })

-- Money that rolls to its new value and says what just changed, because a
-- number that simply becomes another number tells you nothing about the size
-- of what happened.
local Purse = Page:Wallet({ Label = "Kions", Default = 5250 })
Purse:Add(1750)

-- A wheel you pick from by direction rather than by position: hover highlights,
-- letting go commits, which is what makes emote wheels work at speed.
Page:Radial({ Label = "Emote", Items = { … }, Callback = fn })

-- One bar shared by two sides, growing from the middle out.
Page:Versus({ LeftLabel = "HOME", RightLabel = "AWAY", Left = 62, Right = 38 })
```

**Colour** — `Color` `ColorPicker` `Swatches` `Gradient`

**Media** — `Image` `Icon` `Gallery` `Zoom` `Viewport` `Video` `Audio`
`Marquee`

```lua
-- A gallery shows whole pictures, and a press opens one out of its own
-- thumbnail: it starts at exactly that cell's rectangle and springs to the
-- middle of the screen, so it reads as that picture getting bigger.
Section:Gallery({ Label = "Shots", Items = { … } })
Section:Gallery({ Label = "Shots", Items = { … }, Expand = false })

-- A carousel is a sliding strip, or a deck with the neighbours behind it.
Section:Carousel({ Label = "Shots", Items = { … } })
Section:Carousel({ Label = "Shots", Items = { … }, Variant = "Deck", Tilt = 2 })
```

```lua
-- A magnifier that tracks the pointer. The wheel changes the factor.
Section:Zoom({ Label = "Detail", Image = Id, Lens = 90, Factor = 2.5,
    Min = 1, Max = 8, Crosshair = true })

-- Or the picture itself, panned by dragging and scaled about the pointer,
-- with all four inside faces lit in proportion to the travel left that way.
Section:Zoom({ Label = "Map", Image = Id, Mode = "Pan", Factor = 1, Max = 6 })

Handle:SetFactor(4)   Handle:GetFactor()   Handle:Reset()   Handle:Set(Other)
```

Both modes only answer the pointer while it is actually over them — the wheel
used to move every zoom on screen at once, wherever the cursor was.

The wheel is the page's before it is the control's. A zoom in a scrolling page
that ate the wheel would silently stop the page scrolling whenever the pointer
crossed it, and quietly rescale the picture while someone was only trying to
read further down. So by default it takes the wheel **only while a control key
is held**: `Wheel = true` claims it outright, `Wheel = false` never takes it.

Two different questions are kept apart on purpose. *Whether* the pointer is
over the image is answered by `MouseEnter`/`MouseLeave`, because Roblox already
resolves what is on top: a window covering this one takes the hover and the
control below hears nothing. *Where* the pointer is comes from
`InputObject.Position`, which is measured from the same corner as
`AbsolutePosition`. `MouseMoved` is not — it reports the whole screen including
the top bar, so using it put the loupe a top bar's height below the cursor.

```lua
-- A split button does what its face says, and the caret changes its face.
local Deploy = Page:SplitButton({
    Label = "Deploy", Action = "Run",
    Items = { { Label = "Dry run" }, { Separator = true }, { Label = "Rollback" } },
    Callback = function(Item) … end,        -- runs the current item
    Chose = function(Item, Index) … end,    -- and fires when one is picked
    RunOnSelect = false,                    -- pick without running
})

Deploy:Select(2)   Deploy:Get()   Deploy:Run()   Deploy:SetAction("Ship")
```

Choosing from the menu retitles the button and runs what was chosen. An item
can carry its own `Callback`; otherwise the control's is called and told which
item it is running.

**More** — `Empty` `Confirm` `Sortable` `Skeleton` `LoadMore` `Motd` `Kbd`
`Well` `Split` `Group` `Columns`

```lua
-- The state a list is in before there is anything in it, which is worth saying
-- because a blank space is indistinguishable from a failed load.
Page:Empty({ Text = "No rounds yet", Detail = "Play one", Action = "Find a game" })

-- A button that will not do it until you say so twice, and disarms itself if
-- you walk away. The alternative to a modal for anything small and destructive.
Page:Confirm({ Label = "Delete save", Action = "Delete", Window = 3, Callback = fn })

-- A list you drag into a different order. The row you hold follows the pointer
-- and the rest spring aside, so the order you see is the order you will get.
Page:Sortable({ Label = "Loadout", Items = { … }, Callback = fn })
```

**Content** — `Button` `Rule` `Divider` `Gap` `Paragraph` `Quote` `Code`
`Alert` `Callout` `Accordion` `Breadcrumb` `Steps` `Avatar` `Link` `Toolbar`
`Header` `Group` `Columns`

### Variants

Most controls take a `Variant`:

```lua
Section:Toggle({ Label = "A",  Variant = "Switch" })   -- Switch, Check, Pill
Section:Button({ Label = "B",  Variant = "Rule" })     -- Pill, Solid, Outline,
                                                       -- Ghost, Text, Rule
Section:Alert({ Label = "C",   Variant = "Outline" })  -- Accent, Solid,
                                                       -- Outline, Subtle
Window:Tabs({ Variant = "Underline" })                 -- Pill, Underline, Rule
Section:Slider({ Label = "D",  Variant = "Ticks" })    -- Bar, Ticks
```

Rows and blocks take `Variant` too: `Filled`, `Flat`, `Outline`, `Solid`,
`Rule`.

### Rule buttons

The bracket style — a vertical rule either side of the label, filling in on
hover — comes in three shapes:

```lua
Section:Button({ Label = "Reset", Action = "Run", Variant = "Rule" })
Section:Rule({ Action = "Continue", Callback = Continue })   -- full width
Section:Divider({ Label = "or start over", Callback = Restart })
```

### Options every control takes

| Option | Does |
| --- | --- |
| `Label` `Description` | the text on the left |
| `Callback` | fired on change |
| `Default` | the starting value |
| `Variant` | the look |
| `Color` | the accent |
| `Radius` | corner radius, overriding the theme |
| `Visible` `Disabled` | starting state |
| `Tooltip` | a hint on hover |
| `Flat` | no fill behind the row |
| `Icon` | a small picture on the left |
| `LayoutOrder` | position in the flow, if you do not want declaration order |
| `Height` `Width` | size, where it means something |

### Embeds

Every embed decides its own plate, which is what the dark background behind an
image is:

```lua
Section:Image({ Image = Id })                              -- the default well
Section:Image({ Image = Id, Background = false })          -- no plate at all
Section:Image({ Image = Id, Background = Colour, BackgroundTransparency = 0.2 })

Handle:SetBackground(false)                                -- and after the fact
```

`Paragraph`, `Image`, `Icon`, `Gallery`, `Viewport`, `Video` and `Avatar` all
take the same three options.

### Links go anywhere

A link is not only a URL:

```lua
Page:Link({ Label = "Go to Audio",  Target = "Audio" })      -- a page
Page:Link({ Label = "Open detail",  Target = SomeWindow })   -- a window
Page:Link({ Label = "Find it",      Target = SomeControl })  -- scroll + flash
Page:Link({ Label = "Do it",        Target = function() end })
Page:Link({ Label = "Docs",         Url = "https://..." })
```

`Handle:Follow()` returns what it did: `"page"`, `"window"`, `"element"`,
`"action"`, `"url"`, `"blocked"` or `"missing"`.

---

## Layers

```lua
Kuik.Prompt({
    Title = "Leave the match?",
    Text  = "Your progress this round will not be saved.",
    Buttons = {
        { Label = "Stay" },
        { Label = "Leave", Primary = true, Value = "leave" },
    },
    Callback = function(Choice) end,
})
```

A prompt is genuinely modal: nothing behind it scrolls, no keybind fires, and
`Kuik.Blocked()` is true for as long as it is up.

```lua
local Menu = Kuik.Menu({
    Items = {
        { Label = "Inspect", Shortcut = "I" },
        { Separator = true },
        { Label = "Delete", Color = Kuik.Theme.Danger },
    },
})

Menu:ShowAtMouse()
```

```lua
local Deck = Kuik.Cards({ Gap = 90 })

Deck:Add(Kuik.Window({ Title = "One" }))
Deck:Add(Kuik.Window({ Title = "Two" }))

Deck:Next()        -- or the left and right arrows, or Q and E
```

A deck opens the cards you add to it, keeps them in a carousel, and destroys
them with itself unless you pass `Deck:Destroy(true)` — `Deck:Destroy(false, true)`
animates them out instead. Every card but the one in focus wears a grey wash,
and that wash is the same object that stops a shrunk card being clicked, so a
card is exactly as interactive as it looks.

---

## HUD

None of these live in a window:

`Toast` `Notify` `Hints` `Log` `Feed` `Arrival` `Console` `Watermark` `Bar`
`Timer` `Ammo` `Crosshair` `Killfeed` `Objective` `Vignette` `Compass` `Fab`
`Viewfinder`

```lua
-- Hints are not only keybinds. A hint is a badge and a line, and the badge can
-- be a key, a chord, a mouse button, an icon, or nothing at all.
local Hints = Kuik.Hints({ Side = "Right", Align = "Center" })

Hints:Add("E", "interact")
Hints:Add({ Keys = { "Ctrl", "S" }, Action = "save" })
Hints:Add({ Mouse = "Left", Action = "fire" })
Hints:Add({ Icon = Id, Action = "equip" })
Hints:Add({ Action = "the door is locked" })          -- no badge, just a line

local Pick = Hints:Add({ Hold = "F", Action = "pick up" })
Pick:SetProgress(0.4)                                  -- fills as it is held

Hints:Set({ … })   -- replace the whole rail, which is what a context change wants
```

```lua
-- Centred notices that stack upward and expire. The newest wears a hairline
-- that runs out from behind it and fades at both ends.
local Feed = Kuik.Feed({ Limit = 5, Life = 4 })

Feed:Push("You've earned: 7,000 Kions")
Feed:Push("After Tax: 5,250 Kions", { Color = Theme.Good })

-- The loading screen, laid out where the reference lays it out: a bracketed
-- status chip at 9% down, the title dead centre, fine print along the bottom.
local Arrival = Kuik.Arrival({
    Title    = 'You\'re arriving at "West Haven Offices"',
    Subtitle = "Placing you in the level",
    Status   = "Loaded West Haven Offices",
    Footer   = { "a line", "and another" },
})

Arrival:SetProgress(0.4)   Arrival:SetStatus("Placing you")   Arrival:Done(fn)
```

An arrival screen does not fade its chip up — a white bar over it **closes to
nothing**, uncovering it. That is the plate's gesture played backwards, and it
is what the reference uses to cover a cut: one frame to black, then the bar
shuts. `Kuik.Close` is that on its own, for anything else you want uncovered
rather than faded in.

```lua
local Health = Kuik.Bar({ Label = "HEALTH", Max = 100, Warn = 0.5, Danger = 0.25 })
Health:Set(62)

Kuik.Toast("picked up a key", { Duration = 2 })
Kuik.Notify({ Title = "Saved", Text = "Everything is up to date." })
```

---

## Themes

A theme is a sparse overlay on the token table. Applying one repaints
everything already on screen:

```lua
Kuik.SetTheme("Terminal")

Kuik.RegisterTheme("Studio", {
    Accent = Color3.fromRGB(120, 200, 255),
    Scrim  = Color3.fromRGB(8, 10, 16),
})

Kuik.SetTheme("Studio")
```

Built in: `Remorse` (the default), `Redliner`, `Ember`, `Terminal`,
`Midnight`, `Paper`.

Tokens are mutated in place, so anything holding a reference to `Kuik.Theme`
keeps seeing the current values. Objects painted with a token are tracked in a
weak registry, which is what lets a live UI change under you.

Squaring the whole library off, or rounding it, is three numbers:

```lua
Kuik.Metrics.RowRadius  = 0
Kuik.Metrics.CardRadius = 0
Kuik.Metrics.PillRadius = 0
```

---

## Motion

**Everything moves on a spring.** A spring is stepped on `Heartbeat` by an
analytic damped harmonic oscillator, and it retargets mid flight instead of
restarting — so a value that changes twice in three frames bends toward the new
goal rather than stuttering. That is the whole reason these are not tweens.

A role with a `Duration` still resolves to a tween if you ask for one; the
library itself only does that for `instant`.

```lua
Kuik.Tween(Object, { Position = UDim2.new(0, 40, 0, 0) }, "layout")
Kuik.Tween(Object, { Size = UDim2.new(1, 0, 0, 40) }, { Stiffness = 190, Damping = 24 })
Kuik.Tween(Object, { BackgroundTransparency = 0 }, { Duration = 0.3, Easing = "outQuint" })
```

Named roles: `instant` (the one tween), then `enter` `exit` `expand` `hint`
`item` `list` `drop` `hover` `press` `fade` `tint` `layout` `morph` `drag`
`toss` `reveal` `snap` `pop` `shrink` `scroll`, and the white layer's own
`plate` `open` `burn` `smear` `sweep`.

Damping is read against the frequency: at `2 * sqrt(Stiffness)` a spring is
critically damped and never overshoots. Roles that carry a transparency or a
colour — `hover`, `press`, `fade`, `tint`, `scroll` — are kept at or above
critical, because an overshoot there clips at the end of the range and reads as
a flicker. Roles that carry a position or a size are allowed to overshoot a
little, because that is what makes them feel alive. There is a test for it.

### The white layer

A white shape stands in for something for a moment, and then hands over to it.
Every timing in here was measured off recordings frame by frame rather than
chosen — the frame tables, and how closely this reproduces them, are in
[MOTION.md](MOTION.md).

**Panels do this by default.** A window with chrome — the `Rules` and `Card`
variants — arrives as a plate; a `Bare` or `Panel` variant does not, because a
health bar that flashes white every time it appears would be ridiculous. Turn it
off anywhere with `Reveal = false`, or library-wide with
`Kuik.Metrics.Reveal = false`.

```lua
-- The plate grows wide, opens down, and burns off while the window resolves
-- underneath it. From makes it drift on from whatever opened it.
Kuik.Window({ Title = "Settings", Reveal = { From = Button.Frame }, Open = true })

-- Any control can do it too.
Page:Toggle({ Label = "Arrived", Reveal = true })

-- A menu, given the rectangle it is about to occupy.
Kuik.Menu({ Items = …, Reveal = true })
```

Three details carry the plate, and all three came out of the frame table rather
than out of taste: it never starts from a dot (it appears already 56% wide and
31% open), it is only about 60% white when it appears, and the burn starts as
the height starts — so the panel is showing through before the plate has
finished moving. That last one is what makes it read as the plate *becoming* the
panel rather than sitting in front of it.

The rest of the layer:

```lua
Kuik.Follow(Object)          -- a white ghost that trails it while it moves
Kuik.Ghost(Object)           -- one afterimage stamped where it was
Kuik.Trail(Object)           -- a ghost stamped every frame while it moves
Kuik.Wipe(Object)            -- a bar sweeps across and leaves it uncovered
Kuik.Flash({ Hold = 0.17, Covered = fn })   -- full white, held, then decays
Kuik.Plate(Object, Options)  -- the reveal, by hand
```

`Follow` is what a tab bar's highlight wears: it chases on a soft exponential
rather than a spring, because a spring would overshoot and arrive *ahead* of the
thing it is trailing, which is the one thing an afterimage must never do. It is
invisible at rest, stretches to span the gap it has not covered yet, and lets go
of the frame loop as soon as it catches up — so a tab bar nobody is touching
costs nothing. Turn it off with `Ghost = false` on the tab bar.

A flash **holds** before it decays. One frame to full, about five held, then
seven of decay: without the hold it is a blink, and a blink cannot hide a cut
behind it. `Covered` runs at the top of the hold, while the screen is solid.

### Arriving, leaving, scaling, repainting

```lua
Motion.Pop(Object)                     -- grow into place from slightly small
Motion.Scale(Object, 1.2)              -- spring a UIScale, layout untouched
Motion.FadeIn(Object, 0.05)            -- the object and everything inside it
Motion.Fade(Object, 1)                 -- and back out again
Motion.Out(Object, function() … end)   -- shrink and fade, then call back
Motion.Paint(Object, { BackgroundColor3 = Colour }, Animate)
Motion.Halt(Object, "Position")        -- let go of it where it stands
```

`Motion.Paint` is the rule for every direct set in the library: **a direct
assignment must cancel any spring already running on that property**, or the
spring lands on top of it a frame later and the set looks ignored.

### Asking for it explicitly

Creation and destruction are still immediate by default, because a control that
lingers after the code that removed it has moved on is a bug every other time.
Say so and they animate:

```lua
Page:Toggle({ Label = "Arrives", Enter = true })   -- or Enter = "drop"
Handle:Destroy(true)                              -- shrink and fade, then go
Window:Destroy(true)                              -- the same, for a window

Handle:Set("value", Theme.Good, true)             -- spring the colour across
Handle:SetColor(Theme.Danger, true)
Window:SetFill(Colour, 0.1, true)
```

Rows arriving in a page are staggered for you: selecting a page fades the first
nine rows in, one behind the next, contents and all.

---

## Writing your own control

The registry is open. Anything you add becomes a method on every container
built afterwards:

```lua
Kuik.Register("Sticker", function(Container, Options, Owner)
    local Built = Kuik.Row(Container, Options)
    Built:Reserve(40)

    local Handle = {}

    return Kuik.Parts.Common(Handle, Built.Frame, Options, {
        Label = Built.Label,
        Description = Built.Description,
    })
end)

Page:Sticker({ Label = "Mine" })
```

`Kuik.Row` and `Kuik.Block` are the two shells everything else is built from;
`Kuik.Parts.Common` mixes in the shared handle behaviour.

---

## Layout

```
src/
    init.luau      the public surface
    Theme.luau     tokens, presets, the repaint registry
    Motion.luau    easings, the spring solver, Tween
    Util.luau      New, and the small helpers
    Screen.luau    the ScreenGui, and the modal count
    Scroll.luau    smooth wheel scrolling and the edge gleams
    Shared.luau    the seam that keeps the module graph acyclic
    Parts.luau     Row, Block, and the shared handle behaviour
    Layout.luau    Attach, sections, tab bars
    Window.luau    windows and panels
    Hud.luau       the screen furniture
    Layers.luau    menus, prompts, card decks
    Controls/      the registry, in five files

tests/
    build.luau     279 checks against the built library
    parse.luau     a syntax check over demo/
    shim.luau      enough of Roblox to run headlessly under lune

tools/
    build.py       builds dist/
```

Tests run under [lune](https://lune-rs.com):

```
python3 tools/build.py && lune run tests/build
```

The shim has no layout engine — `AbsoluteSize` is always zero and nothing is
ever measured — so the suite proves construction and logic, never appearance.
Anything about how it looks has to be checked in Studio.

---

MIT © 2026 kr3ative
