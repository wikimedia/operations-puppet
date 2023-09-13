--   Copyright 2020 Bryan Davis <bd808@wikimedia.org>
--   Copyright 2020 Arturo Borrero Gonzalez <aborrero@wikimedia.org>
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
-- @param path url URL
function route_backend_and_exit_if_ok(toolname, url)
    local routes_arr = nil
    local route = nil

    if not toolname then
        return
    end

    routes_arr = red:hgetall('prefix:' .. toolname)
    if not routes_arr then
        return
    end

    local routes = red:array_to_hash(routes_arr)
    for pattern, backend in pairs(routes) do
        if ngx.re.match(url, pattern) ~= nil then
            route = backend
            break
        end
    end

    if not route then
        return
    end

    -- Use a connection pool of 256 connections with a 32s idle timeout
    -- This also closes the current redis connection.
    red:set_keepalive(1000 * 32, 256)
    ngx.var.backend = route
    ngx.var.connection_error_document = '/.error/unreachable.html'
    ngx.exit(ngx.OK)
end

if ngx.var.http_host == nil then
    -- missing HOST: header from client. We can't figure out where to route
    -- the request without it, so tell the client this was a bad request.
    return ngx.exit(400)
end

local subdomain = string.match(ngx.var.http_host, "^[^.]+")
route_backend_and_exit_if_ok(subdomain, "/")

-- anything else, send it to k8s
ngx.exit(ngx.OK)
