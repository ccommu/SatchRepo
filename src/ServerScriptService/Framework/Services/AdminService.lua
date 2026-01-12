--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Framework = ServerScriptService:FindFirstChild("Framework")
local Services = Framework:FindFirstChild("Services")

local ServerTimeService = require(Services:FindFirstChild("ServerTimeService"))

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Networking = Shared:FindFirstChild("Networking")
local MiscEvents = Networking:FindFirstChild("Misc")
local AmIAdminRequest = MiscEvents:FindFirstChild("AmIAdmin")

--------------------------------
--\\ Variables //--
--------------------------------

local Service = {}

Service.AdminIDs = {
	[1914631401] = true, -- Me (Commu)
	[5794081167] = true, -- Joshua (CitiApparel - 5794081167)
	[-1] = true, -- TEST ACC
	[-2] = true, -- TEST ACC
}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function ManageTimeCommands()
	Players.PlayerAdded:Connect(function(Player : Player)
		if Service.AdminIDs[Player.UserId] then
			
			Player.Chatted:Connect(function(Text)
				
				if string.lower(string.sub(Text, 1, 8)) == "!addtime" then
					local amount = tonumber(string.sub(Text, 10))
					ServerTimeService:AddTime(amount)

				elseif string.lower(string.sub(Text, 1, 11)) == "!removetime" then
					local amount = tonumber(string.sub(Text, 13))
					ServerTimeService:RemoveTime(amount)

				end
			end)
		end
	end)
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Service:OnStart()
	ManageTimeCommands()
	
	AmIAdminRequest.OnServerInvoke = function(player)
		if Service.AdminIDs[player.UserId] then
			--[[ // Remove comments if i want to have headless lol
			if player.UserId == 1914631401 then
				task.spawn(function()
					local character = player.Character
					if not character then
						player.CharacterAdded:Wait()
					end

					character = player.Character
					character:FindFirstChild("Head").Transparency = 1

					player.CharacterAdded:Connect(function(Character)
						Character:FindFirstChild("Head").Transparency = 1
					end)
				end)
			end
			]]

			return true
		else
			return false
		end
	end
	
	print("AdminService Has been started.")
end


--------------------------------
--\\ Main //--
--------------------------------

return Service