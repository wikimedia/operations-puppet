# == Class role::nodepool
#
# See our and upstream documentations:
# https://wikitech.wikimedia.org/wiki/Nodepool
# http://docs.openstack.org/infra/nodepool/
#
class role::labs::openstack::nodepool {

    system::role { 'role::nodepool': description => 'CI Nodepool' }

    include passwords::nodepool
    $nova_controller = hiera('labs_nova_controller')

    # dib scripts
    git::clone { 'integration/config':
        ensure    => present,  # manually deployed / refreshed
        directory => '/etc/nodepool/wikimedia',
        branch    => 'master',
        owner     => 'nodepool',
        group     => 'nodepool',
        require   => Class['::nodepool'],
    }

    class { '::nodepool':
        db_host                 => 'm5-master.eqiad.wmnet',
        db_name                 => 'nodepooldb',
        db_user                 => 'nodepool',
        db_pass                 => $passwords::nodepool::nodepooldb_pass,
        dib_base_path           => '/srv/dib',
        jenkins_api_user        => 'nodepoolmanager',
        jenkins_api_key         => $passwords::nodepool::jenkins_api_key,
        jenkins_credentials_id  => 'nodepool-dib-jenkins',
        jenkins_ssh_public_key  => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrERFfjRBOIoI5ASW0gx/rxSeJX/ThszByypsoA80jCfbcjrfsG94WtOGXYQw4Zjs/8u4DYMfI5aHEZKvk/K4jTAR09J9swFash9ML60AvQx/VFC5ZEDHMBa7dYyzxspDX5v73QEDYG9Hhxo6qfFOLO3IvYfat9CfwQR4/oS2lzV+oIsD68lSy/OoKCpywMs0/pExdP65RHR7xpvAlrgehzKoayfHo5Vzg9dCawj4ZoHsqwCnKG4ctMflyzyN/Lwgniv/+GSjgqf/FNXDCMDJCh+d410IXLS7szY3JTzpWekF82SxIM19CdwKh1R2zPVjUT6hvbm9kOo8Y72ORL2yj nodepool@labnodepool1001',
        jenkins_ssh_private_key => secret('nodepool/dib_jenkins_id_rsa'),
        openstack_auth_url      => "http://${nova_controller}:5000/v2.0",
        openstack_username      => 'nodepoolmanager',
        openstack_password      => $passwords::nodepool::manager_pass,
        openstack_tenant_id     => 'contintcloud',
    }

    nrpe::monitor_service { 'nodepoold':
        description   => 'nodepoold running',
        contact_group => 'contint',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u nodepool --ereg-argument-array="^/usr/bin/python /usr/bin/nodepoold -d"',
    }

}
