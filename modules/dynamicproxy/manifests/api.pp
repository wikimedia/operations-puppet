class dynamicproxy::api {
    package { ['python-invisible-unicorn', 'python-flask-sqlalchemy', 'redis', 'python-flask']
        ensure => 'present',
    }

    upstart_job{ 'dynamic-proxy-api':
        require => Package['python-invisible-unicorn', 'python-flask-sqlalchemy', 'redis', 'python-flask'],
        install => true,
    }
}
