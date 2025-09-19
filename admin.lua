-- Admin Panel untuk Executor (LocalScript)
-- Fitur: player list (side panel, hide/show), teleport, bring, kill, rope, unrope all,
-- walkspeed, jump power, reset to map defaults, fly, noclip, ESP, auto-refresh, auto-refresh toggle, animations optional.

-- CONFIG
local UI_NAME = "AdminPanel"
local REFRESH_INTERVAL = 5 -- detik untuk auto refresh list
local DEFAULT_WALKSPEED = 16 -- fallback jika tidak ada map default
local DEFAULT_JUMPPOWER = 50 -- fallback

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- REMOTES (cek ketersediaan)
local RopePlayer = nil
local UnropeAll = nil
local SendNotification = nil
local AdminAction = nil

pcall(function()
    RopePlayer = game:GetService("ReplicatedStorage"):WaitForChild("RopePlayer", 2)
end)
pcall(function()
    UnropeAll = game:GetService("ReplicatedStorage"):WaitForChild("UnropeAll", 2)
end)
pcall(function()
    SendNotification = game:GetService("ReplicatedStorage"):WaitForChild("SendNotification", 2)
end)
pcall(function()
    AdminAction = game:GetService("ReplicatedStorage"):WaitForChild("AdminAction", 2)
end)

-- helper: safe fire remote
local function safeFire(remote, ...)
    if remote and remote.FireServer then
        pcall(function() remote:FireServer(...) end)
        return true
    end
    return false
end

-- store active ropes local (for fallback)
local activeLocalRopes = {}

-- store original defaults for reset
local storedDefaults = {
    WalkSpeed = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed) or DEFAULT_WALKSPEED,
    JumpPower = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower) or DEFAULT_JUMPPOWER
}

-- try to read workspace.MapDefaults if exists
pcall(function()
    if workspace:FindFirstChild("MapDefaults") then
        local md = workspace.MapDefaults
        if md:FindFirstChild("WalkSpeed") and typeof(md.WalkSpeed.Value) == "number" then
            storedDefaults.WalkSpeed = md.WalkSpeed.Value
        end
        if md:FindFirstChild("JumpPower") and typeof(md.JumpPower.Value) == "number" then
            storedDefaults.JumpPower = md.JumpPower.Value
        end
    end
end)

-- UI CREATION (ScreenGui)
-- Remove existing UI if exists
local existing = LocalPlayer:FindFirstChildOfClass("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(UI_NAME)
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = UI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 480)
mainFrame.Position = UDim2.new(0.02,0,0.2,0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
mainFrame.BorderSizePixel = 0
mainFrame.AnchorPoint = Vector2.new(0,0)
mainFrame.Parent = screenGui
mainFrame.Visible = true
mainFrame.Active = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1,0,0,32)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "🔧 Aguz Admin Panel"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(240,240,240)

-- Hide / Drag
local hideButton = Instance.new("TextButton", mainFrame)
hideButton.Size = UDim2.new(0,90,0,28)
hideButton.Position = UDim2.new(1,-95,0,2)
hideButton.Text = "Hide Player List"
hideButton.Font = Enum.Font.SourceSans
hideButton.TextSize = 14
hideButton.BackgroundColor3 = Color3.fromRGB(45,45,45)
hideButton.TextColor3 = Color3.fromRGB(230,230,230)
hideButton.BorderSizePixel = 0

-- left: player list panel
local leftPanel = Instance.new("Frame", mainFrame)
leftPanel.Size = UDim2.new(0,160,1,-40)
leftPanel.Position = UDim2.new(0,10,0,40)
leftPanel.BackgroundTransparency = 0.05
leftPanel.BorderSizePixel = 0

local leftTitle = Instance.new("TextLabel", leftPanel)
leftTitle.Size = UDim2.new(1, -10, 0, 24)
leftTitle.Position = UDim2.new(0,6,0,6)
leftTitle.BackgroundTransparency = 1
leftTitle.Text = "Players"
leftTitle.Font = Enum.Font.SourceSansBold
leftTitle.TextSize = 14
leftTitle.TextColor3 = Color3.fromRGB(240,240,240)

local refreshButton = Instance.new("TextButton", leftPanel)
refreshButton.Size = UDim2.new(0,70,0,22)
refreshButton.Position = UDim2.new(1,-78,0,6)
refreshButton.Text = "Refresh"
refreshButton.Font = Enum.Font.SourceSans
refreshButton.TextSize = 12
refreshButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
refreshButton.TextColor3 = Color3.fromRGB(230,230,230)
refreshButton.BorderSizePixel = 0

local autoRefreshToggle = Instance.new("TextButton", leftPanel)
autoRefreshToggle.Size = UDim2.new(1,-10,0,24)
autoRefreshToggle.Position = UDim2.new(0,5,0,34)
autoRefreshToggle.Text = "Auto Refresh: ON ("..tostring(REFRESH_INTERVAL).."s)"
autoRefreshToggle.Font = Enum.Font.SourceSans
autoRefreshToggle.TextSize = 12
autoRefreshToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
autoRefreshToggle.TextColor3 = Color3.fromRGB(230,230,230)
autoRefreshToggle.BorderSizePixel = 0

local playerList = Instance.new("ScrollingFrame", leftPanel)
playerList.Size = UDim2.new(1,-10,1,-70)
playerList.Position = UDim2.new(0,5,0,64)
playerList.CanvasSize = UDim2.new(0,0,0,0)
playerList.BackgroundTransparency = 1
playerList.ScrollBarThickness = 6

local uiListLayout = Instance.new("UIListLayout", playerList)
uiListLayout.Padding = UDim.new(0,4)
uiListLayout.SortOrder = Enum.SortOrder.Name

-- right: controls panel
local rightPanel = Instance.new("Frame", mainFrame)
rightPanel.Size = UDim2.new(1,-190,1,-40)
rightPanel.Position = UDim2.new(0,180,0,40)
rightPanel.BackgroundTransparency = 0.05
rightPanel.BorderSizePixel = 0

local selectedLabel = Instance.new("TextLabel", rightPanel)
selectedLabel.Size = UDim2.new(1, -10, 0, 28)
selectedLabel.Position = UDim2.new(0,5,0,5)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Selected: (None)"
selectedLabel.Font = Enum.Font.SourceSansBold
selectedLabel.TextSize = 14
selectedLabel.TextColor3 = Color3.fromRGB(240,240,240)

-- Buttons grid
local buttonNames = {
    {"Teleport To","Bring","Kill"},
    {"Rope","Unrope All","Kill (Server)"},
    {"Teleport (Server)","Bring (Server)","Unrope (Server)"},
}
local buttons = {}
local startY = 40
for rowIndex,row in ipairs(buttonNames) do
    for colIndex, name in ipairs(row) do
        local btn = Instance.new("TextButton", rightPanel)
        btn.Size = UDim2.new(0,120,0,30)
        btn.Position = UDim2.new(0, 10 + (colIndex-1)*135, 0, startY + (rowIndex-1)*38)
        btn.Text = name
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 13
        btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        btn.BorderSizePixel = 0
        buttons[name] = btn
    end
end

-- Walkspeed & Jump Power
local wsLabel = Instance.new("TextLabel", rightPanel)
wsLabel.Size = UDim2.new(0,200,0,22)
wsLabel.Position = UDim2.new(0,8,0,200)
wsLabel.BackgroundTransparency = 1
wsLabel.Text = "WalkSpeed: "..tostring(storedDefaults.WalkSpeed)
wsLabel.Font = Enum.Font.SourceSans
wsLabel.TextSize = 13
wsLabel.TextColor3 = Color3.fromRGB(230,230,230)

local wsInput = Instance.new("TextBox", rightPanel)
wsInput.Size = UDim2.new(0,120,0,26)
wsInput.Position = UDim2.new(0,210,0,196)
wsInput.Text = tostring(storedDefaults.WalkSpeed)
wsInput.Font = Enum.Font.SourceSans
wsInput.TextSize = 14
wsInput.ClearTextOnFocus = false
wsInput.BackgroundColor3 = Color3.fromRGB(55,55,55)
wsInput.TextColor3 = Color3.fromRGB(230,230,230)
wsInput.BorderSizePixel = 0

local wsSet = Instance.new("TextButton", rightPanel)
wsSet.Size = UDim2.new(0,80,0,26)
wsSet.Position = UDim2.new(0,340,0,196)
wsSet.Text = "Set WS"
wsSet.Font = Enum.Font.SourceSans
wsSet.TextSize = 12
wsSet.BackgroundColor3 = Color3.fromRGB(70,70,70)
wsSet.TextColor3 = Color3.fromRGB(230,230,230)
wsSet.BorderSizePixel = 0

local jpLabel = Instance.new("TextLabel", rightPanel)
jpLabel.Size = UDim2.new(0,200,0,22)
jpLabel.Position = UDim2.new(0,8,0,230)
jpLabel.BackgroundTransparency = 1
jpLabel.Text = "JumpPower: "..tostring(storedDefaults.JumpPower)
jpLabel.Font = Enum.Font.SourceSans
jpLabel.TextSize = 13
jpLabel.TextColor3 = Color3.fromRGB(230,230,230)

local jpInput = Instance.new("TextBox", rightPanel)
jpInput.Size = UDim2.new(0,120,0,26)
jpInput.Position = UDim2.new(0,210,0,226)
jpInput.Text = tostring(storedDefaults.JumpPower)
jpInput.Font = Enum.Font.SourceSans
jpInput.TextSize = 14
jpInput.ClearTextOnFocus = false
jpInput.BackgroundColor3 = Color3.fromRGB(55,55,55)
jpInput.TextColor3 = Color3.fromRGB(230,230,230)
jpInput.BorderSizePixel = 0

local jpSet = Instance.new("TextButton", rightPanel)
jpSet.Size = UDim2.new(0,80,0,26)
jpSet.Position = UDim2.new(0,340,0,226)
jpSet.Text = "Set JP"
jpSet.Font = Enum.Font.SourceSans
jpSet.TextSize = 12
jpSet.BackgroundColor3 = Color3.fromRGB(70,70,70)
jpSet.TextColor3 = Color3.fromRGB(230,230,230)
jpSet.BorderSizePixel = 0

local resetDefaultsBtn = Instance.new("TextButton", rightPanel)
resetDefaultsBtn.Size = UDim2.new(0,120,0,26)
resetDefaultsBtn.Position = UDim2.new(0,8,0,262)
resetDefaultsBtn.Text = "Reset to Map Default"
resetDefaultsBtn.Font = Enum.Font.SourceSans
resetDefaultsBtn.TextSize = 12
resetDefaultsBtn.BackgroundColor3 = Color3.fromRGB(85,85,85)
resetDefaultsBtn.TextColor3 = Color3.fromRGB(230,230,230)
resetDefaultsBtn.BorderSizePixel = 0

-- Fly, Noclip, ESP toggles
local flyToggle = Instance.new("TextButton", rightPanel)
flyToggle.Size = UDim2.new(0,120,0,26)
flyToggle.Position = UDim2.new(0,8,0,300)
flyToggle.Text = "Fly: OFF"
flyToggle.Font = Enum.Font.SourceSans
flyToggle.TextSize = 12
flyToggle.BackgroundColor3 = Color3.fromRGB(85,85,85)
flyToggle.TextColor3 = Color3.fromRGB(230,230,230)

local noclipToggle = Instance.new("TextButton", rightPanel)
noclipToggle.Size = UDim2.new(0,120,0,26)
noclipToggle.Position = UDim2.new(0,140,0,300)
noclipToggle.Text = "Noclip: OFF"
noclipToggle.Font = Enum.Font.SourceSans
noclipToggle.TextSize = 12
noclipToggle.BackgroundColor3 = Color3.fromRGB(85,85,85)
noclipToggle.TextColor3 = Color3.fromRGB(230,230,230)

local espToggle = Instance.new("TextButton", rightPanel)
espToggle.Size = UDim2.new(0,120,0,26)
espToggle.Position = UDim2.new(0,272,0,300)
espToggle.Text = "ESP: OFF"
espToggle.Font = Enum.Font.SourceSans
espToggle.TextSize = 12
espToggle.BackgroundColor3 = Color3.fromRGB(85,85,85)
espToggle.TextColor3 = Color3.fromRGB(230,230,230)

-- FOOTER: small credits / close
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0,60,0,26)
closeBtn.Position = UDim2.new(1,-66,1,-32)
closeBtn.Text = "Close"
closeBtn.Font = Enum.Font.SourceSans
closeBtn.TextSize = 12
closeBtn.BackgroundColor3 = Color3.fromRGB(90,40,40)
closeBtn.TextColor3 = Color3.fromRGB(240,240,240)
closeBtn.BorderSizePixel = 0

-- DRAGGING mainFrame
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- STATE
local selectedPlayer = nil
local autoRefresh = true
local espEnabled = false
local espItems = {}
local flyEnabled = false
local noclipEnabled = false
local flyObjects = {}
local humanoidWalkSpeedConnection = nil
local noclipConnection = nil

-- UTIL FUNCTIONS
local function notify(text)
    if SendNotification and SendNotification.FireServer then
        pcall(function() SendNotification:FireServer(LocalPlayer, text) end)
    else
        -- fallback: small in-GUI tweened label
        local tmp = Instance.new("TextLabel", mainFrame)
        tmp.Size = UDim2.new(0.5,0,0,28)
        tmp.Position = UDim2.new(0.25,0,1,-60)
        tmp.BackgroundTransparency = 0.2
        tmp.Text = text
        tmp.Font = Enum.Font.SourceSans
        tmp.TextSize = 14
        tmp.TextColor3 = Color3.fromRGB(240,240,240)
        tmp.BackgroundColor3 = Color3.fromRGB(60,60,60)
        tmp.BorderSizePixel = 0
        tmp.AnchorPoint = Vector2.new(0.5,0.5)
        local tween = TweenService:Create(tmp, TweenInfo.new(1), {BackgroundTransparency = 1, TextTransparency = 0.5})
        delay(2, function() pcall(function() tween:Play() end) end)
        delay(4, function() pcall(function() tmp:Destroy() end) end)
    end
end

local function clearPlayerList()
    for _, child in pairs(playerList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function buildPlayerList()
    clearPlayerList()
    for _, plr in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Text = plr.Name
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        btn.BorderSizePixel = 0
        btn.Parent = playerList

        btn.MouseButton1Click:Connect(function()
            selectedPlayer = plr
            selectedLabel.Text = "Selected: "..plr.Name
        end)
    end
    -- adjust canvas size
    local count = #Players:GetPlayers()
    playerList.CanvasSize = UDim2.new(0,0,0, (count*32) + 8)
end

-- auto-refresh loop
spawn(function()
    while true do
        if autoRefresh then
            pcall(buildPlayerList)
        end
        wait(REFRESH_INTERVAL)
    end
end)

-- initial build
buildPlayerList()

-- hide/show left panel handler
local leftVisible = true
hideButton.MouseButton1Click:Connect(function()
    leftVisible = not leftVisible
    leftPanel.Visible = leftVisible
    if leftVisible then
        hideButton.Text = "Hide Player List"
        mainFrame.Size = UDim2.new(0,420,0,480)
    else
        hideButton.Text = "Show Player List"
        mainFrame.Size = UDim2.new(0,260,0,480)
    end
end)

refreshButton.MouseButton1Click:Connect(function()
    buildPlayerList()
    notify("Player list refreshed")
end)

autoRefreshToggle.MouseButton1Click:Connect(function()
    autoRefresh = not autoRefresh
    autoRefreshToggle.Text = "Auto Refresh: "..(autoRefresh and "ON ("..tostring(REFRESH_INTERVAL).."s)" or "OFF")
end)

-- FEATURE IMPLEMENTATIONS

-- Safe helper to get target character & root part
local function getCharacterRoot(plr)
    if not plr or not plr.Character then return nil end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("UpperTorso")
    return plr.Character, hrp
end

-- Teleport local player to target (client-side)
local function teleportTo(target)
    if not target then notify("Pilih player dulu!") return end
    local tchar, thrp = getCharacterRoot(target)
    local myChar, myHrp = getCharacterRoot(LocalPlayer)
    if tchar and thrp and myChar and myHrp then
        pcall(function()
            myHrp.CFrame = thrp.CFrame + Vector3.new(0,3,0)
        end)
        notify("Teleport ke "..target.Name)
    else
        notify("Gagal teleport - karakter tidak ada")
    end
end

-- Bring target to local player (client-side)
local function bringToMe(target)
    if not target then notify("Pilih player dulu!") return end
    local tchar, thrp = getCharacterRoot(target)
    local myChar, myHrp = getCharacterRoot(LocalPlayer)
    if tchar and thrp and myChar and myHrp then
        pcall(function()
            thrp.CFrame = myHrp.CFrame + Vector3.new(2,0,0)
        end)
        notify("Membawa "..target.Name.." ke kamu")
    else
        notify("Gagal membawa - karakter tidak ada")
    end
end

-- Kill target (client-side attempt)
local function killPlayerLocal(target)
    if not target then notify("Pilih player dulu!") return end
    local tchar = target.Character
    if tchar then
        local humanoid = tchar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function() humanoid.Health = 0 end)
            notify("Dibunuh: "..target.Name)
            return true
        end
    end
    notify("Gagal kill local (mencoba server...)")
    return false
end

-- Rope target (use remote if possible, fallback local)
local function ropePlayer(target)
    if not target then notify("Pilih player dulu!") return end
    -- prefer remote
    if RopePlayer and RopePlayer.FireServer then
        pcall(function() RopePlayer:FireServer(LocalPlayer, target) end)
        notify("Rope request dikirim ke server untuk "..target.Name)
        return
    end
    -- fallback: create attachments + rope constraint locally on our HRP
    local myChar, myHrp = getCharacterRoot(LocalPlayer)
    local tchar, thrp = getCharacterRoot(target)
    if myHrp and thrp then
        local att1 = Instance.new("Attachment")
        att1.Parent = myHrp
        local att2 = Instance.new("Attachment")
        att2.Parent = thrp
        local rope = Instance.new("RopeConstraint")
        rope.Attachment0 = att1
        rope.Attachment1 = att2
        rope.Length = 6
        rope.Visible = true
        rope.Parent = myHrp
        table.insert(activeLocalRopes, rope)
        notify("Rope lokal dibuat ke "..target.Name)
    else
        notify("Gagal rope - HRP tidak ditemukan")
    end
end

local function unropeAll()
    -- Try remote
    if UnropeAll and UnropeAll.FireServer then
        pcall(function() UnropeAll:FireServer(LocalPlayer) end)
        notify("Unrope all dikirim ke server")
    end
    -- local cleanup
    for _, r in ipairs(activeLocalRopes) do
        pcall(function() if r and r.Parent then r:Destroy() end end)
    end
    activeLocalRopes = {}
    notify("Semua tali lokal dihapus")
end

-- Server-side generic admin action (if AdminAction remote present)
-- AdminAction:FireServer(action:string, targetPlayer:Player)
local function fireAdminAction(action, target)
    if not AdminAction then return false end
    pcall(function()
        if target then
            AdminAction:FireServer(action, target)
        else
            AdminAction:FireServer(action)
        end
    end)
    return true
end

-- ESP functions
local function createESPForPlayer(plr)
    if not plr.Character then return end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if espItems[plr] then return end

    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0,100,0,40)
    bill.AlwaysOnTop = true
    bill.Adornee = root
    bill.StudsOffset = Vector3.new(0,2,0)
    bill.Parent = root

    local text = Instance.new("TextLabel", bill)
    text.Size = UDim2.new(1,0,1,0)
    text.BackgroundTransparency = 1
    text.Text = plr.Name
    text.Font = Enum.Font.SourceSansBold
    text.TextSize = 14
    text.TextColor3 = Color3.fromRGB(255,255,255)
    text.TextStrokeTransparency = 0.5

    espItems[plr] = bill
end

local function removeESPForPlayer(plr)
    if espItems[plr] then
        pcall(function() espItems[plr]:Destroy() end)
        espItems[plr] = nil
    end
end

local function toggleESP(on)
    espEnabled = on
    if espEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                createESPForPlayer(plr)
            end
        end
        -- connect new players
        Players.PlayerAdded:Connect(function(p)
            if espEnabled and p ~= LocalPlayer then
                p.CharacterAdded:Connect(function() createESPForPlayer(p) end)
            end
        end)
        -- remove when left
        Players.PlayerRemoving:Connect(function(p)
            removeESPForPlayer(p)
        end)
        notify("ESP ON")
    else
        for p,_ in pairs(espItems) do removeESPForPlayer(p) end
        espItems = {}
        notify("ESP OFF")
    end
end

-- Fly implementation (simple body movers)
local function enableFly(on)
    flyEnabled = on
    local character, hrp = getCharacterRoot(LocalPlayer)
    if not character or not hrp then notify("Karakter tidak ditemukan") return end

    if flyEnabled then
        -- create BodyVelocity + BodyGyro
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e5,1e5,1e5)
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = hrp

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp

        flyObjects.bv = bv
        flyObjects.bg = bg

        local speed = 50
        local forward = 0
        local right = 0
        local up = 0

        local function updateFly()
            if not flyEnabled then return end
            local cam = workspace.CurrentCamera
            local dir = Vector3.new(0,0,0)
            local camCFrame = cam.CFrame
            dir = dir + (camCFrame.LookVector * forward)
            dir = dir + (camCFrame.RightVector * right)
            dir = dir + Vector3.new(0, up, 0)
            if flyObjects.bv then
                flyObjects.bv.Velocity = dir * speed
            end
            if flyObjects.bg then
                flyObjects.bg.CFrame = CFrame.new(hrp.Position, hrp.Position + camCFrame.LookVector)
            end
        end

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not flyEnabled then
                conn:Disconnect()
                return
            end
            updateFly()
        end)

        -- WASD + space/shift to control
        local down = {}
        UserInputService.InputBegan:Connect(function(i,gp)
            if gp then return end
            down[i.KeyCode] = true
            if i.KeyCode == Enum.KeyCode.W then forward = 1 end
            if i.KeyCode == Enum.KeyCode.S then forward = -1 end
            if i.KeyCode == Enum.KeyCode.D then right = 1 end
            if i.KeyCode == Enum.KeyCode.A then right = -1 end
            if i.KeyCode == Enum.KeyCode.Space then up = 1 end
            if i.KeyCode == Enum.KeyCode.LeftShift then up = -1 end
        end)
        UserInputService.InputEnded:Connect(function(i,gp)
            if gp then return end
            down[i.KeyCode] = nil
            if i.KeyCode == Enum.KeyCode.W or i.KeyCode == Enum.KeyCode.S then forward = 0 end
            if i.KeyCode == Enum.KeyCode.D or i.KeyCode == Enum.KeyCode.A then right = 0 end
            if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.LeftShift then up = 0 end
        end)

        notify("Fly ON (gunakan WASD + Space/Shift)")
    else
        if flyObjects.bv then pcall(function() flyObjects.bv:Destroy() end) end
        if flyObjects.bg then pcall(function() flyObjects.bg:Destroy() end) end
        flyObjects = {}
        notify("Fly OFF")
    end
end

-- Noclip implementation
local function enableNoclip(on)
    noclipEnabled = on
    if noclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        notify("Noclip ON")
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        -- try to restore collisions
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = true end)
                end
            end
        end
        notify("Noclip OFF")
    end
end

-- WalkSpeed & JumpPower setters
local function setWalkSpeed(value)
    local char = LocalPlayer.Character
    if not char then notify("Karakter tidak ditemukan") return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid.WalkSpeed = value end)
        notify("WalkSpeed diset ke "..tostring(value))
    end
end
local function setJumpPower(value)
    local char = LocalPlayer.Character
    if not char then notify("Karakter tidak ditemukan") return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid.JumpPower = value end)
        notify("JumpPower diset ke "..tostring(value))
    end
end
local function resetToMapDefaults()
    setWalkSpeed(storedDefaults.WalkSpeed)
    setJumpPower(storedDefaults.JumpPower)
    wsInput.Text = tostring(storedDefaults.WalkSpeed)
    jpInput.Text = tostring(storedDefaults.JumpPower)
    wsLabel.Text = "WalkSpeed: "..tostring(storedDefaults.WalkSpeed)
    jpLabel.Text = "JumpPower: "..tostring(storedDefaults.JumpPower)
    notify("Reset ke default map: WS="..storedDefaults.WalkSpeed.." JP="..storedDefaults.JumpPower)
end

-- BUTTONS behavior
buttons["Teleport To"].MouseButton1Click:Connect(function()
    if selectedPlayer then teleportTo(selectedPlayer) end
end)
buttons["Bring"].MouseButton1Click:Connect(function()
    if selectedPlayer then bringToMe(selectedPlayer) end
end)
buttons["Kill"].MouseButton1Click:Connect(function()
    if selectedPlayer then killPlayerLocal(selectedPlayer) end
end)
buttons["Rope"].MouseButton1Click:Connect(function()
    if selectedPlayer then ropePlayer(selectedPlayer) end
end)
buttons["Unrope All"].MouseButton1Click:Connect(function()
    unropeAll()
end)

-- server variants (try remote AdminAction names)
buttons["Kill (Server)"].MouseButton1Click:Connect(function()
    if not selectedPlayer then notify("Pilih player dulu!") return end
    if fireAdminAction("Kill", selectedPlayer) then
        notify("Permintaan kill dikirim ke server untuk "..selectedPlayer.Name)
    else
        notify("Server kill remote tidak tersedia")
    end
end)
buttons["Teleport (Server)"].MouseButton1Click:Connect(function()
    if not selectedPlayer then notify("Pilih player dulu!") return end
    if fireAdminAction("TeleportTo", selectedPlayer) then
        notify("Permintaan teleport dikirim ke server")
    else
        notify("Server teleport remote tidak tersedia")
    end
end)
buttons["Bring (Server)"].MouseButton1Click:Connect(function()
    if not selectedPlayer then notify("Pilih player dulu!") return end
    if fireAdminAction("Bring", selectedPlayer) then
        notify("Permintaan bring dikirim ke server")
    else
        notify("Server bring remote tidak tersedia")
    end
end)
buttons["Unrope (Server)"].MouseButton1Click:Connect(function()
    if not selectedPlayer then notify("Pilih player dulu!") return end
    if fireAdminAction("Unrope", selectedPlayer) then
        notify("Permintaan unrope dikirim ke server")
    else
        notify("Server unrope remote tidak tersedia")
    end
end)

-- Walkspeed / JumpPower UI
wsSet.MouseButton1Click:Connect(function()
    local val = tonumber(wsInput.Text)
    if val then
        setWalkSpeed(val)
        wsLabel.Text = "WalkSpeed: "..tostring(val)
    else
        notify("Nilai WalkSpeed invalid")
    end
end)
jpSet.MouseButton1Click:Connect(function()
    local val = tonumber(jpInput.Text)
    if val then
        setJumpPower(val)
        jpLabel.Text = "JumpPower: "..tostring(val)
    else
        notify("Nilai JumpPower invalid")
    end
end)
resetDefaultsBtn.MouseButton1Click:Connect(resetToMapDefaults)

-- toggles
flyToggle.MouseButton1Click:Connect(function()
    enableFly(not flyEnabled)
    flyToggle.Text = "Fly: "..(flyEnabled and "ON" or "OFF")
end)
noclipToggle.MouseButton1Click:Connect(function()
    enableNoclip(not noclipEnabled)
    noclipToggle.Text = "Noclip: "..(noclipEnabled and "ON" or "OFF")
end)
espToggle.MouseButton1Click:Connect(function()
    toggleESP(not espEnabled)
    espToggle.Text = "ESP: "..(espEnabled and "ON" or "OFF")
end)

-- Close button
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Cleanup ESP on character removal etc.
Players.PlayerRemoving:Connect(function(p)
    removeESPForPlayer(p)
end)
Players.PlayerAdded:Connect(function(p)
    if espEnabled then
        p.CharacterAdded:Connect(function() createESPForPlayer(p) end)
    end
end)

-- Auto-refresh selected label if selected player left
Players.PlayerRemoving:Connect(function(p)
    if selectedPlayer == p then
        selectedPlayer = nil
        selectedLabel.Text = "Selected: (None)"
    end
end)

-- Attach to local character when character spawns (to reapply WS/JP if needed)
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.5)
    setWalkSpeed(tonumber(wsInput.Text) or storedDefaults.WalkSpeed)
    setJumpPower(tonumber(jpInput.Text) or storedDefaults.JumpPower)
end)

-- Final notify
notify("Admin Panel siap — pilih player dari daftar di kiri.")

-- END OF SCRIPT
