# Role class for a DRBD client
# This will be moved elsewhere
class role::labs::labstore::drbd_node {

    include labstore::drbd_node

    $drbd_resource_configs = hiera_hash('labstore::drbd_node::resource_configs')
    $drbd_resource_names = keys($drbd_resource_configs)

    define drbd_resources() {
        labstore::drbd_resource {$name:
            nodes   => $drbd_resource_configs[$name][nodes],
            port    => $drbd_resource_configs[$name][port],
            device  => $drbd_resource_configs[$name][device],
            disk    => $drbd_resource_configs[$name][disk],
            notify => Exec['drbdadm-adjust'],
        }
    }

    drbd_resources($drbd_resource_names)

    # labstore::drbd_resource {'maps':
    #     nodes  => ['labstore-test-01', 'labstore-test-02'],
    #     port   => 7788,
    #     device => '/dev/drbd1',
    #     disk   => '/dev/misc/maps',
    #     notify => Exec['drbdadm-adjust'],
    # }
    #
    # labstore::drbd_resource {'tools-project':
    #     nodes  => ['labstore-test-01', 'labstore-test-02'],
    #     port   => 7789,
    #     device => '/dev/drbd2',
    #     disk   => '/dev/tools-project/tools-project',
    #     notify => Exec['drbdadm-adjust'],
    # }
    #
    # labstore::drbd_resource {'others':
    #     nodes  => ['labstore-test-01', 'labstore-test-02'],
    #     port   => 7790,
    #     device => '/dev/drbd3',
    #     disk   => '/dev/misc/others',
    #     notify => Exec['drbdadm-adjust'],
    # }

    # Ensure that the service is running
    base::service_unit { 'drbd':
        ensure         => present,
        service_params => {
            hasrestart => true,
            hasstatus  => true,
            path       => '/etc/init.d',
        }
    }

    exec {'drbdadm-dump':
        command     => '/sbin/drbdadm dump all',
        refreshonly => true,
        # notify => Exec['drbdadm-adjust']
    }

    # When existing resources are modified, this exec reconfigures them without
    # requiring service restart.
    exec { 'drbdadm-adjust':
        command     => '/sbin/drbdadm adjust all',
        refreshonly => true,
        require     => Base::Service_unit['drbd']
    }

}
