local function entry(_, job)
	local cmd
	if #job.args == 0 then
		local value, event = ya.input({
			pos = { "top-center", y = 2, w = 50 },
			title = "Shell (peek):",
		})
		if event ~= 1 or not value or value == "" then return end
		cmd = value
	else
		cmd = table.concat(job.args, " ")
	end

	local output, err = Command("sh")
			:arg({ "-c", cmd })
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()

	if err then
		ya.err("[shell-peek] ERR: " .. tostring(err))
		ya.notify({ title = "sh (error) $ " .. cmd, content = tostring(err), timeout = 5, level = "error" })
		return
	end

	local result = output.stdout ~= "" and output.stdout or output.stderr
	result = result ~= "" and result or "(no output)"
	result = result:gsub("\n+$", "")
	ya.notify({ title = "sh $ " .. cmd, content = result, timeout = 5, level = "info" })
end

return { entry = entry }
