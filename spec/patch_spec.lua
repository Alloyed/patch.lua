local patch = require 'patch'

local function test(input)
   local patched, undo = patch.apply(input.old, input.diff)
   local unpatched = patch.apply(input.new, undo)
   it("apply", function()
      assert.same(input.new, patched)
   end)
   it("undo", function()
      assert.same(input.old, unpatched)
   end)
end

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
