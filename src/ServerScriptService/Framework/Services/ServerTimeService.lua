--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

--------------------------------
--\\ Constants //--
--------------------------------

local ServerInfo = ReplicatedStorage:FindFirstChild("ServerInfo")
local ServerTime = ServerInfo:WaitForChild("InGameTime")

local MIN_LIGHT_MINUTES = 5 * 60
local MAX_LIGHT_MINUTES = (19 * 60) + 30
local BASE_LIGHT_MINUTES = (14 * 60) + 30

local MIN_CONTRAST = -0.15
local BASE_CONTRAST = 0.1

local DayCloudColor = Color3.fromRGB(255, 255, 255)
local NightCloudColor = Color3.fromRGB(100, 100, 100)

local DAY_WAIT = 10
local NIGHT_MULTIPLIER = 10

--------------------------------
--\\ Variables //--
--------------------------------

local Service = {}

local CurrentTimeSTR = "14:30"
local CurrentTimeNMB = 870

local ColorCorrection = Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect")
local Clouds = Terrain:FindFirstChildOfClass("Clouds")

--------------------------------
--\\ Private Functions //--
--------------------------------

local function UpdateTime()
	local totalMinutes = CurrentTimeNMB % 1440
	local hours = totalMinutes // 60
	local minutes = totalMinutes % 60

	CurrentTimeSTR = string.format("%02d:%02d", hours, minutes)
	ServerTime.Value = CurrentTimeSTR
end

local function UpdateLighting()
	local totalMinutes = CurrentTimeNMB % 1440

	local clamped = math.clamp(totalMinutes, MIN_LIGHT_MINUTES, MAX_LIGHT_MINUTES)

	local distance = math.abs(clamped - BASE_LIGHT_MINUTES)
	local maxDistance = math.max(BASE_LIGHT_MINUTES - MIN_LIGHT_MINUTES, MAX_LIGHT_MINUTES - BASE_LIGHT_MINUTES)
	local alpha = distance / maxDistance

	if ColorCorrection then
		ColorCorrection.Contrast = BASE_CONTRAST + (MIN_CONTRAST - BASE_CONTRAST) * alpha
	end

	if Clouds then
		Clouds.Color = DayCloudColor:Lerp(NightCloudColor, alpha)
	end

	Lighting.ClockTime = (totalMinutes / 60) % 24
end

function Service:_BeginCount()
	task.spawn(function()
		while true do
			local totalMinutes = CurrentTimeNMB % 1440

			local isNight = totalMinutes < MIN_LIGHT_MINUTES or totalMinutes > MAX_LIGHT_MINUTES

			local waitTime = isNight and (DAY_WAIT / NIGHT_MULTIPLIER) or DAY_WAIT

			CurrentTimeNMB = (CurrentTimeNMB + 1) % 1440
			UpdateTime()
			UpdateLighting()

			task.wait(waitTime)
		end
	end)
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Service:AddTime(amount)
	if typeof(amount) ~= "number" or amount == 0 then return end

	task.spawn(function()
		local duration = 1
		local steps = 60
		local stepTime = duration / steps
		local stepAmount = amount / steps

		for _ = 1, steps do
			CurrentTimeNMB = (CurrentTimeNMB + stepAmount) % 1440
			UpdateTime()
			UpdateLighting()
			task.wait(stepTime)
		end
	end)
end

function Service:RemoveTime(amount)
	if typeof(amount) ~= "number" or amount == 0 then return end

	task.spawn(function()
		local duration = 1
		local steps = 60
		local stepTime = duration / steps
		local stepAmount = amount / steps

		for _ = 1, steps do
			CurrentTimeNMB = (CurrentTimeNMB - stepAmount) % 1440
			UpdateTime()
			UpdateLighting()
			task.wait(stepTime)
		end
	end)
end

function Service:OnStart()
	Service:_BeginCount()
	print("ServerTime Service Initiated.")
end

--------------------------------
--\\ Main //--
--------------------------------

return Service
