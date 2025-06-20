--[[
Pandoc Lua filter: image-title-to-figcaption.lua
(with help from Claude Sonnet 4)

DESCRIPTION:
  Converts Pandoc Figure elements (from Markdown images with titles) to custom HTML <figure> blocks.
  The image title (caption) is rendered as HTML in <figcaption>, preserving formatting (bold, italic, etc.).
  This filter outputs the final HTML directly—no JavaScript post-processing is required.

IMPLEMENTATION:
  - Intercepts Figure elements in the Pandoc AST
  - Extracts the image, alt text, and caption
  - Converts the caption to HTML, preserving formatting
  - Outputs a single RawBlock with the desired <figure> HTML

USAGE:
  pandoc --lua-filter=image-title-to-figcaption.lua input.md -o output.html

EXAMPLE:
  Input:  ![alt](image.jpg "**Bold** and *italic* text")
  Output: <figure><img src="image.jpg" alt="alt"/><figcaption><strong>Bold</strong> and <em>italic</em> text</figcaption></figure>
]]

function Figure(elem)
  -- Find the image inside the Figure's content (which is a list of blocks)
  local img = nil
  for _, block in ipairs(elem.content) do
    if block.t == "Plain" and #block.content == 1 and block.content[1].t == "Image" then
      img = block.content[1]
      break
    end
  end

  if not img then
    return nil
  end

  -- Get image src and alt
  local src = img.src
  local alt = pandoc.utils.stringify(img.caption or img.alt or {})

  -- Get the image title (caption text)
  local title = img.title or ""

  -- Convert the title (markdown) to HTML for the figcaption
  local caption_html = ""
  if title ~= "" then
    local parsed = pandoc.read(title, "markdown")
    caption_html = pandoc.write(parsed, "html")
    caption_html = caption_html:gsub("^%s*<p>(.-)</p>%s*$", "%1") -- remove <p> if present
  end

  -- Build the custom HTML
  local html
  if caption_html ~= "" then
    html = string.format(
      '<figure><img src="%s" alt="%s"/><figcaption>%s</figcaption></figure>',
      src, alt, caption_html
    )
  else
    html = string.format(
      '<figure><img src="%s" alt="%s"/></figure>',
      src, alt
    )
  end

  return pandoc.RawBlock("html", html)
end
