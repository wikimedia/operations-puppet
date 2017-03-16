# set up a Tor relay (https://www.torproject.org/)
class role::tor_relay {
    include ::standard
    include ::base::firewall
    include ::profile::tor::relay
}
