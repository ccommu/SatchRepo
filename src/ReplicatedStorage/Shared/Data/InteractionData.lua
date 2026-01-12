local Interactions = {
	["IntroNPC"] = {
		["ProximityPrompt"] = workspace:WaitForChild("IslandOne"):WaitForChild("IntroCharacter"):WaitForChild("HumanoidRootPart"):WaitForChild("ProximityPrompt"),
		["InitialText"] = "...",
		["MainText"] = "What do you want?",

		["Answers"] = {
			["Answer1"] = "[1] I dont know how to play, can you explain?",
			["Answer2"] = "[2] What do you do?",
			["Answer3"] = "[3] Actually, nevermind. (EXIT CONVERSATION)", 
		},
		["Results"] = {
			["Result1"] = "",
				["Action1"] = "tutorial",
			["Result2"] = "I give information to newbies, and sell some cheap starting stuff. Wanna see?",
				["Action2"] = "secondaryResults",
			["Result3"] = ". . . Alright.",
				["Action3"] = "exit",
		},
		
		["ResultResults"] = {
			["Answer2Answer1"] = "Yes!",
				["ActionAnswer2Answer1"] = "starterShop",
			["Answer2Answer2"] = "Maybe some other time. (EXIT CONVERSATION)",
				["ActionAnswer2Answer2"] = "exit",
		}
	};
}

return Interactions