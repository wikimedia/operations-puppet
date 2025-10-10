-- SPDX-License-Identifier: Apache-2.0

local core = require("mock_core_concat")

describe("HAProxy core.concat()", function()
  it("builds empty strings", function()
    local c = core.concat()
    assert.are.equal("", c:dump())
    assert.are.equal("", c:dump()) -- idempotent
  end)

  it("builds single strings", function()
    local c = core.concat()
    c:add("hello")
    assert.are.equal("hello", c:dump())
    assert.are.equal("hello", c:dump()) -- idempotent
  end)

  it("builds multiple strings", function()
    local c = core.concat()
    c:add("hello")
    c:add(", ")
    c:add("world")
    assert.are.equal("hello, world", c:dump())
    assert.are.equal("hello, world", c:dump()) -- idempotent
    c:add("!")
    assert.are.equal("hello, world!", c:dump())
    assert.are.equal("hello, world!", c:dump()) -- idempotent
  end)

  it("handles nil and non-string inputs", function()
    local c = core.concat()
    c:add(nil) -- no-op
    c:add(123)
    c:add(true)
    c:add("!")
    assert.are.equal("123true!", c:dump())
  end)

  it("reports length correctly", function()
    local c = core.concat()
    assert.are.equal(0, c:len())
    c:add("abc")
    assert.are.equal(3, c:len())
    c:add("defg")
    assert.are.equal(7, c:len())
    assert.are.equal("abcdefg", c:dump()) -- compacts
    assert.are.equal(7, c:len())
    c:add("hi")
    assert.are.equal(9, c:len())
  end)
end)