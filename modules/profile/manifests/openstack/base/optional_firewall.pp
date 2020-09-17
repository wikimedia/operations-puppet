class profile::openstack::base::optional_firewall (
    $use_firewall = lookup('profile::openstack::base::optional_firewall', {'default_value' => true}),
) {
    if $use_firewall {
        include ::profile::base::firewall
    }
}
