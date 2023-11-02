class profile::openstack::base::pdns::dns_floating_ip_updater(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    $floating_ip_ptr_zone = lookup('profile::openstack::base::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = lookup('profile::openstack::base::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = lookup('profile::openstack::base::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    # only run the cronjob in one node
    if $::facts['networking']['fqdn'] == $openstack_control_nodes[0]['host_fqdn'] {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    class {'::openstack::designate::dns_floating_ip_updater':
        ensure                                   => $ensure,
        floating_ip_ptr_zone                     => $floating_ip_ptr_zone,
        floating_ip_ptr_fqdn_matching_regex      => $floating_ip_ptr_fqdn_matching_regex,
        floating_ip_ptr_fqdn_replacement_pattern => $floating_ip_ptr_fqdn_replacement_pattern,
    }
}
