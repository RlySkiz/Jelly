


-- userid shows which client (human) has that character in their party.
-- the entity that has the component ClientControl is the host
-- TODO - implement Multiplayer compatibility. 
function ClientHelper:ClientGetHostEntity()
    local allHosts = Ext.Entity.GetAllEntitiesWithComponent("ClientControl")
    return allHosts[1] -- TODO - this returns the first one. Make this work for MP by also passing the userId as parameter
    -- local userID = entity.PartyMember.UserId
end


-- usually not possible on client, so here is a workaround for client
function ClientHelper:ClientGetHostCharacter()
    local entity = ClientHelper:ClientGetHostEntity()
    return ClientEntityHelper:GetUuid(entity)
end
