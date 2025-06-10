--[[
    engocheat
    FILE: drawing.lua
    DESC: drawing library wrapper for engocheat
    BY: engo
]]

local runService = cloneref(game:GetService('RunService'))

local classes = {
    Base = {
        Visible = 'boolean',
        ZIndex = 'number',
        Transparency = 'number',
        Color = 'Color3'
    },
    Line = {
        Thickness = 'number',
        From = 'Vector2',
        To = 'Vector2'
    },
    Text = {
        Text = 'string',
        Size = 'number',
        Center = 'boolean',
        Outline = 'boolean',
        OutlineColor = 'Color3',
        Position = 'Vector2',
        TextBounds = 'Vector2',
        Font = 'number'
    },
    Image = {
        Data = 'string',
        Size = 'Vector2',
        Position = 'Vector2',
        Rounding = 'number'
    },
    Circle = {
        Thickness = 'number',
        NumSides = 'number',
        Radius = 'number',
        Filled = 'boolean',
        Position = 'Vector2'
    },
    Square = {
        Thickness = 'number',
        Size = 'Vector2',
        Position = 'Vector2',
        Filled = 'boolean'
    },
    Quad = {
        Thickness = 'number',
        PointA = 'Vector2',
        PointB = 'Vector2',
        PointC = 'Vector2',
        PointD = 'Vector2',
        Filled = 'boolean'
    },
    Triangle = {
        Thickness = 'number',
        PointA = 'Vector2',
        PointB = 'Vector2',
        PointC = 'Vector2',
        Filled = 'boolean'
    }
}

local drawing = {}
--[[
function drawing.new(class)
    local proxy = setmetatable({_instance = Drawing.new(class)}, {})
    local mt = getmetatable(proxy)
    local _class = classes[class]

    function proxy:Destroy()
        self._instance:Destroy()
    end

    mt.__index = function(t, k)
        print(t, k)
        if (classes.Base[k] or _class[k]) then
            return t._instance[k]
        end

        error(k .. ' is not valid member of drawing ' .. class)
    end

    mt.__newindex = function(t, k, v)
        print(t, k, v)
        local expectedType = classes.Base[k] or _class[k]
        local typeOf = typeof(v)
        if (expectedType and expectedType == typeOf) then
            t._instance[k] = v
            return
        end

        if (expectedType ~= typeOf) then
            return error(k .. ' invalid type for value in __newindex on ' .. class)
        end

        error(k .. ' is not valid member of drawing ' .. class)
    end

    return proxy
end]]


-- This may need some compat checks for diff script execs
drawing.is = function(obj)
    local success, metatable = pcall(getmetatable, obj)
    if (not success) then
        return false
    end

    if (metatable and (metatable.__type == 'Drawing' or metatable.__OBJECT)) then
        return true
    end

    return false
end

drawing.new = Drawing.new

return drawing