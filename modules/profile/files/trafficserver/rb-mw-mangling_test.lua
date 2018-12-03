_G.ts = {
  client_request = {
    header = {}
  }
}

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - do_remap", function()
      stub(ts, "hook")

      require("rb-mw-mangling")

      local result = do_remap()

      assert.are.equals(0, result)
      assert.stub(ts.hook).was.called_with(TS_LUA_HOOK_POST_REMAP, remap_hook)
    end)

    it("test - restbase mangling", function()
      stub(ts.client_request, "set_uri")

      require("rb-mw-mangling")

      _G.ts.client_request.get_uri = function() return "/api/rest_v1/page/summary/Test" end
      _G.ts.client_request.header['Host'] = "en.wikipedia.org"

      remap_hook()

      assert.stub(ts.client_request.set_uri).was.called_with("/en.wikipedia.org/v1/page/summary/Test")
    end)

    it("test - mediawiki mangling", function()
      require("rb-mw-mangling")

      _G.ts.client_request.header['X-Subdomain'] = "m"
      _G.ts.client_request.header['x-dt-host'] = "it.wikipedia.org"

      remap_hook()

      assert.equals(_G.ts.client_request.header['Host'], 'it.wikipedia.org')
    end)

  end)
end)
