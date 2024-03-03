--[[
    engocheat
    FILE: loader.lua
    DESC: loads engocheat
]]

--[[
    TODO:
        possibly create a list of file hashes on the github, compare them to the downloaded file hashes json and download any differences. 
]]

-- services
local httpService = cloneref(game:GetService("HttpService"))

-- global table
local engocheat = {}
engocheat.functions = {}
engocheat.libraries = {}
engocheat.constants = {}
engocheat.ui = {}

getgenv().engocheat = engocheat

do
    engocheat.constants.baseurl = "https://raw.githubusercontent.com/joeengo/engocheat/main/"
    engocheat.constants.basedir = "engocheat"
    engocheat.constants.prefix = "[engocheat]"
end

do
    -- Creates the folders + file
    engocheat.functions.writeFile = function(path, data)
        local sections = string.split(path, "/")
        local currentDir
        for i, v in sections do
            if (i == #sections) then
                writefile(path, data)
            else
                currentDir = if currentDir then `{currentDir}/{v}` else v
                makefolder(currentDir)
            end
        end
    end

    --[[
        getFile
        Usage:
            getFile({
                path = "lib/janitor.lua",
                -- Uses baseurl as baseurl if path is not found, if no baseurl is supplied, it will resort to the engocheat github.
                baseurl = "",
                -- if url is supplied it bypasses the 2 above fields and directly uses it.
                url = ""
            })
    ]]
    engocheat.functions.getLocalFile = function(data) 
        if (isfile(`engocheat/{data.path}`)) then
            return readfile(`engocheat/{data.path}`)
        end
    end

    engocheat.functions.getOnlineFile = function(data)
        local url = data.url or `{data.baseurl or engocheat.constants.baseurl}/{data.path}`
        url = string.gsub(url, "\\", "/")
        local requested = request({ Url = url })
        if (requested.StatusCode == 200) then
            return requested.Body
        end

        error(`{engocheat.constants.prefix} Unable to get file {data.url or data.path}, ({requested.StatusCode}: {requested.StatusMessage})`)
    end

    engocheat.functions.getFile = function(data)
        return engocheat.functions.getLocalFile(data) or engocheat.functions.getOnlineFile(data)
    end

    engocheat.functions.getHashManifests = function() 
        return engocheat.functions.getLocalFile({ path = "hash-manifest.json" }) or "{}", engocheat.functions.getOnlineFile({ path = "hash-manifest.json" }) or error("Online hash manifest not found")
    end

    engocheat.functions.loadSrc = function(src, ...)
        local loadedFunction, result = loadstring(src)
        if (not loadedFunction) then
            error(`Error while loading src: {result}`)
        end

        return loadedFunction(...)
    end
end

if (getgenv().engocheat_developer) then
    engocheat.functions.loadSrc( engocheat.functions.getLocalFile( {path = "lua/actions/update-manifest.lua"} ) )
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