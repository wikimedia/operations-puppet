# == Class: wikimetrics
# This class sets up the wikimetrics user and the deploy repo
#
class wikimetrics::base (
    $branch = 'master',
) {

    $user = 'wikimetrics'
    $group = 'wikimetrics'
    $venv_path = '/srv/wikimetrics/venv'
    $config_path = '/srv/wikimetrics/config'

    # We use virtualenv and pip install requirements because not all of them
    # have debian packages available
    ensure_packages(['virtualenv', 'gcc', 'python-dev', 'libmysqlclient-dev'])

    group { $group:
      ensure => 'present',
      system => true,
    }

    user { $user:
        ensure     => 'present',
        gid        => $group,
        home       => '/srv/wikimetrics',
        managehome => false,
        system     => true,
    }

    file { '/srv':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/srv/wikimetrics':
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0775',
        require => File['/srv'],
    }

    git::clone { 'wikimetrics-deploy':
        ensure    => present,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/wikimetrics-deploy',
        directory => $config_path,
        branch    => $branch,
        owner     => $user,
        group     => $group,
        require   => File['/srv/wikimetrics'],
    }
}
