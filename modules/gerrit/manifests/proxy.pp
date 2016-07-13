class gerrit::proxy($host = $::gerrit::host, $lets_encrypt = true) {

    $ssl_settings = ssl_ciphersuite('apache', 'compat', true)

    if $lets_encrypt {
        $ssl_cert_file = '/etc/acme/cert/gerrit.crt'
        $ssl_cert_chain_file = '/etc/acme/cert/gerrit.chain.crt'
        $ssl_cert_key_file = '/etc/acme/key/gerrit.key'
    } else {
        $ssl_cert_file = "/etc/ssl/localcerts/${host}.crt"
        $ssl_cert_chain_file = "/etc/ssl/localcerts/${host}.chain.crt"
        $ssl_cert_key_file = "/etc/ssl/private/${host}.key"
    }

    apache::site { $host:
        content => template('gerrit/gerrit.wikimedia.org.erb'),
    }

    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::ssl

    include ::apache::mod::headers
}
