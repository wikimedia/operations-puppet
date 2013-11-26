-- Lua file run by nginx that does appropriate routing

local redis = require 'resty.redis'
local red = redis:new()
red:set_timeout(1000)

red:connect('127.0.0.1', 6379)

local captures = ngx.re.match(ngx.var.uri, "^/([^/]*)(/.*)?")

if captures == ngx.null then
   ngx.exit(404)
end

local prefix = captures[1]
local rest = captures[2]

if rest == nil then
   -- Ideally wer redirect here, to prevent fragmentation
   rest = '/'
end

local routes_arr = red:hgetall('prefix:' .. prefix)

if routes_arr == ngx.null then
    ngx.exit(404)
end

local routes = red:array_to_hash(routes_arr)

for pattern, backend in pairs(routes) do
   if ngx.re.match(rest, pattern) ~= nil then
      ngx.var.backend = backend
      ngx.exit(ngx.OK)
   end
end

ngx.exit(404) -- We didn't find any matches!
