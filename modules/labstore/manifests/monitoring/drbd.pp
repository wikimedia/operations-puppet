# == Class: labstore::monitoring::drbd
#
# Installs an icinga check to make sure resource status on a drbd node is OK
class labstore::monitoring::drbd(
    $resource = 'all',
    $role = 'primary') {

    file { '/usr/local/sbin/check_drbd_status':
        source => 'puppet:///modules/labstore/monitor/check_drbd_status',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check-drbd-status':
        description   => 'Check status of DRBD node',
        nrpe_command  => '/usr/local/sbin/check_drbd_status ${resource} ${role}',
        require       => File['/usr/local/sbin/check_drbd_status'],
    }
}
