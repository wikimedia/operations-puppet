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

