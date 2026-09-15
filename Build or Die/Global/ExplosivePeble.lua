local function DMG_AREA (centerXYZ,radius,damage,knockback,playerDamageDealer,selfEffect)

    local radius_multiplier = 1.5;
    local airRessist = 12.733;
    local radius = radius * radius_multiplier;

    local function DEALS_DAMAGE_2_AREA(playerID, x, y, z, dx, dy, dz, amount, dtype)
        local r, areaID = Area:createAreaRect({x = x, y = y, z = z}, {x = dx*radius_multiplier, y = dy*radius_multiplier, z = dz*radius_multiplier})

        local function mergeAndRemoveDealer(Dealer,table1, table2)
            local mergedTable = {}
            local index = 1
            if table1 then
                for _, value in ipairs(table1) do
                    if value ~= Dealer then
                        mergedTable[index] = value
                        index = index + 1
                    end 
                end
            end
            if table2 then
                for _, value in ipairs(table2) do
                    if value ~= Dealer then
                        mergedTable[index] = value
                        index = index + 1
                    end 
                end
            end
            return mergedTable
        end

        -- Obtain the Both Affected Object;
        local r1, players = Area:getAreaPlayers(areaID)
        local r2, creatures = Area:getAreaCreatures(areaID)

        -- merge into target;
        local target = mergeAndRemoveDealer(selfEffect == false and playerDamageDealer or 0 ,players,creatures);

        local function CalculateDistance(pos1, pos2)
            local dx = pos2.x - pos1.x
            local dy = pos2.y - pos1.y
            local dz = pos2.z - pos1.z
            return math.sqrt(dx * dx + dy * dy + dz * dz)
        end

        local function CalculateDirBetween2Pos(pos1, pos2)
            local dx = pos2.x - pos1.x
            local dy = pos2.y - pos1.y
            local dz = pos2.z - pos1.z
            local magnitude = math.sqrt(dx * dx + dy * dy + dz * dz)
            return { x = dx / magnitude, y = dy / magnitude, z = dz / magnitude }
        end

        for i, a in ipairs(target) do
            -- calculate the distance between a -- as object within center of x,y,z; 
            local err,ax,ay,az = Actor:getPosition(a)
            if err == 0 then 
                local distance = CalculateDistance({x=x,y=y,z=z},{x=ax,y=ay,z=az});
                if distance <= radius then 
                    local l = (radius - distance)/radius;
                    if a == playerID then
                        -- Smaller the damage for self; 
                        l = l * 0.25;
                    else 
                        -- higher the damage for other;
                        l = l * 2.5;
                    end 
                    Actor:playerHurt(playerID, a, 25 + amount*l, dtype)
                    local dir = CalculateDirBetween2Pos({x=x,y=y,z=z},{x=ax,y=ay,z=az});
                    
                    Actor:appendSpeed(a, dir.x*knockback/airRessist,(dir.y*knockback)/airRessist,dir.z*knockback/airRessist)
                end 
            end
        end

        Area:destroyArea(areaID)
    end 

    -- handle damage
    DEALS_DAMAGE_2_AREA(playerDamageDealer,centerXYZ.x,centerXYZ.y,centerXYZ.z,radius,radius,radius,damage,1,knockback);
end

local radius = 5
local damage = 100
local knockback = 0


ScriptSupportEvent:registerEvent("Actor.Projectile.Hit",function(e)

    local itemid = e.itemid 

    if itemid and itemid == 12051 then 

        local playerid = e.helperobjid;
        local x,y,z = e.x,e.y,e.z 

        DMG_AREA({x=x,y=y,z=z},radius,damage,knockback,playerid)

    end 
end)

-- ScriptSupportEvent:registerEvent("Missile.Create",function(e)

--     if e.itemid and e.itemid == 12051 then 
--         local r, x,y,z = Actor:getPosition(e.toobjid)
--         local playerid = e.eventobjid or e.helperobjid;
--         local r, px,py,pz = Actor:getPosition(playerid)

--         local dx,dy,dz = x-px, y-py, z-pz
--         local len = math.sqrt(dx*dx + dy*dy + dz*dz)
--         local dirx,diry,dirz = dx/len, dy/len, dz/len

--         local cx,cy,cz = px + (dirx * 0.5) , py + 0.9 + (diry*0.5) , pz + (dirz * 0.5) 
--         --Spawn another projectile for precision use invisible projectile with id of 12619
--         local code, objid = World:spawnProjectile(playerid, 12282, cx, cy, cz, x,y,z, 1)

--         local info = Graphics:makeGraphicsLineToActor(e.toobjid, 0.4, 0xff0000, 1)
--         Graphics:createGraphicsLineByActorToActor(objid, info, {x=0,y=0,z=0}, 0)

--         threadpool:wait(0.4);
--         Actor:killSelf(objid);
--     end 

-- end)