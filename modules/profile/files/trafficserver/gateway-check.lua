-- SPDX-License-Identifier: Apache-2.0
-- Decide if a request should be routed to a gateway and, if so, which gateway

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

local random_seeded = false
local config_read_time = nil
-- Paths to match upon that will require us to change the host and port
-- The default value of gateway_paths is a structurally valid noop config, and
-- is only relevant in the case where initial config loading fails.
local gateway_paths = {["default"] = {}}

-- Read the configuration file and return the resulting table, or nil if the
-- configuration was invalid.
local function read_config()
    local configfile = ts.get_config_dir() .. "/lua/gateway-check.lua.conf"
    local conf = dofile(configfile)
    if (type(conf) ~= "table" or conf["default"] == nil or conf["hostmatch"] == nil or conf["groupmatch"] == nil or conf["groups"] == nil) then
        ts.error("gateway-check.lua: invalid config file")
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
        -- Only accept the new config if it's valid (non-nil).
        local conf = read_config()
        if conf ~= nil then
            gateway_paths = conf
        end
    end
end


local function use_rest_gateway()
    reload_config()
    local orig_path = ts.client_request.get_uri()
    local rules = gateway_paths["default"]
    local host = ts.client_request.header["Host"]

    -- If a host:[URL...] pair is specified under ignore, don't check
    -- for or complete any redirects for this pairing and just
    -- immediately return
    if host ~= nil and gateway_paths["ignore"] ~= nil and gateway_paths["ignore"][host] ~= nil then
        local ignore_paths = gateway_paths["ignore"][host]
        for index, ignore_path in pairs(ignore_paths) do
            if string.find(orig_path, ignore_path) then
                return false
            end
        end
    end
    -- If we have a host, check the regex matches.
    -- This will stop on first match.
    if host ~= nil then
        -- Start from a fresh copy of default.
        local merged_rules = {}
        for k, v in pairs(rules) do
            merged_rules[k] = v
        end

        -- If we find a literal host match, add the rules to the merged_rules table
        -- and do not look for regex matches.
        if gateway_paths["hostmatch"] ~= nil and gateway_paths["hostmatch"][host] ~= nil then
            for k, v in pairs(gateway_paths["hostmatch"][host]) do
                merged_rules[k] = v
            end
        else
            -- Find out which group the host belongs to and merge these rules
            if gateway_paths["groups"] ~= nil then
                for group, hosts in pairs(gateway_paths["groups"]) do
                    if hosts[host] == true then
                        for k2, v2 in pairs(gateway_paths["groupmatch"][group]) do
                            merged_rules[k2] = v2
                        end
                        break
                    end
                end
            end
        end
        rules = merged_rules
    end

    -- And now let's see if any url path rule matches
    for key, value in pairs(rules) do
        if string.find(orig_path, key) then
            -- We've found a matching rule, apply the load_fraction sampling
            -- probability, return the configured destination if we should
            -- route to the gateway, otherwise return false early and go to the
            -- original destination
            if not random_seeded then
                random_seeded = true
                math.randomseed(ts.http.id())
            end
            if math.random() < value[3] then
                return value
            else
                return false
            end
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
