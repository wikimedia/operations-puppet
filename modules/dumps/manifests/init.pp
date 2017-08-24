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

    logrotate::rule { 'nginx':
        ensure      => present,
        file_glob   => '/var/log/nginx/*.log',
        frequency   => 'daily',
        rotate      => 30,
        dateext     => true,
        missingok   => true,
        compress    => true,
        create      => '0640 www-data adm',
        post_rotate => '[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`',
    }

    file { '/data/xmldatadumps/public/favicon.ico':
        source => 'puppet:///modules/dumps/favicon.ico',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
