
--
-- This is an example of filters applied sequencially
-- It will first apply the Link then apply Header.
--

--
-- links-to-html.lua converts links to local Markdown documents to
-- there respective .html counterparts.
--
function Link(el)
  el.target = string.gsub(el.target, "%.md", ".html")
  return el
end

--
-- Allow mdashes in headings instead of stripping them
--
function Header(heading)
    -- Concatenate all the heading content into a single string
    local heading_content = pandoc.utils.stringify(heading)

    -- Check if the heading contains '--'
    if heading_content:match("--") then
        -- Return the heading unmodified
        return heading
    end
end
