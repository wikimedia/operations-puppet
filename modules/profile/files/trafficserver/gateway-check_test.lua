-- SPDX-License-Identifier: Apache-2.0
local file_name = debug.getinfo(1, "S").source:sub(1)
local base_dir = (file_name:reverse():match("/([^@]*)") or ""):reverse() or "."
local gateway_file = loadfile(base_dir .. "/gateway-check.lua")

local function make_ts(request)
  ts = {
    client_request = {
      get_uri = function() return request.uri end
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

  gateway_file()
  result.remap_value = do_remap()
  result.host = _G.ts.client_request.mapped_host
  result.port = _G.ts.client_request.mapped_port
  return result
end

function expect(result, is_gateway, host, port)
  if is_gateway then
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
   ["/api/rest_v1/(.+)/pdf/(.*)"] = {"rest-gateway.discovery.wmnet", 4113},
   ["/api/rest_v1/metrics/unique%-devices/(.+)"] = {"api-gateway.discovery.wmnet", 8087}
}

-- the tests start here.

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()

    it("test - route with multiple match groups", function()
      result = run({
          host = 'en.wikipedia.org',
          uri = '/api/rest_v1/page/pdf/Tornado'
        },
        default_config
      )
      expect(result, true, 'rest-gateway.discovery.wmnet', 4113)
    end)

    it("test - route with one match group and a dash in the match", function()
      result = run({
          host = 'en.wikipedia.org',
          uri = '/api/rest_v1/metrics/unique-devices/en.wikipedia.org/all-sites/daily/20160201/20160229'
        },
        default_config
      )
      expect(result, true, 'api-gateway.discovery.wmnet', 8087)
    end)

    it("test - route that doesn't match", function()
      result = run({
          host = 'ga.wikipedia.org',
          uri = '/wiki/Amharclann'
        },
        default_config
      )
      expect(result, false, nil, nil)
    end)
  end)
end)
