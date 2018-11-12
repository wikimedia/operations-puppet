_G.ts = {
    client_response = {
        header = {}
    }
}

uri = "/wikipedia/commons/thumb/3/37/Home_Albert_Einstein_1895.jpg/200px-Home_Albert_Einstein_1895.jpg"
expected = "/wikipedia/commons/3/37/Home_Albert_Einstein_1895.jpg"

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - gen_x_mediawiki_original, non-thumb URI", function()
      require("x-mediawiki-original")

      gen_x_mediawiki_original("/this/is/just/a/test")
      assert.are.equals(nil, ts.client_response.header['X-MediaWiki-Original'])
    end)

    it("test - gen_x_mediawiki_original, thumb URI", function()
      require("x-mediawiki-original")

      gen_x_mediawiki_original(uri)
      assert.are.equals(expected, ts.client_response.header['X-MediaWiki-Original'])
    end)

  end)
end)
