--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local SharedData = Shared:FindFirstChild("Data")

local NPCData = require(SharedData:FindFirstChild("NPCData"))
local NPCNameTag = ReplicatedStorage:FindFirstChild("NPCNameTag")

local IsNPCUnlocked = Shared:WaitForChild("Networking"):WaitForChild("NPC"):WaitForChild("IsUnlockedNPC")

local Player = Players.LocalPlayer

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}


--------------------------------
--\\ Private Functions //--
--------------------------------

local function InFadeTween(NameTag : BillboardGui)
	local Label = NameTag:FindFirstChild("Label") :: TextLabel
	if not Label then return warn(`No label found in billboardGui {NameTag}.`) end

	Label.TextTransparency = 1
	Label:FindFirstChild("UIStroke").Transparency = 1

	local TransparencyTween = TweenService:Create(Label, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false), {TextTransparency = 0})
	local OffsetTween = TweenService:Create(NameTag, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 0, true), {StudsOffset = Vector3.new(0, 2.6, 0)})
	local UIStrokeTween = TweenService:Create(Label:FindFirstChild("UIStroke"), TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false), {Transparency = 0.5})
	
	TransparencyTween:Play()
	OffsetTween:Play()
	UIStrokeTween:Play()
end

local function FadeOutTween(NameTag : BillboardGui)
	local Label = NameTag:FindFirstChild("Label") :: TextLabel
	if not Label then return warn(`No label found in billboardGui {NameTag}.`) end

	Label.TextTransparency = 0
	Label:FindFirstChild("UIStroke").Transparency = 0.5

	local TransparencyTween = TweenService:Create(Label, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false), {TextTransparency = 1})
	local UIStrokeTween = TweenService:Create(Label:FindFirstChild("UIStroke"), TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false), {Transparency = 1})

	TransparencyTween:Play()
	UIStrokeTween:Play()
end


--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:InitializeNPCs()
	for NPCDATANAME, RecievedData in pairs(NPCData) do
		task.spawn(function()
			local UnlockedName = RecievedData["Name"] :: string
			local IsAutoDiscovered = RecievedData["AutoDiscovered"] :: boolean
			local Rig = RecievedData["Rig"] :: Model

			local Head = Rig:WaitForChild("Head")

			local Character = Player.Character or Player.CharacterAdded:Wait()
			Character = Player.Character

			local HMRP = Character:FindFirstChild("HumanoidRootPart")

			local NameTag = NPCNameTag:Clone()
			NameTag:FindFirstChild("Label").TextTransparency = 1
			NameTag:FindFirstChild("Label"):FindFirstChild("UIStroke").Transparency = 1
			NameTag.Parent = Head

			local IsVisible = false
			
			if IsNPCUnlocked:InvokeServer(NPCDATANAME) == true then
				NameTag:FindFirstChild("Label").Text = UnlockedName
			end

			RunService.RenderStepped:Connect(function()
				if not HMRP then return end

				local distance = (HMRP.Position - Head.Position).Magnitude
				if distance <= 15 then
					if not IsVisible then
						IsVisible = true
						InFadeTween(NameTag)
					end
				else
					if IsVisible then
						IsVisible = false
						FadeOutTween(NameTag)
					end
				end
			end)
		end)
	end
end

function Controller:UpdateNPCName(NPC : Model, NewDisplayName : string)
	local Head = NPC:FindFirstChild("Head")
	if not Head then return end
	
	if Head:FindFirstChild("NPCNameTag") then
		Head:FindFirstChild("NPCNameTag"):FindFirstChild("Label").Text = NewDisplayName
	else
		return warn(`Supposed NPC model {NPC}'s head doesn't contain a "NPCNameTag" which is required to change the visible name.`)
	end
end

function Controller:OnStart()
	Controller:InitializeNPCs()
	
	print("Initited NPC Controller")
end

--------------------------------
--\\ Main //--
--------------------------------

return Controller