--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Animations = ReplicatedStorage:FindFirstChild("Animations")
local DiggingAnimation = Animations:FindFirstChild("DiggingAnimation")
local DiggingAnimationInstance = DiggingAnimation:FindFirstChild("Animation") :: Animation

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local DataFolder = Shared:FindFirstChild("Data")
local SatchelData = require(DataFolder:FindFirstChild("SatchelData"))

--------------------------------
--\\ Variables //--
--------------------------------

local Service = {}
local ActiveSatchels = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

function Service.FindSatchelByName(SatchelName)
    for _, Satchel in pairs(ServerStorage:FindFirstChild("Satchels"):GetDescendants()) do
        if Satchel:IsA("Tool") and string.lower(Satchel.Name) == string.lower(SatchelName) then
            return Satchel
        end
    end
    return nil
end

function Service.FindSatchelInBackpack(player : Player) : Tool?
    local Backpack = player:FindFirstChildWhichIsA("Backpack")
    if not Backpack then return nil end

    for _, Tool in pairs(Backpack:GetChildren()) do
        if Tool:IsA("Tool") and Tool:HasTag("satchel") then
            return Tool
        end
    end

    return nil
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Service.ActivateSatchel(player : Player, SatchelName : string)
    ActiveSatchels[player.UserId] = SatchelName
    print(`SatchelService -- Activated satchel: {SatchelName} for player: {player.Name}`)
end

function Service.ControlSatchel(player : Player, SatchelItem : Tool, GivenSatchelData : {Price : number, Rarity : string, Luck : number, Resilience : number, Speed : number, IconId : number, RarityColor : ColorSequence})
    local SatchelName = SatchelItem.Name
    if not SatchelName then return end

    if not GivenSatchelData then GivenSatchelData = SatchelData["Starter Satchel"] warn(`SatchelService -- Satchel data not found for: {SatchelName}`) end

    print(`SatchelService -- Controlling satchel: {SatchelItem.Name} with data: {GivenSatchelData} for player: {player.Name}`)

	SatchelItem.Activated:Connect(function()
        if ActiveSatchels[player.UserId] ~= SatchelName then
            print(`SatchelService -- Satchel: {SatchelName} is not currently equipped for player: {player.Name}`)
            return
        end

		local Character = player.Character
		if not Character then
			return
		end

		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		if not Humanoid then
			return
		end

		local Animator = Humanoid:FindFirstChildOfClass("Animator")
		if not Animator then
			return
		end

        for _, AnimationTrack in pairs(Animator:GetPlayingAnimationTracks()) do
            AnimationTrack:Stop(0.5)
        end

        for _, Part in pairs(SatchelItem:GetDescendants()) do
            if Part:IsA("BasePart") then
                Part.CanCollide = false
            end
        end

		local DiggingAnimTrack = Animator:LoadAnimation(DiggingAnimationInstance) :: AnimationTrack
        DiggingAnimTrack.Looped = false
        Humanoid.WalkSpeed = 0
        SatchelItem.AncestryChanged:Connect(function()
            DiggingAnimTrack:Stop(0.5)
        end)
		DiggingAnimTrack:Play()
        DiggingAnimTrack:GetMarkerReachedSignal("Hold"):Connect(function()
            print("Reached")
            DiggingAnimTrack:AdjustSpeed(0)
        end)
        DiggingAnimTrack.Ended:Connect(function()
            Humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
        end)
	end)
end

function Service.EquipSatchel(player : Player, SatchelName : string) : boolean
    print(`SatchelService -- Equipping satchel: {SatchelName} for player: {player.Name}`)

    local Backpack = player:FindFirstChildWhichIsA("Backpack")
    if not Backpack then return false end

    if Backpack:FindFirstChild(SatchelName) then
        print(`SatchelService -- Player: {player.Name} already has satchel: {SatchelName} equipped.`)
        ActiveSatchels[player.UserId] = SatchelName
        return true
    end
    
    local SatchelTool = Service.FindSatchelByName(SatchelName)
    if not SatchelTool then return false end

    for _, Tool in pairs(Backpack:GetChildren()) do
        if Tool:IsA("Tool") and Tool:HasTag("satchel") then
            Tool:Destroy()
            print(`SatchelService -- Removed existing satchel: {SatchelName} from player: {player.Name}'s backpack.`)
            ActiveSatchels[player.UserId] = ""
        end
    end

    local ClonedTool = SatchelTool:Clone()
    ClonedTool.Parent = Backpack

    if ClonedTool.Parent == Backpack then
        print(`SatchelService -- Successfully equipped satchel: {SatchelName} for player: {player.Name}`)
        ActiveSatchels[player.UserId] = SatchelName

        local FoundSatchelData = SatchelData[SatchelName]
        if not FoundSatchelData then
            FoundSatchelData = SatchelData["Starter Satchel"]
        end

        Service.ControlSatchel(player, ClonedTool, FoundSatchelData)

        return true
    end

    return false 
end

function Service:OnStart()
	print(`SatchelService started.`)
end

--------------------------------
--\\ Main //--
--------------------------------

return Service