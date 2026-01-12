if not game:GetService("RunService"):IsStudio() then script.Parent:Destroy() script:Destroy() end

local DB = false
local IsOpen = false

script.Parent.Activated:Connect(function()
	IsOpen = game.Players.LocalPlayer.PlayerGui.MainGui.Shops.StarterShop.Visible
	
	if DB == false then
		DB = true
		
		if IsOpen == true then
			print("`Closing` Shop - VIA: TEST SCRIPT")
			local shop = require(game.ReplicatedStorage.Framework.Controllers.ShopController)
			shop:CloseShop(game.Players.LocalPlayer.PlayerGui.MainGui.Shops.StarterShop)
		else
			print("`Opening` Shop - VIA: TEST SCRIPT")
			local shop = require(game.ReplicatedStorage.Framework.Controllers.ShopController)
			shop:OpenShop(game.Players.LocalPlayer.PlayerGui.MainGui.Shops.StarterShop)
		end
		
		task.wait(1)
		DB = false
	end
end)

local TextEffects = require(game.ReplicatedStorage.Packages.EasyVisuals)
--local Effect = TextEffects.new(script.Parent, "PurchaseStroke", 0.3, 2)
local Effect = TextEffects.new(script.Parent, "GoldStroke", 1, 2)