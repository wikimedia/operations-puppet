-- SPDX-License-Identifier: Apache-2.0
local file_name = debug.getinfo(1, "S").source:sub(1)
local base_dir = (file_name:reverse():match("/([^@]*)") or ""):reverse() or "."
local gateway_file = loadfile(base_dir .. "/gateway-check.lua")

local function make_ts(request)
  ts = {
    client_request = {
      get_uri = function() return request.uri end
    },
    get_config_dir = function() return base_dir end,
  }
  if request.host ~= nil then
    ts.client_request.header = {Host = request.host}
  else
    ts.client_request.header = {}
  end
  if request.now ~= nil then
    ts.now = function() return request.now end
  else
    ts.now = function() return os.clock() end
  end
  ts.error = function(msg) ts.error_msg = msg end
  ts.client_request.set_url_host = function(host) ts.client_request.mapped_host = host end
  ts.client_request.set_url_port = function(port) ts.client_request.mapped_port = port end
  return ts
end

local function setup(request, config)
  _G.ts = make_ts(request)
  _G.dofile = function ()
    return config
  end
  _G.TS_LUA_REMAP_DID_REMAP = 'DID_REMAP'
  _G.TS_LUA_REMAP_NO_REMAP = 'NO_REMAP'
end

local function run(request, config)
  setup(request, config)
  gateway_file()
  local result = {}
  result.remap_value = do_remap()
  result.host = _G.ts.client_request.mapped_host
  result.port = _G.ts.client_request.mapped_port
  return result
end

local default_config = {
    ["default"] = {
        ["/api/rest_v1/(.+)/pdf/(.*)"] = {"rest-gateway.discovery.wmnet", 4113},
        ["/api/rest_v1/metrics/unique%-devices/(.+)"] = {"api-gateway.discovery.wmnet", 8087}
    },
    ["test.wikipedia.org"] = {
        ["/api/rest_v1/page/title/(.*)"] = {"rest-gateway.discovery.wmnet", 4113},
    },
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
      assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
      assert.are.same('rest-gateway.discovery.wmnet', result.host)
      assert.are.same(4113, result.port)
      assert.is_nil(ts.error_msg)
    end)

    it("test - route with one match group and a dash in the match", function()
      result = run({
          host = 'en.wikipedia.org',
          uri = '/api/rest_v1/metrics/unique-devices/en.wikipedia.org/all-sites/daily/20160201/20160229'
        },
        default_config
      )
      assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
      assert.are.same('api-gateway.discovery.wmnet', result.host)
      assert.are.same(8087, result.port)
      assert.is_nil(ts.error_msg)
    end)

    it("test - route that doesn't match", function()
      result = run({
          host = 'ga.wikipedia.org',
          uri = '/wiki/Amharclann'
        },
        default_config
      )
      assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
      assert.is_nil(result.host)
      assert.is_nil(result.port)
      assert.is_nil(ts.error_msg)
    end)

    it("should remap nothing on initial load failure", function()
      result = run({
          host = 'en.wikipedia.org',
          uri = '/api/rest_v1/page/pdf/Tornado'
        },
        'clearly not a table'
      )
      -- Expectation: an error is logged on load failure, and nothing is
      -- remapped.
      assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
      assert.is_nil(result.host)
      assert.is_nil(result.port)
      assert.are.same("gateway-check.lua: invalid config file", ts.error_msg)
    end)

    it("should retain the existing config on reload failure", function()
      setup({
          host = 'en.wikipedia.org',
          uri = '/api/rest_v1/page/pdf/Tornado',
          now = 0
        },
        default_config
      )

      gateway_file()

      assert.are.same(TS_LUA_REMAP_DID_REMAP, do_remap())
      assert.are.same('rest-gateway.discovery.wmnet', _G.ts.client_request.mapped_host)
      assert.are.same(4113, _G.ts.client_request.mapped_port)
      assert.is_nil(ts.error_msg)

      -- Advance the clock by 11 seconds and replace with a bogus config table.
      setup({
          host = 'en.wikipedia.org',
          uri = '/api/rest_v1/page/pdf/Tornado',
          now = 11
        },
        'clearly not a table'
      )

      -- Expectation: an error is logged on load failure, and the previous
      -- configuration remains intact.
      assert.are.same(TS_LUA_REMAP_DID_REMAP, do_remap())
      assert.are.same('rest-gateway.discovery.wmnet', _G.ts.client_request.mapped_host)
      assert.are.same(4113, _G.ts.client_request.mapped_port)
      assert.are.same("gateway-check.lua: invalid config file", ts.error_msg)
    end)

    it("test - specific wiki route that matches", function()
      result = run({
          host = 'test.wikipedia.org',
          uri = '/api/rest_v1/page/title/Hospet'
        },
        default_config
      )
      assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
      assert.are.same('rest-gateway.discovery.wmnet', result.host)
      assert.are.same(4113, result.port)
      assert.is_nil(ts.error_msg)
    end)

    it("test - specific wiki route that fails", function()
      result = run({
          host = 'test.wikipedia.org',
          uri = '/api/rest_v1/utterfail'
        },
        default_config
      )
      assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
      assert.is_nil(result.host)
      assert.is_nil(result.port)
      assert.is_nil(ts.error_msg)
    end)

    it("test - specific wiki matches default routes", function()
      result = run({
          host = 'test.wikipedia.org',
          uri = '/api/rest_v1/metrics/unique-devices/en.wikipedia.org/all-sites/daily/20160201/20160229'
        },
        default_config
      )
      assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
      assert.are.same('api-gateway.discovery.wmnet', result.host)
      assert.are.same(8087, result.port)
      assert.is_nil(ts.error_msg)
    end)
  end)
end)
