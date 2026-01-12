------------------------------
--\\ Services //--
------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------
--\\ Variables //--
------------------------------

local PlayerDataTemplate = require(ReplicatedStorage.Shared.ProfileStore_Related.PlayerData)
local ProfileStore = require(ServerScriptService.Packages.ProfileStore.ProfileStore)

local DataStoreKey = "Production"
if RunService:IsStudio() then
	DataStoreKey = "StudioTest"
end

local PlayerStore = ProfileStore.New(DataStoreKey, PlayerDataTemplate.DEFAULT_PLAYER_DATA)
local Profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}

local NumberUtils =
	require(ServerScriptService:FindFirstChild("Framework"):FindFirstChild("Utils"):FindFirstChild("Numbers"))

local UpdateUI = ReplicatedStorage:FindFirstChild("Shared")
	:FindFirstChild("Networking")
	:FindFirstChild("Misc")
	:FindFirstChild("UpdateUI")

------------------------------
--\\ Module Tables //--
------------------------------

local Local = {}
local DataManager = {}

------------------------------
--\\ Local Functions //--
------------------------------

function Local.OnStart()
	for _, Player in Players:GetPlayers() do -- Early joiners
		task.spawn(Local.LoadProfile, Player)
	end

	Players.PlayerAdded:Connect(Local.LoadProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)
end

function Local.LoadProfile(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		return player:Kick("Data load fail. Please rejoin.")
	end

	profile:AddUserId(player.UserId) -- required in order to comply with GDRP erasur requests (DO NOT REMOVE!).
	profile:Reconcile()

	-- Basic schema/type sanitization to protect against corrupted/old saves.
	local defaults = PlayerDataTemplate.DEFAULT_PLAYER_DATA

	local function sanitize(data)
		if typeof(data) ~= "table" then
			data = {}
		end

		if typeof(data.DiscoveredNPCS) ~= "table" then
			data.DiscoveredNPCS = {}
		end
		if typeof(data.Currency) ~= "number" then
			data.Currency = defaults.Currency
		end
		if typeof(data.Level) ~= "number" then
			data.Level = defaults.Level
		end
		if typeof(data.OwnedSatchels) ~= "table" then
			data.OwnedSatchels = {}
		end

		if typeof(data.Banned) ~= "boolean" then
			data.Banned = false
		end
		if data.BanReason ~= nil and typeof(data.BanReason) ~= "string" then
			data.BanReason = nil
		end
		if data.BanTime ~= nil and typeof(data.BanTime) ~= "number" then
			data.BanTime = nil
		end
		if data.BanLength ~= nil and (typeof(data.BanLength) ~= "number" and data.BanLength ~= "inf") then
			data.BanLength = nil
		end

		return data
	end

	profile.Data = sanitize(profile.Data)

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Data session ended, if this was a mistake please rejoin.")
	end)

	local isInGame = player.Parent == Players
	if isInGame then
		Profiles[player] = profile
	else
		profile:EndSession()
	end
end

function Local.RemoveProfile(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

------------------------------
--\\ Shared Functions //--
------------------------------

function DataManager.GetData(player: Player): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then
		return
	end

	return profile.Data
end

--[[
function DataManager.SetValue(player : Player, NewDataVal : number)
	local profile = Profiles[player]
	if not profile then return warn("No profile found for "..player.Name) end

	local DataInstance = player:WaitForChild("Data", 10):WaitForChild("EXAMPLEDATA", 10) :: IntValue
	if not DataInstance then return warn("No EXAMPLEDATA data instance for: "..player.Name) end

	profile.Data.EXAMPLEDATA = NewDataVal
	DataInstance.Value = profile.Data.EXAMPLEDATA
end

function DataManager.ModifyValue(player : Player, ChangeAmount : number)
	local profile = Profiles[player]
	if not profile then return warn("No profile found for "..player.Name) end

	local DataInstance = player:WaitForChild("Data", 10):WaitForChild("EXAMPLEDATA", 10) :: IntValue
	if not DataInstance then return warn("No EXAMPLEDATA data instance for: "..player.Name) end

	profile.Data.EXAMPLEDATA += ChangeAmount
	DataInstance.Value = profile.Data.EXAMPLEDATA
end
]]

function DataManager.LoadOffline(userId)
	local profile = ProfileStore:LoadProfileAsync(userId, "ForceLoad")

	if not profile then
		return nil
	end

	profile:Release()

	return profile.Data
end

function DataManager.AddDiscoveredNPC(Player: Player, NPCName: string)
	local Profile = Profiles[Player]
	if not Profile then
		return warn(`No data profile found for: {Player}.`)
	end

	if Profile.Data.DiscoveredNPCS[NPCName] ~= nil then
		return warn(
			`Player {Player} has already discovered NPC {NPCName}. Please refrain from multi-calling this function.`
		)
	else
		Profile.Data.DiscoveredNPCS[NPCName] = {
			["Name"] = NPCName,
		}
	end
end

function DataManager.RemoveDiscoveredNPC(Player: Player, NPCName: string)
	local Profile = Profiles[Player]
	if not Profile then
		return warn(`No data profile found for: {Player}.`)
	end

	Profile.Data.DiscoveredNPCS[NPCName] = nil
end

function DataManager.UpdateSavedInventory(Player: Player, NewInventory: any)
	local Profile = Profiles[Player]
	if not Profile then
		return warn(`No data profile found for: {Player}.`)
	end

	Profile.Data.SavedInventory = NewInventory
end

function DataManager.AddCurrency(Player: Player, AddAmount: number)
	local Profile = Profiles[Player]
	if not Profile then
		return warn(`No data profile found for: {Player}.`)
	end

	Profile.Data.Currency += AddAmount

	local Leaderstats = Player:FindFirstChild("leaderstats")
	if not Leaderstats then
		return warn(`No leaderstats found for player {Player}`)
	end

	local CurrencyLeaderstat = Leaderstats:FindFirstChild("F$")
	if not CurrencyLeaderstat then
		return warn(`Failed to find a "F$" Currency Leaderstat for player {Player}.`)
	end

	CurrencyLeaderstat.Value = NumberUtils:FormatNumber(Profile.Data.Currency)

	UpdateUI:FireClient(Player, "currency", Profile.Data.Currency)
end

function DataManager.SetCurrency(Player: Player, NewAmount: number)
	local Profile = Profiles[Player]
	if not Profile then
		return warn(`No data profile found for: {Player}.`)
	end

	Profile.Data.Currency = NewAmount

	local Leaderstats = Player:FindFirstChild("leaderstats")
	if not Leaderstats then
		return warn(`No leaderstats found for player {Player}`)
	end

	local CurrencyLeaderstat = Leaderstats:FindFirstChild("F$")
	if not CurrencyLeaderstat then
		return warn(`Failed to find a "F$" Currency Leaderstat for player {Player}.`)
	end

	CurrencyLeaderstat.Value = NumberUtils:FormatNumber(Profile.Data.Currency)

	UpdateUI:FireClient(Player, "currency", Profile.Data.Currency)
end

function DataManager.UnlockSatchel(User: Player, SatchelName: string)
	local Profile = Profiles[User]
	if not Profile then
		return warn(`No data profile found for: {User}.`)
	end

	Profile.Data.OwnedSatchels[SatchelName] = true
end

function DataManager.LockSatchel(User: Player, SatchelName: string)
	local Profile = Profiles[User]
	if not Profile then
		return warn(`No data profile found for: {User}.`)
	end

	Profile.Data.OwnedSatchels[SatchelName] = false
end

function DataManager.BanUser(User: Player, BanReason: string, Time: number)
	local Profile = Profiles[User]
	if not Profile then
		return warn(`No data profile found for: {User}.`)
	end

	if Time == -1 then
		Time = "inf"
	end

	Profile.Data.Banned = true

	if Time == -1 then
		Profile.Data.BanReason =
			`You have been permenantley banned for reason: "{BanReason}", if you feel this was incorrect, let us know in the community server.`
	else
		Profile.Data.BanReason =
			`You have been banned for {Time} seconds for the reason: "{BanReason}, if you feel this was incorrect, let us know in the community server.`
	end

	Profile.Data.BanTime = os.time()
	Profile.Data.BanLength = Time
end

function DataManager.Unban(Player: Player)
	local Profile = Profiles[Player]
	if not Profile then
		return warn(`No data profile found for: {Player}.`)
	end

	Profile.Data.Banned = false
	Profile.Data.BanReason = nil
	Profile.Data.BanTime = nil
	Profile.Data.BanLength = nil
end

function DataManager.LevelUp(Player: Player, Amount: number)
	local Profile = Profiles[Player]
	if not Profile then
		return warn(`No data profile found for: {Player}.`)
	end

	Profile.Data.Level += Amount

	UpdateUI:FireClient(Player, "level", Profile.Data.Level)
end

function DataManager.SetLevel(Player: Player, Level: number)
	local Profile = Profiles[Player]
	if not Profile then
		return warn(`No data profile found for: {Player}.`)
	end

	Profile.Data.Level = Level

	UpdateUI:FireClient(Player, "level", Profile.Data.Level)
end

------------------------------
--\\ Main //--
------------------------------

Local.OnStart()

return DataManager
