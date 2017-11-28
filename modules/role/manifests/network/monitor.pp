class role::network::monitor {

    include ::standard
    include ::base::firewall
    include ::passwords::network
    include ::profile::prometheus::snmp_exporter
}
