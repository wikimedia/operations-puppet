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
        'gnupg',
        'reprepro',
        'dctrl-tools'
        ]:
        ensure => latest,
    }

    # TODO: add something that sets up /etc/environment for reprepro

    file { '/srv/wikimedia':
            ensure  => directory,
            mode    => '0755',
            owner   => 'root',
            group   => 'root';
    }

    # TODO: This has been long enough in deprecation, time to ensure
    # deletion, remove this resource at some later time
    file { '/usr/local/sbin/update-repository':
            ensure  => absent,
    }

    # Reprepro configuration
    file {
        '/srv/wikimedia/conf':
            ensure  => directory,
            mode    => '0755',
            owner   => 'root',
            group   => 'root';
        '/srv/wikimedia/conf/log':
            ensure  => present,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/install-server/reprepro-log';
        '/srv/wikimedia/conf/distributions':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/install-server/reprepro-distributions';
        '/srv/wikimedia/conf/updates':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/install-server/reprepro-updates';
        '/srv/wikimedia/conf/incoming':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/install-server/reprepro-incoming';
    }
}
