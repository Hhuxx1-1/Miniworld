-- Utility: normalize a vector (keeps the bullet traveling at the correct speed)
local function normalize(x, y, z)
    local len = math.sqrt(x*x + y*y + z*z)
    if len == 0 then return 0, 0, 0 end
    return x/len, y/len, z/len
end

---------------------------------------------------
-- CONFIG: tweak these values to taste
---------------------------------------------------
local SNIPER_BULLET_ID = 4099  -- The item shot by the weapon
local PROJECTILE_ID    = 4100  -- The actual projectile entity
local SPEED            = 500   -- Snipers are much faster than shotguns
local MAX_PIERCE       = 3     -- How many targets the bullet can pass through
---------------------------------------------------

-- Tracker to remember how many times a player's current shot can still pierce
local pierceTracker = {}

-- Event 1: Firing the Sniper
ScriptSupportEvent:registerEvent("Missile.Create", function(e)
    if e.itemid == SNIPER_BULLET_ID then
        local shooterId = e.helperobjid
        local dummyProjId = e.toobjid

        -- Get forward direction from where the player is looking
        local r, fx, fy, fz = Actor:getFaceDirection(shooterId)
        fx, fy, fz = normalize(fx, fy, fz)

        -- Get muzzle/world spawn position
        local rpos, mx, my, mz = Actor:getPosition(dummyProjId)

        -- Kill the dummy shotgun/sniper shell
        Actor:killSelf(dummyProjId)

        -- Spawn a single, straight, high-speed sniper projectile
        World:spawnProjectileByDir(shooterId, PROJECTILE_ID, mx, my, mz, fx, fy, fz, SPEED)

        -- Reset the pierce counter for this player's shot
        pierceTracker[shooterId] = MAX_PIERCE
    end

    -- Clean up the projectile if it flies into the sky forever (Sniper range limit)
    if e.itemid == PROJECTILE_ID then
        threadpool:delay(1.5, function()
            Actor:killSelf(e.toobjid)
        end)
    end
end)

-- Event 2: Penetration Logic (Respawning the bullet on impact)
ScriptSupportEvent:registerEvent("Actor.Damage", function(e)
    local victimId = e.actorid
    local shooterId = e.objid

    -- Check if the attacker recently fired a sniper and still has pierce charges left
    if shooterId and pierceTracker[shooterId] and pierceTracker[shooterId] > 0 then

        -- Subtract one pierce charge
        pierceTracker[shooterId] = pierceTracker[shooterId] - 1

        -- Calculate the exact trajectory the bullet was traveling
        -- Trajectory = (Victim's Position) - (Shooter's Position)
        local r1, sx, sy, sz = Actor:getPosition(shooterId)
        local r2, vx, vy, vz = Actor:getPosition(victimId)

        if r1 == 0 and r2 == 0 then
            local dx = vx - sx
            local dy = vy - sy
            local dz = vz - sz
            dx, dy, dz = normalize(dx, dy, dz)

            -- Spawn the new bullet slightly PAST the victim 
            -- (We multiply the direction by 1.5 blocks so it spawns on the other side of their body and doesn't instantly hit them again)
            local spawnX = vx + (dx * 1.5)
            local spawnY = vy + (dy * 1.5)
            local spawnZ = vz + (dz * 1.5)

            -- Fire the continuation bullet to hit the next target
            World:spawnProjectileByDir(shooterId, PROJECTILE_ID, spawnX, spawnY, spawnZ, dx, dy, dz, SPEED)
        end
    end
end)