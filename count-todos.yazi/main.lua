--- Stores todo count in plugin state, triggers a re-render. Runs on main
--- thread. A count of 0 clears the entry instead of storing it.
local add = ya.sync(function(state, path, count)
	if not state.counts then state.counts = {} end
	state.counts[path] = count > 0 and count or nil
	ui.render()
end)

--- Fetcher entry point. Counts todo occurences via `rg`, manipulates plugin
--- state via `add`. Returns `false` to indicate no further fetchers should run
--- for these files. Runs in async context (off the main thread).
local function fetch(_, job)
	for _, file in ipairs(job.files) do
		local path = tostring(file.url)
		-- `--hidden` searches hidden/dot files
		-- `-c` prints count of matches per file
		local output, _ = Command("rg"):arg({ "--hidden", "-c", "@todo", path }):output()
		local total = 0
		if output then
			for n in (output.stdout .. "\n"):gmatch("(%d+)\n") do
				total = total + tonumber(n)
			end
		end
		add(path, total)
	end
	return false
end

--- Setup entry point. Reads `sign`/`fg`/`order` from `~/.config/yazi/init.lua`.
--- Registers a Linemode child to render todo count next to each row (e.g.
--- `@42`, `@99+`, ` ` (blank), etc.).
local function setup(state, opts)
	state.counts = {}
	local order = (opts and opts.order) or 1400
	local t = th["count_todos"] or {}
	local sign = t.sign or (opts and opts.sign) or "@"
	local style = ui.Style():fg(t.fg or (opts and opts.fg) or "#FF8C00")

	Linemode:children_add(function(self)
		if not self._file.in_current then return "" end
		local count = state.counts[tostring(self._file.url)]
		if not count then return "" end
		local label = count > 99 and (sign .. "99+") or (sign .. count)
		return ui.Line { "  ", self._file.is_hovered and label or ui.Span(label):style(style) }
	end, order)
end

return {
	fetch = fetch,
	setup = setup,
}
