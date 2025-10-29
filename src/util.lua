local util = {}



-- mantiene le metatabelle, al contrario della funzione fornita da Luanti
function util.deepcopy(obj, seen)
	if type(obj) ~= 'table' then
		return obj
	end
	if seen and seen[obj] then
		return seen[obj]
	end
	local s = seen or {}
	local copy = setmetatable({}, getmetatable(obj))
	s[obj] = copy
	for k, v in pairs(obj) do
		copy[util.deepcopy(k, s)] = util.deepcopy(v, s)
	end
	return copy
end

return util