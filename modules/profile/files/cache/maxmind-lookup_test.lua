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
        set_var = function(self, name, value)
            self[string.sub(name, 5)] = value
        end,

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

            register_action = function(name, action, func)
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
                                    if ip_address == "10.0.2.20" then
                                        return "Very Big Datacenter Corp."
                                    end
                                    if ip_address == "10.0.2.21" then
                                        return "HYDROLAB_PROXY"
                                    end
                                return nil
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

    -- Test datacenter functionality.
    describe("Datacenter Spur.US lookup", function()
        it("Known datacenter lookup - IPv4", function()
            local txn = test_txn("10.0.2.20")
            haproxy.is_datacenter(txn)
            assert.is_true(txn.is_datacenter)
        end)
        it("Not a datacenter lookup - IPv4", function()
            local txn = test_txn("10.0.3.30")
            haproxy.is_datacenter(txn)
            assert.is_nil(txn.is_datacenter)
        end)
    end)

    -- Test proxy lookup functionality.
    describe("Proxy Spur.US lookup", function()
        it("Known proxy lookup - IPv4", function()
            local txn = test_txn("10.0.2.21")
            haproxy.res_proxy(txn)
            assert.is_equal(txn.res_proxy, "proxy=hydrolab")
        end)
        it("Not a proxy lookup - IPv4", function()
            local txn = test_txn("10.0.3.30")
            haproxy.res_proxy(txn)
            assert.is_nil(txn.res_proxy)
        end)
    end)


end)
