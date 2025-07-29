-- word-blockquote-to-markdown-image.lua
-- (with help from Claude Sonnet 4)
-- Pandoc Lua filter to convert blockquotes with pipe-delimited content
-- into Markdown image elements

-- Function to split a string by pipes and create Str elements
function split_string_by_pipes(text)
  local result = {}
  local current_pos = 1

  -- Find each pipe character and split accordingly
  while current_pos <= #text do
    local pipe_pos = text:find("|", current_pos, true)

    if pipe_pos then
      -- Add the text before the pipe (if any)
      if pipe_pos > current_pos then
        local part = text:sub(current_pos, pipe_pos - 1)
        table.insert(result, pandoc.Str(part))
      end
      -- Add the pipe separator
      table.insert(result, pandoc.Str("|"))
      current_pos = pipe_pos + 1
    else
      -- Add the remaining text (if any)
      if current_pos <= #text then
        local part = text:sub(current_pos)
        table.insert(result, pandoc.Str(part))
      end
      break
    end
  end

  return result
end

-- Function to expand any Str elements containing pipes
function expand_pipe_strings(inlines)
  local expanded = {}

  for _, elem in ipairs(inlines) do
    if elem.t == "Str" and elem.text:match("|") then
      -- Split this string by pipes and add the parts
      local parts = split_string_by_pipes(elem.text)
      for _, part in ipairs(parts) do
        table.insert(expanded, part)
      end
    else
      table.insert(expanded, elem)
    end
  end

  return expanded
end

-- Function to split content by pipe characters while preserving inline formatting
function split_blockquote_content(content)
  -- First expand any strings containing pipes
  local expanded_content = expand_pipe_strings(content)

  local segments = {}
  local current_segment = {}

  -- Walk through all inline elements in the blockquote
  for i, elem in ipairs(expanded_content) do
    -- Check if this element is a pipe character
    if elem.t == "Str" and elem.text == "|" then
      -- Finalize current segment (skip if empty)
      if #current_segment > 0 then
        table.insert(segments, current_segment)
      end
      -- Start new segment
      current_segment = {}
    else
      -- Add element to current segment (skip standalone spaces after pipes)
      if not (elem.t == "Space" and #current_segment == 0) then
        table.insert(current_segment, elem)
      end
    end
  end

  -- Add final segment if it has content
  if #current_segment > 0 then
    table.insert(segments, current_segment)
  end

  return segments
end

-- Function to trim leading/trailing spaces from inline elements
function trim_inlines(inlines)
  local result = {}
  local start_idx = 1
  local end_idx = #inlines

  -- Skip leading spaces
  while start_idx <= #inlines and inlines[start_idx].t == "Space" do
    start_idx = start_idx + 1
  end

  -- Skip trailing spaces
  while end_idx >= 1 and inlines[end_idx].t == "Space" do
    end_idx = end_idx - 1
  end

  -- Copy the trimmed range
  for i = start_idx, end_idx do
    table.insert(result, inlines[i])
  end

  return result
end

-- Function to extract plain text from inline elements (for filename)
function extract_plain_text(inlines)
  local text = ""
  for _, elem in ipairs(inlines) do
    if elem.t == "Str" then
      text = text .. elem.text
    elseif elem.t == "Space" then
      text = text .. " "
    end
  end
  return text:match("^%s*(.-)%s*$") -- trim whitespace
end

-- Function to convert inlines back to Markdown syntax (for titles)
function inlines_to_markdown(inlines)
  local result = ""
  for _, elem in ipairs(inlines) do
    if elem.t == "Str" then
      result = result .. elem.text
    elseif elem.t == "Space" then
      result = result .. " "
    elseif elem.t == "Emph" then
      result = result .. "*" .. inlines_to_markdown(elem.content) .. "*"
    elseif elem.t == "Strong" then
      result = result .. "**" .. inlines_to_markdown(elem.content) .. "**"
    elseif elem.t == "Code" then
      result = result .. "`" .. elem.text .. "`"
    elseif elem.t == "Strikeout" then
      result = result .. "~~" .. inlines_to_markdown(elem.content) .. "~~"
    elseif elem.t == "Superscript" then
      result = result .. "^" .. inlines_to_markdown(elem.content) .. "^"
    elseif elem.t == "Subscript" then
      result = result .. "~" .. inlines_to_markdown(elem.content) .. "~"
    -- Add other inline types as needed
    else
      -- Fallback to stringify for unknown types
      result = result .. pandoc.utils.stringify({elem})
    end
  end
  return result
end

-- Process BlockQuote elements
function BlockQuote(elem)
  -- Get all inline content from the blockquote
  local all_inlines = {}

  -- Extract inlines from all paragraphs in the blockquote
  for _, block in ipairs(elem.content) do
    if block.t == "Para" then
      for _, inline in ipairs(block.content) do
        table.insert(all_inlines, inline)
      end
    end
  end

  -- Check if the content contains pipe characters
  local has_pipes = false
  for _, inline in ipairs(all_inlines) do
    if inline.t == "Str" and inline.text:match("|") then
      has_pipes = true
      break
    end
  end

  -- Only process blockquotes with pipe-delimited content
  if not has_pipes then
    return elem
  end

  -- Split content by pipes
  local segments = split_blockquote_content(all_inlines)

  -- We need at least 2 segments (alt text and filename)
  if #segments < 2 then
    return elem
  end

  -- Extract the three parts - trim whitespace from inlines
  local alt_text_inlines = trim_inlines(segments[1] or {})
  local filename = extract_plain_text(segments[2] or {})
  local title = ""

  if #segments >= 3 then
    -- Convert formatted title back to Markdown syntax
    title = inlines_to_markdown(segments[3])
  end

  -- Create the image element with proper alt text inlines
  local image = pandoc.Image(alt_text_inlines, filename, title)

  -- Return as a paragraph containing the image
  return pandoc.Para({image})
end
