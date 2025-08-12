local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Expedition Antartica by Fokus ID",
   Icon = 0,
   LoadingTitle = "Expedition Antartica",
   LoadingSubtitle = "by Fokus ID",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, 
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = false, 
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", 
      FileName = "Key",
      SaveKey = true, 
      GrabKeyFromSite = false,
      Key = {"Hello"} 
   }
})

local Tab = Window:CreateTab("Main")
local Section = Tab:CreateSection("- 3xplo Yang Tersedia -")

local InfiniteJumpEnabled = false

local Toggle = Tab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        InfiniteJumpEnabled = Value

        if InfiniteJumpEnabled then
            local Player = game:GetService("Players").LocalPlayer
            local UIS = game:GetService("UserInputService")

            if _G.InfiniteJumpConnection then
                _G.InfiniteJumpConnection:Disconnect()
            end

            _G.InfiniteJumpConnection = UIS.JumpRequest:Connect(function()
                if InfiniteJumpEnabled and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
                    Player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if _G.InfiniteJumpConnection then
                _G.InfiniteJumpConnection:Disconnect()
                _G.InfiniteJumpConnection = nil
            end
        end
    end,
})

local AutoHealEnabled = false
local HealConnection

local Toggle = Tab:CreateToggle({
    Name = "Auto Heal",
    CurrentValue = false,
    Flag = "AutoHealToggle",
    Callback = function(Value)
        AutoHealEnabled = Value
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        if AutoHealEnabled then
            HealConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = math.min(humanoid.Health + 5, humanoid.MaxHealth)
                end
            end)
        else
            if HealConnection then HealConnection:Disconnect() HealConnection = nil end
        end
    end,
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local godModeConnection = nil
local function enableGodMode(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Name ~= "GodHumanoid" then
        humanoid.Name = "GodHumanoid"

        godModeConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health < 1 then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    end
end

local function disableGodMode(character)
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    local humanoid = character:FindFirstChild("GodHumanoid")
    if humanoid then
        humanoid.Name = "Humanoid"
    end
end

local Toggle = Tab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodModeToggle",
    Callback = function(Value)
        local character = player.Character or player.CharacterAdded:Wait()
        if Value then
            enableGodMode(character)
        else
            disableGodMode(character)
        end
    end,
})

player.CharacterAdded:Connect(function(character)
    wait(1)
    if Toggle.CurrentValue then
        enableGodMode(character)
    else
        disableGodMode(character)
    end
end)

local Toggle = Tab:CreateToggle({
    Name = "Click Teleport",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        local player = game.Players.LocalPlayer
        local mouse = player:GetMouse()

        local existingTool = player.Backpack:FindFirstChild("Equip to Click TP") or player.Character:FindFirstChild("Equip to Click TP")

        if Value then
            if not existingTool then
                local tool = Instance.new("Tool")
                tool.RequiresHandle = false
                tool.Name = "Equip to Click TP"

                tool.Activated:Connect(function()
                    local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
                    pos = CFrame.new(pos.X, pos.Y, pos.Z)
                    player.Character.HumanoidRootPart.CFrame = pos
                end)

                tool.Parent = player.Backpack
            end
        else
            if existingTool then
                existingTool:Destroy()
            end
        end
    end,
})

local Slider = Tab:CreateSlider({
   Name = "WalkSpeed",
   Range = {0, 100},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "Slider1",
   Callback = function(Value)
      local player = game.Players.LocalPlayer
      local character = player.Character or player.CharacterAdded:Wait()
      local humanoid = character:FindFirstChildOfClass("Humanoid")
      
      if humanoid then
          humanoid.WalkSpeed = Value
      end
   end,
})

-- ========================== Teleport ==========================

local Tab = Window:CreateTab("Teleport")
local Section = Tab:CreateSection("- 3xplo Yang Tersedia -")

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Camp 1",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(-3719.244873046875, 226.95399475097656, 235.3978271484375)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Mount Kirkpatrik",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(-3189.724365234375, 362.63299560546875, 124.80664825439453)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Beardmore Glacier",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(-2285.0361328125, 98, -43.22997283935547)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Camp 2",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(1790.7022705078125, 107.41500091552734, -137.0068359375)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Mount Vinson",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(3731.1513671875, 1513.1986083984375, -183.84559631347656)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Camp 3",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(5891.3115234375, 323.10498046875, -17.62114906311035)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Canada Glacier",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(7603.6708984375, 317.68597412109375, 284.7451477050781)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Camp 4",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(8992.1708984375, 597.85498046875, 104.2709197980469)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Pole",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(10991.6826171875, 550.1880493164062, 106.43280029296875)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Teleport to Plane",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        if Value then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Ganti ini ke koordinat tujuan kamu
            local targetPosition = CFrame.new(10988.951171875, 560.2615966796875, -1.934710063934326)

            hrp.CFrame = targetPosition
        end
        -- Kalau Value == false, nggak ngapa-ngapain
    end,
})

Rayfield:LoadConfiguration()
