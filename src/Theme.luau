--!nonstrict
--- Theme.luau — every colour, size and motion number Kuik draws with.
---
--- The token tables are mutated in place rather than replaced, so anything
--- holding a reference to them keeps seeing the current theme. Objects painted
--- with a token are remembered in a weak registry, which is what lets
--- Kuik.SetTheme repaint a UI that is already on screen.

local Palette = {}

--- Colour tokens. Everything visible resolves to one of these, so a theme is
--- nothing more than a different set of values under the same names.
local Theme = {
	Font       = Font.fromName("Montserrat", Enum.FontWeight.Regular),
	FontMedium = Font.fromName("Montserrat", Enum.FontWeight.Medium),
	FontBold   = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
	FontMono   = Font.fromEnum(Enum.Font.Code),

	--- Ink and ground. White is what type and rules are drawn in; Black backs
	--- the chips and knobs; Scrim is the wash behind a window.
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(20, 20, 20),
	Scrim = Color3.fromRGB(8, 8, 10),

	--- Type is transparency over White, not a second colour, so it stays
	--- correct over any backdrop.
	TextPrimary   = 0.00,
	TextSecondary = 0.42,
	TextTertiary  = 0.58,
	TextDisabled  = 0.72,

	RuleTransparency = 0.45,

	RowTransparency      = 0.94,
	RowHoverTransparency = 0.88,
	RowPressTransparency = 0.82,

	ChipTransparency = 0.45,

	--- Media wells: the dark plate an image or viewport sits on. Set
	--- EmbedTransparency to 1 for embeds with no plate at all.
	EmbedColor        = Color3.fromRGB(20, 20, 20),
	EmbedTransparency = 0.65,

	Danger  = Color3.fromRGB(255, 72, 72),
	Warn    = Color3.fromRGB(255, 176, 46),
	Info    = Color3.fromRGB(96, 156, 255),
	Good    = Color3.fromRGB(96, 210, 128),
	Neutral = Color3.fromRGB(255, 255, 255),
	Accent  = Color3.fromRGB(255, 255, 255),

	--- Named motion. Anything with a Duration is a tween; anything with a
	--- Stiffness is a spring, which is what most of the library uses.
	--- Everything the library moves, moves on a spring. A spring retargets in
	--- flight instead of restarting, so a value that changes twice in three
	--- frames bends toward the new goal rather than stuttering — which is the
	--- whole reason these are not tweens.
	---
	--- Damping is read as a ratio against the frequency: at 2 * sqrt(Stiffness)
	--- a spring is critically damped and never overshoots. Anything that moves
	--- a transparency or a colour is kept at or above critical, because an
	--- overshoot there clips at the end of the range and reads as a flicker.
	--- Anything that moves a position or a size is allowed to overshoot a
	--- little, because that is what makes it feel alive.
	Motion = {
		instant = { Duration = 0 },

		enter  = { Stiffness = 170,  Damping = 24 },
		exit   = { Stiffness = 250,  Damping = 32 },
		expand = { Stiffness = 310,  Damping = 34 },
		hint   = { Stiffness = 740,  Damping = 56 },
		item   = { Stiffness = 400,  Damping = 40 },
		list   = { Stiffness = 460,  Damping = 43 },
		drop   = { Stiffness = 170,  Damping = 19 },

		--- At or above critical: these carry transparency and colour.
		hover  = { Stiffness = 2500, Damping = 100 },
		press  = { Stiffness = 7300, Damping = 171 },
		fade   = { Stiffness = 310,  Damping = 36 },
		tint   = { Stiffness = 420,  Damping = 42 },

		--- The white layer. These four came off a frame table rather than out of
		--- the air: a plate snaps wide in about an eighth of a second, opens
		--- down in about a fifth, and burns off in about a quarter.
		plate  = { Stiffness = 5000, Damping = 142 },
		open   = { Stiffness = 1500, Damping = 78 },
		burn   = { Stiffness = 200,  Damping = 29 },
		smear  = { Stiffness = 400,  Damping = 40 },
		sweep  = { Stiffness = 294,  Damping = 34 },

		--- A white bar closing to nothing. Fitted against eleven frames of the
		--- reference and it lands within a pixel or two on every one of them.
		close  = { Stiffness = 144,  Damping = 24 },

		layout = { Stiffness = 190, Damping = 24 },
		morph  = { Stiffness = 210, Damping = 26 },
		drag   = { Stiffness = 620, Damping = 42 },
		toss   = { Stiffness = 340, Damping = 22 },
		reveal = { Stiffness = 150, Damping = 20 },
		snap   = { Stiffness = 600, Damping = 40 },
		pop    = { Stiffness = 420, Damping = 28 },
		shrink = { Stiffness = 520, Damping = 46 },

		--- Deliberately over critical: the wheel should never overshoot.
		scroll = { Stiffness = 300, Damping = 38 },
	},
}

--- Sizes. Radii live here too, which is why squaring off the whole library is
--- three numbers rather than a search across forty files.
local Metrics = {
	--- Whether a panel arrives as a white plate rather than by fading up. On,
	--- because it is the single thing that makes the library look like the house
	--- it is modelled on — but only for windows that are panels: a HUD element
	--- with no chrome opens without ceremony, and a Bare or Panel variant is
	--- therefore left alone whatever this says.
	Reveal        = true,

	--- How every overlay — menu, popover, sheet, drawer, prompt — is dressed
	--- unless it says otherwise. "Card" is a dark plate; "Rules" is the house
	--- style, two hairlines and almost no fill.
	OverlayVariant = "Card",

	WindowWidth   = 460,
	WindowHeight  = 500,
	WindowPadding = 26,

	TitleSize    = 27,
	SubtitleSize = 14,

	SectionTitleSize = 18,
	SectionDescSize  = 12,

	--- The type scale. Every size in the library is one of these names, never
	--- an offset from another one: a caption that is "RowDescSize - 3" cannot
	--- be tuned without doing arithmetic in your head at forty call sites.
	RowLabelSize = 16,
	RowDescSize  = 16,
	SubheadSize  = 14,
	BodySize     = 15,
	ValueSize    = 14,
	CaptionSize  = 13,
	TinySize     = 11,
	RowHeight    = 46,
	RowHeightTall = 62,
	RowGap       = 16,
	RowPadding   = 14,
	RowRadius    = 0,
	CardRadius   = 0,
	PillRadius   = 0,

	TabHeight  = 30,
	TabPadding = 14,
	TabGap     = 6,
	TabIcon    = 14,

	ToggleWidth  = 50,
	ToggleHeight = 25,
	KnobInset    = 3,
	CheckSize    = 18,

	SliderTrack = 3,
	SliderThumbWidth  = 4,
	SliderThumbHeight = 15,

	ChipWidth  = 52,
	ChipHeight = 23,
	ChipRadius = 5,

	--- Monospaced sizes: the small readouts the library sets numbers in.
	MonoSize      = 10,
	MonoBoldSize  = 11,
	MonoLargeSize = 12,

	--- The one oversized readout in the library: an ammo count.
	CountSize = 22,

	StrokeThickness = 1,
}

Palette.Tokens  = Theme
Palette.Metrics = Metrics

--- The properties worth repainting. Colour properties are matched by value,
--- which is reliable because theme colours are distinctive; transparency is
--- matched only against the named text and surface tokens.
local COLOUR_PROPERTIES = {
	"BackgroundColor3",
	"TextColor3",
	"ImageColor3",
	"PlaceholderColor3",
	"BorderColor3",
	"Color",
}

local ALPHA_PROPERTIES = {
	"BackgroundTransparency",
	"TextTransparency",
	"ImageTransparency",
	"Transparency",
}

local COLOUR_TOKENS = {
	"White", "Black", "Scrim", "EmbedColor",
	"Danger", "Warn", "Info", "Good", "Neutral", "Accent",
}

--- 0 is left out on purpose: it means "fully opaque" far more often than it
--- means "primary type", and repainting every opaque thing would be wrong.
local ALPHA_TOKENS = {
	"TextSecondary", "TextTertiary", "TextDisabled",
	"RuleTransparency",
	"RowTransparency", "RowHoverTransparency", "RowPressTransparency",
	"ChipTransparency",
	"EmbedTransparency",
}

--- Object -> { [Property] = Token }. Weak keys, so a destroyed instance drops
--- out of the registry on its own.
local Painted = setmetatable({}, { __mode = "k" })

--- Records anything drawn in a theme colour so SetTheme can find it again.
--- Called by Util.New for every object it builds, which is all of them.
function Palette.Track(Object, Properties)
	local Record = nil

	--- Matched by value rather than by type: equality with a known colour
	--- token is itself the type check, and it is the only form that works
	--- headlessly, where typeof cannot be shimmed.
	for _, Property in COLOUR_PROPERTIES do
		local Value = Properties[Property]

		if Value ~= nil then
			for _, Token in COLOUR_TOKENS do
				if Theme[Token] == Value then
					Record = Record or {}
					Record[Property] = Token
					break
				end
			end
		end
	end

	for _, Property in ALPHA_PROPERTIES do
		local Value = Properties[Property]

		if type(Value) == "number" then
			for _, Token in ALPHA_TOKENS do
				if Theme[Token] == Value then
					Record = Record or {}
					Record[Property] = Token
					break
				end
			end
		end
	end

	if Record then
		Painted[Object] = Record
	end
end

--- Paints an object with tokens by name, for the places that set a colour
--- after construction and still want it to follow the theme.
function Palette.Paint(Object, Map)
	local Record = Painted[Object] or {}

	for Property, Token in Map do
		Record[Property] = Token
		Object[Property] = Theme[Token]
	end

	Painted[Object] = Record
end

--- Stops an object following the theme, for a colour the caller owns.
function Palette.Release(Object)
	Painted[Object] = nil
end

--- The presets. A theme is a sparse overlay: anything it leaves out keeps the
--- default, so a two-line theme is a perfectly good theme.
Palette.Themes = {
	Remorse = {},

	Redliner = {
		Accent = Color3.fromRGB(255, 62, 62),
		Info   = Color3.fromRGB(255, 62, 62),
		Scrim  = Color3.fromRGB(10, 6, 6),
		Black  = Color3.fromRGB(24, 16, 16),
	},

	Ember = {
		Accent = Color3.fromRGB(255, 138, 46),
		Info   = Color3.fromRGB(255, 138, 46),
		Scrim  = Color3.fromRGB(14, 9, 5),
		Black  = Color3.fromRGB(28, 20, 14),
	},

	Terminal = {
		White  = Color3.fromRGB(198, 255, 208),
		Accent = Color3.fromRGB(96, 255, 140),
		Info   = Color3.fromRGB(96, 255, 140),
		Scrim  = Color3.fromRGB(2, 10, 4),
		Black  = Color3.fromRGB(8, 22, 12),
		Font       = Font.fromEnum(Enum.Font.Code),
		FontMedium = Font.fromEnum(Enum.Font.Code),
		FontBold   = Font.fromEnum(Enum.Font.Code),
	},

	Midnight = {
		White  = Color3.fromRGB(226, 232, 255),
		Accent = Color3.fromRGB(122, 162, 255),
		Info   = Color3.fromRGB(122, 162, 255),
		Scrim  = Color3.fromRGB(6, 8, 18),
		Black  = Color3.fromRGB(18, 22, 40),
	},

	--- Ink on paper. The one theme that flips the polarity, so it also flips
	--- the surface transparencies to keep contrast.
	Paper = {
		White = Color3.fromRGB(24, 24, 26),
		Black = Color3.fromRGB(248, 248, 250),
		Scrim = Color3.fromRGB(244, 244, 246),
		EmbedColor        = Color3.fromRGB(228, 228, 232),
		EmbedTransparency = 0.15,
		RowTransparency      = 0.92,
		RowHoverTransparency = 0.86,
		RowPressTransparency = 0.80,
		ChipTransparency     = 0.88,
		RuleTransparency     = 0.78,
		Accent = Color3.fromRGB(24, 24, 26),
		Info   = Color3.fromRGB(40, 90, 200),
		Good   = Color3.fromRGB(28, 140, 70),
		Warn   = Color3.fromRGB(180, 110, 0),
		Danger = Color3.fromRGB(200, 40, 40),
	},
}

--- A copy of the defaults, so applying a sparse theme can restore whatever the
--- previous one had changed.
local Defaults = {}

for Key, Value in Theme do
	if Key ~= "Motion" then
		Defaults[Key] = Value
	end
end

local Listeners = {}
local Current = "Remorse"

--- Called after a theme lands, for the handful of things that redraw rather
--- than repaint — gradients, charts, anything built from a colour rather than
--- painted in one.
function Palette.OnChange(Handler)
	table.insert(Listeners, Handler)

	return function()
		local At = table.find(Listeners, Handler)

		if At then
			table.remove(Listeners, At)
		end
	end
end

function Palette.Name()
	return Current
end

--- Applies a theme by name or by table. Every tracked object is repainted, so
--- a live UI changes under you rather than needing a rebuild.
---
--- Repaint is the caller's choice: pass false to change the tokens without
--- touching what is already drawn, which is what you want before the first
--- window is built.
function Palette.Set(Theme_, Repaint)
	local Overlay = Theme_

	if type(Theme_) == "string" then
		Overlay = Palette.Themes[Theme_]

		if not Overlay then
			return false
		end

		Current = Theme_
	else
		Current = "Custom"
	end

	--- Restore first, then overlay, so themes never leak into each other.
	for Key, Value in Defaults do
		Theme[Key] = Value
	end

	for Key, Value in Overlay do
		if Key == "Motion" then
			for Role, Spec in Value do
				Theme.Motion[Role] = Spec
			end
		elseif Key == "Metrics" then
			for Name, Number in Value do
				Metrics[Name] = Number
			end
		else
			Theme[Key] = Value
		end
	end

	if Repaint ~= false then
		for Object, Record in Painted do
			if Object.Parent then
				for Property, Token in Record do
					local Value = Theme[Token]

					--- Fonts and anything non paintable are set outright;
					--- colours and alphas are the only tweened kinds.
					local Ok = pcall(function()
						Object[Property] = Value
					end)

					if not Ok then
						Record[Property] = nil
					end
				end
			else
				Painted[Object] = nil
			end
		end
	end

	for _, Handler in Listeners do
		task.spawn(Handler, Theme)
	end

	return true
end

--- Registers a theme of your own under a name, so it works with SetTheme like
--- any of the built in ones.
function Palette.Register(Name, Overlay)
	Palette.Themes[Name] = Overlay
end

return Palette
