function read_config()
    local configfile = ts.get_config_dir() .. "/lua/tls.lua.conf"

    ts.debug("Reading " .. configfile)

    dofile(configfile)
    assert(lua_websocket_support ~= nil, "lua_websocket_support not set by " .. configfile)

    ts.debug("read_config() returning " .. tostring(lua_websocket_support))

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

    local x_tls_prot = 'h1'
    local x_tls_sess = 'new'
    local x_tls_vers = ssl_protocol
    local x_tls_keyx = ssl_curve
    local x_tls_auth = ssl_cipher
    local x_tls_ciph = x_tls_auth

    for k,v in pairs(client_stack) do
        if string.match(v, "h2") then
            http2 = 1
            x_tls_prot = 'h2'
            break
        end
    end

    if ssl_reused == 1 then
        x_tls_sess = 'reused'
    end

    x_tls_ciph = string.gsub(x_tls_ciph, "^DHE%-RSA%-", "")
    x_tls_ciph = string.gsub(x_tls_ciph, "^ECDHE%-ECDSA%-", "")
    x_tls_ciph = string.gsub(x_tls_ciph, "^ECDHE%-RSA%-", "")

    -- Starting with TLSv1.3, CHACHA20-POLY1305 will be renamed into
    -- CHACHA20-POLY1305-SHA256. Do the renaming now in Lua to avoid stats
    -- skew later on
    x_tls_ciph = string.gsub(x_tls_ciph, "^CHACHA20%-POLY1305$", "CHACHA20-POLY1305-SHA256")

    if string.match(x_tls_auth, "^ECDHE%-RSA") then
        x_tls_auth = "RSA"
    elseif string.match(x_tls_auth, "^DHE%-RSA") then
        x_tls_auth = "RSA"
        x_tls_keyx = "DHE"
    else
        x_tls_auth = "ECDSA"
    end

    ts.server_request.header['X-Analytics-TLS'] = string.format("tls: vers=%s;keyx=%s;auth=%s;ciph=%s;prot=%s;sess=%s", x_tls_vers, x_tls_keyx, x_tls_auth, x_tls_ciph, x_tls_prot, x_tls_sess)

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
