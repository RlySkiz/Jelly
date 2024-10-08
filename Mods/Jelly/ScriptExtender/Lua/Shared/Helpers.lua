----------------------------------------------------------------------------------------
--
--                               For handling Helpers
--
----------------------------------------------------------------------------------------


Helpers = {}
Helpers.__index = Helpers

-- METHODS
--------------------------------------------------------------

-- TODO: Check if that even works
-- Generates a new UUID
function Helpers:GenerateUUID()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end


--Credit: Yoinked from Morbyte (Norbyte?)
-- TODO: Description
---@param srcObject any
---@param dstObject any
function Helpers:TryToReserializeObject(srcObject, dstObject)
    local serializer = function()
        local serialized = Ext.Types.Serialize(srcObject)
        Ext.Types.Unserialize(dstObject, serialized)
    end
    local ok, err = xpcall(serializer, debug.traceback)
    if not ok then
        return err
    end
    return nil
end


-- Function to clean the prefix and return only the ID
---@return string   - UUID
function Helpers:CleanPrefix(fullString)
    -- Use pattern matching to extract the ID part
    local id = fullString:match(".*_(.*)")
    return id
end



-- Checks if the substring 'sub' is present within the string 'str'.
---@param str string 	- The string to search within.
---@param sub string 	- The substring to look for.
---@return bool			- Returns true if 'sub' is found within 'str', otherwise returns false.
function Helpers:StringContains(str, sub)
    -- Make the comparison case-insensitive
    str = str:lower()
    sub = sub:lower()
    return (string.find(str, sub, 1, true) ~= nil)
end


function Helpers.StringContainsTwo(input, search)
    return string.find(input, search) ~= nil
end

-- Retrieves the value of a specified property from an object or returns a default value if the property doesn't exist.
---@param obj           - The object from which to retrieve the property value.
---@param propertyName  - The name of the property to retrieve.
---@param defaultValue  - The default value to return if the property is not found.
---@return value        - The value of the property if found; otherwise, the default value.
function Helpers:GetPropertyOrDefault(obj, propertyName, defaultValue)
    local success, value = pcall(function() return obj[propertyName] end)
    if success then
        return value or defaultValue
    else
        return defaultValue
    end
end

-- Tries to get the value of an entities component
---@param uuid              string      - The entity UUID to check
---@param previousComponent value       - component of previous iteration
---@param components        table       - Sorted list of component path
---@return Value                        - Returns the value of a field within a component
---@example
-- Entity:TryGetEntityValue("UUID", nil, {"ServerCharacter, "PlayerData", "HelmetOption"})
-- nil as previousComponent on first call because it iterates over this parameter during recursion
function Helpers.TryGetEntityValue(uuid, previousComponent, components)
    local entity = Ext.Entity.Get(uuid)
    if #components == 1 then -- End of recursion
        if not previousComponent then
            local value = Helpers:GetPropertyOrDefault(entity, components[1], nil)
            return value
        else
            local value = Helpers:GetPropertyOrDefault(previousComponent, components[1], nil)
            return value
        end
    end

    local currentComponent
    if not previousComponent then -- Recursion
        currentComponent = Helpers:GetPropertyOrDefault(entity, components[1], nil)
        -- obscure cases
        if not currentComponent then
            return nil
        end
    else
        currentComponent = Helpers:GetPropertyOrDefault(previousComponent, components[1], nil)
    end

    table.remove(components, 1)

    -- Return the result of the recursive call
    return Helpers.TryGetEntityValue(uuid, currentComponent, components)
end

Helpers.Character = {}
---@return EntityHandle|nil
function Helpers.Character:GetLocalControlledEntity()
    if Ext.IsServer() then
        return Ext.Entity.Get(Osi.GetHostCharacter())
    else
        for _, entity in pairs(Ext.Entity.GetAllEntitiesWithComponent("ClientControl")) do
            if entity.UserReservedFor.UserID == 1 then
                return entity
            end
        end
    end
end

Helpers.Timer = {}
---Ext.OnNextTick, but variable ticks
---@param ticks integer
---@param fn function
function Helpers.Timer:OnTicks(ticks, fn)
    local ticksPassed = 0
    local eventID
    eventID = Ext.Events.Tick:Subscribe(function()
        ticksPassed = ticksPassed + 1
        if ticksPassed >= ticks then
            fn()
            Ext.Events.Tick:Unsubscribe(eventID)
        end
    end)
end

function Helpers.IsScalar(v) -- by Norbyte
    local ty = Ext.Types.GetValueType(v)
    return ty == "nil" or ty == "string" or ty == "number" or ty == "boolean" or ty == "Enum" or ty == "Bitfield"
end


-- Return siblings of an element
function Helpers.GetSiblings(elem)
    return elem.ParentElement and elem.ParentElement.Children or {}
end

function Helpers.GetLastCharacter(str)
    return str:sub(-1)
end