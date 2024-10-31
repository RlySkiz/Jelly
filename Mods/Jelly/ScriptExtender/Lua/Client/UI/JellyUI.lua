---@diagnostic disable: redefined-local, param-type-mismatch
JellyUI = {
    Instances = {}
}
function JellyUI:New(entity)
    local instance = setmetatable({
        Entity = entity,
        Window = nil,
        WindowPos = nil,
        WindowSize = nil,
        Colors = {},
        Visuals = {
            VisualArea = { -- e.g. "Entity" or "Equipment" UI Wrapper
                Visuals = {}
            },
        },
        Materials = {},
    },JellyUI)
    self.__index = self
    return instance
end


function JellyUI:Init(uuid)
    self.Instances[uuid] = self
    self.Window = Ext.IMGUI.NewWindow(ClientEntityHelper:GetName(self.Entity))
    self.Window.IDContext = uuid
    self.WindowPos = {0,0}
    self.WindowSize = {500, 500}
    self.Window:SetPos(self.WindowPos, "Always")
    self.Window:SetSize(self.WindowSize, "Always")
    self.Window.Closeable = true
    
    self.Colors = JellyColors:New(self)
    self.Colors.Window.IDContext = uuid .. "_Colors"
    self.Colors.Window:SetPos({self.WindowPos[1]+self.WindowSize[1], self.WindowPos[2]}, "Always")
    self.Colors.Window:SetSize({300, 250}, "FirstUseEver")
    self.Colors.Window.Closeable = true

    -- self:PremadeColors()
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
local function LoadAllEyeColors()
    preMadeColors["CharacterCreationEyeColor"] = Ext.StaticData.GetAll("CharacterCreationEyeColor")
end
local function LoadAllSkinColors()
    preMadeColors["CharacterCreationSkinColor"] = Ext.StaticData.GetAll("CharacterCreationSkinColor")
end
local function LoadAllPremadeColors()
    -- LoadAllDyeColors() -- Can't access MaterialPreset Names to StringContains "DYE"
    LoadAllHairColors()
    LoadAllEyeColors()
    LoadAllSkinColors()
end
local function GetPremadeColorsOfType(type)
    return preMadeColors[type]
end
local function GenerateAndReturnAllPremadeColors()
    LoadAllPremadeColors()
    return preMadeColors
end

JellyColors = {
    Instances = {}
}
function JellyColors:New()
    local instance = setmetatable({
        Window = Ext.IMGUI.NewWindow("Colors"),
        Types = {},
    },JellyColors)
    self.__index = self

    instance:PremadeColors()
    return instance
end

function JellyUI:GetOrCreate(entity)
    if self.Instances[entity.Uuid.EntityUuid] ~= nil then
        return self.Instances[entity.Uuid.EntityUuid]
    end

    local i = self:New(entity)
    i:Init(entity.Uuid.EntityUuid)
    return i
end

function JellyColors:PremadeColors()
    local colorTable = self.Window:AddTable("",1)
    -- colorTable.ScrollY = true
    for type,content in pairs(preMadeColors) do
        local colorCell = colorTable:AddRow():AddCell()
        local typeTree = colorCell:AddTree(type)
        local columns = 10
        local typeTable = typeTree:AddTable("", columns)
        -- typeTable.ScrollY = true
        local typeRow = typeTable:AddRow()
        self.Types[type] = {}
        for i,uuid in ipairs(content) do
            local color = Ext.StaticData.Get(uuid, type)
            -- Get name from charactercreationskincolors.lsx, and color from _merged with material presets - ask Astra 
            local name = Ext.Loca.GetTranslatedString(color.DisplayName.Handle.Handle)
            if i % columns == 1 then -- Create a new row if the current iteration is divisible by the set column count and equals
                typeRow = typeTable:AddRow()
            end
            local colEdit = typeRow:AddCell():AddColorEdit("")
            colEdit.NoInputs = true
            colEdit.Color = color.UIColor
            table.insert(self.Types[type], colEdit)
        end
    end
end
--#endregion

--#region Material Handling
local function GetWornEquipmentCount(ent)
    -- Might return unexpectd values, as only equipment that is currently visual is shown
    -- eg. is both meelee and ranged are equipped, onl the one "active" is in Equipment
    -- additonally, irregardless of visibility, both armor and camp clothing were always in Equipment
    return #Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment"})
end
local function GetSubVisualCount(ent, slot)
    return #Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals"})
end
local function GetMaterialCount(ent, slot, subVisual)
    return #Helpers.TryGetEntityValue(ClientEntityHelper:GetUuid(ent), nil, {"ClientEquipmentVisuals", "Equipment", slot, "SubVisuals", subVisual, "Visual", "Visual", "ObjectDescs"})
end
--#endregion


-- Create and handle updating of EditorElements (Sliders/Colorwheels) across multiple LOD
---comment
---@param area string            - "Equipment" or "Entity"
---@param Materials table        - table of IMGUIHandles [material instance UUID, IMGUIHandle]
---@param currentMaterial string - UUID
---@param parent ImguiHandle
---@param path table             - table with 3 integers ex: [1,2,3] that indicate the path to a specific material
---@param data table|integer     - current value of material
function JellyUI:HandleParameterData(area, Materials, currentMaterial, parent, path, data)
    local isUpdating = false

    -- Update parameter across all LOD levels for the current material
    ---comment
    ---@param partype string    - "Scalar" or "Vector3"
    ---@param editorVal table   - Value of the editor. For Vector 3 it's [r,g,b]. For Scalar it's [value] 
    local function UpdateAllLODParameters(partype, editorVal)

        -- prevent infinite loop
        if isUpdating then
            return
        end
        isUpdating = true
        for uuid, Material in pairs(Materials) do
            if uuid == currentMaterial then
                for LOD, LODTab in pairs(Material) do -- Material = {Bar = tabbar, LOD0 = LOD0Tab, LOD1 = LOD1Tab, ...}
                    if LOD ~= Material.Bar then -- To handle genOrGetMainMatBar recursion
                        local parameterTabs = LODTab.Children[1].Children -- Get the actual parameterTabs - Children[1] is the ParameterTabBar from GenerateParameterAreas()
                        for _, parameterTab in pairs(parameterTabs) do -- Go through all parameterTabs within this LOD tab
                            if parameterTab.Label == parent.ParentElement.Label then -- Gives .OnChange only access to its own parameterTab Type e.g. "ScalarParameters"
                                for _,parameter in pairs(parameterTab.Children) do -- Go through all parameters within the parameter type node
                                    if parameter.Label == parent.Label then -- Gives .OnChange only access to a parameter with the same name as its own elements' .ParentElement
                                        if partype == "Vector3" then
                                            local r, g, b = editorVal[1], editorVal[2], editorVal[3]
                                            local val = {r, g, b}
                                            -- _P("Updating Vector3 " .. parameter.Label .. " to " .. val .. " at " .. LOD)
                                            ClientVisualHelper:GetActiveMaterial(self.Entity, area, path):SetVector3(parameter.Label, val)
                                            parameter.Children[1].Color = editorVal

                                            -- TODO -  parameter.Children[1].OnChange() wsa necessary, as changing LOD1 did not show a change in the visuals
                                            -- changing LOD0 however always showed a change, even on other LODs
                                            -- Since there is no reason to change LODs separately, as they are getting synced anyways
                                            -- We can simplify this function and get rid of the isUpdating parameter.

                                            -- For this, also modify GenerateMaterials [1*]


                                            --parameter.Children[1].OnChange()

                                        elseif partype == "Scalar" then
                                            local val = editorVal[1]
                                            -- _P("Updating Scalar " .. parameter.Label .. " to " .. val .. " at " .. LOD)
                                            ClientVisualHelper:GetActiveMaterial(self.Entity, area, path):SetScalar(parameter.Label, val)
                                            parameter.Children[1].Value = editorVal
                                            --parameter.Children[1].OnChange()
                                        end 
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        isUpdating = false
    end

    local function CreateUIElementAndHandleChange(data, parent)
        if type(data) == "table" and #data > 1 then
            -- If data is a table with multiple values, treat it as a color edit element
            local editor = parent:AddColorEdit("", data)
            editor.NoAlpha = true
            editor.OnChange = function()
                if not isUpdating then
                    UpdateAllLODParameters("Vector3",editor.Color)
                end
            end
        else
            -- Otherwise, treat data as a scalar and create a slider
            local editor = parent:AddSlider("", data)
            editor.OnChange = function()
                if not isUpdating then
                    UpdateAllLODParameters("Scalar",editor.Value)
                end
            end
        end
    end
    CreateUIElementAndHandleChange(data, parent)
end


function JellyUI:GenerateParameterAreas(area, Materials, currentMaterial, parent, path)
    local materialInstance = ClientVisualHelper:GetMaterialInstance(self.Entity, area, path)
    local paramTabBar = parent:AddTabBar("")
    for paramTypeName, paramType in pairs(materialInstance.Parameters) do
        -- Check if the name of the parameter type contains "Scalar"
        if Helpers.StringContainsTwo(paramTypeName, "Scalar") or Helpers.StringContainsTwo(paramTypeName, "Vector3") then
            local paramTab = paramTabBar:AddTabItem(tostring(paramTypeName))
            for _, param in pairs(paramType) do
                local parTree = paramTab:AddTree(param.ParameterName)
                self:HandleParameterData(area, Materials, currentMaterial, parTree, path, param.Value)

                -- Reenable if we need both, BaseValue and Value
                -- local basevalTree = parTree:AddTree("BaseValue")
                -- local valueTree = parTree:AddTree("Value")
                -- self:HandleParameterData(area, basevalTree, path, param.BaseValue)
                -- self:HandleParameterData(area, valueTree, path, param.Value)
            end
        end
    end
end



-- TODO [1*]
-- Currently this function creates a new TabBar for each LOD for a uuid
-- instead, since we want to only use one LOD, we can directly show the values for LOD0
-- update logic for other LODs has to be handles on the entity directly

function JellyUI:GenerateMaterials(area, parent, slotIteration, visualIteration, materialHolder)
    local slotIteration = slotIteration or nil
    local materialsBar = parent:AddTabBar("")
    local Materials = {}
    local matCounter = 0

    for material, materialContent in pairs(materialHolder) do
        local materialInstance = materialContent.Renderable.ActiveMaterial.MaterialInstance
        local materialBar
        local lod

        -- Function to get or create the main material tab bar
        local function genOrGetMainMatBar(parent, uuid)
            if uuid and Materials[uuid] then
                return Materials[uuid].Bar -- If it exists, return
            else
                matCounter = matCounter + 1
                local mainMatTabItem = parent:AddTabItem("Material " .. tostring(matCounter))
                mainMatTabItem.IDContext = Ext.Math.Random()

                mainMatTabItem:AddText("MaterialInstance:")
                local matUuidInput = mainMatTabItem:AddInputText("")
                matUuidInput.Text = materialInstance.Name
                matUuidInput.SameLine = true

                local newMaterialBar = mainMatTabItem:AddTabBar("")
                newMaterialBar.IDContext = Ext.Math.Random()
                Materials[uuid] = {Bar = newMaterialBar}
                return newMaterialBar
            end
        end

        materialBar = genOrGetMainMatBar(materialsBar, materialInstance.Name)
        lod = materialBar:AddTabItem("LOD " .. tostring(materialContent.field_8))
        lod.IDContext = Ext.Math.Random()

        Materials[materialInstance.Name]["LOD"..materialContent.field_8] = lod -- Materials[uuid][LOD]["LODInstance"] = imguiHandle of the LOD

        self:GenerateParameterAreas(area, Materials, materialInstance.Name, lod, {slotIteration, visualIteration, material})
    end
end


function JellyUI:GenerateContent(area)
    local contentArea = self.Window:AddCollapsingHeader(area)
    self.Visuals.VisualArea[area] = {Area = contentArea, Visuals = {}}
    local materialHolder

    if area == "Equipment" then
        if self.Entity.ClientEquipmentVisuals then
            for slot,slotContent in pairs(self.Entity.ClientEquipmentVisuals.Equipment) do
                if slotContent.Item ~= null then
                    local eq = contentArea:AddTree(ClientItemHelper:GetItemName(slotContent.Item))
                    self.Visuals.VisualArea[area].Visuals[slot] = {Item = eq, SubVisuals = {}}
                    local visualTabBar = eq:AddTabBar("")
                    for subVisual,subVisualEntity in pairs(slotContent.SubVisuals) do
                        Ext.IO.SaveFile("Jelly/active_material.json", Ext.DumpExport(subVisualEntity:GetAllComponents()))
                        local materialParent = visualTabBar:AddTabItem("Visual " .. tostring(subVisual))
                        materialParent.IDContext = Ext.Math.Random()

                        materialHolder = subVisualEntity.Visual.Visual.ObjectDescs
                        self.Visuals.VisualArea[area].Visuals[slot].SubVisuals[subVisual] = {Visual = materialParent, MaterialHolder = materialHolder}
                        self:GenerateMaterials(area, materialParent, slot, subVisual, materialHolder)
                    end
                end
            end
        else
            _P("[Jelly] No Equipment Visuals")
            -- Mods.Jelly._CC().Visual.Visual.VisualEntity.Visual.Visual.VisualEntity:GetAllComponents()
        end
    elseif area == "Entity" then
        if self.Entity.Visual then
            for attachment,attachmentContent in pairs(self.Entity.Visual.Visual.Attachments) do
                Ext.IO.SaveFile("Jelly/attachment.json", Ext.DumpExport(attachmentContent))
                if attachmentContent.Visual ~= null then
                    local visualEntity = attachmentContent.Visual.VisualEntity
                    local visualResource = visualEntity.Visual.Visual.VisualResource
                    -- Ext.IO.SaveFile("Jelly/visual.json", Ext.DumpExport(visualEntity:GetAllComponents()))
                    if visualResource ~= null then
                        local materialParent = contentArea:AddTree(visualResource.Slot)
                        materialParent.IDContext = Ext.Math.Random()

                        materialHolder = attachmentContent.Visual.ObjectDescs
                        self:GenerateMaterials(area, materialParent, nil, attachment, materialHolder)
                    else
                        _P("[Jelly] VisualResource = null found")
                        Ext.IO.SaveFile("Jelly/visualEntity.json", Ext.DumpExport(visualEntity:GetAllComponents()))
                    end
                end
            end
        else
            _P("[Jelly] No Entity Visual")
        end
    end
end


-----------------------------------------------------------------------------------------------

local function giveNextFileName(wishFileName)
    local count = 1

    -- Strip the .json extension if it exists
    local baseName, ext = wishFileName:match("^(.-)(%.json)$")
    if not baseName then
        -- If the file doesn't end with .json, assume the whole input is the base name
        baseName = wishFileName
        ext = ".json"
    end

    local function giveNextFileNameRecurse(currentFileName)
        -- Check if the file exists
        if Ext.IO.LoadFile(currentFileName) == nil then
            return currentFileName
        else
            -- Recursively call with an incremented count
            count = count + 1
            return giveNextFileNameRecurse(baseName .. "_" .. tostring(count) .. ext)
        end
    end

    return giveNextFileNameRecurse(wishFileName)
end


local function OnSessionLoaded()
    LoadAllPremadeColors()

    local acquireSubHandle -- limit to one instance
    Ext.Entity.OnCreate("ClientControl", function(entity, ct, c)
        if acquireSubHandle then
            Ext.Events.Tick:Unsubscribe(acquireSubHandle)
        end
        acquireSubHandle = Helpers.Timer:OnTicks(10, function()
            -- grab what's currently selected, in case it's changed since last ClientControl
            local entity
            entity = Helpers.GetLocalControlledEntity()
            JellyUI:GetOrCreate(entity)
        end)
    end)

    -- Kaz Sound Test

    local allSounds = {}
    for _, sound in pairs(Ext.Resource.GetAll("Sound")) do
        local soundToDump = Ext.Resource.Get(sound, "Sound")
        allSounds[sound] = soundToDump
    end
    Ext.IO.SaveFile("Sounds/SoundDump.json", Ext.DumpExport(allSounds))

    local allVoiceBarks = {}
    for _, voiceBark in pairs(Ext.Resource.GetAll("VoiceBark")) do
        local voiceBarkToDump = Ext.Resource.Get(voiceBark, "VoiceBark")
        allVoiceBarks[voiceBark] = voiceBarkToDump
    end
    Ext.IO.SaveFile("VoiceBarks/VoiceBarksDump.json", Ext.DumpExport(allVoiceBarks))

end
Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)