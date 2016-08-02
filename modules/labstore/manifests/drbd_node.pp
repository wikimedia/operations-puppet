# Class that defines the basics for a DRBD node setup.
# It sets up the required packages, and the global configuration for DRBD.
# Once this class is applied, DRBD resources can then be defined by using
# the labstore::drbd_resource define type.
# The service management is also expected to happen outside this class.
#
#
class labstore::drbd_node {

    # Installing this package also sets up a systemd init script in /etc/init.d
    package {'drbd8-utils':
      ensure => present,
    }

    file {'/etc/drbd.d':
        ensure => directory,

    }
    # Setup global config that is shared for all DRBD resources on this node
    file { '/etc/drbd.d/global_common.conf':
        ensure  => present,
        content => template('labstore/drbd/global_common.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }


}
