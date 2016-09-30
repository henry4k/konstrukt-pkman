#!/usr/bin/env lua5.2

require 'compat53'

local function seek_eocd( file )
    local signature = 'PK\5\6'
    local overlap = #signature - 1 -- in case the signature is between two windows
    local window = 1024
    local i = 1
    while true do
        local chunk_position = -i*window
        file:seek('end', chunk_position)
        local chunk = file:read(window+overlap)
        local _, position = chunk:find(signature, 1, true) -- just use plain text search
        if position then
            return file:seek('end', chunk_position + position)
        end
        i = i + 1
    end
end

local function seek_eocd_comment( file )
    assert(seek_eocd(file), 'Can\'t locate EOCD.')
    file:seek('cur', 16) -- move to the comment length entry
    return file:seek()
end

local function read_eocd_comment( file )
    seek_eocd_comment(file)
    local comment_length = string.unpack('<I2', assert(file:read(2)))
    if comment_length > 0 then
        local comment = file:read(comment_length)
        assert(#comment == comment_length, 'Comment length lied.')
        local comment_end = file:seek()
        local file_size = file:seek('end')
        assert(comment_end == file_size, 'There is still something behind the comment - weird.')
        return comment
    end
end

local function write_eocd_comment( file, comment )
    seek_eocd_comment(file)
    file:write(string.pack('<I2', #comment))
    file:write(comment)
end

local file = io.open(arg[1], 'r+b')
write_eocd_comment(file, 'WELL YES')
file:close()
