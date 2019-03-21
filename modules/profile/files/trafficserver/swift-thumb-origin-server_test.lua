_G.ts = {
    client_request = {}
}

uri = "/wikipedia/commons/thumb/3/37/Home_Albert_Einstein_1895.jpg/200px-Home_Albert_Einstein_1895.jpg"
expected_origin = "swift-ro.discovery.wmnet"

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()
    it("test - swift-thumb-origin-server, non-thumb URI", function()
      require("swift-thumb-origin-server")
      stub(ts.client_request, "set_url_scheme")
      stub(ts.client_request, "set_url_host")
      spy.on(ts.client_request, "set_url_scheme")
      spy.on(ts.client_request, "set_url_host")

      set_origin_server("/this/is/just/a/test")
      assert.spy(ts.client_request.set_url_scheme).was_not_called_with("https")
      assert.spy(ts.client_request.set_url_host).was_not_called_with(expected_origin)
    end)

    it("test - swift-thumb-origin-server, thumb URI", function()
      set_origin_server(uri)
      assert.spy(ts.client_request.set_url_scheme).was.called_with("https")
      assert.spy(ts.client_request.set_url_host).was.called_with(expected_origin)
    end)
  end)
end)
