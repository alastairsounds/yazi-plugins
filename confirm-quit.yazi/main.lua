local count = ya.sync(function() return #cx.tabs end)

local function entry()
	if count() < 2 then
		return ya.emit("quit", {})
	end

	local yes = ya.confirm {
		pos = { "center", w = 40, h = 9 },
		title = "Quit?",
		content = "\nMultiple tabs open.\n\nAre you sure you want to quit?"
	}
	if yes then
		ya.emit("quit", {})
	end
end

return { entry = entry }

--[[
╭────────────────Quit?─────────────────╮
│                                      │
│          Multiple tabs open.         │
│                                      │
│    Are you sure you want to quit?    │
│                                      │
│──────────────────────────────────────│
│       [Y]es               (N)o       │
╰──────────────────────────────────────╯
]]
