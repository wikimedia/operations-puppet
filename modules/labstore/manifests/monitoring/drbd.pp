# == Class: labstore::monitoring::drbd
#
# Installs icinga checks to make sure resource status on a drbd node is OK,
# and to check that the nodes conform to the expected drbd roles.

class labstore::monitoring::drbd($drbd_role, $resource = 'all') {

    file { '/usr/local/sbin/check_drbd_status':
        source => 'puppet:///modules/labstore/monitor/check_drbd_status',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check-drbd-status':
        description  => 'Check status of DRBD node',
        nrpe_command => "/usr/local/sbin/check_drbd_status ${resource} ${drbd_role}",
        require      => File['/usr/local/sbin/check_drbd_status'],
    }

    file { '/usr/local/sbin/check_drbd_role':
        source => 'puppet:///modules/labstore/monitor/check_drbd_role',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_drbd_role':
        description  => 'Check status of DRBD node',
        nrpe_command => "/usr/local/sbin/check_drbd_role ${::hostname} ${drbd_role}",
        require      => File['/usr/local/sbin/check_drbd_role'],
    }

}
