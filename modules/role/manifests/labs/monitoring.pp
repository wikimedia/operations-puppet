class role::labs::monitoring {
    system::role { 'labs::monitoring': }
    include ::role::labs::graphite
    include ::role::labs::prometheus
    include ::profile::grafana
    include standard
    include ::base::firewall
}
