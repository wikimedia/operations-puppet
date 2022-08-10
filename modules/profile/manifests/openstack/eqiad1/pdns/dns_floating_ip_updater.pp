class profile::openstack::eqiad1::pdns::dns_floating_ip_updater(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers', {default_value => ['cloudcontrol1005.wikimedia.org']}),
    $floating_ip_ptr_zone = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = lookup('profile::openstack::eqiad1::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    class {'::profile::openstack::base::pdns::dns_floating_ip_updater':
        openstack_controllers                    => $openstack_controllers,
        floating_ip_ptr_zone                     => $floating_ip_ptr_zone,
        floating_ip_ptr_fqdn_matching_regex      => $floating_ip_ptr_fqdn_matching_regex,
        floating_ip_ptr_fqdn_replacement_pattern => $floating_ip_ptr_fqdn_replacement_pattern,
    }
}
