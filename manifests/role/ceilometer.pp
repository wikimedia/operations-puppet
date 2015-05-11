class role::ceilometer::controller {
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    class { 'openstack::ceilometer::controller':
        openstack_version => $::openstack_version,
        novaconfig        => $novaconfig,
    }
}

class role::ceilometer::compute {
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    class { 'openstack::ceilometer::compute':
        openstack_version => $::openstack_version,
        novaconfig        => $novaconfig,
    }
}
