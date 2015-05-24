-- 
--

local redis = require 'resty.redis'
local json = require 'cjson'
local red = redis:new()
red:set_timeout(1000)

red:connect('127.0.0.1', 6379)

ngx.req.read_body()
local raw_event_data = ngx.req.get_body_data()

local data = json.decode(raw_event_data)

if data['taskStatus'] == 'TASK_RUNNING' then
	key = 'prefix:' .. data['appId']:gsub('/', '', 1)
    host = data['host']
	port = data['ports'][1]
    proxy_url = 'http://' .. host .. ':' .. tostring(port)
	red:sadd(key, proxy_url)
end


-- Use a connection pool of 256 connections with a 32s idle timeout
-- This also closes the current redis connection.
red:set_keepalive(1000 * 32, 256)
