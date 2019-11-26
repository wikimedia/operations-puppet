require("default")

_G.ts = {
  http = {},
  ctx = {},
  server_response = { header = {} },
  server_request = { header = {} },
  client_response = { header = {} },
  client_request = { header = {} },
}

_G.TS_LUA_CACHE_LOOKUP_MISS = 0
_G.TS_LUA_CACHE_LOOKUP_HIT_FRESH = 1

_G.ts.client_request.get_uri = function() return "/" end
_G.read_config = function() return 'pass-test-hostname' end
_G.ts.server_response.get_status = function() return 200 end

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()
    stub(ts, "debug")
    stub(ts, "hook")

    it("test - do_global_read_response Set-Cookie", function()

      -- Without Set-Cookie
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      do_global_read_response()
      assert.are.equals('public, max-age=10', _G.ts.server_response.header['Cache-Control'])

      -- With Set-Cookie
      _G.ts.server_response.header['Set-Cookie'] = 'banana potato na'
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      do_global_read_response()
      assert.is_nil(_G.ts.server_response.header['Cache-Control'])
    end)

    it("test - do_global_read_response cacheable Cookie", function()
      _G.ts.server_response.header = {}
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie does not contain Session / Token
      _G.ts.client_request.header['Cookie'] = 'WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      do_global_read_response()
      assert.are.equals('public, max-age=10', _G.ts.server_response.header['Cache-Control'])
    end)

    it("test - do_global_read_response uncacheable Cookie but no Vary", function()
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie contains Session / Token but there is no Vary
      _G.ts.client_request.header['Cookie'] = 'centralauth_Token=BANANA; WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      do_global_read_response()
      assert.are.equals('public, max-age=10', _G.ts.server_response.header['Cache-Control'])
    end)

    it("test - do_global_read_response uncacheable Cookie and not Vary:Cookie", function()
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie contains Session / Token and the response is NOT Vary:Cookie
      _G.ts.server_response.header['Vary'] = 'Accept-Encoding,Authorization'
      _G.ts.client_request.header['Cookie'] = 'centralauth_Token=BANANA; WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      do_global_read_response()
      assert.are.equals('public, max-age=10', _G.ts.server_response.header['Cache-Control'])
    end)

    it("test - do_global_read_response uncacheable Cookie and Vary:Cookie", function()
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie contains Session / Token and the response is Vary:Cookie
      _G.ts.server_response.header['Vary'] = 'Accept-Encoding,Cookie,Authorization'
      _G.ts.client_request.header['Cookie'] = 'centralauth_Token=BANANA; WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      do_global_read_response()
      assert.is_nil(_G.ts.server_response.header['Cache-Control'])
    end)

    it("test - do_global_read_response large Content-Length", function()
      -- No Content-Length
      _G.ts.server_response.header = {}
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      do_global_read_response()
      assert.are.equals('public, max-age=10', _G.ts.server_response.header['Cache-Control'])

      -- Small enough object
      _G.ts.server_response.header['Content-Length'] = '120'
      do_global_read_response()
      assert.are.equals('public, max-age=10', _G.ts.server_response.header['Cache-Control'])

      -- Large enough object
      _G.ts.server_response.header['Content-Length'] = '1073741825'
      do_global_read_response()
      assert.is_nil(_G.ts.server_response.header['Cache-Control'])

      -- PKP headers sanitation
      _G.ts.server_response.header['Public-Key-Pins'] = 'test'
      _G.ts.server_response.header['Public-Key-Pins-Report-Only'] = 'test'
      do_global_read_response()
      assert.are.equals(nil, _G.ts.server_response.header['Public-Key-Pins'])
      assert.are.equals(nil, _G.ts.server_response.header['Public-Key-Pins-Report-Only'])
    end)

    it("test - do_global_read_response 503 error with Cache-Control", function()
      _G.ts.server_response.header = {}
      -- 200 response with Cache-Control
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      do_global_read_response()
      assert.are.equals('public, max-age=10', _G.ts.server_response.header['Cache-Control'])

      -- 503 response with Cache-Control
      _G.ts.server_response.get_status = function() return 503 end
      do_global_read_response()
      assert.is_nil(_G.ts.server_response.header['Cache-Control'])
      assert.are.equals('public, max-age=10', _G.ts.ctx['Cache-Control'])
    end)

    it("test - do_global_read_response Vary-slotting for X-Forwarded-Proto", function()
      local old_status = _G.ts.server_response.get_status
      _G.ts.server_response.get_status = function() return 301 end

      _G.ts.server_response.header['Vary'] = nil
      do_global_read_response()
      assert.are.equals('X-Forwarded-Proto', _G.ts.server_response.header['Vary'])

      -- Do not add X-Forwarded-Proto on other status codes
      _G.ts.server_response.get_status = old_status
      _G.ts.server_response.header['Vary'] = nil
      do_global_read_response()
      assert.are.equals(nil, _G.ts.server_response.header['Vary'])
    end)

    it("test - do_global_send_response cache miss", function()
      _G.ts.http.get_cache_lookup_status = function() return TS_LUA_CACHE_LOOKUP_MISS end

      assert.are.equals(0, do_global_send_response())
      assert.are.equals('pass-test-hostname miss', ts.client_response.header['X-Cache-Int'])
      assert(ts.client_response.header['X-ATS-Timestamp'] > 1567423579)
    end)

    it("test - do_global_send_response cache hit", function()
      _G.ts.http.get_cache_lookup_status = function() return TS_LUA_CACHE_LOOKUP_HIT_FRESH end

      assert.are.equals(0, do_global_send_response())
      assert.are.equals('pass-test-hostname hit', ts.client_response.header['X-Cache-Int'])
    end)

    it("test - restore_cc_data restore Cache-Control", function()
      _G.ts.client_response.header = {}
      _G.ts.ctx['Cache-Control'] = 'public, max-age=10'
      restore_cc_data()
      assert.are.equals('public, max-age=10', _G.ts.client_response.header['Cache-Control'])
    end)
  end)
end)
