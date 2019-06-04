class profile::openstack::eqiad1::pdns::recursor::service(
    Stdlib::Fqdn $designate_primary       = lookup('profile::openstack::eqiad1::designate_host'),
    Stdlib::Fqdn $designate_secondary     = lookup('profile::openstack::eqiad1::designate_host_standby'),
    Stdlib::Fqdn $pdns_host               = lookup('profile::openstack::eqiad1::pdns::host'),
    Stdlib::Fqdn $pdns_host_secondary     = lookup('profile::openstack::eqiad1::pdns::host_secondary'),
    Stdlib::Fqdn $pdns_recursor           = lookup('profile::openstack::eqiad1::pdns::recursor'),
    Stdlib::Fqdn $pdns_recursor_secondary = lookup('profile::openstack::eqiad1::pdns::recursor_secondary'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $observer_password = hiera('profile::openstack::eqiad1::observer_password'),
    $tld = hiera('profile::openstack::eqiad1::pdns::tld'),
    $private_reverse_zones = hiera('profile::openstack::eqiad1::pdns::private_reverse_zones'),
    $aliaser_extra_records = hiera('profile::openstack::eqiad1::pdns::recursor_aliaser_extra_records'),
    ) {

    # support for a 2 nodes designate deployment
    if ($::fqdn == $designate_primary) {
        $service_pdns_host     = $pdns_host
        $service_pdns_recursor = $pdns_recursor
    } elsif ($::fqdn == $designate_secondary) {
        $service_pdns_host     = $pdns_host_secondary
        $service_pdns_recursor = $pdns_recursor_secondary
    } else {
        fail('wrong primary/secondary designate/pdns configuration')
    }

    class {'::profile::openstack::base::pdns::recursor::service':
        nova_controller       => $nova_controller,
        keystone_host         => $keystone_host,
        observer_password     => $observer_password,
        pdns_host             => $service_pdns_host,
        pdns_recursor         => $service_pdns_recursor,
        tld                   => $tld,
        private_reverse_zones => $private_reverse_zones,
        aliaser_extra_records => $aliaser_extra_records,
    }

    class{'::profile::openstack::base::pdns::recursor::monitor::rec_control':}
}
