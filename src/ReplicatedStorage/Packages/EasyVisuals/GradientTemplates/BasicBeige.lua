return function()
	local Gradient = Instance.new("UIGradient");
	Gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 200)),
		ColorSequenceKeypoint.new(0.220486119389534, Color3.fromRGB(255, 230, 200)),
		ColorSequenceKeypoint.new(0.3680555522441864, Color3.fromRGB(245, 220, 190)),
		ColorSequenceKeypoint.new(0.4982638955116272, Color3.fromRGB(235, 215, 185)),
		ColorSequenceKeypoint.new(0.5034722089767456, Color3.fromRGB(250, 240, 210)),
		ColorSequenceKeypoint.new(0.6927083134651184, Color3.fromRGB(255, 230, 200)),
		ColorSequenceKeypoint.new(0.7916666865348816, Color3.fromRGB(255, 230, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 200))

	})
	return Gradient;
end