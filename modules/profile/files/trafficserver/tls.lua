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
    ts.server_request.header['Connection'] = 'close'
    -- Avoid propagating Proxy-Connection to varnish-fe and ats-be
    ts.server_request.header['Proxy-Connection'] = nil
end
