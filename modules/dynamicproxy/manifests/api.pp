class dynamicproxy::api {
    package { 'python-flask':
        ensure => 'latest',
        require => Class['misc::labsdebrepo'],
    }

    package { ['python-invisible-unicorn', 'python-flask-sqlalchemy']:
        ensure => 'present',
        require => Package['python-flask'],
    }

    upstart_job{ 'dynamicproxy-api':
        require => Package['python-invisible-unicorn', 'python-flask-sqlalchemy', 'redis', 'python-flask'],
        install => 'true',
        start   => 'true'
    }
}
