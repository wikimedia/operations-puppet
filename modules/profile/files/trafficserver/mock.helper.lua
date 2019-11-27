_G.ts = {}
_G.ts.get_config_dir = function() return "/tmp" end
_G.ts.error = function(msg) return true end
_G.ts.debug = function(msg) return true end
_G.dofile = function()
    lua_hostname = "pass-test-hostname"
    lua_websocket_support = false
end
