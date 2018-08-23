# = Class: profile::quarry::base
#
# This class sets up the basic underlying structure for both
# Quarry web frontends and Quarry query runners.
class profile::quarry::base(
    $clone_path = hiera('profile::quarry::base::clone_path'),
    $result_path_parent = hiera('profile::quarry::base::result_path_parent'),
    $result_path = hiera('profile::quarry::base::result_path'),
) {
    include ::redis::client::python

    package { [
        'python-celery',
        'python-sqlalchemy',
        'python-unicodecsv',
        'python-translitcodec',
        'python-xlsxwriter',
    ]:
        ensure => latest,
    }

    user { 'quarry':
        ensure => present,
        system => true,
    }

    file { [$clone_path, $result_path_parent, $result_path]:
        ensure  => directory,
        owner   => 'quarry',
        require => User['quarry'],
    }

    git::clone { 'analytics/quarry/web':
        ensure    => present,
        directory => $clone_path,
        branch    => 'master',
        require   => [File[$clone_path], User['quarry']],
        owner     => 'quarry',
        group     => 'www-data',
    }
}
