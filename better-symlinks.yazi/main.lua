--- Shortens symlink paths from `/Users/you` to `~` when the path is under `$HOME`.
local HOME = os.getenv("HOME")

--- Replaces a leading `$HOME` path segment with `~`.
local function shorten(path)
	if not HOME or HOME == "" then return path end
	if path == HOME then return "~" end
	if path:sub(1, #HOME + 1) == HOME .. "/" then return "~" .. path:sub(#HOME + 1) end
	return path
end

---@diagnostic disable: undefined-global
local function setup()
	function Entity:symlink()
		if not rt.mgr.show_symlink then return "" end
		local to = self._file.link_to
		if not to then return "" end
		return ui.Span(string.format(" -> %s", shorten(tostring(to)))):style(th.mgr.symlink_target)
	end
end

return { setup = setup }
