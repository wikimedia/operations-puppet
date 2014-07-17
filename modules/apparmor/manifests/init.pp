# == Class: apparmor
#
# Stub class for apparmor so that other classes can define profiles
# and then notify service['apparmor']
#

class apparmor (
    package {
        [
            'apparmor',
        ]:
        ensure => present,
    }

    service { 'apparmor':
        ensure     => running,
        provider   => init,
        hasstatus  => true,
        hasrestart => true,
    }
)
