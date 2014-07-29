class quarry::base {

    $clone_path = "/srv/quarry"
    $result_path = "/srv/results"
    $venv_path = "/srv/venv"

    package { [
        'python-virtualenv',
        'python-pip',
    ]:
        ensure => latest
    }

    user { 'quarry':
        ensure => present,
        system => true
    }

    file { [$clone_path, $result_path, $venv_path]:
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
}

class quarry::database {
    $data_path = "/srv/mysql/data"

    class { 'mysql::server':
        config_hash => {
            'datadir' => $data_path,
            'bind_address' => '0.0.0.0'
        }
    }
}

class quarry::redis {
    class { '::redis':
        dir       => '/srv/redis',
        maxmemory => '2GB',
        persist   => 'aof',
        monitor   => false,
    }
}

class quarry::pip::installer(
    $venv_path,
    $requirements_path,
    $user,
) {
    $pip_path = "$venv_path/bin/pip"

    # This is idempotent, so it's alright
    exec { 'pip-install-things':
        command => "$pip_path install -r $requirements_path",
        user    => $user
    }
}

