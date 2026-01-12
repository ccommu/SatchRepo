local Data = {}

Data.DEFAULT_PLAYER_DATA = {
	DiscoveredNPCS = {},
	Currency = 50,
	Level = 1,
	OwnedSatchels = {},
	SavedInventory = {},
	
	Banned = false, 
	BanReason = nil,
	BanTime = nil,
	BanLength = nil,
}

export type PlayerData = typeof(Data.DEFAULT_PLAYER_DATA)

return Data
