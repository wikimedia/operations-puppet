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

    ts.client_response.header['X-ATS-Timestamp'] = os.time()
    return 0
end

function do_not_cache()
    ts.http.config_int_set(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)
end

--- Add header to Vary
-- @param old_vary: the original value of the Vary response header as sent by
--                  the origin server
-- @param header_name: the header to insert into Vary if not already there
function add_vary(old_vary, header_name)
    if not old_vary or string.match(old_vary, "^%s*$") then
        return header_name
    end

    local pattern = header_name:lower():gsub('%-', '%%-')
    if string.match(old_vary:lower(), pattern) then
        return old_vary
    end

    return old_vary .. ',' ..header_name
end

function uncacheable_cookie(cookie, vary)
    if cookie and vary then
        cookie = cookie:lower()
        vary = vary:lower()

        -- Vary:Cookie and Cookie ~ "session|token"
        if string.find(vary, 'cookie') and (string.find(cookie, 'session') or string.find(cookie, 'token')) then
            return true
        end
    end

    return false
end

function do_global_read_response()
    -- Various fairly severe privacy/security/uptime risks exist if we allow
    -- possibly compromised or misconfigured internal apps to emit these headers
    -- through our CDN blindly.
    ts.server_response.header['Public-Key-Pins'] = nil
    ts.server_response.header['Public-Key-Pins-Report-Only'] = nil

    local response_status = ts.server_response.get_status()
    if response_status == 301 or response_status == 302 then
        ts.server_response.header['Vary'] = add_vary(ts.server_response.header['Vary'], 'X-Forwarded-Proto')
    end

    -------------------------------------------------------------
    -- Force caching responses that would not be cached otherwise
    -------------------------------------------------------------
    if response_status == 404 then
        -- Cache 404s for 10 minutes
        ts.server_response.header['Cache-Control'] = 's-maxage=600'
    end

    ----------------------------------------------------------
    -- Avoid caching responses that might get cached otherwise
    ----------------------------------------------------------
    local content_length = ts.server_response.header['Content-Length']
    local cookie = ts.client_request.header['Cookie']
    local vary = ts.server_response.header['Vary']

    if ts.server_response.header['Set-Cookie'] then
        ts.debug("Do not cache response with Set-Cookie for uri " ..  ts.client_request.get_uri())
        do_not_cache()
    elseif uncacheable_cookie(cookie, vary) then
        ts.debug("Do not cache response with Vary: " .. vary .. ", request has Cookie: " .. cookie)
        do_not_cache()
    elseif content_length and tonumber(content_length) > 1024 * 16 * 16 * 16 * 16 * 16 then
        -- Do not cache files bigger than 1GB
        ts.debug("Do not cache response with CL:" .. ts.server_response.header['Content-Length'] ..", uri=" ..  ts.client_request.get_uri())
        do_not_cache()
    elseif response_status > 499 then
        -- Do not cache server errors under any circumstances
        do_not_cache()
    elseif ts.client_request.header['Authorization'] then
        do_not_cache()
    end

    return 0
end
