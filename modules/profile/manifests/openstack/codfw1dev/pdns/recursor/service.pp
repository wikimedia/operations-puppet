class profile::openstack::codfw1dev::pdns::recursor::service(
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $observer_password = hiera('profile::openstack::codfw1dev::observer_password'),
    $pdns_host = hiera('profile::openstack::codfw1dev::pdns::host'),
    $pdns_recursor = hiera('profile::openstack::codfw1dev::pdns::recursor'),
    $tld = hiera('profile::openstack::codfw1dev::pdns::tld'),
    $private_reverse_zones = hiera('profile::openstack::codfw1dev::pdns::private_reverse_zones'),
    $aliaser_extra_records = hiera('profile::openstack::codfw1dev::pdns::recursor_aliaser_extra_records'),
    ) {

    class {'::profile::openstack::base::pdns::recursor::service':
        keystone_api_fqdn     => $keystone_api_fqdn,
        observer_password     => $observer_password,
        pdns_host             => $pdns_host,
        pdns_recursor         => $pdns_recursor,
        tld                   => $tld,
        private_reverse_zones => $private_reverse_zones,
        aliaser_extra_records => $aliaser_extra_records,
    }

    class{'::profile::openstack::base::pdns::recursor::monitor::rec_control':}
}
