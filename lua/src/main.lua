--[[
    engocheat
    FILE: main.lua
    DESC: main file for engocheat
]]

-- TODO: improve ui lib

-- Load libraries
do
    engocheat.libraries.sha = engocheat.functions.loadLibrary("sha.lua")
    engocheat.libraries.janitor = engocheat.functions.loadLibrary("janitor.lua")
    engocheat.libraries.entity = engocheat.functions.loadSrc(
        engocheat.functions.getOnlineFile({ url = "https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/Libraries/entityHandler.lua" })
    )
end

-- Init xylex stupid entity
engocheat.libraries.entity.fullEntityRefresh()

-- Self destruct janitor
engocheat.ui.selfDestructJanitor = engocheat.libraries.janitor.new()

-- Load UI + Init UI Stuff
do
    engocheat.ui.api = engocheat.functions.loadSrc(
        engocheat.functions.getFile({path = "lua/src/ui.lua"})
    )

    engocheat.ui.window = engocheat.ui.api:AddWindow("engocheat pre-release", {
        main_color = Color3.fromRGB(33, 42, 105),
        min_size = Vector2.new(500, 600),
        toggle_key = Enum.KeyCode.RightShift,
        can_resize = true,
    })

    engocheat.ui.selfDestructJanitor:Add(engocheat.ui.window.Instance)

    engocheat.ui.mainTab = engocheat.ui.window:AddTab("main")
    engocheat.ui.characterTab = engocheat.ui.window:AddTab("character")
    engocheat.ui.visualsTab = engocheat.ui.window:AddTab("visuals")
    engocheat.ui.miscTab = engocheat.ui.window:AddTab("misc")
    engocheat.ui.optionsTab = engocheat.ui.window:AddTab("options")

    
        -- TEST MODULE
        --[[
    engocheat.ui.killauraFolder = engocheat.ui.mainTab:AddFolder("Killaura")
    engocheat.ui.killauraFolder:AddSwitch("Enabled")
    engocheat.ui.killauraFolder:AddSlider("Range")
    engocheat.ui.killauraFolder:AddTextBox("Textbox")
    local d = engocheat.ui.killauraFolder:AddDropdown("Target Mode")
    d:Add("Distance")
    d:Add("Health")
    d:Add("Threat")
    engocheat.ui.killauraFolder:AddColorPicker()
    engocheat.ui.killauraFolder:AddKeybind("Keybind")
    ]]
end


print(`{engocheat.constants.prefix} Loaded in {math.floor((os.clock() - engocheat.startUnix) * 1000)}ms`)