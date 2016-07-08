class gerrit::proxy(
    $host         = $::gerrit::host,
    $ssl_cert     = $::gerrit::sslhost,
    $ssl_cert_key = $::gerrit::proxy::ssl_cert,
    ) {

    $ssl_settings = ssl_ciphersuite('apache', 'compat', true)

    apache::site { $host:
        content => template('gerrit/gerrit.wikimedia.org.erb'),
    }

    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::ssl

    include ::apache::mod::headers
}
