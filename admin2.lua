--[[====================================================
      Fly + NoClip + Player Panel (PC & Mobile) by FokusID
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

--[[====================================================
      FLY SYSTEM (PC & Mobile)
======================================================]]
local FLYING = false
local QEfly = true
local iyflyspeed = 1
local vehicleflyspeed = 1
local flyKeyDown, flyKeyUp
local velocityHandlerName = "VelHandler"
local gyroHandlerName = "GyroHandler"
local mfly1, mfly2

-- ... (kode Fly + NoClip kamu tetap sama, tidak aku hapus) ...

--[[====================================================
      GUI UTAMA
======================================================]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

-- Toggle Button
local toggleBtn = Instance.new("TextButton", ScreenGui)
toggleBtn.Size = UDim2.new(0,100,0,30)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Position = UDim2.new(1,-10,0,10)
toggleBtn.Text = "Hide GUI"
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggleBtn.TextColor3 = Color3.new(1,1,1)

-- Frame utama
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,220,0,160)
Frame.Position = UDim2.new(0.7,0,0.15,0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

-- Tombol Fly
local flyBtn = Instance.new("TextButton", Frame)
flyBtn.Size = UDim2.new(1,-20,0,30)
flyBtn.Position = UDim2.new(0,10,0,10)
flyBtn.Text = "Fly Toggle"
flyBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)

-- Input Speed
local speedBox = Instance.new("TextBox", Frame)
speedBox.Size = UDim2.new(1,-20,0,30)
speedBox.Position = UDim2.new(0,10,0,50)
speedBox.PlaceholderText = "Speed"
speedBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
speedBox.TextColor3 = Color3.new(1,1,1)

-- Tombol NoClip
local clipBtn = Instance.new("TextButton", Frame)
clipBtn.Size = UDim2.new(1,-20,0,30)
clipBtn.Position = UDim2.new(0,10,0,90)
clipBtn.Text = "NoClip: OFF"
clipBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
clipBtn.TextColor3 = Color3.new(1,1,1)

--[[====================================================
      PANEL PLAYER LIST
======================================================]]
local PlayerFrame = Instance.new("Frame", ScreenGui)
PlayerFrame.Size = UDim2.new(0,220,0,300)
PlayerFrame.Position = UDim2.new(0.02,0,0.2,0)
PlayerFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)

-- Search Box
local searchBox = Instance.new("TextBox", PlayerFrame)
searchBox.Size = UDim2.new(1,-20,0,30)
searchBox.Position = UDim2.new(0,10,0,10)
searchBox.PlaceholderText = "Search player..."
searchBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
searchBox.TextColor3 = Color3.new(1,1,1)

-- Scroll list
local scroll = Instance.new("ScrollingFrame", PlayerFrame)
scroll.Size = UDim2.new(1,-20,1,-50)
scroll.Position = UDim2.new(0,10,0,50)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 0.2
scroll.BackgroundColor3 = Color3.fromRGB(25,25,25)

-- Template Button
local function CreatePlayerButton(plr)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,30)
    btn.Text = plr.Name
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.new(1,1,1)

    btn.MouseButton1Click:Connect(function()
        local menu = Instance.new("Frame", btn)
        menu.Size = UDim2.new(1,0,0,80)
        menu.Position = UDim2.new(0,0,1,0)
        menu.BackgroundColor3 = Color3.fromRGB(15,15,15)

        local tp = Instance.new("TextButton", menu)
        tp.Size = UDim2.new(0.5,-5,0,25)
        tp.Position = UDim2.new(0,5,0,5)
        tp.Text = "TP"
        tp.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character:MoveTo(plr.Character.HumanoidRootPart.Position + Vector3.new(2,0,0))
            end
        end)

        local bring = Instance.new("TextButton", menu)
        bring.Size = UDim2.new(0.5,-5,0,25)
        bring.Position = UDim2.new(0.5,0,0,5)
        bring.Text = "Bring"
        bring.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(2,0,0))
            end
        end)

        local rope = Instance.new("TextButton", menu)
        rope.Size = UDim2.new(0.5,-5,0,25)
        rope.Position = UDim2.new(0,5,0,35)
        rope.Text = "Rope"
        rope.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and plr.Character then
                local hrp1 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local hrp2 = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp1 and hrp2 then
                    local att1 = Instance.new("Attachment", hrp1)
                    local att2 = Instance.new("Attachment", hrp2)
                    local rope = Instance.new("RopeConstraint")
                    rope.Attachment0 = att1
                    rope.Attachment1 = att2
                    rope.Length = 6
                    rope.Visible = true
                    rope.Parent = hrp1
                end
            end
        end)

        local esp = Instance.new("TextButton", menu)
        esp.Size = UDim2.new(0.5,-5,0,25)
        esp.Position = UDim2.new(0.5,0,0,35)
        esp.Text = "ESP"
        esp.MouseButton1Click:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("Head") then
                if not plr.Character.Head:FindFirstChild("ESPTag") then
                    local Billboard = Instance.new("BillboardGui", plr.Character.Head)
                    Billboard.Name = "ESPTag"
                    Billboard.Size = UDim2.new(0,80,0,20)
                    Billboard.AlwaysOnTop = true
                    local Label = Instance.new("TextLabel", Billboard)
                    Label.Size = UDim2.new(1,0,1,0)
                    Label.BackgroundTransparency = 1
                    Label.Text = plr.Name
                    Label.TextColor3 = Color3.fromRGB(255,0,0)
                    Label.Font = Enum.Font.Code -- kecil
                    Label.TextScaled = true
                else
                    plr.Character.Head.ESPTag:Destroy()
                end
            end
        end)
    end)

    return btn
end

-- Refresh player list
local function RefreshPlayers()
    scroll:ClearAllChildren()
    local y = 0
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (searchBox.Text == "" or plr.Name:lower():find(searchBox.Text:lower())) then
            local btn = CreatePlayerButton(plr)
            btn.Position = UDim2.new(0,0,0,y)
            btn.Parent = scroll
            y = y + 35
        end
    end
    scroll.CanvasSize = UDim2.new(0,0,0,y)
end

Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)
searchBox:GetPropertyChangedSignal("Text"):Connect(RefreshPlayers)
RefreshPlayers()

-- Hide/Show
local visible = true
toggleBtn.MouseButton1Click:Connect(function()
    visible = not visible
    Frame.Visible = visible
    PlayerFrame.Visible = visible
    toggleBtn.Text = visible and "Hide GUI" or "Show GUI"
end)

-- Drag Frame
local UIS = game:GetService("UserInputService")
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)