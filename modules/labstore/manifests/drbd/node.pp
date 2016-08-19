# General DRBD node setup.
# The service management is also expected to happen outside this class.
#
# [*protocol]
#  replication protocol method
#
# [*sync_rate]
#  bandwidth to use between nodes

class labstore::drbd::node (
    $protocol = 'B',
    $sync_rate = '300M',
) {

    package {'drbd8-utils':
      ensure => present,
    }

    file {'/etc/drbd.conf':
        ensure => present,
        source => 'puppet:///modules/labstore/drbd.conf',
    }

    file {'/etc/drbd.d':
        ensure  => directory,
        purge   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/drbd.conf'],
    }

    # Setup global config that is shared for all DRBD resources on this node
    file { '/etc/drbd.d/global_common.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('labstore/drbd/global_common.conf.erb'),
    }

    # When the global config is modified, this exec reconfigures them without
    # requiring service restart.
    exec { 'drbdadm-adjust':
        command     => '/sbin/drbdadm adjust all -v',
        onlyif      => '/bin/ls /etc/drbd.d/*.res',
        logoutput   => true,
        refreshonly => true,
        subscribe   => File['/etc/drbd.d/global_common.conf'],
    }
}
