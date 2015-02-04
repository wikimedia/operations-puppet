class dumps {
    install_certificate{ 'dumps.wikimedia.org': ca => 'RapidSSL_SHA256_CA_-_G3.crt' }

    include ::nginx

    $ssl_settings = ssl_ciphersuite('nginx', 'compat')

    nginx::site { 'dumps':
        content => template('dumps/nginx.dumps.conf.erb'),
        notify  => Service['nginx'],
    }
    nginx::site { 'download':
        source  => 'puppet:///modules/dumps/nginx.download.conf',
        notify  => Service['nginx'],
    }
}
