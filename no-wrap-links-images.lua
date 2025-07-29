-- no-wrap-links-images.lua
-- (with help from Claude Sonnet 4)
-- Pandoc Lua filter to prevent wrapping of links and images
-- while allowing normal text wrapping

function Link(elem)
  if FORMAT:match 'markdown' then
    -- Extract link components
    local link_text = pandoc.utils.stringify(elem.content or {})
    local url = elem.target or ""
    local title = elem.title or ""

    -- Build the markdown link syntax
    local markdown_link
    if title ~= "" then
      markdown_link = "[" .. link_text .. "](" .. url .. ' "' .. title .. '")'
    else
      markdown_link = "[" .. link_text .. "](" .. url .. ")"
    end

    -- Return as raw markdown to prevent further processing/wrapping
    return pandoc.RawInline('markdown', markdown_link)
  end
end

function Image(elem)
  if FORMAT:match 'markdown' then
    -- Extract image components - NOTE: alt text is in elem.caption, not elem.content
    local alt_text = pandoc.utils.stringify(elem.caption or {})
    local url = elem.src or ""
    local title = elem.title or ""

    -- Build the markdown image syntax
    local markdown_image
    if title ~= "" then
      markdown_image = "![" .. alt_text .. "](" .. url .. ' "' .. title .. '")'
    else
      markdown_image = "![" .. alt_text .. "](" .. url .. ")"
    end

    -- Return as raw markdown to prevent further processing/wrapping
    return pandoc.RawInline('markdown', markdown_image)
  end
end
