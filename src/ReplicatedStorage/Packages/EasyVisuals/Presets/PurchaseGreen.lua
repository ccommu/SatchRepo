local TextEffects = require(script.Parent.Parent);

return function(uiInstance: GuiObject, speed: number, size: number)
	local mainGradient = TextEffects.Gradient.new(uiInstance, TextEffects.Templates.GreenCustom.Color, 0);
	mainGradient:SetRotation(-75, 1);
	mainGradient:SetOffsetSpeed(speed, 1);
	return {
		Effects = { mainGradient }
	};
end