-- Utility: normalize a vector
local function normalize(x, y, z)
    local len = math.sqrt(x*x + y*y + z*z)
    if len == 0 then return 0, 0, 0 end
    return x/len, y/len, z/len
end

-- Build a stable perpendicular basis (right, up, forward)
local function buildBasis(fx, fy, fz)
    -- choose an arbitrary up vector that's not parallel to forward
    local upx, upy, upz = 0, 1, 0
    if math.abs(fy) > 0.99 then
        upx, upy, upz = 1, 0, 0
    end

    -- right = forward x up
    local rx = fy * upz - fz * upy
    local ry = fz * upx - fx * upz
    local rz = fx * upy - fy * upx
    rx, ry, rz = normalize(rx, ry, rz)

    -- recompute orthogonal up = right x forward
    local ux = ry * fz - rz * fy
    local uy = rz * fx - rx * fz
    local uz = rx * fy - ry * fx
    ux, uy, uz = normalize(ux, uy, uz)

    return rx, ry, rz, ux, uy, uz
end

-- Spawn a fixed ring of pellets around forward
local function spawnFixedRing(sourceId, projId, x, y, z, fx, fy, fz, speed, pelletCount, coneAngleDeg)
    -- ensure forward is normalized
    fx, fy, fz = normalize(fx, fy, fz)

    -- build perpendicular basis
    local rx, ry, rz, ux, uy, uz = buildBasis(fx, fy, fz)

    -- cone angle measured from forward (degrees -> radians)
    local theta = math.rad(coneAngleDeg)
    local cosTheta = math.cos(theta)
    local sinTheta = math.sin(theta)
    -- Chat:sendSystemMsg("Sin : "..sinTheta..", Cos : "..cosTheta..", theta : ",theta)
    -- Chat:sendSystemMsg("rx : "..rx.." ry : "..ry.." rz : "..rz.." ux : "..ux.." uy : "..uy.." uz : "..uz)
    -- evenly spaced around circle

        -- Chat:sendSystemMsg("ux :"..ux);
        -- Chat:sendSystemMsg("uy :"..uy);
        -- Chat:sendSystemMsg("uz :"..uz);
    for i = 0, pelletCount - 1 do
        local phi = (2 * math.pi) * (i / pelletCount)
        local c = math.cos(phi)
        local s = math.sin(phi)

        -- axis = cos(phi) * right + sin(phi) * up
        local ax = rx * c + ux * s
        local ay = ry * c + uy * s
        local az = rz * c + uz * s

        -- direction = forward * cosTheta + axis * sinTheta
        local dx = fx * cosTheta + ax * sinTheta
        local dy = fy * cosTheta + ay * sinTheta
        local dz = fz * cosTheta + az * sinTheta

        dx, dy, dz = normalize(dx, dy, dz)

        -- if math.abs(dx) < 0.001 or math.abs(dy) < 0.001 or math.abs(dz) < 0.001 then 
        --     -- dx,dy,dz = dx *1000,dy *1000,dz *1000
        -- end 
        World:spawnProjectileByDir(sourceId, projId, x, y, z, dx, dy, dz, speed)
    end
end

---------------------------------------------------
-- CONFIG: tweak these values to taste
---------------------------------------------------
local PELLET_COUNT    = 6    -- number of pellets around the ring
local CONE_ANGLE_DEG_MIN,CONE_ANGLE_DEG_MAX  = 4,8    -- angle from forward to pellets (degrees)
local PROJECTILE_ID   = 4100  -- projectile to spawn
local SPEED           = 300   -- projectile speed
local ShotgunBullet_ID = 4099
---------------------------------------------------

-- Event: shotgun shell (itemid 4102) spawns fixed ring of pellets
ScriptSupportEvent:registerEvent("Missile.Create", function(e)
    if e.itemid == ShotgunBullet_ID then
        -- forward direction from actor facing
        local r, fx, fy, fz = Actor:getFaceDirection(e.helperobjid)
        -- muzzle/world spawn position (your muzzle object)
        local rpos, mx, my, mz = Actor:getPosition(e.toobjid)
        local CONE_ANGLE_DEG = math.random(CONE_ANGLE_DEG_MIN,CONE_ANGLE_DEG_MAX)

        for i = 1, 2 do 
            spawnFixedRing(
                e.helperobjid,   -- sourceId (shooter)
                PROJECTILE_ID,   -- projectile id
                mx, my, mz,      -- muzzle position
                fx, fy, fz,      -- forward direction
                SPEED,           -- speed
                PELLET_COUNT/i,    -- pellet count
                CONE_ANGLE_DEG/i   -- cone angle deg
            )
        end 

        Actor:killSelf(e.toobjid)
    end

    if e.itemid == PROJECTILE_ID then
        threadpool:delay(0.2, function()
            Actor:killSelf(e.toobjid)
        end)
    end
end)
