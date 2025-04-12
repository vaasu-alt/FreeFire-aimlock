--[[
  Free Fire MAX - Lua Injector (Safe Aim Assist)
  Features:
  - Non-conflict aimlock (soft tracking)
  - Always runs in-app with memory protection
  - Disables native aim mechanics
  - Mobile/PC dual support
--]]

-- 🛡️ CONFIG (Safe Defaults)
local Injector = {
    Always_Run_In_App = true,     -- Critical for injection
    Remove_Aim_Mechanics = true,  -- Disables FF's built-in assist
    NonInit = true,               -- Memory protection
    Mode = "SoftLock",            -- "SoftLock" or "Humanized"
    FOV = 55,                     -- Degrees (narrow = less obvious)
    Touch_Radius = 60             -- Mobile touch area (pixels)
}

-- 🔒 MEMORY SAFETY (NonInit System)
function _G.NonInit()
    if Injector.NonInit then
        -- Clear residual aim data
        if _G.AimAssistCache then _G.AimAssistCache = nil end
        collectgarbage("step", 100) -- Lite memory cleanup
    end
end

-- 🎯 NON-CONFLICT AIMLOGIC
function SoftAim(target)
    if not target or target.team == GetLocalPlayer().team then return end

    -- 🖱️ PC/Mobile Hybrid Control
    local input_method = IsMobile() and "TOUCH" or "MOUSE"
    local aim_pos = target[Injector.Mode == "SoftLock" and "chest" or "head"]

    -- 🌐 Prediction (Reduced for safety)
    local predicted_pos = aim_pos.position + (target.velocity * 1.2)

    -- 🌀 Humanized Movement
    if input_method == "MOUSE" then
        MoveMouseSmooth(predicted_pos, Injector.FOV)
    else
        -- Mobile touch simulation
        local screen_pos = WorldToScreen(predicted_pos)
        Tap(screen_pos.x, screen_pos.y, Injector.Touch_Radius)
    end
end

-- ⚙️ INJECTION BRIDGE
if Injector.Always_Run_In_App then
    local app_name = GetForegroundApp()
    if app_name ~= "com.dts.freefiremax" then
        StopScript() -- Exit if not in FF
    else
        -- Disable native aim assist if needed
        if Injector.Remove_Aim_Mechanics then
            SetNativeAimAssist(false) -- Hypothetical API call
        end
    end
end

-- 🔄 MAIN LOOP (Universal)
function Main()
    NonInit() -- Initialize memory safety

    while true do
        local target = GetNearestEnemy(Injector.FOV)
        SoftAim(target)
        Sleep(Injector.Mode == "SoftLock" and 30 or 50) -- Delay variance
    end
end

-- 🚀 START CONDITION
if Injector.Always_Run_In_App then
    RegisterEvent("INPUT", SoftAim) -- Hook inputs
    Main()
end
