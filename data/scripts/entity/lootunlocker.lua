package.path = package.path .. ";data/scripts/lib/?.lua"

function initialize()
    if onServer() then
        local loots = {Sector():getEntitiesByType(EntityType.Loot)}
        for _,loot in pairs(loots) do
            loot.reservedPlayer = -1
            loot.excludedPlayer = -1
        end
    end
    terminate()
end
