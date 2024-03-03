--[[
    engocheat
    FILE: update-manifest.lua
    DESC: updates the file hash manifest, only ran by developers.
]]

local httpService = cloneref(game:GetService("HttpService"))
local sha = engocheat.functions.loadSrc(engocheat.functions.getLocalFile({path = "lua/lib/sha.lua"}))

local function createHashManifestRecursive(dir, manifest)
    local manifest = manifest or {}
    local dir = dir or "engocheat/lua"

    local files = listfiles(dir)
    for i, v in files do 
        if (isfile(v)) then
            manifest[string.gsub(v, "engocheat/", "")] = sha.sha512(readfile(v))
        else
            createHashManifestRecursive(v, manifest)
        end
    end

    return manifest
end

local manifest = createHashManifestRecursive()
manifest = httpService:JSONEncode(manifest)

engocheat.functions.writeFile("engocheat/hash-manifest.json", manifest)
print(`{engocheat.constants.prefix} Updated hash-manifest.json!`)