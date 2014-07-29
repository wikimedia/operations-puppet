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
        directory => $clone_dir,
        ensure    => latest,
        branch    => 'master',
        require   => [File[$clone_dir], User['quarry']]
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
        require           => [Git::Clone['analytics/quarry/web'], User['quarry']],

        notify            => Service['uwsgi']
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

class quarry::web {
    $clone_path = "$base_path/web"
    $result_path = "$base_path/results"
    $venv_path = "$base_path/venv"

    include quarry::base

    uwsgi::app { 'quarry-web':
        require => Git::Clone['analytics/quarry/web']
        settings             => {
            uwsgi            => {
                'socket'     => '/run/uwsgi/quarry-web.sock',
                'wsgi-file'  => "$clone_path/app.wsgi",
                'master'     => true,
                'processes'  => 8,
                'virtualenv' => $venv_path
            }
        }
    }

    nginx::site { 'quarry-web-nginx':
        require => Uwsgi::App['quarry-web'],
        content => template('quarry/quarry-web.nginx.erb')
    }
}

class quarry::celeryrunner {
    $clone_path = "/srv/web"
    $result_path = "/srv/results"

    include quarry::base
}
