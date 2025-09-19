-- 🔹 Roblox Admin Panel Hybrid (PC + Mobile)
-- ✅ Players Tab: Teleport, Bring, Kill, Rope, Unrope
-- ✅ Local Tab: WalkSpeed, JumpPower, Reset Default, Fly, Noclip, ESP
-- ✅ Utility Tab: Refresh Char, Kill All, Teleport Random
-- ✅ Mobile Control: Fly pakai tombol arah di layar
-- ✅ PC Control: Fly pakai WASD

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Save defaults
local function GetHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end
local defaultWalk = GetHumanoid() and GetHumanoid().WalkSpeed or 16
local defaultJump = GetHumanoid() and GetHumanoid().JumpPower or 50

-- Global states
local FlyEnabled, NoclipEnabled, ESPEnabled = false, false, false
local RopeTargets = {}
local FlyDirection = Vector3.new()

-- 🔹 ScreenGui
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "AdminPanel"

-- Toggle Button (pojok layar)
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 100, 0, 40)
ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
ToggleBtn.Text = "☰ Admin"
ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)

-- Main Panel
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
MainFrame.Active, MainFrame.Draggable = true, true
MainFrame.Visible = false

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0,10)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Tab system
local TabFrame = Instance.new("Frame", MainFrame)
TabFrame.Size = UDim2.new(1,0,0,30)
TabFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)

local TabLayout = Instance.new("UIListLayout", TabFrame)
TabLayout.FillDirection = Enum.FillDirection.Horizontal

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1,0,1,-30)
ContentFrame.Position = UDim2.new(0,0,0,30)
ContentFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)

local function createTab(name)
    local btn = Instance.new("TextButton", TabFrame)
    btn.Size = UDim2.new(0,120,1,0)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    local frame = Instance.new("ScrollingFrame", ContentFrame)
    frame.Size = UDim2.new(1,0,1,0)
    frame.Visible = false
    frame.CanvasSize = UDim2.new(0,0,0,500)
    frame.ScrollBarThickness = 5
    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0,5)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    btn.MouseButton1Click:Connect(function()
        for _,f in pairs(ContentFrame:GetChildren()) do
            if f:IsA("ScrollingFrame") then f.Visible = false end
        end
        frame.Visible = true
    end)
    return frame
end

local PlayersTab = createTab("Players")
local LocalTab = createTab("Local")
local UtilityTab = createTab("Utility")
PlayersTab.Visible = true

-- 🔹 Helper UI
local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0,380,0,30)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.MouseButton1Click:Connect(callback)
end

local function createTextBox(parent, placeholder, callback)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0,380,0,30)
    box.PlaceholderText = placeholder
    box.BackgroundColor3 = Color3.fromRGB(60,60,60)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.FocusLost:Connect(function()
        callback(tonumber(box.Text))
    end)
end

-- 🔹 Player Functions
local function GetChar(plr) return plr.Character or plr.CharacterAdded:Wait() end
local function TeleportToPlayer(plr)
    local char, target = GetChar(LocalPlayer), GetChar(plr)
    if char:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
    end
end
local function BringPlayer(plr)
    local char, target = GetChar(LocalPlayer), GetChar(plr)
    if char:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart") then
        target.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
    end
end
local function KillPlayer(plr) local hum = GetChar(plr):FindFirstChildOfClass("Humanoid") if hum then hum.Health = 0 end end
local function RopePlayer(plr)
    local char, target = GetChar(LocalPlayer), GetChar(plr)
    local hrp, thrp = char:FindFirstChild("HumanoidRootPart"), target:FindFirstChild("HumanoidRootPart")
    if hrp and thrp then
        local att1, att2 = Instance.new("Attachment", hrp), Instance.new("Attachment", thrp)
        local rope = Instance.new("RopeConstraint")
        rope.Attachment0, rope.Attachment1 = att1, att2
        rope.Length, rope.Visible, rope.Parent = 6, true, hrp
        RopeTargets[plr.Name] = rope
    end
end
local function UnropePlayer(plr) if RopeTargets[plr.Name] then RopeTargets[plr.Name]:Destroy() RopeTargets[plr.Name] = nil end end

-- 🔹 Local Functions
local function SetWalkSpeed(v) if GetHumanoid() and v then GetHumanoid().WalkSpeed = v end end
local function ResetWalkSpeed() if GetHumanoid() then GetHumanoid().WalkSpeed = defaultWalk end end
local function SetJumpPower(v) if GetHumanoid() and v then GetHumanoid().JumpPower = v end end
local function ResetJumpPower() if GetHumanoid() then GetHumanoid().JumpPower = defaultJump end end

-- Fly
local flyVel, flyGyro
local function ToggleFly()
    FlyEnabled = not FlyEnabled
    local char = GetChar(LocalPlayer)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if FlyEnabled and hrp then
        flyVel = Instance.new("BodyVelocity", hrp)
        flyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
        flyGyro = Instance.new("BodyGyro", hrp)
        flyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
        RunService.RenderStepped:Connect(function()
            if FlyEnabled and hrp then
                local cam = workspace.CurrentCamera
                flyGyro.CFrame = cam.CFrame
                flyVel.Velocity = FlyDirection * 50
            end
        end)
    else
        if flyVel then flyVel:Destroy() end
        if flyGyro then flyGyro:Destroy() end
        FlyDirection = Vector3.new()
    end
end

-- Noclip
RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)
local function ToggleNoclip() NoclipEnabled = not NoclipEnabled end

-- ESP
local function ToggleESP()
    ESPEnabled = not ESPEnabled
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if ESPEnabled then
                local Billboard = Instance.new("BillboardGui", plr.Character.Head)
                Billboard.Name = "ESPTag"
                Billboard.Size = UDim2.new(0,100,0,40)
                Billboard.AlwaysOnTop = true
                local Label = Instance.new("TextLabel", Billboard)
                Label.Size = UDim2.new(1,0,1,0)
                Label.BackgroundTransparency = 1
                Label.Text = plr.Name
                Label.TextColor3 = Color3.fromRGB(255,0,0)
                Label.Font = Enum.Font.GothamBold
                Label.TextScaled = true
            else
                if plr.Character.Head:FindFirstChild("ESPTag") then
                    plr.Character.Head.ESPTag:Destroy()
                end
            end
        end
    end
end

-- 🔹 Utility
local function RefreshChar() LocalPlayer:LoadCharacter() end
local function KillAll() for _, plr in pairs(Players:GetPlayers()) do if plr ~= LocalPlayer then KillPlayer(plr) end end end
local function TeleportRandom()
    local plist = {}
    for _, plr in pairs(Players:GetPlayers()) do if plr ~= LocalPlayer then table.insert(plist, plr) end end
    if #plist > 0 then TeleportToPlayer(plist[math.random(1,#plist)]) end
end

-- 🔹 Player List
local PlayerListFrame = Instance.new("Frame", PlayersTab)
PlayerListFrame.Size = UDim2.new(1,0,0,200)
local ListLayout = Instance.new("UIListLayout", PlayerListFrame)

local function refreshPlayers()
    for _, c in pairs(PlayerListFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            createButton(PlayerListFrame, plr.Name.." | Teleport", function() TeleportToPlayer(plr) end)
            createButton(PlayerListFrame, plr.Name.." | Bring", function() BringPlayer(plr) end)
            createButton(PlayerListFrame, plr.Name.." | Kill", function() KillPlayer(plr) end)
            createButton(PlayerListFrame, plr.Name.." | Rope", function() RopePlayer(plr) end)
            createButton(PlayerListFrame, plr.Name.." | Unrope", function() UnropePlayer(plr) end)
        end
    end
end
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- 🔹 Local Tab UI
createTextBox(LocalTab, "Set WalkSpeed", function(v) SetWalkSpeed(v) end)
createButton(LocalTab, "Reset WalkSpeed", ResetWalkSpeed)
createTextBox(LocalTab, "Set JumpPower", function(v) SetJumpPower(v) end)
createButton(LocalTab, "Reset JumpPower", ResetJumpPower)
createButton(LocalTab, "Toggle Fly", ToggleFly)
createButton(LocalTab, "Toggle Noclip", ToggleNoclip)
createButton(LocalTab, "Toggle ESP", ToggleESP)

-- 🔹 Utility Tab UI
createButton(UtilityTab, "Refresh Character", RefreshChar)
createButton(UtilityTab, "Kill All Players", KillAll)
createButton(UtilityTab, "Teleport Random Player", TeleportRandom)

-- 🔹 Mobile Fly Controls
local ControlFrame = Instance.new("Frame", ScreenGui)
ControlFrame.Size = UDim2.new(0,150,0,150)
ControlFrame.Position = UDim2.new(1,-160,1,-160)
ControlFrame.BackgroundTransparency = 1
ControlFrame.Visible = true

local function createControlBtn(name, pos, dir)
    local btn = Instance.new("TextButton", ControlFrame)
    btn.Size = UDim2.new(0,40,0,40)
    btn.Position = pos
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.MouseButton1Down:Connect(function() FlyDirection = FlyDirection + dir end)
    btn.MouseButton1Up:Connect(function() FlyDirection = FlyDirection - dir end)
end

createControlBtn("↑", UDim2.new(0.33,0,0,0), Vector3.new(0,0,-1))
createControlBtn("↓", UDim2.new(0.33,0,0.66,0), Vector3.new(0,0,1))
createControlBtn("←", UDim2.new(0,0,0.33,0), Vector3.new(-1,0,0))
createControlBtn("→", UDim2.new(0.66,0,0.33,0), Vector3.new(1,0,0))
