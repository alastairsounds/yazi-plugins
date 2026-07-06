local get_context = ya.sync(function(_)
	local hovered = cx.active.current.hovered
	local hovered_url = hovered and hovered.url or nil
	local hovered_path = hovered_url and tostring(hovered_url) or ""
	local hovered_dir = (hovered_url and hovered_url.parent) and tostring(hovered_url.parent) or ""

	local selected = cx.active.selected
	local sel_paths, sel_dirs = {}, {}
	if selected and #selected > 0 then
		for _, file in pairs(selected) do
			sel_paths[#sel_paths + 1] = tostring(file.url)
			sel_dirs[#sel_dirs + 1] = file.url.parent and tostring(file.url.parent) or ""
		end
	end
	---@diagnostic disable-next-line: redundant-return-value
	return hovered_path, hovered_dir, sel_paths, sel_dirs
end)

--- Resolves yazi keymap-style placeholders in a shell command string.
---
--- Supported patterns:
--- - `%h`  / `%H`  hovered path
--- - `%s`  / `%S`  all selected paths (falls back to hovered)
--- - `%sN` / `%SN` Nth selected path (1-indexed)
--- - `%d`  / `%D`  dirs of all selected (falls back to hovered dir)
--- - `%dN` / `%DN` dir of Nth selected (1-indexed)
--- - `%%`          literal `%`
--- - `%0`          hovered path (deprecated; mirrors yazi keymap removal)
local function resolve_wildcards(cmd, hovered_path, hovered_dir, sel_paths, sel_dirs)
	-- Note: yazi's splatter.rs does not pass down to lua. Manually resolving here.

	-- Indexed patterns first to avoid accidental replacement in unindexed patterns.
	-- %sN / %SN: Nth selected path (1-indexed)
	cmd = cmd:gsub("%%[sS](%d+)", function(n)
		local path = sel_paths[tonumber(n)] or ""
		return path ~= "" and ya.quote(path) or ""
	end)

	-- %dN / %DN: dirname of Nth selected path (1-indexed)
	cmd = cmd:gsub("%%[dD](%d+)", function(n)
		local path = sel_dirs[tonumber(n)] or ""
		return path ~= "" and ya.quote(path) or ""
	end)

	-- %h / %H: hovered path
	cmd = cmd:gsub("%%[hH]", ya.quote(hovered_path))

	-- %s / %S: all selected paths (falls back to hovered if none selected)
	local function quoted_list(list, fallback)
		if #list > 0 then
			local quoted = {}
			for _, path in ipairs(list) do quoted[#quoted + 1] = ya.quote(path) end
			return table.concat(quoted, " ")
		end
		return ya.quote(fallback)
	end
	cmd = cmd:gsub("%%[sS]", quoted_list(sel_paths, hovered_path))

	-- %d / %D: dirnames of all selected (falls back to hovered dir)
	cmd = cmd:gsub("%%[dD]", quoted_list(sel_dirs, hovered_dir))

	-- %0: hovered path [deprecated in yazi keymap; will be removed eventually]
	cmd = cmd:gsub("%%0", ya.quote(hovered_path))

	-- %%: literal % (must be last)
	cmd = cmd:gsub("%%%%", "%%")

	return cmd
end

--- Detects login shell. Enables aliases and functions in bash/zsh.
local function get_shell()
	local shell_bin = os.getenv("SHELL") or "/bin/sh"
	local shell_name = (shell_bin:match("([^/]+)$") or "sh"):lower()
	return shell_bin, shell_name
end

--- Builds a command to execute in a shell, optionally using `setsid` to avoid job control issues.
local function get_command(cmd, shell_bin, shell_name)
	local setsid_file = io.open("/usr/bin/setsid") or io.open("/bin/setsid")
	if setsid_file then setsid_file:close() end
	local setsid = setsid_file ~= nil

	local flags = {
		-- bash and zsh have tty flags in non-setsid contexts
		["bash"] = setsid and { "-ic" } or { "--noediting", "+m", "-ic" },
		["zsh"]  = setsid and { "-ic" } or { "-o", "NO_MONITOR", "-o", "NO_ZLE", "-ic" },
	}
	local shell_flags = flags[shell_name] or { "-c" } -- fish/sh/unknown all run non-interactively

	local args = { table.unpack(shell_flags) }
	table.insert(args, cmd)

	local cmd_wrapped = setsid and Command("setsid"):arg({ "--wait", shell_bin }) or Command(shell_bin)
	return cmd_wrapped:arg(args)
end

--- Strip ANSI escape sequences from a string
local function strip_ansi(s)
	return s:gsub("\27%[[%d;]*[A-Za-z]", ""):gsub("\27[()][AB012]", "")
end

local function entry(_, job)
	local cmd
	if #job.args == 0 then
		local value, event = ya.input({
			pos = { "top-center", y = 2, w = 50 },
			title = "Shell (peek):",
			history = "shared"
		})
		if event ~= 1 or not value or value == "" then return end
		cmd = value
	else
		cmd = table.concat(job.args, " ")
	end

	local hovered_path, hovered_dir, sel_paths, sel_dirs = get_context()
	cmd = resolve_wildcards(cmd, hovered_path, hovered_dir, sel_paths, sel_dirs)
	local shell_bin, shell_name = get_shell()

	local output, err = get_command(cmd, shell_bin, shell_name)
			:stdin(Command.NULL)
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()

	if err then
		ya.err("[shell-peek] ERR: " .. tostring(err))
		ya.notify({ title = shell_name .. " (error) $ " .. cmd, content = tostring(err), timeout = 5, level = "error" })
		return
	end

	if not output.status.success then
		local code = output.status.code or "?"
		local content = output.stderr ~= "" and output.stderr or output.stdout
		content = content ~= "" and content or ("(command exited with code " .. code .. ")")
		content = strip_ansi(content)
		content = content:gsub("\n+$", "")
		ya.notify({ title = shell_name .. " $ " .. cmd, content = content, timeout = 5, level = "warn" })
		return
	end

	local content = output.stdout ~= "" and output.stdout or output.stderr
	content = strip_ansi(content ~= "" and content or "(no output)"):gsub("\n+$", "")
	ya.notify({ title = shell_name .. " $ " .. cmd, content = content, timeout = 5, level = "info" })
end

return { entry = entry }
