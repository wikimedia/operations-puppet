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
            require    => Interface::Manual['eth1'],
        }
    }

    # TODO: hiera this
    $drbd_cluster = {
        'labstore1004' => 'eth1.labstore1004.eqiad.wmnet',
        'labstore1005' => 'eth1.labstore1005.eqiad.wmnet',
    }

    labstore::drbd::resource {'test':
        drbd_cluster => $drbd_cluster,
        port         => '7790',
        device       => '/dev/drbd1',
        disk         => '/dev/misc/test',
        require      => Interface::Ip['drbd-replication'],
    }

    labstore::drbd::resource {'tools':
        drbd_cluster => $drbd_cluster,
        port         => '7791',
        device       => '/dev/drbd4',
        disk         => '/dev/tools/tools-project',
        require      => Interface::Ip['drbd-replication'],
    }

    labstore::drbd::resource {'others':
        drbd_cluster => $drbd_cluster,
        port         => '7792',
        device       => '/dev/drbd3',
        disk         => '/dev/misc/others',
        require      => Interface::Ip['drbd-replication'],
    }

    class { 'labstore::monitoring::drbd':
        drbd_role  => $drbd_role,
    }
}
