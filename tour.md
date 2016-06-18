## Tour
	patch = require 'patch'
The core verb of patch is `patch.apply`. As the name suggests, it
applies a patch to an existing value, and spits out the result:
	-- Replace the input (1) with the new value (2)
	value = 1
	value, undo = patch.apply(value, 2) -- replace value with 2

	print(value) -- 2
Patches are normal Lua values. Here we used the number 2, but we can
update a value to whatever we want.
	value, undo2 = patch.apply(value, "magic")    --       2 -> "magic"
	value, undo3 = patch.apply(value, {"carpet"}) -- "magic" -> {"carpet"}
Every time you call apply, in addition to the the result value, it will
also spit out an "undo" patch. This will be an inverse of the input
patch: if you give the current value and the undo back to
apply it will give you the original value.
	value, _ = patch.apply(value, undo3) -- {"carpet"} -> "magic"
	value, _ = patch.apply(value, undo2) --    "magic" -> 2
	value, _ = patch.apply(value, undo)  --          2 -> 1
Patch supports more complex operations than simple replacement, though.
When the patch is a table, then each value in the patch table is
recursively applied to the input, like so:
	t = { a = 1, 'a', 'b', 'c'}
	t2, _ = patch.apply(t,  {[2] = 2})           -- t2[2]    = 2
	t3, _ = patch.apply(t2, {a = {age = "old"}}) -- t3.a     = {age = "old"}
	t4, _ = patch.apply(t3, {a = {age = "new"}}) -- t4.a.age = "new"
When working with complex types like this, apply makes the
guarantee that it won't modify the input table:
	print(t == t4)   -- false
	print(t.a)       -- b
	print(t2.a)      -- 2
	print(t3[2].age) -- old
But if you'd rather reuse a single instance of a datastructure, you can
use `patch.apply_inplace` instead.
	t5, _ = patch.apply_inplace(t4, {a = 3}) -- t4.a = 3

	print(t4 == t5)     -- true
	print(t4.a == t5.a) -- true
These two primitive behaviors, replacing and merging, work for many of
changes you might want to make to a table. However, this can't represent
everything. For example, if you want to set a field in a table to nil,
this won't work:
	patch.apply({field = "set"}, {field = nil}) -- {field = "set"}, nil
That's because in Lua, `nil` is the same as `undefined`. instead of
passing in a field set to `nil`, we've passed in nothing at all!

To fix this we use @{patch.Updaters|Updaters}. An updater is a simple marker that suggests
that patch should do something special when applying it. For this
specific example, we can use the `patch.Nil` updater, which will always
replace the input with nil:
	patch.apply({field = "set"}, {field = patch.Nil} -- {}, {field = "set"}

