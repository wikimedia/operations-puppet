class profile::openstack::base::pdns::dns_floating_ip_updater(
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $observer_user = hiera('profile::openstack::base::observer_user'),
    $observer_pass = hiera('profile::openstack::base::observer_password'),
    $observer_project = hiera('profile::openstack::base::observer_project'),
    $floating_ip_ptr_zone = hiera('profile::openstack::base::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = hiera('profile::openstack::base::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = hiera('profile::openstack::base::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    class {'::openstack::designate::dns_floating_ip_updater':
        nova_controller                          => $nova_controller,
        observer_user                            => $observer_user,
        observer_pass                            => $observer_pass,
        observer_project                         => $observer_project,
        floating_ip_ptr_zone                     => $floating_ip_ptr_zone,
        floating_ip_ptr_fqdn_matching_regex      => $floating_ip_ptr_fqdn_matching_regex,
        floating_ip_ptr_fqdn_replacement_pattern => $floating_ip_ptr_fqdn_replacement_pattern,
    }
    contain '::openstack::designate::dns_floating_ip_updater'
}
