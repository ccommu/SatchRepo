return function()
    local Gradient = Instance.new("UIGradient");
    Gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.93, 0.93, 0.93)),
		ColorSequenceKeypoint.new(0.220486119389534, Color3.new(0.93, 0.93, 0.93)),
		ColorSequenceKeypoint.new(0.3680555522441864, Color3.new(0.88, 0.88, 0.88)),
		ColorSequenceKeypoint.new(0.4982638955116272, Color3.new(0.95, 0.95, 0.95)),
		ColorSequenceKeypoint.new(0.5034722089767456, Color3.new(0.99, 0.99, 0.99)),
		ColorSequenceKeypoint.new(0.6927083134651184, Color3.new(0.93, 0.93, 0.93)),
		ColorSequenceKeypoint.new(0.7916666865348816, Color3.new(0.93, 0.93, 0.93)),
		ColorSequenceKeypoint.new(1, Color3.new(0.93, 0.93, 0.93)),
    })
    return Gradient;
end