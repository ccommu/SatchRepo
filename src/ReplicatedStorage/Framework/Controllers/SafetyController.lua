--------------------------------
--\\ Services //--
--------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

--------------------------------
--\\ Constants //--
--------------------------------

local PossibleSafetyNeededMessages = {
	"disboard",
	"discorn",
	"discord",
	"purple app",
	"alien app",
	"app",
	"whats your username on",
	"username on",
	"d1sc0rd",
	"d1sc0rn",
	"disco",
	"whats your",
	"phone",
	"telegram",
	"snap",
	"snapchat",
	"sn3pch3t",
	"tele",
	"messenger",
	"messager",
	"msnger",
	"dscrd",
	"d1scrd",
	"contact",
	"your information",
	"your info",
	"your number",
	"dc",
	"my number",
	"dm",
	"call",
	"text",
	"message",
	"txt",
	"how old",
	"age",
	"your user",
	"blue app",
	"birthday",
	"adress",
	"live",
	"location",
	"my info",
	"what's your",
	"whats your user",
	"what's your user",
	"what is your",
	"what is your user",
	"tele",
	"nmber",
	"whts your",
	"d1sc",
	"read backwards",
	"decode",
	"d i s c o r d"
}

local SafeText = "Warning! Be careful when going off platform and try to avoid it! Be careful when giving any information to people online, as it is unsafe and can be dangerous. Stay safe online."

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}
local FoundSafetyInIDs = {}

--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:OnStart()
	print(`SafetyController Initiated. Will attempt to prevent any harmful behavior`)

	TextChatService.OnIncomingMessage = function(Message : TextChatMessage)
		local Text = Message.Text
		local ID = Message.MessageId

		for _, Check in ipairs(PossibleSafetyNeededMessages) do
			if not FoundSafetyInIDs[ID] and string.find(string.lower(Text), string.lower(Check), 1, true) then
				FoundSafetyInIDs[ID] = true

				TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(`<font color='#ffd500'>{"[SERVER]: "..SafeText}</font>`)
			end
		end
	end
end

--------------------------------
--\\ Main //--
--------------------------------

return Controller