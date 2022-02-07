-- mod-version:2
local syntax = require "core.syntax"

syntax.add {
  files = { "%.xml$" },
  headers = "<%?xml",
  patterns = {
    { pattern = { "<!%-%-", "%-%->" },     type = "comment"  },
    { pattern = { '%f[^>][^<]', '%f[<]' }, type = "normal"   },
    { pattern = { '"', '"', '\\' },        type = "string"   },
    { pattern = { "'", "'", '\\' },        type = "string"   },
    { pattern = "0x[%da-fA-F]+",           type = "number"   },
    { pattern = "-?%d+[%d%.]*f?",          type = "number"   },
    { pattern = "-?%.?%d+f?",              type = "number"   },
    { pattern = "%f[^<]![%a_][%w_]*",      type = "literal" },
    { pattern = "%f[^<][%a_][%w_]*",       type = "keyword" },
    { pattern = "%f[^<]/[%a_][%w_]*",      type = "keyword" },
    { pattern = "[%a_][%w_]*",             type = "literal"  },
    { pattern = "[/<>=]",                  type = "operator" },
  },
  symbols = {},
}
