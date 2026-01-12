--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Networking = Shared:FindFirstChild("Networking")
local MiscEvents = Networking:FindFirstChild("Misc")

local WarningEvent = MiscEvents:FindFirstChild("Warning")

local DetectorPartOriginal = ReplicatedStorage:FindFirstChild("Detector")

local ShowDetectorHitbox = false

local CheckDelay = 1.5

--------------------------------
--\\ Variables //--
--------------------------------

local Module = {}
local HandlingPlayers = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function HandlePlayer(Player : Player)
	local DetectorPart = DetectorPartOriginal:Clone()
	local Character = Player.Character or Player.CharacterAdded:Wait()
	Character = Player.Character

	local Counts = {}
	local LastPositions = {}
	local LastTouchTime = {}

	DetectorPart.Parent = workspace

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local BackOffset = 1.5
	local DetectorCFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, BackOffset)

	DetectorPart:PivotTo(DetectorCFrame)
	DetectorPart.Parent = HumanoidRootPart
	DetectorPart:FindFirstChild("WeldConstraint").Part0 = DetectorPart
	DetectorPart:FindFirstChild("WeldConstraint").Part1 = HumanoidRootPart

	if RunService:IsStudio() and ShowDetectorHitbox then
		DetectorPart.Transparency = 0.5
		DetectorPart.Color = Color3.new(1, 0, 0.0156863)
	else
		DetectorPart.Transparency = 1
	end

	DetectorPart.Touched:Connect(function(OtherPart)
		if not HandlingPlayers[Player] then
			return print("PLAYER ISN'T BEING HANDLED BY ANTIPLAYERABUSE, CANNOT DO ANYTHING!")
		end

		local OtherCharacter = OtherPart.Parent
		if not OtherCharacter then return end

		local OtherPlayer = Players:GetPlayerFromCharacter(OtherCharacter)
		if not OtherPlayer then return end

		local OtherHumanoid = OtherCharacter:FindFirstChild("Humanoid")
		local OtherHRP = OtherCharacter:FindFirstChild("HumanoidRootPart")
		if not OtherHumanoid or not OtherHRP then return end

		local MIN_SPEED = 0.1
		if OtherHumanoid.MoveDirection.Magnitude < MIN_SPEED and OtherHRP.Velocity.Magnitude < MIN_SPEED then
			return
		end

		local lastPos = LastPositions[OtherPlayer]
		local distanceMoved = lastPos and (OtherHRP.Position - lastPos).Magnitude or 0
		local MOVE_THRESHOLD = 4
		if distanceMoved > MOVE_THRESHOLD then
			Counts[OtherPlayer] = 0
		end
		LastPositions[OtherPlayer] = OtherHRP.Position

		local currentTime = tick()
		if LastTouchTime[OtherPlayer] and currentTime - LastTouchTime[OtherPlayer] < CheckDelay then
			return
		end
		LastTouchTime[OtherPlayer] = currentTime

		if not Counts[OtherPlayer] then
			Counts[OtherPlayer] = 1
		else
			Counts[OtherPlayer] += 1
		end

		if Counts[OtherPlayer] >= 6 then
			WarningEvent:FireClient(OtherPlayer, "WARNING! An alert has been sent to game moderators about your actions.")
		elseif Counts[OtherPlayer] >= 3 then
			WarningEvent:FireClient(OtherPlayer, "WARNING! Do not repeat the motions that you have just done, as they are innapropriate. Continuing will result in moderation.")
		end
	end)
end


--------------------------------
--\\ Public Functions //--
--------------------------------

function Module:OnStart()
	print(`AntiPlayerAbuse / Anti "Backshot" System initiating.`)
	
	for _, Player in Players:GetPlayers() do
		HandlePlayer(Player)
		HandlingPlayers[Player] = true
	end
	
	Players.PlayerAdded:Connect(function(NewPlayer)
		if not HandlingPlayers[NewPlayer] then
			HandlePlayer(NewPlayer)
			HandlingPlayers[NewPlayer] = true
		end
	end)
	
	Players.PlayerRemoving:Connect(function(NewPlayer)
		if HandlingPlayers[NewPlayer] then
			HandlingPlayers[NewPlayer] = nil
		end
	end)
end


--------------------------------
--\\ Main //--
--------------------------------

return Module