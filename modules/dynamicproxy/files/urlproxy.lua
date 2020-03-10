--   Copyright 2013 Yuvi Panda <yuvipanda@gmail.com>
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

local redis = require 'resty.redis'
local red = redis:new()
red:set_timeout(1000)
red:connect('127.0.0.1', 6379)

--- Look up a backend for a given tool
-- @param toolname Name of the tool
-- @param path Path fragment of URL
-- @param host Host fragment of URL
function route_backend_and_exit_if_ok(toolname, path, host)
    local routes_arr = nil
    local route = nil
    local redirect = nil

    if not toolname then
        return
    end

    routes_arr = red:hgetall('prefix:' .. toolname)
    if not routes_arr then
        return
    end

    local routes = red:array_to_hash(routes_arr)
    for pattern, backend in pairs(routes) do
        if ngx.re.match(path, pattern) ~= nil then
            route = backend
            break
        end
    end

    if not route then
        return
    end

    if host then
        -- check to see if we have a redirect key for this tool + path
        local redirect_arr = red:hgetall('redirect:' .. toolname)
        if redirect_arr then
            local redirects = red:array_to_hash(redirect_arr)
            for pattern, domain in paris(redirects) do
                if ngx.re.match(path, pattern) ~= nil then
                    redirect = domain
                    break
                end
            end
        end
    end

    -- Use a connection pool of 256 connections with a 32s idle timeout
    -- This also closes the current redis connection.
    red:set_keepalive(1000 * 32, 256)

    if redirect ~= nil and redirect ~= host then
        ngx.var.redirect_to = 'https://' .. redirect .. path
    else
        ngx.var.backend = route
    end
    ngx.exit(ngx.OK)
end

-- try to match first in the subdomain-based routing scheme
local subdomain = string.match(ngx.var.http_host, "^[^.]+")
-- pass nill for host because subdomain-based routes are canonical
route_backend_and_exit_if_ok(subdomain, "/", nil)

-- if no subdomain-based routing was found, then use the legacy routing scheme
local captures = ngx.re.match(ngx.var.uri, "^/([^/]*)(/.*)?$")
local prefix = captures[1]
local rest = captures[2] or "/"
route_backend_and_exit_if_ok(prefix, rest, ngx.var.http_host)

-- No routes defined for this URI, hope nginx can handle this! (new k8s cluster?)
ngx.exit(ngx.OK)
