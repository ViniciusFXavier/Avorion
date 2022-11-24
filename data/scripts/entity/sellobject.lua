package.path = package.path .. ";data/scripts/lib/?.lua"

include ("utility")
include ("stringutility")
include ("galaxy")
include ("faction")
include ("callable")
include ("relations")
local FactionEradicationUtility = include("factioneradicationutility")

local lines = {}

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    if Entity().factionIndex == playerIndex then
        return true
    end

    if Player().allianceIndex == Entity().factionIndex then
        return true
    end

    return false
end

-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(700, 235)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Sell Asteroid"%_t
    window.showCloseButton = 1
    window.moveable = 1

    menu:registerWindow(window, "Sell Asteroid"%_t, 4);

    local buttonCaption = ""
    local buttonCallback = ""

    buttonCaption = "Sell"%_t

    local size = window.size

--    window:createFrame(Rect(vec2(10, 10), size - vec2(10, 10)))

    local nameX = 20
    local reputationX = 380
    local priceX = 480
    local buttonX = size.x - 130

    -- header
    window:createLabel(vec2(nameX, 20), "Faction"%_t, 15)
    window:createLabel(vec2(reputationX, 20), "Reputation"%_t, 15)
    window:createLabel(vec2(priceX, 20), "¢", 15)

    local y = 45
    for i = 1, 5 do

        local yText = y + 6

        local frame = window:createFrame(Rect(10, y, buttonX - 10, 30 + y))

        local nameLabel = window:createLabel(vec2(nameX, yText), "The United Udiie Corporation", 15)
        local reputationLabel = window:createLabel(vec2(reputationX, yText), "+5000", 15)
        local priceLabel = window:createLabel(vec2(priceX, yText), "", 15)
        local button = window:createButton(Rect(buttonX, yText - 6, size.x - 10, 30 + yText - 6), "Sell"%_t, "onSellButtonPressed")
        button.maxTextSize = 15

        table.insert(lines, {
            frame = frame,
            nameLabel = nameLabel,
            reputationLabel = reputationLabel,
            priceLabel = priceLabel,
            button = button,
            hide = function(self)
                self.frame:hide()
                self.nameLabel:hide()
                self.reputationLabel:hide()
                self.priceLabel:hide()
                self.button:hide()
            end,
            show = function(self)
                self.frame:show()
                self.nameLabel:show()
                self.reputationLabel:show()
                self.priceLabel:show()
                self.button:show()
            end
        })

        lines[#lines]:hide()

        y = y + 35
    end

end

function onShowWindow()
    invokeServerFunction("sendFactions")
end

function onSellButtonPressed(button)
    local c = 1
    for _, line in pairs(lines) do
        if button.index == line.button.index and line.faction then

            invokeServerFunction("sell", line.faction.index)
            break
        end

        c = c + 1
    end
end

function receiveFactions(factions_in)
    factions = factions_in

    for _, line in pairs(lines) do
        line:hide()
    end

    local counter = 1
    for _, faction in pairs(factions) do
        local line = lines[counter]
        line:show()

        local actualFaction = Faction(faction.index)
        if actualFaction then
            line.nameLabel.caption = actualFaction.translatedName
        else
            line.nameLabel.caption = "Unknown"%_t
        end

        line.priceLabel.caption = createMonetaryString(faction.price)
        line.reputationLabel.caption = string.format("%+i", faction.reputation)
        line.faction = faction

        counter = counter + 1
    end

end

function getFactions()
    local ownFaction = Faction(Entity().factionIndex)

    local factions = {}
    local x, y = Sector():getCoordinates()
    local offsets =
    {
        {x = 0, y = 0},
        {x = -8, y = 0},
        {x = 8, y = 0},
        {x = 0, y = -8},
        {x = 0, y = 8}
    }

    for _, offset in pairs(offsets) do
        local faction = Galaxy():getNearestFaction(x + offset.x, y + offset.y)
        if FactionEradicationUtility.isFactionEradicated(faction.index) then goto continue end

        local relations = ownFaction:getRelations(faction.index)

        local totalMoney = 0
        local totalReputation = 0

        for i = 1, 3 do
            local price = lerp(relations, -100000, 100000, 500, 30000)
            local reputation = lerp(relations, -100000, RelationChangeMaxCap[RelationChangeType.Commerce], 12000, 0)

            totalMoney = totalMoney + price
            totalReputation = totalReputation + reputation
            relations = relations + reputation
        end

        totalMoney = totalMoney * Balancing_GetSectorRichnessFactor(x, y)

        factions[faction.index] = {index = faction.index, price = totalMoney, reputation = totalReputation}

        ::continue::
    end

    return factions
end

function sendFactions()
    local factions = getFactions()
    invokeClientFunction(Player(callingPlayer), "receiveFactions", factions)
end
callable(nil, "sendFactions")

function sell(receiverIndex)
    if anynils(receiverIndex) then return end

    local owner, self = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageStations)
    if not owner then return end

    local factions = getFactions()
    local faction = factions[receiverIndex]

    owner:receive("Sold an object for %1% Credits."%_T, faction.price)
    changeRelations(Faction(faction.index), owner, faction.reputation, RelationChangeType.Commerce, nil, nil, faction.index)

    self.factionIndex = faction.index

    local actualFaction = Faction()

    if actualFaction.isAIFaction then
        self:addScriptOnce("utility/autotransformtomine.lua")
        self:addScriptOnce("entity/utility/aiundockable.lua")
        self:setValue("map_marker", nil)
    end

    terminate()
end
callable(nil, "sell")
