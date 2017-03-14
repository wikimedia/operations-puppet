class role::network::monitor {
    include ::standard
    include ::base::firewall
    include ::profile::prometheus::snmp_exporter
}
