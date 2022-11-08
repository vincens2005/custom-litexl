-- mod-version:3
local config = require "core.config"
local linter = require "plugins.linter"

config.flake8_args = {}

linter.add_language {
  file_patterns = {"%.py$"},
  warning_pattern = "[^:]:(%d+):(%d+):%s[%w]+%s([^\n]*)",
  command = "flake8 $ARGS $FILENAME --use-flake8-tabs",
  args = config.flake8_args,
  expected_exitcodes = {0, 1}
}
