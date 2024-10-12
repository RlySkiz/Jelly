


---@param entity EntityRef 
---@param area string - "Equipment" or "Entity" 
---@param path table  - table with 3 integers ex: [1,2,3] that indicate the path to a specific material
---@return RenderableObject 
function ClientVisualHelper:GetRenderable(entity, area, path)

    if (not area == "Equipment") and (not area == "Entity") then
        print("[Jelly] ", area , " is not a valid parameter, choose Equipment or Entity")
        return
    end

    local slot = path[1]
    local subVisualOrAttachment = path[2]
    local material = path[3]


    local pathToEquipmentRenderable = {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisualOrAttachment, "Visual", "Visual", "ObjectDescs", material, "Renderable"}
    local pathToEntityRenderable = {"Visual", "Visual", "Attachments", subVisualOrAttachment, "Visual", "ObjectDescs", material, "Renderable"}

    if area == "Equipment" then
        return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(entity), nil, pathToEquipmentRenderable)
    elseif area == "Entity" then
        return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(entity), nil,pathToEntityRenderable)
    end
end


---@param entity EntityRef 
---@param area string - "Equipment" or "Entity" 
---@param path table  - table with 3 integers ex: [1,2,3] that indicate the path to a specific material
---@return ActiveMaterial 
function ClientVisualHelper:GetActiveMaterial(entity, area, path)

    local renderable = ClientVisualHelper:GetRenderable(entity, area, path)
    return renderable.ActiveMaterial
end


---@param entity EntityRef 
---@param area string - "Equipment" or "Entity" 
---@param path table  - table with 3 integers ex: [1,2,3] that indicate the path to a specific material
---@return Material 
function ClientVisualHelper:GetMaterialInstance(entity, area, path)

    local activeMaterial = ClientVisualHelper:GetActiveMaterial(entity, area, path)
    return activeMaterial.MaterialInstance
end

