# https://wikitech.wikimedia.org/wiki/Dumps
class dumps {

    class { '::nginx':
        variant => 'extras',
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid', true)

    letsencrypt::cert::integrated { 'dumps':
        subjects   => 'dumps.wikimedia.org',
        puppet_svc => 'nginx',
        system_svc => 'nginx',
    }

    nginx::site { 'dumps':
        content => template('dumps/nginx.dumps.conf.erb'),
        notify  => Service['nginx'],
    }

    file { '/etc/logrotate.d/nginx':
        source  => 'puppet:///modules/dumps/logrotate.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['nginx-extras'],
    }
    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/dumps/logrotate.conf',
    }

    file { '/data/xmldatadumps/public/favicon.ico':
        source => 'puppet:///modules/dumps/favicon.ico',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
