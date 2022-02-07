-- mod-version:2 -- lite-xl 2.0
-- Support for the GDScript programming language: https://godotengine.org/
-- Covers the most used keywords up to Godot version 3.2.x

local syntax = require "core.syntax"

syntax.add {
  files = { "%.gd$" },
  comment = "#",
  patterns = {
    { pattern = "#.-\n",                    type = "comment"  },
    { pattern = { '"', '"', '\\' },         type = "string"   },
    { pattern = { "'", "'", '\\' },         type = "string"   },
    { pattern = "-?0x%x*",                  type = "number"   },
    { pattern = "-?%d+[%d%.e]*",            type = "number"   },
    { pattern = "-?%.?%d+",                 type = "number"   },
    { pattern = "[%+%:%-=/%*%^%%<>!~|&]",   type = "operator" },
    { pattern = "[%a_][%w_]*%f[(]",         type = "function" },
    { pattern = "[A-Z][%w_]*",              type = "class" },
    { pattern = "[%a_][%w_]*",              type = "symbol"   },
  },
  symbols = {
    -- keywords
    ["if"]               = "keyword",
    ["elif"]             = "keyword",
    ["else"]             = "keyword",
    ["for"]              = "keyword",
    ["while"]            = "keyword",
    ["match"]            = "keyword",
    ["break"]            = "keyword",
    ["continue"]         = "keyword",
    ["pass"]             = "keyword",
    ["return"]           = "keyword",
    ["class"]            = "keyword",
    ["class_name"]       = "keyword",
    ["extends"]          = "keyword",
    ["is"]               = "keyword",
    ["in"]               = "keyword",
    ["as"]               = "keyword",
    ["and"]              = "keyword",
    ["or"]               = "keyword",
    ["not"]              = "keyword",
    ["self"]             = "keyword",
    ["tool"]             = "keyword",
    ["signal"]           = "keyword",
    ["func"]             = "keyword",
    ["static"]           = "keyword",
    ["const"]            = "keyword",
    ["enum"]             = "keyword",
    ["var"]              = "keyword",
    ["onready"]          = "keyword",
    ["export"]           = "keyword",
    ["setget"]           = "keyword",
    ["breakpoint"]       = "keyword",
    ["preload"]          = "keyword",
    ["yield"]            = "keyword",
    ["assert"]           = "keyword",
    ["remote"]           = "keyword",
    ["master"]           = "keyword",
    ["puppet"]           = "keyword",
    ["remotesync"]       = "keyword",
    ["mastersync"]       = "keyword",
    ["puppetsync"]       = "keyword",
    -- types
    ["void"]             = "keyword2",
    ["int"]              = "keyword2",
    ["float"]            = "keyword2",
    ["bool"]             = "keyword2",
    ["String"]           = "keyword2",
    ["Vector2"]          = "keyword2",
    ["Rect2"]            = "keyword2",
    ["Vector3"]          = "keyword2",
    ["Transform2D"]      = "keyword2",
    ["Plane"]            = "keyword2",
    ["Quat"]             = "keyword2",
    ["AABB"]             = "keyword2",
    ["Basis"]            = "keyword2",
    ["Transform"]        = "keyword2",
    ["Color"]            = "keyword2",
    ["NodePath"]         = "keyword2",
    ["RID"]              = "keyword2",
    ["Object"]           = "keyword2",
    ["Array"]            = "keyword2",
    ["PoolByteArray"]    = "keyword2",
    ["PoolIntArray"]     = "keyword2",
    ["PoolRealArray"]    = "keyword2",
    ["PoolStringArray"]  = "keyword2",
    ["PoolVector2Array"] = "keyword2",
    ["PoolVector3Array"] = "keyword2",
    ["PoolColorArray"]   = "keyword2",
    ["Dictionary"]       = "keyword2",
    -- literals
    ["null"]             = "literal",
    ["true"]             = "literal",
    ["false"]            = "literal",
    ["PI"]               = "literal",
    ["TAU"]              = "literal",
    ["INF"]              = "literal",
    ["NAN"]              = "literal",
  },
}
