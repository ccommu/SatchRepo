local AnimationsStorage = game:GetService("ReplicatedStorage"):FindFirstChild("Animations")

local AnimationData = {
	["MainChar"] = {
		["Animation"] = AnimationsStorage:WaitForChild("SittingAnimation"):WaitForChild("Animation"),
		["Version"] = AnimationsStorage:FindFirstChild("SittingAnimation"):WaitForChild("Version").Value,
		["Animator"] =  workspace:WaitForChild("IslandOne"):WaitForChild("IntroCharacter"):WaitForChild("Humanoid"):WaitForChild("Animator"),
		["Credits"] = AnimationsStorage:FindFirstChild("SittingAnimation"):WaitForChild("Credits").Value,
		["Name"] = "SittingAnimation",
		["Rig"] = workspace:FindFirstChild("IslandOne"):FindFirstChild("IntroCharacter"),
		["IsLooped"] = true,
		["CreditOnly"] = false
	};
	["Walking"] = {
		["Name"] = "Walk3",
		["Credits"] = AnimationsStorage:WaitForChild("WalkingAnimation"):WaitForChild("Credits").Value,
		["CreditOnly"] = true,
		["ID"] = "rbxassetid://74735142371088" --// OPTIONAL, PURELY FOR FUTURE USEAGE IF NEEDED
	};
	["Running"] = {
		["Name"] = "Run2",
		["Credits"] = AnimationsStorage:WaitForChild("RunningAnimation"):WaitForChild("Credits").Value,
		["CreditOnly"] = true,
		["ID"] = "rbxassetid://74448893257393" --// OPTIONAL, PURELY FOR FUTURE USEAGE IF NEEDED
	};
	["Idle"] = {
		["Name"] = "Idle2",
		["Credits"] = AnimationsStorage:WaitForChild("IdleAnimation"):WaitForChild("Credits").Value,
		["CreditOnly"] = true,
		["ID"] = "rbxassetid://139112408040175" --// OPTIONAL, PURELY FOR FUTURE USEAGE IF NEEDED
	};
	["Dig"] = {
		["Name"] = "DiggingAnimation",
		["Credits"] = AnimationsStorage:WaitForChild("DiggingAnimation"):WaitForChild("Credits").Value,
		["CreditOnly"] = true,
		["ID"] = "rbxassetid://72407752135535" --// OPTIONAL, PURELY FOR FUTURE USEAGE IF NEEDED
	};
}

return AnimationData