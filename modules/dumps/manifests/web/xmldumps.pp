# https://wikitech.wikimedia.org/wiki/Dumps
class dumps::xmldumps {

    class { '::nginx':
        variant => 'extras',
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid', true)

    letsencrypt::cert::integrated { 'dumps':
        subjects   => 'dumps.wikimedia.org',
        puppet_svc => 'nginx',
        system_svc => 'nginx',
    }

    nginx::site { 'xmldumps':
        content => template('dumps/web/xmldumps/nginx.conf.erb'),
        notify  => Service['nginx'],
    }

    logrotate::conf { 'xmldumps-nginx':
        ensure => present,
        source => 'puppet:///modules/dumps/web/xmldumps/logrotate.conf',
    }

    file { '/data/xmldatadumps/public/favicon.ico':
        source => 'puppet:///modules/dumps/web/xmldumps/favicon.ico',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
