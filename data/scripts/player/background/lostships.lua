
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LostShips
LostShips = {}

function LostShips.getUpdateInterval()
    return 5
end

function LostShips.updateServer()
    local faction = getParentFaction()
    local names = {faction:getShipNames()}
    local galaxy = Galaxy()

    for _, name in pairs(names) do
        local entry = ShipDatabaseEntry(faction.index, name)
        local x, y = entry:getCoordinates()

        if entry:getAvailability() == ShipAvailability.Available then
            if galaxy:sectorInRift(x, y) and not galaxy:sectorLoaded(x, y) then
                if entry:getScriptValue("left_in_rift") then
                    entry:setAvailability(ShipAvailability.Destroyed)
                    entry:setScriptValue("lost_in_rift", true)
                    entry:setScriptValue("left_in_rift", nil)

                    -- give turrets back as they'd be lost
                    if GameSettings().reconstructionAllowed then
                        local turrets = entry:getTurrets()
                        local inventory = faction:getInventory()

                        for turret, info in pairs(turrets) do
                            inventory:add(InventoryTurret(turret))
                        end
                    end
                else
                    if faction.isPlayer then
                        entry:setCoordinates(faction:getReconstructionSiteCoordinates())
                    elseif faction.isAlliance then
                        -- alliance has no reconstruction site, use the first members' reconstruction site
                        local members = {faction:getMembers()}

                        -- an alliance is guaranteed to have at least 1 member
                        local first = nil
                        for _, playerIndex in pairs(members) do
                            first = Player(playerIndex)
                            break
                        end

                        entry:setCoordinates(first:getReconstructionSiteCoordinates())
                    end
                end
            end
        end
    end
end
