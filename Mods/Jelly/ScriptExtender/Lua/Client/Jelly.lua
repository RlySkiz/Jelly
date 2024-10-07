-- local ent = _CC()

--local tabbar = w:AddTabBar("")
Jelly = {
    Instances = {}
}
-- Jelly.__index = Jelly

function Jelly:New(entity)
    local instance = setmetatable({
        Window = nil,
        Entity = entity
    },Jelly)
    self.__index = self
    return instance
end

function Jelly:GetOrCreate(entity)
    if self.Instances[entity.Uuid.EntityUuid] ~= nil then
        return self.Instances[entity.Uuid.EntityUuid]
    end

    local i = self:New(entity)
    i:Init(entity.Uuid.EntityUuid)
    return i
end

function Jelly:Init(uuid)
    self.Instances[uuid] = self
    self.Window = Ext.IMGUI.NewWindow(Ext.Loca.GetTranslatedString(self.Entity.DisplayName.NameKey.Handle.Handle))
    self.Window.IDContext = uuid
    self.Window:SetSize({500, 500}, "FirstUseEver")
    self.Window.Closeable = true
    
    self:PremadeColors()
    self:GenerateContent("Entity")
    self:GenerateContent("Equipment")

    self.Window.OnClose = function (e)
        for i,instance in ipairs(self.Instances) do
            if instance == self then
                table.remove(self.Instances, i)
            end
        end
        self.Window:Destroy()
    end
end

--#region Color Handling
local preMadeColors = {}
local function LoadAllDyeColors()
    local dyes = {}
    local allPresets = Ext.Resource.GetAll("MaterialPreset")
    for _,preset in pairs(allPresets) do
        local resource = Ext.Resource.Get(preset, "MaterialPreset")
        _D(resource)
        if resource.Name then
            if Helpers:StringContains(Ext.Resource.Get(resource, "MaterialPreset").Name, "DYE_ARM") then
                table.insert(dyes, preset)
            end
        end
    end
    preMadeColors["Dyes"] = dyes
end
local function LoadAllHairColors()
    preMadeColors["CharacterCreationHairColor"] = Ext.StaticData.GetAll("CharacterCreationHairColor")
end
local function LoadtAllEyeColors()
    preMadeColors["CharacterCreationEyeColor"] = Ext.StaticData.GetAll("CharacterCreationEyeColor")
end
local function LoadtAllSkinColors()
    preMadeColors["CharacterCreationSkinColor"] = Ext.StaticData.GetAll("CharacterCreationSkinColor")
end
local function LoadAllPremadeColors()
    -- LoadAllDyeColors() -- Can't access MaterialPreset Names to StringContains "DYE"
    LoadAllHairColors()
    LoadtAllEyeColors()
    LoadtAllSkinColors()
end
local function GetPremadeColorsOfType(type)
    return preMadeColors[type]
end
local function GenerateAndReturnAllPremadeColors()
    LoadAllPremadeColors()
    return preMadeColors
end
--#endregion

function Jelly:PremadeColors()
    local colorTable = self.Window:AddTable("",1)
    local colorCell = colorTable:AddRow():AddCell()
    -- colorTable.ScrollY = true
    for type,content in pairs(preMadeColors) do
        local typeTree = colorCell:AddTree(type)
        local typeTable = typeTree:AddTable("", 20)
        -- typeTable.ScrollY = true
        local typeRow = typeTable:AddRow()
        for i,uuid in ipairs(content) do
            local color = Ext.StaticData.Get(uuid, type)
            local name = Ext.Loca.GetTranslatedString(color.DisplayName.Handle.Handle)
            if i % 20 == 0 then
                typeRow = typeTable:AddRow()
            end
            local colEdit = typeRow:AddCell():AddColorEdit("")
            colEdit.NoInputs = true
            colEdit.Color = color.UIColor
        end
    end
end

--#region Material Handling
local function GetWornEquipmentCount(ent)
    return #Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment"})
end
local function GetSubVisualCount(ent, slot)
    return #Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals"})
end
local function GetMaterialCount(ent, slot, subVisual)
    return #Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisual, "Visual", "Visual", "ObjectDescs"})
end

function Jelly:GetMaterialInstance(area, path)
    local slot = path[1]
    local subVisualOrAttachment = path[2]
    local material = path[3]
    if area == "Equipment" then
    return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(self.Entity), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisualOrAttachment, "Visual", "Visual", "ObjectDescs", material, "Renderable", "ActiveMaterial", "MaterialInstance"})
    elseif area == "Entity" then
        return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(self.Entity), nil, {"Visual", "Visual", "Attachments", subVisualOrAttachment, "Visual", "ObjectDescs", material, "Renderable", "ActiveMaterial", "MaterialInstance"})
    end
end
function Jelly:GetActiveMaterial(area, path)
    local slot = path[1]
    local subVisualOrAttachment = path[2]
    local material = path[3]
    if area == "Equipment" then
        return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(self.Entity), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisualOrAttachment, "Visual", "Visual", "ObjectDescs", material, "Renderable", "ActiveMaterial"})
    elseif area == "Entity" then
        return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(self.Entity), nil, {"Visual", "Visual", "Attachments", subVisualOrAttachment, "Visual", "ObjectDescs", material, "Renderable", "ActiveMaterial"})
    end
end
function Jelly:GetRenderable(area, path)
    local slot = path[1]
    local subVisualOrAttachment = path[2]
    local material = path[3]
    if area == "Equipment" then
        return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(self.Entity), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisualOrAttachment, "Visual", "Visual", "ObjectDescs", material, "Renderable"})
    elseif area == "Entity" then
        return Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(self.Entity), nil, {"Visual", "Visual", "Attachments", subVisualOrAttachment, "Visual", "ObjectDescs", material, "Renderable"})
    end
end

--#endregion

function Jelly:HandleParameterData(area, parent, path, data)
    if type(data) == "table" then
        if #data > 1 then
            local colEdit = parent:AddColorEdit("", data)
            colEdit.NoAlpha = true
            colEdit.OnChange = function()
                -- Ext.IO.SaveFile("Jelly/active_material.json", Ext.DumpExport(GetActiveMaterial(ent, path)))
                local r,g,b = colEdit.Color[1], colEdit.Color[2], colEdit.Color[3]
                self:GetActiveMaterial(area, path):SetVector3(colEdit.ParentElement.ParentElement.Label, {r,g,b})
            end
        end
    else
        local slider = parent:AddSlider("", data)
        slider.OnChange = function()
            self.GetActiveMaterial(area, path):SetScalar(slider.ParentElement.ParentElement.Label, slider.Value[1])
            --data = slider.Value
        end
    end
end


function Jelly:GenerateParameterAreas(area, parent, path)
    local materialInstance = self:GetMaterialInstance(area, path)
    local paramTabBar = parent:AddTabBar("")
    for paramTypeName, paramType in pairs(materialInstance.Parameters) do
        -- Check if the name of the parameter type contains "Scalar"
        if Helpers.StringContainsTwo(paramTypeName, "Scalar") or Helpers.StringContainsTwo(paramTypeName, "Vector3") then
            local paramTab = paramTabBar:AddTabItem(tostring(paramTypeName))
            for _, param in pairs(paramType) do
                local parTree = paramTab:AddTree(param.ParameterName)
                local basevalTree = parTree:AddTree("BaseValue")
                local valueTree = parTree:AddTree("Value")
                self:HandleParameterData(area, basevalTree, path, param.BaseValue)
                self:HandleParameterData(area, valueTree, path, param.Value)
            end
        end
    end
end

function Jelly:GenerateMaterials(area, parent, slotIteration, visualIteration, materialHolder)
    local slotIteration = slotIteration or nil
    local materialTabBar = parent:AddTabBar("")
    local LOD0Mats = {}
    for material,materialContent in pairs(materialHolder) do
        local mat
        local materialInstance = materialContent.Renderable.ActiveMaterial.MaterialInstance
        if LOD0Mats[materialInstance.Name] then
            mat = materialTabBar:AddTabItem("Material " .. tostring(LOD0Mats[materialInstance.Name]) .. "_LOD" .. tostring(materialContent.field_8))
        else
            mat = materialTabBar:AddTabItem("Material " .. tostring(material))
        end
        LOD0Mats[materialInstance.Name] = material

        mat:AddText("MaterialInstance:")
        local matName = mat:AddInputText("")
        matName.Text = materialInstance.Name
        matName.SameLine = true
        self:GenerateParameterAreas(area, mat, {slotIteration, visualIteration, material})
    end
end

function Jelly:GenerateContent(area)
    local contentArea = self.Window:AddCollapsingHeader(area)
    local materialHolder

    if area == "Equipment" then
        for slot,slotContent in pairs(self.Entity.ClientEquipmentVisuals.Equipment) do
            if slotContent.Item ~= null then
                local eq = contentArea:AddTree(ClientItemHelper:GetItemName(slotContent.Item))
                local visualTabBar = eq:AddTabBar("")
                for subVisual,subVisualEntity in pairs(slotContent.SubVisuals) do
                    Ext.IO.SaveFile("Jelly/active_material.json", Ext.DumpExport(subVisualEntity:GetAllComponents()))
                    local materialParent = visualTabBar:AddTabItem("Visual " .. tostring(subVisual))

                    materialHolder = subVisualEntity.Visual.Visual.ObjectDescs
                    self:GenerateMaterials(area, materialParent, slot, subVisual, materialHolder)
                end
            end
        end
    elseif area == "Entity" then
        for attachment,attachmentContent in pairs(self.Entity.Visual.Visual.Attachments) do
            Ext.IO.SaveFile("Jelly/attachment.json", Ext.DumpExport(attachmentContent))
            if attachmentContent.Visual ~= null then
                local visualEntity = attachmentContent.Visual.VisualEntity
                -- Ext.IO.SaveFile("Jelly/visual.json", Ext.DumpExport(visualEntity:GetAllComponents()))
                local materialParent = contentArea:AddTree(visualEntity.Visual.Visual.VisualResource.Slot)

                materialHolder = attachmentContent.Visual.ObjectDescs
                self:GenerateMaterials(area, materialParent, nil, attachment, materialHolder)
            end
        end
    end
end


-----------------------------------------------------------------------------------------------

local acquireSubHandle -- limit to one instance
Ext.Entity.OnCreate("ClientControl", function(entity, ct, c)
    if acquireSubHandle then
        Ext.Events.Tick:Unsubscribe(acquireSubHandle)
    end
    acquireSubHandle = Helpers.Timer:OnTicks(10, function()
        -- grab what's currently selected, in case it's changed since last ClientControl
        local entity
        entity = Helpers.Character:GetLocalControlledEntity()
        Jelly:GetOrCreate(entity)
    end)
end)

local function OnSessionLoaded()
    LoadAllPremadeColors()
end
Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)