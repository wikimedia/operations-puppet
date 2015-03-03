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

    if $::initsystem == 'systemd' {
        # there is a procps service alias; the primary difference here
        #  is that under systemd "start" does not re-apply for new settings
        #  files, only "restart" does so.
        $update_cmd = '/bin/systemctl restart systemd-sysctl.service'
    }
    else {
        $update_cmd = '/usr/sbin/service procps start'
    }

    exec { 'update_sysctl':
        command     => $update_cmd,
        refreshonly => true,
    }
}
