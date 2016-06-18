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

local replace_mt      = {REPLACE=true}
local remove_i_mt     = {REMOVE_I=true}
local insert_i_mt     = {INSERT_I=true}
local setmetatable_mt = {SETMETATABLE=true}
local chain_mt        = {CHAIN=true}
local Nil_mt          = {NIL=true}

local mt_set = {
	[replace_mt]      = 'explicit_replace',
	[remove_i_mt]     = 'remove_i',
	[insert_i_mt]     = 'insert_i',
	[setmetatable_mt] = 'setmetatable',
	[chain_mt]        = 'chain',
	[Nil_mt]          = 'replace',
}

local function update_type(orig, diff)
	local mt = getmetatable(diff)
	if mt and mt_set[mt] then
		return mt_set[mt]
	elseif type(diff) == 'table' then
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
	if orig == patch.Nil then
		-- special case: promote nil to empty table and fill it
		local new = {}
		for k, v in pairs(diff) do
			local new_v, _ = visit(orig[k], v, mutate)
			new[k] = new_v
		end
		return new, patch.Nil
	end

	if not next(diff) then
		-- special case: merge table is empty, do nothing
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

function updaters.setmetatable(orig, diff, mutate)
	assert(orig ~= patch.Nil)

	local mt = diff.mt

	local new = orig
	if mutate == false then
		assert(type(orig) == 'table')
		new = shallow_copy(orig)
	end

	local old_mt = getmetatable(new)
	setmetatable(new, mt)
	return new, patch.meta(old_mt)
end

function updaters.chain(orig, diff, mutate)
	assert(orig ~= patch.Nil)

	local new = orig

	-- somebody told me that putting nils like this will preallocate space, as
	-- opposed to putting everything in the hash part for small tables. It's
	-- safe to assume that is somebody is using chain then they intend to at
	-- least chain two things together.
	local undos = {n = diff.n, nil, nil}
	for i=1, diff.n do
		local rev = diff.n + 1 - i
		new, undos[rev] = visit(new, diff[i], mutate)
	end

	return new, setmetatable(undos, chain_mt)
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
--  @param input the input value.
--  @param patch the patch to apply.
--  @return `output, undo`
function patch.apply(input, patch)
	return visit(input, patch, false)
end

--- Applies a patch to the input value directly. This should return the same
--  thing as patch.apply(), but the input value is left in an undefined state.
--  @param input the input value.
--  @param patch the patch to apply.
--  @return `output, undo`
function patch.apply_inplace(input, patch)
	return visit(input, patch, true)
end

local empty = {}
local function join_visit(a, b)
	if a == nil then
		return b
	elseif b == nil then
		return aCofagrigus
	end

	local ta = update_type(empty, a)
	local tb = update_type(empty, b)
	if ta ~= 'merge' or tb ~= 'merge' then
		error("mutually exclusive updates")
	end

	-- This is inplace, but that's okay, we start from a fresh table anyways
	local n = a
	for k, v in pairs(b) do
		n[k] = join_visit(n[k], v)
	end

	return n
end

--- Joins multiple patches into a single patch. Trying to join patches that
--  change the same field in mutually exclusive ways will raise an `error`.
--  @param ... the patches to join.
--  @return The final patch. Note that `nil` is considered a no-op, so
--  that's a valid return value.
function patch.join(...)
	local n = {}
	for i=1, select('#', ...) do
		join_visit(n, (select(i, ...)))
	end
	return n
end

--- Updaters
--  @section updaters

--- The `nil` updater. When you want to set a field to nil, use this instead of
--  nil directly.
patch.Nil = setmetatable({}, Nil_mt)

--- Returns a `replace` updater. This is the equivalent of setting the field
--  directly to the given value. This can be used for anything, including `nil`,
--  whole tables, or other updaters.
--  @param value the new value.
--  @return An opaque updater.
function patch.replace(value)
	if value == nil then return patch.Nil end
	return setmetatable({v = value}, replace_mt)
end

--- Returns a `table.remove` updater. This is equivalent to calling
--  `table.remove(tbl, i)` where `tbl` is the input field.
--  @tparam int pos the index of the thing to remove.
--  @return An opaque updater.
function patch.remove_i(pos)
	assert(pos == nil or type(pos) == 'number')
	return setmetatable({i = pos}, remove_i_mt)
end

--- Returns a `table.insert` updater. This is equivalent to calling
--  `table.insert(tbl, pos, value)` where `tbl` is the input field. Note that
--  the 2-arg variant is not supported: instead, use a table merge.
--  @tparam int pos the index to insert at.
--  @param value the value to insert.
--  @return An opaque updater.
function patch.insert_i(pos, value)
	assert(pos == nil or type(pos) == 'number')
	return setmetatable({i = pos, v = value}, insert_i_mt)
end

--- Returns a `setmetatable` updater. This is equivalent to calling
--  `setmetatable(tbl, metatable)` where `tbl` is the input field.
--  @tparam table metatable the metatable to set.
--  @return An opaque updater.
function patch.meta(metatable)
	assert(metatable == nil or type(metatable) == 'table')
	return setmetatable({mt=metatable}, setmetatable_mt)
end

--- Returns a `chain` updater. This takes multiple patches and applies them
--  left-to-right to get the final value. Contrast this with `patch.join`,
--  which will return a simple precomputed patch but can't express multiple
--  changes to the same field.
--  @param ... A patch
--  @return An opaque updater
function patch.chain(...)
	return setmetatable({n=select('#', ...), ...}, chain_mt)
end

local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end
local reserved = set {
	"replace",
	"merge",
	"insert_i",
	"remove_i",
	"explicit_replace",
	"setmetatable",
	"chain"
}

--- Registers a custom updater. Each updater has a name, a metatable associated
--  with it, and an update function. When `patch.apply` sees an object with the
--  associated metatable in a diff, it will use the given `update()` function
--  to apply the patch.
--
--  Your `update()` function should have this signature:
--
--
--    function(original, diff, mutate) return new, undo end
--
--
--  where
--
--  * `original` is the original value in the table.
--
--  * `diff` is your updater object.
--
--  * `mutate` will be true if your updater is allowed to directly modify the
--    `original` value.
--
--  * `new` is what your updater will replace `original` with.
--
--  * `undo` can be any patch that can turn `new` back into `original`.
--
--  @tparam string name the name of the updater.
--  @tparam table mt the metatable each instance of the updater will share.
--  @tparam function update the update function.
function patch.register_updater(name, mt, update)
	if reserved[name] then
		error("Updater " .. tostring(name) .. " is a builtin.")
	end

	mt_set[mt]     = name
	updaters[name] = update
	return true
end

return patch
