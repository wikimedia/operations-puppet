-- Send certain MediaWiki requests to the nearest DC
-- SPDX-License-Identifier: Apache-2.0
--
-- This file is managed by Puppet

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

local all_config = nil
local config_read_time = nil
local host_config_cache = {}
local dest_host = nil
local random_seeded = false

-- Read the configuration file and return the resulting table
local function read_config()
    local configfile = ts.get_config_dir() .. "/lua/multi-dc.lua.conf"
    local conf = dofile(configfile)
    if (type(conf) ~= "table" or type(conf.default) ~= "table") then
        ts.error("multi-dc.lua: invalid config file")
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
        host_config_cache = {}
        all_config = read_config()
    end
end

-- Get configuration for a host, with a cache
local function get_config(host)
    reload_config()
    local host_config = host_config_cache[host]
    if host_config == nil then
        if all_config.domains == nil then
            host_config = all_config.default or {}
        else
            host_config = all_config.domains[host]
            if host_config == nil then
                host_config = all_config.default or {}
            else
                for key, value in ipairs(all_config.default) do
                    if host_config[key] == nil then
                        host_config[key] = value
                    end
                end
            end
        end
        host_config_cache[host] = host_config
    end
    return host_config
end

-- Extract a parameter from a query string, with quick failure if
-- the parameter doesn't exist.
local function get_query_param(query, search)
    local namePos, eqPos = string.find(query, search)
    if namePos == nil then
        return nil
    elseif namePos > 1 then
        namePos, eqPos = string.find(query, "&" .. search)
        if namePos == nil then
            return nil
        end
    end
    local valuePos = eqPos + 1
    local endPos = string.find(query, "&", valuePos)
    if endPos == nil then
        return string.sub(query, valuePos)
    else
        return string.sub(query, valuePos, endPos - 1)
    end
end

-- Determine whether to use the "local" (nearby, read-only) DC
local function use_local_dc()
    local host = ts.client_request.header.Host:lower()
    local cookie = ts.client_request.header.Cookie
    local config = get_config(host)
    local mode = config.mode

    -- If the configuration disables the local DC, use primary
    if mode == "primary" then
        return false
    elseif mode == "local-anon" then
        if cookie and (string.find(cookie, "[Ss]ession=") or string.find(cookie, "Token=")) then
            return false
        end
    elseif mode ~= "local" then
        ts.error("multi-dc.lua: unrecognised mode \"" .. tostring(mode) .. "\"")
        return false
    end

    -- Check configured sample probability
    if config.load ~= nil then
        if not random_seeded then
            -- All states start with the same random seed, so let's fix that
            random_seeded = true
            math.randomseed(ts.http.id())
        end
        if math.random() >= config.load then
            return false
        end
    end

    -- POST requests go to primary unless there is an override header
    local promise = ts.client_request.header['Promise-Non-Write-API-Action']
    if promise ~= "true" and ts.client_request.get_method() == "POST" then
        return false
    end

    -- Cookie pin
    if cookie and string.find(cookie, "UseDC=master") then
        return false
    end

    -- cpPosIndex
    local query = ts.client_request.get_uri_args()
    if query ~= nil and get_query_param(query, "cpPosIndex=") then
        return false
    end

    -- Rollback
    local path = ts.client_request.get_uri()
    if query ~= nil and get_query_param(query, "action=") == "rollback" then
        return false
    end

    -- CentralAuth login
    if host == "login.wikimedia.org" or path == "/wiki/Special:CentralAutoLogin" then
        return false
    end

    -- CentralAuth foreign API
    local authorization = ts.client_request.header.Authorization
    if authorization ~= nil and string.find(authorization, "CentralAuthToken") == 1 then
        return false
    end
    if path == "/w/api.php" and query ~= nil then
        if get_query_param(query, "action=") == "centralauthtoken" or
           get_query_param(query, "centralauthtoken=") ~= nil
        then
            return false
        end
    end

    -- OAuth
    -- Due to T59500, initiate always uses index.php, and due to T74186,
    -- authorize always uses /wiki/
    if path == "/w/index.php" and query ~= nil then
        local title = get_query_param(query, "title=")
        if title == "Special:OAuth/initiate" or
            title == "Special:OAuth/token"
        then
            return false
        end
    end
    if path == "/wiki/Special:OAuth/authorize" or
        path == "/w/rest.php/oauth2/authorize"
    then
        return false
    end

    return true
end

-- Configure the module. This is called by ATS when the state is initialised.
function __init__(args)
    if type(args[1]) ~= "string" then
        ts.error("multi-dc.lua: pparam required giving local destination host")
    end
    dest_host = args[1]
end

-- The ATS hook point.
function do_remap()
    if use_local_dc() then
        ts.client_request.set_url_host(dest_host)
        return TS_LUA_REMAP_DID_REMAP
    end
    return TS_LUA_REMAP_NO_REMAP
end

-- vim: sw=4 sts=4 et
