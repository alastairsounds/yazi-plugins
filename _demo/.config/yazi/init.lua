require("better-symlinks"):setup()

require("count-todos"):setup({
  order = 400,
  git_only = true,
  skip_gitignored_files = true, -- skip dist/, *.generated.js, etc.
  skip_gitignored_folders = true, -- skip dist/, *.generated.js, etc.
})

-- Custom linemode display
function Linemode:size_and_mtime()
  local time = math.floor(self._file.cha.mtime or 0)
  if time == 0 then
    time = ""
  elseif os.date("%Y", time) == os.date("%Y") then
    time = os.date("%m/%d %H:%M", time)
  else
    time = os.date("%m/%d  %Y", time)
  end
  local size = self._file:size()
  return string.format("%s", time)
end
