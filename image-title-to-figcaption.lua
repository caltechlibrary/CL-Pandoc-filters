--[[
Pandoc Lua filter: image-title-to-figcaption.lua
(with help from Claude Sonnet 4)
(and blended with [ideas from Achuan-2](https://github.com/jgm/pandoc/issues/8752#issuecomment-2940636242))

DESCRIPTION:
  Sets the caption of figures (from Markdown images with titles) to the image's title, supporting Markdown formatting in the caption.
  If there is no title, no caption is generated. This preserves Pandoc's default Figure handling (IDs, classes, etc.), but allows rich formatting in captions.

IMPLEMENTATION:
  - Intercepts Para blocks containing a single image, and wraps them in a Figure if the image has a title.
  - Intercepts Figure blocks, and sets the caption from the image's title, parsing it as Markdown for formatting.
  - If there is no title, ensures no caption is generated.
  - Returns the modified block, so Pandoc's default writer handles the HTML output.

USAGE:
  pandoc --lua-filter=image-title-to-figcaption.lua input.md -o output.html

EXAMPLE:
  Input:  ![alt](image.jpg "**Bold** and *italic* text")
  Output: <figure><img src="image.jpg" alt="alt"/><figcaption><strong>Bold</strong> and <em>italic</em> text</figcaption></figure>
]]

-- Helper to create a caption from Markdown-formatted text
local function create_caption(text)
  if not text or text:find("^%s*$") then
    return {}
  else
    -- Parse the title as markdown and return its blocks
    return pandoc.read(text, 'markdown').blocks
  end
end

function Para(para)
  -- Check if the paragraph contains only an image
  if #para.content == 1 and para.content[1].t == "Image" then
    local img = para.content[1]
    if img.title and img.title ~= "" then
      -- Remove the title attribute
      img.title = ""
      local content = {pandoc.Plain({img})}
      local caption = create_caption(img.title)
      return pandoc.Figure(content, caption)
    else
      -- If only alt text (no title), ensure no caption
      img.caption = {}
      img.title = ""
      return pandoc.Para({img})
    end
  end
  return para
end

function Figure(fig)
  -- Look for an image in the figure
  for _, block in ipairs(fig.content) do
    if block.t == "Plain" then
      for _, inline in ipairs(block.content) do
        if inline.t == "Image" then
          local img = inline
          if img.title and img.title ~= "" then
            fig.caption = create_caption(img.title)
            img.title = ""
          else
            fig.caption = {}
            img.title = ""
          end
        end
      end
    end
  end
  return fig
end
