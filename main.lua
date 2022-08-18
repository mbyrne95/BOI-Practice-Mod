local Mod = RegisterMod("A", 1)

local function onRender(t)
    Isaac.RenderText("test", 50, 30, 1, 1, 1, 255)
end

Mod:AddCallback(ModCallbacks.MC_POST_RENDER, onRender)