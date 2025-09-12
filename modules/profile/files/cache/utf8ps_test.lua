-- SPDX-License-Identifier: Apache-2.0

local haproxy = {}

describe("HAProxy - utf8ps converter", function()
    setup(function()
        -- Mock HAProxy core module.
        _G.core = {
            register_converters = function(name, func)
                haproxy[name] = func
            end,
        }
        require "utf8ps"

    end)

    describe("Test utf8ps converter", function()
        it("pure ascii input", function()
            local input = "curl/7.88.1"
            local expected = "curl/7.88.1"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
        it("utf8 input", function()
            local input = "gutiérrez"
            local expected = "gutiérrez"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
        it("utf8 extended input", function()
            local input = "😊"
            local expected = "\\U0001f60a"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
        it("iso-8559-15 input", function()
            local input = "guti\xe9rrez"
            local expected = "guti\\u00e9rrez"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)
end)
