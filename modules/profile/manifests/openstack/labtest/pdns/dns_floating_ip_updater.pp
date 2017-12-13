class profile::openstack::labtest::pdns::dns_floating_ip_updater(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $observer_pass = hiera('profile::openstack::labtest::observer_password'),
    $floating_ip_ptr_zone = hiera('profile::openstack::labtest::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = hiera('profile::openstack::labtest::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = hiera('profile::openstack::labtest::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    class {'::profile::openstack::base::pdns::dns_floating_ip_updater':
        nova_controller                          => $nova_controller,
        observer_pass                            => $observer_pass,
        floating_ip_ptr_zone                     => $floating_ip_ptr_zone,
        floating_ip_ptr_fqdn_matching_regex      => $floating_ip_ptr_fqdn_matching_regex,
        floating_ip_ptr_fqdn_replacement_pattern => $floating_ip_ptr_fqdn_replacement_pattern,
    }
    contain '::profile::openstack::base::pdns::dns_floating_ip_updater'
}
