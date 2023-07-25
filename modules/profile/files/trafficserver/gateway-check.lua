-- SPDX-License-Identifier: Apache-2.0
-- Decide if a request should be routed to a gateway and, if so, which gateway

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

local config_read_time = nil
-- Paths to match upon that will require us to change the host and port
local gateway_paths = {}

-- Read the configuration file and return the resulting table
local function read_config()
  local configfile = ts.get_config_dir() .. "/lua/gateway-check.lua.conf"
  local conf = dofile(configfile)
  if (type(conf) ~= "table") then
      ts.error("gateway-check.lua: invalid config file")
      return {}
  end
  return conf
end

-- Reload the config every 10 seconds.
--
-- In ATS 8, Lua modules are never reloaded, you have to restart the server.
-- In ATS 10, there is documentation to the effect that Lua modules may be
-- reloaded if remap.config was touched. Maybe it just means if the plugin
-- parameters were changed.
--
-- Note that with 256 states, read_config() will receive an average of 25.6
-- calls per second. But it takes <1ms for a small file.
local function reload_config()
  local now = ts.now()
  if config_read_time == nil or now - config_read_time > 10 then
      config_read_time = now
      -- only reload the configuration if it's valid
      local conf = read_config()
      if conf ~= {} then
        gateway_paths = conf
      end
  end
end

local function use_rest_gateway()
   reload_config()
   local orig_path = ts.client_request.get_uri()

   for key, value in pairs(gateway_paths) do
      if string.find(orig_path, key) then
         return value
      end
   end
   return false
end

-- The ATS hook point.
function do_remap()
   local use_gateway = use_rest_gateway()
   if use_gateway then
      ts.client_request.set_url_host(use_gateway[1])
      ts.client_request.set_url_port(use_gateway[2])
    return TS_LUA_REMAP_DID_REMAP
  end
  return TS_LUA_REMAP_NO_REMAP
end
