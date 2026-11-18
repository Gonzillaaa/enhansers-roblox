--[[
    anticheat_tester.lua
    Red-team script for testing the anti-cheat of YOUR OWN Roblox game.

    It simulates the most common client-side cheat behaviours so you can
    check that your server-side detection flags / kicks / rolls back each one.

    SETUP: set ALLOWED_PLACE_IDS below to your game's PlaceId(s). The script
    refuses to run anywhere else, so it can't be used against other games.

    Keybinds:
        F1  speed hack      (WalkSpeed -> SPEED_VALUE)
        F2  jump hack       (JumpPower/JumpHeight boost)
        F3  teleport        (instant move TELEPORT_STUDS forward)
        F4  fly             (BodyVelocity-based flight, WASD + Space/Ctrl)
        F5  noclip          (CanCollide off on the character)
        F6  infinite jump
        F7  restore everything / stop all tests

    Each test prints what it did, so compare against your server logs:
    a good anti-cheat should detect every one of these within a few seconds.
]]

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
local ALLOWED_PLACE_IDS = {
    -- 0, -- <-- put your game's PlaceId here, e.g. 1234567890
}

local SPEED_VALUE     = 100   -- default is 16
local JUMP_POWER      = 150   -- default is 50
local JUMP_HEIGHT     = 30    -- default is 7.2 (used when UseJumpPower is false)
local TELEPORT_STUDS  = 200
local FLY_SPEED       = 80

----------------------------------------------------------------------
-- SAFETY GATE
----------------------------------------------------------------------
local function placeAllowed()
    for _, id in ipairs(ALLOWED_PLACE_IDS) do
        if id ~= 0 and id == game.PlaceId then
            return true
        end
    end
    return false
end

if not placeAllowed() then
    warn(("[ACTester] PlaceId %d is not in ALLOWED_PLACE_IDS. Edit the script and add your game's PlaceId. Aborting."):format(game.PlaceId))
    return
end

----------------------------------------------------------------------
-- SERVICES / STATE
----------------------------------------------------------------------
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local player = Players.LocalPlayer

local state = {
    speed = false,
    jump = false,
    fly = false,
    noclip = false,
    infJump = false,
}

local connections = {}
local flyBV, flyBG

local function log(msg)
    print("[ACTester] " .. msg)
end

local function getChar()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root then
        return char, hum, root
    end
end

local defaults = {}

local function saveDefaults(hum)
    if next(defaults) == nil then
        defaults.WalkSpeed = hum.WalkSpeed
        defaults.JumpPower = hum.JumpPower
        defaults.JumpHeight = hum.JumpHeight
    end
end

----------------------------------------------------------------------
-- TESTS
----------------------------------------------------------------------
local function toggleSpeed()
    local _, hum = getChar()
    if not hum then return end
    saveDefaults(hum)
    state.speed = not state.speed
    hum.WalkSpeed = state.speed and SPEED_VALUE or defaults.WalkSpeed
    log(("Speed hack %s (WalkSpeed=%s)"):format(state.speed and "ON" or "OFF", hum.WalkSpeed))
end

local function toggleJump()
    local _, hum = getChar()
    if not hum then return end
    saveDefaults(hum)
    state.jump = not state.jump
    if hum.UseJumpPower then
        hum.JumpPower = state.jump and JUMP_POWER or defaults.JumpPower
    else
        hum.JumpHeight = state.jump and JUMP_HEIGHT or defaults.JumpHeight
    end
    log("Jump hack " .. (state.jump and "ON" or "OFF"))
end

local function teleportForward()
    local _, _, root = getChar()
    if not root then return end
    root.CFrame = root.CFrame + root.CFrame.LookVector * TELEPORT_STUDS
    log(("Teleported %d studs forward"):format(TELEPORT_STUDS))
end

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    if connections.fly then connections.fly:Disconnect() connections.fly = nil end
    local _, hum = getChar()
    if hum then hum.PlatformStand = false end
end

local function toggleFly()
    local _, hum, root = getChar()
    if not hum then return end
    state.fly = not state.fly
    if not state.fly then
        stopFly()
        log("Fly OFF")
        return
    end

    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 1e4
    flyBG.Parent = root

    connections.fly = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam or not flyBV then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * FLY_SPEED or Vector3.zero
        flyBG.CFrame = cam.CFrame
    end)
    log("Fly ON (WASD + Space/Ctrl)")
end

local function toggleNoclip()
    state.noclip = not state.noclip
    if state.noclip then
        connections.noclip = RunService.Stepped:Connect(function()
            local char = getChar()
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    elseif connections.noclip then
        connections.noclip:Disconnect()
        connections.noclip = nil
    end
    log("Noclip " .. (state.noclip and "ON" or "OFF"))
end

local function toggleInfJump()
    state.infJump = not state.infJump
    if state.infJump then
        connections.infJump = UserInputService.JumpRequest:Connect(function()
            local _, hum = getChar()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    elseif connections.infJump then
        connections.infJump:Disconnect()
        connections.infJump = nil
    end
    log("Infinite jump " .. (state.infJump and "ON" or "OFF"))
end

local function restoreAll()
    local _, hum = getChar()
    if hum and next(defaults) ~= nil then
        hum.WalkSpeed = defaults.WalkSpeed
        hum.JumpPower = defaults.JumpPower
        hum.JumpHeight = defaults.JumpHeight
    end
    stopFly()
    for k, c in pairs(connections) do
        c:Disconnect()
        connections[k] = nil
    end
    for k in pairs(state) do state[k] = false end
    log("All tests stopped, defaults restored")
end

----------------------------------------------------------------------
-- INPUT
----------------------------------------------------------------------
local binds = {
    [Enum.KeyCode.F1] = toggleSpeed,
    [Enum.KeyCode.F2] = toggleJump,
    [Enum.KeyCode.F3] = teleportForward,
    [Enum.KeyCode.F4] = toggleFly,
    [Enum.KeyCode.F5] = toggleNoclip,
    [Enum.KeyCode.F6] = toggleInfJump,
    [Enum.KeyCode.F7] = restoreAll,
}

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local fn = binds[input.KeyCode]
    if fn then fn() end
end)

log("Loaded. F1 speed | F2 jump | F3 teleport | F4 fly | F5 noclip | F6 inf jump | F7 restore all")
