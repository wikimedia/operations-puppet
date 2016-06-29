class gerrit::proxy(
    $host        = '',
    $ssl_cert    = 'ssl-cert-snakeoil',
    $ssl_cert_key= 'ssl-cert-snakeoil'
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
