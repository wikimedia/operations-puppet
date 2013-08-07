-- Lua file run by nginx that does appropriate routing
-- Gets domain name, figures out instance name from it, and routes there

local redis = require 'resty.redis'
local red = redis:new()
red.set_timeout(1000)

red:connect('127.0.0.1', 6379)

local frontend = ngx.re.match(ngx.var.http_host, "^([^:]*)")[1]
local domain = ngx.re.match(frontend, "([^.]+)\\.proxy\\.wmflabs\\.org$")[1]

local backend = red:srandmember('frontend:' .. domain)[1]

ngx.var.backend = backend
ngx.var.vhost = domain
