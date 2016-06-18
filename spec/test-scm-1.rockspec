package = "test"
version = "scm-1"
source = {
   url = "file://"
}
description = {
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1",
   "busted",
   "luacheck",
   "luacov",
   "luacov-coveralls",
}
build = {
   type = "none"
}
