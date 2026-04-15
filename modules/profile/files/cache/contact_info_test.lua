-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Giuseppe Lavagetto, Wikimedia Foundation Inc.
local haproxy = {}

-- Constructs test transactions.
function test_txn(ua_string)
    return {
        f = {
            req_fhdr = function(self, what)
                return ua_string
            end,
        },
        req = {},
        set_var = function(self, name, value)
            self.req[string.sub(name, 5)] = value
        end,

    }
end

describe("HAProxy - set contact info", function()
    setup(function()
        -- Mock HAProxy core module.
        _G.core = {
            register_action = function(name, action, func)
                haproxy[name] = func
            end,
        }
        require "contact_info"
    end)

    it("should extract email address from UA string", function()
        local txn = test_txn("MyUserAgent/1.0 (email@example.com)")
        haproxy.set_contact_info(txn)
        assert.are.equal("email@example.com", txn.req.contact_info)
    end)

    it("should extract URL from UA string", function()
        local txn = test_txn("MyUserAgent/1.0 (https://example.com/path)")
        haproxy.set_contact_info(txn)
        assert.are.equal("https://example.com/path", txn.req.contact_info)
    end)

    it("should extract wiki username from UA string", function()
        local txn = test_txn("MyUserAgent/1.0 (wikit:tl-dr; User:WikiUser123)")
        haproxy.set_contact_info(txn)
        assert.are.equal("WikiUser123", txn.req.contact_info)
    end)
    it("should prioritize email over URL and wiki username", function()
        local txn = test_txn("MyUserAgent/1.0 (email@example.com; https://example.com/path); (wikit:tl-dr; User:WikiUser123)")
        haproxy.set_contact_info(txn)
        assert.are.equal("email@example.com", txn.req.contact_info)
    end)

    it("should prioritize URL over wiki username", function()
        local txn = test_txn("MyUserAgent/1.0 (https://example.com/path); (wikit:tl-dr; User:WikiUser123)")
        haproxy.set_contact_info(txn)
        assert.are.equal("https://example.com/path", txn.req.contact_info)
    end)

    it("should return nil if no contact info found", function()
        local txn = test_txn("MyUserAgent/1.0 (No contact info here)")
        haproxy.set_contact_info(txn)
        assert.are.equal(nil, txn.req.contact_info)
    end)

    it("should handle nil User-Agent", function()
        local txn = test_txn(nil)
        haproxy.set_contact_info(txn)
        assert.are.equal(nil, txn.req.contact_info)
    end)

    it("should match non-conventional email formats", function()
        local txn = test_txn("MyUserAgent/1.0 (user+label@example-test.com)")
        haproxy.set_contact_info(txn)
        assert.are.equal("user+label@example-test.com", txn.req.contact_info)
    end)

    it("should match urls with character encodings and spaces", function()
        local txn = test_txn("MyUserAgent/1.0 (https://example.com/path%20with%20spaces)")
        haproxy.set_contact_info(txn)
        assert.are.equal("https://example.com/path%20with%20spaces", txn.req.contact_info)
    end)

    it("should not set contact info for overly long User-Agent strings", function()
        local long_ua = string.rep("A", 600)
        local txn = test_txn(long_ua)
        haproxy.set_contact_info(txn)
        assert.are.equal(nil, txn.req.contact_info)
    end)

    it("should handle wiki usernames with parentheses and spaces", function()
        local txn = test_txn("MyUserAgent/1.0  (commons:commons; User:GLavagetto (WMF))")
        haproxy.set_contact_info(txn)
        assert.are.equal("GLavagetto (WMF)", txn.req.contact_info)
    end)

    it("should ignore patterns containing an @ that aren't email addresses", function()
        local txn = test_txn("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Mobile Safari/537.36 (Ecosia android@111.0.5563.116)")
        haproxy.set_contact_info(txn)
        assert.are.equal(nil, txn.req_contact_info)
    end)
end)
