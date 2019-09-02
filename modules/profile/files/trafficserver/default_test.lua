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
_G.get_hostname = function() return 'pass-test-hostname' end
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

    it("test - do_global_read_response Vary-slotting for PHP7", function()
      -- No Vary at all, no X-Powered-By
      do_global_read_response()
      assert.is_nil(_G.ts.server_response.header['Vary'])

      -- No Vary, powered by PHP
      _G.ts.server_response.header['X-Powered-By'] = "PHP/7.2.16-1+0~20190307202415.17+stretch~1.gbpa7be82+wmf1"
      do_global_read_response()
      assert.are.equals('X-Seven', _G.ts.server_response.header['Vary'])

      -- Empty Vary
      _G.ts.server_response.header['Vary'] = ""
      do_global_read_response()
      assert.are.equals('X-Seven', _G.ts.server_response.header['Vary'])

      -- Vary made entirely of %s
      _G.ts.server_response.header['Vary'] = "    "
      do_global_read_response()
      assert.are.equals('X-Seven', _G.ts.server_response.header['Vary'])

      -- Vary already set to X-Seven
      _G.ts.server_response.header['Vary'] = "X-Seven"
      do_global_read_response()
      assert.are.equals('X-Seven', _G.ts.server_response.header['Vary'])

      -- Vary already set to X-Seven and something else
      _G.ts.server_response.header['Vary'] = "Cookie, X-Seven"
      do_global_read_response()
      assert.are.equals('Cookie, X-Seven', _G.ts.server_response.header['Vary'])

      -- Vary set to something else
      _G.ts.server_response.header['Vary'] = "Cookie"
      do_global_read_response()
      assert.are.equals('Cookie,X-Seven', _G.ts.server_response.header['Vary'])
    end)

    it("test - do_global_read_response Vary-slotting for X-Forwarded-Proto", function()
      local old_status = _G.ts.server_response.get_status
      _G.ts.server_response.get_status = function() return 301 end

      _G.ts.server_response.header['Vary'] = nil
      do_global_read_response()
      assert.are.equals('X-Seven,X-Forwarded-Proto', _G.ts.server_response.header['Vary'])

      -- Do not add X-Forwarded-Proto on other status codes
      _G.ts.server_response.get_status = old_status
      _G.ts.server_response.header['Vary'] = nil
      do_global_read_response()
      assert.are.equals('X-Seven', _G.ts.server_response.header['Vary'])
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
