local Players = game:GetService("Players")

local RemoteSecurity = {}

-- lastUsed[player.UserId] = { [key] = timestamp }
local lastUsed = {}

local function getPlayerTable(player)
	if not player or typeof(player) ~= "Instance" then
		return nil
	end
	local uid = player.UserId
	lastUsed[uid] = lastUsed[uid] or {}
	return lastUsed[uid]
end

function RemoteSecurity:CheckCooldown(player, key, cooldownSeconds)
	local now = tick()
	local t = getPlayerTable(player)
	if not t then
		return false
	end
	local last = t[key]
	if last and (now - last) < cooldownSeconds then
		return false, cooldownSeconds - (now - last)
	end
	t[key] = now
	return true
end

function RemoteSecurity:Reset(player, key)
	local t = getPlayerTable(player)
	if not t then
		return
	end
	t[key] = nil
end

function RemoteSecurity:Init()
	print(`RemoteSecurity Utils Initialized`)
end

return RemoteSecurity