package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

materialLevel = 0
range = 0
amount = 0
interestingEntities = {}
wreckageEntities = {}
detections = {}
highlightRange = 0
wreckageRange = 0

local entityId
local highlightColor = ColorRGB(1.0, 1.0, 1.0)
local wreckageColor = ColorRGB(0.7, 0.3, 0.7)

-- this variable gets reset on the client every time the player changes sectors because the script is recreated
local chatMessageDisplayed = false


-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
Unique = true

function getBonuses(seed, rarity)
	math.randomseed(seed)

    local lootRange = (rarity.value + 2 + getFloat(0.0, 0.75)) * 2 * (1.3 ^ rarity.value) * 25 -- one unit is 10 meters
    local deepScan = (math.max(0, getInt(rarity.value, rarity.value * 1.5)) + 1)*2
    local radar = (math.max(0, getInt(rarity.value, rarity.value * 2.0)) + 1)*1.5
    local scanner = 1

    local highlightRange = 0
    if rarity.value >= RarityType.Rare then
        highlightRange = 400 + math.random() * 200
    end

    if rarity.value >= RarityType.Exceptional then
        highlightRange = 900 + math.random() * 200
    end

    if rarity.value >= RarityType.Exotic then
        highlightRange = math.huge
    end

    local dockRange = (rarity.value / 2 + 1 + round(getFloat(0.0, 0.4), 1)) * 100

    lootRange = round(lootRange)

    local wreckageRange = (rarity.value * 400) + (math.random() * 200)
    if rarity.value >= RarityType.Legendary then
        wreckageRange = math.huge
    end

    scanner = 5 -- base value, in percent
    -- add flat percentage based on rarity
    scanner = scanner + (rarity.value + 2) * 15 -- add +15% (worst rarity) to +105% (best rarity)

    -- add randomized percentage, span is based on rarity
    scanner = scanner + math.random() * ((rarity.value + 1) * 15) -- add random value between +0% (worst rarity) and +90% (best rarity)
    scanner = scanner / 50

    return lootRange, deepScan, radar, detections, highlightRange, dockRange, wreckageRange, scanner
end

function onInstalled(seed, rarity, permanent)
	if not permanent then return end

    local lootRange, deepScan, radar, detections, hrange, dockRange, wreckageRange, scanner = getBonuses(seed, rarity)

    addAbsoluteBias(StatsBonuses.LootCollectionRange, lootRange)
    addAbsoluteBias(StatsBonuses.HiddenSectorRadarReach, deepScan)
    addAbsoluteBias(StatsBonuses.RadarReach, radar)
    addAbsoluteBias(StatsBonuses.TransporterRange, dockRange)
    addBaseMultiplier(StatsBonuses.ScannerReach, scanner)

end

function onUninstalled(seed, rarity, permanent)
end


if onClient() then

function onInstalled(seed, rarity, permanent)
    local player = Player()
    if valid(player) then
        player:registerCallback("onPreRenderHud", "onPreRenderHud")
        player:registerCallback("onShipChanged", "detectAndSignal")
    end

    _, _, _, detections, highlightRange, _, wreckageRange, _ = getBonuses(seed, rarity, permanent)
    detectAndSignal()
end

function onUninstalled(seed, rarity, permanent)

end

function onDelete()
    if entityId then
        removeShipProblem("ValuablesDetector", entityId)
    end
end

function detectAndSignal()

    -- check for valuables and send a signal
    interestingEntities = {}
    wreckageEntities = {}

    local player = Player()
    if not valid(player) then return end
    if player.craftIndex ~= Entity().index then return end

    detectValuables()
    detectFlightRecorders()
    detectWreckages()
    signal()
end


function detectWreckages()

    local entities = {Sector():getEntitiesByType(EntityType.Wreckage)}

    for _, entity in pairs(entities) do
        local sphere = entity:getBoundingSphere()
        local size = sphere and sphere.radius * 2 or 0
        local material = entity:getLowestMineableMaterial()
        local resources = 0
        for a, value in pairs({entity:getMineableResources()}) do
            resources = resources + value
        end
 
        if  size >= 20 or resources > 10 then
                table.insert(wreckageEntities, entity)
        end
    end
end

function detectValuables()

    local rarity = getRarity()
    if not rarity then return end

    local entities = {Sector():getEntitiesByScriptValue("valuable_object")}

    for _, entity in pairs(entities) do
        local value = entity:getValue("valuable_object") or RarityType.Petty
        if rarity.value >= value then
            table.insert(interestingEntities, entity)
        end
    end
end

function detectFlightRecorders()

    local entities = {Sector():getEntitiesByScriptValue("blackbox_wreckage")}

    local rarity = getRarity()
    for _, entity in pairs(entities) do
        local value = entity:getValue("blackbox_wreckage") or RarityType.Petty
        if rarity.value >= value then
            table.insert(interestingEntities, entity)
        end
    end

end

function signal()
    local player = Player()

    if valid(player) and player.craftIndex == Entity().index then
        if #interestingEntities > 0 then
            if not chatMessageDisplayed then
                displayChatMessage("Valuable objects detected."%_t, "Object Detector"%_t, 3)
                chatMessageDisplayed = true
            end

            entityId = Entity().id
            addShipProblem("ValuablesDetector", entityId, "Valuable objects detected."%_t, "data/textures/icons/valuables-detected.png", highlightColor)
        end
        if #interestingEntities == 0 then
            removeShipProblem("ValuablesDetector", Entity().id)
        end
    end

end

function onSectorChanged()
    detectAndSignal()
end

function updateClient()
    detectAndSignal()
end

function getUpdateInterval()
    return 10
end

function onPreRenderHud()

    if not highlightRange or highlightRange == 0 then return end
    if not wreckageRange or wreckageRange == 0 then return end

    local player = Player()
    if not player then return end
    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

    local shipPos = Entity().translationf

    -- detect all objects in range
    local renderer = UIRenderer()

    for i, entity in pairs(interestingEntities) do
        if not valid(entity) then
            interestingEntities[i] = nil
        end
    end

    for i, entity in pairs(interestingEntities) do
        local d = distance2(entity.translationf, shipPos)

        if d <= highlightRange * highlightRange then
            renderer:renderEntityTargeter(entity, highlightColor);
            renderer:renderEntityArrow(entity, 30, 10, 250, highlightColor);
        end
    end

    for i, entity in pairs(wreckageEntities) do
        if not valid(entity) then
            wreckageEntities[i] = nil
        end
    end

    for i, entity in pairs(wreckageEntities) do
        local d = distance2(entity.translationf, shipPos)

        if d <= wreckageRange * wreckageRange then
            renderer:renderEntityTargeter(entity, wreckageColor);
            renderer:renderEntityArrow(entity, 30, 10, 250, wreckageColor);
        end
    end

    renderer:display()
end
end

function getComparableValues(seed, rarity)
    local _, _, _, _, range, _, wrange, scanner = getBonuses(seed, rarity, false)

    local base = {}
    local bonus = {}
    table.insert(base, {name = "Highlight Range"%_t, key = "highlight_range", value = round(range / 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(base, {name = "Detection Range"%_t, key = "detection_range", value = 1, comp = UpgradeComparison.MoreIsBetter})
    table.insert(base, {name = "Wreckage Range"%_t, key = "wreckage_range", value = round(wrange / 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(base, {name = "Scanner Range"%_t, key = "range", value = round(scanner * 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Scanner Range"%_t, key = "range", value = round(scanner * 100), comp = UpgradeComparison.MoreIsBetter})

    return base, bonus
end

---------------------------

function getName(seed, rarity)
    return "Universal Adventuring Companion"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/fusion-core.png"
end

function getEnergy(seed, rarity, permanent)
    local lootRange, deepScan, radar, detections, highlightRange, dockRange, _, _ = getBonuses(seed, rarity)
    highlightRange = math.min(highlightRange, 1500)

    return lootRange * 1000 * 1000 / (1.1 ^ rarity.value)
end

function getPrice(seed, rarity)
    local lootRange, deepScan, radar, detections, range, dockRange, _, _ = getBonuses(seed, rarity)
    range = math.min(range, 1500)

    local price = ((#detections+1) * 750) + (range * 1.5)

    return 400 * lootRange
end

function getTooltipLines(seed, rarity, permanent)
    local lootRange, deepScan, radar, detections, range, dockRange, wrange, scanner = getBonuses(seed, rarity)

    local texts =
    {
        {ltext = "Loot Collection Range"%_t, rtext = "+${distance} km"%_t % {distance = lootRange / 100}, icon = "data/textures/icons/sell.png", boosted = permanent},
        {ltext = "Docking Distance"%_t, rtext = "+${distance} km"%_t % {distance = dockRange / 100}, icon = "data/textures/icons/solar-system.png", boosted = permanent},
        {ltext = "Deep Scan Range"%_t, rtext = string.format("%+i", deepScan), icon = "data/textures/icons/radar-sweep.png", boosted = permanent},
        {ltext = "Radar Range"%_t, rtext = string.format("%+i", radar), icon = "data/textures/icons/radar-sweep.png", boosted = permanent}
    }

    if range > 0 then
        local rangeText = "Sector"%_t
        if range < math.huge then
            rangeText = string.format("%g", round(range / 100, 2))
        end

        table.insert(texts, {ltext = "Highlight Range"%_t, rtext = rangeText, icon = "data/textures/icons/rss.png"})
    end

    table.insert(texts, {ltext = "Detection Range"%_t, rtext = "Sector"%_t, icon = "data/textures/icons/rss.png"})

    if wrange > 0 then
        local rangeText = "Sector"%_t
        if wrange < math.huge then
            rangeText = string.format("%g km", round(wrange / 100, 2))
        end

    	table.insert(texts, {ltext = "Wreckage Detect Range"%_t, rtext = rangeText, icon = "data/textures/icons/rss.png"})
    end

    if scanner ~= 0 then
        table.insert(texts, {ltext = "Scanner Range"%_t, rtext = string.format("%+i%%", round(scanner * 100)), icon = "data/textures/icons/signal-range.png", boosted = permanent})
    end

    if not permanent then
        return {}, texts
    else
        return texts, texts
    end
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Makes life better."%_t, lcolor = ColorRGB(1, 0.5, 0.5)},
        {ltext = "", boosted = permanent}
    }
end
