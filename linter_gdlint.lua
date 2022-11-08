-- mod-version:3
-- this is for the gdlint linter (the version from https://github.com/Scony/godot-gdscript-toolkit)

local config = require "core.config"
local linter = require "plugins.linter"

-- if you want to specify any CLI arguments
config.gdlint_args = {}

local function warning_parse(text, filename)
  local line, col, warn
  for line_text in text:gmatch("[^\n]+") do
    -- nothing
  end
  return
end

linter.add_language {
  file_patterns = {"%.gd$"},
  warning_pattern = warning_parse,
  command = "gdlint $ARGS $FILENAME",
  args = config.gdlint_args,
  expected_exitcodes = {0, 1}
}
