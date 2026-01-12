--------------------------------
--\\ Services //--
--------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Networking = Shared:WaitForChild("Networking")
local MiscEvents = Networking:WaitForChild("Misc")
local AmIAdminRequest = MiscEvents:WaitForChild("AmIAdmin")
local DragRequest = MiscEvents:WaitForChild("DragRequest")

local Player = Players.LocalPlayer
local MaxDistance = 25

local Highlight = script:WaitForChild("SelectedHighlight")
local ObjectNameBillboard = script:WaitForChild("PartNameBillboard")
local ObjectNameBillboardTextObject = ObjectNameBillboard:WaitForChild("ObjectName")

local DragTargetAttachment = workspace.Terrain:WaitForChild("DragTarget")
local AlignPos = script:WaitForChild("AlignPosition")
local AlignOrient = script:WaitForChild("AlignOrientation")

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}

local Target
local GrabbingObject
local DragDistance = 0

local IsAdmin = AmIAdminRequest:InvokeServer()

--------------------------------
--\\ Private Functions //--
--------------------------------

local function HighlightObject(Object, EnableBillboard)
	Highlight.Adornee = Object
	ObjectNameBillboard.Adornee = Object
	ObjectNameBillboard.Enabled = EnableBillboard
	if Object then
		ObjectNameBillboardTextObject.Text = string.gsub(Object.Name, "_", " ")
	end
end

local function DropObject()
	if not GrabbingObject then return end
	DragRequest:InvokeServer(GrabbingObject, false)
	GrabbingObject = nil
	AlignPos.Attachment0 = nil
	AlignOrient.Attachment0 = nil
	AlignPos.Parent = script
	AlignOrient.Parent = script
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:OnStart()
	ObjectNameBillboard.Parent = Player.PlayerGui

	UserInputService.InputBegan:Connect(function(Input, Processed)
		if Processed then return end
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not Target or GrabbingObject then return end

		local GrantedObject = DragRequest:InvokeServer(Target, true)
		if GrantedObject then
			GrabbingObject = GrantedObject
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		DropObject()
	end)

	Player.CharacterRemoving:Connect(function()
		DropObject()
	end)

	RunService.Heartbeat:Connect(function()
		if not workspace.CurrentCamera then return end

		local MousePosition = UserInputService:GetMouseLocation()
		local Ray = workspace.CurrentCamera:ViewportPointToRay(MousePosition.X, MousePosition.Y)

		if GrabbingObject then
			local DragAttachment = GrabbingObject:FindFirstChild("DragAttachment") or Instance.new("Attachment", GrabbingObject)
			DragAttachment.Name = "DragAttachment"

			AlignPos.Attachment0 = DragAttachment
			AlignOrient.Attachment0 = DragAttachment
			AlignPos.Parent = GrabbingObject
			AlignOrient.Parent = GrabbingObject

			local WorldPoint = Ray.Origin + Ray.Direction * DragDistance
			DragTargetAttachment.WorldCFrame = CFrame.new(WorldPoint, workspace.CurrentCamera.CFrame.Position)

			HighlightObject(GrabbingObject, false)
		else
			if not Player.Character then return end

			local Params = RaycastParams.new()
			Params.FilterType = Enum.RaycastFilterType.Exclude
			Params.FilterDescendantsInstances = Player.Character:GetDescendants()

			local Result = workspace:Raycast(Ray.Origin, Ray.Direction * MaxDistance, Params)

			if Result and Result.Instance and Result.Instance:IsA("BasePart") and not Result.Instance.Anchored and (IsAdmin or Result.Instance:HasTag("allowDrag")) then
				Target = Result.Instance
				DragDistance = (Ray.Origin - Result.Position).Magnitude
				HighlightObject(Target, true)
			else
				Target = nil
				HighlightObject(nil, false)
			end
		end
	end)
end

return Controller
