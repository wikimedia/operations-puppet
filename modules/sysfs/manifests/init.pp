# == Class: sysfs
#
# This Puppet module provides 'sysfs::conffile' and 'sysfs::parameters'
# resources which manages kernel parameters using /etc/sysfs.d files
# and the sysfsutils service.
#
class sysfs {
    package { 'sysfsutils':
        ensure => present,
    }

    file { '/etc/sysfs.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        purge   => true,
        force   => true,
    }

    service { 'sysfsutils':
        # Does not have any permanent process, so prevent puppet from
        # attempting to restart a service which is not meant to be running.
        # sysfs::conffile() notify the service to trigger the restart whenever
        # configuration files change.
        ensure     => stopped,
        hasstatus  => false,
        status     => '/bin/true',
        # Have it running on boot
        enable     => true,
        # Quicker restart
        hasrestart => true,
    }
}
