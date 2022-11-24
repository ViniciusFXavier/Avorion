package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")
include ("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Blinker
Blinker = {}

local data = {}
data.blinkCooldown = 0
data.glow = false

function Blinker.initialize()
    if onServer() then
        local entity = Entity()
        entity:registerCallback("onHullHit", "onHit")
        entity:registerCallback("onShieldHit", "onHit")
    end
end

function Blinker.updateServer(timeStep)
    if data.blinkCooldown <= 0 then return end
    data.blinkCooldown = data.blinkCooldown - timeStep
end

local glowSize = 0
function Blinker.updateClient(timeStep)
    -- Glow as indicator for charging the blink
    if data.glow == true then
        glowSize = math.min(glowSize + timeStep * 1.6, 2.5)

        Sector():createGlow(Entity().translationf, Entity().radius * glowSize, ColorRGB(0.8, 0.5, 0.3))
    else
        glowSize = 0
    end
end

function Blinker.blink()
    local entity = Entity()
    local distance = entity.radius * (2 + random():getFloat(0, 3))
    local direction = random():getDirection()

    data.glow = false
    Blinker.sync()

    broadcastInvokeClientFunction("animation", direction, 0.2)
    entity.translation = dvec3(entity.translationf + direction * distance)
end

function Blinker.animation(direction, intensity)
    Sector():createHyperspaceJumpAnimation(Entity(), direction, ColorRGB(0.6, 0.5, 0.3), intensity)
end

local successiveBlinks = 1
function Blinker.onHit()
    -- Quantum Xsotan only blinks after a hit and with reasonable time intervals so it is fun to fight against it
    if data.blinkCooldown <= 0 then
        -- Quantum Xsotan can only cascade after a few executed normal blinks and should have the chance to cascade when hit for the first time
        if successiveBlinks > random():getInt(1, 3) then
            data.blinkCooldown = random():getFloat(4, 6)
            successiveBlinks = 0

            -- The cascade has to be deferred because it charges before it gets executed
            deferredCallback(1.5, "cascade", random():getInt(3, 4))
        else
            data.blinkCooldown = random():getFloat(3, 5)
            successiveBlinks = successiveBlinks + 1

            -- The blink has to be deferred because it charges before it gets executed
            deferredCallback(1.5, "blink")
        end

        data.glow = true
        Blinker.sync()
    end
end

function Blinker.cascade(remainingCascades)
    if remainingCascades <= 0 then return end

    deferredCallback(0.4, "cascade", remainingCascades - 1)
    Blinker.blink()
end

function Blinker.sync(data_in)
    if onClient() then
        if not data_in then
            invokeServerFunction("sync")
        else
            data = data_in
        end
    else
        broadcastInvokeClientFunction("sync", data)
    end
end
callable(Blinker, "sync")
