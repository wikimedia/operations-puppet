# == Class role::nodepool
#
# See our and upstream documentations:
# https://wikitech.wikimedia.org/wiki/Nodepool
# http://docs.openstack.org/infra/nodepool/
#
class role::nodepool {

    system::role { 'role::nodepool': description => 'CI Nodepool' }

    include role::nova::config
    include passwords::nodepool

    $novaconfig = $role::nova::config::novaconfig

    class { '::nodepool':
        jenkins_api_user               => 'nodepoolmanager',
        jenkins_api_key                => $passwords::nodepool::jenkins_api_key,
        jenkins_credentials_id         => 'nodepool-dib-jenkins',
        jenkins_ssh_public_key_source  => 'puppet:///files/nodepool/dib_jenkins_id_rsa.pub',
        jenkins_ssh_private_key_source => secret('nodepool/dib_jenkins_id_rsa'),
        openstack_auth_uri             => $novaconfig['auth_uri'],
        openstack_username             => 'nodepoolmanager',
        openstack_password             => $passwords::nodepool::manager_pass,
        openstack_tenant_id            => 'contintcloud',
    }

}
