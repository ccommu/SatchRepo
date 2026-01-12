--------------------------------
--\\ Services //--
--------------------------------

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Networking = Shared:FindFirstChild("Networking")
local MiscEvents = Networking:FindFirstChild("Misc")
local Debug = MiscEvents:FindFirstChild("Debug")

local Framework = ServerScriptService:FindFirstChild("Framework")
local Services = Framework:FindFirstChild("Services")

local AdminService = require(Services.AdminService)
local SecurityService = require(Services.SecurityService)
local RemoteSecurity = require(Framework:FindFirstChild("Utils"):FindFirstChild("RemoteSecurity"))

--------------------------------
--\\ Variables //--
--------------------------------

local DebugAllServerType = "S-All"
local DebugSelected = "S-Select"

local Service = {}

local Disabled = false
local CurrentType = nil

--------------------------------
--\\ Public Functions //--
--------------------------------

function Service:LogMessage(Message: string, MessageType: string)
	if CurrentType == DebugSelected then
		Debug:FireAllClients(Message, MessageType)
	end
end

function Service:OnStart()
	Debug.OnServerEvent:Connect(function(fromPlayer, debugType, disable)
		if typeof(fromPlayer) ~= "Instance" or not fromPlayer:IsA("Player") then
			return
		end
		if typeof(debugType) ~= "string" then
			return
		end
		if typeof(disable) ~= "boolean" and typeof(disable) ~= "nil" then
			return
		end

		local ok = RemoteSecurity:CheckCooldown(fromPlayer, "DebugEvent", 1)
		if not ok then
			return
		end

		if not AdminService.AdminIDs[fromPlayer.UserId] then
			SecurityService:BanUser(fromPlayer, "Exploiting.", -1)
			return
		end

		if disable == true then
			Disabled = true
		end

		if debugType == DebugAllServerType then
			CurrentType = DebugAllServerType
		elseif debugType == DebugSelected then
			CurrentType = DebugSelected
		end
	end)

	LogService.MessageOut:Connect(function(message, messageType)
		if CurrentType == DebugAllServerType and Disabled == false then
			local tag
			if messageType == Enum.MessageType.MessageOutput then
				tag = "O"
			elseif messageType == Enum.MessageType.MessageWarning then
				tag = "W"
			elseif messageType == Enum.MessageType.MessageInfo then
				tag = "I"
			end
			if tag then
				Debug:FireAllClients(message, tag)
			end
		end
	end)

	LogService.MessageOut:Connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageError then
			Debug:FireAllClients(message, "E")
		end
	end)

	print(`DebugService Started.`)
end

--------------------------------
--\\ Main //--
--------------------------------

return Service
