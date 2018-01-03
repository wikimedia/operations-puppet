# == Class: apparmor
#
# Stub class for apparmor so that other classes can define profiles
# and then notify service['apparmor']
#

class apparmor {

    package { 'apparmor':
        ensure => present,
    }

    service { 'apparmor':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['apparmor'],
    }

    # This directory is only created when some
    # profiles are installed by default, but we
    # forcibly create it in case we need to
    # install one ourselves in it
    file { '/etc/apparmor.d/abstractions':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['apparmor'],
    }

}
