--[[
    engocheat
    FILE: update.lua
    DESC: updates the hashes and files.
    BY: engo
]]

local httpService = cloneref(game:GetService('HttpService'))
local sha

local function createHashManifestRecursive(dir, manifest)
    sha = sha or engocheat.functions.loadLibrary('sha.lua')
    local manifest = manifest or {}
    local dir = dir or 'engocheat/lua'

    local files = listfiles(dir)
    for i, v in files do 
        if (isfile(v)) then
            manifest[string.gsub(v, 'engocheat/', '')] = sha.sha512(readfile(v))
        else
            task.wait()
            createHashManifestRecursive(v, manifest)
        end
    end

    return manifest
end

if (getgenv().engocheat_developer) then
    local manifest = createHashManifestRecursive()
    manifest = httpService:JSONEncode(manifest)

    engocheat.functions.writeFile('engocheat/hash-manifest.json', manifest)
    print(`{engocheat.constants.prefix} Updated hash-manifest.json!`)
else
    local hashedFileDataJSON, onlineHashedFileDataJSON = engocheat.functions.getHashManifests()
    local hashedFileData, onlineHashedFileData = httpService:JSONDecode(hashedFileDataJSON), httpService:JSONDecode(onlineHashedFileDataJSON)

    for path, hash in onlineHashedFileData do
        local localHash = hashedFileData[path]
        if (localHash == hash) then 
            continue
        end

        local onlineFileData = engocheat.functions.getOnlineFile({path = path})
        engocheat.functions.writeFile(`{engocheat.constants.basedir}/{path}`, onlineFileData)
    end
        
    engocheat.functions.writeFile(`{engocheat.constants.basedir}/hash-manifest.json`, onlineHashedFileDataJSON)
end

----> TEST <----