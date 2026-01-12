--------------------------------
--\\ Services //--
--------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Networking = Shared:FindFirstChild("Networking")
local MiscEvents = Networking:FindFirstChild("Misc")
local AreaNotificiationEvent = MiscEvents:WaitForChild("AreaNotification")

--------------------------------
--\\ Variables //--
--------------------------------

local Service = {}

--------------------------------
--\\ Public Functions //--
--------------------------------

function Service:OnStart()
	local Areas = CollectionService:GetTagged("AreaDistinction")

	local Active = {}

	local function IsCharacterInArea(Character, Area)
		local Root = Character:FindFirstChild("HumanoidRootPart")
		if not Root then return false end

		local Params = OverlapParams.new()
		Params.FilterType = Enum.RaycastFilterType.Include
		Params.FilterDescendantsInstances = { Root }

		local Parts = workspace:GetPartBoundsInBox(
			Area.CFrame,
			Area.Size,
			Params
		)

		return #Parts > 0
	end

	for _, Area in ipairs(Areas) do
		if not Area:IsA("BasePart") then continue end

		local AreaName = Area:GetAttribute("AreaName")
		if not AreaName then continue end

		Active[Area] = {}

		RunService.Heartbeat:Connect(function()
			for _, Player in ipairs(Players:GetPlayers()) do
				local Character = Player.Character
				if not Character then continue end

				local Inside = IsCharacterInArea(Character, Area)

				if Inside and not Active[Area][Player] then
					Active[Area][Player] = true
					AreaNotificiationEvent:FireClient(Player, AreaName)

				elseif not Inside and Active[Area][Player] then
					Active[Area][Player] = nil
				end
			end
		end)
	end
	
	print("NotificationService Initiated.")
end


--------------------------------
--\\ Main //--
--------------------------------

return Service