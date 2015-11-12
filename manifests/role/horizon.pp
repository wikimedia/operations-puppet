class role::horizon {
    include role::labs::openstack::nova::config
    $novaconfig = $role::labs::openstack::nova::config::novaconfig

    class { 'openstack::horizon::service':
        openstack_version => $::openstack_version,
        novaconfig        => $novaconfig,
    }

    ferm::service { 'horizon_http':
        proto => 'tcp',
        port  => '80',
    }
}
