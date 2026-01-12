--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SharedData = Shared:WaitForChild("Data")

local Networking = Shared:WaitForChild("Networking")
local NPCEvents = Networking:WaitForChild("NPC")

local UnlockNPCEvent = NPCEvents:WaitForChild("UnlockNPC")
local IsNPCUnlockedRequest = NPCEvents:WaitForChild("IsUnlockedNPC")

local InteractionData = require(SharedData:WaitForChild("InteractionData"))
local InteractionTabloid = StarterGui:WaitForChild("NpcInteractionTabloid")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui")
local ShopsFolder = MainGui:WaitForChild("Shops")

local Framework = ReplicatedStorage:WaitForChild("Framework")
local GameManager = require(Framework:WaitForChild("GameController"))

local NPCController
local NotificationController

local NPCUnlockParticles = ReplicatedStorage:WaitForChild("NPCUnlockParticles")
local NPCData = require(SharedData:WaitForChild("NPCData"))

local NPCTalkExample = ReplicatedStorage:WaitForChild("NPCText")

local NewInput = false

local Framework = ReplicatedStorage:WaitForChild("Framework")
local GameManager = require(Framework:WaitForChild("GameController"))

local ShopController

--------------------------------
--\\ Variables //--
--------------------------------

local Module = {}

--------------------------------
--\\ Private Functions //--
--------------------------------

local function HandleDistanceLeave(Rig, ActiveTabloid, ProxPrompt)
	local IsVisible = true
	local Character = Player.Character or Player.CharacterAdded:Wait()
	Character = Player.Character
	local HMRP = Character:FindFirstChild("HumanoidRootPart")
	local NPCHMRP = Rig:FindFirstChild("HumanoidRootPart")
	
	local Connection

	Connection = RunService.RenderStepped:Connect(function()
		if not HMRP then return end
		if NewInput then Connection:Disconnect() end

		local distance = (HMRP.Position - NPCHMRP.Position).Magnitude
		if distance >= ProxPrompt.MaxActivationDistance then
			if IsVisible then
				IsVisible = false
				Player:SetAttribute("InteractingWith", "None")
				HideTabloid(ActiveTabloid)
				ProxPrompt.Enabled = true
				ActiveTabloid:Destroy()

				NewInput = true

				NotificationController:DisplayNotificationLower("Interaction eneded as you strayed too far away.")
			end
		end
	end)
end

local function NPCTalk(Text : string, DelayPerChar : number, ParentObject : BasePart, AfterTextFunction)
	local NPCText = NPCTalkExample:Clone()
	
	local Label = NPCText:FindFirstChild("Label")
	local LabelUIStroke = Label:FindFirstChild("UIStroke")
	
	local ShowTI = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	
	Label.Visible = false
	Label.TextTransparency = 1
	Label.BackgroundTransparency = 1

	LabelUIStroke.Transparency = 1
	
	Label.Visible = true
	NPCText.Enabled = true
	
	NPCText.Parent = ParentObject
	
	local TextTransparencyTween = TweenService:Create(Label, ShowTI, {TextTransparency = 0})
	local BackgroundTransparencyTween = TweenService:Create(Label, ShowTI, {BackgroundTransparency = 0.5})
	local UIStrokeTween = TweenService:Create(LabelUIStroke, ShowTI, {Transparency = 0.5})
	
	TextTransparencyTween:Play()
	BackgroundTransparencyTween:Play()
	UIStrokeTween:Play()
	
	for i = 1, #Text do
		Label.Text = string.sub(Text, 1, i)
		task.wait(DelayPerChar)
	end
	
	task.spawn(function()
		repeat task.wait() until NewInput == true

		NewInput = false
		NPCText:Destroy()
	end)
	
	AfterTextFunction()
end

local function HandleClick(Option, Tabloid, CallbackFunction)
	local ClickDB = false
	local Hovered = false

	local HoverTI = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local ClickTI = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local UIScale = Option:FindFirstChild("UIScale")
	if not UIScale then
		UIScale = Instance.new("UIScale")
		UIScale.Scale = 1
		UIScale.Parent = Option
	end

	
	Option.MouseEnter:Connect(function()
		if not Hovered then
			Hovered = true
			TweenService:Create(UIScale, HoverTI, {Scale = 1.05}):Play()
		end
	end)

	Option.MouseLeave:Connect(function()
		if Hovered then
			Hovered = false
			TweenService:Create(UIScale, HoverTI, {Scale = 1}):Play()
		end
	end)

	Option.MouseButton1Down:Connect(function()
		TweenService:Create(UIScale, ClickTI, {Scale = 0.95}):Play()
	end)

	Option.MouseButton1Up:Connect(function()
		TweenService:Create(UIScale, ClickTI, {Scale = Hovered and 1.05 or 1}):Play()
	end)

	Option.Activated:Connect(function()
		if ClickDB then return end
		ClickDB = true
		CallbackFunction()
		HideTabloid(Tabloid)
	end)
end

function ShowTabloidCleanly(Tabloid, UpToOption, OptionData, ActionsResults, Rig, ProxPrompt, ResultResults)
	task.spawn(function()
		if UpToOption < 1 then return warn(`Cannot interact with less than 1 tabloid option`) end
		if UpToOption > #Tabloid:GetChildren() - 1 then return warn(`Cannot produce more tabloids than are available in the NPC interaction tabloid ({#InteractionTabloid:GetChildren() - 1}.)`) end

		local Options = {}
		for _, OptionInTabloid in Tabloid:GetChildren() do
			if OptionInTabloid:IsA("TextButton") then
				if tonumber(string.sub(OptionInTabloid.Name, 7, 7)) <= UpToOption then
					OptionInTabloid.Active = true
					table.insert(Options, OptionInTabloid)
				end
			end
		end

		local Tweens = {}
		local ShowTI = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

		for Index, Option in pairs(Options) do
			Option.BackgroundTransparency = 1
			Option.TextTransparency = 1
			Option:FindFirstChild("UIStrokeBorder").Transparency = 1
			Option:FindFirstChild("UIStroke").Transparency = 1

			local OptionName = Option.Name
			
			Option.Visible = true
			local OptionTween = TweenService:Create(Option, ShowTI, {BackgroundTransparency = 0.3, TextTransparency = 0})
			local UIStrokeTween = TweenService:Create(Option:FindFirstChild("UIStroke"), ShowTI, {Transparency = 0.5})
			local UIStrokeBorderTween = TweenService:Create(Option:FindFirstChild("UIStrokeBorder"), ShowTI, {Transparency = 0.5})

			Tweens[Index] = {
				MainTween = OptionTween,
				UIStrokeTween = UIStrokeTween,
				BorderUIStrokeTween = UIStrokeBorderTween,
			}

			HandleClick(Option, Tabloid, function()
				local Result = ActionsResults["Result"..tostring(string.sub(OptionName, 7, 7))]
				local Action = ActionsResults["Action"..tostring(string.sub(OptionName, 7, 7))]
				
				NewInput = true
				
				HideTabloid(Tabloid)
				
				Tabloid:Destroy()
				
				if Result ~= "" then
					NPCTalk(Result, 0.05, Rig:FindFirstChild("Head"), function()
						if Action == "secondaryResults" then
							
							HandleDistanceLeave(Rig, Tabloid, ProxPrompt)
							
							local SecondaryUpTo = 0
							
							Tabloid = InteractionTabloid:Clone()
							
							for SResultName, SecondaryResult in pairs(ResultResults) do
								local ResultFromName = string.sub(SResultName, 1, 7)
								local ResultAnswerNum = string.sub(SResultName, 8)
								
								if ResultFromName == OptionName then
									--print(`InteractionController -- RESULT NAME MATCH CHOSEN OPTION: {ResultFromName}. ANSWERNUM: {ResultAnswerNum}`)
									SecondaryUpTo += 1
									
									Tabloid:FindFirstChild(ResultAnswerNum).Text = SecondaryResult
								--else
									--print(`InteractionController -- RESULT NAME NO MATCH OF CHOSEN OPTION: {ResultFromName}. ANSWERNUM: {ResultAnswerNum}`)
								end
							end
							
							local Options = {}
							for _, OptionInTabloid in Tabloid:GetChildren() do
								if OptionInTabloid:IsA("TextButton") then
									if tonumber(string.sub(OptionInTabloid.Name, 7, 7)) <= SecondaryUpTo then
										OptionInTabloid.Active = true
										table.insert(Options, OptionInTabloid)
									end
								end
							end

							local NewTweens = {}

							for NewIndex, NewOption in pairs(Options) do
								NewOption.BackgroundTransparency = 1
								NewOption.TextTransparency = 1
								NewOption:FindFirstChild("UIStrokeBorder").Transparency = 1
								NewOption:FindFirstChild("UIStroke").Transparency = 1

								NewOption.Visible = true
								local NewOptionTween = TweenService:Create(NewOption, ShowTI, {BackgroundTransparency = 0.3, TextTransparency = 0})
								local NewUIStrokeTween = TweenService:Create(NewOption:FindFirstChild("UIStroke"), ShowTI, {Transparency = 0.5})
								local NewUIStrokeBorderTween = TweenService:Create(NewOption:FindFirstChild("UIStrokeBorder"), ShowTI, {Transparency = 0.5})

								NewTweens[NewIndex] = {
									MainTween = NewOptionTween,
									UIStrokeTween = NewUIStrokeTween,
									BorderUIStrokeTween = NewUIStrokeBorderTween,
								}
								
								HandleClick(NewOption, Tabloid, function()
									if NewInput == false then
										NewInput = true
										
										local Action = ResultResults["Action"..OptionName..NewOption.Name]
										
										if Action == "exit" then
											HideTabloid(Tabloid)
											Player:SetAttribute("InteractingWith", "None")
											ProxPrompt.Enabled = true

											task.delay(0.5, function()
												NewInput = true
											end)
										elseif Action == "starterShop" then
											
											ShopController:OpenShop(ShopsFolder:WaitForChild("StarterShop"))
											
											task.delay(0.5, function()
												NewInput = true
												ProxPrompt.Enabled = true
												Player:SetAttribute("InteractingWith", "None")
											end)
											
										end
									end
								end)
							end
							
							Tabloid.Parent = Player.PlayerGui
							Tabloid.Adornee = Rig:FindFirstChild("HumanoidRootPart")
							
							Tabloid.Enabled = true
							print(`Enabled Tabloid`)
							
							for _, TweenGroup in pairs(NewTweens) do
								TweenGroup.MainTween:Play()
								TweenGroup.UIStrokeTween:Play()
								TweenGroup.BorderUIStrokeTween:Play()
								task.wait(0.1)
							end
							print(`Showed All Options`)
						elseif Action == "exit" then
							HideTabloid(Tabloid)
							Player:SetAttribute("InteractingWith", "None")
							ProxPrompt.Enabled = true
							
							task.delay(0.5, function()
								NewInput = true
							end)
						elseif Action == "tutorial" then
							print("TUTORIAL")
						end
					end)
				end
			end)
		end

		for Name, Text in pairs(OptionData) do
			Tabloid:FindFirstChild(Name).Text = Text
		end

		for _, TweenGroup in pairs(Tweens) do
			TweenGroup.MainTween:Play()
			TweenGroup.UIStrokeTween:Play()
			TweenGroup.BorderUIStrokeTween:Play()
			task.wait(0.1)
		end
	end)
end

function HideTabloid(Tabloid)
	local Tweens = {}
	local TI = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	for _, Item in Tabloid:GetChildren() do
		if Item:IsA("TextButton") and Item.Visible == true then
			local MainTween = TweenService:Create(Item, TI, {BackgroundTransparency = 1, TextTransparency = 1})
			local StrokeTween = TweenService:Create(Item:FindFirstChild("UIStroke"), TI, {Transparency = 1})
			local StrokeBorderTween = TweenService:Create(Item:FindFirstChild("UIStrokeBorder"), TI, {Transparency = 1})

			table.insert(Tweens, MainTween)
			table.insert(Tweens, StrokeTween)
			table.insert(Tweens, StrokeBorderTween)

			task.spawn(function()
				StrokeBorderTween.Completed:Wait()
				Item.Visible = false
			end)
		end
	end

	for _, Tween in Tweens do
		Tween:Play()
	end
end

local function InitiateInteractions()
	for NPCDATANAME, Data in InteractionData do
		local ProxPrompt = Data["ProximityPrompt"]
		local OptionTexts = {}
		local NumOfOptions = 0

		for Index, Answer in Data["Answers"] do
			OptionTexts[Index] = Answer
			NumOfOptions += 1
		end

		ProxPrompt.Triggered:Connect(function()
			if ShopController:CanIInteract() then
				local Tabloid = InteractionTabloid:Clone()

				Tabloid.Active = true
				Tabloid.AlwaysOnTop = true
				Tabloid.MaxDistance = 30
				Tabloid.Adornee = ProxPrompt.Parent
				Tabloid.Parent = Player.PlayerGui
				Tabloid.Enabled = true

				ProxPrompt.Enabled = false

				Player:SetAttribute("InteractingWith", NPCDATANAME)

				task.spawn(function()
					local IsNPCUnlocked = IsNPCUnlockedRequest:InvokeServer(NPCDATANAME)

					if IsNPCUnlocked == false then
						UnlockNPCEvent:FireServer(ProxPrompt.Parent.Parent, NPCDATANAME)

						task.wait(0.3)
						if IsNPCUnlockedRequest:InvokeServer(NPCDATANAME) == true then
							local UnlockParticles = NPCUnlockParticles:Clone()
							UnlockParticles.Parent = ProxPrompt.Parent.Parent:FindFirstChild("Head")

							NPCController:UpdateNPCName(ProxPrompt.Parent.Parent, NPCData[NPCDATANAME].Name)

							task.spawn(function()
								UnlockParticles:FindFirstChild("1"):Emit(50)
								UnlockParticles:FindFirstChild("2"):Emit(15)

								NotificationController:DisplayNotification("Unlocked:", `{NPCData[NPCDATANAME].Name} ({NPCData[NPCDATANAME].NPCType}) NPC `)

								task.wait(5)
								UnlockParticles:Destroy()
							end)
						else
							warn(`InteractionController - Something went wrong unlocking NPC {NPCDATANAME}.`)
						end
					end
				end)

				NPCTalk(Data["InitialText"], 1, ProxPrompt.Parent.Parent:FindFirstChild("Head"), function()
					NewInput = true
					NPCTalk(Data["MainText"], 0.05, ProxPrompt.Parent.Parent:FindFirstChild("Head"), function()
						ShowTabloidCleanly(Tabloid, NumOfOptions, OptionTexts, Data["Results"], ProxPrompt.Parent.Parent, ProxPrompt, Data["ResultResults"])

						HandleDistanceLeave(ProxPrompt.Parent.Parent, Tabloid, ProxPrompt)
					end)
				end)
			else
				NPCTalk("... You're in a shop right now.", 0.05, ProxPrompt.Parent.Parent:FindFirstChild("Head"), function()
					task.delay(3, function()
						NewInput = true
					end)
				end)
			end
		end)
	end
end

--------------------------------
--\\ Public Functions //--
--------------------------------

function Module:OnStart()
	print(`InteractionController Started`)
	repeat task.wait() until GameManager:IsGameLoaded() == true
	
	NPCController = GameManager:GetController("NPCController")
	NotificationController = GameManager:GetController("NotificationController")
	ShopController = GameManager:GetController("ShopController")
	
	InitiateInteractions()
end

--------------------------------
--\\ Main //--
--------------------------------

return Module
