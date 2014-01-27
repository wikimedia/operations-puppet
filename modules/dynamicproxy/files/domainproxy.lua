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
-- Gets domain name, figures out instance name from it, and routes there

local redis = require 'resty.redis'
local red = redis:new()
red:set_timeout(1000)

red:connect('127.0.0.1', 6379)

local frontend = ngx.re.match(ngx.var.http_host, "^([^:]*)")[1]

local backend = red:srandmember('frontend:' .. frontend)

if backend == ngx.null then
    -- Handle frontends wihout any configuration in them
    ngx.exit(404)
end

ngx.var.backend = backend
ngx.var.vhost = frontend
