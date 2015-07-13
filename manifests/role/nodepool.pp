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
        dib_base_path           => '/srv/dib',
        jenkins_api_user        => 'nodepoolmanager',
        jenkins_api_key         => $passwords::nodepool::jenkins_api_key,
        jenkins_credentials_id  => 'nodepool-dib-jenkins',
        jenkins_ssh_public_key  => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrERFfjRBOIoI5ASW0gx/rxSeJX/ThszByypsoA80jCfbcjrfsG94WtOGXYQw4Zjs/8u4DYMfI5aHEZKvk/K4jTAR09J9swFash9ML60AvQx/VFC5ZEDHMBa7dYyzxspDX5v73QEDYG9Hhxo6qfFOLO3IvYfat9CfwQR4/oS2lzV+oIsD68lSy/OoKCpywMs0/pExdP65RHR7xpvAlrgehzKoayfHo5Vzg9dCawj4ZoHsqwCnKG4ctMflyzyN/Lwgniv/+GSjgqf/FNXDCMDJCh+d410IXLS7szY3JTzpWekF82SxIM19CdwKh1R2zPVjUT6hvbm9kOo8Y72ORL2yj nodepool@labnodepool1001',
        jenkins_ssh_private_key => secret('nodepool/dib_jenkins_id_rsa'),
        openstack_auth_uri      => $novaconfig['auth_uri'],
        openstack_username      => 'nodepoolmanager',
        openstack_password      => $passwords::nodepool::manager_pass,
        openstack_tenant_id     => 'contintcloud',
    }

}
