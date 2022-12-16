-- SPDX-License-Identifier: Apache-2.0
core.register_fetches("xcps", function(txn)
    local ssl_reused = txn.f:ssl_fc_is_resumed()
    local ssl_protocol = txn.f:ssl_fc_protocol()
    local ssl_cipher = txn.f:ssl_fc_cipher()
    local ssl_curve = 'UNKNOWN'
    local http2 = 0

    if txn.f:fc_http_major() == 2 then
        http2 = 1
    end
    return string.format("H2=%i; SSR=%i; SSL=%s; C=%s; EC=%s;",
                          http2, ssl_reused, ssl_protocol, ssl_cipher, ssl_curve)
end)

core.register_fetches("analytics_tls", function(txn)
    local x_tls_vers = txn.f:ssl_fc_protocol()
    local x_tls_auth = txn.f:ssl_fc_cipher()
    local x_tls_ciph = x_tls_auth
    local x_tls_prot = 'h1'
    local x_tls_keyx = 'unknown'
    local x_tls_sess = 'new'

    if txn.f:fc_http_major() == 2 then
        x_tls_prot = 'h2'
    end

    if txn.f:ssl_fc_is_resumed() == 1 then
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

    return string.format("vers=%s;keyx=%s;auth=%s;ciph=%s;prot=%s;sess=%s", x_tls_vers, x_tls_keyx, x_tls_auth, x_tls_ciph, x_tls_prot, x_tls_sess)
end)
