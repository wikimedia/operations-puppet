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

local captures = ngx.re.match(ngx.var.uri, "^/([^/]*)(/.*)?$")

local prefix = captures[1]
local rest = captures[2] or nil
local routes_arr = nil
local route = nil

routes_arr = red:hgetall('prefix:' .. prefix)

if routes_arr then
    local routes = red:array_to_hash(routes_arr)
    for pattern, backend in pairs(routes) do
        if ngx.re.match(rest, pattern) ~= nil then
            if string.match(backend, '://') then
                route = backend
            else
                -- Temp hack since portgrabber did not
                -- specify the http:// protocol by default
                route = 'http://' .. backend
            end
            break
        end
    end
end

-- if a route is found and there was nothing (no trailing slash)
-- then the url is of form tools.wmflabs.org/tool. If we just let
-- that be, lighttpd will redirect it to a http://tools.wmflabs.org/tool
-- even if the original request was https. So let's do the redirect ourself
-- making sure it keeps the appropriate protocol. This doesn't cover all
-- the ways lighttpd can silently strip off https, but hey it covers the most
-- common one :) See https://phabricator.wikimedia.org/T66627
if route and rest ~= nil then
    return ngx.redirect(ngx.var.request_uri .. '/')
end

if not route then
    -- No routes defined for this uri, try the default (admin) prefix instead
    rest = ngx.var.uri
    routes_arr = red:hgetall('prefix:admin')
    if routes_arr then
        local routes = red:array_to_hash(routes_arr)
        for pattern, backend in pairs(routes) do
            if ngx.re.match(rest, pattern) then
                route = backend
                break
            end
        end
    end
end

-- Use a connection pool of 256 connections with a 32s idle timeout
-- This also closes the current redis connection.
red:set_keepalive(1000 * 32, 256)

if route then
    ngx.var.backend = route
    ngx.exit(ngx.OK)
else
    -- Oh noes!  Even the admin prefix is dead!
    -- Fall back to the static site
    if rest then
        -- the URI had a slash, so the user clearly expected /something/
        -- there.  Fail because there is no registered webservice.
        ngx.exit(503)
    else
        ngx.var.backend = ''
        ngx.exit(ngx.OK)
    end
end

