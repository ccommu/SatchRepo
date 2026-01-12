--------------------------------
--\\ Constants //--
--------------------------------

local suffixes = {
	{1e15, "Q"},
	{1e12, "T"},
	{1e9, "B"},
	{1e6, "M"},
	{1e3, "K"},
}

--------------------------------
--\\ Variables //--
--------------------------------

local Utils = {}

--------------------------------
--\\ Public Functions //--
--------------------------------

function Utils:Init()
	print("Numbers Util Initated")
end

function Utils:FormatNumber(Number : number)
	if math.abs(Number) < 1000 then
		return tostring(Number)
	end

	for _, v in ipairs(suffixes) do
		local value, suffix = v[1], v[2]
		if math.abs(Number) >= value then
			local shortened = Number / value
			if shortened % 1 == 0 then
				return string.format("%d%s", shortened, suffix)
			else
				return string.format("%.1f%s", shortened, suffix)
			end
		end
	end
end

--------------------------------
--\\ Main //--
--------------------------------

return Utils