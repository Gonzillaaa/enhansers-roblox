--[[
    anticheat_tester.lua
    Test menu for YOUR OWN Roblox game.

    Features: Fly, Wallhack (see players through walls).
    RightShift hides / shows the menu.

    SETUP: put your game's PlaceId in ALLOWED_PLACE_IDS below. The script
    refuses to run in any other game.
]]

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
local ALLOWED_PLACE_IDS = {
    -- 1234567890, -- <-- put your game's PlaceId here
}

local FLY_SPEED = 80

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
    local placeId = tostring(game.PlaceId)
    warn("[ACTester] PlaceId " .. placeId .. " is not in ALLOWED_PLACE_IDS. Edit the script and add it. Aborting.")

    -- Show the PlaceId on screen so it can be read and copied without a console.
    pcall(function()
        local notice = Instance.new("ScreenGui")
        notice.Name = "ACTesterNotice"
        notice.ResetOnSpawn = false
        local ok = pcall(function()
            notice.Parent = gethui and gethui() or game:GetService("CoreGui")
        end)
        if not ok or not notice.Parent then
            notice.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end

        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 340, 0, 110)
        box.Position = UDim2.new(0.5, -170, 0, 30)
        box.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        box.BorderSizePixel = 0
        box.Parent = notice
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 12)
        c.Parent = box

        local msg = Instance.new("TextLabel")
        msg.BackgroundTransparency = 1
        msg.Size = UDim2.new(1, -20, 0, 50)
        msg.Position = UDim2.new(0, 10, 0, 8)
        msg.TextWrapped = true
        msg.TextSize = 14
        msg.Font = Enum.Font.Gotham
        msg.TextColor3 = Color3.fromRGB(235, 235, 245)
        msg.Text = "AC Tester is locked. Put this PlaceId in ALLOWED_PLACE_IDS, then run the script again:"
        msg.Parent = box

        local idBox = Instance.new("TextBox")
        idBox.Size = UDim2.new(1, -20, 0, 32)
        idBox.Position = UDim2.new(0, 10, 0, 66)
        idBox.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
        idBox.BorderSizePixel = 0
        idBox.ClearTextOnFocus = false
        idBox.Text = placeId
        idBox.TextSize = 18
        idBox.Font = Enum.Font.GothamBold
        idBox.TextColor3 = Color3.fromRGB(120, 255, 170)
        idBox.Parent = box
        local c2 = Instance.new("UICorner")
        c2.CornerRadius = UDim.new(0, 8)
        c2.Parent = idBox
    end)
    return
end

----------------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------------
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

local player = Players.LocalPlayer
local wait_ = (task and task.wait) or wait

----------------------------------------------------------------------
-- THEME
----------------------------------------------------------------------
local COLORS = {
    bg      = Color3.fromRGB(24, 24, 32),
    bar     = Color3.fromRGB(36, 36, 48),
    row     = Color3.fromRGB(32, 32, 42),
    text    = Color3.fromRGB(235, 235, 245),
    dim     = Color3.fromRGB(150, 150, 170),
    accent  = Color3.fromRGB(120, 100, 255),
    on      = Color3.fromRGB(70, 200, 120),
    off     = Color3.fromRGB(80, 80, 95),
}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function label(parent, text, size, color, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.TextColor3 = color or COLORS.text
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.Parent = parent
    return l
end

----------------------------------------------------------------------
-- GUI ROOT
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ACTesterGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function mountGui()
    local ok = pcall(function()
        if gethui then
            gui.Parent = gethui()
        else
            gui.Parent = CoreGui
        end
    end)
    if not ok or not gui.Parent then
        gui.Parent = player:WaitForChild("PlayerGui")
    end
end
mountGui()

----------------------------------------------------------------------
-- FEATURES
----------------------------------------------------------------------
-- Fly
local flyEnabled = false
local flyBV, flyBG, flyConn

local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function startFly()
    stopFly()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    hum.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 1e4
    flyBG.Parent = root

    flyConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam or not flyBV then return end
        local dir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then
            flyBV.Velocity = dir.Unit * FLY_SPEED
        else
            flyBV.Velocity = Vector3.new(0, 0, 0)
        end
        flyBG.CFrame = cam.CFrame
    end)
end

local function setFly(on)
    flyEnabled = on
    if on then startFly() else stopFly() end
end

player.CharacterAdded:Connect(function()
    if flyEnabled then
        wait_(1)
        if flyEnabled then startFly() end
    end
end)

-- Wallhack (highlight other players through walls)
local wallhackEnabled = false
local highlights = {}
local espConns = {}

local function removeHighlight(plr)
    local h = highlights[plr]
    if h then h:Destroy() highlights[plr] = nil end
end

local function addHighlight(plr)
    removeHighlight(plr)
    if plr == player or not plr.Character then return end
    local h = Instance.new("Highlight")
    h.Name = "ACTesterESP"
    h.FillColor = Color3.fromRGB(255, 70, 70)
    h.FillTransparency = 0.6
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = plr.Character
    h.Parent = gui
    highlights[plr] = h
end

local function hookPlayer(plr)
    if plr == player then return end
    espConns[#espConns + 1] = plr.CharacterAdded:Connect(function()
        if wallhackEnabled then
            wait_(0.2)
            addHighlight(plr)
        end
    end)
    espConns[#espConns + 1] = plr.CharacterRemoving:Connect(function()
        removeHighlight(plr)
    end)
    if wallhackEnabled then addHighlight(plr) end
end

local function setWallhack(on)
    wallhackEnabled = on
    if on then
        for _, plr in ipairs(Players:GetPlayers()) do
            hookPlayer(plr)
        end
        espConns[#espConns + 1] = Players.PlayerAdded:Connect(hookPlayer)
        espConns[#espConns + 1] = Players.PlayerRemoving:Connect(removeHighlight)
    else
        for _, c in ipairs(espConns) do c:Disconnect() end
        espConns = {}
        for plr in pairs(highlights) do removeHighlight(plr) end
    end
end

local features = {
    { name = "Fly",      desc = "WASD + Space / Ctrl", set = setFly },
    { name = "Wallhack", desc = "See players through walls", set = setWallhack },
}

----------------------------------------------------------------------
-- MENU
----------------------------------------------------------------------
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.Size = UDim2.new(0, 280, 0, 40 + (#features * 52) + 30)
menu.Position = UDim2.new(0.5, -140, 0.5, -100)
menu.BackgroundColor3 = COLORS.bg
menu.BorderSizePixel = 0
menu.Visible = false
menu.Parent = gui
corner(menu, 12)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = COLORS.bar
titleBar.BorderSizePixel = 0
titleBar.Parent = menu
corner(titleBar, 12)

local title = label(titleBar, "AC Tester", 16, COLORS.text, true)
title.Size = UDim2.new(1, -16, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.TextXAlignment = Enum.TextXAlignment.Left

local list = Instance.new("Frame")
list.BackgroundTransparency = 1
list.Position = UDim2.new(0, 10, 0, 48)
list.Size = UDim2.new(1, -20, 1, -80)
list.Parent = menu

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local hint = label(menu, "RightShift: hide / show", 12, COLORS.dim, false)
hint.Size = UDim2.new(1, 0, 0, 20)
hint.Position = UDim2.new(0, 0, 1, -26)

for i, feature in ipairs(features) do
    local row = Instance.new("Frame")
    row.LayoutOrder = i
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Parent = list
    corner(row, 8)

    local name = label(row, feature.name, 15, COLORS.text, true)
    name.Size = UDim2.new(1, -90, 0, 22)
    name.Position = UDim2.new(0, 12, 0, 4)
    name.TextXAlignment = Enum.TextXAlignment.Left

    local desc = label(row, feature.desc, 11, COLORS.dim, false)
    desc.Size = UDim2.new(1, -90, 0, 14)
    desc.Position = UDim2.new(0, 12, 0, 25)
    desc.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 56, 0, 26)
    toggle.Position = UDim2.new(1, -68, 0.5, -13)
    toggle.BackgroundColor3 = COLORS.off
    toggle.BorderSizePixel = 0
    toggle.Text = "OFF"
    toggle.TextSize = 12
    toggle.Font = Enum.Font.GothamBold
    toggle.TextColor3 = COLORS.text
    toggle.AutoButtonColor = false
    toggle.Parent = row
    corner(toggle, 13)

    local on = false
    toggle.MouseButton1Click:Connect(function()
        on = not on
        toggle.Text = on and "ON" or "OFF"
        TweenService:Create(toggle, TweenInfo.new(0.15), {
            BackgroundColor3 = on and COLORS.on or COLORS.off,
        }):Play()
        feature.set(on)
    end)
end

-- Dragging
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = menu.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            menu.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Hide / show
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift and menu.Parent then
        menu.Visible = not menu.Visible
    end
end)

----------------------------------------------------------------------
-- LOADING SCREEN
----------------------------------------------------------------------
local loading = Instance.new("Frame")
loading.Name = "Loading"
loading.Size = UDim2.new(0, 320, 0, 130)
loading.Position = UDim2.new(0.5, -160, 0.5, -65)
loading.BackgroundColor3 = COLORS.bg
loading.BorderSizePixel = 0
loading.Parent = gui
corner(loading, 14)

local lTitle = label(loading, "AC Tester", 22, COLORS.text, true)
lTitle.Size = UDim2.new(1, 0, 0, 36)
lTitle.Position = UDim2.new(0, 0, 0, 14)

local lStatus = label(loading, "Starting...", 13, COLORS.dim, false)
lStatus.Size = UDim2.new(1, 0, 0, 20)
lStatus.Position = UDim2.new(0, 0, 0, 56)

local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(1, -40, 0, 8)
barBack.Position = UDim2.new(0, 20, 0, 92)
barBack.BackgroundColor3 = COLORS.bar
barBack.BorderSizePixel = 0
barBack.Parent = loading
corner(barBack, 4)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = COLORS.accent
barFill.BorderSizePixel = 0
barFill.Parent = barBack
corner(barFill, 4)

local steps = {
    { "Checking game...",   0.25 },
    { "Loading fly...",     0.55 },
    { "Loading wallhack...", 0.80 },
    { "Building menu...",   1.00 },
}

for _, step in ipairs(steps) do
    lStatus.Text = step[1]
    TweenService:Create(barFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
        Size = UDim2.new(step[2], 0, 1, 0),
    }):Play()
    wait_(0.5)
end

lStatus.Text = "Done!"
wait_(0.3)

-- Fade out the loading screen, then show the menu
TweenService:Create(loading, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
for _, d in ipairs(loading:GetDescendants()) do
    if d:IsA("TextLabel") then
        TweenService:Create(d, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    elseif d:IsA("Frame") then
        TweenService:Create(d, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
    end
end
wait_(0.4)
loading:Destroy()
menu.Visible = true

print("[ACTester] Loaded. RightShift hides / shows the menu.")
