--!nonstrict
--- Controls/init.luau — the registry.
---
--- Every name in here becomes a method on every container: a window, a page, a
--- section, an accordion. Adding a control is adding it to one of the files
--- below; nothing else has to know.

local Controls = {}

local Sets = {
	require(script.Inputs),
	require(script.Data),
	require(script.Colour),
	require(script.Pickers),
	require(script.Media),
	require(script.Content),
	require(script.More),
	require(script.Play),
}

for _, Set in Sets do
	for Name, Constructor in Set do
		Controls[Name] = Constructor
	end
end

return Controls
