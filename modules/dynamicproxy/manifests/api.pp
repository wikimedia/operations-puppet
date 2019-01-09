class dynamicproxy::api(
    $port = 5668,
) {
    file { '/usr/local/bin/invisible-unicorn.py':
        source => 'puppet:///modules/dynamicproxy/invisible-unicorn.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    require_package('python3-flask', 'python3-redis', 'python3-flask-sqlalchemy', 'sqlite3')

    uwsgi::app { 'invisible-unicorn':
        settings  => {
            uwsgi => {
                plugins            => 'python3',
                master             => true,
                http-socket        => '0.0.0.0:5668',
                mount              => '/dynamicproxy-api=/usr/local/bin/invisible-unicorn.py',
                callable           => 'app',
                manage-script-name => true,
                workers            => 4,
            },
        },
        subscribe => File['/usr/local/bin/invisible-unicorn.py'],
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

    # This is a GET-only front end that sits on port 5669.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { 'proxygetter':
        source => 'puppet:///modules/dynamicproxy/proxygetter.conf',
    }
}
