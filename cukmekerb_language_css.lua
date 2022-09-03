-- mod-version:2
local syntax = require "core.syntax"

syntax.add {
  files = { "%.css$", "%.rasi$", "%.less$"},
  patterns = {
    { pattern = "\\.",                type = "selector" },
    { pattern = "//.-\n",             type = "comment"  },
    { pattern = { "/%*", "%*/" },     type = "comment"  },
    { pattern = { '"', '"', '\\' },   type = "string"   },
    { pattern = { "'", "'", '\\' },   type = "string"   },
    { pattern = "[%a][%w-]*%s*%f[:]", type = "literal"  },
    { pattern = "[(]*[%-][%-][%g]+[)]*%s*",type = "literal"},
    { pattern = "#%x+",               type = "string"   },
    { pattern = "-?%d+[%d%.]*p[xt]",  type = "number"   },
    { pattern = "-?%d+[%d%.]*deg",    type = "number"   },
    { pattern = "-?%d+[%d%.]*",       type = "number"   },
    { pattern = "[%a_][%w_]*",        type = "string"   },
    { pattern = "#[%a][%w_-]*",       type = "selector" },
    { pattern = "@[%a][%w_-]*",       type = "selector" },
    { pattern = "%.[%a][%w_-]*",      type = "selector" },
    { pattern = "[{}:]",              type = "operator" },
  },
  symbols = {},
}
