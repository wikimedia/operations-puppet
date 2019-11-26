function read_config()
    local configfile = ts.get_config_dir() .. "/lua/tls.lua.conf"

    ts.error("Reading " .. configfile)

    dofile(configfile)
    assert(lua_websocket_support ~= nil, "lua_websocket_support not set by " .. configfile)

    ts.error("read_config() returning " .. tostring(lua_websocket_support))

    return lua_websocket_support
end

local WEBSOCKET_SUPPORT = read_config()

function get_websocket_support()
    return WEBSOCKET_SUPPORT
end

function do_global_send_request()
    local ssl_reused = ts.client_request.get_ssl_reused()
    local ssl_protocol = ts.client_request.get_ssl_protocol()
    local ssl_cipher = ts.client_request.get_ssl_cipher()
    local ssl_curve = ts.client_request.get_ssl_curve()
    local client_stack = {ts.http.get_client_protocol_stack()}
    local http2 = 0
    local client_ip, client_port, client_family = ts.client_request.client_addr.get_addr()
    for k,v in pairs(client_stack) do
        if string.match(v, "h2") then
            http2 = 1
            break
        end
    end
    header_content = string.format("H2=%i; SSR=%i; SSL=%s; C=%s; EC=%s;",
                                   http2, ssl_reused, ssl_protocol, ssl_cipher, ssl_curve)
    ts.server_request.header['X-Client-IP'] = client_ip
    ts.server_request.header['X-Connection-Properties'] = header_content
    ts.server_request.header['X-Forwarded-Proto'] = 'https'
    -- Avoid propagating Proxy-Connection to varnish-fe and ats-be
    ts.server_request.header['Proxy-Connection'] = nil

    if get_websocket_support() and ts.client_request.header['Upgrade'] and ts.client_request.header['Connection'] then
        ts.server_request.header['Upgrade'] = ts.client_request.header['Upgrade']
        ts.server_request.header['Connection'] = ts.client_request.header['Connection']
    else
        ts.server_request.header['Connection'] = 'close'
    end
end
