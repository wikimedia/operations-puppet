class dynamicproxy::api {
    package { ['python-invisible-unicorn', 'python-flask-sqlalchemy', 'python-flask']:
        ensure => 'present',
        require => Class['misc::labsdebrepo'],
    }

    upstart_job{ 'dynamic-proxy-api':
        require => Package['python-invisible-unicorn', 'python-flask-sqlalchemy', 'redis', 'python-flask'],
        install => 'true',
        start   => 'true'
    }
}
