-- Global Lua script.
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

function do_global_send_response()
    local cache_status = cache_status_to_string(ts.http.get_cache_lookup_status())
    ts.client_response.header['X-Cache-Int'] = get_hostname() .. " " .. cache_status
    return 0
end

function do_global_read_response()
    if ts.server_response.header['Set-Cookie'] then
        ts.server_response.header['Cache-Control'] = 'private, max-age=0, s-maxage=0'
        ts.error("Setting CC:private on response with Set-Cookie for uri " ..  ts.client_request.get_uri())
    end

    -- Do not cache files bigger than 1GB
    local content_length = ts.server_response.header['Content-Length']
    if content_length and tonumber(content_length) > 1024 * 16 * 16 * 16 * 16 * 16 then
        ts.server_response.header['Cache-Control'] = 'private, max-age=0, s-maxage=0'
        ts.error("Setting CC:private on response with CL:" .. ts.server_response.header['Content-Length'] ..", uri=" ..  ts.client_request.get_uri())
    end

    return 0
end

function do_global_send_request()
    -- This is to avoid some corner-cases and bugs as noted in T125938 , e.g.
    -- applayer gzip turning 500s into junk-response 503s, applayer gzipping
    -- CL:0 bodies into a 20 bytes gzip header, applayer compressing tiny
    -- outputs in general, etc.
    -- We have also observed Swift returning Content-Type: gzip with
    -- non-gzipped content, which confuses varnish-fe making it occasionally
    -- return 503.
    ts.server_request.header['Accept-Encoding'] = nil
end
