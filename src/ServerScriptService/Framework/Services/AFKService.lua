--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local RemoteSecurity =
	require(ServerScriptService:FindFirstChild("Framework"):FindFirstChild("Utils"):FindFirstChild("RemoteSecurity"))

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Networking = Shared:FindFirstChild("Networking")
local MiscEvents = Networking:FindFirstChild("Misc")
local DisplayAFKEvent = MiscEvents:FindFirstChild("DisplayAFK")

local AFKBillboardGui = ReplicatedStorage:FindFirstChild("AFK-BillboardGui")

--------------------------------
--\\ Variables //--
--------------------------------

local Module = {}

--------------------------------
--\\ Public Functions //--
--------------------------------

function Module:OnStart()
	print(`AFKService Initiated`)

	DisplayAFKEvent.OnServerEvent:Connect(function(player, enable)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return
		end
		if typeof(enable) ~= "boolean" then
			return
		end
		local ok = RemoteSecurity:CheckCooldown(player, "DisplayAFK", 0.05)
		if not ok then
			return
		end

		if enable == true and player:GetAttribute("AFK") ~= true then
			player:SetAttribute("AFK", true)

			local BillboardGui = AFKBillboardGui:Clone()
			local Character = player.Character
			if not Character then
				return
			end

			local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			if not HumanoidRootPart then
				return
			end

			BillboardGui.Parent = HumanoidRootPart
		elseif enable == false and player:GetAttribute("AFK") == true then
			player:SetAttribute("AFK", false)

			local Character = player.Character
			if not Character then
				return
			end

			local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			if not HumanoidRootPart then
				return
			end

			local BillboardGui = HumanoidRootPart:FindFirstChild("AFK-BillboardGui")
			if not BillboardGui then
				return
			end

			BillboardGui:Destroy()
		end
	end)
end

--------------------------------
--\\ Main //--
--------------------------------

return Module
