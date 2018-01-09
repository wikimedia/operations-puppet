class role::netmon {
    system::role { 'netmon':
        description => 'Network monitoring and management'
    }
    # Basic boilerplate for network-related servers
    require ::role::network::monitor
    include ::profile::librenms
    include ::profile::rancid
    include ::profile::smokeping
    include ::profile::netbox
    include ::profile::prometheus::postgres_exporter

    interface::add_ip6_mapped { 'main': }
}
