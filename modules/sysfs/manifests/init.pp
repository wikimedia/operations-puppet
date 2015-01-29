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
        refreshonly => true,
    }
}
