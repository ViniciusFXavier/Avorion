package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")
include ("stringutility")
include ("callable")
AI = include ("story/ai")

local interactable = true

function initialize()
    if onClient() then
        Entity():registerCallback("onBreak", "onBreak")
    end
end

function interactionPossible(playerIndex, option)
    return interactable
end

function initUI()
    ScriptUI():registerInteraction("Hail"%_t, "onHail")
end

function startAttacking()
    if onClient() then
        invokeServerFunction("startAttacking")
        return
    end
    if Entity():hasScript("story/bigaibehavior.lua") then
        Entity():invokeFunction("bigaibehaviour.lua", "setAngry")
    else
        Entity():invokeFunction("aibehaviour.lua", "setAngry")
    end
end
callable(nil, "startAttacking")

function onHail()

    local negative = {}
    negative.text = "..."
    negative.followUp = {text = "[There seems to be no reaction.]"%_t}

    local positive = {}
    positive.text = "Xsotan detected. Commencing attack."%_t
    positive.followUp = {text = "Routing power from shields to weapons."%_t, onEnd = "startAttacking"}

    local ship = Player().craft

    -- check if the ship has a key equipped
    if ship:hasScript("systems/teleporterkey") then
        ScriptUI():showDialog(positive, false)

        interactable = false
    else
        ScriptUI():showDialog(negative, false)
    end

end

function getUpdateInterval()
    return 0.5
end

function updateClient(timeStep)
    if interactable then
        local ship = Player().craft
        if ship and ship:hasScript("systems/teleporterkey") then
            Player():startInteracting(Entity(), "aidialog.lua", 0)
        end
    end
end

