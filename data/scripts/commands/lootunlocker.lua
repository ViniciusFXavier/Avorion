package.path = package.path .. ";data/scripts/player/?.lua"

function execute(sender, commandName)
    Player(sender).craft:addScriptOnce("data/scripts/entity/lootUnlocker.lua")
    return 0, "", ""
end

function getDescription()
    return "Unbinds all loot in a sector from its owner."
end

function getHelp()
    return "usage /lootunlocker"
end
