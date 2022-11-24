
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include ("SectorGenerator")

include("callable")
include("stringutility")
local WaveUtility = include("waveutility")
local SpawnUtility = include("spawnutility")
local PlanGenerator = include ("plangenerator")

function getDefaults()
    return {
        waves = {},
        firstSpawnTimer = 10,
        timerEnded = false,
        chatMessageSent = false,
        wavesStarted = false,
        initialEnemies = true,
        encounterJustStarted = false,
        waveSpawned = false,
        stashGenerated = false,
        waveNumber = 1,
    }
end

local data = getDefaults()

--sets the scenario
function initializeWaves()
    -- initialize scenario
    local sector = Sector()
    local generator = SectorGenerator(sector:getCoordinates())
    local mat, asteroids = generator:createAsteroidField()

    -- mark the asteroids that have to be deleted later
    for _, asteroid in pairs(asteroids) do
        asteroid:setValue("wave_encounter_specific", true)
    end

    local stash = createStash(generator, mat)
    data.stashGenerated = true

    sector:sendCallback("onWaveEncounterStarted")
end

function createStash(generator, worldMatrix)
    local plan = PlanGenerator.makeContainerPlan()

    local container = generator:createContainer(plan, worldMatrix, 0)

    container.title = ""
    container:addScript("piratestash.lua")
    container.title = "Secret Stash"%_t
    container:setValue("wave_encounter_specific", true)

    return container
end

-- starts the encounter
-- is called from fakestash
function startEncounter()
    if onClient() then invokeServerFunction("startEncounter") return end

    data.waves = WaveUtility.getWaves()
    data.encounterJustStarted = true
end
callable(nil, "startEncounter")

function updateServer(timeStep)

    -- timer
    if data.encounterJustStarted then
        data.firstSpawnTimer = data.firstSpawnTimer - timeStep
    end

    if data.firstSpawnTimer <= 0 and not data.timerEnded then
        WaveUtility.createPirateWave(data.waveNumber, data.waves[data.waveNumber], onPiratesGenerated)
        data.timerEnded = true
    end

    if Sector().numPlayers >= 1 then
        if not data.stashGenerated then
            initializeWaves()
        end

        if data.waveSpawned == true then
            local numEnemies = WaveUtility.getNumEnemies()

            if numEnemies <= 1 then
                data.waveSpawned = false

                if data.waveNumber < WaveUtility.data.numWaves then
                    data.waveNumber = data.waveNumber + 1
                    WaveUtility.createPirateWave(data.waveNumber, data.waves[data.waveNumber], onPiratesGenerated)
                elseif data.waveNumber == WaveUtility.data.numWaves and not bossWaveSpawned then
                    WaveUtility.createPirateBossWave(onBossWaveGenerated)
                end
            end
        end
    end

    if data.bossDefeated and WaveUtility.getNumEnemies() == 0 then
        sectorCleared()
    end
end

-- callback for generator in wavegenerator. Needed here because it doesn't work when set in wavegenerator
function onPiratesGenerated(generated)
    SpawnUtility.addEnemyBuffs(generated)
    for _, ship in pairs(generated) do
        if valid(ship) then
            ship:setValue("is_wave", true)
        end
    end

    data.waveSpawned = true
end

-- callback for generator in wavegenerator. Needed here because it doesn't work when set in wavegenerator
function onBossWaveGenerated(generated)
    SpawnUtility.addEnemyBuffs(generated)
    for _, ship in pairs(generated) do
        if valid(ship) then
            ship:setValue("is_wave", true)
        end
    end

    local boss = generated[#generated]
    local bossLoot = Loot(boss.id)

    -- adds legendary turret drop
    boss:addScriptOnce("internal/common/entity/background/legendaryloot.lua", 0.1)
    boss:addScriptOnce("utility/buildingknowledgeloot.lua")
    boss:registerCallback("onDestroyed", "onBossDefeated")

    for _, turret in pairs(WaveUtility.generateTurrets()) do
        bossLoot:insert(turret)
    end
end

function onBossDefeated()
    data.bossDefeated = true
end

function sectorCleared()
    Sector():sendCallback("onWaveEncounterFinished")
    broadcastInvokeClientFunction("showClearedMessage")
    WaveUtility.increaseLootGoonPityCounter()
    WaveUtility.improveReputation()
    terminate()
end

function showClearedMessage()
    if onServer() then return end

    WaveUtility.showSectorCleared()
end


function secure()
    return {dat = data, wdata = WaveUtility.data}
end

function restore(data_in)
    data_in = data_in or {}

    data = data_in.dat or getDefaults()
    WaveUtility.data = data_in.wdata or {}
end
