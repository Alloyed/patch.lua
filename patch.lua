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

local replace_mt = {}
local update_mt  = {}

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
      return diff.v, orig
   elseif getmetatable(diff) == update_mt then
      return diff.fn(orig, unpack(diff.args, 1, diff.n)), orig
   elseif type(diff) == 'table' then
      return merge(orig, diff, mutate)
   else
      return diff, orig
   end
end

--- The "nil" updater. When you want to set a field to nil, use this instead of
--  nil directly.
patch.Nil = {}

--- Returns a "replace" updater. This forces patch() to replace the field with
--  the given value. This can be used for anything, including `nil` and other.
--  updaters.
--  @param v the new value
function patch.replace(v)
   return setmetatable({v = v}, replace_mt)
end

--- Returns a custom updater. Takes a function that, given an old value,
--  returns an a new, updated value.
--  @param fn the updater function
--  @param ... extra arguments to pass to fn
function patch.update(fn, ...)
   return setmetatable({fn = fn, n = select('#', ...), args = {...}}, update_mt)
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
