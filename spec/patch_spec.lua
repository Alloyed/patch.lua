local patch = require 'patch'
local test

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
		old  = {foo = {foo = "b", bar = "a"}},
		diff = {foo = {foo = "c"}},
		new  = {foo = {foo = "c", bar = "a"}}
	}
end)

describe("empty tables", function()
	test {
		old  = {},
		diff = {v = {}},
		new  = {v = {}}
	}

	test {
		old  = {v = "hi"},
		diff = {v = {}},
		new  = {v = {}}
	}

	test {
		old  = {v = {"my", "fancy", "table"}},
		diff = {v = {}},
		new  = {v = {"my", "fancy", "table"}},
	}
end)

describe("no-ops", function()
	test {
		old  = {},
		diff = patch.noop,
		new  = {}
	}

	test {
		old  = {},
		diff = {v = patch.noop},
		new  = {}
	}
end)

describe("tables with patch.replace()", function()
	test {
		old  = {foo = {foo = "b", bar = "a"}},
		diff = {foo = patch.replace {foo = "c"}},
		new  = {foo = {foo = "c"}}
	}
end)

describe("tables with patch.Nil", function()
	test {
		old  = {foo = {foo = "b", bar = "a"}},
		diff = {foo = patch.Nil, bar = "hi"},
		new  = {bar = "hi"}
	}
end)

describe("tables with custom updaters", function()
	local function add(orig, diff, mutate)
		return orig + diff.num, orig
	end
	local mt = {}
	patch.register_updater("add", mt, add)
	test {
		old  = {foo = 6900},
		diff = {foo = setmetatable({num=42}, mt)},
		new  = {foo = 6942}
	}
end)

describe("tables with table.insert_i()", function()
	test {
		old  = {1, 2, 3, 4},
		diff = patch.insert_i(2, "foo"),
		new  = {1, "foo", 2, 3, 4}
	}

	test {
		old  = {1, 2, 3, 4},
		diff = patch.insert_i("foo"),
		new  = {1, 2, 3, 4, "foo"}
	}
end)

describe("tables with patch.remove_i()", function()
	test {
		old  = {1, 2, 3, 4},
		diff = patch.remove_i(2),
		new  = {1, 3, 4}
	}
	test {
		old  = {1, 2, 3, 4},
		diff = patch.remove_i(),
		new  = {1, 2, 3}
	}
end)

-- FIXME: This is probably surprising behavior.
describe("tables with shared references", function()
	local t = {chthulu ='bar'}
	test {
		old  = {foo = t, bar = t},
		diff = {foo = {foo = "c"}},
		new  = {foo = {foo = "c", chthulu = 'bar'}, bar = t}
	}
end)

describe("tables with cycles", function()
	local t = {chthulu ='bar'}
	t.woah = t
	test {
		old  = {foo = t, bar = t},
		diff = {foo = {foo = "c"}},
		new  = {foo = {foo = "c", chthulu = 'bar', woah = t}, bar = t}
	}
end)

describe("tables with patch.meta()", function()
	local o_mt = {"old"}
	local n_mt = {"new"}
	test {
		old  = setmetatable({}, o_mt),
		diff = patch.meta(n_mt),
		new  = setmetatable({}, n_mt)
	}
end)

describe("tables with patch.chain() #atm", function()
	local o_mt = {"old"}
	local n_mt = {"new"}
	test {
		old  = setmetatable({}, o_mt),
		diff = patch.chain({a=1}, patch.meta(n_mt)),
		new  = setmetatable({a=1}, n_mt)
	}

	--test {
	--	old  = {a=1},
	--	diff = patch.chain({a=2}, {a=3}),
	--	new  = {a=3}
	--}

	test {
		old  = {a=1},
		diff = patch.chain({a=2, b = 1}, {a=3}),
		new  = {a=3, b = 1}
	}

	test {
		old  = {a=1},
		diff = patch.chain(nil, {a=3}),
		new  = {a=3}
	}

	test {
		old  = {a=1},
		diff = patch.chain({a=1, c = 2}, patch.chain({a=2, b = 1}, {a=3})),
		new  = {a=3, b = 1, c = 2}
	}
end)

describe("tables that promote nil -> {}", function()
	test {
		old  = {foo = nil},
		diff = {foo = {a = "table"}},
		new  = {foo = {a = "table"}}
	}
	test {
		old  = {foo = nil},
		diff = {foo = {a = patch.replace("replaced")}},
		new  = {foo = {a = "replaced"}}
	}
	test {
		old  = {bar = nil},
		diff = {bar = {}},
		new  = {bar = {}}
	}
	test {
		old  = {foo = nil},
		diff = {foo = {a = patch.Nil}},
		new  = {foo = {}}
	}
end)

describe("patch.join()", function()
	it("can join a patch with nothing", function()
		assert.same({my="patch"}, patch.join(nil, {my="patch"}))
		assert.same({my="patch"}, patch.join({my="patch"}, nil))
		assert.same({my="patch"}, patch.join(nil, {my="patch"}, nil))
	end)
	local function call(f, ...)
		local a = {n = select('#', ...), ...}
		return function()
			return f(unpack(a, 1, a.n))
		end
	end
	it("will error for non-merges", function()
		assert.has_errors(call(patch.join, 1, 2))
		assert.has_errors(call(patch.join, {}, 2))
		assert.has_errors(call(patch.join, patch.Nil, 2))
		assert.has_errors(call(patch.join, patch.Nil, patch.Nil))
		assert.has_errors(call(patch.join, nil, 1, 1))
	end)
	it("can join two merge-tables", function()
		assert.same({a="b", c="d"}, patch.join({a="b"}, {c="d"}))
		assert.same({a="b", c=patch.Nil}, patch.join({a="b"}, {c=patch.Nil}))
		assert.same({a="b", c=patch.replace(2)}, patch.join({a="b"}, {c=patch.replace(2)}))
	end)
	it("will error if the non-merge happens inside another merge", function()
		assert.has_errors(call(patch.join, {a="2"}, {a="3"}))
		assert.has_errors(call(patch.join, {a="2"}, {a="2"})) -- TODO do we want this?
		assert.has_errors(call(patch.join, {b=2}, {b=patch.Nil}))
		assert.has_errors(call(patch.join, {{b=2}}, {{b=patch.Nil}}))
	end)
	it("can do nested joins", function()
		assert.same({
			{a = "b"},
			{c = patch.Nil, d = "e"}
		}, patch.join({{a="b"}}, {[2]={c=patch.Nil, d="e"}}))
	end)
	it("can join more than two patches at a time", function()
		assert.same({
			{a = "b", d = "e"},
			{c = patch.Nil}
		}, patch.join({{a="b"}}, {[2]={c=patch.Nil}},{{d="e"}}))
	end)
end)

describe("patch.diff", function()
	local input = {}

	input.old = {}
	for i=1, 20 do
		input.old[math.random()] = tostring(math.random())
	end

	input.new = {}
	input.new[patch.Nil] = patch.replace("obj")
	for i=1, 20 do
		input.new[math.random()] = tostring(math.random())
	end
	input.new[patch.Nil] = patch.Nil
	
	input.diff = patch.diff(input.old, input.new)
	input.is_diff = true

	test(input)
end)

function test(input)
	local d = input.is_diff and " (diffed)" or ""
	local util = require 'luassert.util'
	local _old, _new = util.deepcopy(input.old), util.deepcopy(input.new)
	local patched, undo = patch.apply(input.old, input.diff)
	local unpatched = patch.apply(input.new, undo)
	it("can be applied"..d, function()
		assert.not_equal(_new, input.new)
		assert.same(_new, input.new)
		assert.not_equal(input.new, patched)
		assert.same(input.new, patched)
	end)
	it("can be undone"..d, function()
		assert.not_equal(_old, input.old)
		assert.same(_old, input.old)
		assert.not_equal(input.old, unpatched)
		assert.same(input.old, unpatched)
	end)

	local T, T_undo
	it("can be applied inplace"..d, function()
		T, T_undo = patch.apply_inplace(unpatched, input.diff)
		assert.not_equal(_new, input.new)
		assert.same(_new, input.new)
		assert.equal(unpatched, T)
		assert.same(input.new, T)
	end)
	it("can be undone inplace"..d, function()
		T, T_undo = patch.apply_inplace(T, T_undo)
		assert.not_equal(_old, input.old)
		assert.same(_old, input.old)
		assert.equal(unpatched, T)
		assert.same(input.old, T)
	end)

	local function is_tbl(o) return type(o) == 'table' end
	if input.is_diff == nil and is_tbl(input.old) and is_tbl(input.new) then
		local diff = patch.diff(input.old, input.new)
		test {
			old     = input.old,
			new     = input.new,
			diff    = diff,
			is_diff = true
		}
	end
end
