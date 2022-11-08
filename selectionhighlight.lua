-- mod-version:3 lite-xl 2.1
local style = require "core.style"
local DocView = require "core.docview"

-- originally written by luveti

-- Workaround for bug in Lite XL 2.1
-- Remove this when b029f5993edb7dee5ccd2ba55faac1ec22e24609 is in a release
local function get_selection(doc, sort)
  local line1, col1, line2, col2 = doc:get_selection_idx(doc.last_selection)
  if line1 then
    return doc:get_selection_idx(doc.last_selection, sort)
  else
    return doc:get_selection_idx(1, sort)
  end
end

local draw_line_body = DocView.draw_line_body

function DocView:draw_line_body(line, x, y)
  local line1, col1, line2, col2 = get_selection(self.doc, true)
  if line1 == line2 and col1 ~= col2 then
    local selection = self.doc:get_text(line1, col1, line2, col2)
    if not selection:match("^%s+$") then
      local lh = self:get_line_height()
      local selected_text = self.doc.lines[line1]:sub(col1, col2 - 1)
      local current_line_text = self.doc.lines[line]
      local last_col = 1
      while true do
        local start_col, end_col = current_line_text:find(
          selected_text, last_col, true
        )
        if start_col == nil then break end
        -- don't draw box around the selection
        if line ~= line1 or start_col ~= col1 then
          local x1 = x + self:get_col_x_offset(line, start_col)
          local x2 = x + self:get_col_x_offset(line, end_col + 1)
          local color = style.selectionhighlight or style.syntax.comment
          renderer.draw_rect(x1, y, x2 - x1, lh, color)
        end
        last_col = end_col + 1
      end
    end
  end
  return draw_line_body(self, line, x, y)
end

