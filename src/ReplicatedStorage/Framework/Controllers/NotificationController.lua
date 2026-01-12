--------------------------------
--\\ Services //--
--------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--------------------------------
--\\ Constants //--
--------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui") :: ScreenGui
local NotificationsFrame = MainGui:WaitForChild("Notifications") :: Frame

local NotificationExampleFrame = NotificationsFrame:WaitForChild("NotificationExample") :: Frame
local LowerNotifExampleFrame = NotificationsFrame:WaitForChild("LongNotificationExample") :: Frame

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local MiscEvents = Networking:WaitForChild("Misc")

local AreaNotification = MiscEvents:WaitForChild("AreaNotification")
local LowerNotification = MiscEvents:WaitForChild("LowerNotification")
local WarningNotification = MiscEvents:WaitForChild("Warning")

local WarningGroup = MainGui:WaitForChild("Warning")

local OriginalWarningPosition = UDim2.new(0.298, 0, 0.903, 0)
local LowerWarningPosition = UDim2.new(0.298, 0, 1.1,  0)

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function AnimateNotification(NotificationFrame : Frame)
	NotificationFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	local TI = TweenInfo.new(10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	
	local MoveTween = TweenService:Create(NotificationFrame, TI, {Position = UDim2.new(0.5, 0, 0.944, 0)})
	local TransparencySeperatorTween = TweenService:Create(NotificationFrame:WaitForChild("Seperator"), TI, {BackgroundTransparency = 1})
	local TransparencyDetailsTextTween = TweenService:Create(NotificationFrame:FindFirstChild("Details"), TI, {TextTransparency = 1})
	local TransparencyOverallTextTween = TweenService:Create(NotificationFrame:FindFirstChild("Overall"), TI, {TextTransparency = 1})
	
	NotificationFrame.Visible = true
	
	MoveTween:Play()
	TransparencySeperatorTween:Play()
	TransparencyOverallTextTween:Play()
	TransparencyDetailsTextTween:Play()
	
	TransparencyDetailsTextTween.Completed:Connect(function()
		NotificationFrame:Destroy()
	end)
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:DisplayNotification(NotificationTopText : string, NotificationLowerText : string)
	local Notification = NotificationExampleFrame:Clone()
	
	Notification:WaitForChild("Details").Text = NotificationLowerText
	Notification:WaitForChild("Overall").Text = string.upper(NotificationTopText)
	
	Notification.Parent = NotificationsFrame
	
	AnimateNotification(Notification)
end

function Controller:DisplayNotificationLower(NotificationText : string)
	local Notification = LowerNotifExampleFrame:Clone()
	
	Notification:WaitForChild("Text").Text = NotificationText
	
	Notification.Parent = NotificationsFrame
	
	local TI = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	
	Notification.BackgroundTransparency = 1
	
	Notification:FindFirstChild("Text").TextTransparency = 1
	Notification:FindFirstChild("Text"):FindFirstChild("UIStroke").Transparency = 1
	
	Notification.Visible = true
	
	local MainTransparencyTween = TweenService:Create(Notification, TI, {BackgroundTransparency = 0.5})
	local TextTransparencyTween = TweenService:Create(Notification:FindFirstChild("Text"), TI, {TextTransparency = 0.2})
	local TextUIStrokeTransparencyTween = TweenService:Create(Notification:FindFirstChild("Text"):FindFirstChild("UIStroke"), TI, {Transparency = 0.5})
	
	MainTransparencyTween:Play()
	TextTransparencyTween:Play()
	TextUIStrokeTransparencyTween:Play()
	
	task.delay(0.5, function()
		local HideTI = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		
		local HideMainTween = TweenService:Create(Notification, HideTI, {BackgroundTransparency = 1})
		local HideTextTween = TweenService:Create(Notification:FindFirstChild("Text"), HideTI, {TextTransparency = 1})
		local HideStrokeTween = TweenService:Create(Notification:FindFirstChild("Text"):FindFirstChild("UIStroke"), HideTI, {Transparency = 1})
		
		HideMainTween:Play()
		HideTextTween:Play()
		HideStrokeTween:Play()
	end)
end

function Controller:DisplayWarning(WarningText : string)
	local Warning = WarningGroup:Clone() :: CanvasGroup
	
	Warning:WaitForChild("TextLabel").Text = WarningText
	Warning.Position = LowerWarningPosition
	
	Warning.GroupTransparency = 1
	Warning.Visible = true
	Warning.Parent = WarningGroup.Parent
	
	local OpenTween = TweenService:Create(Warning, TweenInfo.new(1.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {GroupTransparency = 0, Position = OriginalWarningPosition})
	OpenTween:Play()
	
	OpenTween.Completed:Wait()
	
	task.wait(5)
	local CloseTween = TweenService:Create(Warning, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = LowerWarningPosition})
	CloseTween:Play()
	
	CloseTween.Completed:Wait()
	Warning:Destroy()
end

function Controller:OnStart()
	NotificationExampleFrame.Visible = false
	
	AreaNotification.OnClientEvent:Connect(function(AreaName)
		Controller:DisplayNotification("Entering:", AreaName)
	end)
	
	LowerNotification.OnClientEvent:Connect(function(Text)
		Controller:DisplayNotificationLower(Text)
	end)
	
	WarningNotification.OnClientEvent:Connect(function(WarningText)
		Controller:DisplayWarning(WarningText)
	end)
	
	print("NotificationController Initiated.")
end


--------------------------------
--\\ Main //--
--------------------------------

return Controller