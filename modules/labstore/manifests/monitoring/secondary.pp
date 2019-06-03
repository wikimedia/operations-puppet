# == Class: labstore::monitoring::secondary
#
# This is the secondary NFS server for maps / scratch
#
# Installs icinga checks to
# - maps NFS is being served over cluster IP

class labstore::monitoring::secondary(
    $cluster_iface,
    $cluster_ip,
    $critical=true,
    $resource = 'all',
    $contact_groups='wmcs-team',
    ) {
    file { '/usr/local/sbin/check_nfs_status':
        source => 'puppet:///modules/labstore/monitor/check_nfs_status.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_nfs_status':
        critical      => $critical,
        description   => 'NFS served over cluster IP',
        nrpe_command  => "/usr/bin/sudo /usr/local/sbin/check_nfs_status ${cluster_ip}",
        contact_group => $contact_groups,
        require       => File['/usr/local/sbin/check_nfs_status'],
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }
}
