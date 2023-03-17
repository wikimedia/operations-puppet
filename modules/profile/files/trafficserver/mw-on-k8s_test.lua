-- SPDX-License-Identifier: Apache-2.0
_G.ts = {
    client_request = {
      header = {},
      get_url_host = function() return "api-ro.discovery.wmnet" end
    },
    http = {}
}
describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()
    it("test - do_remap without a host header", function()
      require("mw-on-k8s")

      assert.are.equals(TS_LUA_REMAP_NO_REMAP, do_remap())
    end)

    it("test - api RO request with a matching host header", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      _G.ts.client_request.header = {Host = "test2.wikipedia.org"}
      _G.ts.client_request.get_url_host = function() return "api-ro.discovery.wmnet" end
      assert.are.equals(TS_LUA_REMAP_DID_REMAP, do_remap())
      assert.stub(ts.client_request.set_url_host).was.called_with("mw-api-ext-ro.discovery.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4447)
    end)

    it("test - appserver RW with a matching host header", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      _G.ts.client_request.header = {Host = "test.wikidata.org"}
      _G.ts.client_request.get_url_host = function() return "appservers-rw.discovery.wmnet" end
      assert.are.equals(TS_LUA_REMAP_DID_REMAP, do_remap())
      assert.stub(ts.client_request.set_url_host).was.called_with("mw-web.discovery.wmnet")
      assert.stub(ts.client_request.set_url_port).was.called_with(4450)
    end)

    it("test - appserver RO with a non-matching host header", function()
      stub(ts.client_request, "set_url_host")
      stub(ts.client_request, "set_url_port")
      _G.ts.client_request.header = {Host = "fr.wikipedia.org"}
      _G.ts.client_request.get_url_host = function() return "appservers-ro.discovery.wmnet" end
      assert.are.equals(TS_LUA_REMAP_DID_REMAP, do_remap())
      assert.stub(ts.client_request.set_url_host).was_not.called()
      assert.stub(ts.client_request.set_url_port).was_not.called()
    end)
  end)
end)