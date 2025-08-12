local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
	Name = "Expedition Antartica by Fokus ID",
	Icon = 0,
	LoadingTitle = "Mount Daun",
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
	end
})

local Slider = Tab:CreateSlider({
	Name = "Speed / Walkspeed",
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
	end
})

local Noclipping = nil
local Clip = Tab:CreateSlider({
	Name = "Clip",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		Clip = value

		if Clip then
			local player = game.Players.LocalPlayer
			local character = player.Character or player.CharacterAdded:Wait()
			
			wait(0.1)
			local function NoclipLoop()
				if clipEnabled == false and character ~= nil then
					for _, child in pairs(character:GetDescendants()) do
						if child:IsA("BasePart") and child.CanCollide == true and child.Name ~= floatName then
							child.CanCollide = false
						end
					end
				end
			end
			Noclipping = RunService.Stepped:Connect(NoclipLoop)
		else
			if Noclipping then
				Noclipping:Disconnect()
			end
		end
	end
})

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
			
			local targetPosition = CFrame.new(-623, 249, -380)
			
			hrp.CFrame = targetPosition
		end
	end
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
			
			local targetPosition = CFrame.new(-1202, 261, -485)
			
			hrp.CFrame = targetPosition
		end
	end
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
			
			local targetPosition = CFrame.new(-1399, 578, -950)
			
			hrp.CFrame = targetPosition
		end
	end
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
			
			local targetPosition = CFrame.new(-1700, 816, -1398)
			
			hrp.CFrame = targetPosition
		end
	end
})

local Toggle = Tab:CreateToggle({
	Name = "Teleport to Summit",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		if Value then
			local player = game.Players.LocalPlayer
			local character = player.Character or player.CharacterAdded:Wait()
			local hrp = character:WaitForChild("HumanoidRootPart")
			
			local targetPosition = CFrame.new(-3242, 1716, -2583)
			
			hrp.CFrame = targetPosition
		end
	end
})

Rayfield:LoadConfiguration()