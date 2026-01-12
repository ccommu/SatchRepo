--------------------------------
--\\ Services //--
--------------------------------

local ServerScriptService = game:GetService("ServerScriptService")

--------------------------------
--\\ Constants //--
--------------------------------

local Packages = ServerScriptService:FindFirstChild("Packages")
local ProfileStorePackage = Packages:FindFirstChild("ProfileStore")
local DataManager = require(ProfileStorePackage:FindFirstChild("DataManager"))

--------------------------------
--\\ Variables //--
--------------------------------

local Service = {}

--------------------------------
--\\ Private Functions //--
--------------------------------


--------------------------------
--\\ Public Functions //--
--------------------------------

-- User is the user to be banned, Reason is the displayed ban reason, not counting the formatting, BanTime is how long the ban should last in seconds set to -1 for infinite ban.
function Service:BanUser(User : Player, Reason : string, BanTime : number)
	DataManager.BanUser(User, Reason, BanTime)
end

function Service:OnStart()
	print(`Security Service Initiated.`)
end


--------------------------------
--\\ Main //--
--------------------------------

return Service