# == Class: sysctl
#
# This Puppet class provides 'sysctl::conffile' and 'sysctl::parameters'
# resources which manages kernel parameters using /etc/sysctl.d files
# and the procps service.
#
class sysctl {
    file { '/etc/sysctl.d':
        ensure => directory,
    }

    file { '/etc/sysctl.d/puppet-managed':
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        source  => 'puppet:///modules/sysctl/sysctl.d-puppet-managed-empty',
    }

    file { '/etc/init/procps-puppet.conf':
        source  => 'puppet:///modules/sysctl/procps-puppet.conf',
        require => File['/etc/sysctl.d/puppet-managed'],
    }

    service { 'procps-puppet':
        provider => upstart,
        require  => File['/etc/init/procps-puppet.conf'],
    }
}
