-- SPDX-License-Identifier: Apache-2.0
_G.ts = {
  client_request = {
    header = {},
    get_uri = function() return "/" end
  },
  http = {}
}

-- Initialize TS Lua remap status constants to distinct legible values. This
-- allows us to properly assert on do_remap return value.
_G.TS_LUA_REMAP_DID_REMAP_STOP = "DID_REMAP_STOP"
_G.TS_LUA_REMAP_NO_REMAP = "NO_REMAP"
_G.TS_LUA_REMAP_NO_REMAP_STOP = "NO_REMAP_STOP"
_G.TS_LUA_CONFIG_HTTP_CACHE_HTTP = "HTTP_CACHE_HTTP"

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - do_remap without X-Wikimedia-Debug request header", function()
      require("x-wikimedia-debug-routing")

      assert.are.equals(TS_LUA_REMAP_NO_REMAP, do_remap())
    end)

    it("test - valid X-Wikimedia-Debug eqiad", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      stub(ts, "hook")
      stub(ts.http, "config_int_set")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=k8s-mw-experimental-eqiad; profile"

      assert.are.equals(TS_LUA_REMAP_DID_REMAP_STOP, do_remap())

      assert.stub(ts.client_request.set_url_host).was.called_with("mw-experimental.eqiad.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4456)
      assert.stub(ts.http.config_int_set).was.called_with(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)
    end)

    it("test - X-Wikimedia-Debug with hostname only", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      stub(ts, "hook")
      stub(ts.http, "config_int_set")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "k8s-mw-experimental-codfw"

      assert.are.equals(TS_LUA_REMAP_DID_REMAP_STOP, do_remap())

      assert.stub(ts.client_request.set_url_host).was.called_with("mw-experimental.codfw.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4456)
      assert.stub(ts.http.config_int_set).was.called_with(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)
    end)

    it("test - X-Wikimedia-Debug on k8s", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=k8s-mwdebug"
      _G.ts.client_request.header['Host'] = 'www.wikidata.org'

      assert.are.equals(TS_LUA_REMAP_DID_REMAP_STOP, do_remap())

      assert.stub(ts.client_request.set_url_host).was.called_with("mwdebug.discovery.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4444)
    end)

    it("test - X-Wikimedia-Debug on k8s, route to specific DC", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=k8s-mwdebug-codfw"
      _G.ts.client_request.header['Host'] = 'www.wikidata.org'

      assert.are.equals(TS_LUA_REMAP_DID_REMAP_STOP, do_remap())

      assert.stub(ts.client_request.set_url_host).was.called_with("mwdebug.svc.codfw.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4444)
    end)

    it("test - X-Wikimedia-Debug on k8s next", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=k8s-mwdebug-next"
      _G.ts.client_request.header['Host'] = 'www.wikidata.org'

      assert.are.equals(TS_LUA_REMAP_DID_REMAP_STOP, do_remap())

      assert.stub(ts.client_request.set_url_host).was.called_with("mwdebug-next.discovery.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4453)
    end)

    it("test - X-Wikimedia-Debug on k8s next, route to specific DC", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=k8s-mwdebug-next-codfw"
      _G.ts.client_request.header['Host'] = 'www.wikidata.org'

      assert.are.equals(TS_LUA_REMAP_DID_REMAP_STOP, do_remap())

      assert.stub(ts.client_request.set_url_host).was.called_with("mwdebug-next.svc.codfw.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4453)
    end)

    it("test - X-Wikimedia-Debug with invalid value", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      stub(ts, "hook")
      stub(ts.http, "set_resp")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.header['X-Wikimedia-Debug'] = "the best banana and the worst potato"

      assert.are.equals(TS_LUA_REMAP_NO_REMAP_STOP, do_remap())

      assert.stub(ts.http.set_resp).was.called_with(400, "x-wikimedia-debug-routing: no match found for the backend specified in X-Wikimedia-Debug")
    end)

    it("test - skip remap for /w/rest.php endpoint paths", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      stub(ts.client_request, "get_uri")
      stub(ts.http, "config_int_set")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.get_uri.returns("/w/rest.php/v1/koko")
      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=k8s-mwdebug"

      assert.are.equals(TS_LUA_REMAP_NO_REMAP, do_remap())
      assert.stub(ts.client_request.set_url_host).was_not.called()
      assert.stub(ts.client_request.set_url_port).was_not.called()
      assert.stub(ts.http.config_int_set).was_not.called()
    end)

    it("test - skip remap for /w/rest.php trailing slash", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      stub(ts.client_request, "get_uri")
      stub(ts.http, "config_int_set")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.get_uri.returns("/w/rest.php/")
      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=k8s-mwdebug"

      assert.are.equals(TS_LUA_REMAP_NO_REMAP, do_remap())
      assert.stub(ts.client_request.set_url_host).was_not.called()
      assert.stub(ts.client_request.set_url_port).was_not.called()
      assert.stub(ts.http.config_int_set).was_not.called()
    end)

    it("test - allow remap for /w/rest.php endpoint paths with mw-experimental backend", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      stub(ts.client_request, "get_uri")
      stub(ts.http, "config_int_set")

      require("x-wikimedia-debug-routing")

      _G.ts.client_request.get_uri.returns("/w/rest.php/v1/koko")
      _G.ts.client_request.header['X-Wikimedia-Debug'] = "backend=k8s-mw-experimental-codfw"

      assert.are.equals(TS_LUA_REMAP_DID_REMAP_STOP, do_remap())
      assert.stub(ts.client_request.set_url_host).was.called_with("mw-experimental.codfw.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4456)
      assert.stub(ts.http.config_int_set).was.called_with(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)
    end)

  end)
end)