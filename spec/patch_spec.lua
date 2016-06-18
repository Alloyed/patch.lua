local patch = require 'patch'

describe("flat tables", function()
	test {
		old  = {foo = "bar"},
		diff = {foo = "baz"},
		new  = {foo = "baz"}
	}
	test {
		old  = {2, 4, 5},
		diff = {[2] = 'meme'},
		new  = {2, "meme", 5}
	}
end)

describe("new keys", function()
	test {
		old  = {oh   = "baby"},
		diff = {yeah = "okay"},
		new  = {oh = "baby", yeah = "okay"}
	}
end)

describe("nested tables", function()
	test {
		old  = {foo = { foo = "b", bar = "a"}},
		diff = {foo = { foo = "c" }},
		new  = {foo = { foo = "c", bar = "a"}}
	}
end)

describe("tables with patch.replace()", function()
	test {
		old  = {foo = { foo = "b", bar = "a"}},
		diff = {foo = patch.replace { foo = "c" }},
		new  = {foo = { foo = "c"}}
	}
end)

describe("tables with patch.Nil", function()
	test {
		old  = {foo = { foo = "b", bar = "a"}},
		diff = {foo = patch.Nil, bar = "hi"},
		new  = {bar = "hi"}
	}
end)

describe("tables with patch.update()", function()
	local function add(a, b)
		return a + b
	end
	test {
		old  = {foo = 6900},
		diff = {foo = patch.update(add, 42)},
		new  = {foo = 6942}
	}
end)

-- FIXME: This is probably surprising behavior.
describe("tables with shared references", function()
	local t = {chthulu ='bar'}
	test {
		old  = {foo = t, bar = t},
		diff = {foo = {foo = "c" }},
		new  = {foo = {foo = "c", chthulu = 'bar'}, bar = t}
	}
end)

describe("tables with cycles", function()
	local t = {chthulu ='bar'}
	t.woah = t
	test {
		old  = {foo = t, bar = t},
		diff = {foo = {foo = "c" }},
		new  = {foo = {foo = "c", chthulu = 'bar', woah = t}, bar = t}
	}
end)

function test(input)
	local util = require 'luassert.util'
	local _old, _new = util.deepcopy(input.old), util.deepcopy(input.new)
	local patched, undo = patch.apply(input.old, input.diff)
	local unpatched = patch.apply(input.new, undo)
	it("can be applied", function()
		assert.not_equal(_new, input.new)
		assert.same(_new, input.new)
		assert.not_equal(input.new, patched)
		assert.same(input.new, patched)
	end)
	it("can be undone", function()
		assert.not_equal(_old, input.old)
		assert.same(_old, input.old)
		assert.not_equal(input.old, unpatched)
		assert.same(input.old, unpatched)
	end)

	local T, T_undo
	it("can be applied inplace", function()
		T, T_undo = patch.apply_inplace(unpatched, input.diff)
		assert.not_equal(_new, input.new)
		assert.same(_new, input.new)
		assert.equal(unpatched, T)
		assert.same(input.new, T)
	end)
	it("can be undone inplace", function()
		T, T_undo = patch.apply_inplace(T, T_undo)
		assert.not_equal(_old, input.old)
		assert.same(_old, input.old)
		assert.equal(unpatched, T)
		assert.same(input.old, T)
	end)
end
