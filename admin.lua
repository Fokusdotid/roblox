--[[====================================================
    FokusID Ultimate Admin GUI (Executor)
    Features:
    - Player list (select target) + auto refresh & highlight
    - Teleport to player / Bring to you / Kill / Freeze / Unfreeze / Set Health
    - WalkSpeed / JumpPower set & reset (restore original)
    - Fly (PC & Mobile) adapted from prior code
    - RopeGun (RopeConstraint) + Unrope All + rope length slider
    - NoClip toggle
    - UI animations (selection pulse, evil effect, status spinner)
    - Auto-refresh interval control
    - Intended for executors (client-side powerful admin)
======================================================]]

-- ========== Services & Locals ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Platform
local IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform()) ~= nil

-- Helper constructors
local function make(class, props)
    local o = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            pcall(function() o[k] = v end)
        end
    end
    return o
end

local function getRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

-- preserve originals
local originalStats = {}
local function recordOriginal(player)
    if not player or not player.Character then return end
    local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
    if hum then
        originalStats[player] = originalStats[player] or {}
        originalStats[player].WalkSpeed = originalStats[player].WalkSpeed or hum.WalkSpeed
        originalStats[player].JumpPower = originalStats[player].JumpPower or hum.JumpPower
    end
end

Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() wait(0.1) recordOriginal(p) end) end)
for _,p in ipairs(Players:GetPlayers()) do if p.Character then recordOriginal(p) end end

-- ========== Fly System (PC + Mobile) ==========
local FLYING = false
local iyflyspeed = 1
local vehicleflyspeed = 1
local QEfly = true
local flyKeyDown, flyKeyUp
local mobileConn = nil
local velocityHandlerName = "FokusVel_"..math.random(1000,9999)
local gyroHandlerName = "FokusGyr_"..math.random(1000,9999)

local function sFLY(vfly)
    repeat task.wait() until LocalPlayer and LocalPlayer.Character and getRoot(LocalPlayer.Character) and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local T = getRoot(LocalPlayer.Character)
    if not T then return end

    if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown = nil end
    if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp = nil end

    local CONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
    local SPEED = 0

    local BG = Instance.new("BodyGyro", T)
    local BV = Instance.new("BodyVelocity", T)
    BG.P = 9e4; BG.MaxTorque = Vector3.new(9e9,9e9,9e9); BG.CFrame = T.CFrame
    BV.MaxForce = Vector3.new(9e9,9e9,9e9); BV.Velocity = Vector3.new(0,0,0)

    FLYING = true

    spawn(function()
        repeat
            task.wait()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            if humanoid and not vfly then humanoid.PlatformStand = true end

            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                SPEED = 50
            else
                SPEED = 0
            end

            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                BV.Velocity = ((workspace.CurrentCamera.CFrame.LookVector * (CONTROL.F + CONTROL.B))
                    + ((workspace.CurrentCamera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p)
                    - workspace.CurrentCamera.CFrame.p)) * SPEED
            else
                BV.Velocity = Vector3.new(0,0,0)
            end

            BG.CFrame = workspace.CurrentCamera.CFrame
        until not FLYING

        BG:Destroy(); BV:Destroy()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
            LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
        end
    end)

    flyKeyDown = Mouse.KeyDown:Connect(function(k)
        k = tostring(k):lower()
        if k == "w" then CONTROL.F = (vfly and vehicleflyspeed or iyflyspeed)
        elseif k == "s" then CONTROL.B = -(vfly and vehicleflyspeed or iyflyspeed)
        elseif k == "a" then CONTROL.L = -(vfly and vehicleflyspeed or iyflyspeed)
        elseif k == "d" then CONTROL.R = (vfly and vehicleflyspeed or iyflyspeed)
        elseif QEfly and k == "e" then CONTROL.Q = (vfly and vehicleflyspeed or iyflyspeed)*2
        elseif QEfly and k == "q" then CONTROL.E = -(vfly and vehicleflyspeed or iyflyspeed)*2 end
    end)
    flyKeyUp = Mouse.KeyUp:Connect(function(k)
        k = tostring(k):lower()
        if k == "w" then CONTROL.F = 0
        elseif k == "s" then CONTROL.B = 0
        elseif k == "a" then CONTROL.L = 0
        elseif k == "d" then CONTROL.R = 0
        elseif k == "e" then CONTROL.Q = 0
        elseif k == "q" then CONTROL.E = 0 end
    end)
end

local function NOFLY()
    FLYING = false
    if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown = nil end
    if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp = nil end
    if mobileConn then mobileConn:Disconnect(); mobileConn = nil end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
        LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
    end
end

local function mobilefly(speaker, vfly)
    -- simplified mobile fly: require ControlModule
    local root = getRoot(speaker.Character)
    if not root then return end
    local ok, controlModule = pcall(function()
        return require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    end)
    if not ok or not controlModule then return end

    local v3zero = Vector3.new(0,0,0)
    local v3inf = Vector3.new(9e9,9e9,9e9)
    local bv = Instance.new("BodyVelocity", root); bv.Name = velocityHandlerName; bv.MaxForce = v3zero; bv.Velocity = v3zero
    local bg = Instance.new("BodyGyro", root); bg.Name = gyroHandlerName; bg.MaxTorque = v3inf; bg.P = 1000; bg.D = 50

    if mobileConn then mobileConn:Disconnect() mobileConn = nil end
    FLYING = true
    mobileConn = RunService.RenderStepped:Connect(function()
        root = getRoot(speaker.Character); if not root then return end
        if not speaker.Character:FindFirstChildWhichIsA("Humanoid") then return end
        local VH = root:FindFirstChild(velocityHandlerName); local GH = root:FindFirstChild(gyroHandlerName)
        if not VH or not GH then return end
        VH.MaxForce = v3inf; GH.MaxTorque = v3inf
        if not vfly then speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = true end
        GH.CFrame = workspace.CurrentCamera.CFrame; VH.Velocity = Vector3.new()
        local dir = controlModule:GetMoveVector()
        if dir and dir.Magnitude > 0 then
            VH.Velocity = VH.Velocity + workspace.CurrentCamera.CFrame.RightVector * (dir.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
            VH.Velocity = VH.Velocity + workspace.CurrentCamera.CFrame.LookVector * (dir.Z * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
        end
    end)
end

-- ========== Rope System ==========
local activeRopes = {} -- entries: {targetPlayer, a1, a2, rope}
local defaultRopeLength = 12

local function clearRopes()
    for _,t in ipairs(activeRopes) do
        pcall(function()
            if t.rope and t.rope.Parent then t.rope:Destroy() end
            if t.a1 and t.a1.Parent then t.a1:Destroy() end
            if t.a2 and t.a2.Parent then t.a2:Destroy() end
        end)
    end
    activeRopes = {}
end

-- remove on death/respawn
LocalPlayer.CharacterAdded:Connect(function() clearRopes() end)
-- give rope tool (executor context)
local function giveRopeTool()
    if LocalPlayer.Backpack:FindFirstChild("RopeGun") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("RopeGun")) then return end
    local tool = Instance.new("Tool"); tool.Name = "RopeGun"; tool.RequiresHandle = false; tool.Parent = LocalPlayer.Backpack
    tool.Activated:Connect(function()
        local conn
        conn = Mouse.Button1Down:Connect(function()
            local tpart = Mouse.Target
            if not tpart then return end
            local model = tpart:FindFirstAncestorOfClass("Model")
            local targetPlr = model and Players:GetPlayerFromCharacter(model)
            if not targetPlr or targetPlr == LocalPlayer then return end
            local root1 = getRoot(LocalPlayer.Character); local root2 = getRoot(targetPlr.Character)
            if not root1 or not root2 then return end
            local a1 = Instance.new("Attachment", root1); a1.Name = "Fokus_AttA_"..math.random(1,99999); a1.Position = Vector3.new(0,0.5,0)
            local a2 = Instance.new("Attachment", root2); a2.Name = "Fokus_AttB_"..math.random(1,99999); a2.Position = Vector3.new(0,0.5,0)
            local rope = Instance.new("RopeConstraint"); rope.Attachment0 = a1; rope.Attachment1 = a2; rope.Length = defaultRopeLength; rope.Visible = true; rope.Parent = workspace
            table.insert(activeRopes, {targetPlayer = targetPlr, a1 = a1, a2 = a2, rope = rope})
            StarterGui:SetCore("SendNotification", {Title="RopeGun", Text="Rope to "..targetPlr.Name.." created"})
            conn:Disconnect()
        end)
        delay(6, function() if conn and conn.Connected then conn:Disconnect() end end)
    end)
end

-- change rope length for all active ropes
local function setRopeLength(len)
    for _,t in ipairs(activeRopes) do
        pcall(function() if t.rope then t.rope.Length = len end end)
    end
end

-- ========== NoClip ==========
local clipEnabled = false
local noclipConn = nil
local function Clip(enable)
    clipEnabled = enable
    if enable then
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _,part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    end
end

-- ========== Extra Admin Actions ==========
local function freezePlayer(p)
    if not p or not p.Character then return end
    local r = getRoot(p.Character)
    if r then r.Velocity = Vector3.new(0,0,0); r.Anchored = true end
end
local function unfreezePlayer(p)
    if not p or not p.Character then return end
    local r = getRoot(p.Character)
    if r then r.Anchored = false end
end
local function killPlayer(p)
    if not p or not p.Character then return end
    local hum = p.Character:FindFirstChildWhichIsA("Humanoid")
    if hum then pcall(function() hum.Health = 0 end) end
end
local function bringPlayerToMe(p)
    if not p or not p.Character then return end
    local r = getRoot(p.Character); local myr = getRoot(LocalPlayer.Character)
    if r and myr then pcall(function() r.CFrame = myr.CFrame + Vector3.new(0,3,0) end) end
end
local function teleportToPlayer(p)
    if not p or not p.Character then return end
    local r = getRoot(p.Character); local myr = getRoot(LocalPlayer.Character)
    if r and myr then pcall(function() myr.CFrame = r.CFrame + Vector3.new(0,3,0) end) end
end
local function setPlayerHealth(p, val)
    if not p or not p.Character then return end
    local hum = p.Character:FindFirstChildWhichIsA("Humanoid")
    if hum then pcall(function() hum.Health = val end) end
end

-- ========== UI: build & behaviors ==========
local function buildUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "FokusUltimateAdmin"
    screen.ResetOnSpawn = false
    screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screen.IgnoreGuiInset = true

    -- Top-right toggle
    local topToggle = make("TextButton", {
        Parent = screen, Size = UDim2.new(0,140,0,34), AnchorPoint = Vector2.new(1,0),
        Position = UDim2.new(1, -10, 0, 10), Text = "Hide Admin GUI", BackgroundColor3 = Color3.fromRGB(35,35,35),
        TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSans, TextSize = 16
    })

    -- Main panel
    local panel = make("Frame", {
        Parent = screen, Size = UDim2.new(0,480,0,480), Position = UDim2.new(0.05,0,0.08,0),
        BackgroundColor3 = Color3.fromRGB(22,22,22), BorderSizePixel = 0
    })

    -- Status spinner (kevil animation)
    local spinner = make("Frame", {
        Parent = panel, Size = UDim2.new(0,26,0,26), Position = UDim2.new(0.01,0,0.02,0), BackgroundColor3 = Color3.fromRGB(0,0,0)
    })
    local spinIcon = make("TextLabel", {Parent = spinner, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "😈", TextScaled = true})
    -- Tween spin continuously
    spawn(function()
        while spinner.Parent do
            pcall(function()
                spinIcon.Rotation = 0
                TweenService:Create(spinIcon, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Rotation = 360}):Play()
            end)
            wait(1.2)
        end
    end)

    -- Title
    local title = make("TextLabel", {Parent = panel, Size = UDim2.new(0.72,0,0,34), Position = UDim2.new(0.05,40,0.02,0), BackgroundTransparency = 1, Text = "Fokus Ultimate Admin", Font = Enum.Font.SourceSansBold, TextSize = 20, TextColor3 = Color3.new(1,1,1)})

    -- Left: controls stack
    local leftY = 0.08
    local function addLabel(txt, y)
        return make("TextLabel", {Parent = panel, Size = UDim2.new(0.45,0,0,22), Position = UDim2.new(0.025,0,y,0), BackgroundTransparency = 1, Text = txt, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSans, TextSize = 14})
    end
    local wsLabel = addLabel("WalkSpeed:", 0.12)
    local wsBox = make("TextBox", {Parent = panel, Size = UDim2.new(0.2,0,0,30), Position = UDim2.new(0.025,0,0.16,0), PlaceholderText = "e.g. 20", BackgroundColor3 = Color3.fromRGB(45,45,45), TextColor3 = Color3.new(1,1,1)})
    local jpLabel = addLabel("JumpPower:", 0.12 + 0.04)
    local jpBox = make("TextBox", {Parent = panel, Size = UDim2.new(0.2,0,0,30), Position = UDim2.new(0.275,0,0.16,0), PlaceholderText = "e.g. 60", BackgroundColor3 = Color3.fromRGB(45,45,45), TextColor3 = Color3.new(1,1,1)})

    local applyBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.45,0,0,32), Position = UDim2.new(0.025,0,0.24,0), Text = "Apply WS/JP", BackgroundColor3 = Color3.fromRGB(70,70,70), TextColor3 = Color3.new(1,1,1)})
    local resetWSBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.215,0,0,28), Position = UDim2.new(0.025,0,0.295,0), Text = "Reset WS", BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Color3.new(1,1,1)})
    local resetJPBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.215,0,0,28), Position = UDim2.new(0.26,0,0.295,0), Text = "Reset JP", BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Color3.new(1,1,1)})

    -- Fly controls
    local flyBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.45,0,0,34), Position = UDim2.new(0.025,0,0.355,0), Text = "Toggle Fly", BackgroundColor3 = Color3.fromRGB(85,85,85), TextColor3 = Color3.new(1,1,1)})

    -- Rope controls and slider
    local ropeLenLabel = make("TextLabel", {Parent = panel, Size = UDim2.new(0.45,0,0,20), Position = UDim2.new(0.025,0,0.425,0), BackgroundTransparency = 1, Text = "Rope Length:", TextColor3 = Color3.new(1,1,1)})
    local ropeLenBox = make("TextBox", {Parent = panel, Size = UDim2.new(0.2,0,0,28), Position = UDim2.new(0.025,0,0.455,0), PlaceholderText = tostring(defaultRopeLength), BackgroundColor3 = Color3.fromRGB(45,45,45), TextColor3 = Color3.new(1,1,1)})
    local giveRopeBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.2,0,0,30), Position = UDim2.new(0.26,0,0.455,0), Text = "Give Rope", BackgroundColor3 = Color3.fromRGB(85,85,85), TextColor3 = Color3.new(1,1,1)})
    local unropeBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.45,0,0,30), Position = UDim2.new(0.025,0,0.505,0), Text = "Unrope All", BackgroundColor3 = Color3.fromRGB(140,60,60), TextColor3 = Color3.new(1,1,1)})

    -- NoClip / Godmode
    local clipBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.215,0,0,30), Position = UDim2.new(0.025,0,0.565,0), Text = "NoClip: OFF", BackgroundColor3 = Color3.fromRGB(80,40,40), TextColor3 = Color3.new(1,1,1)})
    local godBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.215,0,0,30), Position = UDim2.new(0.26,0,0.565,0), Text = "God: OFF", BackgroundColor3 = Color3.fromRGB(80,40,40), TextColor3 = Color3.new(1,1,1)})
    local godEnabled = false

    local statusLabel = make("TextLabel", {Parent = panel, Size = UDim2.new(0.95,0,0,24), Position = UDim2.new(0.025,0,0.625,0), BackgroundTransparency = 1, Text = "Status: Ready", TextColor3 = Color3.new(1,1,1)})

    -- Side player panel (list)
    local side = make("Frame", {Parent = screen, Size = UDim2.new(0,240,0,480), Position = UDim2.new(0.55,0,0.08,0), BackgroundColor3 = Color3.fromRGB(24,24,24)})
    local sideTitle = make("TextLabel", {Parent = side, Size = UDim2.new(1,0,0,34), Position = UDim2.new(0,0,0,0), Text = "Players", BackgroundColor3 = Color3.fromRGB(40,40,40), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, TextSize = 16})
    local listFrame = make("ScrollingFrame", {Parent = side, Size = UDim2.new(1,-10,0,380), Position = UDim2.new(0,5,0,40), CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 6, BackgroundTransparency = 1})
    local listLayout = Instance.new("UIListLayout", listFrame); listLayout.Padding = UDim.new(0,4)
    local selectedLabel = make("TextLabel", {Parent = side, Size = UDim2.new(1,0,0,32), Position = UDim2.new(0,0,0,428), Text = "Selected: (none)", BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1)})
    local actionRow = make("Frame", {Parent = side, Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,460), BackgroundTransparency = 1})
    local tpBtn = make("TextButton", {Parent = actionRow, Size = UDim2.new(0.33, -6, 1, 0), Position = UDim2.new(0,3,0,0), Text = "Teleport →", BackgroundColor3 = Color3.fromRGB(60,120,60), TextColor3 = Color3.new(1,1,1)})
    local killBtn = make("TextButton", {Parent = actionRow, Size = UDim2.new(0.33, -6, 1, 0), Position = UDim2.new(0.335,3,0,0), Text = "Kill", BackgroundColor3 = Color3.fromRGB(140,40,40), TextColor3 = Color3.new(1,1,1)})
    local bringBtn = make("TextButton", {Parent = actionRow, Size = UDim2.new(0.33, -6, 1, 0), Position = UDim2.new(0.67,3,0,0), Text = "Bring", BackgroundColor3 = Color3.fromRGB(60,60,140), TextColor3 = Color3.new(1,1,1)})
    local freezeBtn = make("TextButton", {Parent = side, Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,420), Text = "Freeze / Unfreeze", BackgroundColor3 = Color3.fromRGB(100,60,60), TextColor3 = Color3.new(1,1,1)})

    -- Extra controls row (set health)
    local healthBox = make("TextBox", {Parent = panel, Size = UDim2.new(0.2,0,0,30), Position = UDim2.new(0.025,0,0.69,0), PlaceholderText = "Set Health", BackgroundColor3 = Color3.fromRGB(45,45,45), TextColor3 = Color3.new(1,1,1)})
    local setHealthBtn = make("TextButton", {Parent = panel, Size = UDim2.new(0.2,0,0,30), Position = UDim2.new(0.26,0,0.69,0), Text = "Set Health", BackgroundColor3 = Color3.fromRGB(90,90,90), TextColor3 = Color3.new(1,1,1)})

    local autoRefLabel = make("TextLabel", {Parent = panel, Size = UDim2.new(0.45,0,0,20), Position = UDim2.new(0.025,0,0.745,0), BackgroundTransparency = 1, Text = "Auto-refresh (sec):", TextColor3 = Color3.new(1,1,1)})
    local autoRefBox = make("TextBox", {Parent = panel, Size = UDim2.new(0.2,0,0,28), Position = UDim2.new(0.025,0,0.78,0), PlaceholderText = "5", BackgroundColor3 = Color3.fromRGB(45,45,45), TextColor3 = Color3.new(1,1,1)})

    -- Helper: play small "evil" effect on target (particle + brief spin)
    local function playEvilEffectOnCharacter(char)
        if not char then return end
        local root = getRoot(char); if not root then return end
        -- particle
        local p = Instance.new("ParticleEmitter")
        p.Texture = "rbxassetid://241594314" -- small smoke-ish (executor context)
        p.Rate = 200; p.Lifetime = NumberRange.new(0.2,0.6); p.Speed = NumberRange.new(2,6)
        p.Rotation = NumberRange.new(0,360); p.RotSpeed = NumberRange.new(-180,180)
        p.Parent = root
        delay(0.3, function() p.Enabled = false; wait(1); p:Destroy() end)
        -- brief body angular spin
        local bav = Instance.new("BodyAngularVelocity", root)
        bav.MaxTorque = Vector3.new(9e9,9e9,9e9); bav.AngularVelocity = Vector3.new(0,8,0)
        delay(0.6, function() if bav and bav.Parent then bav:Destroy() end end)
    end

    -- UI behaviors & functions
    local playersButtons = {}
    local selected = nil
    local selectedTween = nil

    local function updateSelectedLabel()
        if selected and selected.Parent then
            selectedLabel.Text = "Selected: " .. selected.Name
        else
            selected = nil
            selectedLabel.Text = "Selected: (none)"
        end
    end

    local function refreshPlayerList()
        -- clear
        for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        playersButtons = {}
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local btn = make("TextButton", {Parent = listFrame, Size = UDim2.new(1, -8, 0, 28), BackgroundColor3 = Color3.fromRGB(55,55,55), Text = p.Name, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSans})
                btn.MouseButton1Click:Connect(function()
                    -- selection animation: pulse & highlight
                    selected = p
                    updateSelectedLabel()
                    for _,other in ipairs(listFrame:GetChildren()) do
                        if other:IsA("TextButton") then
                            TweenService:Create(other, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(55,55,55)}):Play()
                        end
                    end
                    TweenService:Create(btn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(90,40,120)}):Play()
                    pcall(function()
                        if selectedTween then selectedTween:Cancel(); selectedTween = nil end
                    end)
                    -- pulse
                    selectedTween = TweenService:Create(btn, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.2})
                    selectedTween:Play()
                end)
            end
        end
        -- adjust canvas
        local total = 0
        for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("GuiObject") then total = total + c.AbsoluteSize.Y + 4 end end
        listFrame.CanvasSize = UDim2.new(0,0,0, math.max(total,1))
        updateSelectedLabel()
    end

    -- Auto refresh
    local autoRefreshInterval = 5
    spawn(function()
        while screen.Parent do
            refreshPlayerList()
            wait(autoRefreshInterval)
        end
    end)

    -- Buttons wiring
    applyBtn.MouseButton1Click:Connect(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then
            local ws = tonumber(wsBox.Text); local jp = tonumber(jpBox.Text)
            if ws then hum.WalkSpeed = ws end
            if jp then hum.JumpPower = jp end
            originalStats[LocalPlayer] = originalStats[LocalPlayer] or {}
            originalStats[LocalPlayer].WalkSpeed = originalStats[LocalPlayer].WalkSpeed or hum.WalkSpeed
            originalStats[LocalPlayer].JumpPower = originalStats[LocalPlayer].JumpPower or hum.JumpPower
            statusLabel.Text = "Status: Applied WS/JP"
        else statusLabel.Text = "Status: Humanoid not found" end
    end)
    resetWSBtn.MouseButton1Click:Connect(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum and originalStats[LocalPlayer] and originalStats[LocalPlayer].WalkSpeed then
            hum.WalkSpeed = originalStats[LocalPlayer].WalkSpeed
        else if hum then hum.WalkSpeed = 16 end end
        statusLabel.Text = "Status: WalkSpeed reset"
    end)
    resetJPBtn.MouseButton1Click:Connect(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum and originalStats[LocalPlayer] and originalStats[LocalPlayer].JumpPower then
            hum.JumpPower = originalStats[LocalPlayer].JumpPower
        else if hum then hum.JumpPower = 50 end end
        statusLabel.Text = "Status: JumpPower reset"
    end)

    flyBtn.MouseButton1Click:Connect(function()
        if FLYING then NOFLY(); statusLabel.Text = "Status: Fly stopped" else
            if IsOnMobile then mobilefly(LocalPlayer,false) else sFLY(false) end
            statusLabel.Text = "Status: Fly started"
        end
    end)

    giveRopeBtn.MouseButton1Click:Connect(function()
        giveRopeTool()
        statusLabel.Text = "Status: RopeGun given"
    end)
    unropeBtn.MouseButton1Click:Connect(function() clearRopes(); statusLabel.Text = "Status: All ropes removed" end)

    clipBtn.MouseButton1Click:Connect(function()
        Clip(not clipEnabled)
        clipBtn.Text = clipEnabled and "NoClip: ON" or "NoClip: OFF"
        clipBtn.BackgroundColor3 = clipEnabled and Color3.fromRGB(40,80,40) or Color3.fromRGB(80,40,40)
    end)

    godBtn.MouseButton1Click:Connect(function()
        godEnabled = not godEnabled
        godBtn.Text = godEnabled and "God: ON" or "God: OFF"
        godBtn.BackgroundColor3 = godEnabled and Color3.fromRGB(40,80,40) or Color3.fromRGB(80,40,40)
        if godEnabled then
            -- naive godmode: set huge health and prevent health changes quickly
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum.MaxHealth = 1e9; hum.Health = hum.MaxHealth
            end
        else
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            if hum and originalStats[LocalPlayer] then
                hum.MaxHealth = 100; hum.Health = 100
            end
        end
    end)

    ropeLenBox.FocusLost:Connect(function(enter)
        local v = tonumber(ropeLenBox.Text)
        if v and v > 0 then defaultRopeLength = v; setRopeLength(v); statusLabel.Text = "Status: Rope length set to "..v end
    end)

    setHealthBtn.MouseButton1Click:Connect(function()
        local v = tonumber(healthBox.Text)
        if not v then statusLabel.Text = "Status: invalid health value"; return end
        if selected and selected.Character then
            setPlayerHealth(selected, v)
            statusLabel.Text = "Status: Set "..selected.Name.."'s health to "..v
            playEvilEffectOnCharacter(selected.Character)
        else
            statusLabel.Text = "Status: No target selected"
        end
    end)

    tpBtn.MouseButton1Click:Connect(function()
        if selected and selected.Character then
            teleportToPlayer(selected)
            statusLabel.Text = "Status: Teleported to "..selected.Name
            playEvilEffectOnCharacter(LocalPlayer.Character)
        else statusLabel.Text = "Status: No target selected" end
    end)

    killBtn.MouseButton1Click:Connect(function()
        if selected and selected.Character then
            killPlayer(selected)
            statusLabel.Text = "Status: Killed "..selected.Name
            playEvilEffectOnCharacter(selected.Character)
        else statusLabel.Text = "Status: No target selected" end
    end)

    bringBtn.MouseButton1Click:Connect(function()
        if selected and selected.Character then
            bringPlayerToMe(selected)
            statusLabel.Text = "Status: Brought "..selected.Name
            playEvilEffectOnCharacter(selected.Character)
        else statusLabel.Text = "Status: No target selected" end
    end)

    freezeBtn.MouseButton1Click:Connect(function()
        if selected and selected.Character then
            local root = getRoot(selected.Character)
            if root and root.Anchored then
                unfreezePlayer(selected); statusLabel.Text = "Status: Unfroze "..selected.Name
            else freezePlayer(selected); statusLabel.Text = "Status: Froze "..selected.Name end
        else statusLabel.Text = "Status: No target selected" end
    end)

    -- toggle show/hide
    topToggle.MouseButton1Click:Connect(function()
        local vis = not panel.Visible
        panel.Visible = vis; side.Visible = vis
        topToggle.Text = vis and "Hide Admin GUI" or "Show Admin GUI"
    end)

    -- auto-refresh interval box
    autoRefBox.FocusLost:Connect(function()
        local v = tonumber(autoRefBox.Text)
        if v and v > 0 then autoRefreshInterval = v; statusLabel.Text = "Status: Auto-refresh set to "..v.."s" end
    end)

    -- initial populate & periodic refresh
    refreshPlayerList()
    spawn(function()
        while screen.Parent do
            refreshPlayerList()
            wait(5)
        end
    end)

    return screen
end

-- create UI
local gui = buildUI()

-- End of Script
