-- SPDX-License-Identifier: Apache-2.0
-- Copyright (C) 2025 Chris Danis and Wikimedia Foundation

-- Benchmarks for mock_core_concat.lua

-- On my machine:
-- Results for Lua 5.3.6:
--   core.concat()   0.327s  (6111741.0 ops/sec)
--   plain ..        40.380s  (49529.1 ops/sec)
-- Results for luajit 2.1.1737090214:
--   core.concat()   0.028s  (72608458.9 ops/sec)
--   plain ..        276.238s  (7240.1 ops/sec)

local core = require("mock_core_concat")

local clock = os.clock
local N_OUTER = 10
local N_INNER = 200000
local TOKEN = "#####"

local function bench(label, fn)
  local t0 = clock()
  fn()
  local t1 = clock()
  local dt = t1 - t0
  print(string.format("%-15s %.3fs  (%.1f ops/sec)",
    label, dt, (N_OUTER * N_INNER) / dt))
end

bench("core.concat()", function()
  for j = 1, N_OUTER do
    local c = core.concat()
    for i = 1, N_INNER do
      c:add(TOKEN)
    end
    local _ = c:dump()
  end
end)

bench("plain ..", function()
  for j = 1, N_OUTER do
    local s = ""
    for i = 1, N_INNER do
      s = s .. TOKEN
    end
  end
end)
