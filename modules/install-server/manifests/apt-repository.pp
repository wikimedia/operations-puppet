# Class: install-server::apt-repository
#
# This class installs apt repository managements tools
#
# Parameters:
#
# Actions:
#       Install reprepo et al and populate configuration
#
# Requires:
#
# Sample Usage:
#   include install-server::apt-repository

class install-server::apt-repository {
    package { [
        'dpkg-dev',
        'dctrl-tools',
        'gnupg',
        'reprepro',
        ]:
        ensure => present,
    }

    # TODO: add something that sets up /etc/environment for reprepro

    file { '/srv/wikimedia':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # reprepro configuration
    file { '/srv/wikimedia/conf':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/srv/wikimedia/conf/log':
        ensure => present,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/install-server/reprepro/log',
    }
    file { '/srv/wikimedia/conf/distributions':
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/install-server/reprepro/distributions',
    }
    file { '/srv/wikimedia/conf/updates':
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/install-server/reprepro/updates',
    }
    file { '/srv/wikimedia/conf/incoming':
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/install-server/reprepro/incoming',
    }
}
