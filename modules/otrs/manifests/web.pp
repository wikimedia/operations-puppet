class otrs::web {
    include ::apache::mod::perl
    include ::apache::mod::rewrite
    include ::apache::mod::ssl
    include ::apache::mod::headers

    sslcert::certificate { 'ticket.wikimedia.org': }
    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '365')
    apache::site { 'ticket.wikimedia.org':
        content => template('otrs/ticket.wikimedia.org.erb'),
    }
}
