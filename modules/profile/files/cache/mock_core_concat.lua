-- SPDX-License-Identifier: Apache-2.0
-- Copyright (C) 2025 Chris Danis and Wikimedia Foundation
-- A pure-Lua implementation of HAProxy's core.concat() for unit tests.
-- Still much faster than using plain .. concatenation in a loop.

-- If a global `core` doesn't exist (outside HAProxy), create one.
local core = rawget(_G, "core") or {}

-- Concat "class"
local Concat = {}
Concat.__index = Concat

-- Optional: expose the class for white-box tests (core._Concat)
core._Concat = Concat

function Concat:new()
  return setmetatable({
    _chunks = {},
    _len = 0, -- running byte length of all added parts
  }, self)
end

--- Add a string-like value to the builder.
-- Returns self to allow chaining.
function Concat:add(s)
  if s == nil then
    -- Be permissive: nil is a no-op to simplify tests using optional parts.
    return self
  end
  if type(s) ~= "string" then
    -- Match HAProxy docs intent: treat input as string
    s = tostring(s)
  end
  self._chunks[#self._chunks + 1] = s
  self._len = self._len + #s
  return self
end

--- Return the concatenated string.
-- Also compacts internal storage to a single chunk so repeated dumps are cheap.
function Concat:dump()
  local n = #self._chunks
  if n == 0 then
    return ""
  elseif n == 1 then
    return self._chunks[1]
  else
    local out = table.concat(self._chunks)
    self._chunks = { out }
    self._len = #out
    return out
  end
end

--- Optional helpers useful in tests

-- Current length without forcing a recompute.
function Concat:len()
  return self._len
end

-- Allow tostring(c) to behave like c:dump()
function Concat:__tostring()
  return self:dump()
end

-- Public constructor matching HAProxy: core.concat() -> Concat instance
function core.concat()
  return Concat:new()
end

-- Export `core` for `require`-based tests; also put it back on _G if we created it.
if not rawget(_G, "core") then
  rawset(_G, "core", core)
end

return core
