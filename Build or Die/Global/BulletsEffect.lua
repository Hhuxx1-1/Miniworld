local ACTIVE_RAYS = 0

ScriptSupportEvent:registerEvent("Missile.Create", function(e)

    -- if too many rays already, skip creating new effect
    if ACTIVE_RAYS >= 60 then
        return
    end

    if e.itemid and (e.itemid == 4097 or e.itemid == 4100) then
        ACTIVE_RAYS = ACTIVE_RAYS + 1  -- count ray

        local r, x,y,z = Actor:getPosition(e.toobjid)
        if r ~= 0 then return end 
        local playerid = e.eventobjid or e.helperobjid
        local r, px,py,pz = Actor:getPosition(playerid)

        local dx,dy,dz = x-px, y-py, z-pz
        local len = math.sqrt(dx*dx + dy*dy + dz*dz)
        local dirx,diry,dirz = dx/len, dy/len, dz/len

        local cx = px + dirx * 0.5
        local cy = py + 0.9 + diry * 0.5
        local cz = pz + dirz * 0.5

        local code, objid = World:spawnProjectile(playerid, 4098, cx, cy, cz, x,y,z, 1)
        Actor:setActionAttrState(objid,1,false)
        local info = Graphics:makeGraphicsLineToActor(e.toobjid, 0.15, 0xFFD700, 1)
        Graphics:createGraphicsLineByActorToActor(objid, info, {x=0,y=0,z=0}, 0)

        -- destroy visual after delay
        threadpool:wait(0.2)
        Actor:killSelf(objid)
    end
end)

ScriptSupportEvent:registerEvent("Game.RunTime",function(e) 
    if e.second then 
        ACTIVE_RAYS = 0
    end 
end)