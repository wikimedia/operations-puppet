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
