# = Class: profile::quarry::base
#
# This class sets up the basic underlying structure for both
# Quarry web frontends and Quarry query runners.
class profile::quarry::base(
    $clone_path = hiera('profile::quarry::base::clone_path'),
    $venv_path = hiera('profile::quarry::base::venv_path'),
    $result_path_parent = hiera('profile::quarry::base::result_path_parent'),
    $result_path = hiera('profile::quarry::base::result_path'),
) {
    package { 'python3-venv':
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

    exec { 'quarry-venv':
        command => "/usr/bin/python3 -m venv ${venv_path}",
        creates => $venv_path,
        require => Git::Clone['analytics/quarry/web'],
    }

    exec { 'quarry-venv-update-pip-wheel':
        command     => "${venv_path}/bin/pip install -U pip wheel",
        subscribe   => Exec['quarry-venv'],
        refreshonly => true,
    }

    exec { 'quarry-venv-requirements':
        command     => "${venv_path}/bin/pip install -r ${clone_path}/requirements.txt",
        subscribe   => Exec['quarry-venv-update-pip-wheel'],
        refreshonly => true,
    }
}
