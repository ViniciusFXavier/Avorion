package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

function getUpdateInterval()
    return 15 * 60
end

function initialize()
    local self = Entity()

    if onServer() then
        local pos = random():getVector(-1, 1) * 500
        ShipAI(self.index):setFly(pos, 100)
    end

end


function updateServer(timeStep)
    Entity():addScriptOnce("deletejumped.lua")
end
