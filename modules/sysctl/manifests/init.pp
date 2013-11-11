# == Class: sysctl
#
# This Puppet module provides 'sysctl::conffile' and 'sysctl::parameters'
# resources which manages kernel parameters using /etc/sysctl.d files
# and the procps service.
#
class sysctl {
    file { '/etc/sysctl.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        purge   => true,
        force   => true,
        source  => 'puppet:///modules/sysctl/sysctl.d-empty',
    }

    # The 'propcs' Upstart job is available in Ubuntu 10.04 Lucid and up.
    # The dummy service below is a hack to prevent Puppet failures on Hardy.
    # FIXME: Remove dummy service when the last Hardy box is retired.
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
