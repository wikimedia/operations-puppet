-- Connect to Redis database.
local redis = require('resty.redis')
local red = redis:new()
red:set_keepalive(1000 * 32, 256)
red:set_timeout(1000)
red:connect('127.0.0.1', 6379)

-- Return list of proxy entries.
local json = require('json')
ngx.header['Content-Type'] = 'application/json'
local proxy_entries = red:keys('prefix:*')
local result = {}
for k, v in pairs(proxy_entries) do
    result[string.sub(v, string.len('prefix:') + 1)] = {['status']='active'}
end
ngx.say(json.encode(result))
