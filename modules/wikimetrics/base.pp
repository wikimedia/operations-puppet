# = Class: wikimetrics
# This class sets up the wikimetrics user and the deploy repo
#
class wikimetrics::base (
    $branch = 'master',
) {

    $owner = 'wikimetrics'
    $group = 'wikimetrics'
    $venv_path = '/srv/wikimetrics/venv'
    $config_path = '/srv/wikimetrics/config'

    # We use virtualenv and pip install requirements because not all of them
    # have debian packages available
    ensure_packages(['virtualenv', 'gcc', 'python-dev', 'libmysqlclient-dev'])

    if !defined(Group[$group]) {
        group { $group:
          ensure => 'present',
          system => true,
        }
    }
    if !defined(User[$user]) {
        user { $user:
            ensure     => 'present',
            gid        => $group,
            home       => $path,
            managehome => false,
            system     => true,
        }
    }

    file { '/srv':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/srv/wikimetrics':
        ensure  => directory,
        owner   => $owner,
        group   => $group,
        mode    => '0775',
        require => File['/srv'],
    }

    git::clone { 'wikimetrics-deploy':
        ensure    => present,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/wikimetrics-deploy',
        directory => $config_path,
        branch    => $branch,
        owner     => $owner,
        group     => $group,
        require   => File['/srv/wikimetrics'],
    }
}
