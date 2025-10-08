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

    describe("ASCII input", function()
        it("pure ascii string", function()
            local input = "curl/7.88.1"
            local expected = "curl/7.88.1"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("empty string", function()
            local input = ""
            local expected = ""
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("ascii with spaces and punctuation", function()
            local input = "Hello, World! 123"
            local expected = "Hello, World! 123"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Valid UTF-8 input", function()
        it("utf8 latin characters", function()
            local input = "gutiérrez"
            local expected = "gutiérrez"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("utf8 mixed languages", function()
            local input = "Café résumé naïve"
            local expected = "Café résumé naïve"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("utf8 cyrillic", function()
            local input = "Привет мир"
            local expected = "Привет мир"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("utf8 chinese", function()
            local input = "你好世界"
            local expected = "你好世界"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("utf8 japanese", function()
            local input = "こんにちは"
            local expected = "こんにちは"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("utf8 arabic", function()
            local input = "مرحبا"
            local expected = "مرحبا"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("utf8 emoji (non-printable extended)", function()
            local input = "😊"
            local expected = "\\U0001f60a"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("utf8 multiple emojis", function()
            local input = "Hello 😊🎉"
            local expected = "Hello \\U0001f60a\\U0001f389"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("ISO-8859-1/15 (invalid UTF-8) input", function()
        it("iso-8859-15 single character", function()
            local input = "foo\xa1"
            local expected = "foo\\u00a1"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("iso-8859-15 é character", function()
            local input = "guti\xe9rrez"
            local expected = "guti\\u00e9rrez"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("iso-8859-15 multiple characters", function()
            local input = "caf\xe9 r\xe9sum\xe9"
            local expected = "caf\\u00e9 r\\u00e9sum\\u00e9"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("iso-8859-15 ñ character", function()
            local input = "ma\xf1ana"
            local expected = "ma\\u00f1ana"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("iso-8859-15 euro sign", function()
            local input = "Price: \xa4100"  -- € in ISO-8859-15
            local expected = "Price: \\u00a4100"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Control characters", function()
        it("null byte", function()
            local input = "foo\x00bar"
            local expected = "foo\\u0000bar"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("tab character", function()
            local input = "foo\tbar"
            local expected = "foo\\u0009bar"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("newline character", function()
            local input = "foo\nbar"
            local expected = "foo\\u000abar"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("carriage return", function()
            local input = "foo\rbar"
            local expected = "foo\\u000dbar"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("bell character", function()
            local input = "foo\x07bar"
            local expected = "foo\\u0007bar"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("escape character", function()
            local input = "foo\x1bbar"
            local expected = "foo\\u001bbar"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Mixed valid and invalid UTF-8", function()
        it("ascii followed by invalid byte", function()
            local input = "test\xff"
            local expected = "test\\u00ff"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("valid utf8 followed by invalid byte", function()
            local input = "café\xff"
            local expected = "café\\u00ff"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("invalid byte followed by valid utf8", function()
            local input = "\xffcafé"
            local expected = "\\u00ffcafé"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("ascii, invalid, valid utf8", function()
            local input = "test\xe9café"
            local expected = "test\\u00e9café"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("multiple invalid bytes scattered", function()
            local input = "a\xffb\xfec\xfdd"
            local expected = "a\\u00ffb\\u00fec\\u00fdd"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Truncated UTF-8 sequences", function()
        it("truncated 2-byte sequence", function()
            local input = "test\xc3"  -- Should be \xc3\xa9 for é
            local expected = "test\\u00c3"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("truncated 3-byte sequence", function()
            local input = "test\xe2\x82"  -- Should be \xe2\x82\xac for €
            local expected = "test\\u00e2\\u0082"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("truncated 4-byte sequence", function()
            local input = "test\xf0\x9f\x98"  -- Should be \xf0\x9f\x98\x8a for 😊
            local expected = "test\\u00f0\\u009f\\u0098"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Invalid UTF-8 continuation bytes", function()
        it("invalid continuation in 2-byte sequence", function()
            local input = "test\xc3\x00"  -- Second byte should be 0x80-0xBF
            local expected = "test\\u00c3\\u0000"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("invalid continuation in 3-byte sequence", function()
            local input = "test\xe2\x82\x00"  -- Third byte should be 0x80-0xBF
            local expected = "test\\u00e2\\u0082\\u0000"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("orphaned continuation byte", function()
            local input = "test\x80"  -- 0x80 is a continuation byte, not a start
            local expected = "test\\u0080"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Edge cases with printable range", function()
        it("character at 0xa0 boundary (non-breaking space)", function()
            local input = "test\xc2\xa0end"  -- Valid UTF-8 non-breaking space
            local expected = "test\xc2\xa0end"  -- Should be kept as-is (printable range)
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("character at 0xd7ff boundary", function()
            local input = "test\xed\x9f\xbfend"  -- U+D7FF (valid, at boundary)
            local expected = "test\xed\x9f\xbfend"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("character at 0xe000 boundary", function()
            local input = "test\xee\x80\x80end"  -- U+E000 (private use)
            local expected = "test\xee\x80\x80end"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Real-world User-Agent strings", function()
        it("common browser user agent", function()
            local input = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            local expected = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("user agent with iso-8859-1 characters", function()
            local input = "MyBot/1.0 (caf\xe9)"
            local expected = "MyBot/1.0 (caf\\u00e9)"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("user agent with utf-8 characters", function()
            local input = "MyBot/1.0 (café)"
            local expected = "MyBot/1.0 (café)"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Boundary values", function()
        it("all ascii printable characters (32-126)", function()
            local input = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
            local expected = input
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("byte 0x7F (DEL control character)", function()
            local input = "test\x7f"
            local expected = "test\\u007f"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("byte 0x1F (last control character)", function()
            local input = "test\x1f"
            local expected = "test\\u001f"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("byte 0x20 (first printable ascii)", function()
            local input = "test\x20end"
            local expected = "test end"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)

    describe("Long strings", function()
        it("long valid utf-8 string", function()
            local input = string.rep("café ", 100)
            local expected = input
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)

        it("long string with scattered invalid bytes", function()
            local input = "test" .. string.rep("\xe9", 50) .. "end"
            local expected = "test" .. string.rep("\\u00e9", 50) .. "end"
            local result = haproxy.utf8ps(input)
            assert.is.equal(expected, result)
        end)
    end)
end)
