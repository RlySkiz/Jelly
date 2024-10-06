local ent = _CC()

local w = Ext.IMGUI.NewWindow("Jelly")
--local tabbar = w:AddTabBar("")

Jelly = {}

local function GetMaterialInstance(ent, path)
    local slot = path[1]
    local subVisual = path[2]
    local material = path[3]
    return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisual, "Visual", "Visual", "ObjectDescs", material, "Renderable", "ActiveMaterial", "MaterialInstance"})
end

function GetActiveMaterial(ent, path)
    local slot = path[1]
    local subVisual = path[2]
    local material = path[3]
    return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisual, "Visual", "Visual", "ObjectDescs", material, "Renderable", "ActiveMaterial"})
end



local function GetRenderable(ent, path)
    local slot = path[1]
    local subVisual = path[2]
    local material = path[3]
    return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisual, "Visual", "Visual", "ObjectDescs", material, "Renderable"})
end


local function HandleParameterData(parent, ent, path, data)
    if type(data) == "table" then
        if #data > 1 then
            local colPicker = parent:AddColorEdit("", data)
            --colPicker.Size = {100,100}
            colPicker.OnChange = function()
                Ext.IO.SaveFile("Jelly/active_material.json", Ext.DumpExport(GetActiveMaterial(ent, path)))
                GetActiveMaterial(ent, path).SetVector3(colPicker.Color)
                print("materialInctance")
                _D(GetMaterialInstance(ent, path))
                --data[1] = colPicker.Color[1]
                --data[2] = colPicker.Color[2]
                --data[3] = colPicker.Color[3]
                -- No [4] since alpha doesn't exist in vec3 params
            end
        end
    else
        local slider = parent:AddSlider("", data)
        slider.OnChange = function()
            GetActiveMaterial(ent, path).SetScalar(slider.Value)
            --data = slider.Value
        end
    end
end


local function GenerateParameterAreas(parent, ent, path)
    local materialInstance = GetMaterialInstance(ent, path)
    local paramTabBar = parent:AddTabBar("")
    for paramTypeName, paramType in pairs(materialInstance.Parameters) do
        -- Check if the name of the parameter type contains "Scalar"
        if Helpers.StringContainsTwo(paramTypeName, "Scalar") or Helpers.StringContainsTwo(paramTypeName, "Vector3") then
            local paramTab = paramTabBar:AddTabItem(tostring(paramTypeName))
            for _, param in pairs(paramType) do
                local parTree = paramTab:AddTree(param.ParameterName)
                local basevalTree = parTree:AddTree("BaseValue")
                local valueTree = parTree:AddTree("Value")
                HandleParameterData(basevalTree, ent, path, param.BaseValue) -- don't pass param-BaseValue, pass Entitty and path to circumvent Lifetime issues
                HandleParameterData(valueTree, ent, path, param.Value)
            end
        end
    end
end

function Jelly.GenerateArmorAreas()
    for slot,slotContent in pairs(ent.ClientEquipmentVisuals.Equipment) do
        if slotContent.Item ~= null then
            --local eq = tabbar:AddTabItem(ClientItemHelper:GetItemName(slotContent.Item))
            local eq = w:AddCollapsingHeader(ClientItemHelper:GetItemName(slotContent.Item))

            local visualTabBar = eq:AddTabBar("")
            for subVisual,subVisualContent in pairs(slotContent.SubVisuals) do
                local visCount = 1
                local vis = visualTabBar:AddTabItem("Visual" .. tostring(visCount))
                visCount = visCount + 1

                local materialTabBar = vis:AddTabBar("")
                for material,materialContent in pairs(subVisualContent.Visual.Visual.ObjectDescs) do
                    local materialInstance = materialContent.Renderable.ActiveMaterial.MaterialInstance
                    local mat = materialTabBar:AddTabItem(materialInstance.Name)

                    mat:AddSeparator()
                    local maybeLOD = mat:AddText("LOD Level: " .. tostring(materialContent.field_8))
                    GenerateParameterAreas(mat, ent, {slot,subVisual,material})
                end
            end
        end
    end
end

Jelly.GenerateArmorAreas()