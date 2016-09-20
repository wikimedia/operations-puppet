class role::labs::nfs::secondary($monitor = 'eth0') {

    system::role { 'role::labs::nfs::secondary':
        description => 'NFS secondary share cluster',
    }

    include labstore::fileserver::exports
    include labstore::fileserver::secondary
    include labstore::backup_keys

    # Enable RPS to balance IRQs over CPUs
    interface::rps { $monitor: }

    if $::hostname == 'labstore1005' {
        interface::ip { 'drbd-replication':
            interface => 'eth1',
            address   => '10.64.37.26',
            prefixlen => '24',
        }
    }

    if $::hostname == 'labstore1004' {
        interface::ip { 'drbd-replication':
            interface => 'eth1',
            address   => '10.64.37.25',
            prefixlen => '24',
        }
    }

    $drbd_nodes = ['eth1.labstore1004.eqiad.wmnet', 'eth1.labstore1005.eqiad.wmnet']
    labstore::drbd::resource {'test':
        nodes   => $drbd_nodes,
        port    => '7790',
        device  => '/dev/drbd1',
        disk    => '/dev/misc/test',
        require => Interface::Ip['drbd-replication'],
    }

    labstore::drbd::resource {'tools':
        nodes   => $drbd_nodes,
        port    => '7791',
        device  => '/dev/drbd2',
        disk    => '/dev/tools-project/tools-project',
        require => Interface::Ip['drbd-replication'],
    }

    labstore::drbd::resource {'others':
        nodes   => $drbd_nodes,
        port    => '7792',
        device  => '/dev/drbd3',
        disk    => '/dev/misc/others',
        require => Interface::Ip['drbd-replication'],
    }
}
