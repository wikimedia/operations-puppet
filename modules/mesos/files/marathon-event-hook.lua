-- 
--

local redis = require 'resty.redis'
local red = redis:new()
red:set_timeout(1000)

red:connect('127.0.0.1', 6379)

ngx.req.read_body()
local raw_event_data = ngx.req.get_body_data()


ngx.log(ngx.ERR, raw_event_data)


-- Use a connection pool of 256 connections with a 32s idle timeout
-- This also closes the current redis connection.
red:set_keepalive(1000 * 32, 256)
