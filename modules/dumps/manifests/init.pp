class dumps {
    sslcert::certificate { 'dumps.wikimedia.org': }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http!dumps.wikimedia.org',
    }

    class { '::nginx':
        variant => 'extras',
    }

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
