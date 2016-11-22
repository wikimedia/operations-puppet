class role::labs::openstack::nova::api {
    system::role { $name: }
    require openstack
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    class { '::openstack::nova::api':
        novaconfig        => $novaconfig,
    }
}

