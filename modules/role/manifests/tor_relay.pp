# set up a Tor relay (https://www.torproject.org/)
class role::tor_relay {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::tor::relay

    system::role { 'tor_relay':
        description => 'Tor relay'
    }
}
