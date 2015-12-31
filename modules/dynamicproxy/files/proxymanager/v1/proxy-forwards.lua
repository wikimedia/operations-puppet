-- Copyright 2016 Tim Landscheidt
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Connect to Redis database.
local redis = require('resty.redis')
local red = redis:new()
red:set_timeout(1000)
red:connect('127.0.0.1', 6379)

-- Get list of proxy entries.
local proxy_entries = red:keys(ngx.var.proxymanager_proxy_forward_redis_prefix .. '*')

-- Use a connection pool of 16 connections with a 32 s idle timeout.
-- This also closes the current Redis connection.
red:set_keepalive(1000 * 32, 16)

if ngx.req.get_method() == 'GET' then
   local json = require('json')

   local result = {}
   for i, v in ipairs(proxy_entries) do
      table.insert(result, string.sub(v, string.len(ngx.var.proxymanager_proxy_forward_redis_prefix) + 1))
   end

   ngx.header['Content-Type'] = 'application/json'
   ngx.say(json.encode(result))
   ngx.exit(ngx.HTTP_OK)
else
   ngx.exit(ngx.HTTP_NOT_ALLOWED)
end
