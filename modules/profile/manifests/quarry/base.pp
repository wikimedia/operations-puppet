# SPDX-License-Identifier: Apache-2.0
# = Class: profile::quarry::base
#
# This class sets up the basic underlying structure for both
# Quarry web frontends and Quarry query runners.
class profile::quarry::base(
    Stdlib::Unixpath $clone_path         = lookup('profile::quarry::base::clone_path'),
    Stdlib::Unixpath $venv_path          = lookup('profile::quarry::base::venv_path'),
    Stdlib::Unixpath $result_path_parent = lookup('profile::quarry::base::result_path_parent'),
    Stdlib::Unixpath $result_path        = lookup('profile::quarry::base::result_path'),
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
        group   => 'www-data',
        require => User['quarry'],
    }

    git::clone { 'quarry':
        ensure    => present,
        directory => $clone_path,
        branch    => 'master',
        source    => 'github-toolforge',
        require   => [File[$clone_path], User['quarry']],
        owner     => 'quarry',
        group     => 'www-data',
    }

    exec { 'quarry-venv':
        command => "/usr/bin/python3 -m venv ${venv_path}",
        creates => $venv_path,
        require => Git::Clone['quarry'],
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
