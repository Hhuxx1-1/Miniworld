MYWORLD = {};
MYWORLD.Second = 0;
MYWORLD.DAY = 0;
MYWORLD.BUFF_TORCH = 50000000;
MYWORLD.LIGHT_RENDER_LEN = 4 ; 
MYWORLD.IsStarted=false;
MYWORLD.Increment = 1;
MYWORLD.GET_LIGHT_BY_POS = function(x,y,z)
    local r , light = World:getLightByPos(x,y,z);
    if r == 0 then return light end ;
end
MYWORLD.GET_ALL_PLAYER = function()
    local result,num,array=World:getAllPlayers(-1)
    if result == 0 then return num,array end 
end;
MYWORLD.CHECK_PLAYER_TORC = function (playerid)
    local r = Actor:hasBuff(playerid,MYWORLD.BUFF_TORCH);
    if(r==0)then  return true else return false    end 
end;
MYWORLD.LIGHT_CONTAINER = {}; MYWORLD.LIGHT_CONTAINER_INIT = function(playerid)
    MYWORLD.LIGHT_CONTAINER[playerid] = {}; end
MYWORLD.REGISTER_LIGHT = function(playerid,table,i)
    if(MYWORLD.LIGHT_CONTAINER[playerid]==nil)then MYWORLD.LIGHT_CONTAINER_INIT(playerid) end 
    if(MYWORLD.LIGHT_CONTAINER[playerid][i]==nil)then 
        MYWORLD.LIGHT_CONTAINER[playerid][i] = {};
    end 
    MYWORLD.LIGHT_CONTAINER[playerid][i]=table;
end;
MYWORLD.RENDER_LIGHT = function(playerid)
    local bias = 2;
    local xp ,yp ,zp = MYTOOL.GET_POS(playerid);
    local xd ,yd ,zd = MYTOOL.getDir(playerid);
    for i=1,MYWORLD.LIGHT_RENDER_LEN do 
        local cx,cy,cz = xp+(xd*(i*bias)),   yp+(yd*i)+1.5, zp + (zd*(i*bias));
        local light = {x=cx,y=cy,z=cz};
        MYWORLD.REGISTER_LIGHT(playerid,light,tonumber(i));
    end 
end
local temporaryData_light = {};
local function SetLightLevel(lightLevel,tableXYZ,pos,playerid)
    local x,y,z = tableXYZ.x,tableXYZ.y,tableXYZ.z;
    if(temporaryData_light[playerid]==nil)then 
        temporaryData_light[playerid] = {} ; temporaryData_light[playerid][pos] = {x=x,y=y,z=z};
    else
        if(temporaryData_light[playerid][pos] == nil )then  temporaryData_light[playerid][pos] = {x=x,y=y,z=z}; end 
        local xx,yy,zz = temporaryData_light[playerid][pos].x , temporaryData_light[playerid][pos].y , temporaryData_light[playerid][pos].z
        if x==xx and y==yy and z==zz then return true;
        else local code = World:setBlockLightEx(xx, yy, zz, 0) ; end 
    end local code = World:setBlockLightEx(x, y, z, lightLevel);    temporaryData_light[playerid][pos] = {x=x,y=y,z=z};
    return true ;
end 
MYWORLD.DO_RENDER_LIGHT = function()
    --print(MYWORLD.LIGHT_CONTAINER);
    if MYWORLD.LIGHT_CONTAINER ~= {} then 
        --print("Length = ", #MYWORLD.LIGHT_CONTAINER); 0 
        for playerid,light in pairs(MYWORLD.LIGHT_CONTAINER) do
            for i, v in pairs(light) do
                --Chat:sendSystemMsg(" i = "..i);
                local s,error = pcall(SetLightLevel,10-(i/2),v,tonumber(i),tonumber(playerid));
                if not s then  print("Error [Do Render Light] : ",error);  end 
            end
        end 
    end 
end
ScriptSupportEvent:registerEvent("Game.RunTime",function(e)
    local n , players = MYWORLD.GET_ALL_PLAYER();
    if n > 0 then 
        for i , playerid in ipairs (players) do 
        if(MYWORLD.CHECK_PLAYER_TORC(playerid))then 
            MYWORLD.RENDER_LIGHT(playerid);
        else
            if(MYWORLD.LIGHT_CONTAINER[playerid]==nil)then MYWORLD.LIGHT_CONTAINER_INIT(playerid) end 
            if(temporaryData_light[playerid]~=nil)then 
                for pos , a in pairs(temporaryData_light[playerid]) do 
                    if(temporaryData_light[playerid][pos] == nil )then break end 
                    local code = World:setBlockLightEx(a.x , a.y , a.z, 0)   
                end 
                temporaryData_light[playerid]=nil;
            end 
            MYWORLD.LIGHT_CONTAINER[playerid] = {};
        end 
        end 
    end 
    MYWORLD.DO_RENDER_LIGHT();
end)