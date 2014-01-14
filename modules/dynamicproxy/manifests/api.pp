class dynamicproxy::api {
    file { '/etc/nginx/sites-available/api':
        ensure  => 'file',
        content => template('dynamicproxy/api.conf'),
        require => Package['nginx-extras'],
        notify  => Service['nginx'],
    }

    file { '/etc/nginx/sites-enabled/api':
        ensure  => 'link',
        target  => '/etc/nginx/sites-available/api',
        require => File['/etc/nginx/sites-available/api'],
    }

    package { 'python-flask':
        ensure  => 'latest',
        require => Class['misc::labsdebrepo'],
    }

    package { ['python-invisible-unicorn', 'python-flask-sqlalchemy', 'uwsgi', 'uwsgi-plugin-python']:
        ensure  => 'present',
        require => Package['python-flask'],
    }

    generic::upstart_job{ 'dynamicproxy-api':
        require => Package['python-invisible-unicorn', 'python-flask-sqlalchemy', 'redis', 'python-flask', 'uwsgi', 'uwsgi-plugin-python'],
        install => true,
        start   => true,
    }

    file { '/etc/dynamicproxy-api':
            ensure => 'directory',
            owner  => 'www-data',
            group  => 'www-data',
    }

    file { '/data/project/backup':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
    }

    file { '/data/project/backup/README':
            source  => 'puppet:///modules/dynamicproxy/BackupReadme',
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
            hour    => 1,
            minute  => 0,
            command => '/usr/local/sbin/proxydb-bak.sh > /dev/null 2>&1',
            require => File['/data/project/backup'],
    }

    # Create initial db file if it doesn't exist, but don't clobber if it does.
    file { '/etc/dynamicproxy-api/data.db':
        ensure  => 'file',
        source  => 'puppet:///modules/dynamicproxy/initial-data.db',
        replace => false,
        require => File['/etc/dynamicproxy-api'],
        owner   => 'www-data',
        group   => 'www-data',
    }
}
