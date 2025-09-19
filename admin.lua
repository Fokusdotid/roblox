--========================================================
-- Admin Panel with Local (Fly/Noclip/ESP) + Players (TP/Bring/Rope/Spectate)
--========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Helpers
local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

--========================================================
-- Fly System
--========================================================
local FLYING = false
local flyVel, flyGyro
local flySpeed = 60

local function startFly()
    local hrp = getRoot(LocalPlayer.Character)
    if not hrp then return end
    FLYING = true

    flyVel = Instance.new("BodyVelocity", hrp)
    flyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyVel.Velocity = Vector3.new()

    flyGyro = Instance.new("BodyGyro", hrp)
    flyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyGyro.CFrame = workspace.CurrentCamera.CFrame

    RunService.RenderStepped:Connect(function()
        if not FLYING or not hrp then return end
        local cam = workspace.CurrentCamera
        flyGyro.CFrame = cam.CFrame
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        flyVel.Velocity = move * flySpeed
    end)
end

local function stopFly()
    FLYING = false
    if flyVel then flyVel:Destroy() flyVel=nil end
    if flyGyro then flyGyro:Destroy() flyGyro=nil end
end

--========================================================
-- Noclip
--========================================================
local noclip = false
RunService.Stepped:Connect(function()
    if noclip and LocalPlayer.Character then
        for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

--========================================================
-- ESP (global)
--========================================================
local espEnabled = false
local function setESP(state)
    espEnabled = state
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if state then
                if not plr.Character.Head:FindFirstChild("ESPTag") then
                    local Billboard = Instance.new("BillboardGui", plr.Character.Head)
                    Billboard.Name = "ESPTag"
                    Billboard.Size = UDim2.new(0,80,0,20)
                    Billboard.AlwaysOnTop = true
                    local Label = Instance.new("TextLabel", Billboard)
                    Label.Size = UDim2.new(1,0,1,0)
                    Label.BackgroundTransparency = 1
                    Label.Text = plr.Name
                    Label.TextColor3 = Color3.fromRGB(0,255,0)
                    Label.Font = Enum.Font.Code
                    Label.TextScaled = true
                end
            else
                if plr.Character.Head:FindFirstChild("ESPTag") then
                    plr.Character.Head.ESPTag:Destroy()
                end
            end
        end
    end
end
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if espEnabled then task.wait(1) setESP(true) end
    end)
end)

--========================================================
-- Spectator
--========================================================
local spectating = nil
RunService.RenderStepped:Connect(function()
    if spectating and spectating.Character and spectating.Character:FindFirstChild("Head") then
        Camera.CameraSubject = spectating.Character:FindFirstChild("Head")
    elseif not spectating then
        Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    end
end)

--========================================================
-- GUI
--========================================================
local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.ResetOnSpawn = false

-- Main Frame
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,320,0,400)
main.Position = UDim2.new(0.3,0,0.2,0)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)

-- Tabs
local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1,0,0,30)
tabBar.BackgroundColor3 = Color3.fromRGB(40,40,40)

local tabLocal = Instance.new("TextButton", tabBar)
tabLocal.Size = UDim2.new(0.5,0,1,0)
tabLocal.Text = "Local"

local tabPlayers = Instance.new("TextButton", tabBar)
tabPlayers.Size = UDim2.new(0.5,0,1,0)
tabPlayers.Position = UDim2.new(0.5,0,0,0)
tabPlayers.Text = "Players"

-- Pages
local localPage = Instance.new("Frame", main)
localPage.Size = UDim2.new(1,0,1,-30)
localPage.Position = UDim2.new(0,0,0,30)
localPage.BackgroundColor3 = Color3.fromRGB(30,30,30)

local playersPage = localPage:Clone()
playersPage.Parent = main
playersPage.Visible = false

tabLocal.MouseButton1Click:Connect(function()
    localPage.Visible = true
    playersPage.Visible = false
end)
tabPlayers.MouseButton1Click:Connect(function()
    localPage.Visible = false
    playersPage.Visible = true
end)

-- Local Controls
local flyBtn = Instance.new("TextButton", localPage)
flyBtn.Size = UDim2.new(1,-20,0,40)
flyBtn.Position = UDim2.new(0,10,0,10)
flyBtn.Text = "Fly: OFF"
flyBtn.MouseButton1Click:Connect(function()
    if FLYING then stopFly() flyBtn.Text="Fly: OFF"
    else startFly() flyBtn.Text="Fly: ON" end
end)

local speedBox = Instance.new("TextBox", localPage)
speedBox.Size = UDim2.new(1,-20,0,30)
speedBox.Position = UDim2.new(0,10,0,60)
speedBox.PlaceholderText = "Fly Speed"
speedBox.Text = ""
speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text)
    if val then flySpeed = val end
end)

local noclipBtn = Instance.new("TextButton", localPage)
noclipBtn.Size = UDim2.new(1,-20,0,40)
noclipBtn.Position = UDim2.new(0,10,0,100)
noclipBtn.Text = "NoClip: OFF"
noclipBtn.MouseButton1Click:Connect(function()
    noclip = not noclip
    noclipBtn.Text = noclip and "NoClip: ON" or "NoClip: OFF"
end)

local espBtn = Instance.new("TextButton", localPage)
espBtn.Size = UDim2.new(1,-20,0,40)
espBtn.Position = UDim2.new(0,10,0,150)
espBtn.Text = "ESP: OFF"
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    setESP(espEnabled)
    espBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
end)

-- Players Controls
local searchBox = Instance.new("TextBox", playersPage)
searchBox.Size = UDim2.new(1,-20,0,30)
searchBox.Position = UDim2.new(0,10,0,10)
searchBox.PlaceholderText = "Search Player"

local scroll = Instance.new("ScrollingFrame", playersPage)
scroll.Size = UDim2.new(1,-20,1,-50)
scroll.Position = UDim2.new(0,10,0,50)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 6

-- Create Player Button
local function createPlayerBtn(plr)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,30)
    btn.Text = plr.Name
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)

    btn.MouseButton1Click:Connect(function()
        local opts = Instance.new("Frame", btn)
        opts.Size = UDim2.new(1,0,0,95)
        opts.Position = UDim2.new(0,0,1,0)
        opts.BackgroundColor3 = Color3.fromRGB(15,15,15)

        local tp = Instance.new("TextButton", opts)
        tp.Size = UDim2.new(0.5,-5,0,25)
        tp.Position = UDim2.new(0,5,0,5)
        tp.Text = "TP"
        tp.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and plr.Character then
                local hrp1,hrp2=getRoot(LocalPlayer.Character),getRoot(plr.Character)
                if hrp1 and hrp2 then hrp1.CFrame=hrp2.CFrame+Vector3.new(2,0,0) end
            end
        end)

        local bring = Instance.new("TextButton", opts)
        bring.Size = UDim2.new(0.5,-5,0,25)
        bring.Position = UDim2.new(0.5,0,0,5)
        bring.Text = "Bring"
        bring.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and plr.Character then
                local hrp1,hrp2=getRoot(LocalPlayer.Character),getRoot(plr.Character)
                if hrp1 and hrp2 then hrp2.CFrame=hrp1.CFrame+Vector3.new(2,0,0) end
            end
        end)

        local rope = Instance.new("TextButton", opts)
        rope.Size = UDim2.new(0.5,-5,0,25)
        rope.Position = UDim2.new(0,5,0,35)
        rope.Text = "Rope"
        rope.MouseButton1Click:Connect(function()
            local hrp1,hrp2=getRoot(LocalPlayer.Character),getRoot(plr.Character)
            if hrp1 and hrp2 then
                local att1=Instance.new("Attachment",hrp1)
                local att2=Instance.new("Attachment",hrp2)
                local rope=Instance.new("RopeConstraint",hrp1)
                rope.Attachment0=att1
                rope.Attachment1=att2
                rope.Length=6
                rope.Visible=true
            end
        end)

        local spectate = Instance.new("TextButton", opts)
        spectate.Size = UDim2.new(0.5,-5,0,25)
        spectate.Position = UDim2.new(0.5,0,0,35)
        spectate.Text = "Spectate"
        spectate.MouseButton1Click:Connect(function()
            if spectating == plr then
                spectating = nil
                spectate.Text = "Spectate"
            else
                spectating = plr
                spectate.Text = "Stop Spectate"
            end
        end)
    end)
    return btn
end

-- Refresh List
local function refreshList()
    scroll:ClearAllChildren()
    local y=0
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and (searchBox.Text=="" or plr.Name:lower():find(searchBox.Text:lower())) then
            local b=createPlayerBtn(plr)
            b.Position=UDim2.new(0,0,0,y)
            b.Parent=scroll
            y=y+35
        end
    end
    scroll.CanvasSize=UDim2.new(0,0,0,y)
end
Players.PlayerAdded:Connect(refreshList)
Players.PlayerRemoving:Connect(refreshList)
searchBox:GetPropertyChangedSignal("Text"):Connect(refreshList)
refreshList()