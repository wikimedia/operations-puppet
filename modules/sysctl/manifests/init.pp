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

    exec { 'update_sysctl':
        command     => '/bin/systemctl restart systemd-sysctl.service',
        refreshonly => true,
    }
}
