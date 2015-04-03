# Migrate under role::ci ??
class role::nodepool {

    system::role { 'role::nodepool': description => 'CI Nodepool' }

    include role::nova::config
    include passwords::nodepool

    class { '::nodepool':
        jenkins_api_user         => 'nodepoolmanager',
        jenkins_api_key          => $passwords::nodepool::jenkins_api_key,
        jenkins_credentials_id   => 'nodepool-dib-jenkins',
        jenkins_ssh_private_key  => $passwords::nodepool::jenkins_ssh_private_key,
        nova_controller_hostname => $role::nova::config::novaconfig['controller_hostname'],
        openstack_username       => 'nodepoolmanager',
        openstack_password       => $passwords::nodepool::manager_pass,
        openstack_tenant_id      => 'contintcloud',
    }

}
