ClientHelper = {}
ClientHelper.__index = ClientHelper


ClientEntityHelper = {}
ClientEntityHelper.__index = ClientEntityHelper



ClientItemHelper = {}
ClientItemHelper.__index = ClientItemHelper


ClientEquipmentHelper = {}
ClientEquipmentHelper.__index = ClientEquipmentHelper

ClientVisualHelper = {}
ClientVisualHelper.__index = ClientVisualHelper



JellyUIHelper = {}
JellyUIHelper.__index = JellyUIHelper

JellyUI = {}
JellyUI.__index = JellyUI





-- this is used so often that I wanted to use a shortcut
function _CC()
    local allHosts = Ext.Entity.GetAllEntitiesWithComponent("ClientControl")
    return allHosts[1]
end
