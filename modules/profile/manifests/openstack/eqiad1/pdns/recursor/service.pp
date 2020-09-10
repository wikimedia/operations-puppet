class profile::openstack::eqiad1::pdns::recursor::service(
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    Array[Stdlib::Fqdn] $pdns_hosts      = lookup('profile::openstack::eqiad1::pdns::hosts'),
    Stdlib::Fqdn $recursor_service_name  = lookup('profile::openstack::eqiad1::pdns::recursor_service_name'),
    Stdlib::Fqdn $keystone_api_fqdn      = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $observer_password = hiera('profile::openstack::eqiad1::observer_password'),
    $tld = lookup('profile::openstack::eqiad1::pdns::tld'),
    $legacy_tld = lookup('profile::openstack::eqiad1::pdns::legacy_tld'),
    $private_reverse_zones = hiera('profile::openstack::eqiad1::pdns::private_reverse_zones'),
    $aliaser_extra_records = hiera('profile::openstack::eqiad1::pdns::recursor_aliaser_extra_records'),
    ) {

    # This iterates on $hosts and returns the entry in $hosts with the same
    #  ipv4 as $::fqdn
    $service_pdns_host = $pdns_hosts.reduce(false) |$memo, $service_host_fqdn| {
        if (ipresolve($::fqdn,4) == ipresolve($service_host_fqdn,4)) {
            $service_host_fqdn
        } else {
            $memo
        }
    }

    class {'::profile::openstack::base::pdns::recursor::service':
        keystone_api_fqdn     => $keystone_api_fqdn,
        observer_password     => $observer_password,
        pdns_host             => $service_pdns_host,
        pdns_recursor         => $recursor_service_name,
        tld                   => $tld,
        legacy_tld            => $legacy_tld,
        private_reverse_zones => $private_reverse_zones,
        aliaser_extra_records => $aliaser_extra_records,
    }

    class{'::profile::openstack::base::pdns::recursor::monitor::rec_control':}
}
