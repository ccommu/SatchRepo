--------------------------------
--\\ Services //--
--------------------------------

local CollectionsService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local MainGui = PlayerGui:WaitForChild("MainGui")
local ShopsFolder = MainGui:WaitForChild("Shops")

local ShopBackground = ShopsFolder:WaitForChild("Background")

local CloseWhenShopOpen = {
	MainGui:WaitForChild("Time"):GetDescendants(),
	MainGui:WaitForChild("Quests"):GetDescendants(),
	MainGui:WaitForChild("Info"):GetDescendants(),
	MainGui:WaitForChild("CompassFrame"),
	MainGui:FindFirstChild("CompassFrame"):GetDescendants()
}

local TweenInfoParams = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Framework = ReplicatedStorage:WaitForChild("Framework")

local GameManager = require(Framework:WaitForChild("GameController"))

local CompassController
local ConfettiController
local InventoryController

local Packages = ReplicatedStorage:WaitForChild("Packages")
local TextEffects = require(Packages:WaitForChild("EasyVisuals"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local ShopEvents = Networking:WaitForChild("Shop")

local IsSatchelOwnedRequest = ShopEvents:WaitForChild("IsSatchelOwned")
local CanAffordRequest = ShopEvents:WaitForChild("CanAfford")
local PurchaseRequest = ShopEvents:WaitForChild("Purchase")

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}
local OriginalProperties = {}

local CurrentShop = nil
local ViewingShop = false

local OwnedSatchels = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function CameraAndBlur(Open)
	local TI = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	
	if Open then
		local Blur = Lighting:FindFirstChild("UIBlur")
		if not Blur then
			Blur = Instance.new("BlurEffect")
			Blur.Size = 0
			Blur.Name = "UIBlur"
			Blur.Parent = Lighting
		end
		
		local Camera = workspace.CurrentCamera
		
		local BlurTween = TweenService:Create(Blur, TI, {Size = 12})
		local CameraTween = TweenService:Create(Camera, TI, {FieldOfView = 80})
		
		BlurTween:Play()
		CameraTween:Play()
	else
		local Blur = Lighting:FindFirstChild("UIBlur")
		if not Blur then
			return warn(`ShopController -- UIBlur was never created! Meaning the open state was never called, meaning that a close cannot occur. (CameraAndBlur Option 2 result)`)
		end
		local Camera = workspace.CurrentCamera
		
		local BlurTween = TweenService:Create(Blur, TI, {Size = 0})
		local CameraTween = TweenService:Create(Camera, TI, {FieldOfView = 70})

		BlurTween:Play()
		CameraTween:Play()
	end
end

local function CreateItemTween(Item, Reverse)
	if Item == nil or typeof(Item) ~= "Instance" then return end

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

function Controller:_ManageShop(ShopFrame : Frame)
	local SatchelsScrollFrame = ShopFrame:WaitForChild("Satchels")
	if not SatchelsScrollFrame or not SatchelsScrollFrame:IsA("ScrollingFrame") then Controller:CloseShop(ShopFrame) return warn(`ShopController -- Cannot manage a shop that doesn't have a "Satchels" Scrolling Frame.`) end
	
	local ExitButton = ShopFrame:WaitForChild("Exit")
	if not ExitButton or not ExitButton:IsA("TextButton") then Controller:CloseShop(ShopFrame) return warn(`ShopController -- Cannot manage a shop that doesn't have an "Exit" button.`) end
	
	local SearchBox = ShopFrame:WaitForChild("SearchBox")
	if not SearchBox or not SearchBox:IsA("TextBox") then Controller:CloseShop(ShopFrame) return warn(`ShopController -- Cannot manage a shop that doesn't have a "SearchBox" Text Box.`) end
	
	ExitButton.Activated:Connect(function()
		if CurrentShop == ShopFrame then
			Controller:CloseShop(ShopFrame)
		end
	end)
	
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if CurrentShop == ShopFrame then
			local InputText = string.lower(SearchBox.Text)
			print(`Inputed Search Text: {InputText}. Add search function.`)
		end
	end)
	
	local PurchaseButtons = {}
	
	for _, PurchaseButton in CollectionsService:GetTagged("purchaseBtn") do
		if PurchaseButton.Parent.Parent == SatchelsScrollFrame and PurchaseButton:IsA("TextButton") then
			table.insert(PurchaseButtons, PurchaseButton)
		end
	end
	
	for _, Satchel in SatchelsScrollFrame:GetChildren() do
		if Satchel:IsA("Frame") and string.sub(Satchel.Name, 1, 8) ~= "EXAMPLE" then
			print(`ShopController -- Managing Satchel: {Satchel.Name} in Shop: {ShopFrame.Name}`)
			local Cost = Satchel:GetAttribute("cost")
			local SatchelName = Satchel:GetAttribute("satchel")
			
			local PurchaseButton = Satchel:WaitForChild("Buy") :: TextButton
			
			local IsSatchelOwned = IsSatchelOwnedRequest:InvokeServer(SatchelName)
			
			local function OwnedSatchelFunctionality()
				local TextChangeDb = false

				OwnedSatchels[SatchelName] = true
				PurchaseButton.Text = "[ALREADY OWNED]"
				PurchaseButton.Activated:Connect(function()
					if TextChangeDb == false then
						TextChangeDb = true
						PurchaseButton.Text = "[EQUIP IN INVENTORY]"
						task.delay(2, function() PurchaseButton.Text = "[ALREADY OWNED]" TextChangeDb = false end)
					end
				end)
			end
			
			if IsSatchelOwned then
				OwnedSatchelFunctionality()
			else
				PurchaseButton.Activated:Connect(function()
					local CanAfford = CanAffordRequest:InvokeServer(Cost)
					
					if CanAfford and IsSatchelOwned == false then
						local purchased = PurchaseRequest:InvokeServer(SatchelName, Cost)
						if purchased then 
							ConfettiController:MousePosConfetti()
							IsSatchelOwned = true
							OwnedSatchelFunctionality()
						else
							warn(`Player: {Player} failed to purchase satchel: {SatchelName}...`)
							PurchaseButton.Text = "[FAILED TO PURCHASE]"
							task.delay(1, function()
								PurchaseButton.Text = "[PLEASE TRY AGAIN IN A MOMENT]"
							end)
							task.delay(2, function()
								PurchaseButton.Text = "[Purchase]"
							end)
						end
					end
				end)
			end
		end
	end
end

function Controller:_ShowItem(Item)
	CreateItemTween(Item, false)
end

function Controller:_HideItem(Item)
	CreateItemTween(Item, true)
end

function Controller:_HideAllCloseItems()
	CompassController:TemporarilyDisableTransparencyHandling(false)
	
	for _, Group in ipairs(CloseWhenShopOpen) do
		if typeof(Group) == "table" then
			for _, Item in ipairs(Group) do
				if Item:IsA("GuiObject") then
					self:_ShowItem(Item)
				end
			end
		elseif typeof(Group) == "Instance" and Group:IsA("GuiObject") then
			self:_ShowItem(Group)
		end
	end
end

function Controller:_ShowAllCloseItems()
	CompassController:TemporarilyDisableTransparencyHandling(true)
	
	for _, Group in ipairs(CloseWhenShopOpen) do
		if typeof(Group) == "table" then
			for _, Item in ipairs(Group) do
				if Item:IsA("GuiObject") then
					self:_HideItem(Item)
				end
			end
		elseif typeof(Group) == "Instance" and Group:IsA("GuiObject") then
			self:_HideItem(Group)
		end
	end
end

function Controller:_HideShop(ShopFrame)
	if not ShopFrame or not ShopFrame:IsA("Frame") then return end

	for _, Item in ipairs(ShopFrame:GetDescendants()) do
		if Item:IsA("GuiObject") or Item:IsA("UIStroke") then
			self:_HideItem(Item)
		end
	end

	task.wait(TweenInfoParams.Time)
	ShopFrame.Visible = false
	
	CurrentShop = nil
	ViewingShop = false
end

function Controller:_ShowShop(ShopFrame)
	if not ShopFrame or not ShopFrame:IsA("Frame") then return end
	
	ViewingShop = true

	ShopFrame.Visible = true

	for _, Item in ipairs(ShopFrame:GetDescendants()) do
		if Item:IsA("GuiObject") or Item:IsA("UIStroke") then
			self:_ShowItem(Item)
		end
	end
	
	CurrentShop = ShopFrame
	ViewingShop = true
end

function Controller:_ShowBackground()
	CameraAndBlur(true)
	local Tween = TweenService:Create(ShopBackground, TweenInfoParams, {GroupTransparency = 0})
	Tween:Play()
end

function Controller:_HideBackground()
	CameraAndBlur(false)
	local Tween = TweenService:Create(ShopBackground, TweenInfoParams, {GroupTransparency = 1})
	Tween:Play()
end

function Controller:OpenShop(ShopFrame)
	if InventoryController:IsInventoryOpen() == true then
		InventoryController:CloseInventory()
	end
	
	Controller:_ShowBackground()
	Controller:_ShowAllCloseItems()
	Controller:_ShowShop(ShopFrame)
end

function Controller:CloseShop(ShopFrame)
	Controller:_HideBackground()
	Controller:_HideAllCloseItems()
	Controller:_HideShop(ShopFrame)
end

function Controller:CloseCurrentShop()
	if CurrentShop then
		Controller:_HideBackground()
		Controller:_HideAllCloseItems()
		Controller:_HideShop(CurrentShop)
	else
		warn("ShopController -- Cannot hide a shop when no Shop is specified in code, not by calling function. Shop may have already been closed.")
	end
end

function Controller:CanIInteract()
	return not ViewingShop
end

function Controller:OnStart()
	print("Shop Controller Initiating.")
	
	repeat task.wait() until GameManager:IsGameLoaded() == true
	CompassController = GameManager:GetController("CompassController")
	ConfettiController = GameManager:GetController("ConfettiController")
	InventoryController = GameManager:GetController("InventoryController")

	for _, Shop in ipairs(ShopsFolder:GetChildren()) do
		if Shop:IsA("Frame") then
			Controller:_HideShop(Shop)
			Controller:_ManageShop(Shop)
		end
	end
	
	for _, GuiObject in CollectionsService:GetTagged("purchaseBtn") do
		local Effect = TextEffects.new(GuiObject, "PurchaseStroke", 1, 1.5)
	end
	for _, GuiObject in CollectionsService:GetTagged("basicLabel") do
		local Effect = TextEffects.new(GuiObject, "BasicBeige", 1, 1)
	end
	for _, GuiObject in CollectionsService:GetTagged("greenLabel") do
		local Effect = TextEffects.new(GuiObject, "PurchaseGreen", 0.8, 1)
	end
	for _, GuiObject in CollectionsService:GetTagged("commonLabel") do
		local Effect = TextEffects.new(GuiObject, "CommonLabel", 0.75, 1.5)
	end
	for _, GuiObject in CollectionsService:GetTagged("whiteLabel") do
		local Effect = TextEffects.new(GuiObject, "WhiteLabel", 0.75, 1.5)
	end
	
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape and ViewingShop then
			Controller:CloseCurrentShop()
		end
	end)
end

--------------------------------
--\\ Main //--
--------------------------------

return Controller