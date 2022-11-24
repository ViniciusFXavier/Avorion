package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include ("SectorGenerator")
local Xsotan = include ("story/xsotan")
local Placer = include ("placer")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local SectorSpecifics = include("sectorspecifics")
include("music")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y, seed, factionIndex, innerArea)
    local d2 = length2(vec2(x, y))

    if d2 < Balancing.BlockRingMin2 then
        if factionIndex then
            if innerArea then
                return 50
            else
                return 1500
            end
        else
            return 2500
        end
    else
        return 0
    end
end

function SectorTemplate.offgrid(x, y)
    return true
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return false
end

-- this function returns what relevant contents there will be in the sector (exact)
function SectorTemplate.contents(x, y)
    local seed = Seed(string.join({GameSeed(), x, y, "xsotantransformed"}, "-"))
    math.randomseed(seed);
    local random = random()
    local contents = {ships = 0, stations = 0, seed = tostring(seed)}

    contents.xsotan = random:getInt(10, 15)
    contents.ships = contents.xsotan
    contents.wreckageEstimation = 20

    return contents, random
end

function SectorTemplate.musicTracks()
    local good = {
        primary = combine(TrackCollection.Desolate()),
        secondary = combine(TrackCollection.Melancholic()),
    }

    local neutral = {
        primary = combine(TrackCollection.Desolate()),
        secondary = combine(TrackCollection.Melancholic(), TrackCollection.Middle()),
    }

    local bad = {
        primary = combine(TrackCollection.Middle(), TrackCollection.Desolate()),
        secondary = TrackCollection.Neutral(),
    }

    return good, neutral, bad
end

function SectorTemplate.split(entity)

    local plan = Plan(entity.index)

    -- disable accumulation of health to disable expensive superflous recalculations of health
    plan.accumulatingHealth = false

    local blocks = plan.numBlocks
    local bb = plan.boundingBox
    local bblower = bb.lower
    local bbupper = bb.upper
    local bbsize = bb.size

    local toDestroy = {}
    for i = 0, blocks - 1 do
        local block = plan:getNthBlock(i)
        local b = block.box
        local lower = b.lower
        local upper = b.upper

        local add
        for p = 1, 3 do

            local x = bblower.x + bbsize.x * 0.25 * p
            if x > lower.x and x < upper.x then
                add = true
                break
            end

            local y = bblower.y + bbsize.y * 0.25 * p
            if y > lower.y and y < upper.y then
                add = true
                break
            end

            local z = bblower.z + bbsize.z * 0.25 * p
            if z > lower.z and z < upper.z then
                add = true
                break
            end
        end

        if add then
            table.insert(toDestroy, block.index)
        end
    end

    plan:destroy(unpack(toDestroy))

    plan.accumulatingHealth = true
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    local contents, random = SectorTemplate.contents(x, y)

    -- take a random generation script
    local specs = SectorSpecifics();
    specs:addTemplates()

    local template = specs.templates[random:getInt(1, #specs.templates)]
    while string.match(template.path, "xsotan") or template:offgrid(x, y) do
        template = specs.templates[random:getInt(1, #specs.templates)]
    end

    template.generate(player, seed, x, y)

    local generator = SectorGenerator(x, y)
    local sector = Sector()

    -- destroy everything
    local entities = {sector:getEntitiesByComponent(ComponentType.Owner)}
    for _, entity in pairs(entities) do

        -- remove backup script so there won't be any additional ships
        if entity:hasComponent(ComponentType.Scripts) then
            for i, script in pairs(entity:getScripts()) do
                if string.match(script, "backup") then
                    entity:removeScript(script) -- don't spawn military ships coming for help
                end
            end
        end

        if entity:hasComponent(ComponentType.Durability) then
            if Faction(entity.factionIndex).isAIFaction then
                local blockPlan = Plan(entity.id):getMove()
                local wreckage = generator:createWreckage(faction, blockPlan, 0)
                SectorTemplate.split(wreckage)

                entity:clearCargoBay()
                sector:deleteEntity(entity)
            end
        else
            entity.factionIndex = 0
        end
    end

    -- delete loot
    local loot = {sector:getEntitiesByType(EntityType.Loot)}
    for _, entity in pairs(loot) do
        sector:deleteEntity(entity)
    end

    for _, wreckage in pairs({sector:getEntitiesByType(EntityType.Wreckage)}) do
        local deletionTimer = DeletionTimer(wreckage)
        if valid(deletionTimer) then
            deletionTimer:disable()
        end
    end

    -- re-orient them all
    for _, entity in pairs({sector:getEntities()}) do
        entity.orientation = MatrixLookUp(random:getDirection(), random:getDirection())
    end

    -- generate xsotan
    Xsotan.infectAsteroids()

    local ships = {}
    -- spawn special xsotan
    -- don't spawn carrier, as the xsotan fighters are too much here
    -- don't spawn rift DLC xsotan outside of rifts
    local spawnedSummoner = false
    local spawnedQuantum = false
    for i = 1, contents.ships do
        if not spawnedSummoner and random:test(0.1) then
            local xsotan = Xsotan.createSummoner(generator:getPositionInSector(), random:getFloat(0.5, 2.0))
            table.insert(ships, xsotan)
            spawnedSummoner = true
        elseif not spawnedQuantum and random:test(0.1) then
            local xsotan = Xsotan.createQuantum(generator:getPositionInSector(), random:getFloat(0.5, 2.0))
            table.insert(ships, xsotan)
            spawnedQuantum = true
        else
            local xsotan = Xsotan.createShip(generator:getPositionInSector(), random:getFloat(0.5, 2.0))
            table.insert(ships, xsotan)
        end
    end
    -- add enemy buffs
    SpawnUtility.addEnemyBuffs(ships)

    for _, script in pairs(sector:getScripts()) do
        sector:removeScript(script)
    end


    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
