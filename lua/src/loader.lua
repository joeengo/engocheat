--[[
    engocheat
    FILE: loader.lua
    DESC: loads engocheat
]]

--[[
    TODO:
        possibly create a list of file hashes on the github, compare them to the downloaded file hashes json and download any differences. 
]]

-- global table
local engocheat = {}
engocheat.functions = {}
engocheat.libraries = {}
engocheat.constants = {}
engocheat.ui = {}

do
    engocheat.constants.baseurl = ""
    engocheat.constants.prefix = "[engocheat]"
end

do
    --[[
        getfile
        Usage:
            getfile({
                path = "lib/janitor.lua",
                -- Uses baseurl as baseurl if path is not found, if no baseurl is supplied, it will resort to the engocheat github.
                baseurl = "",
                -- if url is supplied it bypasses the 2 above fields and directly uses it.
                url = ""
            })
    ]]
    engocheat.functions.getfile = function(data)
        if ( ( not data.url ) and ( isfile(`engocheat/{data.path}`) ) ) then
            return readfile(`engocheat/{data.path}`)
        end

        
        local url = data.url or `{data.baseurl or engocheat.constants.baseurl}/{data.path}`
        local requested = request({ Url = url })
        if (requested.StatusCode == 200) then
            return requested.Body
        end

        error(`{engocheat.constants.prefix} Unable to get file {data.url or data.path}, ({requested.StatusCode}: {requested.StatusMessage})`)
    end

    engocheat.functions.loadSrc = function(src, ...)
        local loadedFunction, result = loadstring(src)
        if (not loadedFunction) then
            error(`Error while loading src: {result}`)
        end

        return loadedFunction(...)
    end
end

local ui = engocheat.functions.loadSrc(
    engocheat.functions.getfile({
        path = "lua/src/ui.lua",
    })
)

engocheat.ui.api = ui

print("hello")