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

---
patch.Nil = {}

---
-- @param v
function patch.replace(v)
   return setmetatable({v = v}, replace_mt)
end

--- Custom updater. Takes a function that, given an original value, returns an
--  update/transformed value.
function patch.update(fn, ...)
   return setmetatable({fn = fn, n = select('#', ...), args = {...}}, update_mt)
end

---
--  @param orig
--  @param diff
function patch.apply(orig, diff)
   return visit(orig, diff, false)
end

---
--  @param orig
--  @param diff
function patch.apply_inplace(orig, diff)
   return visit(orig, diff, true)
end

return patch
