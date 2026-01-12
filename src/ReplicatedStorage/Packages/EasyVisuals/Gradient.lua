-- Gradient.luau
-- Updated to ensure smooth continuous wrap-around interpolation for any offset/speed.

local RunService = game:GetService("RunService");

type ColorSequenceKeypoints = typeof(ColorSequence.new(Color3.new()).Keypoints);
type NumberSequenceKeypoints = typeof(NumberSequence.new(0).Keypoints);

export type Gradient<T...> = {
	UIInstance: GuiObject,
	Instance: UIGradient,
	IsPaused: boolean,
	ColorSequence: ColorSequence,
	ColorSequenceTarget: ColorSequence,
	TrueColorSequence: ColorSequence?,
	ColorSequenceBlendRate: number,
	TransparencySequence: NumberSequence,
	TransparencySequenceTarget: NumberSequence,
	TrueTransparencySequence: NumberSequence?,
	TransparencySequenceBlendRate: number,
	Offset: number,
	OffsetTarget: number?,
	OffsetSpeed: number,
	OffsetSpeedTarget: number,
	OffsetAcceleration: number,
	TransparencyOffset: number,
	TransparencyOffsetTarget: number?,
	TransparencyOffsetSpeed: number,
	TransparencyOffsetSpeedTarget: number,
	TransparencyOffsetAcceleration: number,
	Rotation: number,
	RotationTarget: number?,
	RotationSpeed: number,
	RotationSpeedTarget: number,
	RotationAcceleration: number,
	Connection: RBXScriptConnection?,
	IsText: boolean,
	Pause: (self: Gradient<T...>) -> nil,
	Resume: (self: Gradient<T...>) -> nil,
	SetColorSequence: (self: Gradient<T...>, sequence: ColorSequence, blendRate: number?) -> ColorSequence,
	SetOffset: (self: Gradient<T...>, offset: number, acceleration: number?) -> nil,
	SetOffsetSpeed: (self: Gradient<T...>, offset: number, acceleration: number?) -> nil,
	SetRotation: (self: Gradient<T...>, rotation: number, acceleration: number?) -> nil,
	SetRotationSpeed: (self: Gradient<T...>, rotation: number, acceleration: number?) -> nil,
	SetTransparencyOffset: (self: Gradient<T...>, offset: number, acceleration: number?) -> nil,
	SetTransparencyOffsetSpeed: (self: Gradient<T...>, offset: number, acceleration: number?) -> nil,
	SetTransparencySequence: (self: Gradient<T...>, transparency: number | NumberSequence, acceleration: number?) -> nil,
	EqualizeColorSequenceKeypoints: (self: Gradient<T...>) -> nil,
	EqualizeTransparencySequenceKeypoints: (self: Gradient<T...>) -> nil,
	CalculateTrueColorSequence: (self: Gradient<T...>) -> ColorSequence,
	CalculateTrueTransparencySequence: (self: Gradient<T...>) -> NumberSequence,
	Destroy: (self: Gradient<T...>) -> nil,
};

-- Evaluate ColorSequence keypoints at any real time (wrap-safe).
local function evalColorSequence(inputSequence: ColorSequenceKeypoints, time: number)
	-- Build extended sequence with shifts -1, 0, +1 to handle wrap-around
	local sequence = {}
	for shift = -1, 1 do
		for i = 1, #inputSequence do
			local kp = inputSequence[i]
			table.insert(sequence, { Time = kp.Time + shift, Value = kp.Value })
		end
	end

	table.sort(sequence, function(a, b) return a.Time < b.Time end)

	-- Find interval
	for i = 1, #sequence - 1 do
		local a = sequence[i]
		local b = sequence[i + 1]
		if time >= a.Time and time < b.Time then
			local denom = (b.Time - a.Time)
			if denom == 0 then
				return a.Value
			end
			local alpha = (time - a.Time) / denom
			return Color3.new(
				(b.Value.R - a.Value.R) * alpha + a.Value.R,
				(b.Value.G - a.Value.G) * alpha + a.Value.G,
				(b.Value.B - a.Value.B) * alpha + a.Value.B
			)
		end
	end

	-- If exactly equal to last keypoint time
	if #sequence > 0 and math.abs(time - sequence[#sequence].Time) < 1e-8 then
		return sequence[#sequence].Value
	end

	-- Fallback
	if #sequence > 0 then
		return sequence[1].Value
	end

	return Color3.new(1, 1, 1)
end

-- Evaluate NumberSequence keypoints at any real time (wrap-safe).
local function evalNumberSequence(inputSequence: NumberSequenceKeypoints, time: number)
	local sequence = {}
	for shift = -1, 1 do
		for i = 1, #inputSequence do
			local kp = inputSequence[i]
			table.insert(sequence, { Time = kp.Time + shift, Value = kp.Value })
		end
	end

	table.sort(sequence, function(a, b) return a.Time < b.Time end)

	for i = 1, #sequence - 1 do
		local a = sequence[i]
		local b = sequence[i + 1]
		if time >= a.Time and time < b.Time then
			local denom = (b.Time - a.Time)
			if denom == 0 then
				return a.Value
			end
			local alpha = (time - a.Time) / denom
			return a.Value + (b.Value - a.Value) * alpha
		end
	end

	if #sequence > 0 and math.abs(time - sequence[#sequence].Time) < 1e-8 then
		return sequence[#sequence].Value
	end

	if #sequence > 0 then
		return sequence[1].Value
	end

	return 0
end

local MAX_COLORSEQUENCE_KEYPOINTS = 19;
local MAX_NUMBERSEQUENCE_KEYPOINTS = 19;

local Gradient = {}
Gradient.__index = Gradient

-- Helper: fractional part in [0,1). Handles negatives.
local function frac(x)
	local f = x - math.floor(x)
	-- math.floor for negative numbers already works; ensure 0 <= f < 1
	if f < 0 then
		f = f + 1
	end
	-- If f is extremely close to 1 due to floating error, clamp to 0
	if f >= 1 - 1e-12 then
		f = 0
	end
	return f
end

function Gradient.new<T...>(uiInstance: GuiObject | UIStroke, colorSequence: ColorSequence, transparencySequence: number | NumberSequence): Gradient<T...>
	assert(uiInstance, "UIInstance not provided")
	assert(uiInstance:IsA("GuiObject") or uiInstance:IsA("UIStroke"), "UIInstance is not a GuiObject or UIStroke")
	assert(colorSequence, "ColorSequence not provided")
	assert(transparencySequence, "TransparencySequence not provided")
	assert(typeof(colorSequence) == "ColorSequence", "ColorSequence is not a ColorSequence")
	assert(typeof(transparencySequence) == "number" or typeof(transparencySequence) == "NumberSequence", "TransparencySequence is not a number or NumberSequence")
	assert(#colorSequence.Keypoints <= MAX_COLORSEQUENCE_KEYPOINTS, "ColorSequence has too many keypoints")
	if (typeof(transparencySequence) == "NumberSequence") then
		assert(#transparencySequence.Keypoints <= MAX_NUMBERSEQUENCE_KEYPOINTS, "TransparencySequence has too many keypoints")
	end

	local self = {}
	self.UIInstance = uiInstance
	self.Instance = uiInstance:FindFirstChildWhichIsA("UIGradient") or Instance.new("UIGradient")
	self.IsPaused = false

	self.ColorSequenceTarget = colorSequence
	self.ColorSequence = colorSequence
	self.TrueColorSequence = nil
	self.ColorSequenceBlendRate = 1

	self.TransparencySequenceTarget = nil
	self.TransparencySequence = nil
	self.TrueTransparencySequence = nil
	self.TransparencySequenceBlendRate = 1

	self.Offset = 0
	self.OffsetTarget = nil
	self.OffsetSpeed = 0
	self.OffsetSpeedTarget = 0
	self.OffsetAcceleration = 1

	self.TransparencyOffset = 0
	self.TransparencyOffsetTarget = nil
	self.TransparencyOffsetSpeed = 0
	self.TransparencyOffsetSpeedTarget = 0
	self.TransparencyOffsetAcceleration = 1

	self.Rotation = 0
	self.RotationSpeed = 0
	self.RotationSpeedTarget = 0
	self.RotationAcceleration = 0
	self.RotationTarget = nil

	self.Connection = nil
	self.IsText = false

	if (typeof(transparencySequence) == "number") then
		self.TransparencySequenceTarget = NumberSequence.new({ NumberSequenceKeypoint.new(0, transparencySequence), NumberSequenceKeypoint.new(1, transparencySequence) })
	elseif (typeof(transparencySequence) == "NumberSequence") then
		self.TransparencySequenceTarget = transparencySequence
	else
		warn("Weird type of data?")
	end

	self.TransparencySequence = self.TransparencySequenceTarget

	if (uiInstance:IsA("TextLabel") or uiInstance:IsA("TextBox") or uiInstance:IsA("TextButton")) then
		self.IsText = true
	end

	self.Connection = RunService.Heartbeat:Connect(function(dt)
		if (self.IsPaused) then return end
		if (not self.UIInstance or self.UIInstance.Parent == nil) then
			self:Destroy()
			return
		end

		-- Blend color sequence if needed
		if (self.ColorSequenceBlendRate == 1) then
			self.ColorSequence = self.ColorSequenceTarget
		else
			self:EqualizeColorSequenceKeypoints()
		end

		-- Blend transparency sequence if needed
		if (self.TransparencySequenceBlendRate == 1) then
			self.TransparencySequence = self.TransparencySequenceTarget
		end

		-- Offset integration
		if (self.OffsetTarget) then
			self.Offset = self.Offset + (self.OffsetTarget - self.Offset) * self.OffsetAcceleration
		else
			self.OffsetSpeed = self.OffsetSpeed + (self.OffsetSpeedTarget - self.OffsetSpeed) * self.OffsetAcceleration * dt
			self.Offset = self.Offset + self.OffsetSpeed * dt
		end

		-- Transparency offset integration
		if (self.TransparencyOffsetTarget) then
			self.TransparencyOffset = self.TransparencyOffset + (self.TransparencyOffsetTarget - self.TransparencyOffset) * self.TransparencyOffsetAcceleration
		else
			self.TransparencyOffsetSpeed = self.TransparencyOffsetSpeed + (self.TransparencyOffsetSpeedTarget - self.TransparencyOffsetSpeed) * self.TransparencyOffsetAcceleration * dt
			self.TransparencyOffset = self.TransparencyOffset + self.TransparencyOffsetSpeed * dt
		end

		-- Rotation integration
		if (self.RotationTarget) then
			self.Rotation = self.Rotation + (self.RotationTarget - self.Rotation) * self.RotationAcceleration
		else
			self.RotationSpeed = self.RotationSpeed + (self.RotationSpeedTarget - self.RotationSpeed) * self.RotationAcceleration * dt
			self.Rotation = self.Rotation + self.RotationSpeed * dt
		end

		self.Instance.Rotation = self.Rotation
		self.Instance.Color = self:CalculateTrueColorSequence()
		self.Instance.Transparency = self:CalculateTrueTransparencySequence()
	end)

	self.Instance.Parent = self.UIInstance

	return setmetatable(self, Gradient)
end

function Gradient:SetColorSequence(sequence: ColorSequence, blendRate: number?): ColorSequence
	assert(typeof(sequence) == "ColorSequence", "Sequence argument is nil or not a ColorSequence")
	self.ColorSequenceBlendRate = blendRate or 1
	self.ColorSequenceTarget = sequence
	return self.ColorSequenceTarget
end

function Gradient:SetOffset(offset: number, acceleration: number?)
	assert(typeof(offset) == "number", "Offset isn't a number")
	assert(typeof(acceleration) == "number", "Acceleration isn't a number")
	self.OffsetTarget = offset
	self.OffsetSpeed = 0
	self.OffsetSpeedTarget = 0
	self.OffsetAcceleration = math.clamp(acceleration, 0, 1)
end

function Gradient:SetOffsetSpeed(offset: number, acceleration: number?)
	assert(typeof(offset) == "number", "Offset isn't a number")
	assert(typeof(acceleration) == "number", "Acceleration isn't a number")
	self.OffsetSpeedTarget = offset
	self.OffsetTarget = nil
	self.OffsetAcceleration = math.clamp(acceleration, 0, 1)
end

function Gradient:SetRotation(rotation: number, acceleration: number?)
	assert(typeof(rotation) == "number", "Rotation isn't a number")
	assert(typeof(acceleration) == "number", "Acceleration isn't a number")
	self.RotationTarget = rotation
	self.RotationSpeed = 0
	self.RotationSpeedTarget = 0
	self.RotationAcceleration = math.clamp(acceleration, 0, 1)
end

function Gradient:SetRotationSpeed(rotation: number, acceleration: number?)
	assert(typeof(rotation) == "number", "Rotation isn't a number")
	assert(typeof(acceleration) == "number", "Acceleration isn't a number")
	self.RotationSpeedTarget = rotation
	self.RotationTarget = nil
	self.RotationAcceleration = math.clamp(acceleration, 0, 1)
end

function Gradient:SetTransparencyOffset(offset: number, acceleration: number)
	assert(typeof(offset) == "number", "Offset isn't a number")
	assert(typeof(acceleration) == "number", "Acceleration isn't a number")
	self.TransparencyOffsetTarget = offset
	self.TransparencyOffsetSpeed = 0
	self.TransparencyOffsetSpeedTarget = 0
	self.TransparencyOffsetAcceleration = math.clamp(acceleration, 0, 1)
end

function Gradient:SetTransparencyOffsetSpeed(offset: number, acceleration: number)
	assert(typeof(offset) == "number", "Offset isn't a number")
	assert(typeof(acceleration) == "number", "Acceleration isn't a number")
	self.TransparencyOffsetSpeedTarget = offset
	self.TransparencyOffsetTarget = nil
	self.TransparencyOffsetAcceleration = math.clamp(acceleration, 0, 1)
end

function Gradient:SetTransparencySequence(transparency: number | NumberSequence, acceleration: number?)
	assert(transparency, "Transparency is nil")
	assert(typeof(acceleration) == "number", "Acceleration isn't a number")
	if (typeof(transparency) == "number") then
		self.TransparencySequenceTarget = NumberSequence.new({ NumberSequenceKeypoint.new(0, transparency), NumberSequenceKeypoint.new(1, transparency) })
	elseif (typeof(transparency) == "NumberSequence") then
		self.TransparencySequenceTarget = transparency
	else
		warn("Weird type of data?")
	end
	self.TransparencySequenceBlendRate = math.clamp(acceleration or 1, 0, 1)
end

function Gradient:EqualizeColorSequenceKeypoints()
	local keypointsA = self.ColorSequenceTarget.Keypoints
	local keypointsB = self.ColorSequence.Keypoints
	local newkeypoints = {}

	if (#keypointsA ~= #keypointsB) then
		for i = 1, #keypointsA do
			local v = keypointsA[i]
			local sampled = evalColorSequence(keypointsB, v.Time)
			table.insert(newkeypoints, ColorSequenceKeypoint.new(v.Time, sampled))
		end
	else
		for i = 1, #keypointsA do
			local v = keypointsA[i]
			local sample = evalColorSequence(keypointsB, v.Time)
			local blend = sample:Lerp(v.Value, self.ColorSequenceBlendRate)
			table.insert(newkeypoints, ColorSequenceKeypoint.new(v.Time, blend))
		end
	end

	self.ColorSequence = ColorSequence.new(newkeypoints)
end

function Gradient:EqualizeTransparencySequenceKeypoints()
	local keypointsA = self.TransparencySequenceTarget.Keypoints
	local keypointsB = self.TransparencySequence.Keypoints
	local newkeypoints = {}

	if (#keypointsA ~= #keypointsB) then
		for i = 1, #keypointsA do
			local v = keypointsA[i]
			local sampled = evalNumberSequence(keypointsB, v.Time)
			table.insert(newkeypoints, NumberSequenceKeypoint.new(v.Time, sampled))
		end
	else
		for i = 1, #keypointsA do
			local v = keypointsA[i]
			local sample = evalNumberSequence(keypointsB, v.Time)
			local blend = sample + (v.Value - sample) * self.TransparencySequenceBlendRate
			table.insert(newkeypoints, NumberSequenceKeypoint.new(v.Time, blend))
		end
	end

	self.TransparencySequence = NumberSequence.new(newkeypoints)
end

function Gradient:CalculateTrueColorSequence()
	-- Map each original keypoint time through the current offset into [0,1)
	-- and then ensure endpoints at 0 and 1 by sampling the original sequence.
	local offset = self.Offset or 0
	local original = self.ColorSequence.Keypoints
	local temp = {}

	-- Map each keypoint time into [0,1) using fractional part of (time + offset)
	for i = 1, #original do
		local kp = original[i]
		local mapped = frac(kp.Time + offset)
		-- If mapped is extremely close to 0, treat as 0; if extremely close to 1, treat as 1
		-- but frac returns [0,1) so 1 won't occur; we will explicitly add 1 endpoint below.
		table.insert(temp, ColorSequenceKeypoint.new(mapped, kp.Value))
	end

	-- Add sampled endpoints to guarantee continuity across the full [0,1] domain.
	-- Sample original at positions (0 - offset) and (1 - offset) in original sequence space.
	local sampleAt0 = evalColorSequence(original, 0 - offset)
	local sampleAt1 = evalColorSequence(original, 1 - offset)
	table.insert(temp, ColorSequenceKeypoint.new(0, sampleAt0))
	table.insert(temp, ColorSequenceKeypoint.new(1, sampleAt1))

	-- Sort by time and remove duplicates that are extremely close (keep first occurrence)
	table.sort(temp, function(a, b) return a.Time < b.Time end)

	local cleaned = {}
	for i = 1, #temp do
		local kp = temp[i]
		if #cleaned == 0 then
			table.insert(cleaned, kp)
		else
			local last = cleaned[#cleaned]
			if math.abs(kp.Time - last.Time) > 1e-6 then
				table.insert(cleaned, kp)
			else
				-- If times are effectively equal, prefer the one that came from original keypoint (not endpoint),
				-- but keep the existing to preserve ordering; we could also average, but keeping one avoids jitter.
				-- Do nothing (skip duplicate)
			end
		end
	end

	-- Ensure first is exactly 0 and last is exactly 1
	if cleaned[1].Time > 0 then
		table.insert(cleaned, 1, ColorSequenceKeypoint.new(0, sampleAt0))
	end
	if cleaned[#cleaned].Time < 1 then
		table.insert(cleaned, ColorSequenceKeypoint.new(1, sampleAt1))
	end

	self.TrueColorSequence = ColorSequence.new(cleaned)
	return self.TrueColorSequence
end

function Gradient:CalculateTrueTransparencySequence()
	-- Map each original transparency keypoint time through the current transparency offset into [0,1)
	local offset = self.TransparencyOffset or 0
	local original = self.TransparencySequence.Keypoints
	-- Quick path for uniform two-point sequences
	if (#self.TransparencySequenceTarget.Keypoints == 2) then
		local a = self.TransparencySequenceTarget.Keypoints[1].Value
		local b = self.TransparencySequenceTarget.Keypoints[2].Value
		if a == b then
			self.TrueTransparencySequence = self.TransparencySequenceTarget
			return self.TrueTransparencySequence
		end
	end

	local temp = {}
	for i = 1, #original do
		local kp = original[i]
		local mapped = frac(kp.Time + offset)
		table.insert(temp, NumberSequenceKeypoint.new(mapped, kp.Value))
	end

	-- Ensure endpoints by sampling original at (0 - offset) and (1 - offset)
	local v0 = evalNumberSequence(original, 0 - offset)
	local v1 = evalNumberSequence(original, 1 - offset)
	table.insert(temp, NumberSequenceKeypoint.new(0, v0))
	table.insert(temp, NumberSequenceKeypoint.new(1, v1))

	table.sort(temp, function(a, b) return a.Time < b.Time end)

	local cleaned = {}
	for i = 1, #temp do
		local kp = temp[i]
		if #cleaned == 0 then
			table.insert(cleaned, kp)
		else
			local last = cleaned[#cleaned]
			if math.abs(kp.Time - last.Time) > 1e-6 then
				table.insert(cleaned, kp)
			else
				-- skip near-duplicate
			end
		end
	end

	if cleaned[1].Time > 0 then
		table.insert(cleaned, 1, NumberSequenceKeypoint.new(0, v0))
	end
	if cleaned[#cleaned].Time < 1 then
		table.insert(cleaned, NumberSequenceKeypoint.new(1, v1))
	end

	self.TrueTransparencySequence = NumberSequence.new(cleaned)
	return self.TrueTransparencySequence
end

function Gradient:Pause()
	self.IsPaused = true
end

function Gradient:Resume()
	self.IsPaused = false
end

function Gradient:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	if (self.Instance) then
		self.Instance:Destroy()
		self.Instance = nil
	end
end

return table.freeze(Gradient)
