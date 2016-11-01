class role::labs::nfs::secondary($monitor = 'eth0') {

    system::role { 'role::labs::nfs::secondary':
        description => 'NFS secondary share cluster',
    }

    include labstore::fileserver::exports
    include labstore::fileserver::secondary
    include labstore::backup_keys

    # Enable RPS to balance IRQs over CPUs
    interface::rps { $monitor: }

    interface::manual{ 'eth1':
        interface => 'eth1',
    }

    if $::hostname == 'labstore1005' {
        # Define DRBD role for this host, should come from hiera
        $drbd_role = 'secondary'

        interface::ip { 'drbd-replication':
            interface => 'eth1',
            address   => '10.64.37.26',
            prefixlen => '24',
            require   => Interface::Manual['eth1'],
        }
    }

    if $::hostname == 'labstore1004' {
        # Define DRBD role for this host, should come from hiera
        $drbd_role = 'primary'

        interface::ip { 'drbd-replication':
            interface => 'eth1',
            address   => '10.64.37.25',
            prefixlen => '24',
            require   => Interface::Manual['eth1'],
        }
    }

    # TODO: hiera this
    $drbd_cluster = {
        'labstore1004' => 'eth1.labstore1004.eqiad.wmnet',
        'labstore1005' => 'eth1.labstore1005.eqiad.wmnet',
    }

    # Floating IP assigned to drbd primary(active NFS server). Should come from hiera
    $cluster_ip = '10.64.37.18'

    $subnet_gateway_ip = '10.64.37.1'

    $drbd_resource_config = hiera('labstore_secondary_drbd_resource_config', {})
    $drbd_resources = keys($drbd_resource_config)

    labstore::drbd::resource { $drbd_resources:
        drbd_cluster => $drbd_cluster,
        port         => $drbd_resource_config[$title]['port'],
        device       => $drbd_resource_config[$title]['device'],
        disk         => $drbd_resource_config[$title]['disk'],
        require      => Interface::Ip['drbd-replication'],
    }

    class { 'labstore::monitoring::drbd':
        drbd_role  => $drbd_role,
    }

    file { '/usr/local/sbin/nfs-manage':
        content => template('labs/nfs/nfs-manage.sh.erb'),
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
    }
}
