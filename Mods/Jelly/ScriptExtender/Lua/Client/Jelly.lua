local ent = Ext.Entity.Get("fa026ba4-2758-51e3-ceaa-26229f8b6b59")

local w = Ext.IMGUI.NewWindow("Jelly")
local testText = w:AddText("Test")
local sep = w:AddSeparatorText("")
local tabbar = w:AddTabBar("")

Jelly = {}

local function GenerateInputScalarsFromData(parent, data)
    local inputs = {}
    if type(data) == "Table" then
        for i,val in ipairs(data) do
            local vec3 = parent:AddInputScalar("", val)
            vec3.SameLine = true
            table.insert(inputs, vec3)
        end
    elseif type(data) == "Number" then
        local num = parent:AddInputScalar("", data)
        table.insert(inputs, num)
    end

    return inputs
end

local function GenerateParameterAreas(parent, params)
    for _,param in pairs(params) do
        local parTree = parent:AddTree(param.ParameterName)
        local basevalTree = parTree:AddTree("BaseValue")
        local valueTree = parTree:AddTree("Value")
        GenerateInputScalarsFromData(basevalTree, param.BaseValue)
        GenerateInputScalarsFromData(valueTree, param.Value)
    end
end

function Jelly.GenerateArmorAreas()
    for equipment,slot in pairs(ent.ClientEquipmentVisuals.Equipment) do
        if slot.Item ~= null then
            local eq = tabbar:AddTabItem(ClientItemHelper:GetItemName(slot.Item))
            
            local visualTabBar = eq:AddTabBar("")
            for _,subvis in pairs(slot.SubVisuals) do
                local visCount = 1
                local vis = visualTabBar:AddTabItem("Visual" .. tostring(visCount))
                visCount = visCount + 1

                local materialTabBar = vis:AddTabBar("")
                for _,material in pairs(subvis.Visual.Visual.ObjectDescs) do
                    local materialInstance = material.Renderable.ActiveMaterial.MaterialInstance
                    local mat = materialTabBar:AddTabItem(materialInstance.Name)
                    local maybeLOD = mat:AddText("LOD Level: " .. tostring(material.field_8))

                    local paramTabBar = mat:AddTabBar("")
                    local parameters = materialInstance.Parameters
                    if parameters.ScalarParameters[1] then
                        local scalarTab = paramTabBar:AddTabItem("ScalarParameters")
                        GenerateParameterAreas(scalarTab, materialInstance.Parameters.Vector3Parameters)
                    end
                    if parameters.Vector3Parameters[1] then
                        local vector3Tab = paramTabBar:AddTabItem("Vector3Parameters")
                        GenerateParameterAreas(vector3Tab, materialInstance.Parameters.Vector3Parameters)
                    end
                end
            end
        end
    end
end

Jelly.GenerateArmorAreas()