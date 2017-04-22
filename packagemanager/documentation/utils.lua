local function IsUrlLocalPath( url )
    return not string.match(url, '^.-://')
end

local function StripHtmlTags( html )
    return string.gsub(html, '<.->', '')
end

return { isUrlLocalPath = IsUrlLocalPath,
         stripHtmlTags = StripHtmlTags }
