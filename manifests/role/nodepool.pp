class role::nodepool {

    include role::nova::config

    class { '::nodepool':
        nova_controller_hostname => $role::nova::config::novaconfig['controller_hostname'],
    }

}
