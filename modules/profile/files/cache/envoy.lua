-- SPDX-License-Identifier: Apache-2.0
function envoy_on_request(request_handle)
    local connection = request_handle:connection()
    local stream_info = request_handle:streamInfo()
    local ssl_info = connection:ssl()
    local client_ip, client_port = string.match(stream_info:downstreamDirectRemoteAddress(), "^%[?([%x.:]+)%]?:(%d+)$")
    -- envoy doesn't expose if a TLS session is being reused or not
    local ssl_reused = "2"
    local x_tls_sess = 'unknown'
    -- envoy doesn't expose the eliptic curve used
    local ssl_curve = 'UNKNOWN'
    local ssl_cipher = ssl_info:ciphersuiteString()
    local ssl_version = ssl_info:tlsVersion()
    local http2 = 0
    local x_tls_prot = 'h1'
    local x_tls_vers = ssl_version
    local x_tls_ciph = ssl_cipher
    local x_tls_keyx = ssl_curve
    local x_tls_auth = x_tls_ciph

    if stream_info:protocol() == "HTTP/2" then
        http2 = 1
        x_tls_prot = 'h2'
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

    request_handle:headers():add('X-Analytics-TLS', string.format("vers=%s;keyx=%s;auth=%s;ciph=%s;prot=%s;sess=%s", x_tls_vers, x_tls_keyx, x_tls_auth, x_tls_ciph, x_tls_prot, x_tls_sess))
    request_handle:headers():add('X-Connection-Properties', string.format("H2=%i; SSR=%i; SSL=%s; C=%s; EC=%s;", http2, ssl_reused, ssl_version, ssl_cipher, ssl_curve))
    request_handle:headers():add('X-Client-IP', client_ip)
    request_handle:headers():add('X-Client-Port', client_port)

end

function envoy_on_response(response_handle)
    -- This header is used internally for analytics purposes and should not be
    -- sent to clients. See https://wikitech.wikimedia.org/wiki/X-Analytics and
    -- https://phabricator.wikimedia.org/T196558
    response_handle:headers():remove('X-Analytics')

    -- Only serve debug HTTP headers when X-Wikimedia-Debug is present. T210484
    if response_handle:headers():get('X-Wikimedia-Debug') == nil then
        response_handle:headers():remove('Backend-Timing')
        response_handle:headers():remove('X-ATS-Timestamp')
        response_handle:headers():remove('X-Envoy-Upstream-Service-Time')
        response_handle:headers():remove('X-Powered-By')
        response_handle:headers():remove('X-Request-Id')
        response_handle:headers():remove('X-Timestamp')
        response_handle:headers():remove('X-Trans-Id')
        response_handle:headers():remove('X-Varnish')
    end
end
