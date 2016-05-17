local crypto = require 'crypto'
local basexx = require 'basexx'
local Config = require 'packagemanager/config'
local FS = require 'packagemanager/fs'


local Security = {}

local function GetPublicKeyFileName( identity )
    return FS.path(Config.publicKeyDir, identity..'.pub')
end

local function ReadSignature( fileName )
    local signature = FS.readJsonFile(fileName)
    assert(signature.identity)
    assert(signature.data)
    signature.data = basexx.from_base64(signature.data)
    return signature
end

function Security.verifyFile( fileName, signatureFileName )
    -- 
end

return Security
