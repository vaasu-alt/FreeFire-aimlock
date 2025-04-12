--[[  
  Free Fire MAX - Hybrid Aimlock (Touch + Mouse)  
  Features:  
  - Touchscreen drag-to-lock (Mobile)  
  - Silent Aim (PC)  
  - Auto-adjusts for recoil & bullet speed  
  - Works with `lua-injector`  
--]]  

-- 🔧 CONFIG  
local Aimlock = {  
    -- Core Settings  
    Mode = "Humanized",       -- "Silent", "Humanized", "SoftLock"  
    HitPart = "head",       -- "head", "chest", "pelvis"  
    FOV = 50,                -- Degrees (smaller = stealthier)  
    Prediction = 1.4,        -- Bullet lead multiplier (1.0-2.0)  

    -- Touch Controls (Mobile)  
    TouchActive = true,      -- Enable touch aiming  
    TouchRadius = 80,       -- Activation area (pixels)  
    TouchSmoothness = 0.1,  -- Lower = faster response  

    -- Safety  
    TeamCheck = true,        -- Ignore teammates  
    MaxRange = 120,         -- Meters (FF render limit)  
    NonInit = true          -- Memory protection  
}  

-- 🔗 SHARED WITH LUA-INJECTOR  
local Injector = _G.LuaInjector or error("lua-injector not loaded")  

-- 📱 TOUCH HANDLER (Mobile)  
function OnTouchEvent(x, y, action)  
    -- action: 0 = DOWN, 1 = UP, 2 = MOVE  
    if not Aimlock.TouchActive then return end  

    if action == 0 or action == 2 then  -- Finger down/moving  
        local target = GetTargetAtScreenPos(x, y, Aimlock.TouchRadius)  
        if target and Aimlock.IsValid(target) then  
            SilentAim(target, true)  -- true = isTouchInput  
        end  
    end  
end  

-- 🎯 SILENT AIM LOGIC (PC + Mobile)  
function SilentAim(target, isTouch)  
    local part = target[Aimlock.HitPart]  

    -- 🚀 Prediction (Bullet Drop + Lead)  
    local predictedPos = part.position +  
        (target.velocity * Aimlock.Prediction) +  
        Vector3(0, CalculateBulletDrop(), 0)  

    -- 🖱️ INPUT METHOD HANDLING  
    if isTouch then  
        -- Mobile: Tap near target (stealthier)  
        local screenPos = WorldToScreen(predictedPos)  
        Tap(screenPos.x, screenPos.y, Aimlock.TouchSmoothness)  
    else  
        -- PC: Smooth mouse movement  
        MoveMouseSmooth(predictedPos, Aimlock.FOV)  
    end  

    -- 🔫 Recoil Compensation (Optional)  
    if Aimlock.Mode == "Humanized" then  
        AdjustRecoil(GetCurrentWeapon())  
    end  
end  

-- 🛡️ VALIDATION CHECKS  
function Aimlock.IsValid(target)  
    if not target then return false end  
    if Aimlock.TeamCheck and target.team == GetLocalPlayer().team then return false end  

    -- Range/FOV Checks  
    local inRange = target.distance <= Aimlock.MaxRange  
    local inFOV = IsInFOV(target, Aimlock.FOV)  

    return inRange and inFOV and target.visible  
end  

-- 🔄 MAIN LOOP (PC)  
function OnUpdate()  
    if not Aimlock.TouchActive then  -- Skip if using touch  
        local target = GetBestTarget(Aimlock.FOV)  
        if target then  
            SilentAim(target, false)  
        end  
    end  
    Sleep(Aimlock.NonInit and 20 or 10)  -- Memory-safe delay  
end  

-- 🚀 INITIALIZE  
if Injector.Always_Run_In_App then  
    -- Register events  
    RegisterEvent("TOUCH", OnTouchEvent)  -- Mobile  
    RegisterEvent("UPDATE", OnUpdate)     -- PC  
else  
    error("Requires lua-injector")  
end  
