# Migrate under role::ci ??
class role::nodepool {

    system::role { 'role::nodepool': description => 'CI Nodepool' }

    include role::nova::config

    class { '::nodepool':
        nova_controller_hostname => $role::nova::config::novaconfig['controller_hostname'],
    }

}
