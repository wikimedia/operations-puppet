_G.ts = {
  server_response = {
    header = {}
  },
  client_request = {},
}

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - set_cc_private", function()
      ts.client_request.get_uri = function() return "/" end
      stub(ts, "error")

      require("cookies-private")

      do_global_read_response()

      assert.are.equals(nil, _G.ts.server_response.header['Cache-Control'])

      _G.ts.server_response.header['Set-Cookie'] = 'banana potato na'

      do_global_read_response()

      assert.are.equals("private, max-age=0, s-maxage=0", _G.ts.server_response.header['Cache-Control'])
    end)

  end)
end)
