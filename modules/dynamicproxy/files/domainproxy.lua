--   Copyright 2020 Wikimedia Foundation and contributors
--
--   Licensed under the Apache License, Version 2.0 (the "License");
--   you may not use this file except in compliance with the License.
--   You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.
--
-- Lua file run by nginx that does appropriate routing
-- Gets domain name, figures out instance name from it, and routes there

local redis = require 'resty.redis'
local red = redis:new()
red:set_timeout(1000)
red:connect('127.0.0.1', 6379)

--- Lookup backend host and port to proxy
-- @parm hostname Hostname to lookup
function lookup_backend(hostname)
    return red:srandmember('frontend:' .. hostname)
end

function redis_shutdown()
    -- Use a connection pool of 256 connections with a 32s idle timeout
    -- This also closes the current redis connection.
    red:set_keepalive(1000 * 32, 256)
end

if ngx.var.http_host == nil then
    -- missing HOST: header from client. We can't figure out where to route
    -- the request without it, so tell the client this was a bad request.
    return ngx.exit(400)
end

local fqdn = ngx.re.match(ngx.var.http_host, "^([^:]*)")[1]
local backend = lookup_backend(fqdn)

if backend ~= ngx.null then
    -- Set vars to be used by ngix to proxy to the located service
    ngx.var.backend = backend
    ngx.var.vhost = fqdn
    redis_shutdown()
    return ngx.exit(ngx.OK)
end

-- Check for a wildcard.
local wildcard_match = ngx.re.match(ngx.var.http_host, "^[^:.]+\\.([^:]*)")
if wildcard_match then
    local wildcard_backend = lookup_backend("*." .. wildcard_match[1])

    if wildcard_backend ~= ngx.null then
        ngx.var.backend = wildcard_backend
        ngx.var.vhost = fqdn
        redis_shutdown()
        return ngx.exit(ngx.OK)
    end
end

-- No configured backend found for this FQDN.
-- Next steps are either:
-- * Redirect to a matching host in the wmcloud.org domain
-- * Return a 404 response
local re_wmflabs = "\\.wmflabs\\.org$"
if ngx.re.match(fqdn, re_wmflabs) then
    -- Check for a .wmcloud.org version of the hostname
    local wmcloud_host = ngx.re.sub(fqdn, re_wmflabs, ".wmcloud.org")
    if lookup_backend(wmcloud_host) ~= ngx.null then
        -- Redirect to .wmcloud.org hostname
        redis_shutdown()
        return ngx.redirect("https://" .. wmcloud_host .. ngx.var.request_uri, ngx.HTTP_MOVED_PERMANENTLY)
    end
end

-- we don't know where to go so return a 404 response
redis_shutdown()
return ngx.exit(404)
