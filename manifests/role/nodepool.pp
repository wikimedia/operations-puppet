# == Class role::nodepool
#
# See our and upstream documentations:
# https://wikitech.wikimedia.org/wiki/Nodepool
# http://docs.openstack.org/infra/nodepool/
#
class role::nodepool {

    system::role { 'role::nodepool': description => 'CI Nodepool' }

#    include role::nova::config
    include passwords::nodepool

    $novaconfig = $role::nova::config::novaconfig

    class { '::nodepool':
        dib_base_path                  => 'whatever',
        jenkins_ssh_public_key         => 'srsly',
        jenkins_api_user               => 'nodepoolmanager',
        jenkins_api_key                => $passwords::nodepool::jenkins_api_key,
        jenkins_credentials_id         => 'nodepool-dib-jenkins',
        jenkins_ssh_private_key_source => 'puppet:///private/nodepool/dib_jenkins_id_rsa',
        openstack_auth_uri             => '1232',
        openstack_username             => 'nodepoolmanager',
        openstack_password             => $passwords::nodepool::manager_pass,
        openstack_tenant_id            => 'contintcloud',
    }

}
