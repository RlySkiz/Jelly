
---@param item EntityHandle
function ClientItemHelper:GetItemName(item)
    return Ext.Loca.GetTranslatedString(item.DisplayName.NameKey.Handle.Handle)
end