--[[====================================================
  FULL Admin Panel (Fly + NoClip + Player Picker + ESP + Admin features)
  - PC & Mobile friendly
  - Spectate, Teleport, Bring, Kill, Rope/Unrope
  - Global ESP toggle (small font)
  - WalkSpeed / JumpPower local controls + reset
  - Kill All, Teleport Random
  - Tries server remotes if available (ReplicatedStorage), else fallback
  Author: merged & extended from user script
======================================================]]

-- SAFETY: run as LocalScript via executor
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- Try to find common remotes (optional)
local function findRemote(name)
    local ok, v = pcall(function() return ReplicatedStorage:FindFirstChild(name) end)
    if ok and v and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
    return nil
end
local Remote_Rope = findRemote("RopePlayer")
local Remote_UnropeAll = findRemote("UnropeAll")
local Remote_AdminAction = findRemote("AdminAction")
local Remote_SendNotification = findRemote("SendNotification")

-- small helpers
local function safeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok, res
end

local function getRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function create(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

-- state
local STATE = {
    flying = false,
    clipEnabled = false,
    espEnabled = false,
    spectating = nil,
    ropeObjects = {}, -- map player.Name -> {rope, att1, att2}
}

-- store local defaults for reset
local function getLocalHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end
local LOCAL_DEFAULTS = {
    WalkSpeed = (getLocalHumanoid() and getLocalHumanoid().WalkSpeed) or 16,
    JumpPower = (getLocalHumanoid() and getLocalHumanoid().JumpPower) or 50
}

-- CLEANUP previous GUI (prevent duplicate)
local EXISTING = LocalPlayer:FindFirstChildOfClass("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Aguz_Admin_Panel")
if EXISTING then EXISTING:Destroy() end

-- MAIN GUI
local screenGui = create("ScreenGui", {Name="Aguz_Admin_Panel", ResetOnSpawn=false})
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.IgnoreGuiInset = true

-- Main container
local main = create("Frame", {
    Parent = screenGui,
    Name = "Main",
    Size = UDim2.new(0,420,0,420),
    Position = UDim2.new(0.18,0,0.1,0),
    BackgroundColor3 = Color3.fromRGB(24,24,24),
    BorderSizePixel = 0,
})
create("UICorner", {Parent = main, CornerRadius = UDim.new(0,8)})

-- Header
local header = create("Frame", {Parent=main, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
local title = create("TextLabel", {Parent=header, Position=UDim2.new(0,12,0,0), Size=UDim2.new(0.6,0,1,0),
    BackgroundTransparency=1, Text="🔧 Aguz Admin Panel", Font=Enum.Font.SourceSansBold, TextSize=18, TextColor3=Color3.fromRGB(240,240,240), TextXAlignment=Enum.TextXAlignment.Left})
local closeBtn = create("TextButton", {Parent=header, Size=UDim2.new(0,64,0,26), Position=UDim2.new(1,-76,0.12,0), Text="Close", Font=Enum.Font.SourceSans, TextSize=14})
closeBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
closeBtn.TextColor3 = Color3.fromRGB(250,250,250)
create("UICorner", {Parent=closeBtn, CornerRadius=UDim.new(0,6)})

local togglePickerBtn = create("TextButton", {Parent=header, Size=UDim2.new(0,120,0,26), Position=UDim2.new(1,-210,0.12,0), Text="Pilih Player", Font=Enum.Font.SourceSans, TextSize=14})
togglePickerBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
togglePickerBtn.TextColor3 = Color3.fromRGB(240,240,240)
create("UICorner", {Parent=togglePickerBtn, CornerRadius=UDim.new(0,6)})

-- Left column: local controls (stack)
local left = create("Frame", {Parent=main, Size=UDim2.new(0,200,1,-46), Position=UDim2.new(0,12,0,46), BackgroundTransparency=1})
local right = create("Frame", {Parent=main, Size=UDim2.new(1,-236,1,-46), Position=UDim2.new(0,224,0,46), BackgroundTransparency=1})

-- Local controls
local function makeLabel(parent, y, text)
    return create("TextLabel", {Parent=parent, Position=UDim2.new(0,6,0,y), Size=UDim2.new(1,-12,0,20),
        BackgroundTransparency=1, Text=text, Font=Enum.Font.SourceSans, TextSize=14, TextColor3=Color3.fromRGB(220,220,220), TextXAlignment=Enum.TextXAlignment.Left})
end

makeLabel(left, 0, "Local Controls")
local flyBtn = create("TextButton", {Parent=left, Position=UDim2.new(0,6,0,28), Size=UDim2.new(1,-12,0,32), Text="Fly: OFF", Font=Enum.Font.SourceSans})
create("UICorner", {Parent=flyBtn, CornerRadius=UDim.new(0,6)})
flyBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
local speedBox = create("TextBox", {Parent=left, Position=UDim2.new(0,6,0,68), Size=UDim2.new(1,-12,0,28), PlaceholderText="Fly speed (1)", Text="", Font=Enum.Font.SourceSans})
speedBox.BackgroundColor3 = Color3.fromRGB(44,44,44)
speedBox.TextColor3 = Color3.fromRGB(230,230,230)
local noclipBtn = create("TextButton", {Parent=left, Position=UDim2.new(0,6,0,106), Size=UDim2.new(1,-12,0,32), Text="NoClip: OFF", Font=Enum.Font.SourceSans})
noclipBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
create("UICorner", {Parent=noclipBtn, CornerRadius=UDim.new(0,6)})

-- ESP global button (per request: placed under player-picker)
local espGlobalBtn = create("TextButton", {Parent=left, Position=UDim2.new(0,6,0,146), Size=UDim2.new(1,-12,0,30), Text="ESP: OFF", Font=Enum.Font.SourceSans})
espGlobalBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
create("UICorner", {Parent=espGlobalBtn, CornerRadius=UDim.new(0,6)})

-- WalkSpeed & JumpPower controls
makeLabel(left, 190, "Local Movement")
local wsBox = create("TextBox", {Parent=left, Position=UDim2.new(0,6,0,214), Size=UDim2.new(1,-12,0,26), PlaceholderText="Set WalkSpeed (e.g. 50)"})
wsBox.BackgroundColor3 = Color3.fromRGB(44,44,44)
local setWSBtn = create("TextButton", {Parent=left, Position=UDim2.new(0,6,0,246), Size=UDim2.new(1,-12,0,28), Text="Set WS"})
setWSBtn.BackgroundColor3 = Color3.fromRGB(65,65,65)
local rstWSBtn = create("TextButton", {Parent=left, Position=UDim2.new(0,6,0,282), Size=UDim2.new(1,-12,0,28), Text="Reset WS"})
rstWSBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)

local jpBox = create("TextBox", {Parent=left, Position=UDim2.new(0,6,0,320), Size=UDim2.new(1,-12,0,26), PlaceholderText="Set JumpPower (e.g. 50)"})
jpBox.BackgroundColor3 = Color3.fromRGB(44,44,44)
local setJPBtn = create("TextButton", {Parent=left, Position=UDim2.new(0,6,0,352), Size=UDim2.new(1,-12,0,28), Text="Set JP"})
setJPBtn.BackgroundColor3 = Color3.fromRGB(65,65,65)
local rstJPBtn = create("TextButton", {Parent=left, Position=UDim2.new(0,6,0,388), Size=UDim2.new(1,-12,0,28), Text="Reset JP"})
rstJPBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)

create("UICorner", {Parent=setWSBtn, CornerRadius=UDim.new(0,6)})
create("UICorner", {Parent=rstWSBtn, CornerRadius=UDim.new(0,6)})
create("UICorner", {Parent=setJPBtn, CornerRadius=UDim.new(0,6)})
create("UICorner", {Parent=rstJPBtn, CornerRadius=UDim.new(0,6)})

-- Right column: placeholder - will hold the Picker panel area (hidden by default)
local pickerPanel = create("Frame", {Parent=main, Size=UDim2.new(0,200,1,-46), Position=UDim2.new(1,-212,0,46), BackgroundColor3=Color3.fromRGB(18,18,18)})
create("UICorner", {Parent=pickerPanel, CornerRadius=UDim.new(0,6)})
pickerPanel.Visible = false

-- Picker header (search)
local pickerHeader = create("Frame", {Parent=pickerPanel, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1})
local pickerTitle = create("TextLabel", {Parent=pickerHeader, Position=UDim2.new(0,8,0,6), Size=UDim2.new(1,-16,0,32), Text="Player Picker", BackgroundTransparency=1, Font=Enum.Font.SourceSansBold, TextSize=16, TextColor3=Color3.fromRGB(230,230,230), TextXAlignment=Enum.TextXAlignment.Left})
local searchBox = create("TextBox", {Parent=pickerHeader, Position=UDim2.new(0,8,0,36), Size=UDim2.new(1,-16,0,28), PlaceholderText="Search player..."})
searchBox.BackgroundColor3 = Color3.fromRGB(36,36,36)
searchBox.TextColor3 = Color3.fromRGB(230,230,230)

-- Picker list (scroll)
local pickerList = create("ScrollingFrame", {Parent=pickerPanel, Position=UDim2.new(0,8,0,72), Size=UDim2.new(1,-16,1,-80), CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=8})
local pickerLayout = create("UIListLayout", {Parent=pickerList})
pickerLayout.Padding = UDim.new(0,6)

-- picker footer util buttons
local utilFrame = create("Frame", {Parent=pickerPanel, Size=UDim2.new(1,0,0,56), Position=UDim2.new(0,0,1,-56), BackgroundTransparency=1})
local killAllBtn = create("TextButton", {Parent=utilFrame, Size=UDim2.new(1,-16,0,28), Position=UDim2.new(0,8,0,8), Text="Kill All (Attempt)"})
killAllBtn.BackgroundColor3 = Color3.fromRGB(90,40,40)
local teleportRandomBtn = create("TextButton", {Parent=utilFrame, Size=UDim2.new(1,-16,0,28), Position=UDim2.new(0,8,0,36), Text="Teleport Random"})
teleportRandomBtn.BackgroundColor3 = Color3.fromRGB(65,65,65)
create("UICorner", {Parent=killAllBtn, CornerRadius=UDim.new(0,6)})
create("UICorner", {Parent=teleportRandomBtn, CornerRadius=UDim.new(0,6)})

-- Notification helper (small)
local function notify(text, dur)
    dur = dur or 2.8
    if Remote_SendNotification and Remote_SendNotification.FireServer then
        pcall(function() Remote_SendNotification:FireServer(LocalPlayer, text) end)
    else
        -- small on-screen label
        local tmp = create("TextLabel", {Parent = screenGui, Size = UDim2.new(0,300,0,30), Position = UDim2.new(0.5,-150,0.03,0), BackgroundColor3=Color3.fromRGB(40,40,40), Text=text, TextColor3=Color3.fromRGB(240,240,240), Font=Enum.Font.SourceSans, TextSize=14})
        create("UICorner",{Parent=tmp, CornerRadius=UDim.new(0,6)})
        delay(dur, function() pcall(function() tmp:Destroy() end) end)
    end
end

-- ============================
-- UI Behaviors & Admin Actions
-- ============================

-- Fly implementation (re-using user's sFLY style for input keys)
local flyConnInput, flyLoopConn
local function startFlyFromSpeed(speed)
    -- if mobile use mobilefly; else use sFLY-like implementation
    local isMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform())
    -- try to reuse original sFLY function behavior: but we'll implement a robust local fly
    if STATE.flying then return end
    STATE.flying = true

    local hrp = getRoot(LocalPlayer.Character)
    if not hrp then notify("Character not ready for fly") STATE.flying=false return end

    -- Body movers
    local BV = create("BodyVelocity", {Parent = hrp, MaxForce = Vector3.new(1e5,1e5,1e5), Velocity = Vector3.new()})
    local BG = create("BodyGyro", {Parent = hrp, MaxTorque = Vector3.new(1e5,1e5,1e5), CFrame = workspace.CurrentCamera.CFrame})
    local speedMult = math.max(0.1, tonumber(speed) or 1)
    flyLoopConn = RunService.RenderStepped:Connect(function()
        if not STATE.flying or not hrp then return end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true end)
        end
        local cam = workspace.CurrentCamera
        BG.CFrame = cam.CFrame
        local mv = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
        BV.Velocity = mv * (50 * speedMult)
    end)

    notify("Fly ON (speed "..tostring(speedMult)..")")
end

local function stopFlyLocal()
    STATE.flying = false
    if flyLoopConn then flyLoopConn:Disconnect() flyLoopConn = nil end
    -- remove bodies if they still exist
    if LocalPlayer.Character then
        local hrp = getRoot(LocalPlayer.Character)
        if hrp then
            for _, child in pairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
                    if child.Name ~= velocityHandlerName and child.Name ~= gyroHandlerName then -- safe
                        pcall(function() child:Destroy() end)
                    end
                end
            end
        end
        pcall(function()
            if LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
            end
        end)
    end
    notify("Fly OFF")
end

-- NoClip toggle: uses stepped to remove collisions
local noclipConn
local function setNoClip(val)
    STATE.clipEnabled = val
    if val then
        if noclipConn then noclipConn:Disconnect() noclipConn=nil end
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end
        end)
        notify("NoClip ON")
    else
        if noclipConn then noclipConn:Disconnect() noclipConn=nil end
        -- try restore collisions
        if LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
        notify("NoClip OFF")
    end
end

-- ESP global functions (small font)
local function addESPToPlayer(plr)
    if not plr.Character or not plr.Character:FindFirstChild("Head") then return end
    if plr.Character.Head:FindFirstChild("ESPTag") then return end
    local bgui = create("BillboardGui", {Parent = plr.Character.Head, Name="ESPTag", Size = UDim2.new(0,90,0,20), AlwaysOnTop=true, ExtentsOffset=Vector3.new(0,1.8,0)})
    local lbl = create("TextLabel", {Parent = bgui, Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=plr.Name, Font=Enum.Font.Code, TextSize=14, TextColor3=Color3.fromRGB(0,255,0), TextScaled=false})
end
local function removeESPFromPlayer(plr)
    if plr.Character and plr.Character:FindFirstChild("Head") and plr.Character.Head:FindFirstChild("ESPTag") then
        pcall(function() plr.Character.Head.ESPTag:Destroy() end)
    end
end
local function setGlobalESP(on)
    STATE.espEnabled = on
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if on then addESPToPlayer(plr) else removeESPFromPlayer(plr) end
        end
    end
    notify("ESP "..(on and "ON" or "OFF"))
end

-- spectate: set camera subject to target Humanoid or Head
local function setSpectatePlayer(plr)
    if not plr or not plr.Character then
        STATE.spectating = nil
        workspace.CurrentCamera.CameraSubject = getLocalHumanoid() or workspace.CurrentCamera.CameraSubject
        notify("Stopped spectate")
        return
    end
    STATE.spectating = plr
    notify("Spectating "..plr.Name)
end

-- Attempt remote admin action then fallback local
local function attemptAdminAction(actionName, targetPlayer)
    -- actionName examples: "Kill", "Bring", "TeleportTo", "Rope", "Unrope", ...
    if Remote_AdminAction and Remote_AdminAction.FireServer then
        pcall(function() Remote_AdminAction:FireServer(actionName, targetPlayer) end)
        notify("Requested server admin action: "..actionName.." -> "..(targetPlayer and targetPlayer.Name or "nil"))
        return true
    end
    return false
end

-- Teleport local to target (client)
local function teleportToPlayer(plr)
    if not plr then return end
    local targetChar = plr.Character
    local myChar = LocalPlayer.Character
    if targetChar and myChar then
        local thrp = getRoot(targetChar)
        local mhrp = getRoot(myChar)
        if thrp and mhrp then
            pcall(function() mhrp.CFrame = thrp.CFrame + Vector3.new(0,3,0) end)
            notify("Teleported to "..plr.Name)
        end
    end
end

-- Bring target to me (client attempt)
local function bringPlayer(plr)
    if not plr then return end
    local targetChar = plr.Character
    local myChar = LocalPlayer.Character
    if targetChar and myChar then
        local thrp = getRoot(targetChar)
        local mhrp = getRoot(myChar)
        if thrp and mhrp then
            pcall(function() thrp.CFrame = mhrp.CFrame + Vector3.new(2,0,0) end)
            notify("Brought "..plr.Name.." to you (client attempt)")
        end
    end
end

-- Kill player (client attempt)
local function killPlayer(plr)
    if not plr then return end
    if attemptAdminAction("Kill", plr) then return end
    pcall(function()
        if plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end)
    notify("Tried kill "..plr.Name)
end

-- Rope player (prefer remote)
local function ropePlayer(plr)
    if not plr then return end
    if Remote_Rope and Remote_Rope.FireServer then
        pcall(function() Remote_Rope:FireServer(LocalPlayer, plr) end)
        notify("Requested server rope to "..plr.Name)
        return
    end
    -- local fallback
    if STATE.ropeObjects[plr.Name] then notify("Already roped "..plr.Name) return end
    local myChar = LocalPlayer.Character
    local tChar = plr.Character
    if myChar and tChar then
        local hrp1 = getRoot(myChar)
        local hrp2 = getRoot(tChar)
        if hrp1 and hrp2 then
            local att1 = create("Attachment", {Parent = hrp1})
            local att2 = create("Attachment", {Parent = hrp2})
            local rope = create("RopeConstraint", {Parent = hrp1})
            rope.Attachment0 = att1
            rope.Attachment1 = att2
            rope.Length = 6
            rope.Visible = true
            STATE.ropeObjects[plr.Name] = {rope=rope, a1=att1, a2=att2}
            notify("Roped "..plr.Name.." (local)")
        end
    end
end

local function unropePlayer(plr)
    if not plr then return end
    if Remote_UnropeAll and Remote_UnropeAll.FireServer then
        pcall(function() Remote_UnropeAll:FireServer(LocalPlayer) end)
        notify("Requested server unrope all")
    end
    local entry = STATE.ropeObjects[plr.Name]
    if entry then
        pcall(function()
            if entry.rope and entry.rope.Parent then entry.rope:Destroy() end
            if entry.a1 and entry.a1.Parent then entry.a1:Destroy() end
            if entry.a2 and entry.a2.Parent then entry.a2:Destroy() end
        end)
        STATE.ropeObjects[plr.Name] = nil
        notify("Unroped "..plr.Name.." (local)")
    end
end

-- Kill all (attempt)
local function killAllPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            killPlayer(plr)
        end
    end
    notify("Attempted kill all")
end

-- Teleport random
local function teleportRandom()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(list, p) end end
    if #list > 0 then teleportToPlayer(list[math.random(1,#list)]) end
end

-- Set local WS/JP
local function setLocalWalkSpeed(v)
    if not v then notify("Invalid WS") return end
    local hum = getLocalHumanoid()
    if hum then pcall(function() hum.WalkSpeed = v end) end
    notify("Set WalkSpeed to "..tostring(v))
end
local function setLocalJumpPower(v)
    if not v then notify("Invalid JP") return end
    local hum = getLocalHumanoid()
    if hum then pcall(function() hum.JumpPower = v end) end
    notify("Set JumpPower to "..tostring(v))
end

-- ============================
-- Picker list UI population
-- ============================
local function clearPickerList()
    for _,child in pairs(pickerList:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
end

local function makePlayerEntry(plr)
    local entry = create("Frame", {Parent = pickerList, Size = UDim2.new(1, -16, 0, 34), BackgroundColor3 = Color3.fromRGB(28,28,28)})
    create("UICorner", {Parent = entry, CornerRadius = UDim.new(0,6)})
    local nameBtn = create("TextButton", {Parent = entry, Size = UDim2.new(0.6,0,1,0), Position = UDim2.new(0,6,0,0), Text = plr.Name, Font=Enum.Font.SourceSans, TextColor3=Color3.fromRGB(230,230,230)})
    nameBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    local menuBtn = create("TextButton", {Parent = entry, Size = UDim2.new(0.38, -8, 1, 0), Position = UDim2.new(0.62,0,0,0), Text = "Options", Font=Enum.Font.SourceSans, TextColor3=Color3.fromRGB(230,230,230)})
    menuBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)

    local optionsFrame -- created on demand

    menuBtn.MouseButton1Click:Connect(function()
        -- toggle options
        if optionsFrame and optionsFrame.Parent then
            optionsFrame:Destroy()
            optionsFrame = nil
            return
        end
        optionsFrame = create("Frame", {Parent = entry, Size = UDim2.new(1,0,0,110), Position = UDim2.new(0,0,1,4), BackgroundColor3 = Color3.fromRGB(12,12,12)})
        create("UICorner", {Parent = optionsFrame, CornerRadius = UDim.new(0,6)})
        -- Buttons grid
        local btnW = 92
        local function addOpt(text, posX, posY, fn)
            local b = create("TextButton", {Parent = optionsFrame, Position = UDim2.new(0,posX,0,posY), Size = UDim2.new(0,btnW,0,28), Text = text, Font=Enum.Font.SourceSans})
            b.BackgroundColor3 = Color3.fromRGB(60,60,60)
            create("UICorner", {Parent = b, CornerRadius = UDim.new(0,6)})
            b.MouseButton1Click:Connect(function() pcall(fn) end)
        end
        addOpt("Spectate", 8, 6, function()
            if STATE.spectating == plr then
                setSpectatePlayer(nil)
            else
                setSpectatePlayer(plr)
            end
        end)
        addOpt("Teleport", 110, 6, function()
            if attemptAdminAction("TeleportTo", plr) then else teleportToPlayer(plr) end
        end)
        addOpt("Bring", 8, 40, function()
            if attemptAdminAction("Bring", plr) then else bringPlayer(plr) end
        end)
        addOpt("Kill", 110, 40, function() killPlayer(plr) end)
        addOpt("Rope", 8, 74, function() ropePlayer(plr) end)
        addOpt("Unrope", 110, 74, function() unropePlayer(plr) end)
    end)

    return entry
end

local function rebuildPickerList(filterText)
    filterText = (filterText or ""):lower()
    clearPickerList()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (filterText == "" or plr.Name:lower():find(filterText)) then
            local entry = makePlayerEntry(plr)
            entry.Parent = pickerList
        end
    end
    -- adjust canvas size
    local contentY = 0
    for _, child in ipairs(pickerList:GetChildren()) do
        if child:IsA("Frame") then contentY = contentY + child.Size.Y.Offset + 6 end
    end
    pickerList.CanvasSize = UDim2.new(0,0,0, contentY)
end

-- wire search
searchBox:GetPropertyChangedSignal("Text"):Connect(function() rebuildPickerList(searchBox.Text) end)
Players.PlayerAdded:Connect(function() rebuildPickerList(searchBox.Text) end)
Players.PlayerRemoving:Connect(function() rebuildPickerList(searchBox.Text) end)

-- initial
rebuildPickerList("")

-- UI Buttons: bind behaviors
togglePickerBtn.MouseButton1Click:Connect(function()
    pickerPanel.Visible = not pickerPanel.Visible
    if pickerPanel.Visible then
        rebuildPickerList(searchBox.Text)
    end
end)

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

flyBtn.MouseButton1Click:Connect(function()
    if STATE.flying then
        stopFlyLocal()
        flyBtn.Text = "Fly: OFF"
    else
        local s = tonumber(speedBox.Text) or 1
        startFlyFromSpeed(s)
        flyBtn.Text = "Fly: ON"
    end
end)

noclipBtn.MouseButton1Click:Connect(function()
    setNoClip(not STATE.clipEnabled)
    noclipBtn.Text = (STATE.clipEnabled and "NoClip: ON") or "NoClip: OFF"
    noclipBtn.BackgroundColor3 = STATE.clipEnabled and Color3.fromRGB(40,80,40) or Color3.fromRGB(80,40,40)
end)

espGlobalBtn.MouseButton1Click:Connect(function()
    setGlobalESP(not STATE.espEnabled)
    espGlobalBtn.Text = "ESP: "..(STATE.espEnabled and "ON" or "OFF")
end)

setWSBtn.MouseButton1Click:Connect(function()
    local v = tonumber(wsBox.Text)
    setLocalWalkSpeed(v)
end)
rstWSBtn.MouseButton1Click:Connect(function()
    setLocalWalkSpeed(LOCAL_DEFAULTS.WalkSpeed)
    notify("WalkSpeed reset to default ("..tostring(LOCAL_DEFAULTS.WalkSpeed)..")")
end)
setJPBtn.MouseButton1Click:Connect(function()
    local v = tonumber(jpBox.Text)
    setLocalJumpPower(v)
end)
rstJPBtn.MouseButton1Click:Connect(function()
    setLocalJumpPower(LOCAL_DEFAULTS.JumpPower)
    notify("JumpPower reset to default ("..tostring(LOCAL_DEFAULTS.JumpPower)..")")
end)

killAllBtn.MouseButton1Click:Connect(function() killAllPlayers() end)
teleportRandomBtn.MouseButton1Click:Connect(function() teleportRandom() end)

-- spectate behavior in render loop (keeps camera following)
RunService.RenderStepped:Connect(function()
    if STATE.spectating and STATE.spectating.Character and STATE.spectating.Character:FindFirstChildOfClass("Humanoid") then
        pcall(function()
            workspace.CurrentCamera.CameraSubject = STATE.spectating.Character:FindFirstChildOfClass("Humanoid")
        end)
    else
        -- if not spectating, ensure camera subject set back to local humanoid
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    end
end)

-- Keep ESP updated when players spawn
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        wait(0.6)
        if STATE.espEnabled then addESPToPlayer(plr) end
    end)
end)

-- Auto-refresh small interval for picker list while visible
spawn(function()
    while screenGui.Parent do
        wait(1.2)
        if pickerPanel.Visible then
            pcall(function() rebuildPickerList(searchBox.Text) end)
        end
    end
end)

-- Final notify
notify("Aguz Admin Panel siap — buka 'Pilih Player' untuk admin tools.", 3)

-- End of script