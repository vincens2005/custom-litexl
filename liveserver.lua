-- mod-version:3
local core = require "core"
local config = require "core.config"
local command = require "core.command"
-- configs
config.liveserver_port = 5500
config.liveserver_usebrowser = true
config.liveserver_browser = nil -- use default browser
config.liveserver_cssinject = true
config.liveserver_wait = 100 -- wait in miliseconds before reloading

local server = nil

local function start_server()
	if server ~= nil then
		return core.log("server is already running")
	end

  local cmd = {"live-server", "-q"}
  if not config.liveserver_browser == nil then
    table.insert(cmd, "--browser=" .. config.liveserver_browser)
  end
  if not config.liveserver_usebrowser then
    table.insert(cmd, "--no-browser")
  end
  if not config.liveserver_cssinject then
    table.insert(cmd, "--no-css-inject")
  end
  table.insert(cmd,  "--port=" .. config.liveserver_port)
	table.insert(cmd,  "--wait=" .. config.liveserver_wait)
  server = process.start(cmd)
end

local function stop_server()
	if server == nil then return core.log("no server is running") end
	server:kill()
	server = nil
end

local quit = core.quit
function core.quit(force)
	stop_server()
	return quit(force)
end

command.add(nil, {
  ["live-server:start-server"] = start_server
})

command.add(nil, {
  ["live-server:stop-server"] = stop_server
})
