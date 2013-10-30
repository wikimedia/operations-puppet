class dynamicproxy::api {
    package { 'python-flask':
        ensure => 'latest',
        require => Class['misc::labsdebrepo'],
    }

    package { ['python-invisible-unicorn', 'python-flask-sqlalchemy', 'uwsgi', 'uwsgi-plugin-python']:
        ensure => 'present',
        require => Package['python-flask'],
    }

    generic::upstart_job{ 'dynamicproxy-api':
        require => Package['python-invisible-unicorn', 'python-flask-sqlalchemy', 'redis', 'python-flask', 'uwsgi', 'uwsgi-plugin-python'],
        install => 'true',
        start   => 'true'
    }

    file { '/etc/dynamicproxy-api':
        ensure => 'directory',
        owner => 'www-data',
        group => 'www-data',
    }

    # Create initial db file if it doesn't exist, but don't clobber if it does.
    file { '/etc/dynamicproxy-api/data.db':
        ensure => 'file',
        source => 'puppet:///modules/dynamicproxy/initial-data.db',
        replace => false,
        require => File['/etc/dynamicproxy-api'],
        owner => 'www-data',
        group => 'www-data',
    }
}
