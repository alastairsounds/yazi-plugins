--- shell-peek.yazi: shell output notifier + logger
-- Usage: plugin shell-peek -- [--log] <cmd>
-- Example (scripted): "plugin shell-peek -- wc -l %h" (count lines in hovered file)
-- Example (interactive): "plugin shell-peek" (will prompt for command)
-- Example (persisted): "plugin shell-peek -- --log cargo test" (also appends the
-- result to ~/.local/state/yazi/shell-peek.log so it outlives the notify toast)

local LOG_PATH = (os.getenv("HOME") or "") .. "/.local/state/yazi/shell-peek.log"

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

	-- Escape `%%` to a sentinel byte first, so a literal `%%h` isn't corrupted by the
	-- `%h` substitution below matching just its trailing `%h` (leaving a stray `%`).
	local ESCAPE = "\1"
	cmd = cmd:gsub("%%%%", ESCAPE)

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

	-- restore escaped `%%` as a literal `%`
	cmd = cmd:gsub(ESCAPE, "%%")

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
	return (s:gsub("\27%[[%d;]*[A-Za-z]", ""):gsub("\27[()][AB012]", ""))
end

--- Open log file in append mode
local function open_log()
	local f = io.open(LOG_PATH, "a")
	if not f then
		os.execute("mkdir -p " .. ya.quote(LOG_PATH:match("(.*/)")))
		f = io.open(LOG_PATH, "a")
	end
	return f
end

local function entry(_, job)
	local args = job.args
	local cmd

	if #args == 0 then
		local value, event = ya.input({
			pos = { "top-center", y = 2, w = 50 },
			title = "Shell (peek):",
			history = "shared"
		})
		if event ~= 1 or not value or value == "" then return end
		cmd = value
	else
		cmd = table.concat(args, " ")
	end

	local hovered_path, hovered_dir, sel_paths, sel_dirs = get_context()
	cmd = resolve_wildcards(cmd, hovered_path, hovered_dir, sel_paths, sel_dirs)
	local shell_bin, shell_name = get_shell()

	local child, err = get_command(cmd, shell_bin, shell_name)
			:stdin(Command.NULL)
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:spawn()

	if err or not child then
		ya.err("[shell-peek] ERR: " .. tostring(err))
		ya.notify({ title = shell_name .. " (error) $ " .. cmd, content = tostring(err), timeout = 5, level = "error" })
		return
	end

	local log = args.log == true
	local log_file = log and open_log() or nil
	if log_file then
		log_file:write(("%s | %s\n"):format(os.date("!%Y-%m-%dT%H:%M:%SZ"), cmd))
		log_file:flush()
	end

	-- Perf check for this loop:
	-- - Run the command (plain) directly in a plain terminal
	--   - `for i in {1..30}; do printf "%s line %s\n" "$EPOCHREALTIME" "$i"; sleep 0.1; done`
	-- - Run the command (escaped) directly in shell-peek with --log while tailing the log file
	--   - `for i in {1..30}; do printf "%%s line %%s\n" "$EPOCHREALTIME" "$i"; sleep 0.1; done`
	-- The per-line timestamps (zsh's $EPOCHREALTIME, no forked process) should show
	-- the same ~100ms cadence in both.
	local out_buf, err_buf = {}, {}
	while true do
		local line, event = child:read_line()
		if event == 0 or event == 1 then
			local buf = event == 0 and out_buf or err_buf
			buf[#buf + 1] = line
			if log_file then
				log_file:write(strip_ansi(line))
				log_file:flush()
			end
		else
			break
		end
	end

	local status = child:wait()
	local code = (status and status.code) or "?"

	if log_file then
		log_file:write(("%s | exit %s\n"):format(os.date("!%Y-%m-%dT%H:%M:%SZ"), code))
		log_file:close()
	end

	local stdout_s, stderr_s = table.concat(out_buf), table.concat(err_buf)

	if not (status and status.success) then
		local content = stderr_s ~= "" and stderr_s or stdout_s
		content = content ~= "" and content or ("(command exited with code " .. code .. ")")
		content = strip_ansi(content)
		content = content:gsub("\n+$", "")
		ya.notify({ title = shell_name .. " $ " .. cmd, content = content, timeout = 5, level = "warn" })
		return
	end

	local content = stdout_s ~= "" and stdout_s or stderr_s
	content = strip_ansi(content ~= "" and content or "(no output)"):gsub("\n+$", "")
	ya.notify({ title = shell_name .. " $ " .. cmd, content = content, timeout = 5, level = "info" })
end

return { entry = entry }
