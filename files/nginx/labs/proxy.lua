-- Lua file run by nginx that does appropriate routing
-- Gets domain name, figures out instance name from it, and routes there
local domain = ngx.re.match(ngx.var.http_host, "^([^:]*)")[1]
local instance_name = ngx.re.match(domain, "([^.]+)\.proxy\.wmflabs\.org$")[1]

ngx.var.backend = "http://" .. instance_name
ngx.var.vhost = instance_name
