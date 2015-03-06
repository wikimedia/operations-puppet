class role::horizon {
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    class { 'openstack::horizon::service':
        openstack_version => $::openstack_version,
        novaconfig        => $novaconfig,
    }

    ferm::service { 'horizon_http':
        proto => 'tcp',
        port  => '80',
    }
}
