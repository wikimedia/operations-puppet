_G.ts = {
  client_request = {
    header = {}
  },
  http = {}
}

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - do_remap without X-Wikimedia-Debug request header", function()
      require("x-wikimedia-debug-routing")

      assert.are.equals(TS_LUA_REMAP_NO_REMAP, do_remap())
    end)

    it("test - valid X-Wikimedia-Debug eqiad", function()
      stub(ts.client_request, "set_url_host")
      stub(ts, "hook")
      stub(ts.http, "config_int_set")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=mwdebug1001.eqiad.wmnet; profile"

      do_remap()

      assert.stub(ts.client_request.set_url_host).was.called_with("mwdebug1001.eqiad.wmnet")
      assert.stub(ts.http.config_int_set).was.called_with(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)
    end)

    it("test - X-Wikimedia-Debug with hostname only", function()
      stub(ts.client_request, "set_url_host")
      stub(ts, "hook")
      stub(ts.http, "config_int_set")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "mwdebug2002.codfw.wmnet"

      do_remap()

      assert.stub(ts.client_request.set_url_host).was.called_with("mwdebug2002.codfw.wmnet")
      assert.stub(ts.http.config_int_set).was.called_with(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)
    end)

    it("test - X-Wikimedia-Debug with invalid value", function()
      stub(ts.client_request, "set_url_host")
      stub(ts, "hook")
      stub(ts.http, "set_resp")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "the best banana and the worst potato"

      do_remap()

      assert.stub(ts.http.set_resp).was.called_with(400, "x-wikimedia-debug-routing: no match found for the backend specified in X-Wikimedia-Debug")
    end)
  end)
end)
