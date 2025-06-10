--[[
    engocheat
    FILE: main.lua
    DESC: main file for engocheat
    BY: engo
]]

-- TODO: improve ui lib

-- Load libraries
do
    engocheat.libraries.sha = engocheat.functions.loadLibrary('sha.lua')
    engocheat.libraries.janitor = engocheat.functions.loadLibrary('janitor.lua')
    engocheat.libraries.signal = engocheat.functions.loadLibrary('signal.lua')
    engocheat.libraries.drawing = engocheat.functions.loadLibrary('drawing.lua')
    engocheat.libraries.entity = engocheat.functions.loadLibrary('entity.lua')
    --[[engocheat.libraries.entity = engocheat.functions.loadSrc(
        engocheat.functions.getOnlineFile({ url = 'https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/refs/heads/main/libraries/entity.lua' })
    )]]
end

-- Self destruct janitor
engocheat.selfDestructJanitor = engocheat.libraries.janitor.new()

-- Load UI + Init UI Stuff
do
    engocheat.ui.api = engocheat.functions.loadSrc(
        engocheat.functions.getFile({path = 'lua/src/ui.lua'}), 'engocheat-ui'
    )

    engocheat.signals = {}

    local options = {
        main_color = Color3.fromRGB(33, 42, 105),
        min_size = Vector2.new(400, 200),
        toggle_key = Enum.KeyCode.RightShift,
        can_resize = true,
    }

    engocheat.ui.api.options = options
    engocheat.ui.window = engocheat.ui.api:AddWindow('engocheat', options)

    engocheat.selfDestructJanitor:Add(engocheat.ui.window.Instance)
    engocheat.selfDestructJanitor:Add(function()
        -- Add more cleaning up here if needed...
        engocheat.libraries.entity.stop()
        getgenv().engocheat = nil
    end)

    engocheat.ui.mainTab = engocheat.ui.window:AddTab('main')
    engocheat.ui.characterTab = engocheat.ui.window:AddTab('character')
    engocheat.ui.visualsTab = engocheat.ui.window:AddTab('visuals')
    engocheat.ui.miscTab = engocheat.ui.window:AddTab('misc')
    engocheat.ui.optionsTab = engocheat.ui.window:AddTab('options')
end


print(`{engocheat.constants.prefix} Loaded in {math.floor((os.clock() - engocheat.startUnix) * 1000)}ms`)