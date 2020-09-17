class profile::openstack::eqiad1::pdns::dns_floating_ip_updater(
    $floating_ip_ptr_zone = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    class {'::profile::openstack::base::pdns::dns_floating_ip_updater':
        floating_ip_ptr_zone                     => $floating_ip_ptr_zone,
        floating_ip_ptr_fqdn_matching_regex      => $floating_ip_ptr_fqdn_matching_regex,
        floating_ip_ptr_fqdn_replacement_pattern => $floating_ip_ptr_fqdn_replacement_pattern,
    }
}
