--rewritten by: SoundInfinity
--original author: scde
--Game: https://www.roblox.com/games/6897226634/Timber

--#region config
local chopped = 0
local chopped_max = 10
local chopped_sellBetweenMin = 50
local chopped_sellBetweenMax = 100
--#endregion
--#region Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
--#endregion
--#region Globals
local random = math.random
local LocalPlayer = game:GetService("Players").LocalPlayer
local GameFolders = {
	["Plots"] = workspace:WaitForChild("Plots", 2),
	["Remotes"] = ReplicatedStorage:WaitForChild("Communication", 2):WaitForChild("Remotes", 2),
}
--#endregion
--#region onIdle
local function player_onIdle()
	local args = { Vector2.new(random(), random()), workspace.CurrentCamera.CFrame }
	VirtualUser:Button2Down(args[1], args[2])
	wait(1)
	VirtualUser:Button2Up(args[1], args[2])
end
--#endregion

local function client_plots_getOwned()
	for _, child in next, GameFolders.Plots:GetChildren() do
		local owner_objectValue = child:FindFirstChild("Owner") or child:WaitForChild("Owner")
		if owner_objectValue.Value == LocalPlayer or owner_objectValue.Value == LocalPlayer.Character then
			return child
		end
	end
end

local function client_plots_getNearestTree(plotFolder)
	local last_magnitude
	local data = { Tree = nil, Branch = nil }

	for _, branch in next, plotFolder:GetChildren() do
		if branch:IsA("Model") then
			for _, tree in next, branch:GetChildren() do
				if tree.Name:match("Tree") then
					local treeBase = tree:FindFirstChild("Base")
					if treeBase ~= nil then
						local treePosition = treeBase.CFrame
						local hrPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						local magnitude = (hrPart.Position - treePosition.Position).Magnitude
						if last_magnitude == nil then
							last_magnitude = magnitude
						end
						if magnitude <= last_magnitude then
							data.Tree = tree
							data.Branch = branch
							last_magnitude = magnitude
						end
					end
				end
			end
		end
	end
	return (data.Tree == nil and nil or data)
end

local function client_actions_walkTo(vector3, magnitude)
	local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local hrPart = LocalPlayer.Character.HumanoidRootPart

	humanoid:MoveTo(vector3)
	local lastTry = tick()
	local not_reached = false
	repeat
		RunService.RenderStepped:Wait()
		if (tick() - lastTry) > 5 then
			not_reached = true
			break
		end
	until (hrPart.Position * Vector3.new(1, 0, 1) - vector3 * Vector3.new(1, 0, 1)).Magnitude <= (magnitude or 4)

	if not_reached then
		local animation = TweenService:Create(hrPart, TweenInfo.new(3, Enum.EasingStyle.Linear), {
			CFrame = CFrame.new(vector3 + Vector3.new(0, 2, 0)),
		})
		animation:Play()
		animation.Completed:Wait()
	end
end

local function client_actions_sellLogs()
	local plot = client_plots_getOwned()
	local block0x0 = plot:FindFirstChild("0_0") or plot:WaitForChild("0_0")
	if block0x0 ~= nil then
		local sellPad = block0x0:FindFirstChild("Sell") or block0x0:WaitForChild("Sell")
		if sellPad ~= nil then
			client_actions_walkTo(sellPad.Position, 1.5)
			chopped = 0
			chopped_max = random(chopped_sellBetweenMin, chopped_sellBetweenMax)
		end
	end
end

local function client_actions_chopLogs_sync()
	local plot = client_plots_getOwned()
	local choice = client_plots_getNearestTree(plot)

	if choice ~= nil then
		local tree_model = choice.Tree
		local tree_number = choice.Tree.Name:match("(%d+)")
		local tree_cframe = (tree_model:FindFirstChild("Base") or tree_model:WaitForChild("Base")).CFrame
		local hrPart = LocalPlayer.Character.HumanoidRootPart

		client_actions_walkTo(tree_cframe.Position)

		if (hrPart.Position - tree_cframe.Position).Magnitude <= 4 then
			GameFolders.Remotes.HitTree:FireServer(plot.Name, choice.Branch.Name, tree_number)
		end
	end
end

local function client_actions_buySpeed()
	GameFolders.Remotes.Upgrade:FireServer("Speed")
end

local function client_actions_expandIsland(blockName)
	-- X_X
	GameFolders.Remotes.ExpandIsland:FireServer("3_0")
end

LocalPlayer.Idled:Connect(player_onIdle)

local IsEnabled = true
local doingTask = false
local function client_chop_service()
	if IsEnabled then
		if not doingTask then
			doingTask = true
			if chopped >= chopped_max then
				client_actions_sellLogs()
			else
				client_actions_chopLogs_sync()
				chopped += 1
			end
			doingTask = false
		end
	end
end

RunService:BindToRenderStep("client_chop_service", Enum.RenderPriority.Input.Value + 1, client_chop_service)

local function script_toggle(state)
	IsEnabled = state or not IsEnabled
	workspace.Water.CanCollide = IsEnabled
	if set_fps_cap ~= nil then
		if IsEnabled then
			set_fps_cap(15)
		else
			set_fps_cap(999)
		end
	end
end

script_toggle(true)

UIS.InputEnded:Connect(function(input)
	if UIS:GetFocusedTextBox() == nil then
		if input.KeyCode == Enum.KeyCode.C then
			script_toggle()
		end
	end
end)
