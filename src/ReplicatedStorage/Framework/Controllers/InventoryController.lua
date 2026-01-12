--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui")
local InventoryFrame = MainGui:WaitForChild("Inventory")

local Framework = ReplicatedStorage:WaitForChild("Framework")
local GameManager = require(Framework:WaitForChild("GameController"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local SatchelEvents = Networking:WaitForChild("Satchels")

local Data = Shared:WaitForChild("Data")
local SatchelData = require(Data:WaitForChild("SatchelData"))

local OwnedSatchelsRequest = SatchelEvents:WaitForChild("OwnedSatchels")
local EquipSatchelRequest = SatchelEvents:WaitForChild("EquipSatchel")

local LastEquippedSatchelEvent = SatchelEvents:WaitForChild("LastEquippedSatchel")

local TweenInfoParams = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local CloseButton = InventoryFrame:WaitForChild("Exit") :: TextButton

local Backpack = Player:WaitForChild("Backpack")

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}

local IsInventoryOpen = false
local OwnedSatchels = {}
local OriginalProperties = {}

local EquippedSatchel = ""

local ShopController
local NotificationController

--------------------------------
--\\ Private Functions //--
--------------------------------

local function CreateItemTween(Item, Reverse)
	if Item == nil or typeof(Item) ~= "Instance" then
		return
	end

	if OriginalProperties[Item] == nil then
		OriginalProperties[Item] = {}
	end

	local Properties = {}

	if Item:IsA("GuiObject") then
		if Item.BackgroundTransparency ~= nil then
			if OriginalProperties[Item].BackgroundTransparency == nil then
				OriginalProperties[Item].BackgroundTransparency = Item.BackgroundTransparency
			end
			Properties.BackgroundTransparency = Reverse and 1 or OriginalProperties[Item].BackgroundTransparency
		end

		if Item:IsA("TextLabel") or Item:IsA("TextButton") or Item:IsA("TextBox") then
			if OriginalProperties[Item].TextTransparency == nil then
				OriginalProperties[Item].TextTransparency = Item.TextTransparency
			end
			Properties.TextTransparency = Reverse and 1 or OriginalProperties[Item].TextTransparency
		end

		if Item:IsA("ImageLabel") or Item:IsA("ImageButton") or Item:IsA("ViewportFrame") then
			if OriginalProperties[Item].ImageTransparency == nil then
				OriginalProperties[Item].ImageTransparency = Item.ImageTransparency
			end
			Properties.ImageTransparency = Reverse and 1 or OriginalProperties[Item].ImageTransparency
		end
	end

	if Item:IsA("UIStroke") then
		if OriginalProperties[Item].Transparency == nil then
			OriginalProperties[Item].Transparency = Item.Transparency
		end
		Properties.Transparency = Reverse and 1 or OriginalProperties[Item].Transparency
	end

	if Item:IsA("ScrollingFrame") then
		if OriginalProperties[Item].ScrollBarImageTransparency == nil then
			OriginalProperties[Item].ScrollBarImageTransparency = Item.ScrollBarImageTransparency
		end
		Properties.ScrollBarImageTransparency = Reverse and 1 or OriginalProperties[Item].ScrollBarImageTransparency

		for _, Child in ipairs(Item:GetDescendants()) do
			if Child:IsA("GuiObject") then
				CreateItemTween(Child, Reverse)
			elseif Child:IsA("UIStroke") then
				CreateItemTween(Child, Reverse)
			end
		end
	end

	if next(Properties) then
		local Tween = TweenService:Create(Item, TweenInfoParams, Properties)
		Tween:Play()
	end
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:GetDataForOwnedSatchels()
	local SatchelDatasToReturn = {}

	for SatchelName, Owned in OwnedSatchels do
		if Owned then
			print(`InventoryController -- Player owns satchel: {SatchelName}, initiating inventory setup.`)
			if SatchelData[SatchelName] then
				SatchelDatasToReturn[SatchelName] = SatchelData[SatchelName]
			else
				warn(
					`InventoryController -- Satchel data for owned satchel: {SatchelName} not found in SatchelData module.`
				)
			end
		end
	end

	return SatchelDatasToReturn
end

function Controller:IsInventoryOpen()
	return IsInventoryOpen
end

function Controller:_CloseInventoryFrame()
	if not InventoryFrame then
		return
	end

	ShopController:_HideItem(InventoryFrame)
	for _, Item in ipairs(InventoryFrame:GetDescendants()) do
		if Item:IsA("GuiObject") or Item:IsA("UIStroke") then
			ShopController:_HideItem(Item)
		end
	end

	task.wait(TweenInfoParams.Time)
	InventoryFrame.Visible = false
	IsInventoryOpen = false
end

function Controller:_OpenInventoryFrame()
	if not InventoryFrame then
		return
	end

	InventoryFrame.Visible = true
	IsInventoryOpen = true

	ShopController:_ShowItem(InventoryFrame)
	for _, Item in ipairs(InventoryFrame:GetDescendants()) do
		if Item:IsA("GuiObject") or Item:IsA("UIStroke") then
			ShopController:_ShowItem(Item)
		end
	end
end

function Controller:CloseInventory()
	ShopController:_HideAllCloseItems()
	ShopController:_HideBackground()
	Controller:_CloseInventoryFrame()
end

function Controller:OpenInventory()
	if ShopController:CanIInteract() == false then
		ShopController:CloseCurrentShop()
	end

	-- Checks every time in case you bought new satchels n stuff
	local PossibleOwnedSatchels = OwnedSatchelsRequest:InvokeServer()
	if not PossibleOwnedSatchels then
		warn(`InventoryController -- Failed to retrieve owned satchels from the server for player: {Player.Name}`)
		return Player:Kick(
			"An error occurred while loading your inventory. Please rejoin the game and contact support."
		)
	end
	OwnedSatchels = PossibleOwnedSatchels

	ShopController:_ShowAllCloseItems()
	ShopController:_ShowBackground()

	local SatchelsScrollingFrame = InventoryFrame:WaitForChild("Satchels")
	local ExampleSatchelItem = SatchelsScrollingFrame:WaitForChild("ExampleSatchel") :: Frame

	local EquipDB = false

	CloseButton.MouseButton1Click:Connect(function()
		Controller:CloseInventory()
	end)

	local OwnedSatchelData = Controller:GetDataForOwnedSatchels()
	for SatchelName, Data in pairs(OwnedSatchelData) do
		if SatchelsScrollingFrame:FindFirstChild(SatchelName) then
			continue
		end

		local NewSatchelItem = ExampleSatchelItem:Clone()
		NewSatchelItem.Name = SatchelName
		NewSatchelItem.SatchelName.Text = SatchelName
		NewSatchelItem.SatchelName.TextTransparency = 0
		NewSatchelItem.SatchelIcon.Image = "rbxassetid://" .. tostring(Data.IconId)
		NewSatchelItem.SatchelIcon.ImageTransparency = 0
		NewSatchelItem.SatchelRarity.Text = Data.Rarity
		NewSatchelItem.SatchelRarity.TextTransparency = 0
		NewSatchelItem.RarityGradient.Gradient.Color = Data.RarityColor
		NewSatchelItem.RarityGradient.BackgroundTransparency = 0.4
		NewSatchelItem.SatchelResilience.Text = `+{Data.Resilience} Resilience`
		NewSatchelItem.SatchelResilience.TextTransparency = 0
		NewSatchelItem.SatchelSpeed.Text = `+{Data.Speed} Speed`
		NewSatchelItem.SatchelSpeed.TextTransparency = 0
		NewSatchelItem.SatchelLuck.Text = `+{Data.Luck} Luck`
		NewSatchelItem.SatchelLuck.TextTransparency = 0

		NewSatchelItem.Background.ImageTransparency = 0

		NewSatchelItem.Parent = SatchelsScrollingFrame
		NewSatchelItem.Visible = true

		NewSatchelItem.Equip.BackgroundTransparency = 0.5
		NewSatchelItem.Equip.TextTransparency = 0
		NewSatchelItem.Equip.UIStroke.Transparency = 0.5

		if EquippedSatchel == SatchelName then
			NewSatchelItem.Equip.Text = "Equipped"
			NewSatchelItem.Equip.UIStroke.Color = Color3.fromRGB(57, 48, 32)

			task.spawn(function()
				while EquippedSatchel == SatchelName do
					task.wait()
				end
				NewSatchelItem.Equip.Text = "Equip"
				NewSatchelItem.Equip.UIStroke.Color = Color3.fromRGB(117, 207, 101)
			end)
		else
			NewSatchelItem.Equip.Text = "Equip"
			NewSatchelItem.Equip.UIStroke.Color = Color3.fromRGB(117, 207, 101)
		end

		NewSatchelItem.Equip.MouseButton1Click:Connect(function()
			if EquipDB == false and EquippedSatchel ~= SatchelName then
				EquipDB = true
				print(`Equipping satchel: {SatchelName}`)
				EquippedSatchel = SatchelName
				local equipped = EquipSatchelRequest:InvokeServer(SatchelName)
				if not equipped then
					warn(`InventoryController -- Failed to equip satchel: {SatchelName} for player: {Player.Name}`)
					NotificationController:DisplayNotificationLower("Failed to equip satchel. Please try again.")
					EquipDB = false
					EquippedSatchel = nil
				else
					print(`Successfully equipped satchel: {SatchelName} for player: {Player.Name}`)
					NewSatchelItem.Equip.Text = "Equipped"
					NewSatchelItem.Equip.UIStroke.Color = Color3.new(57, 48, 32)
					EquipDB = false

					NotificationController:DisplayNotificationLower(`Equipped satchel: {SatchelName}`)

					task.spawn(function()
						while EquippedSatchel == SatchelName do
							task.wait()
						end
						NewSatchelItem.Equip.Text = "Equip"
						NewSatchelItem.Equip.UIStroke.Color = Color3.fromRGB(117, 207, 101)
					end)
				end
			end
		end)
	end
	--TODO: Add remainder of inventory logic here

	Controller:_OpenInventoryFrame()
end

function Controller:OnStart()
	print(`InventoryController Started.`)

	repeat
		task.wait()
	until GameManager:IsGameLoaded() == true
	ShopController = GameManager:GetController("ShopController")
	NotificationController = GameManager:GetController("NotificationController")

	Controller:_CloseInventoryFrame()

	LastEquippedSatchelEvent.OnClientEvent:Connect(function(SatchelName)
		EquippedSatchel = SatchelName
	end)

	local EquipmentTool = Backpack:WaitForChild("Equipment", 5) :: Tool
	EquipmentTool.Enabled = true

	EquipmentTool.Equipped:Connect(function()
		Controller:OpenInventory()
	end)
	EquipmentTool.Unequipped:Connect(function()
		Controller:CloseInventory()
	end)
end

--------------------------------
--\\ Main //--
--------------------------------

return Controller
