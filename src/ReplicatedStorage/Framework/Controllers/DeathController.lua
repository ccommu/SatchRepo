--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local MiscEvents = Networking:WaitForChild("Misc")

local DiedEvent = MiscEvents:WaitForChild("Died")

local InitialTI = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local OutTI = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local DeathTextTI = TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, true)

local DeathText = "You Died..."
local DeathTextColor = Color3.fromRGB(172, 144, 96)
local DeathTextStrokeColor = Color3.fromRGB(64, 46, 33)

--------------------------------
--\\ Variables //--
--------------------------------

local Module = {}

local Open = false

--------------------------------
--\\ Private Functions //--
--------------------------------

function CreateAndAnimateText(Frame : Frame)
	local Text = Instance.new("TextLabel")
	Text.Parent = Frame
	
	Text.Text = DeathText
	Text.TextColor3 = DeathTextColor
	Text.TextStrokeColor3 = DeathTextStrokeColor
	Text.TextStrokeTransparency = 0
	Text.Font = Enum.Font.DenkOne
	Text.Transparency = 1
	Text.Visible = true
	Text.ZIndex = 100
	Text.TextScaled = true
	
	Text.Size = UDim2.new(0.5, 0, 0.5, 0)
	Text.Position = UDim2.new(0.5, 0, 0.5, 0)
	Text.AnchorPoint = Vector2.new(0.5, 0.5)
	
	local VisibleText = TweenService:Create(Text, InitialTI, {TextTransparency = 0.5})
	VisibleText:Play()
	
	local LeftTween = TweenService:Create(Text, DeathTextTI, {Rotation = -2})
	local RightTween = TweenService:Create(Text, DeathTextTI, {Rotation = 2})
	
	task.spawn(function()
		while Open == true do
			LeftTween:Play()
			LeftTween.Completed:Wait()
			RightTween:Play()
			RightTween.Completed:Wait()
		end
	end)
	
	--// After the frame closes
	while Open == true do task.wait() end
	local CloseTween = TweenService:Create(Text, OutTI, {TextTransparency = 1, TextStrokeTransparency = 1})
	CloseTween:Play()
	
	CloseTween.Completed:Wait()
	Text:Destroy()
end

function DeathScreen()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Parent = Player.PlayerGui
	ScreenGui.IgnoreGuiInset = true
	
	local BackgroundFrame = Instance.new("Frame")
	BackgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	BackgroundFrame.BackgroundTransparency = 1
	BackgroundFrame.Size = UDim2.new(1, 0, 1, 0)
	BackgroundFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	BackgroundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	BackgroundFrame.Parent = ScreenGui
	
	BackgroundFrame.ZIndex = 50
	
	local OpenTween = TweenService:Create(BackgroundFrame, InitialTI, {BackgroundTransparency = 0})
	local CloseTween = TweenService:Create(BackgroundFrame, OutTI, {BackgroundTransparency = 1})
	
	OpenTween:Play()
	Open = true
	task.spawn(CreateAndAnimateText, BackgroundFrame)
	
	OpenTween.Completed:Wait()
	task.wait(5)
	CloseTween:Play()
	Open = false
	
	CloseTween.Completed:Wait()
	ScreenGui:Destroy()
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Module:OnStart()
	print(`DeathController Initiated`)
	
	DiedEvent.OnClientEvent:Connect(DeathScreen)
end

--------------------------------
--\\ Main //--
--------------------------------

return Module