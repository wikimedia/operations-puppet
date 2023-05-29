-- SPDX-License-Identifier: Apache-2.0
local file_name = debug.getinfo(1, "S").source:sub(1)
local base_dir = (file_name:reverse():match("/([^@]*)") or ""):reverse()
local mw_on_k8s_file = loadfile(base_dir .. "/mw-on-k8s.lua")

local function make_ts(request)
  ts = {
    client_request = {
      get_url_host = function() return request.backend end
    },
    http = {
      id = function() return 1 end
    },
    now = function() return os.clock() end,
    get_config_dir = function() return base_dir end,
    error = function(msg) error(msg) end
  }
  if request.host ~= nil then
    ts.client_request.header = {Host = request.host}
  else
    ts.client_request.header = {}
  end
  ts.client_request.set_url_host = function(host) ts.client_request.mapped_host = host end
  ts.client_request.set_url_port = function(port) ts.client_request.mapped_port = port end
  return ts
end

local function run(request, config)
  local result = {}
  _G.ts = make_ts(request)
  _G.dofile = function ()
    return config
  end

  mw_on_k8s_file()
  result.remap_value = do_remap()
  result.host = _G.ts.client_request.mapped_host
  result.port = _G.ts.client_request.mapped_port
  return result
end

function expect(result, is_k8s, host, port)
  if is_k8s then
    assert.are.equals(TS_LUA_REMAP_DID_REMAP, result.remap_value)
    assert.are.equals(result.host, host)
    assert.are.equals(result.port, port)
  else
    assert.are.equals(TS_LUA_REMAP_NO_REMAP, result.remap_value)
    assert.are.equals(result.host, nil)
    assert.are.equals(result.port, nil)
  end
end

local default_config = {
  ["test2.wikipedia.org"] = 1,
  ["test.wikidata.org"] = 1,
  ["default"] = 0
}

-- the tests start here.

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()
    it("test - do_remap without a host header", function()
      result = run({
          host = nil,
          backend = "api-ro.discovery.wmnet",
        },
        default_config
      )
      expect(result, false)
    end)


    it("test - api RO request with a matching host header", function()
      result = run({
          host = 'test2.wikipedia.org',
          backend = 'api-ro.discovery.wmnet'
        },
        default_config
      )
      expect(result, true, 'mw-api-ext-ro.discovery.wmnet', 4447)
    end)

    it("test - appserver RW with a matching host header", function()
      result = run({
          host = 'test.wikidata.org',
          backend = 'appservers-rw.discovery.wmnet'
        },
        default_config
      )
      expect(result, true, 'mw-web.discovery.wmnet', 4450)
    end)

    it("test - mobile domain match", function()
      result = run({
          host = 'test2.m.wikipedia.org',
          backend = 'appservers-rw.discovery.wmnet'
        },
        default_config
      )
      expect(result, true, 'mw-web.discovery.wmnet', 4450)
    end)

    it("test - appserver RO with a non-matching host header", function()
      result = run({
            host = 'fr.wikipedia.org',
            backend = 'appservers-rw.discovery.wmnet'
          },
          default_config
      )
      expect(result, false)
    end)

    it("test - respects 0% probability", function()
      result = run({
            host = 'fr.wikipedia.org',
            backend = 'appservers-rw.discovery.wmnet'
          },
          {['fr.wikipedia.org'] = 0, ['default'] = 1}
      )
      expect(result, false)
    end)

    it("test - A random seed smaller than load goes to k8s", function()
      stub(math, "random", 0.4)
      result = run({
            host = 'fr.wikipedia.org',
            backend = 'appservers-rw.discovery.wmnet'
          },
          {["fr.wikipedia.org"] = 0.5}
      )
      expect(result, true, 'mw-web.discovery.wmnet', 4450)
    end)

    it("test - A random seed equal or larger than load is not touched", function()
      stub(math, "random", 0.5)
      result = run({
            host = 'fr.wikipedia.org',
            backend = 'appservers-rw.discovery.wmnet'
          },
          {["fr.wikipedia.org"] = 0.5}
      )
      expect(result, false)
    end)
  end)
end)