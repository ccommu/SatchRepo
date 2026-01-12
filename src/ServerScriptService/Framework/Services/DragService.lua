--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local MiscEvents = Networking:WaitForChild("Misc")
local DragRequest = MiscEvents:WaitForChild("DragRequest")

--------------------------------
--\\ Variables //--
--------------------------------

local Service = {}
local ActiveDrags = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function EnsureGroup(Name)
	if not PhysicsService:IsCollisionGroupRegistered(Name) then
		PhysicsService:RegisterCollisionGroup(Name)
	end
end

local function Release(Player, Object)
	if ActiveDrags[Object] ~= Player then return end
	ActiveDrags[Object] = nil
	Object:SetAttribute("DraggedBy", nil)
	Object:SetNetworkOwner(nil)
	Object.CollisionGroup = "Default"

	if Player.Character then
		for _, Part in Player.Character:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CollisionGroup = "Default"
			end
		end
	end
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Service:OnStart()
	EnsureGroup("Dragged")

	DragRequest.OnServerInvoke = function(Player, Object, Pickup)
		if not Object or not Object:IsA("BasePart") then return false end

		if Pickup then
			if ActiveDrags[Object] then return false end

			ActiveDrags[Object] = Player
			Object:SetAttribute("DraggedBy", Player.UserId)
			Object:SetNetworkOwner(Player)
			Object.CollisionGroup = "Dragged"

			local PlayerGroup = "COL_PLAYER_" .. Player.UserId
			EnsureGroup(PlayerGroup)
			PhysicsService:CollisionGroupSetCollidable(PlayerGroup, "Dragged", false)

			if Player.Character then
				for _, Part in Player.Character:GetDescendants() do
					if Part:IsA("BasePart") then
						Part.CollisionGroup = PlayerGroup
					end
				end
			end

			return Object
		else
			Release(Player, Object)
			return true
		end
	end

	Players.PlayerRemoving:Connect(function(Player)
		for Object, Owner in pairs(ActiveDrags) do
			if Owner == Player then
				Release(Player, Object)
			end
		end
	end)
end

return Service
