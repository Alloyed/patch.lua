--- @module patch
local patch = {}

local function shallow_copy(t)
	local new = {}
	for k, v in pairs(t) do
		new[k] = v
	end
	setmetatable(new, getmetatable(t))
	return new
end

local visit
local function merge(orig, diff, mutate)
	if not next(diff) then -- empty diff
		return orig, nil
	end

	local new = orig
	if mutate == false then
		new = shallow_copy(orig)
	end

	local undo = {}
	for k, v in pairs(diff) do
		local new_v, undo_v = visit(orig[k], v, mutate)
		undo[k] = undo_v
		new[k] = new_v
	end

	return new, undo
end

local function remove_i(orig, i, mutate)
	local new = orig
	if mutate == false then
		new = shallow_copy(orig)
	end
	local v = table.remove(new, i)
	return new, patch.insert_i(i, v)
end

local function insert_i(orig, i, v, mutate)
	local new = orig
	if mutate == false then
		new = shallow_copy(orig)
	end
	table.insert(new, i, v)
	return new, patch.remove_i(i)
end

local replace_mt  = {REPLACE=true}
local remove_i_mt = {REMOVE_I=true}
local insert_i_mt = {INSERT_I=true}
local update_mt   = {UPDATE=true}

function visit(orig, diff, mutate)
	if diff == patch.Nil then
		diff = nil
	end

	if diff == orig then
		return orig, nil -- no-op
	end

	if orig == nil then
		orig = patch.Nil
	end

	if getmetatable(diff) == replace_mt then
		return diff.v, patch.replace(orig)
	elseif getmetatable(diff) == remove_i_mt then
		assert(orig ~= patch.Nil)
		assert(type(orig) == 'table')
		return remove_i(orig, diff.i, mutate)
	elseif getmetatable(diff) == insert_i_mt then
		assert(orig ~= patch.Nil)
		assert(type(orig) == 'table')
		return insert_i(orig, diff.i, diff.v, mutate)
	elseif orig == patch.Nil then
		return diff, orig
	elseif getmetatable(diff) == update_mt then
		return diff.fn(orig, unpack(diff.args, 1, diff.n)), patch.replace(orig)
	elseif type(diff) == 'table' and type(orig) == 'table' then
		return merge(orig, diff, mutate)
	else
		return diff, patch.replace(orig)
	end
end

--- The "nil" updater. When you want to set a field to nil, use this instead of
--  nil directly.
patch.Nil = setmetatable({}, {NIL = true})

--- Returns a "replace" updater. This forces patch() to replace the field with
--  the given value. This can be used for anything, including `nil` and other.
--  updaters.
--  @param v the new value
function patch.replace(v)
	return setmetatable({v = v}, replace_mt)
end

--- Returns a "remove_i" updater. This is equivalent to table.remove.
function patch.remove_i(i)
	assert(i == nil or type(i) == 'number')
	return setmetatable({i = i}, remove_i_mt)
end

--- Returns an "insert_i" updater. This is equivalent to table.insert()
function patch.insert_i(i, v)
	assert(i == nil or type(i) == 'number')
	return setmetatable({i = i, v = v}, insert_i_mt)
end

--- Returns a custom updater. Takes a function that, given an old value,
--  returns an a new, updated value.
--  @param fn the updater function
--  @param ... extra arguments to pass to fn
function patch.update(fn, ...)
	return setmetatable({fn = fn, n = select('#', ...), args = {...}}, update_mt)
end

-- joins multiple patches together
function patch.join(...)
	error("NYI")
end

--- Returns the patched version of the input value. Patches are a compound
--  datatype that can be made of normal Lua values, as well as "updaters" that
--  have specific patching strategies.
--  @tparam any input the input value
--  @tparam Diff patch the patch to apply
function patch.apply(input, patch)
	return visit(input, patch, false)
end

--- Applies a patch to the input value directly. This should return the same
--  thing as patch.apply(), but the input value is left in an undefined state.
--  @tparam any input the input value
--  @tparam Diff patch the patch to apply
function patch.apply_inplace(input, patch)
	return visit(input, patch, true)
end

return patch
