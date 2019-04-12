class profile::openstack::base::optional_firewall (
    $use_firewall = hiera('profile::openstack::base::optional_firewall', true),
) {
    if $use_firewall {
        include ::profile::base::firewall
    }
}