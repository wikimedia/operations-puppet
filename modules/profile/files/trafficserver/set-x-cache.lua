-- Set the X-Cache-Status and X-Cache-Int response headers.
--
-- Example: X-Cache-Status: miss
--          X-Cache-Int: cp1048 miss
--
-- This file is managed by Puppet.
--

local PROXY_HOSTNAME=''
function __init__(argtb)
    PROXY_HOSTNAME = argtb[1]
end

function get_hostname()
    return PROXY_HOSTNAME
end

function cache_lookup()
    local cache_status = ts.http.get_cache_lookup_status()
    ts.ctx['cstatus'] = cache_status
end

function cache_status_to_string(status)
    if status == TS_LUA_CACHE_LOOKUP_MISS then
        return "miss"
    end

    if status == TS_LUA_CACHE_LOOKUP_HIT_FRESH then
        return "hit"
    end

    if status == TS_LUA_CACHE_LOOKUP_HIT_STALE then
        return "miss"
    end

    if status == TS_LUA_CACHE_LOOKUP_SKIPPED then
        return "pass"
    end

    return "bug"
end

function gen_x_cache_int()
    local cache_status = cache_status_to_string(ts.ctx['cstatus'])
    ts.client_response.header['X-Cache-Int'] = get_hostname() .. " " .. cache_status
    ts.client_response.header['X-Cache-Status'] = cache_status
end

function do_remap()
    ts.hook(TS_LUA_HOOK_CACHE_LOOKUP_COMPLETE, cache_lookup)
    ts.hook(TS_LUA_HOOK_SEND_RESPONSE_HDR, gen_x_cache_int)
    return 0
end
