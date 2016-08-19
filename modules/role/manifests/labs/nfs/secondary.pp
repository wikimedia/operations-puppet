class role::labs::nfs::secondary($monitor = 'eth0') {

    system::role { 'role::labs::nfs::secondary':
        description => 'NFS secondary share cluster',
    }

    include labstore::fileserver::secondary
    include labstore::backup_keys

    # Enable RPS to balance IRQs over CPUs
    interface::rps { $monitor: }

    labstore::drbd::resource {'test':
        nodes  => ['labstore1004', 'labstore1005'],
        port   => '7790',
        device => '/dev/drbd1',
        disk   => '/dev/tools-project/test',
    }

    labstore::drbd::resource {'tools':
        nodes  => ['labstore1004', 'labstore1005'],
        port   => '7791',
        device => '/dev/drbd2',
        disk   => '/dev/tools-project/tools-project',
    }

    labstore::drbd::resource {'others':
        nodes  => ['labstore1004', 'labstore1005'],
        port   => '7792',
        device => '/dev/drbd3',
        disk   => '/dev/misc/others',
    }
}
