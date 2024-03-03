--[[
    engocheat
    FILE: main.lua
    DESC: main file for engocheat
]]

-- Load libraries
do
    engocheat.libraries.sha = engocheat.functions.loadLibrary("sha.lua")
    engocheat.libraries.janitor = engocheat.functions.loadLibrary("janitor.lua")
end

print("Main file running!")
print("sha1 test:", engocheat.libraries.sha.sha1("engocheat"))

print(`{engocheat.constants.prefix} Loaded in {os.clock() - engocheat.startUnix}s`)