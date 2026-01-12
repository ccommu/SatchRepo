--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local MiscEvents = Networking:WaitForChild("Misc")

local DebugEvent = MiscEvents:WaitForChild("Debug")
local AmIAdmin = MiscEvents:WaitForChild("AmIAdmin")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Icon = require(Packages.Icon)

local CurrentType = "n"

local DebugUI = script:WaitForChild("DebugUI")
local MainDebugUI = DebugUI:WaitForChild("Main")

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function FormatOsTime(osTime)
	local timeTable = os.date("*t", osTime)
	local fractional = tick() % 1
	local secondsWithFraction = timeTable.sec + fractional
	return string.format("%02d:%02d:%06.3f", timeTable.hour, timeTable.min, secondsWithFraction)
end

local function CreateClippingDetector(TextLabel)
	local Parent = TextLabel.Parent.Parent

	local function CheckClipping()
		local tlPos = TextLabel.AbsolutePosition
		local tlEnd = tlPos + TextLabel.AbsoluteSize

		local pPos = Parent.AbsolutePosition
		local pEnd = pPos + Parent.AbsoluteSize

		local clipped =
			tlPos.X < pPos.X or
			tlPos.Y < pPos.Y or
			tlEnd.X > pEnd.X or
			tlEnd.Y > pEnd.Y
		
		if clipped then
			TextLabel:Destroy()
		end
	end

	TextLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(CheckClipping)
	TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckClipping)
	Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckClipping)
	Parent:GetPropertyChangedSignal("AbsolutePosition"):Connect(CheckClipping)

	CheckClipping()
end

local function CreateDebugLabel(text : string, timeoccured, level : string, client : boolean)
	local Type
	local Color
	local ClientOrServerText

	if client then
		ClientOrServerText = "Client"
	else
		ClientOrServerText = "Server"
	end

	if level == "I" then
		Type = "Info"
		Color = Color3.fromRGB(215, 240, 255)
	elseif level == "O" then
		Type = "Output"
		if client then
			Color = Color3.fromRGB(129, 207, 255)
		else
			Color = Color3.fromRGB(128, 255, 128)
		end
	elseif level == "W" then
		Type = "Warning"
		Color = Color3.fromRGB(255, 174, 43)
	elseif level == "E" then
		Type = "ERROR"
		Color = Color3.fromRGB(255, 0, 0)
	end

	local FormattedText = string.format("%s: %s  %s: %s", ClientOrServerText, FormatOsTime(timeoccured), Type, text)

	local Example = MainDebugUI:WaitForChild("Output"):WaitForChild("Example")
	local Output = Example:Clone()

	Output.Text = FormattedText
	Output.TextColor3 = Color
	Output.Visible = true

	-- Insert new outputs at the top
	Output.Parent = Example.Parent
	Output.LayoutOrder = -tick()  -- Ensures newest output has highest priority

	CreateClippingDetector(Output)
end


--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:OnStart()
	if AmIAdmin:InvokeServer() == false then script:Destroy() end
	
	DebugUI.Parent = game:GetService("Players").LocalPlayer.PlayerGui
	
	local TextChatService = game:GetService("TextChatService")
	local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
	
	MainDebugUI.Visible = false

	if channel then
		DebugEvent.OnClientEvent:Connect(function(message, MessageType)
			CreateDebugLabel(message, os.time(), MessageType, false)
		end)
	end
	
	local debugIcon = Icon.new()
		:setLabel("Debug")
		:setImage(11663743444)
		:setTextSize(16)
		:align("Left")
		:setEnabled(true)

	local stopDebug = Icon.new()
		:setLabel("Stop Debug")
		:oneClick(true)
		:bindEvent("selected", function(icon) 
			DebugEvent:FireServer(nil, true)
			CurrentType = "n"
			MainDebugUI.Visible = false
		end)

	local startFull = Icon.new()
		:setLabel("Start Full Debug")
		:oneClick(true)
		:bindEvent("selected", function(icon)
			DebugEvent:FireServer("S-All")
			CurrentType = "a"
			MainDebugUI.Visible = true
		end)

	local startSelect = Icon.new()
		:setLabel("Start Select Debug")
		:oneClick(true)
		:bindEvent("selected", function(icon)
			DebugEvent:FireServer("S-Select")
			CurrentType = "s"
			MainDebugUI.Visible = true
		end)

	debugIcon:setDropdown({ stopDebug, startFull, startSelect })
		:autoDeselect(true)
		:setEnabled(true)
	
	LogService.MessageOut:Connect(function(message, MessageType)
		if CurrentType == "a" then
			if MessageType == Enum.MessageType.MessageOutput then
				CreateDebugLabel(message, os.time(), "O", true)
			elseif MessageType == Enum.MessageType.MessageInfo then
				CreateDebugLabel(message, os.time(), "I", true)
			elseif MessageType == Enum.MessageType.MessageWarning then
				CreateDebugLabel(message, os.time(), "W", true)
			end
		end
		
		if MessageType == Enum.MessageType.MessageError then
			channel:DisplaySystemMessage('<font color="#FF0000" face="Montserrat">(CLIENT) ERROR: '..message..'</font>')
			CreateDebugLabel(message, os.time(), "E", true)
		end
		
		--No check for type "s" because that should be called either by server or client directly, not via a messageout
	end)
	
	print(`DebugController Initiated.`)
end


--------------------------------
--\\ Main //--
--------------------------------

return Controller