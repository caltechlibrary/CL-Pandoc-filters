-- github-heading-anchors.lua
-- (with help from Claude Sonnet 4)
-- Pandoc Lua filter to generate GitHub-compatible heading anchors

-- Table to track used anchors for duplicate handling
local used_anchors = {}

-- Function to generate GitHub-style anchor from heading text
function generate_github_anchor(heading_text)
  -- Remove markup formatting, leaving only contents
  local plain_text = pandoc.utils.stringify(heading_text)

  -- Convert to lowercase
  local anchor = plain_text:lower()

  -- Remove leading and trailing whitespace
  anchor = anchor:match("^%s*(.-)%s*$")

  -- Replace spaces with hyphens, remove other whitespace and punctuation
  anchor = anchor:gsub("%s+", "-")  -- Replace whitespace with hyphens
  anchor = anchor:gsub("[^%w%-]", "")  -- Remove everything except word chars and hyphens

  -- Clean up multiple consecutive hyphens
  anchor = anchor:gsub("%-+", "-")

  -- Remove leading/trailing hyphens
  anchor = anchor:gsub("^%-+", "")
  anchor = anchor:gsub("%-+$", "")

  -- Handle duplicates by appending incrementing numbers
  local original_anchor = anchor
  local counter = 1

  while used_anchors[anchor] do
    anchor = original_anchor .. "-" .. counter
    counter = counter + 1
  end

  -- Mark this anchor as used
  used_anchors[anchor] = true

  return anchor
end

-- Process Header elements
function Header(elem)
  if FORMAT:match 'markdown' then
    -- Generate GitHub-compatible anchor
    local anchor = generate_github_anchor(elem.content)

    -- Set the identifier attribute
    elem.identifier = anchor

    return elem
  end
end

-- Function to clean up anchor links using the same rules
function clean_anchor_link(url)
  -- Only process internal anchor links (starting with #)
  if not url:match("^#") then
    return url
  end

  -- Remove the # prefix
  local anchor = url:sub(2)

  -- Apply the same cleaning rules as for heading anchors
  anchor = anchor:lower()
  anchor = anchor:gsub("%s+", "-")  -- Replace whitespace with hyphens
  anchor = anchor:gsub("[^%w%-]", "")  -- Remove everything except word chars and hyphens
  anchor = anchor:gsub("%-+", "-")  -- Clean up multiple consecutive hyphens
  anchor = anchor:gsub("^%-+", "")  -- Remove leading hyphens
  anchor = anchor:gsub("%-+$", "")  -- Remove trailing hyphens

  return "#" .. anchor
end

-- Process Link elements
function Link(elem)
  if FORMAT:match 'markdown' then
    -- elem.target is a string (the URL), not a table
    local url = elem.target
    local title = elem.title or ""

    -- Clean up the URL if it's an internal anchor link
    local cleaned_url = clean_anchor_link(url)

    -- Update the link target
    elem.target = cleaned_url

    return elem
  end
end

-- Reset anchor tracking for each document
function Doc(doc)
  used_anchors = {}
  return doc
end
