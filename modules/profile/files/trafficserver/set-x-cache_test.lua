_G.ts = {
  ctx = {},
  client_response = {
    header = {}
  }
}

_G.TS_LUA_CACHE_LOOKUP_MISS = 0
_G.TS_LUA_CACHE_LOOKUP_HIT_FRESH = 1

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - do_remap", function()
      stub(ts, "hook")

      require("set-x-cache")

      local result = do_remap()

      assert.are.equals(0, result)
      assert.stub(ts.hook).was.called_with(TS_LUA_HOOK_CACHE_LOOKUP_COMPLETE, cache_lookup)
      assert.stub(ts.hook).was.called_with(TS_LUA_HOOK_SEND_RESPONSE_HDR, gen_x_cache_int)
    end)

    it("test - gen_x_cache_int miss", function()
      stub(ts, "hook")

      require("set-x-cache")

      _G.get_hostname = function()
          return 'pass-test-hostname'
      end
      _G.ts.ctx['cstatus'] = TS_LUA_CACHE_LOOKUP_MISS

      gen_x_cache_int()

      assert.are.equals('miss', ts.client_response.header['X-Cache-Status'])
      assert.are.equals('pass-test-hostname miss', ts.client_response.header['X-Cache-Int'])
    end)

    it("test - gen_x_cache_int hit", function()
      stub(ts, "hook")

      require("set-x-cache")

      _G.ts.ctx['cstatus'] = TS_LUA_CACHE_LOOKUP_HIT_FRESH

      gen_x_cache_int()

      assert.are.equals('pass-test-hostname hit', ts.client_response.header['X-Cache-Int'])
    end)

  end)
end)
