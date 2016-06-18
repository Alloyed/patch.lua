# patch.lua

Patch.lua is a DSL for expressing complex changes to Lua tables as
discrete patches. Every time a patch is applied, an inverse undo patch
is created, which means patch.lua can be used to easily add multi-level
undo to an application.

## Installing

Patch.lua can be installed using luarocks:

```
$ luarocks install patch
```

To get the most recent source checkout:

```
$ luarocks install https://raw.githubusercontent.com/Alloyed/patch.lua/master/patch-scm-1.rockspec
```

## Docs

[API docs][api] and a [guided tutorial][tour] exist. For more complex
examples, you can check out the [unit tests][test].

[api]: https://alloyed.github.io/patch.lua/
[tour]: https://alloyed.github.io/patch.lua/topics/tour.md.html
[test]: https://github.com/Alloyed/patch.lua/blob/master/spec/patch_spec.lua

## Testing

Patch.lua uses busted for testing:

```
# luarocks install busted
$ busted
```

## LICENSE

Copyright (c) 2016, Kyle McLamb <alloyed@tfwno.gf> under the MIT License

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
