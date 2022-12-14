package.path = package.path .. ";data/scripts/lib/?.lua"

Dialog = include ("dialogutility")
include ("stringutility")
include ("callable")

local canFlee = true

function initialize()
    if onServer() then
        Entity():registerCallback("onShotHit", "onShotHit")
        Entity():registerCallback("onCollision", "onShotHit")

        Entity():registerCallback("onDestroyed", "onDestroyed")
    end
end

function initUI()
    ScriptUI():registerInteraction("I have your goods."%_t, "startInteraction")
end

function interactionPossible(playerIndex, option)
    if angryDialogDisplayed then return false end
    return true
end

function startInteraction()
    local dialog = {}
    local payment = {}
    local youWont = {}
    local notMyProblem = {}
    local noneOfYourBusiness = {}
    local notFound = {}

    local hereYouGo = {}
    local howWillIKnow = {}
    local changedMyMind = {answer = "I've changed my mind."%_t, text = "Tell me when you change it back so we can finally get this over with."%_t}
    local ranIntoProblems = {answer = "I ran into some trouble transporting your goods."%_t, followUp = notMyProblem}

    howWillIKnow.answer = "How will I know that you'll pay me?"%_t
    howWillIKnow.followUp = youWont

    hereYouGo.answer = "Here you go."%_t
    hereYouGo.onSelect = "handOverGoods"


    notFound.text = "My scanners can't find the goods on your ship. Come back when you have the goods. But I won't wait here forever, so hurry up!"%_t

    noneOfYourBusiness.text = "That's none of your business. Hand over the goods!"%_t
    noneOfYourBusiness.answers = {
        hereYouGo,
        ranIntoProblems,
        howWillIKnow,
        changedMyMind,
    }

    notMyProblem.text = "If you can't transport the goods without avoiding patrols or an ambush, that's your own problem, not mine."%_t
    notMyProblem.answers = {
        hereYouGo,
        howWillIKnow,
        changedMyMind,
    }

    youWont.text = "You won't. But if you keep pestering me, I won't pay you at all!"%_t
    youWont.answers = {
        hereYouGo,
        ranIntoProblems,
        changedMyMind,
    }

    payment.text = "We'll work out your payment as soon as I have the goods on board."%_t
    payment.answers = {
        hereYouGo,
        ranIntoProblems,
        howWillIKnow,
        changedMyMind,
    }

    dialog.text = "Good. Hand them over now."%_t
    dialog.answers = {
        hereYouGo,
        {answer = "What about my payment?"%_t, followUp = payment},
        {answer = "Who are you?"%_t, followUp = noneOfYourBusiness},
    }

    if not hasGoods() then
        hereYouGo.followUp = notFound
    else
        hereYouGo.followUp = Dialog.empty()
    end

    if Player():hasScript("player/story/smugglerretaliation.lua") then
        dialog = {text = "Wait a second ..."%_t, followUp = {text = "You again? Screw this, I'm out!"%_t, onEnd = "tryJumpAway"}}
    end

    ScriptUI():showDialog(dialog, false)
end

function hasGoods()
    local ship
    if onClient() then
        ship = Player().craft
    else
        local player = Player(callingPlayer)
        ship = Entity(player.craftIndex)
    end

    for good, amount in pairs(ship:findCargos("Goods")) do
        if good.suspicious and amount > 0 then
            return true
        end
    end

    return false
end

function handOverGoods()
    if onClient() then
        if hasGoods() then
            invokeServerFunction("handOverGoods")
        end
    else
        local player = Player(callingPlayer)

        if hasGoods() then
            local ship = Entity(player.craftIndex)

            for good, amount in pairs(ship:findCargos("Goods")) do
                if good.suspicious and amount > 0 then
                    ship:removeCargo(good, 1)
                    break
                end
            end

            player:addScriptOnce("story/smugglerletter")

            invokeClientFunction(player, "transactionDone")
        else
            invokeClientFunction(player, "noGoods")
        end
    end
end
callable(nil, "handOverGoods")




function transactionDone()
    local dialog = {}

    dialog.text = "Looks like everything is here. Thank you very much for your cooperation, I'll be on my way then!"%_t
    dialog.followUp = {text = "Hahahaha!"%_t, onEnd = "dialogFinished"}

    ScriptUI():showDialog(dialog, false)
end

function noGoods()
    local dialog = {}
    dialog.text = "My scanners can't find the goods on your ship. Come back when you have the goods. But I won't wait here forever, so hurry up."%_t
    ScriptUI():showDialog(dialog, false)
end

function dialogFinished()
    if onClient() then
        invokeServerFunction("dialogFinished")
        return
    end

    local player = Player(callingPlayer)

    if canFlee then
        player:invokeFunction("story/smugglerdelivery", "accomplish")
        Sector():deleteEntityJumped(Entity())
    else
        player:invokeFunction("story/smugglerdelivery", "fail")
        onCantJump()
    end
end
callable(nil, "dialogFinished")

function onShotHit()
    if not wasHit then
        Sector():broadcastChatMessage(Entity().title, 0, "We're taking damage. Retreat, retreat!"%_t)

        -- fail delivery quest in both cases
        local players = {Sector():getPlayers()}
        for _, player in pairs(players) do
            player:invokeFunction("story/smugglerdelivery", "fail")
        end

        if canFlee then
            -- if he can, he will run
            Sector():deleteEntityJumped(Entity())
        else
            onCantJump()
        end
    end

    wasHit = true
end

function tryJumpAway()
    if onClient() then
        invokeServerFunction("tryJumpAway")
        return
    end

    local player = Player(callingPlayer)
    player:invokeFunction("story/smugglerdelivery", "fail")

    if canFlee then
        Sector():deleteEntityJumped(Entity())
    else
        onCantJump()
    end
end
callable(nil, "tryJumpAway")

function onCantJump()
    if onClient() then
        invokeServerFunction("onCantJump")
        registerBoss(Entity().index)
        return
    end

    -- worsen relations to all present players and alliances
    local smugglerFaction = Faction()

    local factions = {Sector():getPresentFactions()}
    for _, factionIndex in pairs(factions) do
        local faction = Faction(factionIndex)
        if not faction.isAIFaction then
            ShipAI():registerEnemyFaction(factionIndex)
        end
    end

    ShipAI():setAggressive()

    broadcastInvokeClientFunction("angryDialog")
end
callable(nil, "onCantJump")

function angryDialog()
    -- only show this once
    if angryDialogDisplayed then return end
    angryDialogDisplayed = true

    local dialog = {text = "What!? Why can't we jump?"%_t, followUp = {text = "You did this! You destroyed my hyperspace drive! Prepare to die!"%_t}}
    ScriptUI():interactShowDialog(dialog, false)
end

function blockHyperspace()
    canFlee = false
end

function onDestroyed()
    local players = {Sector():getPlayers()}
    for _, player in pairs(players) do
        -- smuggler retaliation accomplishes
        if player:hasScript("player/story/smugglerretaliation.lua") then
            player:invokeFunction("smugglerretaliation", "onBottanDestroyed")
        end

        -- smuggler delivery fails if it didn't fail already
        if player:hasScript("player/story/smugglerdelivery.lua") then
            player:invokeFunction("smugglerdelivery", "fail")
        end

        -- reset mission cooldown
        local runtime = Server().unpausedRuntime
        player:setValue("last_killed_bottan", runtime)
    end
end

function secure()
    return {canFlee = canFlee}
end

function restore(data)
    canFlee = data.canFlee or true
end

