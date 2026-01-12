--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--------------------------------
--\\ Constants //--
--------------------------------

local Animations = ReplicatedStorage:WaitForChild("Animations")
local RunningAnimFolder = Animations:WaitForChild("RunningAnimation")
local RunningAnimation = RunningAnimFolder:WaitForChild("Animation")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Framework = ReplicatedStorage:WaitForChild("Framework")
local GameManager = require(Framework:WaitForChild("GameController"))

local MobileButtonController

--------------------------------
--\\ Variables //--
--------------------------------

local Module = {}

local IsRunning = false
local RunKey = Enum.KeyCode.LeftShift
local RunSpeed = 25

local WalkSpeed = StarterPlayer.CharacterWalkSpeed
local PendingRun = false

local MobileButtonActive = false

local DefaultFOV = Camera.FieldOfView
local RunFOV = DefaultFOV + 10

local FOVTweenInfo = TweenInfo.new(
	0.6,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut
)

local ActiveFOVTween = nil

--------------------------------
--\\ Private Functions //--
--------------------------------

local function TweenFOV(TargetFOV)
	if ActiveFOVTween then
		ActiveFOVTween:Cancel()
		ActiveFOVTween = nil
	end

	ActiveFOVTween = TweenService:Create(
		Camera,
		FOVTweenInfo,
		{ FieldOfView = TargetFOV }
	)

	ActiveFOVTween:Play()
end

local function LoadRunAnimationToCharacter(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	local Animator = Humanoid:WaitForChild("Animator")

	local AnimationTrack = Animator:LoadAnimation(RunningAnimation)
	AnimationTrack.Priority = Enum.AnimationPriority.Action

	return AnimationTrack
end

local function EndRunning(Character)
	if not IsRunning then
		PendingRun = false
		return
	end

	IsRunning = false
	PendingRun = false

	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	local Animator = Humanoid and Humanoid:FindFirstChildWhichIsA("Animator")
	if not Humanoid or not Animator then return end

	Humanoid.WalkSpeed = WalkSpeed
	TweenFOV(DefaultFOV)

	for _, Anim in ipairs(Animator:GetPlayingAnimationTracks()) do
		if Anim.Animation.AnimationId == RunningAnimation.AnimationId then
			Anim:Stop()
		end
	end
end

local function StartRunning(Character)
	if IsRunning then return end

	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	if not Humanoid then return end

	local Track = LoadRunAnimationToCharacter(Character)
	Track:Play()

	Humanoid.WalkSpeed = RunSpeed
	IsRunning = true
	PendingRun = false

	TweenFOV(RunFOV)
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Module:OnStart()
	print(`RunningController Initiated`)

	repeat task.wait() until GameManager:IsGameLoaded() == true

	MobileButtonController = GameManager:GetController("MobileButtonController")

	local Character = Player.Character
	if not Character then
		Player.CharacterAdded:Wait()
		Character = Player.Character
	end

	local Humanoid = Character:WaitForChild("Humanoid")

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode ~= RunKey then return end

		if Humanoid.MoveDirection.Magnitude > 0.01 then
			StartRunning(Character)
		else
			PendingRun = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode ~= RunKey then return end

		EndRunning(Character)
	end)

	task.delay(2, function()
		if MobileButtonController:IsMobile() then
			local Button = MobileButtonController:CreateCustomButton(9525535512, 70 / 100)
			Button.Activated:Connect(function()
				if MobileButtonActive then
					Button.ImageColor3 = Color3.fromRGB(255, 255, 255)
					EndRunning(Character)
					MobileButtonActive = false
				else
					Button.ImageColor3 = Color3.fromRGB(0, 0, 0)
					MobileButtonActive = true
					if Humanoid.MoveDirection.Magnitude > 0.01 then
						StartRunning(Character)
					else
						PendingRun = true
					end
				end
			end)
		end
	end)

	RunService.RenderStepped:Connect(function()
		Character = Player.Character
		if not Character then return end
		Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
		if not Humanoid then return end

		local moving = Humanoid.MoveDirection.Magnitude > 0.01
		local holding = UserInputService:IsKeyDown(RunKey)
		if MobileButtonActive then holding = true end

		if PendingRun then
			if holding and moving then
				StartRunning(Character)
			elseif not holding then
				PendingRun = false
			end
		end

		if IsRunning then
			if (not holding) or (not moving) then
				EndRunning(Character)
			end
		end
	end)
end

--------------------------------
--\\ Main //--
--------------------------------

return Module
