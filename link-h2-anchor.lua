function Header(h)
  -- Check if the header level is 2 (H2)
  if h.level == 2 then
    -- Generate a unique name attribute based on the header text
    local text = pandoc.utils.stringify(h)
    local name = string.lower(text)
    name = string.gsub(name, "[^%w%- ]", "") -- Remove non-alphanumeric characters
    name = string.gsub(name, "%s+", "-") -- Replace spaces with hyphens

    -- Create the HTML for the H2 header with an anchor having the name attribute
    local html = string.format('<h2><a name="%s">%s</a></h2>', name, text)

    -- Return the raw HTML block
    return pandoc.RawBlock('html', html)
  else
    -- Return the header unchanged if it's not an H2
    return h
  end
end
