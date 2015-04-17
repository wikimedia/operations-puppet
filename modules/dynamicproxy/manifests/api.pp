class dynamicproxy::api(
    $port = 5668,
) {
    nginx::site { 'api':
        content => template('dynamicproxy/api.conf'),
    }

    ferm::service { 'dynamicproxy-api-http':
        port   => $port,
        proto  => 'tcp',
        desc   => 'API for adding / removing proxies from dynamicproxy domainproxy'
    }

    package { 'python-flask':
        ensure  => latest,
        require => Class['misc::labsdebrepo'],
    }

    package { ['python-invisible-unicorn', 'python-flask-sqlalchemy', 'uwsgi', 'uwsgi-plugin-python']:
        ensure  => present,
        require => Package['python-flask'],
    }

    file { '/etc/init/dynamicproxy-api.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/dynamicproxy/upstart.conf',
        before  => Service['dynamicproxy-api'],
        notify  => Service['dynamicproxy-api'],
    }

    service { 'dynamicproxy-api':
        ensure  => running,
        enable  => true,
        require => [
            Package['python-invisible-unicorn'],
            Package['python-flask-sqlalchemy'],
            Package['redis-server'],
            Package['python-flask'],
            Package['uwsgi'],
            Package['uwsgi-plugin-python'],
        ],
    }

    file { '/etc/dynamicproxy-api':
            ensure => directory,
            owner  => 'www-data',
            group  => 'www-data',
    }

    file { '/data/project/backup':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
    }

    file { '/data/project/backup/README':
            source  => 'puppet:///modules/dynamicproxy/BackupReadme',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => File['/data/project/backup'],
    }

    file { '/usr/local/sbin/proxydb-bak.sh':
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/dynamicproxy/proxydb-bak.sh',
    }

    cron { 'proxydb-bak':
            ensure  => present,
            user    => 'root',
            hour    => '1',
            minute  => '0',
            command => '/usr/local/sbin/proxydb-bak.sh > /dev/null 2>&1',
            require => File['/data/project/backup'],
    }

    # Create initial db file if it doesn't exist, but don't clobber if it does.
    file { '/etc/dynamicproxy-api/data.db':
        ensure  => file,
        source  => 'puppet:///modules/dynamicproxy/initial-data.db',
        replace => false,
        require => File['/etc/dynamicproxy-api'],
        owner   => 'www-data',
        group   => 'www-data',
    }
}
