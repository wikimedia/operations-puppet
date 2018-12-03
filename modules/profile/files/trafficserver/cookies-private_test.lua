_G.ts = {
  client_response = {
    header = {}
  }
}

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - set_cc_private", function()
      require("cookies-private")

      set_cc_private()

      assert.are.equals(nil, _G.ts.client_response.header['Cache-Control'])

      _G.ts.client_response.header['Set-Cookie'] = 'banana potato na'

      set_cc_private()

      assert.are.equals("private, max-age=0, s-maxage=0", _G.ts.client_response.header['Cache-Control'])
    end)

  end)
end)
