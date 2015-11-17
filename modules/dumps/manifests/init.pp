class dumps {
    sslcert::certificate { 'dumps.wikimedia.org': }

    class { '::nginx':
        variant => 'extras',
    }
    $ssl_settings = ssl_ciphersuite('nginx', 'compat')

    nginx::site { 'dumps':
        content => template('dumps/nginx.dumps.conf.erb'),
        notify  => Service['nginx'],
    }
    nginx::site { 'download':
        source => 'puppet:///modules/dumps/nginx.download.conf',
        notify => Service['nginx'],
    }

    file { '/etc/logrotate.d/nginx':
        source  => 'puppet:///modules/dumps/logrotate.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['nginx-extras'],
    }
}
