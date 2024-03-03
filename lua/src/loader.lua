--[[
    engocheat
    FILE: loader.lua
    DESC: loads engocheat
]]

local startUnix = os.clock()

if (getgenv().engocheat) then 
    return error("engocheat already executed, press remove cheat to re-execute.")
end

-- services
local httpService = cloneref(game:GetService("HttpService"))

-- global table
local engocheat = {}
engocheat.functions = {}
engocheat.libraries = {}
engocheat.constants = {}
engocheat.ui = {}
engocheat.startUnix = startUnix

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
        if (isfile(`{engocheat.constants.basedir}/{data.path}`)) then
            return readfile(`{engocheat.constants.basedir}/{data.path}`)
        end
    end

    engocheat.functions.getOnlineFile = function(data)
        local url = data.url or `{data.baseurl or engocheat.constants.baseurl}/{data.path}`
        url = string.gsub(url, "\\", "/")
        local requested = request({ Url = url })
        if (requested.StatusCode == 200) then
            return requested.Body
        elseif (requested.StatusCode == 404) then
            return
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

    local libraryCache = {} -- Not sure if this is even needed as i only load the libraries once anyway.
    engocheat.functions.loadLibrary = function(libName, ...)
        local result = libraryCache[libName]
        if (not result) then
            local libSrc = engocheat.functions.getFile({path = `lua/lib/{libName}`})
            result = engocheat.functions.loadSrc(libSrc, ...)
            libraryCache[libName] = result
        end
        return result
    end

    engocheat.functions.runAction = function(actionName, ...)
        local actSrc = engocheat.functions.getFile({path = `lua/actions/{actionName}`})
        return engocheat.functions.loadSrc(actSrc, ...)
    end
end

-- Run the action to update files/hashes.
engocheat.functions.runAction("update.lua")

-- Load the files
engocheat.functions.loadSrc( engocheat.functions.getFile({ path = "lua/src/main.lua" }) )
engocheat.functions.loadSrc( engocheat.functions.getFile({ path = "lua/src/places/universal.lua" }) )

-- Load this places file
local placeFile = engocheat.functions.getFile({ path = `lua/src/places/{game.PlaceId}.lua` })
if (placeFile) then
    engocheat.functions.loadSrc( placeFile )
end