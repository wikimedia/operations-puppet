# == Class: phabricator::phd
#
# Setup PHD service to run securely
#

class phabricator::phd (
    String $phd_user              = 'phd',
    Stdlib::Unixpath $phd_log_dir = '/var/log/phd',
    Stdlib::Unixpath $basedir     = '/',
    Boolean $use_systemd_sysuser  = false,
) {

    # PHD user needs perms to drop root perms on start
    file { "${basedir}/phabricator/scripts/daemon/":
        owner   => $phd_user,
        recurse => true,
    }

    # Managing repo's as the PHD user
    file { "${basedir}/phabricator/scripts/repository/":
        owner   => $phd_user,
        recurse => true,
    }

    file { '/var/run/phd':
        ensure => directory,
        owner  => 'phd',
        group  => 'phd',
    }

    file { $phd_log_dir:
        ensure => 'directory',
        owner  => 'phd',
        group  => 'phd',
    }

    # TODO: remove if/else and parameter after migration to new servers
    if $use_systemd_sysuser {
        systemd::sysuser { $phd_user:
            ensure      => present,
            id          => '920:920',
            description => 'Phabricator daemon user',
            home_dir    => '/var/run/phd',
        }

    } else {

        group { 'phd':
            ensure => present,
            system => true,
        }

        user { $phd_user:
        gid    => 'phd',
        shell  => '/bin/false',
        home   => '/var/run/phd',
        system => true,
        }
    }

    logrotate::conf { 'phd':
        ensure => present,
        source => 'puppet:///modules/phabricator/logrotate_phd',
    }
}
