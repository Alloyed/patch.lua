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

local replace_mt  = {REPLACE=true}
local remove_i_mt = {REMOVE_I=true}
local insert_i_mt = {INSERT_I=true}
local Nil_mt      = {NIL=true}

local mt_set = {
	[replace_mt]  = 'explicit_replace',
	[remove_i_mt] = 'remove_i',
	[insert_i_mt] = 'insert_i',
	[Nil_mt]      = 'replace',
}

local function update_type(orig, diff)
	local mt = getmetatable(diff)
	if mt and mt_set[mt] then
		return mt_set[mt]
	elseif orig == patch.Nil then
		return 'replace'
	elseif type(diff) == 'table' and type(orig) == 'table' then
		return 'merge'
	else
		return 'replace'
	end
end

local updaters = {}

function updaters.replace(orig, diff)
	return diff, orig
end

function updaters.explicit_replace(orig, diff)
	return diff.v, orig
end

function updaters.merge(orig, diff, mutate)
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

function updaters.insert_i(orig, diff, mutate)
	assert(orig ~= patch.Nil)
	assert(type(orig) == 'table')

	local i, v = diff.i, diff.v
	local new = orig
	if mutate == false then
		new = shallow_copy(orig)
	end
	table.insert(new, i, v)
	return new, patch.remove_i(i)
end

function updaters.remove_i(orig, diff, mutate)
	assert(orig ~= patch.Nil)
	assert(type(orig) == 'table')

	local i = diff.i

	local new = orig
	if mutate == false then
		new = shallow_copy(orig)
	end
	local v = table.remove(new, i)
	return new, patch.insert_i(i, v)
end

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

	local t = update_type(orig, diff)

	return updaters[t](orig, diff, mutate)
end

--- Returns the patched version of the input value. Patches are a compound
--  datatype that can be made of normal Lua values, as well as "updaters" that
--  have specific patching strategies.
--  @param input the input value
--  @tparam Diff patch the patch to apply
--  @return output, undo
function patch.apply(input, patch)
	return visit(input, patch, false)
end

--- Applies a patch to the input value directly. This should return the same
--  thing as patch.apply(), but the input value is left in an undefined state.
--  @param input the input value
--  @tparam Diff patch the patch to apply
--  @return output, undo
function patch.apply_inplace(input, patch)
	return visit(input, patch, true)
end

--- **NYI**: Merges multiple patches into a single patch.  Patches that change the
--  same field in mutually exclusive ways are considered errors and return nil.
function patch.join(...)
	error("NYI")
end

--- Updaters
--  @section updaters

--- The `nil` updater. When you want to set a field to nil, use this instead of
--  nil directly.
patch.Nil = setmetatable({}, Nil_mt)

--- Returns a `replace` updater. This is the equivalent of setting the field
--  directly to the given value. This can be used for anything, including `nil`,
--  whole tables, or other updaters.
--  @param value the new value
--  @return An opaque updater
function patch.replace(value)
	if value == nil then return patch.Nil end
	return setmetatable({v = value}, replace_mt)
end

--- Returns a `table.remove` updater. This is equivalent to calling
--  `table.remove(tbl, i)` where `tbl` is the input field.
--  @tparam number pos the index of the thing to remove
--  @return An opaque updater
function patch.remove_i(pos)
	assert(pos == nil or type(pos) == 'number')
	return setmetatable({i = pos}, remove_i_mt)
end

--- Returns a `table.insert` updater. This is equivalent to calling
--  `table.insert(tbl, pos, value)` where `tbl` is the input field. Note that
--  the 2-arg variant is not supported: either explicitly name the index or use
--  a merge.
--  @tparam number pos the index to insert `v` at
--  @param value the value to insert
--  @return An opaque updater
function patch.insert_i(pos, value)
	assert(pos == nil or type(pos) == 'number')
	return setmetatable({i = pos, v = value}, insert_i_mt)
end

local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end
local reserved = set {
	"replace",
	"merge",
	"insert_i",
	"remove_i",
	"explicit_replace"
}

--- Registers a custom updater. Each updater has a name, a
--  metatable associated with it, and an update function. When patch.apply sees
--  an object with the associated metatable, it will use apply the update()
--  function instead of a builtin one.
function patch.register_updater(name, mt, update)
	if reserved[name] then
		error("Updater " .. tostring(name) .. " is a builtin.")
	end

	mt_set[mt]     = name
	updaters[name] = update
	return true
end

return patch
