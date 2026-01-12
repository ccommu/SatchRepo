--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local SharedData = Shared:FindFirstChild("Data")

local AnimationData = require(SharedData:FindFirstChild("AnimationData"))

--------------------------------
--\\ Variables //--
--------------------------------

local Module = {}


--------------------------------
--\\ Private Functions //--
--------------------------------

local function InitiateAnimation(Data)
	local IsOnlyCredits = Data["CreditOnly"]
	
	local AnimationCredits = Data["Credits"] :: string
	local AnimationName = Data["Name"] :: string
	
	if not IsOnlyCredits then
		local AnimationObject = Data["Animation"] :: Animation
		local AnimationVersion = Data["Version"] :: string
		local AnimationAnimator = Data["Animator"] :: Animator
		local AnimationIsLooped = Data["IsLooped"] :: boolean

		local Rig = Data["Rig"] :: Model

		print(`AnimationService - Initiating Animation: {AnimationName} for rig {Rig}. Anim Version: {AnimationVersion}, Credits go to {AnimationCredits}.`)

		local AnimTrack = AnimationAnimator:LoadAnimation(AnimationObject)

		if AnimationIsLooped then
			AnimTrack.Looped = true
		end

		AnimTrack:Play()

		Rig:FindFirstChild("HumanoidRootPart"):SetNetworkOwner(nil)
	else
		print(`AnimationController - Initiating Animation: {AnimationName}. Credits go to {AnimationCredits}.`)
	end
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Module:OnStart()
	for _, AnimData in pairs(AnimationData) do
		InitiateAnimation(AnimData)
	end
	
	print("Initiated AnimationService")
end


--------------------------------
--\\ Main //--
--------------------------------

return Module