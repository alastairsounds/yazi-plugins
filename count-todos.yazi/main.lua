--- Stores todo count in plugin state, triggers a re-render. Runs on main
--- thread. A count of 0 clears the entry instead of storing it.
local add = ya.sync(function(state, path, count)
	if not state.counts then state.counts = {} end
	state.counts[path] = count > 0 and count or nil
	ui.render()
end)

local get_opts = ya.sync(function(state)
	return state.git_only, state.skip_gitignored_dirs, state.skip_gitignored_files
end)

local function in_git_repo(dir)
	local out = Command("git"):arg({ "-C", dir, "rev-parse", "--show-toplevel" }):output()
	return out ~= nil and out.status.success
end

--- Fetcher entry point. Counts todo occurences via `rg`, manipulates plugin
--- state via `add`. Returns `false` to indicate no further fetchers should run
--- for these files. Runs in async context (off the main thread).
local function fetch(_, job)
	local git_only, skip_gitignored_dirs, skip_gitignored_files = get_opts()
	if git_only and #job.files > 0 then
		local first = tostring(job.files[1].url)
		local parent = first:match("^(.*)/[^/]*$") or first
		if not in_git_repo(parent) then return false end --* return early if not in a git repo
	end

	local paths_files, paths_dirs = {}, {}
	for _, file in ipairs(job.files) do
		local path = tostring(file.url)
		if path:match("[/\\]%.git$") then
			-- skip
		elseif file.cha.is_dir then
			paths_dirs[#paths_dirs + 1] = path
		else
			paths_files[#paths_files + 1] = path
		end
	end

	-- one git check-ignore call covering whichever sets need filtering
	local ignored, to_check = {}, {}
	if skip_gitignored_files then
		for _, p in ipairs(paths_files) do to_check[#to_check + 1] = p end
	end
	if skip_gitignored_dirs then
		for _, p in ipairs(paths_dirs) do to_check[#to_check + 1] = p end
	end
	if #to_check > 0 then
		-- git check-ignore requires a parent directory to be passed, so use the
		-- first path's parent (or "." if no parent) as the working directory.
		local parent = to_check[1]:match("^(.*)/[^/]*$") or "."
		local git_ignore_result = Command("git"):arg({ "-C", parent, "check-ignore", "--" }):arg(to_check):output()
		if git_ignore_result and git_ignore_result.status.success then
			for line in git_ignore_result.stdout:gmatch("[^\n]+") do ignored[line] = true end
		end
	end

	local paths_rg = {}
	for _, p in ipairs(paths_files) do
		if not ignored[p] then paths_rg[#paths_rg + 1] = p end
	end
	for _, p in ipairs(paths_dirs) do
		if not ignored[p] then paths_rg[#paths_rg + 1] = p end
	end
	paths_files = paths_rg

	if #paths_files == 0 then return false end --* return early if no files to search

	local rg_args = {
		"--hidden",                                                      -- searches hidden/dot files
		"-c",                                                            -- prints count of matches per file
		"--with-filename",                                               -- ensures path:count format even for a single file
		"--no-heading",                                                  -- suppresses file name headers in output
		"--iglob", "!*.{png,jpg,gif,pdf,zip,lock,svg,woff,woff2,ttf,eot}", -- excludes binary files and common non-text file types
		"--iglob", "!.git",                                              -- excludes .git directories
		"@todo"
	}
	local output = Command("rg"):arg(rg_args):arg(paths_files):output()
	-- to log: local t0 = ya.time(); ... ya.err(string.format("count-todos: rg %.3f s, %d file(s)", ya.time() - t0, #paths)) -- ~/.local/state/yazi/yazi.log
	local counts = {}
	if output then
		for line in output.stdout:gmatch("[^\n]+") do
			local path, n = line:match("^(.*):(%d+)$")
			if path then counts[path] = tonumber(n) end
		end
	end

	for _, file in ipairs(job.files) do
		local path = tostring(file.url)
		if file.cha.is_dir then
			local total = 0
			for k, v in pairs(counts) do
				if k:sub(1, #path + 1) == path .. "/" then total = total + v end
			end
			add(path, total)
		else
			add(path, counts[path] or 0)
		end
	end
	return false
end

--- Setup entry point. Reads `sign`/`fg`/`order` from `~/.config/yazi/init.lua`.
--- Registers a Linemode child to render todo count next to each row (e.g.
--- `@42`, `@99+`, ` ` (blank), etc.).
local function setup(state, opts)
	state.counts = {}
	state.git_only = opts and opts.git_only or false
	state.skip_gitignored_dirs = opts == nil or opts.skip_gitignored_dirs ~= false
	state.skip_gitignored_files = opts ~= nil and opts.skip_gitignored_files == true
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
