class role::network::monitor {

    include ::standard
    include ::profile::base::firewall
    include ::passwords::network
    include ::profile::prometheus::snmp_exporter
}
