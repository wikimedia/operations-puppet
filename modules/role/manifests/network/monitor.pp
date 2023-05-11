class role::network::monitor {

    include ::profile::base::production
    include ::profile::firewall
    include ::passwords::network
    include ::profile::prometheus::snmp_exporter
    include ::profile::backup::host
}
