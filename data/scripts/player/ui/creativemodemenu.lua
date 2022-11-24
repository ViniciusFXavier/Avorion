package.path = package.path .. ";data/scripts/lib/?.lua"

include("callable")
local UpgradeGenerator = include("upgradegenerator")
local SectorFighterGenerator = include("sectorfightergenerator")
local TorpedoGenerator = include("torpedogenerator")
local CaptainGenerator = include("captaingenerator")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace CreativeMode
CreativeMode = {}

function CreativeMode.initialize()
    if not Scenario().isCreative then
        terminate()
        return
    end

    if onClient() then
        local tab = ShipWindow():createTab("Creative Mode"%_t, "data/textures/icons/round-star.png", "Creative Mode Command Center"%_t)

        local lister = UIVerticalLister(Rect(tab.size), 10, 0)
        tab:createLabel(lister:nextRect(30), "Creative Mode Command Center"%_t, 28):setCenterAligned()

        local splitter = UIVerticalMultiSplitter(lister.rect, 10, 0, 3)

        local leftSplitter = UIHorizontalSplitter(splitter:partition(0), 10, 0, 0.5)
        leftSplitter.topSize = 410
        tab:createFrame(leftSplitter.top)
        tab:createFrame(Rect(leftSplitter.bottom.lower, vec2(leftSplitter.bottom.upper.x, leftSplitter.bottom.lower.y + 124)))


        local lister = UIVerticalLister(leftSplitter.top, 10, 10)
        local red = ColorRGB(1, 0.2, 0.2)

        -- crew
        tab:createLabel(lister:nextRect(20), "Crew"%_t, 20):setCenterAligned()

        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 3)
        CreativeMode.createIconButton(tab, Rect(split:partition(0).topLeft, split:partition(2).bottomRight), "data/textures/icons/crew.png", "Add Crew /* Button */"%_t, "onAddCrewPressed")
        CreativeMode.createIconButton(tab, split:partition(3), "data/textures/icons/captain.png", "Add Captain /* Button */"%_t, "onAddCaptainPressed")


        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 3)
        CreativeMode.createIconButton(tab, split:partition(0), "data/textures/icons/helmet.png", "Add Pilots"%_t, "onAddPilotsPressed")
        CreativeMode.createIconButton(tab, split:partition(1), "data/textures/icons/security.png", "Add Security"%_t, "onAddSecurityPressed")
        CreativeMode.createIconButton(tab, split:partition(2), "data/textures/icons/bolter-gun.png", "Add Boarders"%_t, "onAddBoardersPressed")
        local button = CreativeMode.createIconButton(tab, split:partition(3), "data/textures/icons/cross-mark.png", "Clear"%_t, "onClearCrewPressed")
        button.iconColor = red

--        lister:nextRect(10)

        -- guns, systems
        tab:createLabel(lister:nextRect(20), "Guns 'n' Systems"%_t, 20):setCenterAligned()
        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 3)
        local button = CreativeMode.createIconButton(tab, split:partition(3), "data/textures/icons/cross-mark.png", "Clear Inventory"%_t, "onClearInventoryPressed")
        local split = UIVerticalMultiSplitter(Rect(split:partition(0).lower, split:partition(2).upper), 10, 0, 1)
        CreativeMode.createIconButton(tab, split:partition(0), "data/textures/icons/turret.png", "Guns Guns Guns"%_t, "onAddGunsPressed")
        CreativeMode.createIconButton(tab, split:partition(1), "data/textures/icons/circuitry.png", "Gimme Systems"%_t, "onAddSystemsPressed")
        button.iconColor = red

--        lister:nextRect(10)

        -- fighters
        tab:createLabel(lister:nextRect(20), "Fighters"%_t, 20):setCenterAligned()
        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 3)
        local rect = Rect(split:partition(0).lower, split:partition(1).upper)
        CreativeMode.createIconButton(tab, split:partition(2), "data/textures/icons/mining.png", "Add Mining Fighters"%_t, "onMiningFightersPressed")
        CreativeMode.createIconButton(tab, split:partition(3), "data/textures/icons/rock.png", "Add R-Mining Fighters"%_t, "onRMiningFightersPressed")

        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 3)
        rect.upper = split:partition(1).upper
        CreativeMode.createIconButton(tab, rect, "data/textures/icons/fighter.png", "Add Armed Fighters"%_t, "onArmedFightersPressed")
        CreativeMode.createIconButton(tab, split:partition(2), "data/textures/icons/recycle-arrows.png", "Add Salvaging Fighters"%_t, "onSalvagingFightersPressed")
        CreativeMode.createIconButton(tab, split:partition(3), "data/textures/icons/scrap-metal.png", "Add R-Salvaging Fighters"%_t, "onRSalvagingFightersPressed")

        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 2)
        CreativeMode.createIconButton(tab, split:partition(0), "data/textures/icons/repair.png", "Add Repair Fighters"%_t, "onAddRepairFightersPressed")
        CreativeMode.createIconButton(tab, split:partition(1), "data/textures/icons/crew.png", "Add Boarding Shuttles"%_t, "onAddCrewShuttlesPressed")
        local button = CreativeMode.createIconButton(tab, split:partition(2), "data/textures/icons/cross-mark.png", "Clear Hangar"%_t, "onClearHangarPressed")
        button.iconColor = red

--        lister:nextRect(10)

        -- torpedoes
        tab:createLabel(lister:nextRect(20), "Torpedoes"%_t, 20):setCenterAligned()
        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 3)
        local rect = Rect(split:partition(0).lower, split:partition(2).upper)
        CreativeMode.createIconButton(tab, rect, "data/textures/icons/missile-pod.png", "Add Torpedoes"%_t, "onAddTorpedoesPressed")
        local button = CreativeMode.createIconButton(tab, split:partition(3), "data/textures/icons/cross-mark.png", "Clear Torpedoes"%_t, "onClearTorpedoesPressed")
        button.iconColor = red

--        lister:nextRect(10)

        local lister = UIVerticalLister(leftSplitter.bottom, 10, 10)

        -- relations
        tab:createLabel(lister:nextRect(24), "Relations"%_t, 24):setCenterAligned()
        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 3)
        local relation = Relation()
        local button = CreativeMode.createIconButton(tab, split:partition(0), "data/textures/icons/condor-emblem.png", "Ally"%_t, "onAllyPressed")
        relation.status = RelationStatus.Allies
        button.iconColor = relation.color
        local button = CreativeMode.createIconButton(tab, split:partition(1), "data/textures/icons/shaking-hands.png", "Neutral"%_t, "onNeutralPressed")
        relation.status = RelationStatus.Neutral
        button.iconColor = relation.color
        local button = CreativeMode.createIconButton(tab, split:partition(2), "data/textures/icons/ceasefire.png", "Ceasefire"%_t, "onCeasefirePressed")
        relation.status = RelationStatus.Ceasefire
        button.iconColor = relation.color
        local button = CreativeMode.createIconButton(tab, split:partition(3), "data/textures/icons/crossed-rifles.png", "War"%_t, "onWarPressed")
        relation.status = RelationStatus.War
        button.iconColor = relation.color

        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 1)
        CreativeMode.createIconButton(tab, split:partition(0), "data/textures/icons/arrow-up2.png", "Like"%_t, "onLikePressed")
        CreativeMode.createIconButton(tab, split:partition(1), "data/textures/icons/arrow-down2.png", "Dislike"%_t, "onDislikePressed")


        -- goods
        local sortedGoods = {}
        for name, good in pairs(goods) do
            table.insert(sortedGoods, good)
        end

        function goodsByName(a, b) return a.name < b.name end
        table.sort(sortedGoods, goodsByName)


        local bigColumnIndex = 0
        local columnIndex = 0

        local rect = Rect(splitter:partition(1).lower, splitter:partition(3).upper)
        tab:createFrame(rect)
        local lister = UIVerticalLister(rect, 10, 10)

        local split = UIVerticalSplitter(lister:nextRect(20), 10, 0, 0.7)
        tab:createLabel(split.left, "Cargo"%_t, 20):setCenterAligned()
        CreativeMode.stolenCargoCheckBox = tab:createCheckBox(split.right, "Mark as Stolen"%_t, "onStolenCargoChecked")

        local firstLetter
        local splitCount = 14
        local split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, splitCount)
        for _, good in pairs(sortedGoods) do
            local first = string.sub(good.name, 1, 1)

            if first ~= firstLetter then
                tab:createLabel(split:partition(columnIndex), first, 20):setCenterAligned()
                columnIndex = columnIndex + 1
                if columnIndex > splitCount then
                    columnIndex = 0
                    split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, splitCount)
                end
            end

            firstLetter = first

            CreativeMode.createIconButton(tab, split:partition(columnIndex), good.icon, good.name, "onGoodsButtonPressed")
            columnIndex = columnIndex + 1
            if columnIndex > splitCount then
                columnIndex = 0
                split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, splitCount)
            end
        end

        -- add clear cargo button
        if columnIndex == splitCount then
            split = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, splitCount)
        end

        local button = CreativeMode.createIconButton(tab, split:partition(splitCount), "data/textures/icons/cross-mark.png", "Clear Cargo"%_t, "onClearCargoPressed")
        button.iconColor = red
    end
end

function CreativeMode.createIconButton(tab, rect, icon, tooltip, callback)
    local button = tab:createButton(rect, "", callback)
    button.icon = icon
    button.tooltip = tooltip

    return button
end

function CreativeMode.onStolenCargoChecked()
end

function CreativeMode.onAddCrewPressed()
    if onClient() then
        invokeServerFunction("onAddCrewPressed")
        return
    end

    local player = Player(callingPlayer)
    local craft = player.craft
    if not craft then return end

    local minCrew = craft.idealCrew
    if not minCrew then return end

    local captain = craft:getCaptain()
    if captain then
        minCrew:setCaptain(captain)
    end

    craft.crew = minCrew
end
callable(CreativeMode, "onAddCrewPressed")

function CreativeMode.onAddCaptainPressed()
    if onClient() then
        invokeServerFunction("onAddCaptainPressed")
        return
    end

    local player = Player(callingPlayer)
    local craft = player.craft
    if not craft then return end

    local generator = CaptainGenerator()
    craft:setCaptain(generator:generate())
end
callable(CreativeMode, "onAddCaptainPressed")

function CreativeMode.onAddPilotsPressed()
    if onClient() then
        invokeServerFunction("onAddPilotsPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local crew = player.craft.crew
    if not valid(crew) then return end

    crew:add(10, CrewMan(CrewProfessionType.Pilot))
    player.craft.crew = crew
end
callable(CreativeMode, "onAddPilotsPressed")

function CreativeMode.onAddSecurityPressed()
    if onClient() then
        invokeServerFunction("onAddSecurityPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local crew = player.craft.crew
    if not valid(crew) then return end

    crew:add(10, CrewMan(CrewProfessionType.Security))
    player.craft.crew = crew
end
callable(CreativeMode, "onAddSecurityPressed")

function CreativeMode.onAddBoardersPressed()
    if onClient() then
        invokeServerFunction("onAddBoardersPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local crew = player.craft.crew
    if not valid(crew) then return end

    crew:add(10, CrewMan(CrewProfessionType.Attacker))
    player.craft.crew = crew
end
callable(CreativeMode, "onAddBoardersPressed")

function CreativeMode.onClearCrewPressed()
    if onClient() then
        invokeServerFunction("onClearCrewPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    player.craft.crew = Crew()
end
callable(CreativeMode, "onClearCrewPressed")

function CreativeMode.onAddGunsPressed()
    if onClient() then
        invokeServerFunction("onAddGunsPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local craftFaction = Faction(player.craft.factionIndex)

    local x, y = player:getSectorCoordinates()

    for j = 1, 10 do
        local turret = SectorTurretGenerator():generate(x, y)
        craftFaction:getInventory():add(InventoryTurret(turret))
    end
end
callable(CreativeMode, "onAddGunsPressed")

function CreativeMode.onAddSystemsPressed()
    if onClient() then
        invokeServerFunction("onAddSystemsPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local craftFaction = Faction(player.craft.factionIndex)

    local x, y = player:getSectorCoordinates()
    local generator = UpgradeGenerator()
    if player.ownsBlackMarketDLC then
        generator.blackMarketUpgradesEnabled = true
    end
    if player.ownsIntoTheRiftDLC then
        generator.intoTheRiftUpgradesEnabled = true
    end

    for i = 1, 10 do
        local upgrade = generator:generateSectorSystem(x, y)
        craftFaction:getInventory():add(upgrade)
    end
end
callable(CreativeMode, "onAddSystemsPressed")

function CreativeMode.onClearInventoryPressed()
    if onClient() then
        invokeServerFunction("onClearInventoryPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local craftFaction = Faction(player.craft.factionIndex)
    craftFaction:getInventory():clear()
end
callable(CreativeMode, "onClearInventoryPressed")



function CreativeMode.addFighterSquad(weaponType, squadName)
    local player = Player(callingPlayer)

    local x, y = player:getSectorCoordinates()
    local fighter = SectorFighterGenerator():generate(x, y, nil, nil, weaponType)

    CreativeMode.addFighters(fighter, squadName)
end

function CreativeMode.addFighters(fighter, squadName)
    squadName = squadName or "Script Squad"

    local player = Player(callingPlayer)
    if not player.craft then return end

    local hangar = Hangar(player.craft.id)
    if not valid(hangar) then return end

    local squad = hangar:addSquad(squadName)
    if squad == -1 then return end

    hangar:setBlueprint(squad, fighter)

    for i = hangar:getSquadFighters(squad), hangar:getSquadMaxFighters(squad) - 1 do
        if hangar.freeSpace < fighter.volume then return end

        hangar:addFighter(squad, fighter)
    end
end

function CreativeMode.onArmedFightersPressed()
    if onClient() then
        invokeServerFunction("onArmedFightersPressed")
        return
    end

    CreativeMode.addFighterSquad(WeaponType.RailGun, "Railgun Squad")
end
callable(CreativeMode, "onArmedFightersPressed")

function CreativeMode.onMiningFightersPressed()
    if onClient() then
        invokeServerFunction("onMiningFightersPressed")
        return
    end

    CreativeMode.addFighterSquad(WeaponType.MiningLaser, "Mining Squad")
end
callable(CreativeMode, "onMiningFightersPressed")

function CreativeMode.onRMiningFightersPressed()
    if onClient() then
        invokeServerFunction("onRMiningFightersPressed")
        return
    end

    CreativeMode.addFighterSquad(WeaponType.RawMiningLaser, "R-Mining Squad")
end
callable(CreativeMode, "onRMiningFightersPressed")

function CreativeMode.onSalvagingFightersPressed()
    if onClient() then
        invokeServerFunction("onSalvagingFightersPressed")
        return
    end

    CreativeMode.addFighterSquad(WeaponType.SalvagingLaser, "Salvaging Squad")
end
callable(CreativeMode, "onSalvagingFightersPressed")

function CreativeMode.onRSalvagingFightersPressed()
    if onClient() then
        invokeServerFunction("onRSalvagingFightersPressed")
        return
    end

    CreativeMode.addFighterSquad(WeaponType.RawSalvagingLaser, "R-Salvaging Squad")
end
callable(CreativeMode, "onRSalvagingFightersPressed")

function CreativeMode.onAddRepairFightersPressed()
    if onClient() then
        invokeServerFunction("onAddRepairFightersPressed")
        return
    end

    CreativeMode.addFighterSquad(WeaponType.RepairBeam, "Repair Squad")
end
callable(CreativeMode, "onAddRepairFightersPressed")

function CreativeMode.onAddCrewShuttlesPressed()
    if onClient() then
        invokeServerFunction("onAddCrewShuttlesPressed")
        return
    end

    local player = Player(callingPlayer)

    local x, y = player:getSectorCoordinates()
    local fighter = SectorFighterGenerator():generateCrewShuttle(x, y)
    CreativeMode.addFighters(fighter, "Attacker Squad")
end
callable(CreativeMode, "onAddCrewShuttlesPressed")

function CreativeMode.onClearHangarPressed()
    if onClient() then
        invokeServerFunction("onClearHangarPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local hangar = Hangar(player.craft.id)
    if not valid(hangar) then return end

    hangar:clear()
end
callable(CreativeMode, "onClearHangarPressed")

function CreativeMode.onAddTorpedoesPressed()
    if onClient() then
        invokeServerFunction("onAddTorpedoesPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local launcher = TorpedoLauncher(player.craft.id)
    if not valid(launcher) then return end

    local shafts = {launcher:getShafts()}

    -- fill all present squads
    for _, shaft in pairs(shafts) do
        local torpedo = TorpedoGenerator():generate(x, y)

        for i = 1, 10 do
            launcher:addTorpedo(torpedo, shaft)
        end
    end

    for j = 1, 10 do
        local torpedo = TorpedoGenerator():generate(x, y)

        for i = 1, 5 do
            launcher:addTorpedo(torpedo)
        end
    end
end
callable(CreativeMode, "onAddTorpedoesPressed")

function CreativeMode.onClearTorpedoesPressed()
    if onClient() then
        invokeServerFunction("onClearTorpedoesPressed")
        return
    end

    local player = Player(callingPlayer)
    if not player.craft then return end

    local launcher = TorpedoLauncher(player.craft.id)
    if not valid(launcher) then return end

    launcher:clear()
end
callable(CreativeMode, "onClearTorpedoesPressed")



function CreativeMode.getRelationFactions()
    local player = Player(callingPlayer)
    local craft = player.craft
    if not craft then return end

    local actor = Faction(craft.factionIndex)
    local selected = craft.selectedObject
    if not valid(selected) or not selected.factionIndex then
        player:sendChatMessage("", ChatMessageType.Error, "No object that belongs to an AI faction selected."%_T)
        return
    end

    local faction = Faction(selected.factionIndex)
    if not valid(faction) or not faction.isAIFaction then
        player:sendChatMessage("", ChatMessageType.Error, "No object that belongs to an AI faction selected."%_T)
        return
    end

    local relation = actor:getRelation(faction.index)
    if not relation or relation.isStatic or faction.staticRelationsToPlayers or faction.staticRelationsToAll or
            faction:hasStaticRelationsToFaction(actor.index) or faction.alwaysAtWar then
        player:sendChatMessage("", ChatMessageType.Error, "Relations with this faction can't be changed."%_T)
        return
    end

    return actor, faction
end

function CreativeMode.setRelationStatus(status)
    local actor, faction = CreativeMode.getRelationFactions()
    if not actor or not faction then return end

    setRelationStatus(actor, faction, status, true, true)
end

function CreativeMode.changeRelationLevel(delta)
    local actor, faction = CreativeMode.getRelationFactions()
    if not actor or not faction then return end

    changeRelations(actor, faction, delta)
end

function CreativeMode.onAllyPressed()
    if onClient() then
        invokeServerFunction("onAllyPressed")
        return
    end

    CreativeMode.setRelationStatus(RelationStatus.Allies)
end
callable(CreativeMode, "onAllyPressed")

function CreativeMode.onNeutralPressed()
    if onClient() then
        invokeServerFunction("onNeutralPressed")
        return
    end

    CreativeMode.setRelationStatus(RelationStatus.Neutral)
end
callable(CreativeMode, "onNeutralPressed")

function CreativeMode.onCeasefirePressed()
    if onClient() then
        invokeServerFunction("onCeasefirePressed")
        return
    end

    CreativeMode.setRelationStatus(RelationStatus.Ceasefire)
end
callable(CreativeMode, "onCeasefirePressed")

function CreativeMode.onWarPressed()
    if onClient() then
        invokeServerFunction("onWarPressed")
        return
    end

    CreativeMode.setRelationStatus(RelationStatus.War)
end
callable(CreativeMode, "onWarPressed")

function CreativeMode.onLikePressed()
    if onClient() then
        invokeServerFunction("onLikePressed")
        return
    end

    CreativeMode.changeRelationLevel(10000)
end
callable(CreativeMode, "onLikePressed")

function CreativeMode.onDislikePressed()
    if onClient() then
        invokeServerFunction("onDislikePressed")
        return
    end

    CreativeMode.changeRelationLevel(-10000)
end
callable(CreativeMode, "onDislikePressed")



function CreativeMode.onGoodsButtonPressed(button, stolen, amount)
    if onClient() then
        amount = 1

        local keyboard = Keyboard()
        if keyboard:keyPressed(KeyboardKey.LShift) or keyboard:keyPressed(KeyboardKey.RShift) then
            amount = 10
        elseif keyboard:keyPressed(KeyboardKey.LControl) or keyboard:keyPressed(KeyboardKey.RControl) then
            amount = 100
        end
        invokeServerFunction("onGoodsButtonPressed", button.tooltip, CreativeMode.stolenCargoCheckBox.checked, amount)
        return
    end

    local player = Player(callingPlayer)
    local craft = player.craft
    if not craft then return end

    local name = button -- passed from the client
    local good = goods[name]:good()
    good.stolen = stolen

    craft:addCargo(good, amount)
end
callable(CreativeMode, "onGoodsButtonPressed")

function CreativeMode.onClearCargoPressed()
    if onClient() then
        invokeServerFunction("onClearCargoPressed")
        return
    end

    local player = Player(callingPlayer)
    local craft = player.craft
    if not craft then return end

    for cargo, amount in pairs(craft:getCargos()) do
        craft:removeCargo(cargo, amount)
    end
end
callable(CreativeMode, "onClearCargoPressed")
