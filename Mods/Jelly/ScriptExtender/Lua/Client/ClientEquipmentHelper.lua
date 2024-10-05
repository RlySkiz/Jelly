local EQUIPMENT_TYPES = {

    "Helmet",
    "Armor",
    "Cloak",
    "Weapon", -- or lightsource
    "Shield",
    "BowLeft", -- or Crossbow
    "BowRight", -- or Crossbow,
    "?",
    "Underwear",
    "Boots",
    "Gloves",
    "?",
    "?",
    "?",
    "?",
    "?",
    "Instrument",
    "Clothes",
    "Shoes"
}


---comment
---@param name string
function ClientEquipmentHelper:GetEquipmentTypeNumberByName(name)
    for index, n in ipairs(EQUIPMENT_TYPES) do
        if name == n then
            return index
        end
    end

    print("JELLY ", name " is not a valid equipment type")
end



-- Example usage: _D(Mods.Jelly.ClientEquipmentHelper:GetSubVisuals(Mods.Jelly._CC(), "Armor"))
---@param entity EntityHandle
---@param equipmentType string
---@return table<ExtComponentType,BaseComponent>
function ClientEquipmentHelper:GetSubVisuals(entity, equipmentType) 

    local index = ClientEquipmentHelper:GetEquipmentTypeNumberByName(equipmentType)
    return entity.ClientEquipmentVisuals.Equipment[index].SubVisuals
end
