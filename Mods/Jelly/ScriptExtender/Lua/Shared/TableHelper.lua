TableHelper = {}
TableHelper.__index = TableHelper


-- Prints the first table in a table of tables
-- circumvents "Recursion depth exceeded while stringifying JSON"
---@param tbl table
function TableHelper.DumpS(tbl)
    if type(tbl) ~= "table" then
        print(tbl)  -- If it's not a table, just print the value directly
        return
    end
    
    print("{")
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print("  " .. tostring(key) .. " = { ... },")  -- Indicate that it's a nested table without dumping its contents
        else
            print("  " .. tostring(key) .. " = " .. tostring(value) .. ",")
        end
    end
    print("}")
end