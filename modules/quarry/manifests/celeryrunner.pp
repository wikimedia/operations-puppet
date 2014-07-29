class quarry::celeryrunner {
    $clone_path = "/srv/web"
    $result_path = "/data/project/quarry/results"
    $venv_path = "/srv/venv"

    include quarry::base

    file { '/etc/init.d/celeryd':
        source => 'puppet:///modules/quarry/celeryd',
        mode   => '0755',
    }

    file { '/etc/default/celeryd':
        content => template('quarry/celeryd.conf.erb'),
    }

    service { 'celeryd':
        require => [File['/etc/init.d/celeryd'], File['/etc/default/celeryd'], User['quarry'],
        ensure  => running
    }

}
