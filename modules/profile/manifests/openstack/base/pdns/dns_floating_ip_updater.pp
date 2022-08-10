class profile::openstack::base::pdns::dns_floating_ip_updater(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers', {default_value => ['cloudcontrol1005.wikimedia.org']}),
    $floating_ip_ptr_zone = lookup('profile::openstack::base::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = lookup('profile::openstack::base::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = lookup('profile::openstack::base::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    # only run the cronjob in one node
    if ($::fqdn == $openstack_controllers[0]) {
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
