class role::labs::monitoring {
    system::role { 'labs::monitoring': }
    include ::role::labs::graphite
    include ::role::labs::prometheus
    include ::profile::grafana
    include standard
    include ::profile::base::firewall
    include ::profile::labs::monitoring
}
