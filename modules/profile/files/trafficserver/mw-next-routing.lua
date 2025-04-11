-- SPDX-License-Identifier: Apache-2.0
--
-- Decides whether a request should be routed to a -next service, based on the
-- presence of a pattern in the Cookie header that identifies enrolled requests
-- and a configured load fraction (i.e., random selection probability).
--
-- See mw-next-routing.lua.conf for configuration details.
--
-- This file is managed by Puppet.

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

local random_seeded = false
local config_read_time = nil
-- In the exceptional case where first-load of the config fails, we'll use the
-- default config defined here.
local config = {
    enabled = false,
    load_fraction = 0,
    cookie_pattern = nil,
}

-- Mapping from (multi-dc.lua remapped) hosts to their -next service equivalent
-- host / port pairs.
local next_service_host_ports = {
    ["mw-web.discovery.wmnet"]        = { host = "mw-web-next.discovery.wmnet",        port = 4454 },
    ["mw-web-ro.discovery.wmnet"]     = { host = "mw-web-next-ro.discovery.wmnet",     port = 4454 },
    ["mw-api-ext.discovery.wmnet"]    = { host = "mw-api-ext-next.discovery.wmnet",    port = 4455 },
    ["mw-api-ext-ro.discovery.wmnet"] = { host = "mw-api-ext-next-ro.discovery.wmnet", port = 4455 }
}

-- Read the configuration file and return the resulting table or nil if the
-- config is not valid.
local function read_config()
    local configfile = ts.get_config_dir() .. "/lua/mw-next-routing.lua.conf"
    local conf = dofile(configfile)
    if type(conf) ~= "table" then
        ts.error("mw-next-routing.lua: invalid config file - not a table")
        return nil
    end
    if type(conf.enabled) ~= "boolean" then
        ts.error("mw-next-routing.lua: invalid config file - enabled is not a boolean")
        return nil
    end
    if type(conf.load_fraction) ~= "number" then
        ts.error("mw-next-routing.lua: invalid config file - load_fraction is not a number")
        return nil
    end
    if type(conf.cookie_pattern) ~= "string" then
        ts.error("mw-next-routing.lua: invalid config file - cookie_pattern is not a string")
        return nil
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
        -- Only replace the config if it was valid.
        local conf = read_config()
        if conf ~= nil then
            config = conf
        end
    end
end

-- Determine whether to route the request to its -next service.
local function use_next()
    -- If the load fraction is zero, or if there is no eligible cookie pattern
    -- configured, there's nothing to do.
    if config.load_fraction == 0 or config.cookie_pattern == nil then
        return false
    end
    local cookie = ts.client_request.header.Cookie
    if cookie == nil then
        return false
    end
    if not string.find(cookie, config.cookie_pattern) then
        return false
    end
    if not random_seeded then
      random_seeded = true
      math.randomseed(ts.http.id())
    end
    return math.random() < config.load_fraction
end

-- The ATS hook point.
function do_remap()
    reload_config()
    if not config.enabled then
        return TS_LUA_REMAP_NO_REMAP
    end
    local orig_url_host = ts.client_request.get_url_host()
    local next_dst = next_service_host_ports[orig_url_host]
    if next_dst == nil then
        -- This should not happen, and indicates we've inserted the plugin into
        -- the wrong mapping rule.
        ts.error("mw-next-routing.lua: unrecognized original host \"" .. orig_url_host .. "\"")
    elseif use_next() then
        ts.client_request.set_url_host(next_dst.host)
        ts.client_request.set_url_port(next_dst.port)
        return TS_LUA_REMAP_DID_REMAP
    end
    return TS_LUA_REMAP_NO_REMAP
end
