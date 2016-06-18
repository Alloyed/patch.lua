project="patch.lua"
title="Patch.lua"
description="A library for diffing/patching lua tables"
format="markdown"
file={"patch.lua"}
readme="tour.md"
dir="doc"
sort_modules=true
use_markdown_titles=true
backtick_references=true
no_space_before_args=true
custom_display_name_handler=function(item, default_handler)
	local p = default_handler(item)
	if item.kind == "modules" or item.kind == "topics" then
		return p
	else
		return "patch."..p
	end
end
