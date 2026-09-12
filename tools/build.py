#!/usr/bin/env python3
"""Builds the two installable copies of Kuik from src/.

    dist/Kuik.luau     one ModuleScript, everything bundled behind a tiny
                       require shim. Drop it in and go.
    dist/modules.json  every module separately, for installing as a real
                       folder of ModuleScripts.

Roblox refuses a Source assignment of 200,000 characters or more, so the
bundle also has comments stripped. That is not a minifier: identifiers,
strings and layout inside statements are untouched, so a stack trace still
points at recognisable code. Split installs keep the comments.

    python3 tools/build.py
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "src")
DIST = os.path.join(ROOT, "dist")

LIMIT = 200_000


def strip(text):
    """Removes Luau comments without touching comment-like text inside strings."""
    out = []
    i = 0
    n = len(text)

    while i < n:
        char = text[i]

        # Long bracket string: [[ ]] or [==[ ]==]
        if char == "[":
            match = re.match(r"\[(=*)\[", text[i:])
            if match:
                close = "]" + match.group(1) + "]"
                end = text.find(close, i + match.end())
                end = n if end == -1 else end + len(close)
                out.append(text[i:end])
                i = end
                continue

        if char in "\"'":
            quote = char
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == quote:
                    j += 1
                    break
                j += 1
            out.append(text[i:j])
            i = j
            continue

        if text.startswith("--", i):
            # A long comment: --[[ ]] or --[==[ ]==]
            match = re.match(r"--\[(=*)\[", text[i:])
            if match:
                close = "]" + match.group(1) + "]"
                end = text.find(close, i + match.end())
                i = n if end == -1 else end + len(close)
                continue

            # A line comment, up to but not including the newline.
            end = text.find("\n", i)
            i = n if end == -1 else end
            continue

        out.append(char)
        i += 1

    lines = []
    for line in "".join(out).split("\n"):
        line = line.rstrip()
        if line.strip():
            lines.append(line)

    return "\n".join(lines) + "\n"


def modules():
    """Every module in src/, keyed by its require path.

    src/init.luau            -> ""
    src/Theme.luau           -> "Theme"
    src/Controls/init.luau   -> "Controls"
    src/Controls/Inputs.luau -> "Controls/Inputs"
    """
    found = {}

    for base, _, names in os.walk(SOURCE):
        for name in sorted(names):
            if not name.endswith(".luau"):
                continue

            path = os.path.join(base, name)
            rel = os.path.relpath(path, SOURCE)[: -len(".luau")]
            parts = rel.split(os.sep)

            if parts[-1] == "init":
                parts = parts[:-1]

            with open(path, encoding="utf-8") as handle:
                found["/".join(parts)] = handle.read()

    return found


REQUIRE = re.compile(r"require\(\s*(script(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*\)")


def resolve(expr, here):
    """Turns a `script.Parent.Theme` style path into a module key.

    `here` is the module's own key as a list of segments; an init module is
    its directory, so its `script` is the folder rather than a leaf.
    """
    node = list(here)

    for token in expr.split(".")[1:]:
        if token == "Parent":
            if not node:
                raise ValueError("require walked above the root: " + expr)
            node.pop()
        else:
            node.append(token)

    return "/".join(node)


def rewrite(source, key, known):
    """Repoints every require in a module at the bundle's own loader."""

    def swap(match):
        target = resolve(match.group(1), key.split("/") if key else [])

        if target not in known:
            raise ValueError("%s requires %s, which does not exist" % (key or "init", target))

        return 'KuikRequire("%s")' % target

    return REQUIRE.sub(swap, source)


HEAD = """--!nonstrict
-- Kuik %s - bundled from src/ by tools/build.py.
-- Comments are stripped so the whole library fits inside Roblox's 200,000
-- character limit for a ModuleScript Source assignment.
-- Read src/ instead; that is the source of truth.
local KuikModules = {}
local KuikLoaded = {}
local function KuikRequire(Name)
\tlocal Cached = KuikLoaded[Name]
\tif Cached ~= nil then
\t\treturn Cached
\tend
\tlocal Factory = KuikModules[Name]
\tif not Factory then
\t\terror("Kuik: no module named " .. tostring(Name), 2)
\tend
\tlocal Result = Factory()
\tKuikLoaded[Name] = Result
\treturn Result
end
"""


def version(found):
    match = re.search(r'Version\s*=\s*"([^"]+)"', found.get("", ""))
    return match.group(1) if match else "0.0.0"


def main():
    found = modules()

    if "" not in found:
        sys.exit("src/init.luau is missing")

    known = set(found)
    os.makedirs(DIST, exist_ok=True)

    # The split install keeps its comments; only the bundle is stripped.
    manifest = {key: source for key, source in found.items()}

    with open(os.path.join(DIST, "modules.json"), "w", encoding="utf-8") as handle:
        json.dump(manifest, handle)

    pieces = [HEAD % version(found)]

    for key in sorted(found, key=lambda name: (name != "", name)):
        body = strip(rewrite(found[key], key, known))
        pieces.append('KuikModules["%s"] = function()\n%send\n' % (key, body))

    pieces.append('return KuikRequire("")\n')

    bundle = "".join(pieces)

    with open(os.path.join(DIST, "Kuik.luau"), "w", encoding="utf-8") as handle:
        handle.write(bundle)

    raw = sum(len(source) for source in found.values())
    size = len(bundle)

    print("%d modules, %d chars of source -> dist/Kuik.luau %d chars"
          % (len(found), raw, size))

    biggest = max(found.items(), key=lambda pair: len(pair[1]))
    print("largest module: %s at %d chars" % (biggest[0] or "init", len(biggest[1])))

    if size >= LIMIT:
        print("OVER the %d character Source limit by %d - install as a folder "
              "(dist/modules.json) instead" % (LIMIT, size - LIMIT))
        return 0

    print("fits the %d character Source limit with %d to spare" % (LIMIT, LIMIT - size))
    return 0


if __name__ == "__main__":
    sys.exit(main())
