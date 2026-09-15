-- ============================================================================
-- MINI WORLD: CREATA - OPTIMIZED SPAWNER & WAVE SYSTEM (V2)
-- ============================================================================

local CONFIG = {
    DEBUG_MODE = false,
    
    -- UI Configuration (UI_ID and Element_IDs)
    UI = {
        ID = "7681266177739004146",
        WAVE_TEXT = "7681266177739004146_7",
        REMAINING_TEXT = "7681266177739004146_8",
    },
    
    -- Map Spawning & Area Settings
    SPAWN_PLACES = {
        Center = { x = -6.5, y = 10, z = -75.5 },
    },
    SPAWN_LIST = { "Center" },
    MAIN_AREA_CENTER = { x = 0, y = 5, z = 0 },
    MAIN_AREA_DIM = { x = 128, y = 10, z = 128 },
    
    -- Wave & Spawner Settings
    WAVE = {
        INTERWAVE_COOLDOWN = 10,
        MAX_ACTIVE_MONSTERS = 30,     
        MAX_HP_SCALING_LEVEL = 15,    
        BUDGET_PER_LEVEL = 60,        
        MAX_COST_BASE = 40,           
        MAX_COST_GROWTH = 15,
        SPAWN_DELAY_FRAMES = 3,       -- NEW: How many frames to wait between single spawns
    },
    
    -- Monster Database
    MONSTERS = {
        { name = "Boarman", id = 3101, cost = 5 },
        { name = "Boarman_Captain_1", id = 3921, cost = 15 },
        { name = "Boarman_Captain_2", id = 3920, cost = 25 },
        { name = "Boarman_Centurion_1", id = 3925, cost = 35 },
        { name = "Boarman_Centurion_2", id = 3924, cost = 45 },
        { name = "Boarman_Void", id = 3929, cost = 10 },
        { name = "Spear_Goblin_Normal", id = 3105, cost = 10 },
        { name = "Pike_Goblin", id = 3922, cost = 52 },
        { name = "Pike_Goblin_Throwing_A", id = 3923, cost = 64 },
        { name = "Pike_Goblin_Throwing_B", id = 3926, cost = 76 },
        { name = "Pike_Goblin_Throwing_C", id = 3927, cost = 86 },
        { name = "Sulfur_Archer", id = 3131, cost = 90 },
        { name = "Jockey_Void", id = 3933, cost = 100 },
        { name = "Chaos_Archer", id = 3132, cost = 110 },
        { name = "Lava_Giant", id = 3130, cost = 120 },
        { name = "Ice_Golem", id = 3915, cost = 300 },
        { name = "Wild_Imp", id = 3508, cost = 30 },
        { name = "Void_Boarman_Centurion", id = 3930, cost = 150 },
        { name = "Throwing_Pike_Boarman", id = 3932, cost = 120 },
        { name = "Throwing_Pike_Boarman_Captain", id = 3931, cost = 130 },
        { name = "Bulli", id = 3112, cost = 100 },
        { name = "Frosti", id = 3111, cost = 100 },
        { name = "Giant_Scorpion", id = 3829, cost = 160 },
        { name = "Lightning_Boarman_Shaman", id = 3875, cost = 120 },
        { name = "Pirate_Raider",id = 3220 , cost = 12},
        { name = "Pirate_Hunter",id = 3221 , cost = 16},
    },
    
    -- Boss Database
    BOSSES = {
        { name = "Tensei", id = 14, cost = 900 },
        { name = "FrostMage", id = 13, cost = 1000 },
        { name = "IronGolemGigaChad", id = 7, cost = 1200 },
    },
    
    -- Skins & Appearance Settings
    ENABLE_MOD_APPEARANCE = true,
    EXCLUDE_CREATURES = {3098},
    INVINCIBLE_CREATURES = {3098},
    SKINS = {
        "skin_1", "skin_2", "skin_3", "skin_4", "skin_5", "skin_6", "skin_7", "skin_8", "skin_9",
        "skin_11", "skin_14", "skin_17", "skin_15", "skin_29", "skin_39", "skin_40", "skin_41",
        "skin_44", "skin_49", "skin_244", "skin_18", "skin_19", "skin_20", "skin_21", "skin_22",
        "skin_23", "skin_24", "skin_25", "skin_63", "skin_58", "skin_64", "skin_65", "skin_74",
        "skin_75", "skin_76", "skin_79", "skin_83", "skin_84", "skin_85", "skin_90", "skin_91",
        "skin_92", "skin_93", "skin_95", "skin_96", "skin_98", "skin_99", "skin_100", "skin_101",
        "skin_102", "skin_103", "skin_104", "skin_106", "skin_107", "skin_114", "skin_121",
        "skin_136", "skin_140", "skin_141", "skin_151", "skin_148", "skin_174", "skin_178",
        "skin_190", "skin_192", "skin_197", "skin_196", "skin_198", "skin_199", "skin_200",
        "skin_208", "skin_209", "skin_210", "skin_211", "skin_212", "skin_215", "skin_226",
        "skin_227", "skin_229", "skin_246", "skin_255", "skin_256", "skin_278", "skin_281",
        "skin_285", "skin_282", "skin_283", "skin_293", "skin_302", "skin_322", "skin_326",
        "skin_328", "skin_329", "skin_330", "skin_332", "skin_331", "skin_340", "skin_341",
        "skin_344", "skin_346", "skin_353", "skin_355", "skin_361", "skin_362", "skin_363",
        "skin_364", "skin_365", "skin_366", "skin_367", "skin_368", "skin_372", "skin_373",
        "skin_378", "skin_396",
    }
}

-- Global environment exports (retained for external C-Engine calls)
M = CONFIG.MONSTERS
Boss = CONFIG.BOSSES

-- State Tracking
local state = {
    currentLevel = 0,
    activeCreatures = {},
    spawnQueue = {},      -- New queue system for large waves
    levels = {},
    lastCost = 0,
    counter = 0,
    lastMoveTime = {}
}

local _, main_area = Area:createAreaRect(CONFIG.MAIN_AREA_CENTER, CONFIG.MAIN_AREA_DIM)

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function logDebug(msg)
    if CONFIG.DEBUG_MODE then
        print("System [Spawner Config]: " .. tostring(msg))
    end
end

local function isValueInArray(array, value)
    for i = 1, #array do
        if array[i] == value then return true end
    end
    return false
end

local function safeTranslate(playerObj, text)
    if type(T_Text) == "function" then return T_Text(playerObj, text) end
    return text
end

-- Smarter Random Monster Function
local function getRandomMonster(costBudget, currentLevel)
    local candidates = {}
    -- Capping allowed cost early game (Level 1 allows max 55 cost. Level 10 allows 190, etc)
    local maxAllowedCost = CONFIG.WAVE.MAX_COST_BASE + (currentLevel * CONFIG.WAVE.MAX_COST_GROWTH)

    for i = 1, #CONFIG.MONSTERS do
        local m = CONFIG.MONSTERS[i]
        if m.cost <= costBudget and m.cost <= maxAllowedCost then
            table.insert(candidates, m)
        end
    end

    -- Fallback: return cheapest if budget is extremely low
    if #candidates == 0 then
        local cheapest = CONFIG.MONSTERS[1]
        for i = 2, #CONFIG.MONSTERS do
            if CONFIG.MONSTERS[i].cost < cheapest.cost then cheapest = CONFIG.MONSTERS[i] end
        end
        return cheapest
    end

    -- Sort candidates descending by cost (Highest cost first)
    table.sort(candidates, function(a, b) return a.cost > b.cost end)

    local index = 1
    if currentLevel >= 5 then
        -- Late game: 75% chance to force spawn one of the top 3 most expensive monsters available
        if math.random(1, 100) <= 75 then
            index = math.random(1, math.min(3, #candidates))
        else
            index = math.random(1, #candidates)
        end
    else
        -- Early game: Uniform random selection among allowed candidates
        index = math.random(1, #candidates)
    end

    return candidates[index]
end

local function setBossLevel(waveNum)
    local index = 1 + (math.floor(waveNum / 10) - 1) % #CONFIG.BOSSES
    return { CONFIG.BOSSES[index].id }
end

local function generateLevels(startLvl, endLvl)
    for i = startLvl, endLvl do
        logDebug("Initiating Level " .. i)
        if math.fmod(i, 10) == 0 then
            state.levels[i] = setBossLevel(i)
            logDebug("Boss Level Set")
        else
            -- Increased budget to allow for much larger queues of enemies over time
            local costBudget = state.lastCost + (i * CONFIG.WAVE.BUDGET_PER_LEVEL)
            local levelMonsters = {}
            local failsafe = 150 -- Absolute maximum monsters per level so it doesn't crash memory

            while costBudget >= 20 and failsafe > 0 do
                local monster = getRandomMonster(costBudget, i)
                if costBudget >= monster.cost then
                    costBudget = costBudget - monster.cost
                    table.insert(levelMonsters, monster.id)
                else
                    break
                end
                failsafe = failsafe - 1
            end

            state.levels[i] = levelMonsters
            state.lastCost = costBudget
            logDebug("Level " .. i .. " initialized with " .. #levelMonsters .. " monsters.")
        end
    end
end

-- ============================================================================
-- MONSTER & AI SETUP
-- ============================================================================

local function setupMonster(monsterId, level)
    Creature:setTeam(monsterId, 2)
    local r, maxHP = Creature:getAttr(monsterId, 1)
    if r == 0 and maxHP then
        -- Cap HP scaling so players eventually feel overpowered
        local hpMultiplier = math.min(level, CONFIG.WAVE.MAX_HP_SCALING_LEVEL)
        local hpValue = (maxHP / 5) * hpMultiplier
        Creature:setAttr(monsterId, 1, hpValue)
        Creature:setAttr(monsterId, 2, hpValue)
    end
end

local function navigateCreatureToPlayer(creatureId, targetPlayer)
    local now = os.time()
    state.lastMoveTime[creatureId] = state.lastMoveTime[creatureId] or 0

    if now - state.lastMoveTime[creatureId] >= 2 then
        local r, x, y, z = Actor:getPosition(targetPlayer)
        if r == 0 then
            if Actor:tryNavigationToPos(creatureId, x, y, z, true, true) == 0 then
                state.lastMoveTime[creatureId] = now
            end
        end
    end
end

local function updateActiveCreatures(playerList)
    if #playerList == 0 then return end
    for i = #state.activeCreatures, 1, -1 do
        local cid = state.activeCreatures[i]
        local r, hp = Creature:getAttr(cid, 2)

        if r ~= 0 or hp == nil or hp <= 0 then
            state.lastMoveTime[cid] = nil
            table.remove(state.activeCreatures, i)
        else
            local result,value = VarLib2:getGlobalVarByName(6,"TargetPlayer")
            if result == 0 and value then 
                navigateCreatureToPlayer(cid, value);
            end
        end
    end
end

-- ============================================================================
-- SPAWNER & WAVE LOGIC
-- ============================================================================

local function LoadNextLevelQueue()
    if not state.levels[state.currentLevel + 1] then
        generateLevels(state.currentLevel + 1, state.currentLevel + 10)
    end

    state.currentLevel = state.currentLevel + 1
    local currentWaveMonsters = state.levels[state.currentLevel]
    
    -- Load the monsters into the queue
    state.spawnQueue = {}
    for _, monsterId in ipairs(currentWaveMonsters) do
        table.insert(state.spawnQueue, monsterId)
    end
end

local function ProcessSpawnQueue(maxPerFrame)
    local spaceAvailable = CONFIG.WAVE.MAX_ACTIVE_MONSTERS - #state.activeCreatures
    
    -- Only process if space is available and queue is not empty
    if spaceAvailable > 0 and #state.spawnQueue > 0 then
        local numToSpawn = math.min(spaceAvailable, maxPerFrame, #state.spawnQueue)
        
        for _ = 1, numToSpawn do
            local monsterId = table.remove(state.spawnQueue) 
            local placeName = CONFIG.SPAWN_LIST[math.random(1, #CONFIG.SPAWN_LIST)]
            local spawnPos = CONFIG.SPAWN_PLACES[placeName]

            local r, mlist = World:spawnCreature(spawnPos.x, spawnPos.y, spawnPos.z, monsterId, 1)
            
            if r == 0 and mlist and #mlist > 0 then
                local spawnedMonster = mlist[1]
                Creature:setAIActive(spawnedMonster, false);
                Actor:setActionAttrState(spawnedMonster,512,false)
                setupMonster(spawnedMonster, state.currentLevel)
                table.insert(state.activeCreatures, spawnedMonster)
            end
        end
    end
end

-- ============================================================================
-- UI MANAGEMENT
-- ============================================================================

local function updatePlayersUI(statusText, waveText)
    local r, n, players = World:getAllPlayers(1)
    if r == 0 and n > 0 then
        for _, playerId in ipairs(players) do
            if waveText then
                Customui:setText(playerId, CONFIG.UI.ID, CONFIG.UI.WAVE_TEXT, waveText)
            end
            Customui:setText(playerId, CONFIG.UI.ID, CONFIG.UI.REMAINING_TEXT, safeTranslate(playerId, statusText))
            Player:openUIView(playerId, CONFIG.UI.ID)
        end
    end
end

-- ============================================================================
-- EVENT LISTENERS
-- ============================================================================

ScriptSupportEvent:registerEvent("Actor.Create", function(e)
    if not CONFIG.ENABLE_MOD_APPEARANCE then return end

    local actorId = e.eventobjid
    local r, creatureId = Creature:getActorID(actorId)
    if r ~= 0 then return end

    if not isValueInArray(CONFIG.EXCLUDE_CREATURES, creatureId) then
        local skinIndex = ((state.currentLevel - 1) % #CONFIG.SKINS) + 1
        Actor:changeCustomModel(actorId, CONFIG.SKINS[skinIndex])
    end

    if isValueInArray(CONFIG.INVINCIBLE_CREATURES, creatureId) then
        Actor:setActionAttrState(actorId, 1, false)
        Actor:setActionAttrState(actorId, 8, false)
        Actor:setActionAttrState(actorId, 64, false)
        Actor:setActionAttrState(actorId, 128, false)
    end
end)

local frameTick = 0

ScriptSupportEvent:registerEvent("Game.RunTime", function(e)
    -- ==========================================
    -- TICK/FRAME LOGIC (Runs very fast)
    -- ==========================================
    frameTick = frameTick + 1
    if frameTick >= CONFIG.WAVE.SPAWN_DELAY_FRAMES then
        -- Spawn exactly 1 monster per delay interval to completely prevent lag
        ProcessSpawnQueue(1)
        frameTick = 0
    end

    -- ==========================================
    -- SECOND LOGIC (Runs once per second)
    -- ==========================================
    if e.second == nil then return end

    local r, playerList = Area:getAreaPlayers(main_area)

    if r == 0 and #playerList > 0 then
        -- Check if both arena is clear AND the queue is empty
        if #state.activeCreatures == 0 and #state.spawnQueue == 0 then
            if state.counter <= 0 then
                LoadNextLevelQueue()
                state.counter = CONFIG.WAVE.INTERWAVE_COOLDOWN
            else
                updatePlayersUI("Next Wave in " .. state.counter, "Wave " .. state.currentLevel)
                state.counter = state.counter - 1
            end
        else
            -- Process heavy navigation AI and update UI
            updateActiveCreatures(playerList)
            
            local totalRemaining = #state.activeCreatures + #state.spawnQueue
            updatePlayersUI("Enemies Remaining : " .. totalRemaining, "Wave " .. state.currentLevel)
        end
    else
        updatePlayersUI("Waiting For Players Join Arena")
    end
end)

-- Initialize first batch of levels
generateLevels(1, 20)

ScriptSupportEvent:registerEvent("Actor.ChangeMotion",function(e)
    print("Motion Change Event",e)
end)