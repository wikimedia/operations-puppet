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
        rabbit_host => $::realm ? {
            'production' => 'virt1000.wikimedia.org',
            'labs' => 'localhost',
        },
        auth_uri => $::realm ? {
            'production' => 'http://virt1000.wikimedia.org:5000',
            'labs' => 'http://localhost:5000',
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

    if ($::site == "eqiad") {
        interface::ip { "openstack::network_service_public_dynamic_snat": interface => "lo", address => $site ? { "pmtpa" => "208.80.153.192", "eqiad" => "208.80.155.255" } }

        interface::tagged { "eth1.1102":
            base_interface => "bond1",
            vlan_id => "103",
            method => "manual",
            up => 'ip link set $IFACE up',
            down => 'ip link set $IFACE down',
        }
    }
}
