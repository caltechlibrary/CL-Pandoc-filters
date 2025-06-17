
# User Manual

This repository holds an add-hoc collection of filter functions for use with Pandoc. 

[examples.lua](elements.lua)
: Shows two filters applied sequencially to an AST.

Example: `pandoc  --lua-filter=examples.lua -o output.md yourfile.md`


[links-to-html.lua](links-to-html.lua)
: This is a transform of links to markdown documents (`.md` files) to their HTML equivallent (`.html`)

Example: `pandoc  --lua-filter=links-to-html.lua -o output.md yourfile.md`

[header-mdash.lua](header-mdash.lua)
: This allows a double dash Markdown symbol to exist in a header.

Example: `pandoc  --lua-filter=header-mdash.lua -o output.md yourfile.md`
