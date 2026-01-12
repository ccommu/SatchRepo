local start = tick()
--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Framework = ServerScriptService:FindFirstChild("Framework")
local Services = Framework:FindFirstChild("Services")
local Utils = Framework:FindFirstChild("Utils")

local Packages = ServerScriptService:FindFirstChild("Packages")
local ProfileStorePackages = Packages:FindFirstChild("ProfileStore")

local DataManager = require(ProfileStorePackages:FindFirstChild("DataManager"))

local NumberUtils = require(Utils:FindFirstChild("Numbers"))
local RemoteSecurity = require(Utils:FindFirstChild("RemoteSecurity"))

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Networking = Shared:FindFirstChild("Networking")

local NPCEvents = Networking:FindFirstChild("NPC")
local IsNPCUnlockedRequest = NPCEvents:FindFirstChild("IsUnlockedNPC")
local UnlockNPCEvent = NPCEvents:FindFirstChild("UnlockNPC")

local MiscEvents = Networking:FindFirstChild("Misc")
local DeadEvent = MiscEvents:FindFirstChild("Died")

local ShopEvents = Networking:FindFirstChild("Shop")
local IsSatchelOwnedRequest = ShopEvents:FindFirstChild("IsSatchelOwned")
local CanAffordSatchelRequest = ShopEvents:FindFirstChild("CanAfford")
local PurchaseSatchelRequest = ShopEvents:FindFirstChild("Purchase")

local SatchelEvents = Networking:FindFirstChild("Satchels")
local OwnedSatchelsRequest = SatchelEvents:FindFirstChild("OwnedSatchels")
local EquipSatchelRequest = SatchelEvents:FindFirstChild("EquipSatchel")

local UpdateUIEvent = MiscEvents:WaitForChild("UpdateUI")

--------------------------------
--\\ Variables //--
--------------------------------

local InitiatedServices = 0
local InitiatedUtils = 0

local SuccessfulServiceInitations = 0
local SuccessfulUtilsInitations = 0

local SatchelService = require(Services:FindFirstChild("SatchelService"))

--------------------------------
--\\ Util Functions //--
--------------------------------

local function InitiateService(Service: ModuleScript)
	if not Service:IsA("ModuleScript") then
		return warn("Server - Tried to initialize a non-module script")
	end

	local Required = require(Service)
	local s, f = pcall(function()
		task.spawn(Required.OnStart)
	end)

	InitiatedServices += 1

	if f then
		warn(`Server - Failed to run :OnStart for service: {Service.Name}.`)
	elseif s then
		SuccessfulServiceInitations += 1
	end
end

local function InitiateUtils(Service: ModuleScript)
	if not Service:IsA("ModuleScript") then
		return warn("Server - Tried to initialize a non-module script")
	end

	local Required = require(Service)
	local s, f = pcall(function()
		task.spawn(Required.Init)
	end)

	InitiatedUtils += 1

	if f then
		warn(`Server - Failed to run :Init for util: {Service.Name}.`)
	elseif s then
		SuccessfulUtilsInitations += 1
	end
end

local function GetSafeSpawnPosition(basePosition, radius)
	local newPosition = basePosition
	local attempts = 0
	local maxAttempts = 10

	while attempts < maxAttempts do
		local overlapping = false
		for _, player in ipairs(game.Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local otherHRP = player.Character.HumanoidRootPart
				if (otherHRP.Position - newPosition).Magnitude < radius then
					overlapping = true
					break
				end
			end
		end

		if not overlapping then
			return CFrame.new(newPosition)
		end

		newPosition = basePosition + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
		attempts += 1
	end

	return CFrame.new(newPosition)
end

--------------------------------
--\\ Main //--
--------------------------------

for _, Service in Services:GetDescendants() do
	InitiateService(Service)
end

for _, Utils in Utils:GetDescendants() do
	InitiateUtils(Utils)
end

print(
	`\n===============================\n\n--SERVER--\n\nInitiated All Services and Utils\nTotal Inititated Services: {InitiatedServices}\n\nTotal Initiated Utils: {InitiatedUtils}\n\nUnsuccessful Service Initiations: {InitiatedServices - SuccessfulServiceInitations}\nUnsuccessful Util Initiations: {InitiatedUtils - SuccessfulUtilsInitations}\n\n===============================`
)
if not RunService:IsStudio() then
	print(
		`Running @ccommu on discord and @dev_Commu on roblox's client and server framework, made entirely for Satch 🌿`
	)
end

Players.PlayerAdded:Connect(function(player: Player)
	local PlayerData = DataManager.GetData(player)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(player)
	end
	PlayerData = DataManager.GetData(player)

	if PlayerData.Banned == true then
		if PlayerData.BanLength ~= "inf" then
			local CurrentTime = os.time()
			local IsExpired = (CurrentTime >= PlayerData.BanTime + PlayerData.BanLength)

			if IsExpired then
				DataManager.Unban(player)
			else
				local Remaining = (PlayerData.BanTime + PlayerData.BanLength) - CurrentTime
				player:Kick(
					`You are still banned for the next: {Remaining} seconds for the reason: "{PlayerData.BanReason}, if you feel this was incorrect, let us know in the community server.`
				)
				return
			end
		else
			player:Kick(
				`You are permenantley banned for the reason: "{PlayerData.BanReason}", if you wish to appeal please join the community server.`
			)
		end
	end

	local Leaderstats = Instance.new("Folder")
	Leaderstats.Name = "leaderstats"
	Leaderstats.Parent = player

	local Currency = Instance.new("StringValue")
	Currency.Name = "F$"
	Currency.Value = NumberUtils:FormatNumber(PlayerData.Currency)
	Currency.Parent = Leaderstats

	--DataManager.RemoveDiscoveredNPC(player, "IntroNPC")
	--DataManager.LockSatchel(player, "Starter Satchel")

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	UpdateUIEvent:FireClient(player, "currency", PlayerData.Currency)
	UpdateUIEvent:FireClient(player, "level", PlayerData.Level)

	local Humanoid = player.Character:FindFirstChild("Humanoid")

	player.Character:PivotTo(GetSafeSpawnPosition(workspace:FindFirstChild("SpawnLocation").Position, 3))
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	Humanoid.BreakJointsOnDeath = false
	Humanoid.RequiresNeck = false
	Humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			Humanoid.Health = 1

			Humanoid:ChangeState(Enum.HumanoidStateType.Physics)

			task.delay(2, function()
				if Humanoid.Parent == nil then
					return
				end

				Humanoid.PlatformStand = false
				Humanoid.Health = Humanoid.MaxHealth

				Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				Humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end)

			DeadEvent:FireClient(player)

			task.delay(1, function()
				player.Character:PivotTo(GetSafeSpawnPosition(workspace:FindFirstChild("SpawnLocation").Position, 3))
			end)
		end
	end)

	local Effects = ServerStorage:FindFirstChild("PlayerSpawnEffects"):Clone()
	Effects.Parent = player.Character:FindFirstChild("HumanoidRootPart")

	Effects:FindFirstChild("Flare"):Emit(1)
	Effects:FindFirstChild("Sparkle"):Emit(15)
	Effects:FindFirstChild("Wave"):Emit(1)

	task.delay(2, function()
		Effects:Destroy()
	end)

	local Animate = player.Character:FindFirstChild("Animate")
	Animate.Enabled = false
	task.delay(1, function()
		Animate.Enabled = true
	end)
end)

IsNPCUnlockedRequest.OnServerInvoke = function(playerFrom: Player, NPCName: string)
	if typeof(NPCName) ~= "string" then
		return false
	end

	local PlayerData = DataManager.GetData(playerFrom)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(playerFrom)
	end
	PlayerData = DataManager.GetData(playerFrom)

	if PlayerData.DiscoveredNPCS[NPCName] then
		return true
	else
		return false
	end
end

UnlockNPCEvent.OnServerEvent:Connect(function(playerFrom: Player, NPC: Model, NPCName: string)
	if typeof(playerFrom) ~= "Instance" or not playerFrom:IsA("Player") then
		return
	end
	if typeof(NPCName) ~= "string" then
		return
	end
	if typeof(NPC) ~= "Instance" or not NPC:IsA("Model") then
		return
	end

	local ok = RemoteSecurity:CheckCooldown(playerFrom, "UnlockNPC", 2)
	if not ok then
		return
	end

	local Char = playerFrom.Character or playerFrom.CharacterAdded:Wait()
	local HMRP = Char and Char:FindFirstChild("HumanoidRootPart")
	local NPC_HRP = NPC:FindFirstChild("HumanoidRootPart")
	if not HMRP or not NPC_HRP then
		return
	end

	local distance = (HMRP.Position - NPC_HRP.Position).Magnitude
	if distance <= 30 then
		DataManager.AddDiscoveredNPC(playerFrom, NPCName)
	end
end)

IsSatchelOwnedRequest.OnServerInvoke = function(playerFrom: Player, SatchelName: string)
	if typeof(SatchelName) ~= "string" then
		return false
	end

	local PlayerData = DataManager.GetData(playerFrom)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(playerFrom)
	end
	PlayerData = DataManager.GetData(playerFrom)

	if PlayerData.OwnedSatchels[SatchelName] then
		return true
	else
		return false
	end
end

CanAffordSatchelRequest.OnServerInvoke = function(playerFrom: Player, Cost: number)
	if typeof(Cost) ~= "number" then
		return false
	end
	if Cost < 0 or Cost > 1000000000 then
		return false
	end

	local PlayerData = DataManager.GetData(playerFrom)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(playerFrom)
	end
	PlayerData = DataManager.GetData(playerFrom)

	return PlayerData.Currency >= Cost
end

PurchaseSatchelRequest.OnServerInvoke = function(playerFrom: Player, SatchelName: string, Cost: number)
	if typeof(SatchelName) ~= "string" or typeof(Cost) ~= "number" then
		return false
	end
	if Cost < 0 or Cost > 1000000000 then
		return false
	end

	local PlayerData = DataManager.GetData(playerFrom)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(playerFrom)
	end
	PlayerData = DataManager.GetData(playerFrom)

	if PlayerData.Currency >= Cost then
		if not PlayerData.OwnedSatchels[SatchelName] then
			DataManager.AddCurrency(playerFrom, -Cost)
			DataManager.UnlockSatchel(playerFrom, SatchelName)

			return true
		else
			return false
		end
	else
		return false
	end
end

OwnedSatchelsRequest.OnServerInvoke = function(playerFrom: Player)
	local PlayerData = DataManager.GetData(playerFrom)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(playerFrom)
	end
	PlayerData = DataManager.GetData(playerFrom)

	return PlayerData.OwnedSatchels
end

EquipSatchelRequest.OnServerInvoke = function(playerFrom: Player, SatchelName: string)
	if typeof(SatchelName) ~= "string" then
		return false
	end

	local PlayerData = DataManager.GetData(playerFrom)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(playerFrom)
	end
	PlayerData = DataManager.GetData(playerFrom)

	if PlayerData.OwnedSatchels[SatchelName] then
		local Equipped = SatchelService.EquipSatchel(playerFrom, SatchelName)
		return Equipped
	else
		return false
	end
end

local endtime = tick()
print(`Server initialized in {tostring(endtime - start)} seconds.`)

--Scarf: an$argon2id$v=19$m=262144,t=5,p=4$wFQ8RZK5Yc7q8zVn3M2c5A$0k2XQmZqkG4f8Xv5nRrM9nZk1yF6ZKcH6J1k7yYV5Qw
