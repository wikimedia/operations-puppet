class role::tor_relay {
    include ::standard
    include ::base::firewall
    include profile::tor::relay
}
