package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("utility")
include ("stringutility")
include ("callable")
include ("galaxy")
include ("faction")
include("randomext")
include ("structuredmission")

MissionUT = include ("missionutility")
local ShipUtility = include ("shiputility")
local AdventurerGuide = include ("story/adventurerguide")
local TorpedoGenerator = include ("torpedogenerator")
local AsyncPirateGenerator = include("asyncpirategenerator")
local SectorSpecifics = include("sectorspecifics")
local PlanGenerator = include ("plangenerator")

-- mission.tracing = true

-- mission data
abandon = nil
mission.data.autoTrackMission = true
mission.data.playerShipOnly = true
mission.data.brief = "Torpedo Tests"%_T
mission.data.title = "Torpedo Tests"%_T
mission.data.icon = "data/textures/icons/graduate-cap.png"
mission.data.priority = 5
mission.data.description = {}
mission.data.description[1] = ""
mission.data.description[2] = {text = "Read the Adventurer's mail"%_T, bulletPoint = true, fulfilled = false}
mission.data.description[3] = {text = "Meet the Adventurer in (${xCoord}:${yCoord})"%_T, bulletPoint = true, fulfilled = false, visible = false}
mission.data.description[4] = {text = "Build a Torpedo Storage of at least size 9"%_T, bulletPoint = true, fulfilled = false, visible = false}
mission.data.description[5] = {text = "Open the torpedoes tab in your ship window. Drag & drop the torpedo into a torpedo shaft. In the ship tab, bind the shaft to a keyboard shortcut to activate it"%_T, bulletPoint = true, fulfilled = false, visible = false}
mission.data.description[6] = {text = "Shoot the wreckage with the torpedo [${torpedoKey}]"%_T, bulletPoint = true, fulfilled = false, visible = false}
mission.data.description[7] = {text = "Use the torpedo to destroy the pirate"%_T, bulletPoint = true, fulfilled = false, visible = false}

-- custom data
mission.data.custom = {}
mission.data.custom.interacted = false
mission.data.custom.adventurerId = nil
mission.data.custom.startMailRead = false
mission.data.custom.pirateSetAggressive = false
mission.data.custom.torpedoAssigned = false
mission.data.custom.torpedoLaunched = false
mission.data.custom.torpedoesLaunched = 0
mission.data.custom.pirateId = nil
mission.data.custom.wreckageId = nil
mission.data.custom.torpedoHit = false
mission.data.custom.location = {}

-- mission phases
mission.globalPhase = {}
mission.globalPhase.onTargetLocationEntered = function()
    if onClient() then return end

    createAdventurer()

    if mission.internals.phaseIndex <= 7 then
        createWreckage()
    end

    if mission.data.custom.dialog3Started == 1 then
        mission.data.custom.dialog3Started = 0
    elseif mission.currentPhase == mission.phases[4] then
        buildTorpedoStorageDialog()
    elseif mission.currentPhase == mission.phases[6] or mission.currentPhase == mission.phases[7] then
        equipTorpedoDialog()
    end
end
mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true

mission.globalPhase.updateClient = function()
    mission.data.torpedoKey = GameInput():getKeyName(ControlAction.FireTorpedoes)
end

-- make sure all descriptions are there (they might not be if the mission was started in old version of the game), and if not, reset to phase 1
mission.globalPhase.onRestore = function()
    local descriptionsKnown = true

    for i = 1, 7 do
        if not mission.data.description[i] then
            descriptionsKnown = false
            break
        end
    end

    if descriptionsKnown == false then
        mission.data.description[1] = ""
        mission.data.description[2] = {text = "Read the Adventurer's mail"%_T, bulletPoint = true, fulfilled = false}
        mission.data.description[3] = {text = "Meet the Adventurer in (${xCoord}:${yCoord})"%_T, bulletPoint = true, fulfilled = false, visible = false}
        mission.data.description[4] = {text = "Build a Torpedo Storage of at least size 9"%_T, bulletPoint = true, fulfilled = false, visible = false}
        mission.data.description[5] = {text = "Open the torpedoes tab in your ship window. Drag & drop the torpedo into a torpedo shaft. In the ship tab, bind the shaft to a keyboard shortcut to activate it"%_T, bulletPoint = true, fulfilled = false, visible = false}
        mission.data.description[6] = {text = "Shoot the wreckage with the torpedo [${torpedoKey}]"%_T, bulletPoint = true, fulfilled = false, visible = false}
        mission.data.description[7] = {text = "Use the torpedo to destroy the pirate"%_T, bulletPoint = true, fulfilled = false, visible = false}

        setPhase(1)
    end
end

mission.phases[1] = {}
mission.phases[1].onBeginServer = function()

    mission.data.description[1] = {text = "Learn how to use torpedoes. A complete guide by ${name}, the Adventurer."%_T, arguments = {name = getAdventurerName()}}
    mission.data.description[2].visible = true

    mission.data.custom.location = findEmptySector()

    local player = Player()
    local mail = createStartMail()
    player:addMail(mail)
end
mission.phases[1].playerCallbacks =
{
    {
        name = "onMailRead",
        func = function(playerIndex, mailIndex, mailId)
            -- define mission location here, so that sector is only marked after player read the mail
            mission.data.location = mission.data.custom.location

            if mailId == "Tutorial_Torpedoes" then
                mission.data.description[2].fulfilled = true
                mission.data.description[3].arguments = {xCoord = mission.data.location.x, yCoord = mission.data.location.y}
                mission.data.description[3].visible = true
                mission.data.custom.startMailRead = true
                nextPhase()
            end
        end
    }
}

mission.phases[2] = {}
mission.phases[2].updateClient = function()
    if not Hud().mailWindowVisible then
        Player():sendCallback("onShowEncyclopediaArticle", "Torpedoes")
    end
end

mission.phases[2].onTargetLocationEntered = function()
    if onClient() then
        setTrackThisMission() -- track here to entice player to do this immediately
        return
    end

    createAdventurer()
    createWreckage()
    nextPhase()
end
mission.phases[2].noBossEncountersTargetSector = true
mission.phases[2].noPlayerEventsTargetSector = true

mission.phases[3] = {}
mission.phases[3].onBeginServer = function()
    mission.data.custom.dialog3Started = 0
end
mission.phases[3].updateClient = function()
    if mission.data.custom.dialog3Started == 0 and mission.data.custom.adventurerId then
        if checkAdventurerCreated() then
            onStartFirstDialog()
            mission.data.custom.dialog3Started = 1
        end
    end
end
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onRestore = function()
    if atTargetLocation() then
        -- get new location and reset to phase 2
        mission.data.custom.location = findEmptySector()
        mission.data.location = mission.data.custom.location

        mission.data.description[3].arguments = {xCoord = mission.data.location.x, yCoord = mission.data.location.y}
        mission.data.description[3].fulfilled = false
        setPhase(2)
    end
end
mission.phases[3].onTargetLocationLeft = function()
    mission.data.description[3].fulfilled = false
    setPhase(2)
end

mission.phases[4] = {}
mission.phases[4].onBeginServer = function()
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
end
mission.phases[4].onBeginClient = function()
    if atTargetLocation() then
        buildTorpedoStorageDialog()
    end
end
mission.phases[4].updateServer = function()
    if checkTorpedoStorage() then
        mission.data.description[4].fulfilled = true
        nextPhase()
    end
end
mission.phases[4].onRestore = function()
    if atTargetLocation() then
        resetToPhase2()
    end
end
mission.phases[4].onTargetLocationLeft = function()
    mission.data.description[3].fulfilled = false
end
mission.phases[4].showUpdateOnEnd = true

mission.phases[5] = {}
mission.phases[5].onBeginServer = function()
    if playerInTargetSector() then
        mission.data.description[3].fulfilled = true
        givePlayerTorpedo()
        nextPhase()
    else
        mission.data.description[3].fulfilled = false
    end
end
mission.phases[5].onBeginClient = function()
    if atTargetLocation() then
        equipTorpedoDialog()
    else
        mission.data.description[3].fulfilled = false
    end
end
mission.phases[5].updateInterval = 15
mission.phases[5].updateServer = function()
    if not checkTorpedoStorage() then
        mission.data.description[4].fulfilled = false
        setPhase(4)
    end

    -- if player destroyed the torpedo or lost it in some other way, give him a new one
    if playerInTargetSector() and mission.data.custom.torpedoesLaunched == 0 and not playerHasTorpedo() then
        givePlayerTorpedo(RarityType.Petty)
    end
end
mission.phases[5].onTargetLocationEnteredReportedByClient = function()
    mission.phases[5].onBeginServer()
end
mission.phases[5].onTargetLocationEntered = function()
    if onClient() then
        mission.phases[5].onBeginClient()
    end
end
mission.phases[5].onRestore = function()
    if atTargetLocation() then
        resetToPhase2()
    end
end
mission.phases[5].showUpdateOnEnd = true

mission.phases[6] = {}
mission.phases[6].onBegin = function()
    if onServer() then
        mission.data.description[5].visible = true
        mission.data.description[6].visible = true

        if not Entity(mission.data.custom.wreckageId) then
            createWreckage() -- wreckage was somehow destroyed => make a new one
        end

        Entity(mission.data.custom.wreckageId):registerCallback("onTorpedoHit", "onTorpedoHit")

        nextPhase()
    else
        -- if mission isn't tracked here, we need to do that now
        setTrackThisMission()
    end
end
mission.phases[6].updateInterval = 15
mission.phases[6].updateServer = function()
    -- if player destroyed the torpedo or lost it in some other way, give him a new one
    if playerInTargetSector() and mission.data.custom.torpedoesLaunched == 0 and not playerHasTorpedo() then
        givePlayerTorpedo(RarityType.Petty)
    end
end
mission.phases[6].showUpdateOnEnd = true

mission.phases[7] = {}
mission.phases[7].onBeginServer = function()
    if playerInTargetSector() then
        mission.data.description[3].fulfilled = true
        local entity = Entity(mission.data.custom.wreckageId)
        if entity then
            entity:registerCallback("onTorpedoHit", "onTorpedoHit")
        end

        local craft = Player().craft
        if not craft then return end
        craft:registerCallback("onTorpedoLaunched", "onWreckageTorpedoLaunched")
    else
        mission.data.description[3].fulfilled = false
    end
end
local phase7Timer = 10
mission.phases[7].updateServer = function(timeStep)
    if mission.data.custom.pirateSetAggressive then
        mission.data.description[7].visible = true
        nextPhase()
    end

    phase7Timer = phase7Timer - timeStep

    if phase7Timer <= 0 then
        -- if player destroyed the torpedo or lost it in some other way, give him a new one
        if playerInTargetSector() and mission.data.custom.torpedoesLaunched == 0 and not playerHasTorpedo() then
            givePlayerTorpedo(RarityType.Petty)
            phase7Timer = 10
        end
    end
end
mission.phases[7].timers = {}
mission.phases[7].timers[1] = {callback = function() onSpawnPirate() end}
mission.phases[7].timers[2] = {callback = function() onNeedsNewTorpedo() end}
mission.phases[7].onRestore = function()
    if atTargetLocation() then
        mission.data.description[5].visible = false
        mission.data.description[5].fulfilled = false
        mission.data.description[6].visible = false
        mission.data.description[6].fulfilled = false
        resetToPhase2()
    end
end
mission.phases[7].onTargetLocationEntered = function()
    mission.data.description[3].fulfilled = true
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true

    if not mission.data.custom.torpedoHit then
        local entity = Entity(mission.data.custom.wreckageId)
        if entity then
            entity:registerCallback("onTorpedoHit", "onTorpedoHit")
        end

        -- if player comes back in this phase and has no torpedo, something must have gone wrong => give them one
        givePlayerTorpedo()
    end

    local craft = Player().craft
    if not craft then return end

    craft:registerCallback("onTorpedoLaunched", "onWreckageTorpedoLaunched")
end
mission.phases[7].onTargetLocationLeft = function()
    mission.data.description[3].fulfilled = false
    mission.data.description[5].visible = false
    mission.data.description[5].fulfilled = false
    mission.data.description[6].visible = false
    mission.data.description[6].fulfilled = false
end
mission.phases[7].showUpdateOnEnd = true

mission.phases[8] = {}
local phase8Timer = 10
mission.phases[8].onBeginServer = function()
    local craft = Player().craft
    if not craft then return end

    craft:registerCallback("onTorpedoLaunched", "onPirateTorpedoLaunched")
end
mission.phases[8].updateServer = function(timeStep)
    if mission.data.custom.torpedoLaunched and atTargetLocation() then
        local torps = Sector():getEntitiesByType(EntityType.Torpedo)
        if not torps then
            nextPhase()
        end
    end

    phase8Timer = phase8Timer - timeStep

    if phase8Timer <= 0 then
        -- if player destroyed the torpedo or lost it in some other way, give him a new one
        if mission.data.custom.torpedoLaunched == false and not playerHasTorpedo() and playerInTargetSector() then
            givePlayerTorpedo(RarityType.Petty)
            phase8Timer = 10
        end
    end
end
mission.phases[8].onRestore = function()
    if atTargetLocation() then
        createPirate()
        createAdventurer()

        local craft = Player().craft
        if not craft then return end
        craft:registerCallback("onTorpedoLaunched", "onPirateTorpedoLaunched")
    end
end
mission.phases[8].onTargetLocationLeft = function()
    mission.data.description[3].fulfilled = false
    mission.data.description[5].visible = false
    mission.data.description[5].fulfilled = false
    mission.data.description[6].visible = false
    mission.data.description[6].fulfilled = false
    mission.data.description[7].visible = false
    mission.data.description[7].fulfilled = false
end
mission.phases[8].onTargetLocationEntered = function()
    mission.data.description[7].visible = true
    mission.data.description[7].fulfilled = false
    createPirate()

    local craft = Player().craft
    if not craft then resetToPhase2() return end
    craft:registerCallback("onTorpedoLaunched", "onPirateTorpedoLaunched")
end

mission.phases[9] = {}
mission.phases[9].onBeginServer = function()
    if mission.data.custom.pirateId then
        Player():sendChatMessage(Entity(mission.data.custom.pirateId), ChatMessageType.Chatter, "Dammit, torpedoes again, that's not worth it. I'm out of here."%_T)
        local ai = ShipAI(mission.data.custom.pirateId)
        if ai then
            ai:setPassive()
        end
    end

    mission.phases[9].timers[1].time = 5
end
mission.phases[9].onTargetLocationEntered = function()
    if onServer() then
        mission.phases[9].timers[1].time = 5
    end
end
mission.phases[9].onRestore = function()
    if atTargetLocation() then
        createAdventurer()
        createPirate()
        mission.phases[9].timers[1].time = 5
    end
end
mission.phases[9].onTargetLocationLeft = function()
    mission.data.description[3].fulfilled = false
    mission.data.description[5].visible = false
    mission.data.description[5].fulfilled = false
    mission.data.description[6].visible = false
    mission.data.description[6].fulfilled = false
    mission.data.description[7].visible = false
end
mission.phases[9].timers = {}
mission.phases[9].timers[1] = {callback = function() onPirateJump() end}


mission.phases[10] = {}
local showedLastDialog
mission.phases[10].updateClient = function()
    if playerInTargetSector() then
        mission.data.description[3].fulfilled = true

        if not showedLastDialog then
            local dialog = {}
            dialog.text = "Phew! This pirate had special anti-torpedo weapons. Good for us that he wasn't in the mood for a fight!\n\nLet me give you my spare torpedoes. I've got three with different warheads here. Warheads change the effect of the torpedo, while bodies change speed and maneuverability.\n\nHere, take them, I'd rather do research than fight. They'll be of more use to you."%_t
            dialog.onEnd = "onFinalDialogEnd"

            local entity = Entity(mission.data.custom.adventurerId)
            entity:invokeFunction("story/missionadventurer.lua", "setData", true, false, dialog)
            showedLastDialog = true
        end
    else
        mission.data.description[3].fulfilled = false
    end
end
mission.phases[10].onRestore = function()
    if atTargetLocation() then
        createAdventurer()
    end
end
mission.phases[10].timers = {}
mission.phases[10].timers[1] = {callback = function() showAdventurerChatter() end}


-- helper functions
function getAdventurerName()
    local player = Player()
    local faction = Galaxy():getNearestFaction(player:getHomeSectorCoordinates())
    local language = faction:getLanguage()
    language.seed = Server().seed
    return language:getName()
end

function playerInTargetSector()
    local x, y = Sector():getCoordinates()
    if x == mission.data.location.x and y == mission.data.location.y then
        return true
    else
        return false
    end
end

function findEmptySector(cx, cy)
    if not cx and not cy then
        cx, cy = Sector():getCoordinates()
    end

    local missionTarget = nil
    local playerInsideBarrier = MissionUT.checkSectorInsideBarrier(cx, cy)
    local otherMissionLocations = MissionUT.getMissionLocations()

    local test = function(x, y, regular, offgrid, blocked, home, dust, factionIndex, centralArea)
        if regular then return end
        if blocked then return end
        if offgrid then return end
        if home then return end
        if Balancing_InsideRing(x, y) ~= playerInsideBarrier then return end
        if otherMissionLocations:contains(x, y) then return end

        return true
    end

    local specs = SectorSpecifics(cx, cy, GameSeed())

    for i = 0, 20 do
        local target = specs:findSector(random(), cx, cy, test, 20 + i * 15, i * 15)

        if target then
            missionTarget = target
            break
        end
    end

    if not missionTarget then
        print ("torpedoes tutorial: couldn't find a suitable empty sector")
        terminate()
    end

    return missionTarget
end

function createStartMail()
    local mail = Mail()
    mail.text = Format("Hi there,\n\nI see you found the torpedo launchers. Torpedoes are fantastic weapons with great range that can possibly deal a lot of damage.\n\nMeet me in sector (%1%:%2%) and I'll show you how to get the hang of it. After learning how to use them, you can have some of my old ones.\n\nGreetings,\n%3%"%_T, mission.data.custom.location.x, mission.data.custom.location.y, getAdventurerName())
    mail.header = "Torpedo Instructions /* Mail Subject */"%_T
    mail.sender = Format("%1%, the Adventurer"%_T, getAdventurerName())
    mail.id = "Tutorial_Torpedoes"
    return mail
end

function createAdventurer()
    if onClient() then return end

    local adventShip = AdventurerGuide.spawnOrFindMissionAdventurer(Player())
    if not adventShip then
        -- set new target location and retry
        mission.data.custom.location = findEmptySector()
        mission.data.location = mission.data.custom.location
        mission.data.description[3].arguments = {xCoord = mission.data.location.x, yCoord = mission.data.location.y}
        mission.data.description[3].fulfilled = false
        setPhase(2)
        return
    end

    adventShip.invincible = true
    adventShip.dockable = false
    MissionUT.deleteOnPlayersLeft(adventShip)
    mission.data.custom.adventurerId = adventShip.id.string
    adventShip:invokeFunction("story/missionadventurer.lua", "setInteractingScript", "player/missions/tutorials/torpedoestutorial.lua")
end

function createWreckage()
    local w = Sector():getEntitiesByScriptValue("torpedoes_tutorial_wreckage", true)
    if w then
        mission.data.custom.wreckageId = w.id.string
        mission.data.targets = {}
        table.insert(mission.data.targets, w.id.string)
        return
    end

    local faction = Galaxy():getNearestFaction(mission.data.location.x, mission.data.location.y)
    local plan = PlanGenerator.makeShipPlan(faction, 30, nil, Material(MaterialType.Iron))
    local position = Player().craft.position
    position.pos = position.pos + position.up * 1500
    local wreckage = Sector():createWreckage(plan, position)

    mission.data.custom.wreckageId = wreckage.id.string
    wreckage:addScriptOnce("data/scripts/entity/deleteonplayersleft.lua")
    wreckage:setValue("torpedoes_tutorial_wreckage", true)
    mission.data.targets = {}
    table.insert(mission.data.targets, wreckage.id.string)
end

function checkAdventurerCreated()
    if onServer() then return false end

    return Entity(mission.data.custom.adventurerId) ~= nil
end

function onStartFirstDialog()
    local dialog = {}
    dialog.text = "Hi there, thank you for coming! I'll explain to you how to use torpedoes.\nI've brought this wreckage for target practice."%_t
    dialog.answers = {{answer = "Okay, let's do it."%_t}}
    dialog.onEnd = "onEndFirstDialog"

    local entity = Entity(mission.data.custom.adventurerId)
    entity:invokeFunction("story/missionadventurer.lua", "setData", true, true, dialog)
end

function onEndFirstDialog()
    if onClient() then
        invokeServerFunction("onEndFirstDialog")
        return
    end

    -- check torpedo Storage
    if checkTorpedoStorage() then
        setPhase(5)
    else
        if mission.currentPhase == mission.phases[3] then nextPhase() end
    end
end
callable(nil, "onEndFirstDialog")

function buildTorpedoStorageDialog()
    local dialog = {}
    dialog.text = "Let's start with building a Torpedo Storage that is big enough for our test torpedoes. The overall storage size should be at least 9. Remember that Torpedo Storage needs a certain minimum size for a torpedo to fit in."%_t
    dialog.answers = {{answer = "Okay."%_t}}

    local entity = Entity(mission.data.custom.adventurerId)
    if not entity then return end
    entity:invokeFunction("story/missionadventurer.lua", "setData", true, false, dialog)
end

function equipTorpedoDialog()
    local dialog = {}
    dialog.text = "Here is your first test torpedo. To equip it, you first have to load the torpedo into a Torpedo Shaft.\n\nIn your ship menu, go to the tab for torpedoes and drag & drop the torpedo into the shaft.\n\nThen, go to the overview tab and bind the shaft to a weapon number to set it as active.\n\nI suggest you just go ahead and try to shoot the wreckage as soon as you've done that.\n\nEach torpedo has a certain range so make sure you are close enough to your target!"%_t
    dialog.answers = {{answer = "Okay."%_t}}

    local entity = Sector():getEntitiesByScript("story/missionadventurer.lua")
    if not entity then return end
    entity:invokeFunction("story/missionadventurer.lua", "setData", true, false, dialog)
end

function checkTorpedoStorage()
    local player = Player()
    local craft = player.craft
    if not craft then return false end
    local plan = Plan(craft.id)
    if not plan then return false end

    local torpedoStorage = plan:getBlocksByType(BlockType.TorpedoStorage)
    if not torpedoStorage then
        return false
    end

    local stats = plan:getStats()
    if not stats then return false end
    if stats.torpedoSpace < 8 then
        return false
    end

    return true
end

local warningSent = false
function givePlayerTorpedo(rarity)
    if onClient() then invokeServerFunction("givePlayerTorpedo") return end

    local rarity = rarity or RarityType.Uncommon
    if playerHasTorpedo() then rarity = RarityType.Petty end

    local player = Player()
    local craft = player.craft
    if not craft then return end

    local torpedoLauncher = TorpedoLauncher(craft.id)

    if not torpedoLauncher then
        if not warningSent then
            player:sendChatMessage("The Adventurer"%_T, ChatMessageType.Information, "Your torpedo launcher has been destroyed."%_T)
            warningSent = true
        end

        return
    end

    local x = mission.data.location.x
    local y = mission.data.location.y    
    local torpedo = TorpedoGenerator():generate(x, y, 0, Rarity(rarity), 1, 1)
    torpedoLauncher:addTorpedo(torpedo)
end
callable(nil, "givePlayerTorpedo")

function onTorpedoHit(objectIndex, shooterIndex, location)
    if objectIndex and objectIndex.string ~= mission.data.custom.wreckageId then return end

    local wreckage = Entity(mission.data.custom.wreckageId)
    if wreckage then wreckage:unregisterCallback("onTorpedoHit", "onTorpedoHit") end

    local craft = Player().craft
    if not craft then return end

    craft:unregisterCallback("onTorpedoLaunched", "onWreckageTorpedoLaunched")
    mission.data.custom.torpedoHit = true
    mission.data.targets = {}
    mission.data.description[6].fulfilled = true

    createPirate()
    mission.phases[7].timers[1].time = 5
    mission.phases[7].timers[1].passed = 0
    mission.phases[7].timers[1].stopped = false
    mission.data.custom.torpedoesLaunched = 0
end

function onWreckageTorpedoLaunched()
    mission.data.description[5].fulfilled = true

    if onClient() then return end -- don't run this on Client, we want timer to be server only

    -- player only gets one torpedo at a time from adventurer
    mission.data.custom.torpedoesLaunched = mission.data.custom.torpedoesLaunched + 1
    if mission.data.custom.torpedoesLaunched > 1 then return end

    -- reset timer
    mission.phases[7].timers[2].passed = 0
    mission.phases[7].timers[2].stopped = false
    mission.phases[7].timers[2].time = 15
end

function onNeedsNewTorpedo()
    if onServer() then
        -- if we hit the wreckage, but it still called this function we have to return
        if mission.data.custom.torpedoHit then return end

        mission.data.custom.torpedoesLaunched = 0

        invokeClientFunction(Player(), "newTorpedoDialog")
        return
    end
end

function newTorpedoDialog()
    local dialog = {}
    dialog.text = "Ah, dang it. Here, have another one and try again!"%_t
    dialog.answers = {{answer = "Thanks, I will!"%_t}}
    dialog.onEnd = "onEndMissedWreckageDialog"

    local entity = Entity(mission.data.custom.adventurerId)
    if not entity then return end
    entity:invokeFunction("story/missionadventurer.lua", "setData", true, false, dialog)
end

function onEndMissedWreckageDialog()
    if not playerHasTorpedo() then givePlayerTorpedo() end
end

function playerHasTorpedo()
    local player = Player()
    local craft = player.craft
    if not craft then return end
    local torpedoLauncher = TorpedoLauncher(craft.id)
    if not torpedoLauncher then return false end
    return (torpedoLauncher.numTorpedoes > 0)
end

function createPirate()
    local p = Sector():getEntitiesByScriptValue("torpedoes_tutorial_pirate", true)
    if p then
        return
    end

    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local pos = dir * 1000

    local generator = AsyncPirateGenerator(nil, onPirateCreated)

    generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos))
end

function onPirateCreated(pirate)
    mission.data.custom.pirateId = pirate.id.string
    ShipAI(pirate.id):setPassive()
    pirate.invincible = true
    pirate.dockable = false
    pirate:setValue("torpedoes_tutorial_pirate", true)
    pirate:addScriptOnce("data/scripts/entity/deleteonplayersleft.lua")

    ShipUtility.addCIWSEquipment(pirate)
end

function onSpawnPirate()
    if onServer() then invokeClientFunction(Player(), "onSpawnPirate") return end

    if playerInTargetSector() then

        local dialog = {}
        dialog.text = "Uh oh, there's a pirate! Here, take this torpedo and shoot them down!"%_t
        dialog.onEnd = "onSpawnPirateEnd"

        local entity = Entity(mission.data.custom.adventurerId)
        if not entity then onSpawnPirateEnd() return end
        entity:invokeFunction("story/missionadventurer.lua", "setData", true, false, dialog)
    else
        mission.data.description[3].fulfilled = false
    end
end

function onSpawnPirateEnd()
    if onClient() then invokeServerFunction("onSpawnPirateEnd") return end

    mission.data.description[7].visible = true

    if not playerHasTorpedo() then givePlayerTorpedo() end
    if not mission.data.custom.pirateId or not ShipAI(mission.data.custom.pirateId) then return end

    ShipAI(mission.data.custom.pirateId):setAggressive()
    mission.data.custom.pirateSetAggressive = true
end
callable(nil, "onSpawnPirateEnd")

function onPirateTorpedoLaunched(entityId, torpedoId)
    mission.data.custom.torpedoLaunched = true
end

function onPirateJump()
    local pirate = Entity(mission.data.custom.pirateId)
    if pirate then
        Sector():deleteEntityJumped(pirate)
        mission.data.description[7].fulfilled = true
    end

    nextPhase()
end

function onFinalDialogEnd()

    if onClient() then
        invokeServerFunction("onFinalDialogEnd")
        return
    end

    local player = Player()
    player:setValue("tutorial_torpedoes_accomplished", true) -- we set this here, so that players can't farm this mission

    givePlayerReward()
    mission.phases[10].timers[1].time = 3
end
callable(nil, "onFinalDialogEnd")

function givePlayerReward()
    local player = Player()
    local craft = Player().craft
    if not craft then return end
    local torpedoLauncher = TorpedoLauncher(craft.id)
    local x = mission.data.location.x
    local y = mission.data.location.y

    local generator = TorpedoGenerator()
    local torpedo = generator:generate(x, y, 0, Rarity(RarityType.Uncommon), 1, 9)
    local torpedo2 = generator:generate(x, y, 0, Rarity(RarityType.Uncommon), 2, 5)
    local torpedo3 = generator:generate(x, y, 0, Rarity(RarityType.Uncommon), 4, 1)
    torpedoLauncher:addTorpedo(torpedo)
    torpedoLauncher:addTorpedo(torpedo2)
    torpedoLauncher:addTorpedo(torpedo3)
end

function showAdventurerChatter()
    Player():sendChatMessage(Entity(mission.data.custom.adventurerId), ChatMessageType.Chatter, "Nice, this one has potential. And another good deed done."%_T)
    Entity(mission.data.custom.adventurerId):addScript("data/scripts/entity/utility/delayeddelete.lua", random():getFloat(10, 20))
    accomplish()
end

function resetToPhase2()
    -- get new location and reset to phase 2
    mission.data.custom.location = findEmptySector()
    mission.data.location = mission.data.custom.location

    mission.data.description[3].arguments = {xCoord = mission.data.location.x, yCoord = mission.data.location.y}
    mission.data.description[3].fulfilled = false

    for i = 4, #mission.data.description do
        mission.data.description[i].visible = false
        mission.data.description[i].fulfilled = false
    end

    mission.data.custom.torpedoHit = false

    setPhase(2)
end
