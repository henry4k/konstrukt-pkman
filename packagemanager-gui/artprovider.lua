local wx = require 'wx'


local ArtProvider = wx.wxLuaArtProvider()

function ArtProvider:DoGetSizeHint( client )
    --print('ArtProvider:DoGetSizeHint', client)
    return self.GetSizeHint(client, true)
end

function ArtProvider:CreateBitmap( id, client, size )
    --print('ArtProvider:CreateBitmap', id, client, size)
    return wx.NULL
end


return ArtProvider
