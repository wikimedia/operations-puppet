class role::horizon {
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig
    $designateconfig = hiera_hash('designateconfig', {})

    class { 'openstack::horizon::service':
        openstack_version => $::openstack_version,
        novaconfig        => $novaconfig,
        designateconfig   => $designateconfig,
    }

    ferm::service { 'horizon_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$PRODUCTION_NETWORKS',
    }

    include ::openstack::clientlib
    class { '::openstack::envscripts':
        novaconfig      => $novaconfig,
        designateconfig => $designateconfig,
    }
}
