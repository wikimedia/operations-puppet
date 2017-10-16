class profile::openstack::labtest::pdns::dns_floating_ip_updater {
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $observer_pass = hiera('profile::openstack::base::observer_password'),
    $floating_ip_ptr_zone = hiera('profile::openstack::base::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = hiera('profile::openstack::base::designate::floating_ip_ptr_fqdn_matching_regex'),
    ) {

    class {'::profile::openstack::base::pdns::dns_floating_ip_updater':
        nova_controller                     => $nova_controller,
        observer_pass                       => $observer_pass,
        floating_ip_ptr_zone                => $floating_ip_ptr_zone,
        floating_ip_ptr_fqdn_matching_regex => $floating_ip_ptr_fqdn_matching_regex,
    }
}
