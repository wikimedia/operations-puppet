_G.ts = { client_request = {} }

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - do_remap", function()
      stub(ts, "hook")

      require("normalize-path")

      local result = do_remap()

      assert.are.equals(0, result)
      assert.stub(ts.hook).was.called_with(TS_LUA_HOOK_POST_REMAP, remap_hook)
    end)

    it("test - hexStringTo", function()
      require("normalize-path")

      local result = hexStringToHexSet("3A 2F 40")
      assert.is_true(result["3A"])
      assert.is_true(result["2F"])
      assert.is_true(result["40"])
      assert.falsy(result["41"])

      local result = hexStringToLiteralSet("3A 2F 40")
      assert.is_true(result[":"])
      assert.is_true(result["/"])
      assert.is_true(result["@"])
      assert.falsy(result["?"])
    end)

    it("test - remap_hook", function()
      require("normalize-path")
      local orig_path = "/wiki/User:Ema%2fProfiling_Python%28Now you know[dude]"
      local modified_path = "/wiki/User:Ema/Profiling_Python(Now you know%5Bdude%5D"
      __init__({
          -- decodeset
          "3A 2F 40 21 24 28 29 2A 2C 3B",
          -- encodeset
          "5B 5D 26 27 2B 3D"
      })

      -- Stub get_method() returning "PURGE"
      _G.ts.client_request.get_method = function() return "PURGE" end

      -- Stub get_uri() returning orig_path
      _G.ts.client_request.get_uri = function() return orig_path end

      stub(ts.client_request, "set_uri")

      remap_hook()

      assert.stub(ts.client_request.set_uri).was.called_with(modified_path)
    end)

  end)
end)
