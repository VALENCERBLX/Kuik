# The white layer

Everything in `src/Reveal.luau` was measured off recordings rather than
designed. This is where the numbers came from, so that anyone changing them
later can see what they are changing away from.

The source is five screen recordings of **NO REMORSE**, which is the house the
whole library is modelled on. They live in `~/Downloads` and are not in the
repo. Measurements were taken by decoding frames with `ffmpeg` and thresholding
pixels with `numpy` — a mask of near-white, low-saturation pixels, then the
contiguous span of columns and rows where that mask is dense. Scattered UI text
does not survive a density threshold; a solid plate does.

| file | size | rate | length |
| --- | --- | --- | --- |
| `Sequence 02_2.mp4` | 1920×1080 | 23.976 | 83.6 s |
| `Medal_brDHCildJR.mp4` | 1918×1030 | 30 | 89.2 s |
| `RobloxPlayerBeta_OmAxsXNNbI.mp4` | 1920×1008 | 30 | 16.5 s |
| `RobloxPlayerBeta_yHcRAI2aLj.mp4` | 1920×1010 | 30 | 7.7 s |
| `ScreenRecording_08-25-2026 12-07-31_1.mov` | 1044×480 | 58 | 17.8 s |

---

## The idea in one paragraph

A plain white shape stands in for something for a moment, and then hands over to
it. A panel opens as a white plate that grows and dissolves into the real panel.
A highlight that moves drags a white smear behind it. A cut is hidden behind a
white hold. The white is never decoration: it is always either the thing that is
about to be there, or the thing that just was. Nothing in the reference uses
white as a fill or a highlight colour at rest — the interface at rest is rules
and type on almost nothing, and the white only exists during a transition.

---

## Finding the moments

Rather than scrubbing by eye, every clip was swept for white events: decode the
whole thing small, take the fraction of near-white pixels per frame, and report
runs above the baseline. Three classes fell out, cleanly separated by how much
of the screen they cover.

    class                     white fraction   solid column span
    panel plate reveal            0.08–0.10          ~0.21
    full screen flash             0.97–1.00           1.00
    bright level geometry         0.07–0.32          0.10–0.69

The third class is a **false positive**, and it is worth recording as one. The
long runs in `Sequence` at 63–73 s and 76–82 s look like white events by pixel
count but are the white-walled office level, not interface. Checked frame by
frame afterwards: gameplay, a red damage wash, then black. A white-fraction
sweep cannot tell a UI plate from a lit wall, so every run it reports has to be
looked at before it is believed.

Events found:

| clip | time | what |
| --- | --- | --- |
| `Sequence` | 1.12–1.21 | settings panel plate reveal |
| `Sequence` | 25.96–31.29 | loading screen |
| `Sequence` | 63.12–73.04 | ~~end of round stats~~ bright level, not UI |
| `Sequence` | 76.62–82.17 | ~~final screen~~ bright level, not UI |
| `OmAxsXNNbI` | 8.42–8.71 | settings panel plate reveal |
| `Medal` | 12.17–12.42 | full screen flash |
| `Medal` | 42.75–43.04 | full screen flash |
| `Medal` | 76.42–76.71 | settings panel plate reveal |
| `Medal` | 80.12–80.42 | full screen flash |
| `yHcRAI2aLj` | 5.83–6.04 | full screen flash |

---

## The plate reveal

Three independent samples, all of the same 393 × 479 panel centred on the
screen. Sample 1 is 24 fps, samples 2 and 3 are 30 fps.

### Sample 1 — `Sequence 02_2.mp4` at t = 1.0

Plate rectangle and how white it is, per frame. Alpha is estimated from the mean
luminance inside the plate against the settled panel behind it.

| frame | dt (s) | width | height | alpha |
| --- | --- | --- | --- | --- |
| 5 | 0.167 | 221 | 149 | 0.60 |
| 6 | 0.209 | 349 | 149 | 0.89 |
| 7 | 0.250 | 391 | 164 | 0.96 |
| 8 | 0.292 | 393 | 267 | 0.91 |
| 9 | 0.334 | 393 | 438 | 0.73 |
| 10 | 0.375 | 393 | 470 | 0.60 |
| 11 | 0.417 | 393 | 479 | 0.48 |
| 12 | 0.459 | 393 | 479 | 0.41 |
| 13–14 | 0.50–0.54 | 393 | 479 | → 0 |

The width fits `outQuad` over three frames to three decimals: 0.562 / 0.888 /
0.995 of the final width at x = 1/3, 2/3, 1. As a critically damped spring that
is a stiffness near 5000.

### Sample 2 — `RobloxPlayerBeta_OmAxsXNNbI.mp4` at t = 8.42

The width readings here are polluted by other white UI on the same rows, but the
height is clean:

| frame | t | height |
| --- | --- | --- |
| 7 | 8.450 | 77 |
| 8 | 8.483 | 166 |
| 9 | 8.517 | 210 |
| 10 | 8.550 | 325 |
| 11 | 8.583 | 442 |
| 12 | 8.617 | 459 |
| 13 | 8.650 | 479 |

0.23 s for the height, against 0.25 s in sample 1.

### Sample 3 — `Medal_brDHCildJR.mp4` at t = 76.42

The cleanest of the three, and the only one that shows the plate arriving from
somewhere. `cx` is the plate's centre; the panel's final centre is 958.

| frame | t | width | cx | height | mean lum |
| --- | --- | --- | --- | --- | --- |
| 6 | 76.417 | 168 | 921 | 149 | 254.6 |
| 7 | 76.450 | 165 | 922 | 149 | 254.6 |
| 8 | 76.483 | 159 | 925 | 149 | 254.6 |
| 9 | 76.517 | 393 | 958 | 216 | 250.3 |
| 10 | 76.550 | 393 | 958 | 379 | 235.7 |
| 11 | 76.583 | 393 | 958 | 419 | 227.2 |
| 12 | 76.617 | 393 | 958 | 470 | 199.6 |
| 13 | 76.650 | 393 | 958 | 476 | 187.6 |
| 14 | 76.683 | 393 | 958 | 480 | 149.5 |

Two things to take from this one:

- **The seed bar is 149 px tall in both sample 1 and sample 3.** Same panel, so
  this cannot distinguish a fixed height from a fraction; the implementation
  uses a fraction (0.31), which happens to land on 148.5 for this panel and
  scales for others.
- **The plate starts about 37 px left of where the panel will be and drifts
  onto it** over three frames while it grows. This is the "it came from the
  thing you clicked" half of the effect, and it is small — tens of pixels, not
  a swoop across the screen.

### What the implementation produces

`Reveal.Plate` against sample 1, measured the same way through the test shim:

| frame | mine w / h / alpha | reference w / h / alpha | worst axis |
| --- | --- | --- | --- |
| 1 | 220 / 148 / 0.60 | 221 / 149 / 0.60 | 0.2% |
| 2 | 357 / 148 / 0.92 | 349 / 149 / 0.89 | 2.6% |
| 3 | 390 / 148 / 0.99 | 391 / 164 / 0.96 | 3.2% |
| 4 | 393 / 306 / 1.00 | 393 / 267 / 0.91 | 8.9% |
| 5 | 393 / 423 / 0.88 | 393 / 438 / 0.73 | 15.3% |
| 6 | 393 / 463 / 0.68 | 393 / 470 / 0.60 | 7.5% |
| 7 | 393 / 475 / 0.48 | 393 / 479 / 0.48 | 0.9% |
| 9 | 393 / 479 / 0.22 | 393 / 479 / 0.20 | 1.9% |
| 11 | 393 / 479 / 0.09 | 393 / 479 / 0.00 | 9.2% |

Worst single frame 15.3%, which is inside the noise of thresholding a compressed
24 fps capture. `tests/reveal.luau` holds this table as a regression guard.

### The three details that carry it

Each of these came out of the frame table, and each is the sort of thing that
gets left out when the effect is rebuilt from memory:

1. **It never starts from a dot.** The first visible frame is already 56% of the
   final width and 31% of the height. A plate that scales up from nothing reads
   as a box zooming in; a plate that starts as a bar reads as something being
   drawn.
2. **It is not opaque when it appears.** It comes in at about 60% white and
   reaches full as the width lands. Starting it opaque turns the whole gesture
   into a flash.
3. **The burn starts as the height starts,** not after it. The panel is already
   showing through before the plate has finished moving, which is what makes it
   read as the plate *becoming* the panel rather than sitting in front of it.

---

## The full screen flash

`Medal_brDHCildJR.mp4` at t = 42.7, 30 fps. `white frac` is the fraction of the
frame that is near-white; `lum` is the mean luminance.

| frame | t | lum | white frac |
| --- | --- | --- | --- |
| 7 | 42.700 | 64.0 | 0.002 |
| 8 | 42.733 | 180.2 | 0.934 |
| 9 | 42.767 | 169.4 | 0.975 |
| 10–13 | 42.80–42.90 | 169.3 | 0.976 |
| 14 | 42.933 | 143.1 | 0.260 |
| 15 | 42.967 | 120.7 | 0.033 |
| 16 | 43.000 | 105.1 | 0.020 |
| 17 | 43.033 | 95.3 | 0.016 |
| 20 | 43.133 | 66.6 | 0.006 |

So: **one frame to full, five frames held (0.17 s), then about seven frames of
decay.** The hold is the part that matters and the part that is easy to leave
out — without it the flash is a blink, and a blink cannot hide a scene change
behind it. `Reveal.Flash` takes a `Hold`, and runs a `Covered` callback at the
top of the hold, while the screen is solid.

The same shape appears three more times: `Medal` at 12.17 and 80.12, and
`yHcRAI2aLj` at 5.83, all six to eight frames long.

---

## Closing, and the arrival screen

The cut into the loading screen, `Sequence 02_2.mp4` at t = 20.6, 24 fps. The
screen goes black in a single frame, and a white bar over the status label's
position closes to nothing — so the label is uncovered rather than faded up.

| frame | t | bar width | centre x |
| --- | --- | --- | --- |
| 11 | 20.617 | 215 | 959.5 |
| 12 | 20.659 | 191 | 959.5 |
| 13 | 20.701 | 159 | 959.5 |
| 14 | 20.742 | 129 | 959.5 |
| 15 | 20.784 | 81 | 959.5 |
| 16 | 20.826 | 61 | 959.5 |
| 17 | 20.867 | 47 | 959.5 |
| 18 | 20.909 | 35 | 959.5 |
| 19 | 20.951 | 18 | 959.5 |
| 20 | 20.992 | 13 | 959.5 |
| 21 | 21.034 | 9 | 959.5 |

A critically damped spring at a stiffness of 144 fits every one of those to
within a pixel or two: 195, 158, 120, 87, 43, 20, 9 predicted against 191, 159,
129, 81, 47, 18, 9 measured. The height is held throughout — it closes like a
shutter, not like a box shrinking. `Reveal.Close`.

The screen it hands over to, measured on the settled frame:

| element | y | x | centred |
| --- | --- | --- | --- |
| status chip | 88–115 | 859–1060 | yes |
| title | 538–554 | 778–1143 | yes |
| subtitle | 581–590 | 829–1090 | yes |

So the chip's centre is at 9.4% of the screen and the title's at 50.6%. That is
`Hud.Arrival`, which reproduces both: measured live in a client afterwards, the
chip lands at 0.094 and the title at 0.499.

### One thing that had to be measured in a client, not in the footage

With `IgnoreGuiInset` set, Roblox moves a ScreenGui **up** by the inset and
leaves its size alone. Against a 1532 × 619 viewport with a 58 px bar, Kuik's
layer reports position `(0, -58)` and size `1532 × 619` — so a child sized
`(1, 0, 1, 0)` covers the bar at the top and leaves **exactly one inset
uncovered along the bottom**. Every full bleed thing in the library was doing
that: the flash, the vignette, every backdrop, and the arrival sheet. They all
go through `Screen.Cover` now, which makes them one inset taller than they look.

---

## The follow ghost

The user described "a white copy that follows a moving element, like an
afterimage". The evidence for it is **partial**: what the footage definitely
contains is the drift in sample 3 above, where the white plate trails onto the
panel's position rather than starting on it. A separate white silhouette
trailing a moving element was not isolated in any of the five clips, though the
two longest clips have long stretches (`Sequence` 63–82 s) that were only
surveyed, not measured frame by frame.

`Reveal.Follow` is therefore built from the principle rather than from a frame
table, and is honest about that. It is a white plate that chases an object on a
soft exponential rather than a spring — a spring would overshoot and arrive
*ahead* of the thing it is trailing, which is the one thing an afterimage must
never do. Its transparency is driven by how far behind it is, so it does not
exist at rest, and it stretches to span both where the object is and where the
ghost has got to, which is what turns a lagging copy into a smear rather than a
second object.

It also lets go of the frame loop as soon as it has caught up, and is woken by
the object's own geometry changing, so a tab bar nobody is touching costs
nothing.

---

## Token table

The roles these produced, as they appear in `src/Theme.luau`. Springs
throughout; settle time is `6 / sqrt(Stiffness)` and critical damping is
`2 * sqrt(Stiffness)`.

| role | stiffness | damping | settles | what it carries |
| --- | --- | --- | --- | --- |
| `plate` | 5000 | 142 | 0.085 s | the plate's width, and its fade to full white |
| `open` | 1500 | 78 | 0.155 s | the plate's height |
| `burn` | 200 | 29 | 0.42 s | the plate dissolving, a flash decaying |
| `smear` | 400 | 40 | 0.30 s | a stamped afterimage fading |
| `sweep` | 294 | 34 | 0.35 s | a wipe bar crossing something |
| `close` | 144 | 24 | 0.50 s | a white bar closing to nothing |

The choreography's two delays are expressed as multiples of the preceding
phase's settle time, so retuning a spring keeps the shape: the height starts at
`1.1 ×` the width's settle, and the burn starts with the height.

---

## What not to copy

- The **loading screen** (`Sequence` 26–31 s) and the **role reveal** are
  game-specific set pieces, not UI idioms. The progress bar underneath them is
  ordinary.
- The **red and green screen washes** at the end of a round are game state, not
  interface.
- The **red damage wash** at the end of a round is game state, not interface.
  `Hud.Vignette` already covers the shape of it.
- The `ScreenRecording` clip is a phone capture. Its two white events are the
  iOS control centre, not the game. It is still useful as a look at the mobile
  chat, which is where `Hud.Chat` came from, but it carries no motion evidence.
