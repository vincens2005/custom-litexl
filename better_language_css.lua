-- mod-version:2 -- lite-xl 2.0
local syntax = require "core.syntax"

syntax.add {
  files = { "%.css$" },
  patterns = {
    { pattern = "\\.",                type = "normal"   },
    { pattern = "//.-\n",             type = "comment"  },
    { pattern = { "/%*", "%*/" },     type = "comment"  },
    { pattern = { '"', '"', '\\' },   type = "string"   },
    { pattern = { "'", "'", '\\' },   type = "string"   },
    { regex = "(?<=:)[^;\\n]+(?=;)", type = "literal"},
    { regex = "\\d+[^;\\s(){}]*", type = "number"   },
    { pattern = "[{}:]",              type = "operator" },
    { pattern = "#%x%x%x%x%x%x%f[%W]",type = "string"   },
    { pattern = "#%x%x%x%f[%W]",      type = "string"   },
    { regex = "--[^():;{}\\n\\s]+", type = "literal"},
    { pattern = "[%a_][%w_]*%f[(]",     type = "function" },
    { pattern = "[%a_][%w_]*",        type = "symbol"   },
    { pattern = "@[%a][%w_-]*",       type = "keyword2" },
    { regex = "[^:\\n]+(?=:\\s*[^[;:\\]]+(?:|\\n|}|{))(?=.+;)", type = "keyword"  },
    { regex = "[^{\\n]+(?={)",       type = "keyword2" },-- fix this
  },
  symbols = {},
}
