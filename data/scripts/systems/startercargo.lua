package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getLootCollectionRange(seed, rarity, permanent)
    math.randomseed(seed)
	--origninal code modified by luzivras
    --local range = (rarity.value + 2 + getFloat(0.0, 0.75)) * 2 * (1.3 ^ rarity.value) 
    local range = (rarity.value + 2 + getFloat(0.0, 0.75)) * 2 * 5 * (1.3 ^ rarity.value) -- one unit is 5 meters ------ multiplied 100 by 5 by luzivras

    if permanent then
        range = range * 3
    end

    range = round(range)

    return range
end

function getBonuses(seed, rarity, permanent)
    return 500
end

function onInstalled(seed, rarity, permanent)
    local flat = getBonuses(seed, rarity, permanent)
    local range = getLootCollectionRange(seed, rarity, permanent)

    addAbsoluteBias(StatsBonuses.CargoHold, flat)
    addAbsoluteBias(StatsBonuses.LootCollectionRange, range)
end

function onUninstalled(seed, rarity, permanent)

end

function getName(seed, rarity)
    return "Quantum Cargo Upgrade XE-100"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/crate.png"
end

function getEnergy(seed, rarity, permanent)
    return 0
end

function getPrice(seed, rarity)
    return 0
end

function getTooltipLines(seed, rarity, permanent)
    local texts = {}
    local flat = getBonuses(seed, rarity, permanent)

    table.insert(texts, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i", flat), icon = "data/textures/icons/crate.png", boosted = permanent})
    return texts
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "It's bigger on the inside!"%_t, lcolor = ColorRGB(1, 0.5, 0.5)}
    }
end
