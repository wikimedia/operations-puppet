require("set-x-cache")

_G.ts = {
  client_response = { header = {} },
  http = {}
}

_G.TS_LUA_CACHE_LOOKUP_MISS = 0
_G.TS_LUA_CACHE_LOOKUP_HIT_FRESH = 1


describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - do_global_send_response cache miss", function()
      _G.ts.http.get_cache_lookup_status = function() return TS_LUA_CACHE_LOOKUP_MISS end
      _G.get_hostname = function() return 'pass-test-hostname' end

      assert.are.equals(0, do_global_send_response())
      assert.are.equals('miss', ts.client_response.header['X-Cache-Status'])
      assert.are.equals('pass-test-hostname miss', ts.client_response.header['X-Cache-Int'])

    end)

    it("test - do_global_send_response cache hit", function()
      _G.get_hostname = function() return 'pass-test-hostname' end
      _G.ts.http.get_cache_lookup_status = function() return TS_LUA_CACHE_LOOKUP_HIT_FRESH end

      assert.are.equals(0, do_global_send_response())
      assert.are.equals('hit', ts.client_response.header['X-Cache-Status'])
      assert.are.equals('pass-test-hostname hit', ts.client_response.header['X-Cache-Int'])
    end)
  end)
end)
