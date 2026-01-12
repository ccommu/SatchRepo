--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared")

local SharedData = Shared:WaitForChild("Data")
local AnimationData = require(SharedData:WaitForChild("AnimationData"))

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function InitiateAnimation(Data)
	local IsCreditOnly = Data["CreditOnly"]
	
	local AnimationCredits = Data["Credits"] :: string
	local AnimationName = Data["Name"] :: string
	
	if not IsCreditOnly then
		local AnimationObject = Data["Animation"] :: Animation
		local AnimationVersion = Data["Version"] :: string
		local AnimationAnimator = Data["Animator"] :: Animator
		local AnimationIsLooped = Data["IsLooped"] :: boolean

		local Rig = Data["Rig"] :: Model

		print(`AnimationController - Initiating Animation: {AnimationName} for rig {Rig}. Anim Version: {AnimationVersion}, Credits go to {AnimationCredits}.`)

		local AnimTrack = AnimationAnimator:LoadAnimation(AnimationObject)

		if AnimationIsLooped then
			AnimTrack.Looped = true
		end

		AnimTrack:Play()
	else
		print(`AnimationController - Initiating Animation: {AnimationName}. Credits go to {AnimationCredits}.`)
	end
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:OnStart()
	for _, AnimData in pairs(AnimationData) do
		InitiateAnimation(AnimData)
	end
	
	print("AnimationController Initiated.")
end


--------------------------------
--\\ Main //--
--------------------------------

return Controller