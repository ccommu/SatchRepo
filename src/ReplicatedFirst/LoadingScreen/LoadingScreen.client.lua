--------------------------------
--\\ Services //--
--------------------------------

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

--------------------------------
--\\ Constants //--
--------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local LoadingScreen = script.Parent
local ContinueLabel = LoadingScreen:WaitForChild("Frame"):WaitForChild("ContinueLabel")
local SkipButton = LoadingScreen:FindFirstChild("Frame"):WaitForChild("Skip")

--------------------------------
--\\ Variables //--
--------------------------------

local AllAssets = game:GetChildren()
local CloseScreenDB = false

--------------------------------
--\\ Util Functions //--
--------------------------------

local function CloseScreen()
	local TI = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	
	local FrameTween = TweenService:Create(LoadingScreen:FindFirstChild("Frame"), TI, {BackgroundTransparency = 1})
	local SkipButtonTween = TweenService:Create(SkipButton, TI, {TextTransparency = 1})
	local ContinueLabelTween = TweenService:Create(ContinueLabel, TI, {TextTransparency = 1})
	
	local HalftoneDotTween = TweenService:Create(LoadingScreen:FindFirstChild("Frame"):WaitForChild("HalftoneDots"), TI, {ImageTransparency = 1})
	local HalftoneDotTween2 = TweenService:Create(LoadingScreen:FindFirstChild("Frame"):FindFirstChild("HalftoneDots"):WaitForChild("HalftoneDots2"), TI, {ImageTransparency = 1})
	
	local LogoTween = TweenService:Create(LoadingScreen:FindFirstChild("Frame"):FindFirstChild("Logo"), TI, {ImageTransparency = 1})
	
	FrameTween:Play()
	SkipButtonTween:Play()
	ContinueLabelTween:Play()
	HalftoneDotTween:Play()
	HalftoneDotTween2:Play()
	LogoTween:Play()
	
	HalftoneDotTween.Completed:Wait()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	
	StarterGui:SetCore("ResetButtonCallback", false)
	
	LoadingScreen.Enabled = false
end

--------------------------------
--\\ Main //--
--------------------------------

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

ReplicatedFirst:RemoveDefaultLoadingScreen()
LoadingScreen.Parent = PlayerGui

task.spawn(function()
	task.wait(5)
	SkipButton.Visible = true
	
	SkipButton.Activated:Connect(function()
		if CloseScreenDB then return end 
		CloseScreenDB = true
		CloseScreen()
	end)
end)

for Index, Asset in pairs(AllAssets) do
	ContentProvider:PreloadAsync({Asset})
	--print(`Loading {Asset}...`)
	--print(`Progress: {Index / #AllAssets}...`)
end

ContinueLabel.Text = "[Press Anywhere To Continue]"
PlayerGui:WaitForChild("MainGui").Enabled = true

UserInputService.InputBegan:Connect(function()
	if CloseScreenDB then return end
	CloseScreenDB = true
	CloseScreen()
end)

UserInputService.TouchPan:Connect(function()
	if CloseScreenDB then return end 
	CloseScreenDB = true
	CloseScreen()
end)