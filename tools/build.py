#!/usr/bin/env python3
"""Builds dist/Kuik.luau — the installable copy.

Roblox refuses a Source assignment of 200,000 characters or more, and the
commented source is past that. This strips comments and blank lines so the
library can be written straight into a ModuleScript, leaving init.luau as the
readable source of truth.

Not a minifier: identifiers, strings and layout inside statements are
untouched, so a stack trace still points at recognisable code.

    python3 tools/build.py
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "init.luau")
TARGET = os.path.join(ROOT, "dist", "Kuik.luau")


def strip(text):
    """Removes Luau comments without touching comment-like text inside strings."""
    out = []
    i = 0
    n = len(text)

    while i < n:
        char = text[i]

        # --- short and long strings pass through verbatim
        if char in "'\"":
            quote = char
            out.append(char)
            i += 1

            while i < n:
                if text[i] == "\\" and i + 1 < n:
                    out.append(text[i:i + 2])
                    i += 2
                    continue

                out.append(text[i])

                if text[i] == quote:
                    i += 1
                    break

                i += 1

            continue

        if char == "[" and i + 1 < n and text[i + 1] in "[=":
            level = 0
            j = i + 1

            while j < n and text[j] == "=":
                level += 1
                j += 1

            if j < n and text[j] == "[":
                close = "]" + "=" * level + "]"
                end = text.find(close, j + 1)
                end = n if end == -1 else end + len(close)
                out.append(text[i:end])
                i = end
                continue

        # --- comments
        if char == "-" and i + 1 < n and text[i + 1] == "-":
            j = i + 2
            level = 0

            if j < n and text[j] == "[":
                k = j + 1

                while k < n and text[k] == "=":
                    level += 1
                    k += 1

                if k < n and text[k] == "[":
                    close = "]" + "=" * level + "]"
                    end = text.find(close, k + 1)
                    i = n if end == -1 else end + len(close)
                    continue

            end = text.find("\n", i)
            i = n if end == -1 else end
            continue

        out.append(char)
        i += 1

    return "".join(out)


def main():
    with open(SOURCE, encoding="utf-8") as handle:
        source = handle.read()

    stripped = strip(source)

    lines = []
    for line in stripped.split("\n"):
        line = line.rstrip()

        if line.strip():
            lines.append(line)

    header = (
        "--!nonstrict\n"
        "-- Kuik 1.0.0 — built from init.luau by tools/build.py.\n"
        "-- Comments are stripped so the source fits Roblox's 200,000 character\n"
        "-- limit for a ModuleScript Source assignment. Read init.luau instead.\n"
    )

    built = header + "\n".join(lines) + "\n"

    os.makedirs(os.path.dirname(TARGET), exist_ok=True)

    with open(TARGET, "w", encoding="utf-8") as handle:
        handle.write(built)

    limit = 200000
    print("source %d chars -> dist %d chars (%.0f%% smaller)"
          % (len(source), len(built), (1 - len(built) / len(source)) * 100))
    print("Roblox Source limit %d: %s"
          % (limit, "fits" if len(built) < limit else "STILL TOO LARGE"))

    return 0 if len(built) < limit else 1


if __name__ == "__main__":
    sys.exit(main())
