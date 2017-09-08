# https://wikitech.wikimedia.org/wiki/Dumps
class dumps::web {

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
        content => template('dumps/web/nginx.dumps.conf.erb'),
        notify  => Service['nginx'],
    }

    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/dumps/web/logrotate.conf',
    }

    file { '/data/xmldatadumps/public/favicon.ico':
        source => 'puppet:///modules/dumps/web/favicon.ico',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
