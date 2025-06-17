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
