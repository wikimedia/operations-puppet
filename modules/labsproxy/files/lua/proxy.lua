-- Lua file run by nginx that does appropriate routing
-- Gets domain name, figures out instance name from it, and routes there
local frontend = ngx.re.match(ngx.var.http_host, "^([^:]*)")[1]
local instance_match = ngx.re.match(frontend, "(\\d+)?\\.?([^.]+)\\.proxy\\.wmflabs\\.org$")

local instance_port = 80
local instance_name = instance_match[2]

if instance_match[1] ~= nil then
        instance_port = instance_match[1]
end

ngx.var.backend = "http://" .. instance_name .. ":" .. instance_port
ngx.var.vhost = instance_name
