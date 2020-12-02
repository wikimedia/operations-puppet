class profile::openstack::base::neutron::l3_agent(
    $version = lookup('profile::openstack::base::version'),
    $dmz_cidr = lookup('profile::openstack::base::neutron::dmz_cidr'),
    $network_public_ip = lookup('profile::openstack::base::neutron::network_public_ip'),
    $report_interval = lookup('profile::openstack::base::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::base::neutron::base_interface'),
    $network_flat_interface_vlan_external = lookup('profile::openstack::base::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface_vlan = lookup('profile::openstack::base::neutron::network_flat_interface_vlan'),
    Boolean $enable_hacks        = lookup('profile::openstack::base::neutron::enable_hacks', {default_value => true}),
    Hash    $l3_conntrackd_conf  = lookup('profile::openstack::base::neutron::l3_conntrackd',{default_value => {}}),
    ) {

    interface::tagged { "${base_interface}.${$network_flat_interface_vlan_external}":
        base_interface => $base_interface,
        vlan_id        => $network_flat_interface_vlan_external,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    interface::tagged { "${base_interface}.${$network_flat_interface_vlan}":
        base_interface => $base_interface,
        vlan_id        => $network_flat_interface_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class {'::openstack::neutron::l3_agent':
        version           => $version,
        dmz_cidr_array    => $dmz_cidr,
        network_public_ip => $network_public_ip,
        report_interval   => $report_interval,
        enable_hacks      => $enable_hacks,
    }
    contain '::openstack::neutron::l3_agent'

    class { '::prometheus::node_neutron_namespace':
        ensure => 'present',
    }

    # this expects a data structure like this:
    # profile::openstack::base::neutron::l3_conntrackd_conf:
    #   node1:
    #     netns: qrouter-xxx-xxx
    #     nic: ha-xxx-xxx
    #     local_addr: x.x.x.x
    #     remote_addr: x.x.x.x
    #   node2:
    #     netns: qrouter-xxx-xxx
    #     nic: ha-yyy-yyy
    #     local_addr: y.y.y.y
    #     remote_addr: y.y.y.y

    $conntrackd_netns          = $l3_conntrackd_conf[$::hostname]['netns']
    $conntrackd_nic            = $l3_conntrackd_conf[$::hostname]['nic']
    $conntrackd_local_address  = $l3_conntrackd_conf[$::hostname]['local_addr']
    $conntrackd_remote_address = $l3_conntrackd_conf[$::hostname]['remote_addr']

    class { 'conntrackd':
        conntrackd_cfg => template('profile/openstack/base/neutron/conntrackd.conf.erb'),
        systemd_cfg    => template('profile/openstack/base/neutron/conntrackd.service.erb'),
    }
}
