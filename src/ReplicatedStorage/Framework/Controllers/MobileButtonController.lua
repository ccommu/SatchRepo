--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CustomButton = script:WaitForChild("CustomButton")

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}

local TouchGui
local TouchControlFrame
local JumpButton

local CanMakeButtons = false

--------------------------------
--\\ Private Functions //--
--------------------------------


--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:CreateCustomButton(Image, SizePrecentage)
	if CanMakeButtons then
		local NewButton = CustomButton:Clone()
		if not SizePrecentage then SizePrecentage = 70/100 end
		
		local NewSize = UDim2.new(0, JumpButton.Size.X.Offset * SizePrecentage, 0, JumpButton.Size.Y.Offset * SizePrecentage)
		
		local centerXOffset = JumpButton.Position.X.Offset + (JumpButton.Size.X.Offset / 2) - (NewSize.X.Offset / 2)
		local NewPosition = UDim2.new(JumpButton.Position.X.Scale, centerXOffset, JumpButton.Position.Y.Scale, JumpButton.Position.Y.Offset - JumpButton.Size.Y.Offset)
		
		NewButton.Size = NewSize
		NewButton.Position = NewPosition
		NewButton.Parent = TouchControlFrame
		
		if Image then 
			NewButton:WaitForChild("ImageLabel").Image = "rbxassetid://"..tostring(Image)
		end
		
		return NewButton
	else
		warn("Cannot make touch buttons for players that are not on mobile.")
	end
end

function Controller:IsMobile()
	return CanMakeButtons
end

function Controller:OnStart()
	print(`Mobile Button Controller Initiated.`)
	
	pcall(function()
		TouchGui = PlayerGui:WaitForChild("TouchGui", 5)
	end)
	
	if TouchGui then
		print(`Mobile player, starting mobile button controller`)
		CanMakeButtons = true
		TouchControlFrame = TouchGui:WaitForChild("TouchControlFrame")
		JumpButton = TouchControlFrame:WaitForChild("JumpButton")
	end
end


--------------------------------
--\\ Main //--
--------------------------------

return Controller