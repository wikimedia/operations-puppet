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

-- A mapping from backend name to host and port, where eligible backends are
-- split into disjoint "scopes" by Host header.
local debug_maps = {
    scopes = {
        {
            name = "pretrain",
            -- As of now, only testwiki is served from mw-pretrain.
            hosts = { ["test.wikipedia.org"] = true },
            backends = {
                ["k8s-mw-pretrain"]       = { host = "mw-pretrain.discovery.wmnet", port = 30443 },
                ["k8s-mw-pretrain-eqiad"] = { host = "mw-pretrain.svc.eqiad.wmnet", port = 30443 },
                ["k8s-mw-pretrain-codfw"] = { host = "mw-pretrain.svc.codfw.wmnet", port = 30443 },
            },
        },
    },
    default = {
        name = "default",
        backends = {
            ["k8s-mwdebug"]               = { host = "mwdebug.discovery.wmnet",      port = 4444 },
            ["k8s-mwdebug-eqiad"]         = { host = "mwdebug.svc.eqiad.wmnet",      port = 4444 },
            ["k8s-mwdebug-codfw"]         = { host = "mwdebug.svc.codfw.wmnet",      port = 4444 },
            ["k8s-mwdebug-next"]          = { host = "mwdebug-next.discovery.wmnet", port = 4453 },
            ["k8s-mwdebug-next-eqiad"]    = { host = "mwdebug-next.svc.eqiad.wmnet", port = 4453 },
            ["k8s-mwdebug-next-codfw"]    = { host = "mwdebug-next.svc.codfw.wmnet", port = 4453 },
            ["k8s-mw-experimental-eqiad"] = { host = "mw-experimental.eqiad.wmnet",  port = 4456 },
            ["k8s-mw-experimental-codfw"] = { host = "mw-experimental.codfw.wmnet",  port = 4456 },
            ["k8s-mw-parsoid-eqiad"]      = { host = "mw-parsoid.eqiad.wmnet",       port = 4452 },
            ["k8s-mw-parsoid-codfw"]      = { host = "mw-parsoid.codfw.wmnet",       port = 4452 },
        },
    },
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

    -- For rest.php, only allow debug remapping for mw-experimental and mw-parsoid.
    -- TODO: This is a bandaid. Please remove this block once XWD is properly supported by REST gateway, see T428909
    local orig_path = ts.client_request.get_uri() or ""
    if (string.match(orig_path, "^/w/rest%.php/") or string.match(orig_path, "^/w/rest%.php$")) and
        not string.match(backend, "^k8s%-mw%-experimental") and
        not string.match(backend, "^k8s%-mw%-parsoid") then
        return TS_LUA_REMAP_NO_REMAP
    end

    local debug_map = debug_maps.default
    local host = ts.client_request.header["Host"]
    if host ~= nil then
        -- Pick the first scope that matches the Host header.
        for _, v in ipairs(debug_maps.scopes) do
            if v.hosts ~= nil and v.hosts[host] then
                debug_map = v
                break
            end
        end
    end

    local target = debug_map.backends[backend]
    if target then
        ts.client_request.set_url_host(target.host)
        ts.client_request.set_url_port(target.port)

        -- Skip the cache if XWD is valid
        ts.http.config_int_set(TS_LUA_CONFIG_HTTP_CACHE_HTTP, 0)

        return TS_LUA_REMAP_DID_REMAP_STOP
    else
        ts.http.set_resp(400, "x-wikimedia-debug-routing: no match found for the backend specified in X-Wikimedia-Debug (scope: " .. debug_map.name .. ")")
        return TS_LUA_REMAP_NO_REMAP_STOP
    end
end
