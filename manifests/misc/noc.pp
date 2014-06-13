# https://noc.wikimedia.org/

class misc::noc-wikimedia {

    system::role { 'misc::noc-wikimedia':
        description => 'noc.wikimedia.org'
    }

    package { 'apache2':
        ensure => latest,
    }

    file { '/etc/apache2/sites-available/noc.wikimedia.org':
        require => [Apache_module[userdir],
                    Apache_module[cgi],
                    Package[libapache2-mod-php]],
        path    => '/etc/apache2/sites-available/noc.wikimedia.org',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///files/apache/sites/noc.wikimedia.org',
    }

    # ensure default site is removed
    apache_site { '000_default':
        ensure => absent,
        name   => '000-default',
    }

    apache_site { '000-default-ssl':
        ensure => absent,
        name   => '000-default-ssl',
    }

    apache_module { 'php5':
        name => 'php5'
    }

    apache_module { 'userdir':
        name => 'userdir'
    }

    apache_module { 'cgi':
        name => 'cgi'
    }

    apache_module { 'ssl':
        name => 'ssl'
    }

    apache_site { 'noc':
        name => 'noc.wikimedia.org'
    }

    service { 'apache2':
        ensure    => running,
        require   => [Package[apache2],
                      Apache_module[userdir],
                      Apache_module[cgi],
                      Apache_site[noc]],
        subscribe => [Package[libapache2-mod-php5],
                      Apache_module[userdir],
                      Apache_module[cgi],
                      Apache_site[noc],
                      File['/etc/apache2/sites-available/noc.wikimedia.org']],
    }

    # Monitoring
    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http_url!noc.wikimedia.org!http://noc.wikimedia.org',
    }

    # caches the ganglia xml data from gmetric used by dbtree every minute
    cron { 'dbtree_cache_cron':
        command => '/usr/bin/curl -s \'http://noc.wikimedia.org/dbtree/?recache=true\' >/dev/null',
        user    => 'www-data',
        minute  => '*',
    }
}
