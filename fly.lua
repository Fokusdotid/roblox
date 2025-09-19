--[[====================================================
      Fly + NoClip GUI (PC & Mobile) by FokusID
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
            -- ✅ Fix maju/mundur ketuker
            if direction.X > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.X < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.Z > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.Z < 0 then
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
toggleBtn.Text = "Hide Fly GUI"
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggleBtn.TextColor3 = Color3.new(1,1,1)

-- Frame utama
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,200,0,160)
Frame.Position = UDim2.new(0.7,0,0.15,0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0

-- Tombol Fly
local flyBtn = Instance.new("TextButton", Frame)
flyBtn.Size = UDim2.new(1,-20,0,40)
flyBtn.Position = UDim2.new(0,10,0,10)
flyBtn.Text = "Fly Toggle"
flyBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)

-- Input Speed
local speedBox = Instance.new("TextBox", Frame)
speedBox.Size = UDim2.new(1,-20,0,40)
speedBox.Position = UDim2.new(0,10,0,60)
speedBox.PlaceholderText = "Speed (default 1)"
speedBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
speedBox.TextColor3 = Color3.new(1,1,1)

-- Tombol NoClip
local clipBtn = Instance.new("TextButton", Frame)
clipBtn.Size = UDim2.new(1,-20,0,40)
clipBtn.Position = UDim2.new(0,10,0,110)
clipBtn.Text = "NoClip: OFF"
clipBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
clipBtn.TextColor3 = Color3.new(1,1,1)

-- Hide/Show logic
local visible = true
toggleBtn.MouseButton1Click:Connect(function()
    visible = not visible
    Frame.Visible = visible
    toggleBtn.Text = visible and "Hide Fly GUI" or "Show Fly GUI"
end)

-- Drag logic
local UIS = game:GetService("UserInputService")
local dragging, dragStart, startPos

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--[[====================================================
      Fly Button Action
======================================================]]
flyBtn.MouseButton1Click:Connect(function()
    if FLYING then
        if IsOnMobile then
            unmobilefly(LocalPlayer)
        else
            NOFLY()
        end
    else
        local val = tonumber(speedBox.Text)
        if val and val > 0 then
            iyflyspeed = val
        else
            iyflyspeed = 1
        end
        if IsOnMobile then
            mobilefly(LocalPlayer, false)
        else
            sFLY(false)
        end
    end
end)

--[[====================================================
      NoClip Button Action
======================================================]]
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

--[[====================================================
      ESP System
======================================================]]
local espEnabled = false
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "ESP_Objects"

local function createESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_"..player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0,200,0,50)
    billboard.StudsOffset = Vector3.new(0,3,0)
    billboard.Parent = espFolder

    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1,0,1,0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1,0,0)
    text.TextStrokeTransparency = 0
    text.Text = player.Name
    text.Font = Enum.Font.SourceSansBold
    text.TextScaled = true

    billboard.Adornee = hrp
end

local function removeESP(player)
    for _, obj in pairs(espFolder:GetChildren()) do
        if obj.Name == "ESP_"..player.Name then
            obj:Destroy()
        end
    end
end

local function toggleESP(state)
    espEnabled = state
    if state then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                createESP(p)
            end
        end
    else
        espFolder:ClearAllChildren()
    end
end

-- Auto refresh ESP saat ada player masuk/keluar
Players.PlayerAdded:Connect(function(p)
    if espEnabled then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            createESP(p)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
end)

-- Tombol ESP
local espBtn = Instance.new("TextButton", Frame)
espBtn.Size = UDim2.new(1,-20,0,40)
espBtn.Position = UDim2.new(0,10,0,160) -- taruh di bawah NoClip
espBtn.Text = "ESP: OFF"
espBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
espBtn.TextColor3 = Color3.new(1,1,1)

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        espBtn.Text = "ESP: ON"
        espBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
        toggleESP(true)
    else
        espBtn.Text = "ESP: OFF"
        espBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
        toggleESP(false)
    end
end)