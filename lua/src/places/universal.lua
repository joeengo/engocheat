--[[
    engocheat
    FILE: universal.lua
    DESC: the universal game script for engocheat
]]

local runService = cloneref(game:GetService("RunService"))
local entity = engocheat.libraries.entity

do
    local speedJanitor = engocheat.libraries.janitor.new()
    engocheat.ui.selfDestructJanitor:Add(speedJanitor, "Cleanup")
    engocheat.ui.speedFolder = engocheat.ui.characterTab:AddFolder("speed")
    engocheat.ui.speedEnabled = engocheat.ui.speedFolder:AddToggle("enabled", function(value)
        if (value) then
            speedJanitor:Add(runService.Heartbeat:Connect(function(dt)
                if (not entity.isAlive) then
                    return
                end

                if (not engocheat.ui.speedMode) then
                    return
                end

                local speedVal = engocheat.ui.speedValue.Value
                local moveDirection = entity.character.Humanoid.MoveDirection

                if (engocheat.ui.speedMode.Value == "cframe") then
                    local walkSpeed = entity.character.Humanoid.WalkSpeed
                    local speedValue = math.max(speedVal - walkSpeed, 0)
                    local addition = moveDirection * dt * speedValue

                    entity.character.HumanoidRootPart.CFrame += addition
                elseif (engocheat.ui.speedMode.Value == "velocity") then
                    local preVelocity = entity.character.HumanoidRootPart.Velocity
                    moveDirection = moveDirection * speedVal

                    entity.character.HumanoidRootPart.Velocity = Vector3.new(
                        moveDirection.X,
                        preVelocity.Y,
                        moveDirection.Z
                    )
                end
            end))
        else
            speedJanitor:Cleanup()
        end
    end)
    engocheat.ui.speedValue = engocheat.ui.speedFolder:AddSlider("value", nil, {
        min = 1,
        default = 16,
        max = 150,
    })
    engocheat.ui.speedMode = engocheat.ui.speedFolder:AddDropdown("mode", nil, {
        defaults = {"cframe", "velocity"},
        default = "cframe",
    })
end

-- Self destruct
do
    engocheat.ui.selfDestructButton = engocheat.ui.optionsTab:AddButton("remove cheat", function() 
        engocheat.ui.selfDestructJanitor:Cleanup()
    end)
end