class role::neutron::config {
    include passwords::openstack::neutron

    $commonneutronconfig = {
        db_name => 'neutron',
        db_user => 'neutron',
        db_pass => $passwords::openstack::neutron::neutron_db_pass,
    }
}


class role::neutron::config::eqiad inherits role::neutron::config {
    include role::keystone::config::eqiad

    $keystoneconfig = $role::keystone::config::eqiad::keystoneconfig

    $eqiadneutronconfig = {
        db_host => $::realm ? {
            'production' => 'virt1000.wikimedia.org',
            'labs' => 'localhost',
        },
        bind_ip => $::realm ? {
            'production' => '208.80.154.18',
            'labs' => '127.0.0.1',
        },
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
    }
    $neutronconfig = merge($eqiadneutronconfig, $commonneutronconfig)
}

class role::neutron::server {
    include role::neutron::config::eqiad

    $neutronconfig  = $role::neutron::config::eqiad::neutronconfig

    class { 'openstack::neutron-service':
        openstack_version => $openstack_version,
        neutronconfig     => $neutronconfig
    }
}
