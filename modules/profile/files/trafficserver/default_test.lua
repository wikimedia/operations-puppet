require("default")

_G.ts = {
  http = {},
  server_response = { header = {} },
  client_response = { header = {} },
  client_request = {},
}

_G.TS_LUA_CACHE_LOOKUP_MISS = 0
_G.TS_LUA_CACHE_LOOKUP_HIT_FRESH = 1

_G.ts.client_request.get_uri = function() return "/" end
_G.get_hostname = function() return 'pass-test-hostname' end

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - do_global_read_response Set-Cookie", function()
      stub(ts, "error")

      -- Without Set-Cookie
      _G.ts.server_response.header = {}
      do_global_read_response()
      assert.are.equals(nil, _G.ts.server_response.header['Cache-Control'])

      -- With Set-Cookie
      _G.ts.server_response.header['Set-Cookie'] = 'banana potato na'
      do_global_read_response()
      assert.are.equals("private, max-age=0, s-maxage=0", _G.ts.server_response.header['Cache-Control'])
    end)

    it("test - do_global_read_response large Content-Length", function()
      stub(ts, "error")

      -- No Content-Length
      _G.ts.server_response.header = {}
      do_global_read_response()
      assert.are.equals(nil, _G.ts.server_response.header['Cache-Control'])

      -- Small enough object
      _G.ts.server_response.header['Content-Length'] = '120'
      do_global_read_response()
      assert.are.equals(nil, _G.ts.server_response.header['Cache-Control'])

      -- Large enough object
      _G.ts.server_response.header['Content-Length'] = '1073741825'
      do_global_read_response()
      assert.are.equals("private, max-age=0, s-maxage=0", _G.ts.server_response.header['Cache-Control'])
    end)

    it("test - do_global_send_response cache miss", function()
      _G.ts.http.get_cache_lookup_status = function() return TS_LUA_CACHE_LOOKUP_MISS end

      assert.are.equals(0, do_global_send_response())
      assert.are.equals('pass-test-hostname miss', ts.client_response.header['X-Cache-Int'])
    end)

    it("test - do_global_send_response cache hit", function()
      _G.ts.http.get_cache_lookup_status = function() return TS_LUA_CACHE_LOOKUP_HIT_FRESH end

      assert.are.equals(0, do_global_send_response())
      assert.are.equals('pass-test-hostname hit', ts.client_response.header['X-Cache-Int'])
    end)
  end)
end)
