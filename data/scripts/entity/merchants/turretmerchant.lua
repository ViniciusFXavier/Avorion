package.path = package.path .. ";data/scripts/lib/?.lua"
include ("galaxy")
include ("utility")
include ("randomext")
include ("faction")
include ("stringutility")
include ("weapontype")
local ShopAPI = include ("shop")
local SectorTurretGenerator = include ("sectorturretgenerator")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace TurretMerchant
TurretMerchant = {}
TurretMerchant = ShopAPI.CreateNamespace()
TurretMerchant.interactionThreshold = -30000

TurretMerchant.rarityFactors = {}
TurretMerchant.rarityFactors[-1] = 1.0
TurretMerchant.rarityFactors[0] = 1.0
TurretMerchant.rarityFactors[1] = 1.0
TurretMerchant.rarityFactors[2] = 1.0
TurretMerchant.rarityFactors[3] = 1.0
TurretMerchant.rarityFactors[4] = 1.0
TurretMerchant.rarityFactors[5] = 1.0

TurretMerchant.specialOfferRarityFactors = {}
TurretMerchant.specialOfferRarityFactors[-1] = 0.0
TurretMerchant.specialOfferRarityFactors[0] = 0.0
TurretMerchant.specialOfferRarityFactors[1] = 0.0
TurretMerchant.specialOfferRarityFactors[2] = 1.0
TurretMerchant.specialOfferRarityFactors[3] = 1.0
TurretMerchant.specialOfferRarityFactors[4] = 0.25
TurretMerchant.specialOfferRarityFactors[5] = 0.0

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function TurretMerchant.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, TurretMerchant.interactionThreshold)
end

local function comp(a, b)
    local ta = a.turret;
    local tb = b.turret;

    if ta.rarity.value == tb.rarity.value then
        if ta.material.value == tb.material.value then
            return ta.weaponPrefix < tb.weaponPrefix
        else
            return ta.material.value > tb.material.value
        end
    else
        return ta.rarity.value > tb.rarity.value
    end
end

function TurretMerchant.shop:addItems()

    -- simply init with a 'random' seed
    local station = Entity()

    -- create all turrets
    local turrets = {}

    local x, y = Sector():getCoordinates()
    local generator = SectorTurretGenerator()
    generator.rarities = generator:getSectorRarityDistribution(x, y)

    for i, rarity in pairs(generator.rarities) do
        generator.rarities[i] = rarity * TurretMerchant.rarityFactors[i] or 1
    end

    for i = 1, 13 do
        local turret = InventoryTurret(generator:generate(x, y))
        local amount = 1
        if i == 1 then
            turret = InventoryTurret(generator:generate(x, y, nil, nil, WeaponType.MiningLaser))
            amount = 2
        elseif i == 2 then
            turret = InventoryTurret(generator:generate(x, y, nil, nil, WeaponType.PointDefenseChainGun))
            amount = 2
        elseif i == 3 then
            turret = InventoryTurret(generator:generate(x, y, nil, nil, WeaponType.ChainGun))
            amount = 2
        end

        local pair = {}
        pair.turret = turret
        pair.amount = amount

        if turret.rarity.value == 1 then -- uncommon weapons may be more than one
            if math.random() < 0.3 then
                pair.amount = pair.amount + 1
            end
        elseif turret.rarity.value == 0 then -- common weapons may be some more than one
            if math.random() < 0.5 then
                pair.amount = pair.amount + 1
            end
            if math.random() < 0.5 then
                pair.amount = pair.amount + 1
            end
        end

        table.insert(turrets, pair)
    end

    table.sort(turrets, comp)

    for _, pair in pairs(turrets) do
        TurretMerchant.shop:add(pair.turret, pair.amount)
    end
end

-- sets the special offer that gets updated every 20 minutes
function TurretMerchant.shop:onSpecialOfferSeedChanged()
    local generator = SectorTurretGenerator(TurretMerchant.shop:generateSeed())

    local x, y = Sector():getCoordinates()
    local rarities = generator:getSectorRarityDistribution(x, y)

    for i, rarity in pairs(rarities) do
        rarities[i] = rarity * TurretMerchant.specialOfferRarityFactors[i] or 1
    end

    generator.rarities = rarities

    local specialOfferTurret = InventoryTurret(generator:generate(x, y))
    TurretMerchant.shop:setSpecialOffer(specialOfferTurret)
end

function TurretMerchant.initialize()

    local station = Entity()
    if station.title == "" then
        station.title = "Turret Merchant"%_t
    end

    TurretMerchant.shop:initialize(station.translatedTitle)

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/turret.png"
    end
end

function TurretMerchant.initUI()
    local station = Entity()
    TurretMerchant.shop:initUI("Trade Equipment"%_t, station.translatedTitle, "Turrets"%_t, "data/textures/icons/bag_turret.png")
end
