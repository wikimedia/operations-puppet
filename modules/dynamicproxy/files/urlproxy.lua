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

local captures = ngx.re.match(ngx.var.uri, "^/([^/]*)(/.*)?")

if captures == ngx.null then
   -- This would actually never happen, I'd think.
   ngx.exit(500)
end

local prefix = captures[1]
local rest = captures[2]
local routes_arr = red:hgetall('prefix:' .. prefix)

if routes_arr ~= ngx.null then
   if rest == nil then
      -- Handle cases when there is nothing at all after the prefix
      -- if we get /example, we will redirect to /example/
      return ngx.redirect('/'..prefix..'/', ngx.HTTP_MOVED_PERMANENTLY)
   end

   -- there is a registered prefix, try to find a matching
   -- pattern and send the client there if there is.

   local routes = red:array_to_hash(routes_arr)
   for pattern, backend in pairs(routes) do
      if ngx.re.match(rest, pattern) ~= nil then
         ngx.var.backend = backend
         ngx.exit(ngx.OK)
      end
   end

end

if rest ~= nil then
   -- the URI had a slash, so the user clearly expected /something/
   -- there.  Fail because there is no registered webservice.
   ngx.exit(503)
end

-- No routes defined for this uri, try the default (admin) prefix instead
rest = '/' .. prefix
routes_arr = red:hgetall('prefix:admin')
if routes_arr ~= ngx.null then
   local routes = red:array_to_hash(routes_arr)
   for pattern, backend in pairs(routes) do
      if ngx.re.match(rest, pattern) ~= nil then
         ngx.var.backend = backend
         ngx.exit(ngx.OK)
      end
   end
end

-- Oh noes!  Even the admin prefix is dead!
-- Fall back to the static site
ngx.var.backend = ''
ngx.exit(ngx.OK)

