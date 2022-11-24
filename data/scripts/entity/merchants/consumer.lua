package.path = package.path .. ";data/scripts/lib/?.lua"
include ("galaxy")
include ("randomext")
include ("utility")
include ("faction")
include ("stringutility")
include ("callable")
local FactoryMap = include ("factorymap")
local TradingAPI = include ("tradingmanager")
local Dialog = include("dialogutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Consumer
Consumer = {}
Consumer = TradingAPI:CreateNamespace()

Consumer.consumerName = ""
Consumer.consumerIcon = ""
Consumer.consumedGoods = {}
Consumer.trader.tax = 0.0
Consumer.trader.factionPaymentFactor = 1.0
Consumer.trader.relationsThreshold = -30000

Consumer.toggleBuyButton = nil

function Consumer.interactionPossible(playerIndex, option)
    if Player(playerIndex).craftIndex == Entity().index then return false end
    return CheckFactionInteraction(playerIndex, Consumer.trader.relationsThreshold)
end

function Consumer.restore(values)
    Consumer.restoreTradingGoods(values)
    Consumer.consumerName = values.consumerName
    Consumer.consumedGoods = values.consumedGoods or {}
    Consumer.consumerConfigured = values.consumerConfigured

    if type(Consumer.consumedGoods) ~= "table" or #Consumer.consumedGoods == 0 then
        Consumer.consumedGoods = {Consumer.getBoughtGoods()}
    end

    local broken = (#{Consumer.getBoughtGoods()} == 0)
    for _, good in pairs({Consumer.getBoughtGoods()}) do
        if good == "nil" then
            broken = true
            break
        end
    end

    if broken and #Consumer.consumedGoods > 0 then
        local consumed = {}

        for i, name in pairs(Consumer.consumedGoods) do
            local g = goods[name]
            table.insert(consumed, g:good())
        end

        Consumer.initializeTrading({}, consumed)
    end

    if not Consumer.consumerConfigured then
        local entity = Entity()
        if entity.playerOwned or entity.allianceOwned then
            Consumer.trader.buyFromOthers = false
        end
    end

    Consumer.updateOwnSupply()
end

function Consumer.secure()
    local values = Consumer.secureTradingGoods()
    values.consumerName = Consumer.consumerName
    values.consumedGoods = Consumer.consumedGoods
    values.consumerConfigured = Consumer.consumerConfigured

    return values
end

function Consumer.initialize(name_in, ...)

    local entity = Entity()

    if onServer() then
        Sector():addScriptOnce("sector/traders.lua")

        Consumer.consumerName = name_in or Consumer.consumerName

        -- only use parameter goods if there are any, otherwise we prefer the goods we might already have in consumedGoods
        local consumedGoods_in = {...}
        if #consumedGoods_in > 0 then
            Consumer.consumedGoods = consumedGoods_in
        end
        Consumer.updateOwnSupply()

        local station = Entity()

        -- add the name as a category
        if Consumer.consumerName ~= "" and entity.title == "" then
            entity.title = Consumer.consumerName
        end


        local seed = Sector().seed + Sector().numEntities
        math.randomseed(seed);

        -- consumers only buy
        Consumer.trader.buyPriceFactor = math.random() * 0.2 + 0.9 -- 0.9 to 1.1

        local bought = {}

        for i, name in pairs(Consumer.consumedGoods) do
            local g = goods[name]
            table.insert(bought, g:good())
        end

        Consumer.initializeTrading(bought, {})

        local faction = Faction()
        if faction then
            if faction.isAIFaction then
                Sector():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
            end

            if not _restoring then
                if faction.isAlliance or faction.isPlayer then
                    Consumer.trader.buyFromOthers = false
                end
            end
        end

        math.randomseed(appTimeMs())
    else
        Consumer.requestGoods()

        if Consumer.consumerIcon ~= "" and EntityIcon().icon == "" then
            EntityIcon().icon = Consumer.consumerIcon
            InteractionText().text = Dialog.generateStationInteractionText(entity, random())
        end
    end

end

function Consumer.onRestoredFromDisk(timeSinceLastSimulation)
    Consumer.simulatePassedTime(timeSinceLastSimulation)
end

-- create all required UI elements for the client side
function Consumer.initUI()

    local tabbedWindow = TradingAPI.CreateTabbedWindow()

    -- create buy tab
    local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/bag.png", "Buy from station"%_t)
    Consumer.buildBuyGui(buyTab)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/sell.png", "Sell to station"%_t)
    Consumer.buildSellGui(sellTab)

    Consumer.toggleBuyButton = sellTab:createButton(Rect(sellTab.size.x - 30, -5, sellTab.size.x, 25), "", "onToggleBuyPressed")
    Consumer.toggleBuyButton.icon = "data/textures/icons/sell.png"

    tabbedWindow:deactivateTab(buyTab)

    Consumer.trader.guiInitialized = 1

    if TradingAPI.window.caption ~= "" then
        invokeServerFunction("sendName")
    end

    Consumer.requestGoods()
end

function Consumer.sendName()
    invokeClientFunction(Player(callingPlayer), "receiveName", Consumer.consumerName)
end
callable(Consumer, "sendName")

function Consumer.receiveName(name)
    if TradingAPI.window.caption ~= "" and name ~= "" then
        TradingAPI.window.caption = name%_t
    end
end

function Consumer.updateOwnSupply()
    local factoryMap = FactoryMap()

    for _, name in pairs(Consumer.consumedGoods) do
        Consumer.trader.ownSupplyTypes[name] = factoryMap.SupplyType.Consumer
    end
end

function Consumer.onShowWindow()
    Consumer.requestGoods()

    local faction = Faction()
    local player = Player()

    if player.index == faction.index or player.allianceIndex == faction.index then
        invokeServerFunction("sendConfig")
        Consumer.toggleBuyButton:show()
    else
        Consumer.toggleBuyButton:hide()
    end
end

function Consumer.onToggleBuyPressed()
    Consumer.sendConfig()
end

function Consumer.refreshConfigUI()
    if Consumer.trader.buyFromOthers then
        Consumer.toggleBuyButton.icon = "data/textures/icons/sell-enabled.png"
        Consumer.toggleBuyButton.tooltip = "This station buys consumer goods from traders."%_t
    else
        Consumer.toggleBuyButton.icon = "data/textures/icons/sell-disabled.png"
        Consumer.toggleBuyButton.tooltip = "This station doesn't buy consumer goods from traders."%_t
    end
end

function Consumer.getUpdateInterval()
    return 5
end

function Consumer.getConsumedGoods()
    return Consumer.consumedGoods
end

function Consumer.updateServer(timeStep)
    Consumer.useUpBoughtGoods(timeStep)
    Consumer.updateOrganizeGoodsBulletins(timeStep)
end


function Consumer.sendConfig()
    local config = {}
    if onClient() then
        -- read new config from ui elements
        config.buyFromOthers = not Consumer.trader.buyFromOthers

        invokeServerFunction("setConfig", config)
    else
        -- read config from factory settings
        config.buyFromOthers = Consumer.trader.buyFromOthers

        invokeClientFunction(Player(callingPlayer), "setConfig", config)
    end
end
callable(Consumer, "sendConfig")

function Consumer.setConfig(config)
    if onClient() then
        -- apply config to UI elements
        Consumer.trader.buyFromOthers = config.buyFromOthers

        if TradingAPI.window.visible then
            Consumer.refreshConfigUI()
        end
    else
        if not config then return end

        -- apply config to factory settings
        local owner, station, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageStations)
        if not owner then return end

        Consumer.trader.buyFromOthers = config.buyFromOthers
        Consumer.consumerConfigured = true

        Consumer.sendConfig()
    end
end
callable(Consumer, "setConfig")


return Consumer
