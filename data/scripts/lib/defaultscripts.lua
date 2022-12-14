package.path = package.path .. ";data/scripts/lib/?.lua"
include ("stringutility")

function AddDefaultShipScripts(ship)
    if not valid(ship) then return end
    ship:addScriptOnce("data/scripts/entity/startbuilding.lua")
    ship:addScriptOnce("data/scripts/entity/entercraft.lua")
    ship:addScriptOnce("data/scripts/entity/exitcraft.lua")
    ship:addScriptOnce("data/scripts/entity/invitetogroup.lua")

    ship:addScriptOnce("data/scripts/entity/orderchain.lua")
    ship:addScriptOnce("data/scripts/entity/transfercrewgoods.lua")
end

function AddDefaultStationScripts(station)
    if not valid(station) then return end
    station:addScriptOnce("data/scripts/entity/startbuilding.lua")
    station:addScriptOnce("data/scripts/entity/entercraft.lua")
    station:addScriptOnce("data/scripts/entity/exitcraft.lua")

    station:addScriptOnce("data/scripts/entity/crewboard.lua")
    station:addScriptOnce("data/scripts/entity/backup.lua")
    station:addScriptOnce("data/scripts/entity/bulletinboard.lua")
    station:addScriptOnce("data/scripts/entity/story/bulletins.lua")
    station:addScriptOnce("data/scripts/entity/regrowdocks.lua")
    station:addScriptOnce("data/scripts/entity/missionbulletins.lua")

    station:addScriptOnce("data/scripts/entity/transfercrewgoods.lua")
    station:addScriptOnce("data/scripts/entity/utility/transportmode.lua")
end

function SetBoardingDefenseLevel(entity)
    if entity:hasComponent(ComponentType.Boarding) then
        local faction = Faction(entity.factionIndex)
        if not faction then return end
        if not faction.isAIFaction then return end

        local boarding = Boarding(entity)
        if not boarding then return end

        local careful = math.max(0, faction:getTrait("careful"))
        boarding.defenseLevel = 1 + careful -- 1.0 to 2.0
    end
end
