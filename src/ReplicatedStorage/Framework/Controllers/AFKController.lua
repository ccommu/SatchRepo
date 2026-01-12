--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local MiscEvents = Networking:WaitForChild("Misc")
local DisplayAFKEvent = MiscEvents:WaitForChild("DisplayAFK")

--------------------------------
--\\ Variables //--
--------------------------------

local Module = {}

--------------------------------
--\\ Public Functions //--
--------------------------------

function Module:OnStart()
	print(`AFKController Initiated`)
	
	UserInputService.WindowFocusReleased:Connect(function()
		DisplayAFKEvent:FireServer(true)
	end)
	UserInputService.WindowFocused:Connect(function()
		DisplayAFKEvent:FireServer(false)
	end)
end


--------------------------------
--\\ Main //--
--------------------------------

return Module