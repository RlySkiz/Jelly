
-- for testing use entity = ClientHelper:ClientGetHostEntity()

---@param entity EntityHandle
---@return string uuid
function ClientEntityHelper:GetUuid(entity)
    return entity.Uuid.EntityUuid
end 



---@param entity EntityHandle
---@return string name
function ClientEntityHelper:GetName(entity)
    return Ext.Loca.GetTranslatedString(entity.DisplayName.NameKey.Handle.Handle)
end 



---@param entity EntityHandle
---@return table<ExtComponentType,BaseComponent>
function ClientEntityHelper:GetVisual(entity) 
    return entity.Visual.Visual
end



---@param entity EntityHandle
---@param equipmentType string
---@return table<ExtComponentType,BaseComponent>
function ClientEntityHelper:GetEquipmentOfType(entity, equipmentType) 

    local index = ClientEquipmentHelper:GetEquipmentTypeNumberByName(equipmentType)
    return entity.ClientEquipmentVisuals.Equipment[index].Item
end
