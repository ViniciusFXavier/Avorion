
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include ("SectorGenerator")
local Xsotan = include("story/xsotan")
local Placer = include("placer")
local Balancing = include("galaxy")
local SpawnUtility = include ("spawnutility")
include("music")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y, seed, factionIndex, innerArea)
    local d2 = length2(vec2(x, y))

    if d2 < Balancing.BlockRingMin2 then
        if factionIndex then
            if innerArea then
                return 0
            else
                return 500
            end
        else
            return 750
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
    local seed = Seed(string.join({GameSeed(), x, y, "xsotanbreeders"}, "-"))
    math.randomseed(seed);
    local random = random()
    local contents = {ships = 0, stations = 0, seed = tostring(seed)}

    contents.xsotan = random:getInt(5, 10)
    contents.ships = contents.xsotan

    contents.resourceAsteroids = random:getInt(0, 1)

    local generator = SectorGenerator(x, y)
    contents.asteroidEstimation = generator:estimateAsteroidNumbers(2.5 + contents.resourceAsteroids, 1.5)

    return contents, random
end

function SectorTemplate.musicTracks()
    local good = {
        primary = combine(TrackCollection.Desolate(), TrackCollection.Melancholic()),
        secondary = combine(TrackCollection.Melancholic()),
    }

    local neutral = {
        primary = combine(TrackCollection.Desolate(), TrackCollection.Melancholic()),
        secondary = combine(TrackCollection.Melancholic(), TrackCollection.Middle()),
    }

    local bad = {
        primary = combine(TrackCollection.Middle(), TrackCollection.Desolate()),
        secondary = TrackCollection.Neutral(),
    }

    return good, neutral, bad
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    local contents, random = SectorTemplate.contents(x, y)

    local generator = SectorGenerator(x, y)

    local numFields = random:getInt(2, 3)
    for i = 1, numFields do
        generator:createAsteroidField(0.075)
    end

    for i = 1, contents.resourceAsteroids do
        local position = generator:createAsteroidField(0.075)
        generator:createBigAsteroid(position)
    end

    local w = 10
    local h = 15
    for i = 1, w do
        for j = 1, h do
            if random:test(0.9) then
                local translation = vec3(j * 70, 0, i * 70)
                local position = MatrixLookUpPosition(vec3(1, 0, 0), vec3(0, 1, 0), translation)
                Xsotan.createSmallInfectedAsteroid(position, 2)
            end
        end
    end

    for i = 1, h do
        for j = 1, w do
            if random:test(0.9) then
                local translation = vec3(j * 70, 0, i * 70) + vec3(500, 500, 350)
                local position = MatrixLookUpPosition(vec3(1, 0, 0), vec3(0, 1, 0), translation)
                Xsotan.createSmallInfectedAsteroid(position, 2)
            end
        end
    end

    for i = 1, h do
        for j = 1, w do
            if random:test(0.9) then
                local translation = vec3(j * 70, 0, i * 70) + vec3(-500, -500, 350)
                local position = MatrixLookUpPosition(vec3(1, 0, 0), vec3(0, 1, 0), translation)
                Xsotan.createSmallInfectedAsteroid(position, 2)
            end
        end
    end

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

    local numAsteroids = random:getInt(2, 4)
    for i = 1, numAsteroids do
        Xsotan.createBigInfectedAsteroid(generator:getPositionInSector().pos)
    end

    if random:test(generator:getWormHoleProbability()) then generator:createRandomWormHole() end

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
