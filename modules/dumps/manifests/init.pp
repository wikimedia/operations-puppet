class dumps {
    install_certificate{ 'dumps.wikimedia.org': ca => 'RapidSSL_CA.pem' }

    include ::nginx

    $ssl_settings = ssl_ciphersuite('nginx', 'compat')

    nginx::site { 'dumps':
        source  => 'puppet:///modules/dumps/nginx.dumps.conf',
        notify  => Service['nginx'],
    }
    nginx::site { 'download':
        source  => 'puppet:///modules/dumps/nginx.download.conf',
        notify  => Service['nginx'],
    }
}
