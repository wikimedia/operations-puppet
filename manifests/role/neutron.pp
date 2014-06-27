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
            'labs'       => 'localhost',
        },
        rabbit_host => $::realm ? {
            'production' => 'virt1000.wikimedia.org',
            'labs'       => 'localhost',
        },
        auth_uri => $::realm ? {
            'production' => 'http://virt1000.wikimedia.org:5000',
            'labs'       => 'http://localhost:5000',
        },
        bind_ip => $::realm ? {
            'production' => '208.80.154.18',
            'labs'       => '127.0.0.1',
        },
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
    }
    $neutronconfig = merge($eqiadneutronconfig, $commonneutronconfig)
}

class role::neutron::computenode {
    include role::neutron::config::eqiad
    $neutronconfig  = $role::neutron::config::eqiad::neutronconfig

    class { 'openstack::neutron-compute':
        neutronconfig     => $neutronconfig,
        data_interface_ip => $::ipaddress,
    }

    # In Openstack terms, this is the 'data' interface
    interface::tagged { 'eth1.1102':
        base_interface => 'eth1',
        vlan_id        => '1102',
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }
}

class role::neutron::controller {
    include role::neutron::config::eqiad
    $neutronconfig  = $role::neutron::config::eqiad::neutronconfig

    class { 'openstack::neutron-controller':
        neutronconfig     => $neutronconfig,
        data_interface_ip => $::ipaddress,
    }
}

class role::neutron::nethost {
    include role::neutron::config::eqiad

    $neutronconfig  = $role::neutron::config::eqiad::neutronconfig

    class { 'openstack::neutron-nethost':
        openstack_version  => $openstack_version,
        external_interface => 'eth5.1122',
        neutronconfig      => $neutronconfig,
        data_interface_ip  => '10.68.16.1',
    }

    if ($::site == 'eqiad') {
        interface::ip { 'openstack::network_service_public_dynamic_snat': interface => 'lo', address => '208.80.155.255' }

        # interface::ip { 'openstack::external_interface': interface => 'br-ex', address => '10.64.22.11', prefixlen => '24' }

        # By hand, unpuppetized step: # ifconfig eth5.1122 promisc
        # By hand, unpuppetized step: # ip addr add 10.64.22.11/24 dev br-ex

        # In Openstack terms, this is the 'data' interface
        interface::tagged { 'eth4.1102':
            base_interface => 'eth4',
            vlan_id        => '1102',
            method         => 'manual',
            up             => 'ip link set $IFACE up',
            down           => 'ip link set $IFACE down',
            address        => '10.68.16.1',
            netmask        => '255.255.255.0',
        }

        # In Openstack terms, this is the 'external' interface
        interface::tagged { 'eth5.1122':
            base_interface => 'eth5',
            vlan_id        => '1122',
            method         => 'manual',
            up             => 'ip link set $IFACE up',
            down           => 'ip link set $IFACE down',
        }

        # In Openstack terms, eth0 is the management interface.
    }
}
