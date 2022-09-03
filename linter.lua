-- mod-version:3
local core = require "core"
local style = require "core.style"
local common = require "core.common"
local command = require "core.command"
local config = require "core.config"
local DocView = require "core.docview"
local StatusView = require "core.statusview"
local Doc = require "core.doc"

config.linter_box_line_limit = 80
config.linter_scan_interval = 0.1 -- scan every 100 ms

style.lint = {
  info = style.syntax["keyword2"],
  hint = style.syntax["function"],
  warning = nil,
  error = style.linter_error or { common.color "#FF3333" }
}

core.add_thread(function()
	style.lint.warning = style.lint.warning or style.linter_warning or style.syntax["function"]
end)

local current_doc = nil
local cache = setmetatable({}, { __mode = "k" })
local hover_boxes = setmetatable({}, { __mode = "k" })
local linter_queue = {}
local linters = {}

local function split(str, sep)
	local t = {}
	for s in str:gmatch("([^"..sep.."]+)") do
		table.insert(t, s)
	end
	return t
end

local function completed(proc)
  local current_time = os.time()
  local diff = os.difftime(proc.start, current_time)
  if diff > proc.timeout then
    proc.callback(nil, "Timeout reached")
    return true
  end

  if not proc.doc.ref then -- if the doc is destroyed, delete the item too
    proc.callback(nil, "Weak reference destroyed")
    return true
  end

  if not proc.proc:running() then
    local output = proc.proc:read_stdout() or ""
    local exitcode = proc.proc:returncode()
    proc.callback({ output = output, exitcode = exitcode })
    return true
  end
  return false
end

local function lint_completion_thread()
  while true do
    coroutine.yield(config.linter_scan_interval)

    local j, n = 1, #linter_queue
    for i = 1, n, 1 do
      if not completed(linter_queue[i]) then
        -- move i to j since we want to keep it
        if i ~= j then
          linter_queue[j] = linter_queue[i]
          linter_queue[i] = nil
        end
        j = j + 1
      else
        -- remove i
        linter_queue[i] = nil
      end
    end
  end
end
core.add_thread(lint_completion_thread)

local function async_run_lint_cmd(doc, path, linter, callback, timeout)
  timeout = timeout or 500
  local cmd = linter.command:gsub("$FILENAME", path)
  local args = table.concat(linter.args or {}, " ")
  cmd = cmd:gsub("$ARGS", args)
  local cmd_table = split(cmd, "(.-)%s")
  local proc = process.start(cmd_table, {timeout = timeout})

  table.insert(linter_queue, {
    proc = proc,
    timeout = timeout,
    callback = callback,
    start = os.time(),
    doc = setmetatable({ ref = doc }, { __mode = 'v' })
  })
end

local function match_pattern(text, pattern, order, filename)
  if type(pattern) == "function" then
    return coroutine.wrap(function()
      pattern(text, filename)
    end)
  end

  if order == nil then
    return text:gmatch(pattern)
  end

  return coroutine.wrap(function()
    for one, two, three in text:gmatch(pattern) do
      local fields = {one, two, three}
      local ordered = {line = 1, col = 1, message = "syntax error"}
      for field,position in pairs(order) do
        ordered[field] = fields[position] or ordered[field]
        if
          field == "line"
          and current_doc ~= nil
          and tonumber(ordered[field]) > #current_doc.lines
        then
          ordered[field] = #current_doc.lines
        end
      end
      coroutine.yield(ordered.line, ordered.col, ordered.message)
    end
  end)
end


local function is_duplicate(line_warns, col, warn)
  for _, w in ipairs(line_warns) do
    if w.col == col and w.text == warn then
      return true
    end
  end
  return false
end

-- Escape string so it can be used in a lua pattern
local to_escape = {
  ["%"] = true,
  ["("] = true,
  [")"] = true,
  ["."] = true,
  ["+"] = true,
  ["-"] = true,
  ["*"] = true,
  ["["] = true,
  ["]"] = true,
  ["?"] = true,
  ["^"] = true,
  ["$"] = true
}
local function escape_to_pattern(text, count)
  count = count or 1
  local escaped = {}
  for char in text:gmatch(".") do
    if to_escape[char] then
      for _=1,count do
        table.insert(escaped, "%")
      end
    end
    table.insert(escaped, char)
  end
  return table.concat(escaped, "")
end

local function async_get_file_warnings(doc, warnings, linter, callback)
  local path = system.absolute_path(doc.filename)
  local double_escaped = escape_to_pattern(path, 2)
  local pattern = linter.warning_pattern
  if type(pattern) == "string" then
    pattern = pattern:gsub("$FILENAME", double_escaped)
  end

  local function on_linter_completion(data, error)
    if data == nil then
      return callback(nil, error)
    end

    local text = data.output or ""
    if linter.expected_exitcodes then
      local valid_code = false
      for _, exitcode in ipairs(linter.expected_exitcodes) do
        if data.exitcode == exitcode then
          valid_code = true
        end
      end

      if not valid_code then
        return callback(nil, text)
      end
    end

    local order = linter.warning_pattern_order
    for line, col, warn in match_pattern(text, pattern, order, path) do
      line = tonumber(line)
      col = tonumber(col)
      if linter.column_starts_at_zero then
        col = col + 1
      end
      if not warnings[line] then
        warnings[line] = {}
      end

      local deduplicate = linter.deduplicate or false
      local exists = deduplicate and is_duplicate(warnings[line], col, warn)
      if not exists then
        table.insert(warnings[line], {col=col, text=warn})
      end
    end
    callback(true)
  end

  async_run_lint_cmd(doc, path, linter, on_linter_completion)
end

local function matches_any(filename, patterns)
  for _, ptn in ipairs(patterns) do
    if filename:find(ptn) then return true end
  end
end


local function matching_linters(filename)
  local matched = {}
  for _, l in ipairs(linters) do
    if matches_any(filename, l.file_patterns) then
      table.insert(matched, l)
    end
  end
  return matched
end


local function update_cache(doc)
  local lints = matching_linters(doc.filename or "")
  if not lints[1] then return end

  local d = {}
  for _, l in ipairs(lints) do
    local linter_name = l.command:match("%S+")
    core.log("Linting %s with %s...", doc.filename, linter_name)
    async_get_file_warnings(doc, d, l, function(success, error)
      if not success then
        core.log("Error linting %s with linter %s: %s", doc.filename, linter_name, error)
        print(error)
        return
      end

      local i = 0
      for idx, t in pairs(d) do
        t.line_text = doc.lines[idx] or ""
        i = i + 1
      end
      cache[doc] = d
      core.log("Done linting %s, found %d warning(s).", doc.filename, i)
    end)
  end
end


local function get_word_limits(v, line_text, x, col)
  if col == 0 then col = 1 end
  local _, e = line_text:sub(col):find(config.symbol_pattern)
  if not e or e <= 0 then e = 1 end
  e = e + col - 1

  local font = v:get_font()
  local x1 = x + font:get_width(line_text:sub(1, col - 1))
  local x2 = x + font:get_width(line_text:sub(1, e))
  return x1, x2
end


local clean = Doc.clean
function Doc:clean(...)
  current_doc = self
  clean(self, ...)
  update_cache(self)
end

local new = Doc.new
function Doc:new(...)
  current_doc = self
  new(self, ...)
  update_cache(self)
end


local on_mouse_wheel = DocView.on_mouse_wheel
function DocView:on_mouse_wheel(...)
  on_mouse_wheel(self, ...)
  hover_boxes[self] = nil
end


local on_mouse_moved = DocView.on_mouse_moved
function DocView:on_mouse_moved(px, py, ...)
  on_mouse_moved(self, px, py, ...)

  local doc = self.doc
  local cached = cache[doc]
  if not cached then return end

  -- Check mouse is over this view
  local x, y, w, h = self.position.x, self.position.y, self.size.x, self.size.y
  if px < x or px > x + w or py < y or py > y + h then
    hover_boxes[self] = nil
    return
  end

  -- Detect if any warning is hovered
  local hovered = {}
  local hovered_w = {}
  for line, warnings in pairs(cached) do
    local text = doc.lines[line]
    if text == warnings.line_text then
      for _, warning in ipairs(warnings) do
        local x, y = self:get_line_screen_position(line)
        local x1, x2 = get_word_limits(self, text, x, warning.col)
        local h = self:get_line_height()
        if px > x1 and px <= x2 and py > y and py <= y + h then
          table.insert(hovered_w, warning.text)
          hovered.x = px
          hovered.y = y + h
        end
      end
    end
  end
  hovered.warnings = hovered_w
  hover_boxes[self] = hovered.warnings[1] and hovered
end


local draw_line_text = DocView.draw_line_text
function DocView:draw_line_text(idx, x, y)
  draw_line_text(self, idx, x, y)

  local doc = self.doc
  local cached = cache[doc]
  if not cached then return end

  local line_warnings = cached[idx]
  if not line_warnings then return end

  -- Don't draw underlines if line text has changed
  if line_warnings.line_text ~= doc.lines[idx] then
    return
  end

  -- Draws lines in linted places
  local text = doc.lines[idx]
  for _, warning in ipairs(line_warnings) do
    local x1, x2 = get_word_limits(self, text, x, warning.col)
    local color = style.lint[warning.type] or style.lint.warning or style.syntax.literal
    local h = style.divider_size
    local line_h = self:get_line_height()
    renderer.draw_rect(x1, y + line_h - h, x2 - x1, h, color)
  end
end


local function text_in_lines(text, max_len)
  local text_lines = {}
  local line = ""
  for word, seps in text:gmatch("([%S]+)([%c%s]*)") do
    if #line + #word > max_len then
      table.insert(text_lines, line)
      line = ""
    end
    line=line..word
    for sep in seps:gmatch(".") do
      if sep == "\n" then
        table.insert(text_lines, line)
        line = ""
      else
        line=line..sep
      end
    end
  end
  if #line > 0 then
    table.insert(text_lines, line)
  end
  return text_lines
end


local function draw_warning_box(hovered_item)
  local font = style.font
  local th = font:get_height()
  local pad = style.padding

  local max_len = config.linter_box_line_limit
  local full_text = table.concat(hovered_item.warnings, "\n\n")
  local lines = text_in_lines(full_text, max_len)

  -- draw background rect
  local rx = hovered_item.x - pad.x
  local ry = hovered_item.y
  local text_width = 0
  for _, line in ipairs(lines) do
    local w = font:get_width(line)
    text_width = math.max(text_width, w)
  end
  local rw = text_width + pad.x * 2
  local rh = (th * #lines) + pad.y * 2
  renderer.draw_rect(rx, ry, rw, rh, style.background3)

  -- draw text
  local color = style.text
  local x = rx + pad.x
  for i, line in ipairs(lines) do
    local y = ry + pad.y + th * (i - 1)
    renderer.draw_text(font, line, x, y, color)
  end
end


local draw = DocView.draw
function DocView:draw()
  draw(self)
  if hover_boxes[self] then
    core.root_view:defer_draw(draw_warning_box, hover_boxes[self])
  end
end


local get_items = StatusView.get_items
function StatusView:get_items()
  local left, right  = get_items(self)

  local doc = core.active_view.doc
  local cached = cache[doc or ""]
  if cached then
    local count = 0
    for _, v in pairs(cached) do
      count = count + #v
    end
    table.insert(left, StatusView.separator)
    if not doc:is_dirty() and count > 0 then
      table.insert(left, style.text)
    else
      table.insert(left, style.dim)
    end
    table.insert(left, "warnings: " .. count)
  end

  return left, right
end


local function has_cached()
  return core.active_view.doc and cache[core.active_view.doc]
end

local function doc_from_name(name)
	for _,d in pairs(core.docs) do
		if name == d.filename or name == d.abs_filename then return d end
	end
	return nil
end

local function add_message(filename, line, column, kind, message, rail)
	local doc = doc_from_name(filename)
	if doc == nil then
		core.log_quiet("linter: could not add message. Doc "..filename.."not found")
		return
	end
	local warning = {
		col = column,
		type = kind,
		text = message,
	}
	cache[doc] = cache[doc] or {}
	cache[doc][line] = cache[doc][line] or {
		line_text = doc.lines[line] or ""
	}
	table.insert(cache[doc][line], warning)
end

command.add(has_cached, {
  ["linter:move-to-next-warning"] = function()
    local doc = core.active_view.doc
    local line = doc:get_selection()
    local cached = cache[doc]
    local idx, min = math.huge, math.huge
    for k in pairs(cached) do
      if type(k) == "number" then
        min = math.min(k, min)
        if k < idx and k > line then idx = k end
      end
    end
    idx = (idx == math.huge) and min or idx
    if idx == math.huge then
      core.error("Document does not contain any warnings")
      return
    end
    if cached[idx] then
      doc:set_selection(idx, cached[idx][1].col)
      core.active_view:scroll_to_line(idx, true)
    end
  end,
})

local function clear_messages(filename)
	local doc = doc_from_name(filename)
	if doc == nil then
		core.log_quiet("linter: could not clear warnings. Doc "..filename.."not found")
		return
	end
	cache[doc] = {}
end

return {
  add_language = function(lang)
    table.insert(linters, lang)
  end,
  escape_to_pattern = escape_to_pattern,
  add_message = add_message,
  messages = {},
  clear_messages = clear_messages,
  init_doc = function (a, b) return end
}
