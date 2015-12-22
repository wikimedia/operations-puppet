class role::ceilometer::controller {
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    class { 'openstack::ceilometer::controller':
        openstack_version => $::openstack_version,
        novaconfig        => $novaconfig,
    }
}

