-- mod-version:2 lite-xl 1.16
local core = require "core"
local common = require "core.common"
local style = require "core.style"
local command = require "core.command"
local keymap = require "core.keymap"
local DocView = require "core.docview"

local bracket_maps = {
	-- [     ]    (     )    {      }
	{[91] = 93, [40] = 41, [123] = 125, step = 1},
	-- ]     [    )     (    }      {
 {[93] = 91, [41] = 40, [125] = 123, step = -1}
}

local function get_matching_bracket(doc, line, col, line_limit, open_byte,
                                    close_byte, step)
	if line == nil then return end
	local end_line = line + line_limit * step
	local depth = 0

	while line ~= end_line do
		local byte = doc.lines[line]:byte(col)
		if byte == open_byte then
			depth = depth + 1
		elseif byte == close_byte then
			depth = depth - 1
			if depth == 0 then return line, col end
		end

		local prev_line, prev_col = line, col
		line, col = doc:position_offset(line, col, step)
		if line == prev_line and col == prev_col then break end
	end
end

local state = {}

local function update_state(line_limit)
	line_limit = line_limit or math.huge

	-- reset if we don't have a document (eg. DocView isn't focused)
	local doc = core.active_view.doc
	if not doc then
		state = {}
		return
	end

	-- early exit if nothing has changed since the last call
	local line, col = doc:get_selection()
	local change_id = doc:get_change_id()
	if state.doc == doc and state.line == line and state.col == col and
					state.change_id == change_id and state.limit == line_limit then return end

	-- find matching bracket if we're on a bracket
	local line2, col2, line1, col1
	for _, map in ipairs(bracket_maps) do
		for i = 0, -1, -1 do
			local line, col = doc:position_offset(line, col, i)
			local open = doc.lines[line]:byte(col)
			local close = map[open]
			if close then
				line2, col2 = get_matching_bracket(doc, line, col, line_limit, open, close,
				                                   map.step)
				line1, col1 = get_matching_bracket(doc, line2, col2, line_limit, close,
				                                   open, map.step * -1)
				goto found
			end
		end
	end
	::found::

	-- update
	state = {
		change_id = change_id,
		doc = doc,
		line = line,
		col = col,
		line1 = line1,
		col1 = col1,
		line2 = line2,
		col2 = col2,
		limit = line_limit
	}
end

local update = DocView.update

function DocView:update(...)
	update(self, ...)
	update_state(100)
end

local function draw_match(x1, x2, y, h, height, color)
	if x1 == nil or x2 == nil then return end
	renderer.draw_rect(x1, y - h, x2 - x1, h, color) -- top
	renderer.draw_rect(x2 - h, y - h, h, height, color) -- right
	renderer.draw_rect(x1, y + height - h, x2 - x1, h, color) -- bottom
	renderer.draw_rect(x1, y - h, h, height, color) -- left
end

local draw_line_text = DocView.draw_line_text

local function draw_same_line_match(dv, x, h, lh, color)
    local _, y = dv:get_line_screen_position(state.line1)
    local x1, x2 = x + dv:get_col_x_offset(state.line1, state.col1), x+ dv:get_col_x_offset(state.line1, state.col1 + 1)
    draw_match(x1, x2, y, h, lh, color)
end

function DocView:draw_line_text(idx, x, y)
	draw_line_text(self, idx, x, y)
	local color = style.bracketmatch_color or {common.color "#b9b9b9"}
	local h = 1 * SCALE
	local lh = self:get_line_height()
	if self.doc == state.doc and idx == state.line2 then
		local x1, x2
		if state.line1 == state.line2 and math.abs(state.col1 - state.col2) == 1 then
			-- draw a box around both brackets, rather than the individual ones
			if state.col1 > state.col2 then
				x1 = x + self:get_col_x_offset(idx, state.col2)
				x2 = x + self:get_col_x_offset(idx, state.col1 + 1)
			else
				x1 = x + self:get_col_x_offset(idx, state.col1)
				x2 = x + self:get_col_x_offset(idx, state.col2 + 1)
			end
		else
			if state.line1 == state.line2 then draw_same_line_match(self, x, h, lh, color) end
			x1 = x + self:get_col_x_offset(idx, state.col2)
			x2 = x + self:get_col_x_offset(idx, state.col2 + 1)
		end
		draw_match(x1, x2, y, h, lh, color)
	elseif self.doc == state.doc and idx == state.line1 then
		draw_same_line_match(self, x, h, lh, color)
	end
end

command.add("core.docview", {
	["bracket-match:move-to-matching"] = function()
		update_state()
		if state.line2 then
			core.active_view.doc:set_selection(state.line2, state.col2)
		end
	end
})

keymap.add {["ctrl+m"] = "bracket-match:move-to-matching"}
