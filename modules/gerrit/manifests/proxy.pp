class gerrit::proxy($host        = '',
$ssl_cert    = '',
$ssl_cert_key= '') {

    $ssl_settings = ssl_ciphersuite('apache', 'compat', true)

    apache::site { 'gerrit.wikimedia.org':
        content => template('gerrit/gerrit.wikimedia.org.erb'),
    }

    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::ssl

    include ::apache::mod::headers
}
