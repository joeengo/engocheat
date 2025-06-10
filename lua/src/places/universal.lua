--[[
    engocheat
    FILE: universal.lua
    DESC: the universal game script for engocheat
    BY: engo
]]

local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local camera = cloneref(workspace.CurrentCamera)
local entity = engocheat.libraries.entity
local drawing = engocheat.libraries.drawing

-- references
local tMain = engocheat.ui.mainTab
local tCharacter = engocheat.ui.characterTab
local tVisuals = engocheat.ui.visualsTab
local tMisc = engocheat.ui.miscTab
local tOptions = engocheat.ui.optionsTab

local cheats = {}
engocheat.cheats = cheats

-- MAIN TAB

-- CHARACTER TAB
do
    local speed = {}
    speed.janitor = engocheat.libraries.janitor.new()
    speed.folder = tCharacter:AddFolder('speed')
    speed.enabled = speed.folder:AddToggle('enabled', function(value)
        if (value) then
            speed.janitor:Add(runService.Heartbeat:Connect(function(dt)
                if (not entity.isAlive) then
                    return
                end

                local humanoid: Humanoid = entity.character.Humanoid
                local speedValue = speed.value.Value
                local moveDirection = humanoid.MoveDirection

                if (speed.mode.Value == 'cframe') then
                    local walkSpeed = humanoid.WalkSpeed
                    local speedValue = math.max(speedValue - walkSpeed, 0)
                    local addition = moveDirection * dt * speedValue

                    entity.character.HumanoidRootPart.CFrame += addition
                elseif (speed.mode.Value == 'velocity') then
                    local preVelocity = entity.character.HumanoidRootPart.Velocity
                    local speedVector = moveDirection * speedValue

                    entity.character.HumanoidRootPart.Velocity = Vector3.new(
                        speedVector.X,
                        preVelocity.Y,
                        speedVector.Z
                    )
                end

                if (speed.bhopEnabled.Value) then
                    if ((humanoid:GetState() == Enum.HumanoidStateType.Running) and ((moveDirection * Vector3.new(1, 0, 1)).Magnitude ~= 0)) then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end))
        else
            speed.janitor:Cleanup()
        end
    end)

    speed.bhopEnabled = speed.folder:AddToggle('bunny hop')

    speed.value = speed.folder:AddSlider('value', nil, {
        min = 1,
        default = 16,
        max = 150,
    })

    speed.mode = speed.folder:AddDropdown('mode', nil, {
        defaults = {'cframe', 'velocity'},
        default = 'cframe',
    })

    engocheat.selfDestructJanitor:Add(speed.janitor, 'Cleanup')
    cheats.speed = speed
end

do
    local fly = {}
    fly.janitor = engocheat.libraries.janitor.new()
    fly.folder = tCharacter:AddFolder('fly')
    fly.enabled = fly.folder:AddToggle('enabled', function(value)
        if (value) then
            fly.janitor:Add(runService.Heartbeat:Connect(function(dt)
                if (not entity.isAlive) then
                    return
                end

                local gravityFrame = workspace.Gravity * dt
                local up, down = inputService:IsKeyDown(Enum.KeyCode.Space), inputService:IsKeyDown(Enum.KeyCode.LeftControl)
                local yUnit = up and 1 or down and -1 or 0
                local yValue = (yUnit * fly.vspeed.Value) + gravityFrame
                local speedValue = fly.speed.Value
                local moveDirection = entity.character.Humanoid.MoveDirection
                local preVelocity = entity.character.HumanoidRootPart.Velocity

                if (fly.mode.Value == 'cframe') then
                    local addition = moveDirection * dt * speedValue
                    entity.character.HumanoidRootPart.CFrame += addition
                    entity.character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, yValue, 0)
                elseif (fly.mode.Value == 'velocity') then
                    local speedVector = moveDirection * speedValue
                    entity.character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                        speedVector.X,
                        yValue,
                        speedVector.Z
                    )
                end
            end))
        else
            fly.janitor:Cleanup()
        end
    end)

    fly.speed = fly.folder:AddSlider('speed', nil, {
        min = 1,
        default = 16,
        max = 150,
    })

    fly.vspeed = fly.folder:AddSlider('vertical speed', nil, {
        min = 1,
        default = 5,
        max = 50,
    })

    fly.mode = fly.folder:AddDropdown('mode', nil, {
        defaults = {'cframe', 'velocity'},
        default = 'cframe',
    })

    engocheat.selfDestructJanitor:Add(fly.janitor, 'Cleanup')
    cheats.fly = fly
end

-- VISUALS TAB

-- Probably the best looking/worst performing esp i've ever made...
do
    local wallhack = {}
    wallhack.janitor = engocheat.libraries.janitor.new()
    wallhack.signals = {}
    wallhack.signals.outlineColorChanged = engocheat.libraries.signal.new()
    wallhack.folder = tVisuals:AddFolder('player wallhacks')

    -- wallhack helper functions
    function wallhack.getBoundingBoxPoints(cframe, size)
        local x, y, z = size.X / 2, size.Y / 2, size.Z / 2

        return {
            cframe * Vector3.new(x, y, z),
            cframe * Vector3.new(-x, y, z),
            cframe * Vector3.new(x, -y, z),
            cframe * Vector3.new(-x, -y, z),
            cframe * Vector3.new(x, y, -z),
            cframe * Vector3.new(-x, y, -z),
            cframe * Vector3.new(x, -y, -z),
            cframe * Vector3.new(-x, -y, -z),
        }
    end

    function wallhack.getCharacterPoints(character)
        local points = {}
        for _, v in character:GetDescendants() do
            if (v:IsA('BasePart')) then
                local size = v.Size
                local cframe = v.CFrame

                local points3d = wallhack.getBoundingBoxPoints(cframe, size)
                for _, point in points3d do
                    table.insert(points, point)
                end
            end
        end
        return points
    end

    function wallhack.cast3dTo2dPoints(points3d)
        local points2d = {}
        for _, point in points3d do
            local screenPoint, onScreen = camera:WorldToViewportPoint(point)
            if (onScreen) then
                table.insert(points2d, {vector = Vector2.new(screenPoint.X, screenPoint.Y), zindex = screenPoint.Z})
            end
        end
        return points2d
    end

    function wallhack.compute2dBoundingBox(points2d)
        if #points2d == 0 then
            return
        end
        
        --> Initialize extrema
        local xMin, xMax = points2d[1].vector.X, points2d[1].vector.X
        local yMin, yMax = points2d[1].vector.Y, points2d[1].vector.Y
        
        --> Find min/max x, y
        for _, point in points2d do
            xMin = math.min(xMin, point.vector.X)
            xMax = math.max(xMax, point.vector.X)
            yMin = math.min(yMin, point.vector.Y)
            yMax = math.max(yMax, point.vector.Y)
        end
        
        return {
            Vector2.new(xMin, yMin),
            Vector2.new(xMax, yMin),
            Vector2.new(xMax, yMax),
            Vector2.new(xMin, yMax),
            zindex = points2d[1].zindex
        }
    end

    function wallhack.computeTextPosition(box, textSize, mode)
        local x = (box[1].X + box[3].X) / 2 - textSize.X / 2
        if (mode == 'bottom') then
            local y = box[3].Y
            return Vector2.new(x, y)
        elseif (mode == 'top') then
            local y = box[1].Y - textSize.Y
            return Vector2.new(x, y)
        end
    end

    function wallhack.getText(ent)
        local text = 'player'

        if (ent.Player) then
            text = ent.Player.Name
        elseif (ent.Character) then
            text = ent.Character.Name
        end

        if (ent.NPC) then
            text = '[NPC] ' .. text
        end

        return text
    end

    function wallhack.getTracerFromPosition(mode)
        if (mode == 'center') then
            return camera.ViewportSize / 2
        elseif (mode == 'mouse') then
            local vec = inputService:GetMouseLocation()
            return Vector2.new(vec.X, vec.Y)
        elseif (mode == 'top') then
            return Vector2.new(camera.ViewportSize.X / 2, 0)
        elseif (mode == 'bottom') then
            return Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
        end
    end

    function wallhack.inRange(a, b, c)
        local epsilon = 1e-5
        return math.min(a, b) - epsilon <= c and c <= math.max(a, b) + epsilon
    end

    function wallhack.computeLineIntersection(p1, p2, q1, q2)
        local x1, y1 = p1.X, p1.Y
        local x2, y2 = p2.X, p2.Y
        local x3, y3 = q1.X, q1.Y
        local x4, y4 = q2.X, q2.Y

        local denom = ((x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4))
        if (denom == 0) then
            return nil
        end

        local px = ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4)) / denom
        local py = ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4)) / denom
        local intersection = Vector2.new(px, py)

        if (wallhack.inRange(x1, x2, px) and wallhack.inRange(y1, y2, py) and wallhack.inRange(x3, x4, px) and wallhack.inRange(y3, y4, py)) then
            return intersection
        end

        return nil
    end

    function wallhack.computeLineBoxIntersectionPoint(ent, box, from, to)
        local intersections = {}
        for i = 1, 4 do
            local p1 = box[i]
            local p2 = box[(i % 4) + 1]
            local intersection = wallhack.computeLineIntersection(p1, p2, from, to)
            if (intersection) then
                table.insert(intersections, intersection)
            end
        end

        return intersections[1] or to
    end

    function wallhack.getTracerToPosition(mode, ent, box, fromPosition)
        if (mode == 'head') then
            local vec, vis = camera:WorldToViewportPoint(ent.Head.Position) -- TODO: add non-vis check and point in their direction, possibly add a seperate option for this, like on screen tracers -- same for root mode below!
            return vis and Vector2.new(vec.X, vec.Y) or nil
        elseif (mode == 'root') then
            local vec, vis = camera:WorldToViewportPoint(ent.RootPart.Position)
            return vis and Vector2.new(vec.X, vec.Y) or nil
        elseif (mode == 'center') then
            local centerX = (box[1].X + box[3].X) / 2
            local centerY = (box[1].Y + box[3].Y) / 2
            return Vector2.new(centerX, centerY)
        elseif (mode == 'top') then
            local topY = box[1].Y
            return Vector2.new((box[1].X + box[3].X) / 2, topY)
        elseif (mode == 'bottom') then
            local bottomY = box[3].Y
            return Vector2.new((box[1].X + box[3].X) / 2, bottomY)
        elseif (mode == 'box intersection') then
            local centerX = (box[1].X + box[3].X) / 2
            local centerY = (box[1].Y + box[3].Y) / 2
            local center = Vector2.new(centerX, centerY)
            return wallhack.computeLineBoxIntersectionPoint(ent, box, fromPosition, center)
        end
    end

    function wallhack.constructSkeleton(ent, preComputedParts)
        local skeleton, skeletonParts = {}, preComputedParts or nil
        local humanoid = ent.Humanoid
        if (not skeletonParts) then
            if humanoid.RigType == Enum.HumanoidRigType.R6 then
                skeletonParts = {
                    {ent.Head, ent.Character.Torso},
                    {ent.Character.Torso, ent.Character["Left Arm"]},
                    {ent.Character.Torso, ent.Character["Right Arm"]},
                    {ent.Character.Torso, ent.Character["Left Leg"]},
                    {ent.Character.Torso, ent.Character["Right Leg"]}
                }
            elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
                skeletonParts = {
                    {ent.Head, ent.Character.UpperTorso},
                    {ent.Character.UpperTorso, ent.Character.LowerTorso},
                    {ent.Character.UpperTorso, ent.Character.LeftUpperArm},
                    {ent.Character.LeftUpperArm, ent.Character.LeftLowerArm},
                    {ent.Character.LeftLowerArm, ent.Character.LeftHand},
                    {ent.Character.UpperTorso, ent.Character.RightUpperArm},
                    {ent.Character.RightUpperArm, ent.Character.RightLowerArm},
                    {ent.Character.RightLowerArm, ent.Character.RightHand},
                    {ent.Character.LowerTorso, ent.Character.LeftUpperLeg},
                    {ent.Character.LeftUpperLeg, ent.Character.LeftLowerLeg},
                    {ent.Character.LeftLowerLeg, ent.Character.LeftFoot},
                    {ent.Character.LowerTorso, ent.Character.RightUpperLeg},
                    {ent.Character.RightUpperLeg, ent.Character.RightLowerLeg},
                    {ent.Character.RightLowerLeg, ent.Character.RightFoot},
                }
            else
                return
            end
        end
        
        for idx, pair in skeletonParts do
            local part1, part2 = pair[1], pair[2]
            if part1 and part2 then
                local line = drawing.new('Line')
                skeleton[idx] = line
            end
        end
        
        return skeleton, skeletonParts
    end

    function wallhack.forEveryDrawing(tab, fn)
        for idx, val in tab do
            if (drawing.is(val)) then
                fn(val)
            elseif (type(val) == 'table') then
                wallhack.forEveryDrawing(val, fn)
            end
        end
    end

    -- WallhackObject class
    local WallhackObject = {}; do
        function WallhackObject.new(ent)
            local self = setmetatable({
                _drawingrefs = {},
                _entity = ent,
                _connections = {},
                _Visible = true,
            }, {
                __index = function(t, k)
                    if (k == 'Visible') then
                        k = '_' .. k
                    end

                    return rawget(t, k) or WallhackObject[k]
                end,
                __newindex = function(t, k, v)
                    if (k == 'Visible') then
                        k = '_' .. k
                        return wallhack.forEveryDrawing(t._drawingrefs, function(drawing)
                            drawing.Visible = v
                        end)
                    end

                    rawset(t, k, v)
                end
            })

            self:Init()
            return self
        end

        function WallhackObject:Init()
            local refs = self._drawingrefs
            local ent = self._entity
                
            refs.box = drawing.new('Quad')
            refs.box.Color = engocheat.ui.api.options.main_color
            refs.box.Thickness = 1
            refs.box.Filled = false

            refs.boxOutline = drawing.new('Quad')
            refs.boxOutline.Color = wallhack.outlineColor.Value
            refs.boxOutline.Thickness = 2
            refs.boxOutline.Filled = false

            refs.tracer = drawing.new('Line')
            refs.tracer.Color = engocheat.ui.api.options.main_color
            refs.tracer.Thickness = 1

            refs.tracerOutline = drawing.new('Line')
            refs.tracerOutline.Color = wallhack.outlineColor.Value
            refs.tracerOutline.Thickness = 2

            refs.text = drawing.new('Text')
            refs.text.Color = engocheat.ui.api.options.main_color
            refs.text.Text = wallhack.getText(ent)
            refs.text.Size = 16
            refs.text.Outline = true
            refs.text.OutlineColor = wallhack.outlineColor.Value
            refs.text.Font = Drawing.Fonts.UI

            local skeleton, skeletonParts = wallhack.constructSkeleton(ent)
            refs.skeleton = skeleton
            refs.skeletonParts = skeletonParts

            local skeletonOutline, _ = wallhack.constructSkeleton(ent, skeletonParts)
            refs.skeletonOutline = skeletonOutline

            for idx, line in skeleton do
                line.Color = engocheat.ui.api.options.main_color
                line.Thickness = 1
            end

            for idx, line in skeletonOutline do
                line.Color = wallhack.outlineColor.Value
                line.Thickness = 2
            end

            table.insert(self._connections, wallhack.signals.outlineColorChanged:Connect(function(color)
                refs.boxOutline.Color = color
                refs.tracerOutline.Color = color
                refs.text.OutlineColor = color

                for _, line in refs.skeletonOutline do
                    line.Color = color
                end
            end))

            table.insert(self._connections, engocheat.signals.colorThemeChanged:Connect(function(color)
                refs.box.Color = color
                refs.tracer.Color = color
                refs.text.Color = color
                
                for _, line in refs.skeleton do
                    line.Color = color
                end
            end))
        end

        local CONSTANT_BOX_SIZE = Vector3.new(3.75, 5, 3.75)
        function WallhackObject:Update()
            local ent = self._entity
            local refs = self._drawingrefs
            local points3d

            if (wallhack.targetCheckEnabled.Value) then 
                self.baseVisible = ent.Targetable
            else
                self.baseVisible = true
            end

            if (wallhack.boxMode.Value == 'bounding box') then
                local bbCFrame, bbSize = ent.Character:GetBoundingBox()
                points3d = wallhack.getBoundingBoxPoints(bbCFrame, bbSize)
            elseif (wallhack.boxMode.Value == 'part vertices') then
                points3d = wallhack.getCharacterPoints(ent.Character)
            elseif (wallhack.boxMode.Value == 'constant') then
                points3d = wallhack.getBoundingBoxPoints(ent.HumanoidRootPart.CFrame, CONSTANT_BOX_SIZE)
            end

            local points2d = wallhack.cast3dTo2dPoints(points3d)
            local box = wallhack.compute2dBoundingBox(points2d)
            if (not box) then
                if (self.Visible) then
                    self.Visible = false
                end

                return
            end

            local zindex = box.zindex
            box.zindex = nil

            if (wallhack.boxesEnabled.Value) then
                refs.box.PointA = box[1]
                refs.box.PointB = box[2]
                refs.box.PointC = box[3]
                refs.box.PointD = box[4]
                refs.box.ZIndex = zindex + 1

                refs.boxOutline.PointA = box[1]
                refs.boxOutline.PointB = box[2]
                refs.boxOutline.PointC = box[3]
                refs.boxOutline.PointD = box[4]
                refs.boxOutline.ZIndex = zindex
            end

            if (wallhack.textEnabled.Value) then
                local textPosition = wallhack.computeTextPosition(box, refs.text.TextBounds, wallhack.textMode.Value)
                refs.text.Position = textPosition
                refs.text.ZIndex = zindex
            end

            local renderTracer = wallhack.tracersEnabled.Value
            if (renderTracer) then
                local From = wallhack.getTracerFromPosition(wallhack.tracerFrom.Value)
                local To = wallhack.getTracerToPosition(wallhack.tracerTo.Value, ent, box, From)
                if (To and From) then
                    refs.tracer.To = To
                    refs.tracer.From = From
                    refs.tracer.ZIndex = zindex + 1

                    refs.tracerOutline.To = To
                    refs.tracerOutline.From = From
                    refs.tracerOutline.ZIndex = zindex
                else
                    renderTracer = false
                end
            end

            if (wallhack.skeletonEnabled.Value) then
                for idx, line in refs.skeleton do
                    local part = refs.skeletonParts[idx]
                    local part1, part2 = part[1], part[2]

                    local vec1, vis1 = camera:WorldToViewportPoint(part1.Position)
                    local vec2, vis2 = camera:WorldToViewportPoint(part2.Position)

                    if (vis1 and vis2) then
                        line.From = Vector2.new(vec1.X, vec1.Y)
                        line.To = Vector2.new(vec2.X, vec2.Y)

                        line.ZIndex = vec1.Z
                    else
                        line.Visible = false
                    end
                end

                for idx, line in refs.skeletonOutline do
                    local normalLine = refs.skeleton[idx]
                    if (normalLine and normalLine.To and normalLine.From) then
                        line.From = normalLine.From
                        line.To = normalLine.To

                        line.ZIndex = normalLine.ZIndex - 1
                    else
                        line.Visible = false
                    end
                end
            end

            refs.box.Visible = (wallhack.boxesEnabled.Value) and self.baseVisible
            refs.boxOutline.Visible = (wallhack.boxesEnabled.Value) and (wallhack.boxesOutlineEnabled.Value) and self.baseVisible
            refs.tracer.Visible = (renderTracer) and self.baseVisible
            refs.tracerOutline.Visible = (renderTracer and wallhack.tracersOutlineEnabled.Value) and self.baseVisible
            refs.text.Visible = (wallhack.textEnabled.Value) and self.baseVisible
            refs.text.Outline = (wallhack.textOutlineEnabled.Value) and self.baseVisible

            for _, line in refs.skeleton do
                line.Visible = (wallhack.skeletonEnabled.Value) and self.baseVisible
            end

            for _, line in refs.skeletonOutline do
                line.Visible = (wallhack.skeletonEnabled.Value) and (wallhack.skeletonOutlineEnabled.Value) and self.baseVisible
            end
        end

        function WallhackObject:Destroy()
            wallhack.forEveryDrawing(self._drawingrefs, function(drawing)
                drawing.Visible = false
                drawing:Destroy()
            end)

            for _, connection in self._connections do
                connection:Disconnect()
            end

            self._connections = nil
            self._drawingrefs = nil
        end
    end
    
    -- Wallhack module

    wallhack.enabled = wallhack.folder:AddToggle('enabled', function(value)
        if (not value) then
            wallhack.janitor:Cleanup()
            return
        end

        local WallhackObjects = {}
        for _, ent in entity.List do
            local WallhackObject = WallhackObject.new(ent)
            table.insert(WallhackObjects, WallhackObject)
        end

        wallhack.janitor:Add(entity.Events.EntityAdded:Connect(function(ent)
            local WallhackObject = WallhackObject.new(ent)
            table.insert(WallhackObjects, WallhackObject)
        end), 'Disconnect')

        wallhack.janitor:Add(entity.Events.EntityRemoved:Connect(function(ent)
            for i, WallhackObject in WallhackObjects do
                if (WallhackObject._entity == ent) then
                    WallhackObject:Destroy()
                    table.remove(WallhackObjects, i)
                    break
                end
            end
        end), 'Disconnect')

        wallhack.janitor:Add(runService.PreRender:Connect(function()
            for _, WallhackObject in WallhackObjects do
                WallhackObject:Update()
            end
        end))

        wallhack.janitor:Add(function()
            for _, WallhackObject in WallhackObjects do
                WallhackObject:Destroy()
            end
        end)
    end)

    wallhack.boxesEnabled = wallhack.folder:AddToggle('boxes', function(value) end)
    wallhack.boxesOutlineEnabled = wallhack.folder:AddToggle('boxes outlined', function(value) end)

    -- Tracers
    wallhack.tracersEnabled = wallhack.folder:AddToggle('tracers', function(value) end)
    wallhack.tracersOutlineEnabled = wallhack.folder:AddToggle('tracers outlined', function(value) end)

    -- Name text
    wallhack.textEnabled = wallhack.folder:AddToggle('name', function(value) end)
    wallhack.textOutlineEnabled = wallhack.folder:AddToggle('name outlined', function(value) end)

    wallhack.skeletonEnabled = wallhack.folder:AddToggle('skeleton', function(value) end)
    wallhack.skeletonOutlineEnabled = wallhack.folder:AddToggle('skeleton outlined', function(value) end)

    wallhack.targetCheckEnabled = wallhack.folder:AddToggle('targetable check', function(value) end)

    wallhack.boxMode = wallhack.folder:AddDropdown('box calculation', function(value) end, {
        defaults = {'bounding box', 'part vertices', 'constant'},
        default = 'bounding box',
    })

    wallhack.tracerFrom = wallhack.folder:AddDropdown('tracer from', function(value) end, {
        defaults = {'center', 'mouse', 'top', 'bottom'},
        default = 'center',
    })
    wallhack.tracerTo = wallhack.folder:AddDropdown('tracer to', function(value) end, {
        defaults = {'head', 'root', 'center', 'top', 'bottom', 'box intersection'},
        default = 'head',
    })

    wallhack.textMode = wallhack.folder:AddDropdown('name position', function(value) end, {
        defaults = {'bottom', 'top'},
        default = 'bottom',
    })

    wallhack.folder:AddLabel('outline color')
    wallhack.outlineColor = wallhack.folder:AddColorPicker(function(color)
        wallhack.signals.outlineColorChanged:Fire(color)
    end, Color3.new(0, 0, 0))

    cheats.wallhack = wallhack
end


-- OPTIONS TAB

do
    local buildName = engocheat_developer and 'developer' or 'release'
    tOptions:AddLabel(`engocheat v0.1.0 | {buildName} build | engos.site/engocheat`)
end

do
    tOptions:AddLabel('color theme')
    engocheat.signals.colorThemeChanged = engocheat.libraries.signal.new()
    engocheat.ui.colorTheme = tOptions:AddColorPicker(function(color)
        engocheat.ui.api.options.main_color = color
        engocheat.signals.colorThemeChanged:Fire(color)
    end, engocheat.ui.api.options.main_color or Color3.new(1, 0, 0))
end

do
    tOptions:AddButton('remove cheat', function()
        engocheat.selfDestructJanitor:Cleanup()
    end)
end

do
    tOptions:AddKeybind('ui toggle key', function()
        if imgui then
            imgui.Enabled = not imgui.Enabled
        end
    end, {
        default = Enum.KeyCode.RightShift,
    })
end