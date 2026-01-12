local DistanceFade = require(script.DistanceFade)

-- initiate a new distancefade using .new() constructor
local distanceFade = DistanceFade.new()
local distanceFadeSettings = {
	["EdgeDistanceCalculations"] = true,
	["Texture"] = "rbxassetid://18852900044",
	["TextureTransparency"] = .25,
	["BackgroundTransparency"] = 0.95,
	["TextureColor"] = Color3.fromRGB(255, 211, 135),
	["BackgroundColor"] = Color3.fromRGB(255, 173, 58),
	["TextureSize"] = Vector2.new(6, 5.5),
	["TextureOffset"] = Vector2.new(0, .5),
	["Brightness"] = 3,
}
-- update distancefade with initial customization settings
distanceFade:UpdateSettings(distanceFadeSettings)

-- base x axis texture offsets for each face (to make the effect seamless)
local baseOffsetsX = {
	["1"] = -3,
	["2"] = -2,
	["3"] = -1,
	["4"] = 0,
	["5"] = 1,
	["6"] = 2,
	["7"] = 3
}

-- add faces to apply the effect to
local folder = script.Parent
local partsToAdd = {
	folder:WaitForChild("1"),
	folder:WaitForChild("2"),
	folder:WaitForChild("3"),
	folder:WaitForChild("4"),
}
for _,basePart in partsToAdd do
	distanceFade:AddFace(basePart, Enum.NormalId.Front)
	distanceFade:AddFace(basePart, Enum.NormalId.Back)
end

-- tweens vector3 value to animate offset
local tweenValue = Instance.new("Vector3Value")
tweenValue.Parent = script
game:GetService("TweenService"):Create(tweenValue, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), { Value = Vector3.new(-6, 5.5) }):Play() -- offset is same as texture size for perfect loop
game:GetService("RunService").Heartbeat:Connect(function() -- using Heartbeat for Step() is visually smoother than RenderStepped
	-- update settings with texture offset value to apply animation
	for _,v in partsToAdd do
		local offsetX = baseOffsetsX[v.Name]-- + tweenValue.Value.X
		local offsetY = tweenValue.Value.Y
		distanceFade:UpdateFaceSettings(v, Enum.NormalId.Front, {["TextureOffset"] = Vector2.new(offsetX, offsetY)})
		distanceFade:UpdateFaceSettings(v, Enum.NormalId.Back, {["TextureOffset"] = Vector2.new(-offsetX, offsetY)})
	end
	local newSettings = {}
	-- call Step() for each distancefade. If arguments are left empty, it automatically targets local character's root part
	distanceFade:Step()
end)
