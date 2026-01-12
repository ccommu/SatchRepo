--------------------------------
--\\ Services //--
--------------------------------

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Packages = ServerScriptService:FindFirstChild("Packages")
local ProfileStorePackages = Packages:FindFirstChild("ProfileStore")

local DataManager = require(ProfileStorePackages:FindFirstChild("DataManager"))

local SatchelTools = ServerStorage:FindFirstChild("Satchels")

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Networking = Shared:FindFirstChild("Networking")
local SatchelEvents = Networking:FindFirstChild("Satchels")

local LastEquippedSatchelEvent = SatchelEvents:FindFirstChild("LastEquippedSatchel")

local Framework = ServerScriptService:FindFirstChild("Framework")
local Services = Framework:FindFirstChild("Services")
local SatchelService = require(Services:FindFirstChild("SatchelService"))

local DataFolder = Shared:FindFirstChild("Data")
local SatchelData = require(DataFolder:FindFirstChild("SatchelData"))

--------------------------------
--\\ Variables //--
--------------------------------

local Service = {}
local CharacterSavedInventories = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function IsSatchelStillOwned(targetPlayer : Player, SatchelName : string) : boolean
    local PlayerData = DataManager.GetData(targetPlayer)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(targetPlayer)
	end
	PlayerData = DataManager.GetData(targetPlayer)

    local ownedSatchels = PlayerData.OwnedSatchels
    if ownedSatchels and ownedSatchels[SatchelName] then
        return true
    end

    return false
end

local function FindSatchel(satchelName : string)
    for _, satchel in pairs(SatchelTools:GetDescendants()) do
        if string.lower(satchel.Name) == string.lower(satchelName) then
            return satchel
        end
    end
    return nil
end

local function LoadPlayer(Player : Player)
    local PlayerData = DataManager.GetData(Player)
	if not PlayerData then
		repeat
			task.wait()
		until DataManager.GetData(Player)
	end
	PlayerData = DataManager.GetData(Player)
    
    local LastSavedInventory = PlayerData.SavedInventory
    if not LastSavedInventory then LastSavedInventory = {} end

    --[[
    NOTE:
    The formatting of the LastSavedInventory table is as follows:
    LastSavedInventory = {
        [1] = {
            ItemName = "Satchel_A",
            ItemType = "satchel", --// Tag from the item
        },
        [2] = {
            ItemName = "Equipment",
            ItemType = "inventoryTool",
        },
        ...
    }
    ]]

    task.spawn(function() -- Returns all the itmes
        for _, Item in LastSavedInventory do
            local ItemName = Item.ItemName
            local ItemType = Item.ItemType

            if ItemType == "inventoryTool" then continue end
            if ItemType == "satchel" then
               local stillOwned = IsSatchelStillOwned(Player, ItemName)
               if not stillOwned then
                    continue
                else
                    local SatchelTool = FindSatchel(ItemName):Clone()
                    if SatchelTool then
                        local ClonedSatchel = SatchelTool:Clone()
                        ClonedSatchel.Parent = Player.Backpack
                        
                        SatchelService.ActivateSatchel(Player, ItemName)
                        SatchelService.ControlSatchel(Player, ClonedSatchel, SatchelData[ItemName])

                        LastEquippedSatchelEvent:FireClient(Player, ItemName)
                    else
                        warn(`InventorySaveService - Satchel tool: {ItemName} not found in ServerStorage.Satchels for player: {Player.Name}`)
                    end
                end
            end
        end
    end)
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Service:OnStart()
    for _, player in Players:GetPlayers() do
        LoadPlayer(player)
    end
    Players.PlayerAdded:Connect(function(player)
        LoadPlayer(player)

        local Character = player.Character or player.CharacterAdded:Wait()
        Character = player.Character

        CharacterSavedInventories[player.UserId] = {}

        Character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                local itemType = nil
                if child:HasTag("satchel") then
                    itemType = "satchel"
                elseif child:HasTag("inventoryTool") then
                    itemType = "inventoryTool"
                else
                    itemType = "other"
                    print(`InventorySaveService - Item: {child.Name} in player: {player.Name}'s backpack does not have a valid tag, skipping ItemType for this item. Item tags follow:`)
                    print(child:GetTags())
                end

                table.insert(CharacterSavedInventories[player.UserId], {
                    ItemName = child.Name,
                    ItemType = itemType,
                })
            end
        end)
        Character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                for index, savedItem in pairs(CharacterSavedInventories[player.UserId]) do
                    if savedItem["ItemName"] == child.Name then
                        table.remove(CharacterSavedInventories[player.UserId], index)
                        break
                    end
                end
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(Player)
        print(`InventorySaveService - Saving inventory for player: {Player.Name}`)
        local CurrentInventory = CharacterSavedInventories[Player.UserId] or {}
        CharacterSavedInventories[Player.UserId] = nil

        for _, item in pairs(Player.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                local itemType = nil
                if item:HasTag("satchel") then
                    itemType = "satchel"
                elseif item:HasTag("inventoryTool") then
                    itemType = "inventoryTool"
                else
                    itemType = "other"
                    print(`InventorySaveService - Item: {item.Name} in player: {Player.Name}'s backpack does not have a valid tag, skipping ItemType for this item. Item tags follow:`)
                    print(item:GetTags())
                end

                table.insert(CurrentInventory, {
                    ItemName = item.Name,
                    ItemType = itemType,
                })
            end
        end

        DataManager.UpdateSavedInventory(Player, CurrentInventory)
        print(`InventorySaveService - Inventory saved for player: {Player.Name}`, CurrentInventory)
    end)

	print(`InventorySaveService Started`)
end

--------------------------------
--\\ Main //--
--------------------------------

return Service