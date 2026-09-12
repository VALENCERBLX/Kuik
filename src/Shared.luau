--!nonstrict
--- Shared.luau — the seam that keeps the module graph acyclic.
---
--- Controls need Attach, Attach lives in Layout, and Layout is built out of
--- Controls. Rather than a require cycle, Layout writes itself in here and the
--- controls read it at call time, by which point everything is loaded.

local Shared = {}

--- Filled in by the modules that own them:
---   Shared.Attach  (Object) -> Object          Layout
---   Shared.Window  (Options) -> Window         Window
---   Shared.Tabs    (Owner, Options) -> Tabs    Layout
---   Shared.Section (Owner, ...) -> Section     Layout

return Shared
