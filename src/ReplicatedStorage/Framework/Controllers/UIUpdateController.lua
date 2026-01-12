--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local Misc = Networking:WaitForChild("Misc")
local UpdateUIEvent = Misc:WaitForChild("UpdateUI")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local MainGui = PlayerGui:WaitForChild("MainGui")
local InfoFrame = MainGui:WaitForChild("Info")
local ServerInfoFrame = InfoFrame:WaitForChild("ServerInfo")

local SeasonImageLabel = ServerInfoFrame:WaitForChild("Season")
local TimeImageLabel = ServerInfoFrame:WaitForChild("Time")
local WeatherImageLabel = ServerInfoFrame:WaitForChild("Weather")

local CurrencyLabel = InfoFrame:WaitForChild("Currency")
local LevelLabel = InfoFrame:WaitForChild("Level")

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}

--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:OnStart()
	print(`UI Update Controller Started.`)
	
	UpdateUIEvent.OnClientEvent:Connect(function(change, NewVal)
		if change == "currency" then
			CurrencyLabel.Text = tostring(NewVal).." F$"
		elseif change == "level" then
			LevelLabel.Text = "Level "..tostring(NewVal)
		elseif change == "season" then
			SeasonImageLabel.Image = "rbxassetid://"..tostring(NewVal)
		elseif change == "time" then
			TimeImageLabel.Image = "rbxassetid://"..tostring(NewVal)
		elseif change == "weather" then
			WeatherImageLabel.Image = "rbxassetid://"..tostring(NewVal)
		else
			warn(`Invalid change type of: {change}.`)
		end
	end)
end

--------------------------------
--\\ Main //--
--------------------------------

return Controller