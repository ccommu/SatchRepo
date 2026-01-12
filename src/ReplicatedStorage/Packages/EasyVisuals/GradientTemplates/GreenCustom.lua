return function()
	local Gradient = Instance.new("UIGradient");
	Gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.4, 0.7, 0.4)),  
		ColorSequenceKeypoint.new(0.220486119389534, Color3.new(0.4, 0.7, 0.4)),  
		ColorSequenceKeypoint.new(0.3680555522441864, Color3.new(0.35, 0.6, 0.35)),  
		ColorSequenceKeypoint.new(0.4982638955116272, Color3.new(0.3, 0.65, 0.3)),  
		ColorSequenceKeypoint.new(0.5034722089767456, Color3.new(0.6, 0.85, 0.6)),  
		ColorSequenceKeypoint.new(0.6927083134651184, Color3.new(0.4, 0.7, 0.4)),  
		ColorSequenceKeypoint.new(0.7916666865348816, Color3.new(0.4, 0.7, 0.4)),  
		ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.7, 0.4))
	})
	return Gradient;
end