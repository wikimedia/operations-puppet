-- Lua file run by nginx that does appropriate routing

-- Sorted pairs, sorting based on length of key
-- From http://stackoverflow.com/a/15706820
function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function length_comparison(t, a, b)
   return a:len() > b:len()
end

local redis = require 'resty.redis'
local red = redis:new()
red:set_timeout(1000)

red:connect('127.0.0.1', 6379)

local captures = ngx.re.match(ngx.var.uri, "^/([^/]*)(/.*)?")

if captures == ngx.null then
   -- This would actually never happen, I'd think.
   ngx.exit(404)
end

local prefix = captures[1]
local rest = captures[2]

if rest == nil then
   -- Handle cases when there is nothing at all after the prefix
   -- if we get /example, we will treat it as /example/
   -- Ideally wer redirect here, to prevent fragmentation
   rest = '/'
end

local routes_arr = red:hgetall('prefix:' .. prefix)

if routes_arr == ngx.null then
   -- No routes defined for this
    ngx.exit(404)
end

local routes = red:array_to_hash(routes_arr)

for pattern, backend in spairs(routes, length_comparison) do
   if ngx.re.match(rest, pattern) ~= nil then
      ngx.var.backend = backend
      ngx.exit(ngx.OK)
   end
end

ngx.exit(404) -- We didn't find any matches!
