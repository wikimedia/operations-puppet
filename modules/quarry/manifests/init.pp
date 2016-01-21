# = Class: quarry::base
#
# This class sets up the basic underlying structure for both
# Quarry web frontends and Quarry query runners.
class quarry::base(
    $clone_path = '/srv/quarry',
    $result_path_parent = '/data/project/quarry',
    $result_path = '/data/project/quarry/results',
) {
    include ::redis::client::python

    package { [
        'python-celery',
        'python-sqlalchemy',
        'python-unicodecsv',
        'python-translitcodec',
    ]:
        ensure => latest
    }

    user { 'quarry':
        ensure => present,
        system => true
    }

    file { [$clone_path, $result_path_parent, $result_path]:
        ensure  => directory,
        owner   => 'quarry',
        require => User['quarry']
    }

    git::clone { 'analytics/quarry/web':
        ensure    => present,
        directory => $clone_path,
        branch    => 'master',
        require   => [File[$clone_path], User['quarry']],
        owner     => 'quarry',
        group     => 'www-data'
    }
}

# = Class: quarry::database
#
# Sets up a mysql database for use by Quarry web frontends
# and Quarry query runners
class quarry::database {
    $data_path = '/srv/mysql/data'

    class { 'mysql::server':
        package_name => 'mariadb-server',
        config_hash  => {
            'datadir'      => $data_path,
            'bind_address' => '0.0.0.0',
        }
    }
}

# = Class: quarry::redis
#
# Sets up a redis instance for use as caching and session storage
# by the Quarry frontends and also as working queue & results
# backend by the query runners.
class quarry::redis {
    redis::instance { '6379':
        settings => {
            bind           => '0.0.0.0',
            dir            => '/srv/redis',
            maxmemory      => '2GB',
        }
    }
}

# = Class: quarry:querykiller
#
# Sets up a cron based query-killer
class quarry::querykiller {
    require quarry::base

    file { '/var/log/quarry':
        ensure => directory,
        owner  => 'quarry',
        group  => 'quarry'
    }

    cron { 'query-killer':
        command => "${quarry::base::clone_path}/quarry/web/killer.py",
        minute  => '*',
        user    => 'quarry',
    }
}
