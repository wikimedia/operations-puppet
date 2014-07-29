class quarry::base {

    $clone_path = "/srv/web"
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
        ensure    => latest,
        branch    => 'master',
        require   => [File[$clone_path], User['quarry']],
        owner     => 'quarry',
        group     => 'www-data'
    }

    # Ideally this should be refreshed by the git clone,
    # but the git clone doesn't have a publicly defined
    # refresh I can subscribe to, so just running it every time.
    # This is idempotent, so should be ok
    class { 'quarry::pip::installer':
        venv_path         => $venv_path,
        requirements_path => "$clone_path/requirements.txt",
        user              => 'quarry',
        require           => [Git::Clone['analytics/quarry/web'], User['quarry']]
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
    class { 'redis':
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

