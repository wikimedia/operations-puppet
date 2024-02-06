class profile::openstack::eqiad1::pdns::auth::db(
    String $pdns_db_pass = lookup('profile::openstack::eqiad1::pdns::db_pass'),
    String $pdns_admin_db_pass = lookup('profile::openstack::eqiad1::pdns::db_admin_pass'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    String $openstack_control_node_interface = lookup('profile::openstack::base::neutron::openstack_control_node_interface', {default_value => 'cloud_private_fqdn'}),
    ) {
    $designate_hosts = $openstack_control_nodes.map |$node| { $node[$openstack_control_node_interface] }

    class {'::profile::openstack::base::pdns::auth::db':
        designate_hosts    => $designate_hosts,
        pdns_db_pass       => $pdns_db_pass,
        pdns_admin_db_pass => $pdns_admin_db_pass,
    }
}
