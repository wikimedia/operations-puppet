# = Class: quarry::celeryrunner
#
# Runs queries submitted via celery
class quarry::celeryrunner {
    $clone_path = "/srv/quarry"
    $result_path = "/data/project/quarry/results"

    include quarry::base

    file { '/etc/init.d/celeryd':
        source => 'puppet:///modules/quarry/celeryd',
        mode   => '0755',
    }

    file { '/etc/default/celeryd':
        content => template('quarry/celeryd.conf.erb'),
    }

    service { 'celeryd':
        require => [File['/etc/init.d/celeryd'], File['/etc/default/celeryd'], User['quarry']],
        ensure  => running
    }

    cron { 'query-killer':
        command => "$clone_path/quarry/web/killer.py",
        minute  => '*',
        user    => 'quarry',
    }
}
