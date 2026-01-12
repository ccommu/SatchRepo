local StartTime = tick()
--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui")

local Framework = script.Parent
local Controllers = Framework:WaitForChild("Controllers")

local ServerInfo = ReplicatedStorage:WaitForChild("ServerInfo")
local ServerTime = ServerInfo:WaitForChild("InGameTime")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local CameraShaker = require(Packages:WaitForChild("CameraShaker"))
local Icon = require(Packages:WaitForChild("Icon"))

local Camera = workspace.CurrentCamera
local RenderPriority = Enum.RenderPriority.Camera.Value + 1

local StillTime = 0
local RequiredTime = 2
local SpeedThreshold = 0.1

local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local QuestsChatClosedPosition = UDim2.fromScale(0.157, 0.141)
local QuestsChatOpenPosition = UDim2.fromScale(0.156, 0.45)

--------------------------------
--\\ Variables //--
--------------------------------

local Manager = {}
local LoadedControllers = {}

local GameLoaded = false

local InitiatedControllers = 0
local SuccessfulControllerInitations = 0

--------------------------------
--\\ Private Functions //--
--------------------------------

function Manager:_InitiateControllers()
	for _, Controller in Controllers:GetDescendants() do
		if Controller:IsA("ModuleScript") then
			local Required = require(Controller)
			LoadedControllers[Controller.Name] = Controller

			local s, f = pcall(function()
				task.spawn(Required.OnStart)
				InitiatedControllers += 1
			end)

			if f then
				warn(`GameController -- Failed to run :OnStart on controller {Controller}.`)
				if Controller:HasTag("critical") then
					Player:Kick("An error occured while loading the client framework, causing a critical module to not load. Please contact support in our communications server immediately.")
				end
			else
				SuccessfulControllerInitations += 1
			end
		end
	end
end

-- FOR SOME REASON... This only works as a normal function 🤦‍
function CamShake(shakeCF)
	Camera.CFrame = Camera.CFrame * shakeCF
end

function Manager:_UpdateTime()
	task.spawn(function()
		local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		local MainGui = PlayerGui:WaitForChild("MainGui")

		local TimeFrame = MainGui:WaitForChild("Time")
		local TimeLabel = TimeFrame:WaitForChild("TimeLabel")

		local AmericanLabel = TimeFrame:WaitForChild("AmericanTime")

		while task.wait(1) do
			TimeLabel.Text = ServerTime.Value

			local Hour, Minute = ServerTime.Value:match("^(%d%d):(%d%d)$")
			Hour, Minute = tonumber(Hour), tonumber(Minute)

			local Suffix = "AM"
			local DisplayHour = Hour

			if Hour == 0 then
				DisplayHour = 12
			elseif Hour == 12 then
				Suffix = "PM"
			elseif Hour > 12 then
				DisplayHour = Hour - 12
				Suffix = "PM"
			end

			AmericanLabel.Text = string.format("%d:%02d %s", DisplayHour, Minute, Suffix)
		end
	end) 
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Manager:IsGameLoaded()
	return GameLoaded
end

function Manager:GetController(ControllerName : string, calledBy : string)
	if LoadedControllers[ControllerName] then
		return require(LoadedControllers[ControllerName])
	else
		return error(`GameController -- Couldn't find a controller called: {ControllerName}. Requested by controller: {calledBy}.`)
	end
end

function Manager:Init()
	print(`INITIATING CLIENT GAME CONTROLLER FOR PLAYER: {Player.Name}`)
	
	Manager:_InitiateControllers()
	
	Manager:_UpdateTime()
	
	local CameraShake = CameraShaker.new(RenderPriority, CamShake)
	CameraShake:Start()
	
	if not RunService:IsStudio() then
		print(`Running @ccommu on discord and @dev_Commu on roblox's client and server framework, made entirely for Satch 🌿`)
		print(`Running Bitwise (@BitwiseAndrea)'s proximity prompt customizer!`)
		print(`Running Sleitnick's camera shake script, thank you!`)
		print(`Running @WinnersTakesAll's custom backpack system (Satchel)\nThe version of Satchel in use has slightly modified source code.`)
	end
	
	MainGui:WaitForChild("Shops"):WaitForChild("Background").Visible = true
	
	Icon.new()
		:setName("Version")
		:setLabel("Build Version: "..ReplicatedStorage:WaitForChild("ServerInfo"):WaitForChild("BuildVersion").Value)
		:align("Right")
		:oneClick(true)
	
	GameLoaded = true
	--// Old initiation time print, updated to be included in the main initiation data print.
	--print(`GameController -- Client framework finished initiating for player: {Player.Name} in {tick() - StartTime} seconds`)
	print(`\n===============================\n\n--CLIENT--\n\nInitiated All Controllers for player : {Player.Name} in {tick() - StartTime} seconds\nTotal Inititated Controllers: {InitiatedControllers}\n\nUnsuccessful Controller Initiations: {InitiatedControllers - SuccessfulControllerInitations}\n\n===============================`)
	
	RunService.RenderStepped:Connect(function(dt)
		if HumanoidRootPart and Character then
			local speed = HumanoidRootPart.Velocity.Magnitude

			if speed <= SpeedThreshold then
				StillTime += dt
				if StillTime >= RequiredTime then
					CameraShake:ShakeSustain(CameraShaker.Presets.HandheldCamera)
					StillTime = 0
				end
			else
				CameraShake:StopSustained()
				StillTime = 0
			end
		else
			CameraShake:StopSustained()
			StillTime = 0

			Character = Player.Character
			if not Character then
				return
			else
				HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			end
		end

		if StarterGui:GetCore("ChatActive") then
			Player.PlayerGui:WaitForChild("MainGui"):WaitForChild("Quests").Position = QuestsChatOpenPosition
		else
			Player.PlayerGui:WaitForChild("MainGui"):WaitForChild("Quests").Position = QuestsChatClosedPosition
		end
	end)
end

--------------------------------
--\\ Main //--
--------------------------------

return Manager