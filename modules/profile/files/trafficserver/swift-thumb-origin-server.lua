--[[
  By default, upload.wikimedia.org requests are remapped to swift-rw. We are
  however able to serve thumb requests from both eqiad and codfw. Set swift-ro
  as the origin server for thumb traffic.
]]

function set_origin_server(uri)
	if uri:match("^/+[^/]+/[^/]+/thumb/") then
		ts.client_request.set_url_scheme('https')
		ts.client_request.set_url_host('swift-ro.discovery.wmnet')
	end
end

function remap_hook()
	local uri = ts.client_request.get_uri() or ''
	set_origin_server(uri)
end

function do_remap()
	ts.hook(TS_LUA_HOOK_POST_REMAP, remap_hook)
	return 0
end
