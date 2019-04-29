class role::network::monitor {

    include ::profile::standard
    include ::profile::base::firewall
    include ::passwords::network
    include ::profile::prometheus::snmp_exporter
}
