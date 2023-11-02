class profile::openstack::eqiad1::pdns::dns_floating_ip_updater(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    $floating_ip_ptr_zone = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    class {'::profile::openstack::base::pdns::dns_floating_ip_updater':
        openstack_control_nodes                  => $openstack_control_nodes,
        floating_ip_ptr_zone                     => $floating_ip_ptr_zone,
        floating_ip_ptr_fqdn_matching_regex      => $floating_ip_ptr_fqdn_matching_regex,
        floating_ip_ptr_fqdn_replacement_pattern => $floating_ip_ptr_fqdn_replacement_pattern,
    }
}
