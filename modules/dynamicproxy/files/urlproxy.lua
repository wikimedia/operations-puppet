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
local rest = captures[2] or "/"
local routes_arr = nil
local route = nil

routes_arr = red:hgetall('prefix:' .. prefix)

if routes_arr then
    local routes = red:array_to_hash(routes_arr)
    for pattern, backend in pairs(routes) do
        if ngx.re.match(rest, pattern) ~= nil then
            route = backend
            break
        end
    end
end

if not route then
    -- No routes defined for this URI, hope nginx can handle this! (new k8s cluster?)
    ngx.exit(ngx.OK)
end

-- Use a connection pool of 256 connections with a 32s idle timeout
-- This also closes the current redis connection.
red:set_keepalive(1000 * 32, 256)

ngx.var.backend = route
ngx.exit(ngx.OK)
