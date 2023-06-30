# == Class: phabricator::phd
#
# Setup PHD service to run securely
#

class phabricator::phd (
    String $phd_user              = 'phd',
    Stdlib::Unixpath $phd_log_dir = '/var/log/phd',
    Stdlib::Unixpath $basedir     = '/',
) {

    class { 'phabricator::phd::user':
        user_name => $phd_user,
    }

    # PHD user needs perms to drop root perms on start
    file { "${basedir}/phabricator/scripts/daemon/":
        owner   => $phd_user,
        recurse => true,
    }

    # Managing repos as the PHD user
    file { "${basedir}/phabricator/scripts/repository/":
        owner   => $phd_user,
        recurse => true,
    }

    file { $phd_log_dir:
        ensure => directory,
        owner  => $phd_user,
        group  => $phd_user,
    }

    logrotate::conf { 'phd':
        ensure => present,
        source => 'puppet:///modules/phabricator/logrotate_phd',
    }
}
