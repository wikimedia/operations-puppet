class role::labs::nfs::secondary($monitor = 'eth0') {

    system::role { 'role::labs::nfs::secondary':
        description => 'NFS secondary share cluster',
    }

    include labstore::fileserver::exports
    include labstore::fileserver::secondary
    include labstore::backup_keys
    include role::labs::db::maintain_dbusers

    # Enable RPS to balance IRQs over CPUs
    interface::rps { $monitor: }

    interface::manual{ 'eth1':
        interface => 'eth1',
    }

    if $::hostname == 'labstore1005' {
        # Define DRBD role for this host, should come from hiera
        $drbd_role = 'primary'

        interface::ip { 'drbd-replication':
            interface => 'eth1',
            address   => '192.168.0.2',
            prefixlen => '30',
            require   => Interface::Manual['eth1'],
        }
    }

    if $::hostname == 'labstore1004' {
        # Define DRBD role for this host, should come from hiera
        $drbd_role = 'secondary'

        interface::ip { 'drbd-replication':
            interface => 'eth1',
            address   => '192.168.0.1',
            prefixlen => '30',
            require   => Interface::Manual['eth1'],
        }
    }

    # TODO: hiera this
    # TODO: use hiera in maintain_dbusers too when this is hiera'd

    # Floating IP assigned to drbd primary(active NFS server). Should come from hiera
    $cluster_ip = '10.64.37.18'

    $subnet_gateway_ip = '10.64.37.1'

    $drbd_resource_config = {
        'test'   => {
            port       => '7790',
            device     => '/dev/drbd1',
            disk       => '/dev/misc/test',
            mount_path => '/srv/test',
        },
        'tools'  => {
            port       => '7791',
            device     => '/dev/drbd4',
            disk       => '/dev/tools/tools-project',
            mount_path => '/srv/tools',
        },
        'misc' => {
            port       => '7792',
            device     => '/dev/drbd3',
            disk       => '/dev/misc/misc-project',
            mount_path => '/srv/misc',
        },
    }

    $drbd_defaults = {
        'drbd_cluster' => {
            'labstore1004' => '192.168.0.1',
            'labstore1005' => '192.168.0.2',
        },
    }

    create_resources(labstore::drbd::resource, $drbd_resource_config, $drbd_defaults)

    Interface::Ip['drbd-replication'] -> Labstore::Drbd::Resource[keys($drbd_resource_config)]

    # state managed manually
    service { 'drbd':
        enable => false,
    }

    # state via nfs-manage
    service { 'nfs-kernel-server':
        enable => false,
    }

    file { '/usr/local/sbin/nfs-manage':
        content => template('role/labs/nfs/nfs-manage.sh.erb'),
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
    }

    include labstore::monitoring::interfaces
    include labstore::monitoring::ldap
    include labstore::monitoring::nfsd
    class { 'labstore::monitoring::secondary':
        drbd_role  => $drbd_role,
        cluster_ip => $cluster_ip,
    }

    if($drbd_role == 'primary') {

        file { '/usr/local/sbin/safe-du':
            source  => 'puppet:///modules/labstore/monitor/safe-du.sh',
            mode    => '0744',
            owner   => 'root',
            group   => 'root',
        }

        sudo::user { 'diamond_dir_size_tracker':
            user       => 'diamond',
            privileges => ['ALL = NOPASSWD: /usr/local/sbin/safe-du'],
            require    => File['/usr/local/sbin/safe-du'],
        }

        diamond::collector { 'DirectorySize':
            source      => 'puppet:///modules/labstore/monitor/dir_size_tracker.py',
            config_file => 'puppet:///modules/labstore/monitor/DirectorySizeCollector.conf',
            require     => Sudo::User['diamond_dir_size_tracker'],
        }
    }
}
