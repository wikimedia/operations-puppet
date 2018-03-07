class profile::openstack::labtest::pdns::dns_floating_ip_updater(
    $floating_ip_ptr_zone = hiera('profile::openstack::labtest::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = hiera('profile::openstack::labtest::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = hiera('profile::openstack::labtest::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    class {'::profile::openstack::base::pdns::dns_floating_ip_updater':
        floating_ip_ptr_zone                     => $floating_ip_ptr_zone,
        floating_ip_ptr_fqdn_matching_regex      => $floating_ip_ptr_fqdn_matching_regex,
        floating_ip_ptr_fqdn_replacement_pattern => $floating_ip_ptr_fqdn_replacement_pattern,
    }
    contain '::profile::openstack::base::pdns::dns_floating_ip_updater'
}
