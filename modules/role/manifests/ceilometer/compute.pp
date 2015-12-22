class role::ceilometer::compute {
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    class { 'openstack::ceilometer::compute':
        openstack_version => $::openstack_version,
        novaconfig        => $novaconfig,
    }
}
