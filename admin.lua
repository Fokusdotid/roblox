--[[====================================================
      Fly + NoClip + ESP GUI (PC & Mobile)
      Versi: Full Pack
======================================================]]

-- Helper
local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

cloneref = missing("function", cloneref, function(...) return ... end)

-- Services
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local LocalPlayer = Players.LocalPlayer
local IYMouse = cloneref(LocalPlayer:GetMouse())

-- Detect platform
local IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform())

-- Helpers
local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function randomString()
    local str = ""
    for i = 1, 10 do
        str = str .. string.char(math.random(97, 122))
    end
    return str
end

-- Fly variables
local FLYING = false
local QEfly = true
local iyflyspeed = 1
local vehicleflyspeed = 1
local flyKeyDown, flyKeyUp
local velocityHandlerName = randomString()
local gyroHandlerName = randomString()
local mfly1, mfly2

-- PC Fly
local function sFLY(vfly)
    repeat task.wait() until LocalPlayer and LocalPlayer.Character and getRoot(LocalPlayer.Character) and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    repeat task.wait() until IYMouse

    if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end

    local T = getRoot(LocalPlayer.Character)
    local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local SPEED = 0

    local function FLY()
        FLYING = true
        local BG = Instance.new("BodyGyro")
        local BV = Instance.new("BodyVelocity")
        BG.P = 9e4
        BG.Parent = T
        BV.Parent = T
        BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.cframe = T.CFrame
        BV.velocity = Vector3.new(0, 0, 0)
        BV.maxForce = Vector3.new(9e9, 9e9, 9e9)

        task.spawn(function()
            repeat task.wait()
                if not vfly and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
                end
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = 50
                else
                    SPEED = 0
                end
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BV.velocity = ((workspace.CurrentCamera.CFrame.LookVector * (CONTROL.F + CONTROL.B))
                        + ((workspace.CurrentCamera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p)
                        - workspace.CurrentCamera.CFrame.p)) * SPEED
                else
                    BV.velocity = Vector3.new(0, 0, 0)
                end
                BG.cframe = workspace.CurrentCamera.CFrame
            until not FLYING

            BG:Destroy()
            BV:Destroy()
            if LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
            end
        end)
    end

    flyKeyDown = IYMouse.KeyDown:Connect(function(KEY)
        KEY = KEY:lower()
        if KEY == "w" then
            CONTROL.F = (vfly and vehicleflyspeed or iyflyspeed)
        elseif KEY == "s" then
            CONTROL.B = -(vfly and vehicleflyspeed or iyflyspeed)
        elseif KEY == "a" then
            CONTROL.L = -(vfly and vehicleflyspeed or iyflyspeed)
        elseif KEY == "d" then
            CONTROL.R = (vfly and vehicleflyspeed or iyflyspeed)
        elseif QEfly and KEY == "e" then
            CONTROL.Q = (vfly and vehicleflyspeed or iyflyspeed) * 2
        elseif QEfly and KEY == "q" then
            CONTROL.E = -(vfly and vehicleflyspeed or iyflyspeed) * 2
        end
    end)

    flyKeyUp = IYMouse.KeyUp:Connect(function(KEY)
        KEY = KEY:lower()
        if KEY == "w" then
            CONTROL.F = 0
        elseif KEY == "s" then
            CONTROL.B = 0
        elseif KEY == "a" then
            CONTROL.L = 0
        elseif KEY == "d" then
            CONTROL.R = 0
        elseif KEY == "e" then
            CONTROL.Q = 0
        elseif KEY == "q" then
            CONTROL.E = 0
        end
    end)

    FLY()
end

local function NOFLY()
    FLYING = false
    if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end
    if LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

-- Mobile Fly
local function unmobilefly(speaker)
    pcall(function()
        FLYING = false
        local root = getRoot(speaker.Character)
        root:FindFirstChild(velocityHandlerName):Destroy()
        root:FindFirstChild(gyroHandlerName):Destroy()
        speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
        if mfly1 then mfly1:Disconnect() end
        if mfly2 then mfly2:Disconnect() end
    end)
end

local function mobilefly(speaker, vfly)
    unmobilefly(speaker)
    FLYING = true

    local root = getRoot(speaker.Character)
    local camera = workspace.CurrentCamera
    local v3none = Vector3.new()
    local v3zero = Vector3.new(0, 0, 0)
    local v3inf = Vector3.new(9e9, 9e9, 9e9)

    local controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

    local bv = Instance.new("BodyVelocity")
    bv.Name = velocityHandlerName
    bv.Parent = root
    bv.MaxForce = v3zero
    bv.Velocity = v3zero

    local bg = Instance.new("BodyGyro")
    bg.Name = gyroHandlerName
    bg.Parent = root
    bg.MaxTorque = v3inf
    bg.P = 1000
    bg.D = 50

    mfly2 = RunService.RenderStepped:Connect(function()
        root = getRoot(speaker.Character)
        camera = workspace.CurrentCamera
        if speaker.Character:FindFirstChildWhichIsA("Humanoid") and root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(gyroHandlerName) then
            local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
            local VelocityHandler = root:FindFirstChild(velocityHandlerName)
            local GyroHandler = root:FindFirstChild(gyroHandlerName)

            VelocityHandler.MaxForce = v3inf
            GyroHandler.MaxTorque = v3inf
            if not vfly then humanoid.PlatformStand = true end
            GyroHandler.CFrame = camera.CFrame
            VelocityHandler.Velocity = v3none

            local direction = controlModule:GetMoveVector()
            if direction.X ~= 0 then
                VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
            end
            if direction.Z ~= 0 then
                VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
            end
        end
    end)
end

-- Noclip
local Noclipping
local clipEnabled = false
local function Clip(value)
    if value then
        local player = LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()

        Noclipping = RunService.Stepped:Connect(function()
            if clipEnabled and character then
                for _, child in pairs(character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide == true then
                        child.CanCollide = false
                    end
                end
            end
        end)
    else
        if Noclipping then Noclipping:Disconnect() end
    end
end

-- ESP
local ESPEnabled = false
local function createESP(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = player.Character
end

local function removeESP(player)
    if player.Character and player.Character:FindFirstChild("ESP_Highlight") then
        player.Character:FindFirstChild("ESP_Highlight"):Destroy()
    end
end

local function toggleESP()
    ESPEnabled = not ESPEnabled
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if ESPEnabled then
                if plr.Character then createESP(plr) end
                plr.CharacterAdded:Connect(function()
                    if ESPEnabled then createESP(plr) end
                end)
            else
                removeESP(plr)
            end
        end
    end
end

--[[====================================================
      GUI
======================================================]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

-- Toggle Button (pojok kanan atas)
local toggleBtn = Instance.new("TextButton", ScreenGui)
toggleBtn.Size = UDim2.new(0,100,0,30)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Position = UDim2.new(1,-10,0,10)
toggleBtn.Text = "Hide GUI"
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggleBtn.TextColor3 = Color3.new(1,1,1)

-- FRAME UTAMA
local MainFrame = Instance.new("Frame",ScreenGui)
MainFrame.Size = UDim2.new(0,200,0,0)
MainFrame.Position = UDim2.new(0.7,0,0.15,0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
MainFrame.BorderSizePixel = 0
MainFrame.AutomaticSize = Enum.AutomaticSize.Y
MainFrame.Visible = true

local layout1 = Instance.new("UIListLayout",MainFrame)
layout1.Padding = UDim.new(0,10)
layout1.FillDirection = Enum.FillDirection.Vertical
layout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout1.SortOrder = Enum.SortOrder.LayoutOrder
local padding1 = Instance.new("UIPadding",MainFrame)
padding1.PaddingTop = UDim.new(0,10)
padding1.PaddingBottom = UDim.new(0,10)
padding1.PaddingLeft = UDim.new(0,10)
padding1.PaddingRight = UDim.new(0,10)

-- FRAME FLY
local FlyFrame = Instance.new("Frame",ScreenGui)
FlyFrame.Size = UDim2.new(0,200,0,0)
FlyFrame.Position = UDim2.new(0.7,0,0.15,0)
FlyFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
FlyFrame.BorderSizePixel = 0
FlyFrame.AutomaticSize = Enum.AutomaticSize.Y
FlyFrame.Visible = false

local layout2 = Instance.new("UIListLayout",FlyFrame)
layout2.Padding = UDim.new(0,10)
layout2.FillDirection = Enum.FillDirection.Vertical
layout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout2.SortOrder = Enum.SortOrder.LayoutOrder
local padding2 = Instance.new("UIPadding",FlyFrame)
padding2.PaddingTop = UDim.new(0,10)
padding2.PaddingBottom = UDim.new(0,10)
padding2.PaddingLeft = UDim.new(0,10)
padding2.PaddingRight = UDim.new(0,10)

-- BUTTONS MAIN
local flyMenuBtn = Instance.new("TextButton",MainFrame)
flyMenuBtn.Size = UDim2.new(1,-20,0,40)
flyMenuBtn.Text = "Fly Settings"
flyMenuBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
flyMenuBtn.TextColor3 = Color3.new(1,1,1)

local clipBtn = Instance.new("TextButton",MainFrame)
clipBtn.Size = UDim2.new(1,-20,0,40)
clipBtn.Text = "NoClip: OFF"
clipBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
clipBtn.TextColor3 = Color3.new(1,1,1)

local espBtn = Instance.new("TextButton",MainFrame)
espBtn.Size = UDim2.new(1,-20,0,40)
espBtn.Text = "ESP: OFF"
espBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
espBtn.TextColor3 = Color3.new(1,1,1)

-- BUTTONS FLYFRAME
local backBtn = Instance.new("TextButton",FlyFrame)
backBtn.Size = UDim2.new(1,-20,0,40)
backBtn.Text = "< Back"
backBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
backBtn.TextColor3 = Color3.new(1,1,1)

local flyToggleBtn = Instance.new("TextButton",FlyFrame)
flyToggleBtn.Size = UDim2.new(1,-20,0,40)
flyToggleBtn.Text = "Fly: OFF"
flyToggleBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
flyToggleBtn.TextColor3 = Color3.new(1,1,1)

local flySpeedBox = Instance.new("TextBox",FlyFrame)
flySpeedBox.Size = UDim2.new(1,-20,0,40)
flySpeedBox.PlaceholderText = "Speed (default 1)"
flySpeedBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
flySpeedBox.TextColor3 = Color3.new(1,1,1)

-- LOGIC
toggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    FlyFrame.Visible = false
    toggleBtn.Text = MainFrame.Visible and "Hide GUI" or "Show GUI"
end)

flyMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FlyFrame.Visible = true
end)

backBtn.MouseButton1Click:Connect(function()
    FlyFrame.Visible = false
    MainFrame.Visible = true
end)

clipBtn.MouseButton1Click:Connect(function()
    clipEnabled = not clipEnabled
    if clipEnabled then
        clipBtn.Text = "NoClip: ON"
        clipBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
        Clip(true)
    else
        clipBtn.Text = "NoClip: OFF"
        clipBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
        Clip(false)
    end
end)

espBtn.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    if ESPEnabled then
        espBtn.Text = "ESP: ON"
        espBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
    else
        espBtn.Text = "ESP: OFF"
        espBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
    end
    toggleESP()
end)

flyToggleBtn.MouseButton1Click:Connect(function()
    if FLYING then
        if IsOnMobile then unmobilefly(LocalPlayer) else NOFLY() end
        flyToggleBtn.Text = "Fly: OFF"
        flyToggleBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
    else
        local val = tonumber(flySpeedBox.Text)
        if val and val > 0 then iyflyspeed = val else iyflyspeed = 1 end
        if IsOnMobile then mobilefly(LocalPlayer,false) else sFLY(false) end
        flyToggleBtn.Text = "Fly: ON"
        flyToggleBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
    end
end)