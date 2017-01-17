# https://wikitech.wikimedia.org/wiki/Dumps
class dumps {

    class { '::nginx':
        variant => 'extras',
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid', true)

    letsencrypt::cert::integrated { 'dumps':
        subjects   => 'dumps.wikimedia.org, download.wikimedia.org',
        puppet_svc => 'nginx',
        system_svc => 'nginx',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http_letsencrypt!dumps.wikimedia.org',
    }

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
