--[[
    engocheat
    FILE: 3214114884.lua
    DESC: Flag Wars
    BY: engo
]]

local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local collectionService = cloneref(game:GetService('CollectionService'))
local players = cloneref(game:GetService('Players'))
local localPlayer = players.LocalPlayer
local camera = cloneref(workspace.CurrentCamera)
local entity = engocheat.libraries.entity
local drawing = engocheat.libraries.drawing
local cheats = engocheat.cheats

local tMain = engocheat.ui.mainTab
local tCharacter = engocheat.ui.characterTab
local tVisuals = engocheat.ui.visualsTab
local tMisc = engocheat.ui.miscTab
local tOptions = engocheat.ui.optionsTab

-- get used dependencies
local gameDependencies = {}; do
    local weaponsSystem = replicatedStorage.WeaponsSystem
    local weaponLibraries = weaponsSystem.Libraries

    local events = replicatedStorage.Events

    gameDependencies.BulletWeapon = require(weaponsSystem.WeaponTypes.BulletWeapon)
    gameDependencies.Parabola = require(weaponLibraries.Parabola)
    gameDependencies.BaseWeapon = require(weaponLibraries.BaseWeapon)
    gameDependencies.ShoulderCamera = require(replicatedStorage.ShoulderCamera)

    gameDependencies.ClientCastReplicationRemote = events['ClientCast Network']['ClientCast-Replication']
end

-- Entity library hook for bots
do
    local function teamCheck(ent)
        local teamName = ent.Character and ent.Character:GetAttribute("Team") or (ent.Player and ent.Player.Team.Name or nil)
        local localTeamName = localPlayer.Team and localPlayer.Team.Name

        if (teamName == nil and localTeamName == nil) then
            return true -- Targetable, neither has a team
        end

        return teamName ~= localTeamName
    end

    engocheat.selfDestructJanitor:Add(collectionService:GetInstanceAddedSignal('BOT'):Connect(function(instance)
        entity.refreshEntity(instance, nil, teamCheck)
    end))

    engocheat.selfDestructJanitor:Add(collectionService:GetInstanceRemovedSignal('BOT'):Connect(function(instance)
        entity.removeEntity(instance)
    end))

    for _, instance in collectionService:GetTagged('BOT') do
        entity.refreshEntity(instance, nil, teamCheck)
    end
end

do
    local slientaim = {}

    local raycastParams = debug.getupvalue(gameDependencies.Parabola._penetrateCast, 1)
    local penetrateCast
    local simulateFire

    slientaim.janitor = engocheat.libraries.janitor.new()
    slientaim.folder = tMain:AddFolder('slient aim')
    slientaim.enabled = slientaim.folder:AddToggle('enabled', function(value)
        if (not value) then 
            return slientaim.janitor:Cleanup()
        end

        if (slientaim.wallbangEnabled.Value) then
            raycastParams.FilterType = Enum.RaycastFilterType.Include
        end

        penetrateCast = gameDependencies.Parabola._penetrateCast; gameDependencies.Parabola._penetrateCast = function(self, ray, instances, ...)
            if (not slientaim.wallbangEnabled.Value) then
                return penetrateCast(self, ray, instances, ...)
            end

            local characters = {}
            for _, ent in entity.List do    
                table.insert(characters, ent.Character)
            end

            return penetrateCast(self, ray, characters, ...)
        end

        simulateFire = gameDependencies.BulletWeapon.simulateFire; gameDependencies.BulletWeapon.simulateFire = function(self, player, data)
            if (player == localPlayer) then
                local origin = rawget(data, 'origin')
                local closest = entity.EntityMouse({
                    Range = 1000,
                    Part = 'Head',
                    Players = true,
                    NPCs = true,
                    Wallcheck = not slientaim.wallbangEnabled.Value,
                    Origin = origin,
                })

                if closest then
                    local lookVector = CFrame.lookAt(origin, closest.Head.Position).LookVector
                    rawset(data, 'dir', lookVector)
                end
            end

            return simulateFire(self, player, data)
        end

        slientaim.janitor:Add(function() 
            gameDependencies.BulletWeapon.simulateFire = simulateFire
            simulateFire = nil

            gameDependencies.Parabola._penetrateCast = penetrateCast
            penetrateCast = nil

            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        end)
    end)

    slientaim.wallbangEnabled = slientaim.folder:AddToggle('wallbang', function(value) 
        if (value and slientaim.enabled.Value) then
            raycastParams.FilterType = Enum.RaycastFilterType.Include
        else
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        end
    end)

    engocheat.selfDestructJanitor:Add(slientaim.janitor, 'Cleanup')
    cheats.slientaim = slientaim
end

do
    local gunmods = {}

    gunmods.janitor = engocheat.libraries.janitor.new()
    gunmods.folder = tMain:AddFolder('gun modifications')

    local getConfigValue
    gunmods.enabled = gunmods.folder:AddToggle('enabled', function(value)
        if (not value) then
            return gunmods.janitor:Cleanup()
        end

        getConfigValue = gameDependencies.BaseWeapon.getConfigValue
        gameDependencies.BaseWeapon.getConfigValue = function(tab, key, fallback)
            if (gunmods.norecoil.Value) and (key == 'RecoilMin' or key == 'RecoilMax') then
                return 0
            end

            if (gunmods.nospread.Value) and (key == 'MinSpread' or key == 'MaxSpread') then
                return 0
            end

            if (gunmods.nocooldown.Value) and (key == 'ShotCooldown') then
                return 0.02
            end

            if (gunmods.instrel.Value) and (key == 'ReloadTime') then
                return 0
            end

            return getConfigValue(tab, key, fallback)
        end

        gunmods.janitor:Add(function()
            gameDependencies.BaseWeapon.getConfigValue = getConfigValue
            getConfigValue = nil
        end)
    end)
    gunmods.norecoil = gunmods.folder:AddToggle('no recoil', function(value) end)
    gunmods.nospread = gunmods.folder:AddToggle('no spread', function(value) end)
    gunmods.nocooldown = gunmods.folder:AddToggle('no shot cooldown', function(value) end)
    gunmods.instrel = gunmods.folder:AddToggle('instant reload', function(value) end)

    engocheat.selfDestructJanitor:Add(gunmods.janitor, 'Cleanup')
    cheats.gunmods = gunmods
end

do
    local instantdig = {}
    local COOLDOWN_UPVALUE_IDX = 6 -- index of cooldown upvalue

    instantdig.janitor = engocheat.libraries.janitor.new()
    instantdig.folder = tMain:AddFolder('instant dig')
    instantdig.enabled = instantdig.folder:AddToggle('enabled', function(value)
        if (not value) then 
            return instantdig.janitor:Cleanup()
        end

        local digHeartbeat
        for _, connection in getconnections(runService.Heartbeat) do 
            local fn = connection.Function
            if (not fn) then
                continue
            end

            local const = debug.getconstants(fn)
            if (table.find(const, 'Dig')) then
                if (digHeartbeat) then 
                    warn(`{engocheat.constants.prefix} Multiple dig heartbeat functions found.`)
                end

                local upvalue = debug.getupvalue(fn, COOLDOWN_UPVALUE_IDX)
                if (type(upvalue) ~= 'number') then
                    warn(`{engocheat.constants.prefix} COOLDOWN_UPVALUE_IDX ({COOLDOWN_UPVALUE_IDX}) upvalue on dig heartbeat function is not a number.`)
                    continue
                end

                digHeartbeat = fn
            end
        end

        if (not digHeartbeat) then
            return warn(`{engocheat.constants.prefix} dig heartbeat function not found.`)
        end

        local cooldown = debug.getupvalue(digHeartbeat, COOLDOWN_UPVALUE_IDX)
        debug.setupvalue(digHeartbeat, COOLDOWN_UPVALUE_IDX, 0)

        instantdig.janitor:Add(function() 
            debug.setupvalue(digHeartbeat, COOLDOWN_UPVALUE_IDX, cooldown)
        end)
    end)

    engocheat.selfDestructJanitor:Add(instantdig.janitor, 'Cleanup')
    cheats.instantdig = instantdig
end

do
    local meleeaura = {}

    meleeaura.janitor = engocheat.libraries.janitor.new()
    meleeaura.folder = tMain:AddFolder('melee aura')
    meleeaura.enabled = meleeaura.folder:AddToggle('enabled', function(value)
        if (not value) then
            return meleeaura.janitor:Cleanup()
        end

        local tab
        for _, connection in getconnections(gameDependencies.ClientCastReplicationRemote.OnClientEvent) do
            local fn = connection.Function
            if (not fn) then
                continue
            end

            local const = debug.getconstants(fn)
            if (const[1] == 'Start' and const[3] == 'Destroy') then
                local fn_2 = debug.getupvalue(fn, 2)
                tab = debug.getupvalue(fn_2, 2)
            end
        end

        meleeaura.janitor:Add(task.spawn(function()
            while (true) do
                local _, data = next(tab) -- Grab a random UniqueId, tbh no clue if its even checked but better safe than sorry.
                local uniqueId = data._UniqueId

                local ent = entity.EntityPosition({
                    Players = true,
                    NPCs = true,
                    Part = 'Head',
                    Range = 35,
                    Wallcheck = false,
                })

                if ent then
                    gameDependencies.ClientCastReplicationRemote:FireServer(uniqueId, 'Humanoid', {
                        Instance = ent.Head,
                        Material = ent.Head.Material,
                        Normal = CFrame.lookAt(camera.CFrame.Position, ent.Head.Position).LookVector,
                        Position = ent.Head.Position,
                    })
                end

                task.wait(.1)
            end
        end))
    end)
    --meleeaura.temp = meleeaura.folder:AddToggle('', function(value) end)


    engocheat.selfDestructJanitor:Add(meleeaura.janitor, 'Cleanup')
    cheats.meleeaura = meleeaura
end
