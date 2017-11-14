# role/dns.pp

class role::dnsrecursor {
    system::role { 'dnsrecursor': description => 'Recursive DNS server' }

    include ::standard
    # TODO make this a profile too
    include ::lvs::configuration
    class { '::lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['dns_rec'][$::site],
    }

    include ::profile::dnsrecursor
    include ::profile::bird::anycast
}
