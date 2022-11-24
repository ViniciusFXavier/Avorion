package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MissionBulletins
MissionBulletins = {}

if onServer() then

function MissionBulletins.random()
    if not MissionBulletins.randomGenerator then
        local id = Server().sessionId
        local seed = Seed(id.string .. Entity().id.string .. tostring(os.time()))

        MissionBulletins.randomGenerator = Random(seed)
    end

    return MissionBulletins.randomGenerator
end

function MissionBulletins.initialize()
end

function MissionBulletins.getUpdateInterval()
    return 1
end

function MissionBulletins.updateServer(timeStep)
    MissionBulletins.updateBulletins(timeStep)
end

local updateFrequency = 60 * 60
local updateTime
function MissionBulletins.updateBulletins(timeStep)

    if not updateTime then
        -- by adding half the time here, we have a chance that a military outpost immediately has a bulletin
        updateTime = 0

        local r = MissionBulletins.random()
        local minutesSimulated = r:getInt(10, 80)
        minutesSimulated = 65
        for i = 1, minutesSimulated do -- simulate bulletin posting / removing
            MissionBulletins.updateBulletins(60)
        end
    end

    updateTime = updateTime + timeStep

    -- don't execute the following code if the time hasn't exceeded the posting frequency
    if updateTime < updateFrequency then return end
    updateTime = updateTime - updateFrequency

    MissionBulletins.addOrRemoveMissionBulletin()
end

function MissionBulletins.addOrRemoveMissionBulletin()
    local scripts = MissionBulletins.getPossibleMissions()
    if #scripts == 0 then return end

    local scriptPath = MissionBulletins.getWeightedRandomEntry(scripts)
    local ok, bulletin = run(scriptPath, "getBulletin", Entity())

    if ok == 0 and bulletin then
        local r = MissionBulletins.random()

        -- since in this case "add" can override "remove", adding a bulletin is slightly more likely than removing one
        local add = r:test(0.3)
        local remove = r:test(0.2)

        if add then
            -- add bulletins
            Entity():invokeFunction("bulletinboard", "postBulletin", bulletin)
        elseif remove then
            -- ... or remove bulletins
            Entity():invokeFunction("bulletinboard", "removeBulletin", bulletin.brief)
        end
    end
end

function MissionBulletins.getWeightedRandomEntry(scripts)
    -- ... determine which mission will be generated at this station
    local scriptsByWeight = {}

    for i, script in pairs(scripts) do
        if script then
            scriptsByWeight[i] = script.prob
        end
    end

    local i = selectByWeight(MissionBulletins.random(), scriptsByWeight)
    return scripts[i].path
end

function MissionBulletins.getPossibleMissions()
    local station = Entity()
    local stationTitle = station.title

    local scripts = {}

    -- delivery and organize are done by tradingmanager.lua without getBulletin-Function
--    table.insert(scripts, {path = "data/scripts/player/missions/delivery.lua", prob = 0})
--    table.insert(scripts, {path = "data/scripts/player/missions/organizegoods.lua", prob = 0})

    -- use this to have missions only spawn at certain stations
    -- Probabilites always have to add up to 10, so that ratio of missions can be seen easier
    if stationTitle == "Habitat" then
        table.insert(scripts, {path = "data/scripts/player/missions/settlertreck/settlertreck.lua", prob = 2})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission1.lua", prob = 2.5, maxDistToCenter = 300}) -- find relic
        table.insert(scripts, {path = "data/scripts/player/missions/freeslaves.lua", prob = 1, minDistToCenter = 25})
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 2})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission4.lua", prob = 1.5}) -- prove innocence
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 3})
    end

    if stationTitle == "${faction} Headquarters" then
        table.insert(scripts, {path = "data/scripts/player/missions/settlertreck/settlertreck.lua", prob = 1})
        table.insert(scripts, {path = "data/scripts/player/missions/hideevidence.lua", prob = 1})
        table.insert(scripts, {path = "data/scripts/player/missions/exploresector/exploresector.lua", prob = 2})
        table.insert(scripts, {path = "data/scripts/player/missions/clearpiratesector.lua", prob = 2})
        table.insert(scripts, {path = "data/scripts/player/missions/clearxsotansector.lua", prob = 1})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission4.lua", prob = 3}) -- prove innocence
    end

    if stationTitle == "Research Station" then
        table.insert(scripts, {path = "data/scripts/player/missions/exploresector/exploresector.lua", prob = 5})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission3.lua", prob = 2}) -- hackathon
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission1.lua", prob = 2.5, maxDistToCenter = 300}) -- find relic
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 4.0})
    end

    if stationTitle == "Trading Post" then
        table.insert(scripts, {path = "data/scripts/player/missions/transfervessel.lua", prob = 0.5})
        table.insert(scripts, {path = "data/scripts/player/missions/investigatemissingfreighters.lua", prob = 2, minDistToCenter = 50})
        table.insert(scripts, {path = "data/scripts/player/missions/freeslaves.lua", prob = 0.5, minDistToCenter = 25})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission2.lua", prob = 2, maxDistToCenter = 300}) -- illuminated
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission4.lua", prob = 2.5}) -- prove innocence
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 2.0})
    end

    if stationTitle == "Military Outpost" then
        table.insert(scripts, {path = "data/scripts/player/missions/hideevidence.lua", prob = 2})
        table.insert(scripts, {path = "data/scripts/player/missions/exploresector/exploresector.lua", prob = 1.5})
        table.insert(scripts, {path = "data/scripts/player/missions/clearpiratesector.lua", prob = 1.5})
        table.insert(scripts, {path = "data/scripts/player/missions/clearxsotansector.lua", prob = 1.5})
        table.insert(scripts, {path = "data/scripts/player/missions/coverretreat.lua", prob = 2})
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 1})
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 2.0})
    end

    if stationTitle == "Shipyard" then
        table.insert(scripts, {path = "data/scripts/player/missions/transfervessel.lua", prob = 4})
        table.insert(scripts, {path = "data/scripts/player/missions/investigatemissingfreighters.lua", prob = 3, minDistToCenter = 50})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission2.lua", prob = 2, maxDistToCenter = 300}) -- illuminated
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 2.0})
    end

    if stationTitle == "Repair Dock" then
        table.insert(scripts, {path = "data/scripts/player/missions/transfervessel.lua", prob = 4})
        table.insert(scripts, {path = "data/scripts/player/missions/investigatemissingfreighters.lua", prob = 3, minDistToCenter = 50})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission2.lua", prob = 2, maxDistToCenter = 300}) -- illuminated
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 2.0})
    end

    if stationTitle == "Smuggler's Market" or stationTitle == "Smuggler Hideout" then
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 4})
        table.insert(scripts, {path = "data/scripts/player/missions/clearpiratesector.lua", prob = 4})
        table.insert(scripts, {path = "data/scripts/player/missions/clearxsotansector.lua", prob = 1})
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 3})
    end

    if stationTitle == "Equipment Dock" then
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 4})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission3.lua", prob = 6}) -- hackathon
    end

    if stationTitle == "Casino" then
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 4})
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission1.lua", prob = 3, maxDistToCenter = 300}) -- find relic
        table.insert(scripts, {path = "internal/dlc/blackmarket/player/missions/sidemissions/sidemission3.lua", prob = 2}) -- hackathon
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 3})
    end

    if stationTitle == "Biotope" then
        table.insert(scripts, {path = "data/scripts/player/missions/investigatemissingfreighters.lua", prob = 5, minDistToCenter = 50})
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 5})
    end

    if stationTitle == "Fighter Factory" then
        table.insert(scripts, {path = "data/scripts/player/missions/investigatemissingfreighters.lua", prob = 5, minDistToCenter = 50})
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 5})
    end

    if stationTitle == "Resource Depot" then
        table.insert(scripts, {path = "data/scripts/player/missions/investigatemissingfreighters.lua", prob = 5, minDistToCenter = 50})
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 5})
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 3.0})
    end

    if stationTitle == "Turret Factory" then
        table.insert(scripts, {path = "data/scripts/player/missions/investigatemissingfreighters.lua", prob = 5, minDistToCenter = 50})
        table.insert(scripts, {path = "data/scripts/player/missions/bountyhuntmission.lua", prob = 5})
    end

    if string.match(stationTitle, " Mine") then
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 10})
    end

    if stationTitle == "Scrapyard" then
        table.insert(scripts, {path = "data/scripts/player/missions/receivecaptainmission.lua", prob = 10})
    end

    -- only choose the missions that should be occuring in that region
    local possibleScripts = {}
    local x, y = Sector():getCoordinates()
    local distance = (x * x) + (y * y)

    for _, script in pairs(scripts) do
        local minDist = script.minDistToCenter or 0
        local maxDist = script.maxDistToCenter or 710 -- this is the highest possible distance (corner sectors)

        if distance >= (minDist * minDist) and distance <= (maxDist * maxDist) then
            table.insert(possibleScripts, script)
        end
    end

    return possibleScripts
end

end
