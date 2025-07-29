-- preserve-en-dash.lua
-- (with help from Claude Sonnet 4)
-- Pandoc Lua filter to preserve en dashes in Markdown output
-- Handles Unicode escapes like \8211\&

function Str(elem)
  -- Only process when outputting to markdown formats
  if FORMAT:match 'markdown' then
    -- Convert Unicode escape sequence back to en dash character
    -- \8211 is the Unicode code point for en dash (U+2013)
    elem.text = elem.text:gsub('\\8211\\&', '–')

    -- Also handle cases without the trailing \&
    elem.text = elem.text:gsub('\\8211', '–')

    -- Handle other potential en dash representations
    elem.text = elem.text:gsub('\\u2013', '–')
    elem.text = elem.text:gsub('\\x{2013}', '–')

    return elem
  end
end

-- More robust approach: let Pandoc handle the Unicode conversion
-- then ensure we preserve the en dash in the final output
function Meta(meta)
  if FORMAT:match 'markdown' then
    -- Set a custom writer option to preserve Unicode characters
    meta['preserve-unicode'] = true
    return meta
  end
end

-- Main filter function
function Str(elem)
  if FORMAT:match 'markdown' then
    -- The elem.text should contain the actual en dash character
    -- after Pandoc processes the Unicode escape
    local text = elem.text

    -- Ensure en dashes stay as en dashes (don't get converted to --)
    -- This is the key: we're preventing the conversion TO --, not FROM --
    if text:match('–') then
      return pandoc.RawInline('markdown', text)
    end

    return elem
  end
end
