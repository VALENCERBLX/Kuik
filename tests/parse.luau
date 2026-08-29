--!nonstrict
--[[
	Syntax check for the scripts in demo/.

	They cannot actually run under the shim — they require the module by
	Instance, which lune has no equivalent for — but loading one still forces
	a full parse. A syntax error surfaces as a compile error before any line
	executes, so an error reported against a line number means the file
	parsed fine and merely hit the shim's limits.

	Run with:  lune run tests/parse
]]

local Process = require("@lune/process")

local Shim = require("./shim")
Shim.Install()

local Failures = 0

local function Parses(Name, Load)
	local Ok, Err = pcall(Load)

	if Ok then
		print(string.format("  ok    %s — parsed and ran", Name))
		return
	end

	local Message = tostring(Err)

	--- A runtime error carries a "<file>:<line>:" prefix; a compile error does not.
	if string.match(Message, Name .. ":%d+:") then
		print(string.format("  ok    %s — parsed (stopped at runtime, as expected)", Name))
		return
	end

	Failures += 1
	print(string.format("  FAIL  %s\n%s", Name, Message))
end

print("\ndemo scripts\n")

Parses("DemoSyntax", function() return require("./DemoSyntax") end)
Parses("ShowcaseSyntax", function() return require("./ShowcaseSyntax") end)

print(string.format("\n%d failures\n", Failures))

if Failures > 0 then
	Process.exit(1)
end
