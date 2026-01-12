if not game:GetService("RunService"):IsStudio() then
	script.Parent:Destroy()
	script:Destroy()
end

local DB = false
local IsOpen = false

script.Parent.Activated:Connect(function()
	IsOpen = game.Players.LocalPlayer.PlayerGui.MainGui.Inventory.Visible

	if DB == false then
		DB = true

		task.spawn(function()
			if IsOpen == true then
				print("`Closing` Inventory - VIA: TEST SCRIPT")
				local Inventory = require(game.ReplicatedStorage.Framework.Controllers.InventoryController)
				Inventory:CloseInventory()
			else
				print("`Opening` Inventory - VIA: TEST SCRIPT")
				local Inventory = require(game.ReplicatedStorage.Framework.Controllers.InventoryController)
				Inventory:OpenInventory()
			end
		end)

		task.wait(0.5)
		DB = false
	end
end)

local TextEffects = require(game.ReplicatedStorage.Packages.EasyVisuals)
--local Effect = TextEffects.new(script.Parent, "PurchaseStroke", 0.3, 2)
local Effect = TextEffects.new(script.Parent, "SilverStroke", 1, 2)
