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
