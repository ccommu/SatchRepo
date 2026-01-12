-- Stroke.luau
-- Updated: use frame-rate independent exponential smoothing to avoid jumps.

local RunService = game:GetService("RunService");

export type Stroke<T...> = {
	UIInstance: GuiObject,
	Instance: UIStroke,
	IsPaused: boolean,
	Color: Color3,
	ColorTarget: Color3,
	ColorAcceleration: number,
	Transparency: number,
	TransparencyTarget: number,
	TransparencyAcceleration: number,
	Size: number,
	SizeTarget: number,
	SizeAcceleration: number,
	Connection: RBXScriptConnection?,
	IsText: boolean,
	Pause: (self: Stroke<T...>) -> nil,
	Resume: (self: Stroke<T...>) -> nil,
	SetSize: (self: Stroke<T...>, size: number, acceleration: number) -> nil,
	SetTransparency: (self: Stroke<T...>, transparency: number, acceleration: number) -> nil,
	SetColor: (self: Stroke<T...>, color: Color3, acceleration: number) -> nil,
	Destroy: (self: Stroke<T...>) -> nil,
};

local Stroke = {};
Stroke.__index = Stroke;

-- Compute a frame-rate independent smoothing alpha from a "rate" parameter.
-- rate is analogous to the previous "Acceleration" field; higher -> faster convergence.
-- dt is the frame delta time.
local function smoothingAlpha(rate: number, dt: number)
	-- clamp rate to non-negative to avoid weird behavior
	if rate <= 0 then
		return 0
	end
	-- exponential smoothing alpha
	local alpha = 1 - math.exp(-rate * dt)
	-- clamp to [0,1] for safety
	if alpha < 0 then alpha = 0 end
	if alpha > 1 then alpha = 1 end
	return alpha
end

function Stroke.new<T...>(uiInstance: GuiObject | UIStroke, size: number, color: Color3?, transparency: number?): Stroke<T...>
	assert(uiInstance, "UIInstance not provided");
	assert(uiInstance:IsA("GuiObject") or uiInstance:IsA("UIStroke"), "UIInstance is not a GuiObject or UIStroke");
	assert(size, "Size not provided");
	assert(typeof(size) == "number", "Size is not a number");
	if (color) then assert(typeof(color) == "Color3", "Color is not a Color3"); end;
	if (transparency) then assert(typeof(transparency) == "number", "Transparency is not a number"); end;

	local self = {};
	self.UIInstance = uiInstance;
	self.Instance = uiInstance:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke");
	self.IsPaused = false;

	self.Color = color or Color3.new(1, 1, 1);
	self.ColorTarget = color or Color3.new(1, 1, 1);
	-- Keep the same semantic name; treat as smoothing rate (higher -> faster)
	self.ColorAcceleration = 1;

	self.Transparency = transparency or 0;
	self.TransparencyTarget = transparency or 0;
	self.TransparencyAcceleration = 1;

	self.Size = size;
	self.SizeTarget = size;
	self.SizeAcceleration = 1;

	self.Connection = nil;
	self.IsText = false;

	if (uiInstance:IsA("TextLabel") or uiInstance:IsA("TextBox") or uiInstance:IsA("TextButton")) then
		self.IsText = true;
	end;

	-- Parent the UIStroke to the UIInstance (preserve original behavior)
	self.Instance.Parent = self.UIInstance;

	-- Heartbeat update: use exponential smoothing for stable, frame-rate independent interpolation
	self.Connection = RunService.Heartbeat:Connect(function(dt)
		if (self.IsPaused) then return; end;
		if (not self.UIInstance or self.UIInstance.Parent == nil) then
			self:Destroy();
			return;
		end;

		-- Color smoothing (Color3:Lerp with frame-rate independent alpha)
		local colorAlpha = smoothingAlpha(self.ColorAcceleration, dt);
		-- Use Color:Lerp with computed alpha
		self.Color = self.Color:Lerp(self.ColorTarget, colorAlpha);

		-- Size smoothing (numeric)
		local sizeAlpha = smoothingAlpha(self.SizeAcceleration, dt);
		self.Size = self.Size + (self.SizeTarget - self.Size) * sizeAlpha;

		-- Transparency smoothing (numeric)
		local transAlpha = smoothingAlpha(self.TransparencyAcceleration, dt);
		self.Transparency = self.Transparency + (self.TransparencyTarget - self.Transparency) * transAlpha;

		-- Apply to instance
		self.Instance.Transparency = self.Transparency;
		self.Instance.Color = self.Color;
		self.Instance.Thickness = self.Size;
	end);

	return setmetatable(self, Stroke);
end

function Stroke:SetSize(size: number, acceleration: number)
	-- Accepts a number as the first argument and a number as the second argument.
	assert(typeof(size) == "number", "Size isn't a number");
	assert(typeof(acceleration) == "number", "Acceleration isn't a number");
	self.SizeTarget = size;
	-- Keep acceleration as a smoothing rate (non-negative)
	self.SizeAcceleration = math.max(0, acceleration);
end

function Stroke:SetTransparency(transparency: number, acceleration: number)
	-- Accepts a number as the first argument and a number as the second argument.
	assert(typeof(transparency) == "number", "Transparency isn't a number");
	assert(typeof(acceleration) == "number", "Acceleration isn't a number");
	self.TransparencyTarget = transparency;
	self.TransparencyAcceleration = math.max(0, acceleration);
end

function Stroke:SetColor(color: Color3, acceleration: number)
	-- Accepts a Color3 as the first argument and a number as the second argument.
	assert(typeof(color) == "Color3", "Color isn't a Color3");
	assert(typeof(acceleration) == "number", "Acceleration isn't a number");
	self.ColorTarget = color;
	self.ColorAcceleration = math.max(0, acceleration);
end

function Stroke:Pause()
	self.IsPaused = true;
end

function Stroke:Resume()
	self.IsPaused = false;
end

function Stroke:Destroy()
	if self.Connection then
		self.Connection:Disconnect();
		self.Connection = nil;
	end;
	if (self.Instance) then
		self.Instance:Destroy();
		self.Instance = nil;
	end;
end

return table.freeze(Stroke);
