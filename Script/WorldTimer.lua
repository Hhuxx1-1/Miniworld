MYWORLD = {};
MYWORLD.Second = 0;
MYWORLD.DAY = 0;
MYWORLD.BUFF_TORCH = 50000000;
MYWORLD.LIGHT_RENDER_LEN = 4 ; 
MYWORLD.IsStarted=false;
local function SpeedUpTimeWorld(speed) 
    local code  = World:SetTimeVanishingSpeed(speed);
end 
MYWORLD.Increment = 1;

MYWORLD.CUR_ACTION = {} ;

MYWORLD.SET_DAY = function(WorldTime)
    if(WorldTime==nil)then 
        World:setHours(1);
    end 
    World:SetTimeVanishingSpeed(60);
    MYWORLD.CUR_ACTION = "SET_DAY";
end

MYWORLD.SET_NIGHT = function(WorldTime)
    if(WorldTime == nil)then 
        World:setHours(10);
    end 
    World:SetTimeVanishingSpeed(120);
    MYWORLD.CUR_ACTION = "SET_NIGHT";
end

MYWORLD.SET_PAUSE = function()
    MYWORLD.CUR_ACTION = "SET_READY";
    World:SetTimeVanishingSpeed(0);
end

MYWORLD.Duration_Of_Day = 400; --[[ 6.6 Minutes]]

MYWORLD.Get_Seconds_Today = function()
    return math.fmod(MYWORLD.Second,MYWORLD.Duration_Of_Day);
end

MYWORLD.GET_LIGHT_BY_POS = function(x,y,z)
    local r , light = World:getLightByPos(x,y,z);
    if r == 0 then return light end ;
end

MYWORLD.TIME_TO_SET_DAY = 280 ;
MYWORLD.TIME_TO_SET_NIGHT = 2 ;

MYWORLD.Check_Event = function(seconds_today)

    if (seconds_today == MYWORLD.TIME_TO_SET_DAY) then
        MYWORLD.SET_DAY();
        --Chat:sendSystemMsg("Day Setting Day")
    end 
    
    if (seconds_today == MYWORLD.TIME_TO_SET_DAY+9) then
        MYWORLD.SET_PAUSE();
        --Chat:sendSystemMsg("Day Paused")
    end 

    if (seconds_today == MYWORLD.TIME_TO_SET_NIGHT) then
        MYWORLD.SET_NIGHT();
        --Chat:sendSystemMsg("Day Setting Night")
    end

    if (seconds_today == MYWORLD.TIME_TO_SET_NIGHT+6) then
        MYWORLD.SET_PAUSE();
        --Chat:sendSystemMsg("Day Paused")
        World:setHours(0);
    end
    
end

MYWORLD.GET_ALL_PLAYER = function()
    local result,num,array=World:getAllPlayers(-1)
    if result == 0 then return num,array end 
end

MYWORLD.CHECK_PLAYER_TORC = function (playerid)
    local r = Actor:hasBuff(playerid,MYWORLD.BUFF_TORCH);
    if(r==0)then         --[[Chat:sendSystemMsg("Player is Light On "..r)]]    return true else return false    end 
end

MYWORLD.LIGHT_CONTAINER = {};

MYWORLD.LIGHT_CONTAINER_INIT = function(playerid)
    MYWORLD.LIGHT_CONTAINER[playerid] = {};
end

MYWORLD.REGISTER_LIGHT = function(playerid,table,i)
    if(MYWORLD.LIGHT_CONTAINER[playerid]==nil)then MYWORLD.LIGHT_CONTAINER_INIT(playerid) end 
    if(MYWORLD.LIGHT_CONTAINER[playerid][i]==nil)then 
        MYWORLD.LIGHT_CONTAINER[playerid][i] = {};
    end 
    MYWORLD.LIGHT_CONTAINER[playerid][i]=table;
end

MYWORLD.RENDER_LIGHT = function(playerid)
    -- iluminate the light in player direction
    -- Chat:sendSystemMsg("Illumanting for player :"..playerid)
    -- Store the Light into Light Container 
    local bias = 2;
    local xp ,yp ,zp = MYTOOL.GET_POS(playerid);
    local xd ,yd ,zd = MYTOOL.getDir(playerid);
    for i=1,MYWORLD.LIGHT_RENDER_LEN do 
        local cx,cy,cz = xp+(xd*(i*bias)),   yp+(yd*i)+1.5, zp + (zd*(i*bias));
    -- store the calulcated coordinate 
        local light = {x=cx,y=cy,z=cz};
        MYWORLD.REGISTER_LIGHT(playerid,light,tonumber(i));
    end 
end

local temporaryData_light = {};

local function SetLightLevel(lightLevel,tableXYZ,pos,playerid)
    --print("pos",pos);
    --print("tableXYZ" , tableXYZ)
    local x,y,z = tableXYZ.x,tableXYZ.y,tableXYZ.z;
    if(temporaryData_light[playerid]==nil)then 
        temporaryData_light[playerid] = {} ;
        temporaryData_light[playerid][pos] = {x=x,y=y,z=z};
    else

        if(temporaryData_light[playerid][pos] == nil )then  temporaryData_light[playerid][pos] = {x=x,y=y,z=z}; end 

        local xx,yy,zz = temporaryData_light[playerid][pos].x , temporaryData_light[playerid][pos].y , temporaryData_light[playerid][pos].z
        -- compare the data is same data on the pos data return false 
        if x==xx and y==yy and z==zz then 
            --Chat:sendSystemMsg("Light Didn't Moved")
            return false ;
        else 
            local code = World:setBlockLightEx(xx, yy, zz, 0) ;
            --print(" Unset Success ");
        end 
    end 
    --Chat:sendSystemMsg("Executing Light Feature")
    local code = World:setBlockLightEx(x, y, z, lightLevel)
    -- set temporary data light 
    temporaryData_light[playerid][pos] = {x=x,y=y,z=z};
    return true ;
end 

MYWORLD.DO_RENDER_LIGHT = function()
    --print(MYWORLD.LIGHT_CONTAINER);
    if MYWORLD.LIGHT_CONTAINER ~= {} then 
        --print("Length = ", #MYWORLD.LIGHT_CONTAINER); 0 
        for playerid,light in pairs(MYWORLD.LIGHT_CONTAINER) do
            for i, v in pairs(light) do
                --Chat:sendSystemMsg(" i = "..i);
                local s,error = pcall(SetLightLevel,10-i,v,tonumber(i),tonumber(playerid));
                if not s then 
                    print("Error [Do Render Light] : ",error);
                end 
            end
        end 
    end 
end

ScriptSupportEvent:registerEvent("Game.RunTime",function(e)

    local n , players = MYWORLD.GET_ALL_PLAYER();
    if n > 0 then 
        for i , playerid in ipairs (players) do 
        local x,y,z = MYTOOL.GET_POS(playerid);    
        local lightLevel = MYWORLD.GET_LIGHT_BY_POS(x,y,z);
       
        --Chat:sendSystemMsg(" Player : "..playerid.." Light Level is : "..lightLevel);
        if(lightLevel<=5)then 
            --Chat:sendSystemMsg("Now is Dark")
        end 
        if(MYWORLD.CHECK_PLAYER_TORC(playerid))then 
            MYWORLD.RENDER_LIGHT(playerid);
        else
            if(MYWORLD.LIGHT_CONTAINER[playerid]==nil)then MYWORLD.LIGHT_CONTAINER_INIT(playerid) end 
            if(temporaryData_light[playerid]~=nil)then 
                for pos , a in pairs(temporaryData_light[playerid]) do 
                    if(temporaryData_light[playerid][pos] == nil )then  break end 
                    local xx,yy,zz = a.x , a.y , a.z
                    local code = World:setBlockLightEx(xx, yy, zz, 0)   
                end 
                temporaryData_light[playerid]=nil;
            end 
            MYWORLD.LIGHT_CONTAINER[playerid] = {};
        end 
        end 
    end 
    
    if e.second ~=nil then 
        if(MYWORLD.IsStarted)then 
        MYWORLD.Second = MYWORLD.Second + MYWORLD.Increment;
        -- Chat:sendSystemMsg("World Timelapse : "..MYWORLD.Second);
        local result,time=World:getHours()
        --Chat:sendSystemMsg("Time Today : "..MYWORLD.Get_Seconds_Today().." Hours  : "..time);
        MYWORLD.Check_Event(MYWORLD.Get_Seconds_Today());
        end 
    end 
   
    MYWORLD.DO_RENDER_LIGHT();

end)