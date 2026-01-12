--------------------------------
--\\ Services //--
--------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------
--\\ Constants //--
--------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Camera = workspace.CurrentCamera
local CompassFrame = PlayerGui:WaitForChild("MainGui"):WaitForChild("CompassFrame")

local Directions = {
	N = 0,
	NE = math.pi / 4,
	E = math.pi / 2,
	SE = 3 * math.pi / 4,
	S = math.pi,
	SW = -3 * math.pi / 4,
	W = -math.pi / 2,
	NW = -math.pi / 4,
}

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}
local HandleTransparency = true

--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:TemporarilyDisableTransparencyHandling(DisableTransparency : boolean)
	if DisableTransparency == true then
		HandleTransparency = false
	else
		HandleTransparency = true
	end
end

function Controller:OnStart()
	print("CompassController Initiated.")
	
	RunService.RenderStepped:Connect(function()
		local Look = Camera.CFrame.LookVector
		local Angle = math.atan2(-Look.X, -Look.Z)
		
		for Name, DirAngle in pairs(Directions) do
			local Label = CompassFrame:FindFirstChild(Name)
			
			if Label then
				local Offset = math.sin(Angle - DirAngle)
				local Facing = math.cos(Angle - DirAngle)
				
				Label.Position = UDim2.new(0.5 + Offset * 0.4, 0, 0.5, 0)
				if Facing > 0 then
					Label.Visible = true
					
					if HandleTransparency then
						Label.TextTransparency = 1 - Facing
					else
						Label.TextTransparency = 1
					end
				else
					Label.Visible = false
				end
			end
		end
	end)
end


--------------------------------
--\\ Main //--
--------------------------------

return Controller