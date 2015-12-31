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

-- Extract tool's name from URI.
local toolname = string.sub(ngx.var.uri, string.len('/v1/proxy-forwards/') + 1)

-- Connect to Redis database.
local redis = require('resty.redis')
local red = redis:new()
red:set_timeout(1000)
red:connect('127.0.0.1', 6379)

-- Require json module.
local json = require('json')

-- Access for "GET" requests is not restricted, so they are handled
-- first.
if ngx.req.get_method() == 'GET' then
   -- Retrieve database entry for prefix.
   local proxy_entries = red:hgetall(ngx.var.proxymanager_proxy_forward_redis_prefix .. toolname)
   if #proxy_entries == 0 then
      ngx.log(ngx.WARN, 'No proxy forward in database for ', toolname)
      ngx.exit(ngx.HTTP_NOT_FOUND)
   end

   -- Return result.
   ngx.header['Content-Type'] = 'application/json'
   ngx.say(json.encode(red:array_to_hash(proxy_entries)))
   ngx.exit(ngx.HTTP_OK)
end

-- Access for other methods is restricted to the referenced tool, so
-- query ident server.
local sock = ngx.socket.tcp()
sock:settimeout(5000)
local ok, err = sock:connect(ngx.var.remote_addr, 113)
if not ok then
   ngx.log(ngx.ERR, 'Failed to connect to ident server on ', ngx.var.remote_addr, ': ', err)
   ngx.exit(ngx.HTTP_UNAUTHORIZED)
end
sock:send(ngx.var.remote_port .. ',' .. ngx.var.server_port .. '\r\n')
local line, err, partial = sock:receive()
sock:close()
if not line then
   ngx.log(ngx.ERR, 'Failed to receive response from ident server on ', ngx.var.remote_addr, ': ', err)
   ngx.exit(ngx.HTTP_UNAUTHORIZED)
end
if line ~= ngx.var.remote_port .. ' , ' .. ngx.var.server_port .. ' : USERID : UNIX , UTF-8 :' .. ngx.var.proxymanager_labsproject_prefix .. toolname then
   ngx.log(ngx.ERR, 'Unauthorized attempt for ', toolname, ': ', line)
   ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- At this point the requester is authorized to manage the proxy
-- forward for the tool.
if ngx.req.get_method() == 'DELETE' then
   -- Delete proxy forward entry.
   red:del(ngx.var.proxymanager_proxy_forward_redis_prefix .. toolname)
   ngx.exit(ngx.HTTP_OK)
elseif ngx.req.get_method() == 'PUT' then
   -- Create/update proxy forward entry.
   ngx.req.read_body()
   local req_body = ngx.req.get_body_data()
   local new_proxy_forwards = json.decode(req_body)
   if not new_proxy_forwards then
      ngx.exit(ngx.HTTP_BAD_REQUEST)
   end
   for k, v in pairs(new_proxy_forwards) do
      red:hset(ngx.var.proxymanager_proxy_forward_redis_prefix .. toolname, k, v)
   end
   ngx.exit(ngx.HTTP_OK)
else
   ngx.exit(ngx.HTTP_NOT_ALLOWED)
end
