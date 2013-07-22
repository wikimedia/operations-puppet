# == Class: sysctl
#
# This Puppet class provides 'sysctl::conffile' and 'sysctl::parameters'
# resources which manages kernel parameters using /etc/sysctl.d files
# and the procps service.
#
class sysctl {
    file { '/etc/sysctl.d':
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        source  => 'puppet:///modules/sysctl/sysctl.d-empty',
    }

    # The 'propcs' Upstart job is available in Ubuntu 10.04 Lucid and up.
    # We declare a dummy service for older versions.
    if versioncmp($::lsbdistrelease, '10') > 0 {
        service { 'procps':
            provider => upstart,
        }
    } else {
        service { 'procps':
            provider => base,
            start    => '/bin/true',
            stop     => '/bin/true',
        }
    }
}
