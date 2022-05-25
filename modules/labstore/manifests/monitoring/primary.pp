# == Class: labstore::monitoring::primary
#
# This is the primary NFS server for Toolforge / Cloud VPS
#
# Installs icinga checks to
# - make sure resource status on a drbd node is OK,
# - check that the nodes conform to the expected drbd roles.
# - drbd service status
# - check that cluster ip is assigned to DRBD primary
# - NFS is being served over cluster IP

class labstore::monitoring::primary(
    String $drbd_role,
    String $cluster_iface,
    Stdlib::IP::Address $cluster_ip,
    Boolean $critical = false,
    String $resource = 'all',
    String $contact_groups = 'wmcs-team',
){

    sudo::user { 'nagios_check_drbd':
        ensure => absent,
    }

    file { [
        '/usr/local/sbin/check_drbd_status',
        '/usr/local/sbin/check_drbd_role',
        '/usr/local/sbin/check_drbd_cluster_ip',
    ]:
        ensure => absent,
    }

    nrpe::plugin { 'check_drbd_status':
        source => 'puppet:///modules/labstore/monitor/check_drbd_status.py',
    }

    nrpe::monitor_service { 'check_drbd_status':
        critical      => $critical,
        description   => 'DRBD node status',
        nrpe_command  => "/usr/local/lib/nagios/plugins/check_drbd_status ${resource}",
        sudo_user     => 'root',
        contact_group => $contact_groups,
        require       => File['/usr/local/sbin/check_drbd_status'],
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }

    nrpe::plugin { 'check_drbd_role':
        source => 'puppet:///modules/labstore/monitor/check_drbd_role.py',
    }

    nrpe::monitor_service { 'check_drbd_role':
        critical      => $critical,
        description   => 'DRBD role',
        nrpe_command  => "/usr/local/lib/nagios/plugins/check_drbd_role ${::hostname} ${drbd_role}",
        sudo_user     => 'root',
        contact_group => $contact_groups,
        require       => File['/usr/local/sbin/check_drbd_role'],
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }

    nrpe::plugin { 'check_drbd_cluster_ip':
        source => 'puppet:///modules/labstore/monitor/check_drbd_cluster_ip.py',
    }

    nrpe::monitor_service { 'check_drbd_cluster_ip':
        critical      => $critical,
        description   => 'DRBD Cluster IP assignment',
        nrpe_command  => "/usr/local/lib/nagios/plugins/check_drbd_cluster_ip ${::hostname} ${drbd_role} ${cluster_iface} ${cluster_ip}",
        sudo_user     => 'root',
        contact_group => $contact_groups,
        require       => File['/usr/local/sbin/check_drbd_cluster_ip'],
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }

    nrpe::monitor_service { 'check_nfs_status':
        description   => 'NFS port is open on cluster IP',
        nrpe_command  => "/usr/lib/nagios/plugins/check_tcp -H ${cluster_ip} -p 2049 --timeout=2",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }
}
