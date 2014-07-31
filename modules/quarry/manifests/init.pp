# = Class: quarry::base
#
# This class sets up the basic underlying structure for both
# Quarry web frontends and Quarry query runners.
class quarry::base {

    $clone_path = "/srv/quarry"
    $result_path_parent = "/data/project/quarry"
    $result_path = "/data/project/quarry/results"

    package { [
        'python-flask',
        'python-mwoauth',
        'python-celery',
        'python-redis',
        'python-pymysql',
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
        directory => $clone_path,
        ensure    => present,
        branch    => 'master',
        require   => [File[$clone_path], User['quarry']],
        owner     => 'quarry',
        group     => 'www-data'
    }

    # Temp. hack until Coren figures out why normal users
    # can't do 'sudo -u <user> <command' on labs
    # Otherwise fabric deployment wokn't work
    admin::sudo { 'wikidev':
        is_group => true,
        comment  => 'Give human users full ability to sudo as anyone without password',
        privs    => ['ALL=(ALL) NOPASSWD: ALL']
    }

}

# = Class: quarry::database
#
# Sets up a mysql database for use by Quarry web frontends
# and Quarry query runners
class quarry::database {
    $data_path = "/srv/mysql/data"

    class { 'mysql::server':
        config_hash => {
            'datadir' => $data_path,
            'bind_address' => '0.0.0.0'
        }
    }
}

# = Class: quarry::redis
#
# Sets up a redis instance for use as caching and session storage
# by the Quarry frontends and also as working queue & results
# backend by the query runners.
class quarry::redis {
    class { '::redis':
        dir       => '/srv/redis',
        maxmemory => '2GB',
        persist   => 'aof',
        monitor   => false,
    }
}
