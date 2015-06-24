# Migrate under role::ci ??
class role::nodepool {

    system::role { 'role::nodepool': description => 'CI Nodepool' }

    include role::nova::config
    include passwords::nodepool

    class { '::nodepool':
        nova_controller_hostname => $role::nova::config::novaconfig['controller_hostname'],
        openstack_username       => 'nodepoolmanager',
        openstack_password       => $passwords::nodepool::manager_pass,
        openstack_tenant_id      => 'contintcloud',
    }

}
