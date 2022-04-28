-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

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
    if x_tls_vers == "TLSv1.3" then
        -- Every TLSv1.3 cipher begins with TLS_
        x_tls_ciph = string.gsub(x_tls_ciph, "^TLS_", "")
        -- TLSv1.3 uses _ instead of - as a separator
        x_tls_ciph = string.gsub(x_tls_ciph, "_", "-")
    end

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

    ts.server_request.header['X-Analytics-TLS'] = string.format("vers=%s;keyx=%s;auth=%s;ciph=%s;prot=%s;sess=%s", x_tls_vers, x_tls_keyx, x_tls_auth, x_tls_ciph, x_tls_prot, x_tls_sess)

    header_content = string.format("H2=%i; SSR=%i; SSL=%s; C=%s; EC=%s;",
                                   http2, ssl_reused, ssl_protocol, ssl_cipher, ssl_curve)
    ts.server_request.header['X-Client-IP'] = client_ip
    ts.server_request.header['X-Client-Port'] = client_port
    ts.server_request.header['X-Connection-Properties'] = header_content
    ts.server_request.header['X-Forwarded-Proto'] = 'https'
end

function do_global_send_response()
    -- This header is used internally for analytics purposes and should not be
    -- sent to clients. See https://wikitech.wikimedia.org/wiki/X-Analytics and
    -- https://phabricator.wikimedia.org/T196558
    ts.client_response.header['X-Analytics'] = nil

    -- Only serve debug HTTP headers when X-Wikimedia-Debug is present. T210484
    if ts.client_request.header['X-Wikimedia-Debug'] == nil then
        ts.client_response.header['Backend-Timing'] = nil
        ts.client_response.header['X-ATS-Timestamp'] = nil
        -- X-Cache-Status is used by WikibaseQualityConstraints
        --ts.client_response.header['X-Cache-Status'] = nil
        ts.client_response.header['X-Envoy-Upstream-Service-Time'] = nil
        ts.client_response.header['X-OpenStack-Request-ID'] = nil
        ts.client_response.header['X-Powered-By'] = nil
        ts.client_response.header['X-Request-Id'] = nil
        ts.client_response.header['X-Timestamp '] = nil
        ts.client_response.header['X-Trans-Id'] = nil
        ts.client_response.header['X-Varnish'] = nil
    end
end
