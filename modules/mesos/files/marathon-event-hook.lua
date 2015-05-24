-- 
--

local redis = require 'resty.redis'
local cjson = require 'cjson'
local red = redis:new()
red:set_timeout(1000)

red:connect('127.0.0.1', 6379)

ngx.req.read_body()
local raw_event_data = ngx.req.get_body_data()

local data = cjson.decode(raw_event_data)

ngx.log(ngx.ERR, raw_event_data)
