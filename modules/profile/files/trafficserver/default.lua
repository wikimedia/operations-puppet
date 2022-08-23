-- Global Lua script.
--
-- This file is managed by Puppet.
--

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

function read_config()
    local configfile = ts.get_config_dir() .. "/lua/default.lua.conf"

    ts.debug("Reading " .. configfile)

    dofile(configfile)
    assert(lua_hostname, "lua_hostname not set by " .. configfile)

    ts.debug("read_config() returning " .. lua_hostname)

    return lua_hostname
end

local HOSTNAME = read_config()

function cache_status_to_string(status)
    if status == TS_LUA_CACHE_LOOKUP_MISS then
        return "miss"
    end

    if status == TS_LUA_CACHE_LOOKUP_HIT_FRESH then
        return "hit"
    end

    if status == TS_LUA_CACHE_LOOKUP_HIT_STALE then
        -- We have a cache hit on a stale object. A conditional request was
        -- performed against the origin, which replied with 304 - Not Modified. The
        -- object can be served from cache. Arguably this is not exactly a "hit",
        -- but it is more of a hit than a miss. Further, Varnish calls these "hit",
        -- so for consistency do the same here too.
        if ts.server_response.get_status() == 304 then
            return "hit"
        else
            return "miss"
        end
    end

    if status == TS_LUA_CACHE_LOOKUP_SKIPPED then
        return "pass"
    end

    return "int"
end

function disable_coalescing()
    ts.http.config_int_set(TS_LUA_CONFIG_HTTP_CACHE_MAX_OPEN_READ_RETRIES, -1)
    ts.http.config_int_set(TS_LUA_CONFIG_HTTP_CACHE_MAX_OPEN_WRITE_RETRIES, 1)
    -- We should also set proxy.config.cache.enable_read_while_writer to 0 but
    -- there seems to be no TS_LUA_CONFIG_ option for it.
end

function no_cache_lookup()
    ts.http.config_int_set(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)
end

function do_global_read_request()
    if ts.client_request.header['Host'] == 'healthcheck.wikimedia.org' and ts.client_request.get_uri() == '/ats-be' then
        ts.http.intercept(function()
            ts.say('HTTP/1.1 200 OK\r\n' ..
                   'Content-Length: 0\r\n' ..
                   'Cache-Control: no-cache\r\n\r\n')
        end)

        return 0
    end

    local cookie = ts.client_request.header['Cookie']

    if cookie then
        -- Equivalent to req.http.Cookie ~ "([sS]ession|Token)=" in VCL
        if string.match(cookie, '[sS]ession=') or string.find(cookie, 'Token=') then
            disable_coalescing()
        end
    end

    if ts.client_request.header['Authorization'] then
        disable_coalescing()
        no_cache_lookup()
    end

    -- This is to avoid some corner-cases and bugs as noted in T125938 , e.g.
    -- applayer gzip turning 500s into junk-response 503s, applayer gzipping
    -- CL:0 bodies into a 20 bytes gzip header, applayer compressing tiny
    -- outputs in general, etc.
    -- We have also observed Swift returning Content-Type: gzip with
    -- non-gzipped content, which confuses varnish-fe making it occasionally
    -- return 503.
    ts.client_request.header['Accept-Encoding'] = nil
end

function do_global_send_response()
    local cache_status = cache_status_to_string(ts.http.get_cache_lookup_status())
    ts.client_response.header['X-Cache-Int'] = HOSTNAME .. " " .. cache_status

    ts.client_response.header['X-ATS-Timestamp'] = os.time()

    if ts.client_response.header['Set-Cookie'] then
        -- At the frontend layer we do have measures in place to ensure that,
        -- regardless of what the origin says, Set-Cookie responses are never
        -- cached. To err on the side of caution and to match what Varnish
        -- backends used to do, override Cache-Control for Set-Cookie responses
        -- here too. T256395
        ts.client_response.header['Cache-Control'] = 'private, max-age=0, s-maxage=0'
    end

    return 0
end

function do_not_cache()
    ts.http.set_server_resp_no_store(1)
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
        vary = vary:lower()

        -- Vary:Cookie and Cookie ~ "([sS]ession|Token)="
        if string.find(vary, 'cookie') and (string.match(cookie, '[sS]ession=') or string.find(cookie, 'Token=')) then
            return true
        end
    end

    return false
end

function log_set_cookie_response()
    -- Log Set-Cookie responses that look cacheable
    local cache_control = ts.server_response.header['Cache-Control'] or "-"

    if string.find(cache_control, "private") or string.find(cache_control, "no%-cache") or string.find(cache_control, "no%-store") then
        -- Looks uncacheable
        return
    end

    -- This should never happen, log the fact that an origin server
    -- sent a Set-Cookie response claiming that it can be cached
    local request_id = ts.server_response.header['X-Request-Id'] or "-"
    local server = ts.server_response.header['Server'] or "-"
    local host = ts.client_request.header['Host'] or "-"
    local msg = "Cacheable object with Set-Cookie found! bereq.url: " .. ts.client_request.get_uri() ..
                " Host: " .. host ..
                " Cache-Control: " .. cache_control ..
                " Set-Cookie: " .. ts.server_response.header['Set-Cookie'] ..
                " X-Request-Id: " .. request_id ..
                " Server: " .. server

    if not string.find(host, "wikimedia.org") or host == "meta.wikimedia.org" or host == "commons.wikimedia.org" then
        -- Send violations for wikis/meta/commons to syslog
        ts.error(msg)
    end
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

    -- Temporary workaround for T255368, to be removed once
    -- https://github.com/apache/trafficserver/issues/6907 is fixed in our
    -- packages
    if response_status == 304 then
        ts.server_response.header['Transfer-Encoding'] = nil
    end

    -- Cap TTL of cacheable 404 responses to 10 minutes
    if response_status == 404 and ts.server_response.is_cacheable() and ts.server_response.get_maxage() > 600 then
        ts.server_response.header['Cache-Control'] = 's-maxage=600'
    end

    ----------------------------------------------------------
    -- Avoid caching responses that might get cached otherwise
    ----------------------------------------------------------
    local content_length = ts.server_response.header['Content-Length']
    local cookie = ts.client_request.header['Cookie']
    local vary = ts.server_response.header['Vary']

    if ts.server_response.header['Set-Cookie'] then
        log_set_cookie_response()
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

function do_global_send_request()
    -- Leave the hook defined but empty to avoid trafficserver.service restarts
    -- in the likely event that it becomes useful again in the future. See
    -- https://gerrit.wikimedia.org/r/#/c/operations/puppet/+/577551/
end
