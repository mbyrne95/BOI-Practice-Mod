local Mod = RegisterMod("A", 1)
local GameState = {}
local json = require("json")

local localDmgCnt
local localRunCnt

-- loading mod data
function Mod:onStart()
    GameState = json.decode(Mod:LoadData())
    if GameState.DamageCount == nil then GameState.DamageCount = 0 end
    if GameState.RunCount == nil then GameState.RunCount = 1 end
    localDmgCnt = GameState.DamageCount
    localRunCnt = GameState.RunCount

end

Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Mod.onStart)

-- saving mod data
function Mod:onExit(save)
    GameState.DamageCount = localDmgCnt
    GameState.RunCount = localRunCnt
    Mod:SaveData(json.encode(GameState))
end

Mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, Mod.onExit)
Mod:AddCallback(ModCallbacks.MC_POST_GAME_END, Mod.onExit)

local dmg = 0
local curseUnknown = false
local game = Game()
local textCoords = {65, 30}
local player = Isaac.GetPlayer(0)

-- dmg counter
function Mod:damageCounter(target, amount, flags, source, num)
    if target.Type == EntityType.ENTITY_PLAYER then
        dmg = dmg + amount
        localDmgCnt = localDmgCnt + amount
    end
end

-- reset counter on new run
function Mod:newRunEval(shouldSave)
    if shouldSave == false then
        dmg = 0
        localRunCnt = localRunCnt + 1
    end
end

-- write to screen, simplify to an int and fraction
local function onRender(t)

    local f = Font()

    local scaleAmountX = 0.7
    local scaleAmountY = 0.7
    local textColor = KColor(1,1,1,0.5)

    f:Load("font/pftempestasevencondensed.fnt")

    local avgDmgDisplay

    if (localDmgCnt == nil or localDmgCnt == 0 or localRunCnt == nil or localRunCnt == 0) then
        avgDmgDisplay = "TBD"
    else 
        avgDmgDisplay = (localDmgCnt/2)/localRunCnt
        avgDmgDisplay = math.floor(avgDmgDisplay*100)/100
    end

    local printDMG = math.floor(dmg/2)

    -- if unknown is active, don't display damage (player can cheat w/ this mod)
    if curseUnknown == true then
        f:DrawStringScaled("DMG: ??? | AVG: " .. tostring(avgDmgDisplay), textCoords[1], textCoords[2], scaleAmountX, scaleAmountY, textColor)
        --Isaac.RenderText("DMG: ???", 65, 30, 1, 1, 1, 0.5)
    else
        if (dmg % 2 > 0) then
            f:DrawStringScaled("DMG: " .. tostring(printDMG) .. "\189" .. " | AVG: " .. tostring(avgDmgDisplay), textCoords[1], textCoords[2], scaleAmountX, scaleAmountY, textColor)
            --Isaac.RenderText("DMG: " .. tostring(printDMG) .. "\189", 65, 30, 1, 1, 1, 0.5)
        else
            f:DrawStringScaled("DMG: " .. tostring(printDMG) .. " | AVG: " .. tostring(avgDmgDisplay), textCoords[1], textCoords[2], scaleAmountX, scaleAmountY, textColor)
            --Isaac.RenderText("DMG: " .. tostring(printDMG), 65, 30, 1, 1, 1, 0.5)
        end
    end
end

-- check to see if curse of unknown is active
local function curseEval()
    local level = Game():GetLevel()
    local curseStatus = level:GetCurses()
    if curseStatus == LevelCurse.CURSE_OF_THE_UNKNOWN then
        curseUnknown = true
    else
        curseUnknown = false
    end
end

-- check player current health, modify text coords
local function healthEval()
    local health = player:GetEffectiveMaxHearts() + player:GetSoulHearts()

    if health > 12 then
        textCoords[2] = 40
    else
        textCoords[2] = 30
    end
end



Mod:AddCallback(ModCallbacks.MC_POST_RENDER, onRender)
Mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Mod.damageCounter)
Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Mod.newRunEval)
Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, curseEval)
Mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, healthEval)