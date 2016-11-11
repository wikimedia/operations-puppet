# == Class: labstore::monitoring::secondary
#
# Installs icinga checks to
# - make sure resource status on a drbd node is OK,
# - check that the nodes conform to the expected drbd roles.
# - drbd service status
# - check that cluster ip is assigned to DRBD primary
# - NFS is being served over cluster IP

class labstore::monitoring::secondary($drbd_role, $cluster_ip, $resource = 'all') {

    sudo::user { 'nagios_check_drbd':
        user       => 'nagios',
        privileges => [
                      'ALL = NOPASSWD: /usr/local/sbin/check_drbd_status',
                      'ALL = NOPASSWD: /usr/local/sbin/check_drbd_role',
                      'ALL = NOPASSWD: /usr/local/sbin/check_drbd_cluster_ip',
                      'ALL = NOPASSWD: /usr/local/sbin/check_nfs_status',
                      ],
    }

    file { '/usr/local/sbin/check_drbd_status':
        source => 'puppet:///modules/labstore/monitor/check_drbd_status',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_drbd_status':
        description  => 'Check status of DRBD node',
        nrpe_command => "/usr/bin/sudo /usr/local/sbin/check_drbd_status ${resource}",
        require      => File['/usr/local/sbin/check_drbd_status'],
    }

    file { '/usr/local/sbin/check_drbd_role':
        source => 'puppet:///modules/labstore/monitor/check_drbd_role',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_drbd_role':
        description  => 'Check DRBD role',
        nrpe_command => "/usr/bin/sudo /usr/local/sbin/check_drbd_role ${::hostname} ${drbd_role}",
        require      => File['/usr/local/sbin/check_drbd_role'],
    }

    file { '/usr/local/sbin/check_drbd_cluster_ip':
        source => 'puppet:///modules/labstore/monitor/check_drbd_cluster_ip',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_drbd_cluster_ip':
        description  => 'Check DRBD Cluster IP assignment',
        nrpe_command => "/usr/bin/sudo /usr/local/sbin/check_drbd_cluster_ip ${::hostname} ${drbd_role} ${cluster_ip}",
        require      => File['/usr/local/sbin/check_drbd_cluster_ip'],
    }

    # Set up DRBD service monitoring
    nrpe::monitor_systemd_unit_state { 'drbd':
        require => Service['drbd'],
    }

    file { '/usr/local/sbin/check_nfs_status':
        source => 'puppet:///modules/labstore/monitor/check_nfs_status',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_nfs_status':
        description  => 'Check if NFS is served over cluster IP',
        nrpe_command => "/usr/bin/sudo /usr/local/sbin/check_nfs_status ${cluster_ip}",
        require      => File['/usr/local/sbin/check_nfs_status'],
    }

}
