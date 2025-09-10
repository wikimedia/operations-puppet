-- SPDX-License-Identifier: Apache-2.0

local haproxy = {}

-- Constructs test transactions.
function test_txn(ip_address)
    return {
        f = {
            src = function(self)
                return ip_address
            end,
        },
    }
end

describe("HAProxy - Maxmind database lookup functions", function()
    setup(function()
        -- Mock HAProxy core module.
        _G.core = {
            Alert = function(msg) end,

            Warning = function(msg) end,

            register_fetches = function(name, func)
                haproxy[name] = func
            end,

            register_action = function(name, func)
                haproxy[name] = func
            end,
        }

        -- Mock maxmind database functionality
        package.preload['maxminddb'] = function()
            return {
                open = function(filepath)
                    return {
                        lookup = function(database, ip_address)
                            return {
                                get = function(key, result)
                                    -- Test data goes here.
                                    if ip_address == "10.0.0.10" then
                                        return "Test ISP; inc"
                                    end
                                return ""
                                end
                            }
                        end
                    }, false
                end
            }
        end

        maxmind_lookup = require("maxmind-lookup")
    end)

    -- Test ISP functionality.
    describe("ISP Maxmind Lookup", function()
        it("Known ISP lookup - IPv4", function()
            local txn = test_txn("10.0.0.10")
            local isp = haproxy.fetch_isp(txn)
            assert.is.equal("isp=Test ISP, inc", isp)
        end)

        it("Unknown ISP lookup", function()
            local txn = test_txn("192.168.0.1")
            local isp = haproxy.fetch_isp(txn)
            assert.is.equal("", isp)
        end)
    end)
end)