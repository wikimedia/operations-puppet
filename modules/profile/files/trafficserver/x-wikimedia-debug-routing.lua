-- SPDX-License-Identifier: Apache-2.0
-- Route requests to a set of un-pooled application servers that are reserved
-- for debugging, based on the value of the X-Wikimedia-Debug header. The
-- X-Wikimedia-Debug header is made up of semicolon-separated fields. Each
-- field may consist of either an attribute name or an attribute=value pairs.
-- The code below extracts the value of the 'backend' attribute. For
-- backward-compatibility, if the header does not contain a well-formed
-- 'backend' attribute, then the entire header is used as the backend value.
--
-- See https://wikitech.wikimedia.org/wiki/X-Wikimedia-Debug

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

local function add_or_replace_cookie(name, value)
    local cookie = ts.client_request.header.Cookie
    local to_add = string.format("%s=%s", name, value)
    local to_search = string.format("%s=[^;]+", name)
    if cookie and cookie ~= "" then
        -- Do check if there is a cookie of the same name
        cookie, count = cookie:gsub(to_search, to_add)
        -- If not, just add it.
        if count == 0 then
            cookie = cookie .. ";" .. to_add
        end
    else
        cookie = to_add
    end
    ts.client_request.header.Cookie = cookie
end

-- A mapping from backend name to host and port.
local debug_map = {
    ["k8s-mwdebug"]             = { host = "mwdebug.discovery.wmnet",      port = 4444 },
    ["1"]                       = { host = "mwdebug1001.eqiad.wmnet",      port =  443 },
    ["mwdebug1001.eqiad.wmnet"] = { host = "mwdebug1001.eqiad.wmnet",      port =  443 },
    ["mwdebug1002.eqiad.wmnet"] = { host = "mwdebug1002.eqiad.wmnet",      port =  443 },
    ["mwdebug2001.codfw.wmnet"] = { host = "mwdebug2001.codfw.wmnet",      port =  443 },
    ["mwdebug2002.codfw.wmnet"] = { host = "mwdebug2002.codfw.wmnet",      port =  443 },
    ["k8s-mwdebug-eqiad"]       = { host = "mwdebug.svc.eqiad.wmnet",      port = 4444 },
    ["k8s-mwdebug-codfw"]       = { host = "mwdebug.svc.codfw.wmnet",      port = 4444 },
    ["k8s-mwdebug-next"]        = { host = "mwdebug-next.discovery.wmnet", port = 4453 },
    ["k8s-mwdebug-next-eqiad"]  = { host = "mwdebug-next.svc.eqiad.wmnet", port = 4453 },
    ["k8s-mwdebug-next-codfw"]  = { host = "mwdebug-next.svc.codfw.wmnet", port = 4453 },
}

function do_remap()
    local xwd = ts.client_request.header['X-Wikimedia-Debug']
    if not xwd then
        -- Stop immediately if no XWD header has been specified
        return TS_LUA_REMAP_NO_REMAP
    end

    local backend = string.match(xwd, 'backend=([%a%d%.-]+)')
    -- For backward-compatibility, if the header does not contain a
    -- well-formed 'backend' attribute, then the entire header is used as
    -- the backend value
    if not backend then
        backend = xwd
    end

    local target = debug_map[backend]
    if target then
        ts.client_request.set_url_host(target.host)
        ts.client_request.set_url_port(target.port)

        -- Skip the cache if XWD is valid
        ts.http.config_int_set(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)

        return TS_LUA_REMAP_DID_REMAP_STOP
    else
        ts.http.set_resp(400, "x-wikimedia-debug-routing: no match found for the backend specified in X-Wikimedia-Debug")
        return TS_LUA_REMAP_NO_REMAP_STOP
    end
end
